/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2024 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2024 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "Gir2Objc.h"

#import "Generator/OGTKClass.h"
#import "Generator/OGTKParameter.h"
#import "Generator/OGTKUtil.h"

#import "GIR/GIRInclude.h"

#import "Exceptions/OGTKClassNoTypeException.h"
#import "Exceptions/OGTKDataProcessingNotImplementedException.h"
#import "Exceptions/OGTKGIRNoPackageException.h"
#import "Exceptions/OGTKNamespaceContainsNoClassesException.h"
#import "Exceptions/OGTKNoGIRAPIException.h"
#import "Exceptions/OGTKNoGIRDictException.h"

#import "XMLReader/XMLReader.h"

@interface Gir2Objc ()

+ (OFString *)firstOfKommaSeparatedElements:(OFString *)elementString;

+ (void)mapGIRClass:(GIRClass *)girClass
        toObjCClass:(OGTKClass *)objCClass
     usingNamespace:(GIRNamespace *)ns;

+ (void)addMappedGIRMethods:(OFMutableArray OF_GENERIC(id<GIRMethodMapping>) *)girMethodArray
                toObjCClass:(OGTKClass *)objCClass
              usingSelector:(SEL)addMethodSelector;

@end

@implementation Gir2Objc

+ (void)parseGirFromFile:(OFString *)girFile intoDictionary:(OFDictionary **)girDict;
{
	*girDict = nil;

	OFString *girContents = [[[OFString alloc] initWithContentsOfFile:girFile] autorelease];

	if (girContents == nil) {
		@throw [OFReadFailedException exceptionWithObject:girFile
		                                  requestedLength:0
		                                            errNo:0];
	}

	@try {
		// Parse the XML into a dictionary
		*girDict = [XMLReader dictionaryForXMLString:girContents];
	} @catch (id exception) {
		// On error, if a dictionary was still created, clean it up
		// before returning
		if (*girDict != nil) {
			[*girDict release];
		}

		@throw exception;
	}
}

+ (GIRAPI *)firstAPIFromGirFile:(OFString *)girFile
{
	OFDictionary *girDict = nil;

	[self parseGirFromFile:girFile intoDictionary:&girDict];

	return [self firstAPIFromDictionary:girDict];
}

+ (GIRAPI *)firstAPIFromDictionary:(OFDictionary *)girDict
{
	if (girDict == nil)
		@throw [OGTKNoGIRDictException exception];

	for (OFString *key in girDict) {
		id value = [girDict objectForKey:key];

		if ([key isEqual:@"api"] || [key isEqual:@"repository"]) {
			return [[[GIRAPI alloc] initWithDictionary:value] autorelease];
		} else if ([value isKindOfClass:[OFDictionary class]]) {
			return [self firstAPIFromDictionary:value];
		}
	}

	return nil;
}

+ (OGTKLibrary *)generateLibraryInfoFromAPI:(GIRAPI *)api
{
	OFArray *namespaces = api.namespaces;

	if (api == nil || namespaces == nil)
		@throw [OGTKNoGIRAPIException exception];

	// Map library information from API
	OGTKLibrary *libraryInfo = [[[OGTKLibrary alloc] init] autorelease];

	if (api.packages == nil || api.packages.count == 0)
		@throw [OGTKGIRNoPackageException exception];
	libraryInfo.packages = api.packages;

	for (GIRInclude *include in api.cInclude) {
		[libraryInfo addCInclude:include];
	}

	for (GIRInclude *dependency in api.include) {
		[libraryInfo addDependency:dependency];
	}

	if (namespaces.count > 1)
		@throw [OGTKDataProcessingNotImplementedException
		    exceptionWithDescription:@"Found more than one namespace within an GIR API. "
		                             @"That's unexpected and not implemented yet. Please "
		                             @"contact the maintainer."];

	GIRNamespace *ns = namespaces.firstObject;

	// Map library information from namespace
	libraryInfo.namespace = ns.name;
	libraryInfo.version = ns.version;
	[libraryInfo addSharedLibrariesAsString:ns.sharedLibrary];
	libraryInfo.cNSIdentifierPrefix =
	    [self firstOfKommaSeparatedElements:ns.cIdentifierPrefixes];
	libraryInfo.cNSSymbolPrefix = [self firstOfKommaSeparatedElements:ns.cSymbolPrefixes];

	OFString *libraryIdentifier = libraryInfo.identifier;

	// Load additional configuration provided manually by config file
	OFDictionary *libraryConfig = [OGTKUtil libraryConfigFor:libraryIdentifier];

	if ([libraryConfig valueForKey:@"customName"] != nil)
		libraryInfo.name = [libraryConfig valueForKey:@"customName"];

	if ([libraryConfig valueForKey:@"excludeClasses"] != nil) {
		OFArray *excludeClasses = [libraryConfig valueForKey:@"excludeClasses"];
		libraryInfo.excludeClasses = [OFSet setWithArray:excludeClasses];
	}

	return libraryInfo;
}

