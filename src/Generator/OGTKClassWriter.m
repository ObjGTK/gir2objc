/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2024 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2024 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKClassWriter.h"

@interface OGTKClassWriter ()
- (OFString *)importForDependency:(OFString *)dependencyGobjType;
- (OFString *)preparedDocumentationStringCopy:(OFString *)unpreparedText;
@end

@implementation OGTKClassWriter

@synthesize classDescription = _classDescription, libraryDescription = _libraryDescription,
            mapper = _mapper;

static OFString *const CErrorParameterName = @"&err";
static OFString *const PrepareErrorHandling = @"\tGError* err = NULL;\n\n";
static OFString *const InitTry = @"\t@try {\n";
static OFString *const InitCatch = @"\t} @catch (id e) {\n"
                                   @"\t\tg_object_unref(gobjectValue);\n"
                                   @"\t\t[wrapperObject release];\n"
                                   @"\t\t@throw e;\n"
                                   @"\t}\n\n";

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithClass:(OGTKClass *)classDescription
                      library:(OGTKLibrary *)libraryDescription
                       mapper:(OGTKMapper *)sharedMapper
{
	self = [super init];

	@try {
		_classDescription = classDescription;
		[_classDescription retain];

		_libraryDescription = libraryDescription;
		[_libraryDescription retain];

		_mapper = sharedMapper;
		[sharedMapper retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_classDescription release];
	[_libraryDescription release];
	[_mapper release];

	[super dealloc];
}

- (void)generateFilesInDir:(OFString *)outputDir
{
	OFFileManager *fileManager = [OFFileManager defaultManager];
	if (![fileManager directoryExistsAtPath:outputDir]) {
		[fileManager createDirectoryAtPath:outputDir createParents:true];
	}

	@try {
		// Header
		OFString *hFilename =
		    [[outputDir stringByAppendingPathComponent:_classDescription.type]
		        stringByAppendingString:@".h"];

		[[self headerString] writeToFile:hFilename];

		// Source
		OFString *sFilename =
		    [[outputDir stringByAppendingPathComponent:_classDescription.type]
		        stringByAppendingString:@".m"];

		[[self sourceString] writeToFile:sFilename];
	} @catch (id e) {
		OFLog(@"Warning: Cannot generate file for type %@. "
		      @"Exception %@, description: %@ "
		      @"Class definition may be incorrect. Skipping…",
		    _classDescription.cName, [e class], [e description]);
	}
}

- (OFString *)headerString
{
	OFMutableString *output = [[OFMutableString alloc] init];

	// OFLog(@"Writing header file for class %@.", _classDescription.type);
	[output appendString:[OGTKClassWriter generateLicense:[OFString stringWithFormat:@"%@.h",
	                                                                _classDescription.type]]];

	[output appendString:@"\n"];

	// Imports/Dependencies
	OFMutableString *importDependencies = [OFMutableString string];
	for (OFString *dependency in _classDescription.dependsOnClasses.allObjects.sortedArray) {

		if ([[OGTKMapper swapTypes:dependency] isEqual:@"OGObject"])
			[importDependencies appendString:@"#import <OGObject/OGObject.h>\n"];
		else if ([OGTKMapper isGobjType:dependency] &&
		    [OGTKMapper isTypeSwappable:dependency]) {

			[importDependencies appendString:[self importForDependency:dependency]];
		}
	}

	// Library dependencies in case we have a class that is at the top of
	// the class dependency tree
	OFMutableString *includes = [OFMutableString string];
	if (_classDescription.topMostGraphNode) {
		for (GIRInclude *cInclude in _libraryDescription.cIncludes) {
			[includes appendFormat:@"#include <%@>\n", cInclude.name];
		}
		[includes appendString:@"\n"];
	}

	[output appendString:includes];
	[output appendString:importDependencies];
	[output appendString:@"\n"];

	// Forward class declarations (for circular dependencies)
	if (_classDescription.forwardDeclarationForClasses.count > 0) {
		for (OFString *gobjClassName in _classDescription.forwardDeclarationForClasses
		         .allObjects.sortedArray) {
			if ([OGTKMapper isGobjType:gobjClassName] &&
			    [OGTKMapper isTypeSwappable:gobjClassName])
				[output appendFormat:@"@class %@;\n",
				        [OGTKMapper swapTypes:gobjClassName]];
		}

		[output appendString:@"\n"];
	}

	// Class documentation
	if (_classDescription.documentation != nil) {
		OFString *docText =
		    [self preparedDocumentationStringCopy:_classDescription.documentation];

		[output appendFormat:@"/**\n * %@\n *\n */\n", docText];

		[docText release];
	}

	// Interface declaration
	OFString *parentClass = [OGTKMapper swapTypes:[_classDescription cParentType]];
	[output
	    appendFormat:@"@interface %@ : %@\n{\n\n}\n\n", [_classDescription type], parentClass];

	// Function declarations
	if (_classDescription.hasFunctions) {
		[output appendString:@"/**\n * Functions\n */\n"];
		[output appendString:@"+ (void)load;\n\n"];

		for (OGTKMethod *func in _classDescription.functions) {
			[output appendFormat:@"\n%@\n", [self generateDocumentationForMethod:func]];

			[output appendFormat:@"+ (%@)%@;\n", func.returnType, func.sig];
		}
	}

	if (_classDescription.hasConstructors) {
		[output appendString:@"\n/**\n * Constructors\n */\n"];

		// Constructor declarations
		for (OGTKMethod *ctor in _classDescription.constructors) {
			[output appendFormat:@"+ (instancetype)%@;\n",
			        [OGTKUtil convertFunctionToInit:ctor.sig
			                        UsingMethodName:_classDescription.cName]];
		}
	}

	[output appendString:@"\n/**\n * Methods\n */\n\n"];

	// GObject getter method declaration
	[output appendFormat:@"- (%@*)%@;\n", _classDescription.cType, @"castedGObject"];

	for (OGTKMethod *meth in _classDescription.methods) {
		[output appendFormat:@"\n%@\n", [self generateDocumentationForMethod:meth]];
		[output appendFormat:@"- (%@)%@;\n", meth.returnType, meth.sig];
	}

	// End interface
	[output appendString:@"\n@end"];

	return [output autorelease];
}

- (OFString *)sourceString
{
	OFMutableString *output = [OFMutableString string];

	// OFLog(@"Writing implementation file for class %@.",
	// _classDescription.type);
	OFString *fileName = [OFString stringWithFormat:@"%@.m", _classDescription.type];
	OFString *license = [OGTKClassWriter generateLicense:fileName];
	[output appendString:license];

	// Imports
	[output appendFormat:@"\n#import \"%@.h\"\n\n", _classDescription.type];

	// Imports for forward class declarations (for circular dependencies)
	if (_classDescription.forwardDeclarationForClasses.count > 0) {
		for (OFString *gobjClassName in _classDescription.forwardDeclarationForClasses
		         .allObjects.sortedArray) {
			if ([OGTKMapper isGobjType:gobjClassName] &&
			    [OGTKMapper isTypeSwappable:gobjClassName]) {

				[output appendString:[self importForDependency:gobjClassName]];
			}
		}

		[output appendString:@"\n"];
	}

	// Implementation declaration
	[output appendFormat:@"@implementation %@\n\n", _classDescription.type];

	[output appendFormat:
	            @"+ (void)load\n{\n"
	            @"\tGType gtypeToAssociate = %@;\n\n"
	            @"\tif (gtypeToAssociate == 0)\n"
	            @"\t\treturn;\n\n"
	            @"\tg_type_set_qdata(gtypeToAssociate, [super wrapperQuark], [self class]);\n"
	            @"}\n\n",
	        _classDescription.gTypeMacro];

	// Class function implementation
	for (OGTKMethod *func in _classDescription.functions) {
		[self appendMethodDefinitionOf:func toString:output classMethod:true];
	}

	// Constructor implementations
	for (OGTKMethod *ctor in _classDescription.constructors) {
		[output appendFormat:@"+ (instancetype)%@",
		        [OGTKUtil convertFunctionToInit:ctor.sig
		                        UsingMethodName:_classDescription.cName]];

		[output appendString:@"\n{\n"];

		if (ctor.throws)
			[output appendString:PrepareErrorHandling];

		// Init GObject and hold result
		OFMutableString *constructorCall =
		    [OFMutableString stringWithFormat:@"%@(%@)", ctor.cIdentifier,
		                     [self generateCParameterListString:ctor.parameters
		                                        throwsException:ctor.throws]];
		OFString *castedConstructorCall =
		    [_classDescription castGObjectMacro:constructorCall];

		[output appendFormat:@"\t%@* gobjectValue = %@;\n\n", _classDescription.cType,
		        castedConstructorCall];
		[output appendString:@"\tif OF_UNLIKELY(!gobjectValue)\n"];
		[output appendString:@"\t\t@throw [OGObjectGObjectToWrapCreationFailedException exception];\n\n"];

		if (_classDescription.derivedFromInitiallyUnowned) {
			[output
			    appendFormat:@"\t// Class is derived from GInitiallyUnowned, so this "
			                 @"reference is floating. Own it:\n"];
			[output appendFormat:@"\tg_object_ref_sink(gobjectValue);\n\n"];
		}

		// Process error handling of the GObject init
		if (ctor.throws)
			[output appendString:
			            [self errorHandlingForGObjectVar:@"gobjectValue"
			                                   ownership:ctor.cOwnershipTransferType]];

		[output appendFormat:@"\t%@* wrapperObject;\n", _classDescription.type];
		[output appendString:InitTry];
		[output appendFormat:@"\t\twrapperObject = %@;\n",
		        [OGTKUtil getFunctionCallForConstructorOfType:_classDescription.type
		                                      withConstructor:@"gobjectValue"]];

		[output appendString:InitCatch];

		[output appendString:@"\tg_object_unref(gobjectValue);\n"];
		[output appendString:@"\treturn [wrapperObject autorelease];\n"];
		[output appendString:@"}\n\n"];
	}

	// GObject getter method implementation
	[output appendFormat:@"- (%@*)%@\n{\n\treturn %@;\n}\n\n", _classDescription.cType,
	        @"castedGObject", [_mapper selfTypeMethodCall:_classDescription.cType]];

	// Method implementations
	for (OGTKMethod *meth in _classDescription.methods) {
		[self appendMethodDefinitionOf:meth toString:output classMethod:false];
	}

	// End implementation
	[output appendString:@"\n@end"];

	return output;
}

- (void)appendMethodDefinitionOf:(OGTKMethod *)method
                        toString:(OFMutableString *)output
                     classMethod:(bool)isClassMethod
{
	if (isClassMethod)
		[output appendFormat:@"+ (%@)%@", method.returnType, method.sig];
	else
		[output appendFormat:@"- (%@)%@", method.returnType, method.sig];

	[output appendString:@"\n{\n"];

	if (method.throws)
		[output appendString:PrepareErrorHandling];

	OFString *cClassFuncSig = [OFString stringWithFormat:@"%@(%@)", method.cIdentifier,
	                                    [self generateCParameterListString:method.parameters
	                                                       throwsException:method.throws]];

	OFString *cInstanceFuncSig =
	    [OFString stringWithFormat:@"%@(%@)", method.cIdentifier,
	              [self generateCParameterListWithInstanceString:_classDescription.type
	                                                   andParams:method.parameters
	                                             throwsException:method.throws]];

	// No return type/GObject/ObjC object
	if (method.returnsVoid) {
		if (isClassMethod) {
			[output appendString:@"\t"];
			[output appendString:cClassFuncSig];
			[output appendString:@";\n"];
		} else {
			[output appendString:@"\t"];
			[output appendString:cInstanceFuncSig];
			[output appendString:@";\n"];
		}

		if (method.throws) {
			[output appendString:@"\n"];
			[output appendString:[self errorHandling]];
		}

	} else {
		// Need to add "return ..."
		if (([_mapper numberOfAsterisksIn:method.cReturnType] < 2) &&
		    [_mapper isTypeSwappable:[method cReturnType]]) {
			// Need to swap type on return

			// Generated source: First execute the GObject API call and hold
			// the result
			[output appendFormat:@"\t%@ gobjectValue = ", method.cReturnType];

			if (isClassMethod) {
				[output appendString:cClassFuncSig];
			} else {
				[output appendString:cInstanceFuncSig];
			}

			[output appendString:@";\n\n"];

			// Generated source: Process error handling of the API call
			if (method.throws) {
				// Generated source: Make sure objects are released in
				// case of error
				if ([_mapper isGobjType:method.cReturnType]) {

					// Ownership: Since the wrapper object refs the cType
					// object, make sure the wrapping method unrefs it if
					// necessary
					OFString *errorHandlingString = [self
					    errorHandlingForGObjectVar:@"gobjectValue"
					                     ownership:method
					                                   .cOwnershipTransferType];
					[output appendString:errorHandlingString];
				} else
					[output appendString:[self errorHandling]];
			}

			// Generated source: Then try to convert the result
			[output appendFormat:@"\t%@ returnValue = ", method.returnType];

			[output
			    appendString:[OGTKMapper convertType:method.cReturnType
			                                withName:@"gobjectValue"
			                                  toType:method.returnType
			                               ownership:method.cOwnershipTransferType]];

			[output appendString:@";\n"];

			if ([_mapper isGobjType:method.cReturnType] &&
			    (method.cOwnershipTransferType == GIRReturnValueOwnershipFull ||
			        method.cOwnershipTransferType ==
			            GIRReturnValueOwnershipContainer)) {
				[output appendString:@"\tg_object_unref(gobjectValue);\n\n"];
			}
		} else {
			// Return type, but no type conversion for return type

			[output appendFormat:@"\t%@ returnValue = (%@)", method.returnType,
			        method.returnType];

			if (isClassMethod) {
				[output appendString:cClassFuncSig];
			} else {
				[output appendString:cInstanceFuncSig];
			}

			[output appendString:@";\n\n"];

			if (method.throws) {
				OFString *varName = nil;
				if ([_mapper isGobjType:method.cReturnType] &&
				    ([_mapper numberOfAsterisksIn:method.cReturnType] < 2))
					varName = @"returnValue";

				// Don't take care ownership if we return plain C types
				// (GIRReturnValueOwnershipNone!) That's the task of the caller in
				// this case
				[output
				    appendString:
				        [self errorHandlingForGObjectVar:varName
				                               ownership:
				                                   GIRReturnValueOwnershipNone]];
			}
		}

		[output appendString:@"\treturn returnValue;\n"];
	}

	[output appendString:@"}\n\n"];
}

- (OFString *)errorHandling
{
	return [self errorHandlingForGObjectVar:nil ownership:GIRReturnValueOwnershipNone];
}

- (OFString *)errorHandlingForGObjectVar:(OFString *)varName
                               ownership:(GIROwnershipTransferType)ownershipType
{
	if (varName != nil &&
	    (ownershipType == GIRReturnValueOwnershipFull ||
	        ownershipType == GIRReturnValueOwnershipContainer))
		return [OFString
		    stringWithFormat:@"\t[OGErrorException throwForError:err unrefGObject:%@];\n\n",
		    varName];

	return [OFString stringWithFormat:@"\t[OGErrorException throwForError:err];\n\n"];
}

- (OFString *)importForDependency:(OFString *)dependencyGobjType
{
	OGTKClass *dependencyClassDescription = [OGTKMapper classInfoByGobjType:dependencyGobjType];

	OFString *result;

	// If parent lib is from this library
	if ([_classDescription.namespace isEqual:dependencyClassDescription.namespace]) {

		result = [OFString stringWithFormat:@"#import \"%@.h\"\n",
		                   [OGTKMapper swapTypes:dependencyGobjType]];

	} else {
		// We need to get the ObjC name of the
		// external library in order to provide
		// the correct header directive
		OGTKLibrary *depLibDescr =
		    [OGTKMapper libraryInfoByNamespace:dependencyClassDescription.namespace];

		if (depLibDescr == nil)
			@throw [OFUndefinedKeyException
			    exceptionWithObject:[OGTKMapper sharedMapper]
			                    key:dependencyClassDescription.namespace];

		// Make sure we include the libs own header, because the parent
		// class will introduce headers of its library. Otherwise we
		// may get undefined symbols for this class
		_classDescription.topMostGraphNode = true;

		result = [OFString stringWithFormat:@"#import <%@/%@.h>\n", depLibDescr.name,
		                   dependencyClassDescription.type];
	}

	return result;
}

- (OFString *)generateCParameterListString:(OFArray OF_GENERIC(OGTKParameter *) *)params
                           throwsException:(bool)throws
{
	OFMutableString *paramsOutput = [OFMutableString string];

	size_t i = 0, count = params.count;
	for (OGTKParameter *param in params) {
		[paramsOutput appendString:[OGTKMapper convertType:param.type
		                                          withName:param.name
		                                            toType:param.cType]];

		if (i++ < count - 1)
			[paramsOutput appendString:@", "];
	}

	if (throws && count > 0) {
		[paramsOutput appendFormat:@", %@", CErrorParameterName];
	} else if (throws && count == 0) {
		[paramsOutput appendString:CErrorParameterName];
	}

	return paramsOutput;
}

- (OFString *)generateCParameterListWithInstanceString:(OFString *)instanceType
                                             andParams:(OFArray OF_GENERIC(OGTKParameter *) *)params
                                       throwsException:(bool)throws
{
	OFMutableString *paramsOutput = [OFMutableString string];

	[paramsOutput appendString:[OGTKMapper selfTypeMethodCall:instanceType]];

	size_t count = params.count;

	if (params != nil && count > 0) {
		[paramsOutput appendString:@", "];

		// Start at index 1
		size_t i = 0;
		for (OGTKParameter *param in params) {
			[paramsOutput appendString:[OGTKMapper convertType:param.type
			                                          withName:param.name
			                                            toType:param.cType]];

			if (i++ < count - 1) {
				[paramsOutput appendString:@", "];
			}
		}
	}

	if (throws)
		[paramsOutput appendFormat:@", %@", CErrorParameterName];

	return paramsOutput;
}

+ (OFString *)generateLicense:(OFString *)fileName
{
	OFString *licText = [OFString
	    stringWithContentsOfFile:[[OGTKUtil dataDir]
	                                 stringByAppendingPathComponent:@"Config/license.txt"]];

	return [licText stringByReplacingOccurrencesOfString:@"@@@FILENAME@@@" withString:fileName];
}

- (OFString *)preparedDocumentationStringCopy:(OFString *)unpreparedText
{
	OFMutableString *docText =
	    [[unpreparedText stringByDeletingEnclosingWhitespaces] mutableCopy];
	[docText replaceOccurrencesOfString:@"\n" withString:@"\n * "];

	[docText makeImmutable];

	return docText;
}

- (OFString *)generateDocumentationForMethod:(OGTKMethod *)meth
{
	OFMutableString *doc = [OFMutableString string];

	OFString *docText;

	if (meth.documentation != nil) {
		docText = [self preparedDocumentationStringCopy:meth.documentation];

		[doc appendFormat:@"/**\n * %@\n *\n", docText];
		[docText release];
	} else {
		[doc appendString:@"/**\n *\n"];
	}

	if ([meth.parameters count] > 0) {
		for (OGTKParameter *parameter in meth.parameters) {

			if (parameter.documentation != nil) {
				docText =
				    [self preparedDocumentationStringCopy:parameter.documentation];

				[doc appendFormat:@" * @param %@ %@\n", parameter.name, docText];

				[docText release];
			} else {
				[doc appendFormat:@" * @param %@\n", parameter.name];
			}
		}
	}

	if (![meth returnsVoid]) {
		if (meth.returnValueDocumentation != nil) {
			docText =
			    [self preparedDocumentationStringCopy:meth.returnValueDocumentation];

			[doc appendFormat:@" * @return %@\n", docText];

			[docText release];
		} else {
			[doc appendString:@" * @return\n"];
		}
	}

	[doc appendString:@" */"];

	return doc;
}

@end