+ (void)generateClassInfoFromNamespace:(GIRNamespace *)ns
                            forLibrary:(OGTKLibrary *)libraryInfo
                            intoMapper:(OGTKMapper *)mapper
{
	if (ns == nil)
		@throw [OGTKNoGIRAPIException exception];

	OFLog(@"Namespace name: %@", ns.name);
	OFLog(@"C symbol prefixex: %@", ns.cSymbolPrefixes);
	OFLog(@"C identifier prefixes: %@", ns.cIdentifierPrefixes);

	if ([ns.classes count] == 0)
		@throw [OGTKNamespaceContainsNoClassesException exception];

	for (GIRClass *girClass in ns.classes) {
		void *pool = objc_autoreleasePoolPush();

		if ([libraryInfo.excludeClasses containsObject:girClass.name])
			continue;

		OGTKClass *objCClass = [[[OGTKClass alloc] init] autorelease];

		[self mapGIRClass:girClass toObjCClass:objCClass usingNamespace:ns];

		@try {
			[mapper addClass:objCClass];
		} @catch (id e) {
			OFLog(@"Warning: Cannot add type %@ to mapper. "
			      @"Exception %@, description: %@"
			      @"Class definition may be incorrect. "
			      @"Skipping…",
			    objCClass.cName, [e class], [e description]);
			[mapper removeClass:objCClass];
		}
		objc_autoreleasePoolPop(pool);
	}
}

+ (void)mapGIRClass:(GIRClass *)girClass
        toObjCClass:(OGTKClass *)objCClass
     usingNamespace:(GIRNamespace *)ns
{
	// Set basic class properties
	[objCClass setCName:girClass.name];

	if (girClass.cType != nil && girClass.cType.length > 0)
		objCClass.cType = girClass.cType;
	else if (girClass.glibTypeName != nil && girClass.glibTypeName.length > 0)
		objCClass.cType = girClass.glibTypeName;
	else
		@throw [OGTKClassNoTypeException exceptionForGirClass:girClass];

	[objCClass setDocumentation:girClass.doc.docText];

	// Set parent name
	[objCClass setParentName:girClass.parent];

	// Try to set parent c type
	// First try to get information from a <field> node.
	// Otherwise we need to get the c type from the mapper
	// later
	OFArray *classFields = girClass.fields;
	for (GIRField *field in classFields) {
		if ([field.name isEqual:@"parent_class"] ||
		    [field.name isEqual:@"parent_instance"]) {
			[objCClass setCParentType:field.type.cType];
		}
	}

	[objCClass setCSymbolPrefix:girClass.cSymbolPrefix];
	[objCClass setNamespace:ns.name];
	[objCClass
	    setCNSIdentifierPrefix:[self firstOfKommaSeparatedElements:ns.cIdentifierPrefixes]];
	[objCClass setCNSSymbolPrefix:[self firstOfKommaSeparatedElements:ns.cSymbolPrefixes]];

	// Set constructors
	[self addMappedGIRMethods:girClass.constructors
	              toObjCClass:objCClass
	            usingSelector:@selector(addConstructor:)];

	// Set functions
	[self addMappedGIRMethods:girClass.functions
	              toObjCClass:objCClass
	            usingSelector:@selector(addFunction:)];

	// Set methods
	[self addMappedGIRMethods:girClass.methods
	              toObjCClass:objCClass
	            usingSelector:@selector(addMethod:)];
}

+ (void)addMappedGIRMethods:(OFMutableArray OF_GENERIC(id<GIRMethodMapping>) *)girMethodArray
                toObjCClass:(OGTKClass *)objCClass
              usingSelector:(SEL)addMethodSelector
{
	for (id<GIRMethodMapping> girMethod in girMethodArray) {
		bool foundVarArgs = false;

		// TODO: Implement varargs
		// First need to check for varargs in list of
		// parameters
		for (GIRParameter *param in girMethod.parameters) {
			if (param.varargs != nil) {
				foundVarArgs = true;
				break;
			}
		}

		// Don't handle VarArgs methods
		if (foundVarArgs)
			continue;

		OGTKMethod *objcMethod = [[OGTKMethod alloc] init];

		OFString *methodName;
		if ([girMethod.name isEqual:@"errno"])
			methodName = @"errNo";
		else
			methodName = girMethod.name;

		// Memory management is encapsulated using the ObjC way, so
		// leave out the GObject API
		if ([methodName isEqual:@"ref"] || [methodName isEqual:@"unref"]) {

			[objcMethod release];
			continue;
		}

		if ([girMethod isKindOfClass:[GIRMethod class]]) {
			GIRMethod *girMethodInstance = (GIRMethod *)girMethod;
			if (girMethodInstance.glibGetForProperty != nil &&
			    girMethodInstance.glibGetForProperty.length != 0)
				objcMethod.isGetter = true;

			if (girMethodInstance.glibSetForProperty != nil &&
			    girMethodInstance.glibSetForProperty.length != 0)
				objcMethod.isSetter = true;
		}

		// Leave "get" because this usually means we want to get a special
		// object member (not implemented as a property),
		// but otherwise remove "get" as a prefix for getters because that's
		// against ObjC rules.
		// Not all `get…` methods are marked as getters, so we currently
		// apply this to all methods to allow ObjC dot-syntax for them.
		if (![methodName isEqual:@"get"] && [methodName hasPrefix:@"get"]) {
			methodName = [methodName substringFromIndex:4];
		}

		if ([methodName isEqual:@"release"])
			methodName = @"decrease_count";
		else if ([methodName isEqual:@"retain"])
			methodName = @"increase_count";

		[objcMethod setName:methodName];
		[objcMethod setCIdentifier:girMethod.cIdentifier];
		objcMethod.documentation = girMethod.doc.docText;

		// Set return type
		if (girMethod.returnValue.type == nil && girMethod.returnValue.array != nil) {
			[objcMethod setCReturnType:girMethod.returnValue.array.cType];
		} else {
			[objcMethod setCReturnType:girMethod.returnValue.type.cType];
		}

		// Set return type documentation
		objcMethod.returnValueDocumentation = girMethod.returnValue.doc.docText;

		// Set return type ownership
		objcMethod.cOwnershipTransferType = girMethod.returnValue.transferOwnership;

		// Set if throws GError
		[objcMethod setThrows:girMethod.throws];

		// Set parameters
		OFMutableArray *paramArray = [[OFMutableArray alloc] init];

		for (GIRParameter *param in girMethod.parameters) {
			OGTKParameter *objcParam = [[OGTKParameter alloc] init];
			objcParam.documentation = param.doc.docText;

			OFString *cType;
			if (param.type == nil && param.array != nil) {
				cType = param.array.cType;
			} else {
				cType = param.type.cType;
			}
			if ([cType containsString:@"const _"]) {
				cType = [cType stringByReplacingOccurrencesOfString:@"const _"
				                                         withString:@"const "
				                                                    @"struct _"];
			}
			[objcParam setCType:cType];

			[objcParam setCName:param.name];
			[paramArray addObject:objcParam];
			[objcParam release];
		}

		[objcMethod setParameters:paramArray];
		[paramArray release];

		// Add method to class
		[objCClass performSelector:addMethodSelector withObject:objcMethod];
		[objcMethod release];
	}
}

+ (OFString *)firstOfKommaSeparatedElements:(OFString *)elementString
{
	return [[elementString componentsSeparatedByString:@","] firstObject];
}

@end
