/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "OGTKMapper.h"
#import "OGTKClass.h"
#import "OGTKLibrary.h"
#import "OGTKParameter.h"

@interface OGTKMapper ()

- (OFString *)stripAsterisks:(OFString *)identifier;

- (size_t)numberOfAsterisksIn:(OFString *)identifier;

- (void)addDependenciesFromMethod:(OGTKMethod *)method to:(OGTKClass *)classInfo;

- (void)walkDependencyTreeFrom:(OGTKClass *)classInfo usingStack:(OFMutableDictionary *)stack;

@end

static OGTKMapper *sharedMyMapper = nil;

@implementation OGTKMapper

@synthesize girNameToLibraryMapping = _girNameToLibraryMapping,
            gobjTypeToClassMapping = _gobjTypeToClassMapping,
            girNameToClassMapping = _girNameToClassMapping,
            objcTypeToClassMapping = _objcTypeToClassMapping;

#pragma mark - Object lifecycle

- (instancetype)init
{
	self = [super init];

	@try {
		_girNameToLibraryMapping = [[OFMutableDictionary alloc] init];
		_gobjTypeToClassMapping = [[OFMutableDictionary alloc] init];
		_girNameToClassMapping = [[OFMutableDictionary alloc] init];
		_objcTypeToClassMapping = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_girNameToLibraryMapping release];
	[_gobjTypeToClassMapping release];
	[_girNameToClassMapping release];
	[_objcTypeToClassMapping release];

	[super dealloc];
}

+ (instancetype)sharedMapper
{
	@synchronized(self) {
		if (sharedMyMapper == nil)
			sharedMyMapper = [[self alloc] init];
	}
	return sharedMyMapper;
}

#pragma mark - Public methods - domain logic

- (void)addLibrary:(OGTKLibrary *)libraryInfo
{
	[_girNameToLibraryMapping setObject:libraryInfo forKey:libraryInfo.namespace];
}

- (void)removeLibrary:(OGTKLibrary *)libraryInfo
{
	if (libraryInfo.namespace != nil &&
	    [_girNameToLibraryMapping objectForKey:libraryInfo.namespace] != nil) {

		[_girNameToLibraryMapping removeObjectForKey:libraryInfo.namespace];
	}
}

- (void)addClass:(OGTKClass *)classInfo
{
	[_gobjTypeToClassMapping setObject:classInfo forKey:classInfo.cType];

	[_girNameToClassMapping setObject:classInfo forKey:classInfo.cName];

	[_objcTypeToClassMapping setObject:classInfo forKey:classInfo.type];
}

- (void)removeClass:(OGTKClass *)classInfo
{
	if (classInfo.cType != nil && [_gobjTypeToClassMapping objectForKey:classInfo.cType] != nil)
		[_gobjTypeToClassMapping removeObjectForKey:classInfo.cType];

	if (classInfo.cName != nil && [_girNameToClassMapping objectForKey:classInfo.cName] != nil)
		[_girNameToClassMapping removeObjectForKey:classInfo.cName];

	if (classInfo.cType != nil && classInfo.type != nil &&
	    [_objcTypeToClassMapping objectForKey:classInfo.type] != nil)
		[_objcTypeToClassMapping removeObjectForKey:classInfo.type];
}

- (bool)isGobjType:(OFString *)type
{
	return ([_gobjTypeToClassMapping objectForKey:[self stripAsterisks:type]] != nil);
}

- (bool)isObjcType:(OFString *)type
{
	return ([_objcTypeToClassMapping objectForKey:[self stripAsterisks:type]] != nil);
}

- (void)determineParentClassNames
{
	OFMutableArray *classesToRemove = [[OFMutableArray alloc] init];

	for (OFString *className in _objcTypeToClassMapping) {
		OGTKClass *currentClass = [_objcTypeToClassMapping objectForKey:className];

		if (currentClass.cParentType == nil) {
			@try {
				OFString *cParentType =
				    [self getCTypeFromName:currentClass.parentName];

				[currentClass setCParentType:cParentType];
			} @catch (id e) {
				OFLog(@"Could not get c type for parent of %@, "
				      @"parent: %@, \n"
				      @"exception %@. "
				      @"Removing class…",
				    currentClass.cName, currentClass.parentName, [e class]);
				[classesToRemove addObject:currentClass];
			}
		}
	}

	for (OGTKClass *currentClass in classesToRemove)
		[self removeClass:currentClass];
	[classesToRemove release];
}

- (void)determineClassDependencies
{
	OFMutableArray *classesToRemove = [[OFMutableArray alloc] init];

	for (OFString *className in _objcTypeToClassMapping) {
		OGTKClass *classInfo = [_objcTypeToClassMapping objectForKey:className];

		if (classInfo.cParentType != nil)
			[classInfo addDependency:classInfo.cParentType];

		for (OGTKMethod *constructor in classInfo.constructors)
			[self addDependenciesFromMethod:constructor to:classInfo];

		for (OGTKMethod *function in classInfo.functions)
			[self addDependenciesFromMethod:function to:classInfo];

		for (OGTKMethod *method in classInfo.methods)
			[self addDependenciesFromMethod:method to:classInfo];

		if (classInfo.parentName == nil ||
				[classInfo.parentName isEqual:@"Object"] ||
		    [classInfo.parentName isEqual:@"GObject.Object"] ||
		    [classInfo.parentName isEqual:@"GObject.InitiallyUnowned"])
			continue;

		if (![self isGobjType:classInfo.cParentType] && ![classInfo.cName isEqual:@"Object"]) {
			OFLog(@"Parent c type of %@ is not in the GObject inheritance chain, "
			      @"parent: %@, \n"
			      @"Removing class…",
			    classInfo.cName, classInfo.parentName);
			[classesToRemove addObject:classInfo];
		}
	}

	for (OGTKClass *currentClass in classesToRemove)
		[self removeClass:currentClass];
	[classesToRemove release];
}

- (void)detectAndMarkCircularClassDependencies
{
	for (OFString *className in _objcTypeToClassMapping) {
		OGTKClass *classInfo = [_objcTypeToClassMapping objectForKey:className];

		OFMutableDictionary *stack = [[OFMutableDictionary alloc] init];

		[stack setObject:@"1" forKey:classInfo.cType];

		[self walkDependencyTreeFrom:classInfo usingStack:stack];

		[stack release];
	}
}

- (OFString *)swapTypes:(OFString *)type
{
	// Convert basic types by hardcoding
	if ([type isEqual:@"GInitiallyUnowned"] || [type isEqual:@"GObject"])
		return @"OGObject";
	else if ([type isEqual:@"const gchar*"] || [type isEqual:@"gchar*"] ||
	    [type isEqual:@"const char*"] || [type isEqual:@"gchar*"])
		return @"OFString*";
	else if ([type isEqual:@"Gtk"])
		return @"OGTK";
	else if ([type isEqual:@"OFString*"])
		return @"const gchar*";

	// Different naming, same type
	else if ([type isEqual:@"gboolean"])
		return @"bool";
	else if ([type isEqual:@"bool"])
		return @"gboolean";

	// Get the number of '*' - currently we only swap simple pointers (*)
	size_t numberOfAsterisks = [self numberOfAsterisksIn:type];
	if (numberOfAsterisks > 1)
		return type;

	OFString *strippedType = [self stripAsterisks:type];

	// Gobj -> ObjC type swapping
	OGTKClass *objcClassInfo = [_gobjTypeToClassMapping objectForKey:strippedType];

	if (objcClassInfo != nil) {
		if ([strippedType isEqual:type])
			return objcClassInfo.type;
		else
			return [OFString stringWithFormat:@"%@*", objcClassInfo.type];
	}

	// ObjC -> Gobj type swapping
	OGTKClass *gobjClassInfo = [_objcTypeToClassMapping objectForKey:strippedType];

	if (gobjClassInfo != nil) {
		if ([strippedType isEqual:type])
			return gobjClassInfo.cType;
		else
			return [OFString stringWithFormat:@"%@*", gobjClassInfo.cType];
	}

	return type;
}

- (bool)isTypeSwappable:(OFString *)type
{
	return [type isEqual:@"gchar*"] || [type isEqual:@"const gchar*"] ||
	    [type isEqual:@"char*"] || [type isEqual:@"const char*"] ||
	    [type isEqual:@"OFString*"] || [type isEqual:@"OFArray*"] || [self isGobjType:type] ||
	    [self isObjcType:type];
}

- (OFString *)convertType:(OFString *)fromType withName:(OFString *)name toType:(OFString *)toType
{
	return [self convertType:fromType
	                withName:name
	                  toType:toType
	               ownership:GIRReturnValueOwnershipUnknown];
}

- (OFString *)convertType:(OFString *)fromType
                 withName:(OFString *)name
                   toType:(OFString *)toType
                ownership:(GIROwnershipTransferType)ownership
{
	// Try to return conversion for string types first
	// Owned strings
	if (([fromType isEqual:@"gchar*"] || [fromType isEqual:@"char*"]) &&
	    (ownership == GIRReturnValueOwnershipFull ||
	        ownership == GIRReturnValueOwnershipContainer ||
	        ownership == GIRReturnValueOwnershipUnknown) &&
	    [toType isEqual:@"OFString*"]) {
		return
		    [OFString stringWithFormat:
		                  @"((%@ != NULL) ? [OFString stringWithUTF8StringNoCopy:(char * "
		                  @"_Nonnull)%@ freeWhenDone:true] : nil)",
		              name, name];
		// Unowned strings
	} else if (([fromType isEqual:@"const char*"] || [fromType isEqual:@"const gchar*"]) &&
	    (ownership == GIRReturnValueOwnershipNone ||
	        ownership == GIRReturnValueOwnershipUnknown) &&
	    [toType isEqual:@"OFString*"]) {
		return
		    [OFString stringWithFormat:
		                  @"((%@ != NULL) ? [OFString stringWithUTF8StringNoCopy:(char * "
		                  @"_Nonnull)%@ freeWhenDone:false] : nil)",
		              name, name];
	} else if ([fromType isEqual:@"OFString*"] &&
	    ([toType isEqual:@"const gchar*"] || [toType isEqual:@"const char*"])) {
		return [OFString stringWithFormat:@"[%@ UTF8String]", name];
	} else if ([fromType isEqual:@"OFString*"] &&
	    ([toType isEqual:@"gchar*"] || [toType isEqual:@"char*"])) {
		return [OFString stringWithFormat:@"g_strdup([%@ UTF8String])", name];
	}

	// Then try to return generic Gobj type conversion
	if ([self isGobjType:fromType] && [self isObjcType:toType]) {
		// Converting from Gobjc -> Objc

		return [OFString
		    stringWithFormat:@"[%@ withGObject:%@]", [self stripAsterisks:toType], name];

	} else if ([self isObjcType:fromType] && [self isGobjType:toType]) {
		// Converting from Objc -> Gobj
		return [OFString stringWithFormat:@"[%@ %@]", name, @"castedGObject"];
	}

	// Otherwise don't do any conversion (including bool types, as ObjFW
	// uses the stdc bool type)
	return name;
}

- (OFString *)selfTypeMethodCall:(OFString *)type;
{
	// Convert OGTKFooBar into [self FOOBAR]
	if ([self isObjcType:type]) {
		return @"[self castedGObject]";
	}

	// Convert GtkFooBar into GTK_FOO_BAR([self GOBJECT])
	if ([self isGobjType:type]) {
		OGTKClass *classInfo =
		    [_gobjTypeToClassMapping objectForKey:[self stripAsterisks:type]];

		return [classInfo castGObjectMacro:@"[self gObject]"];
	}

	return type;
}

- (OFString *)getCTypeFromName:(OFString *)name
{
	// Some shortcut definitions from libraries we do not want to add as
	// dependencies
	if ([name isEqual:@"GObject.InitiallyUnowned"])
		return @"GInitiallyUnowned";
	else if ([name containsString:@"GObject."] || [name containsString:@"Soup."])
		return @"GObject";

	// Case: Name has a namespace prefix
	if ([name containsString:@"."]) {
		OFArray *nameParts = [name componentsSeparatedByString:@"."];

		OGTKClass *classInfo =
		    [_girNameToClassMapping objectForKey:[nameParts objectAtIndex:1]];

		if (classInfo != nil && [classInfo.namespace isEqual:[nameParts objectAtIndex:0]])
			return classInfo.cType;
	}

	// Case: Simple name without prefix
	OGTKClass *classInfo = [_girNameToClassMapping objectForKey:name];
	if (classInfo != nil)
		return classInfo.cType;

	// Case: We did not find any c type
	@throw [OFInvalidArgumentException exception];
}

- (OGTKClass *)classInfoByGobjType:(OFString *)gobjTypeUnfiltered
{
	OFString *gobjType = [self stripAsterisks:gobjTypeUnfiltered];
	OGTKClass *classInfo = [_gobjTypeToClassMapping objectForKey:gobjType];

	if (classInfo == nil)
		@throw [OFUndefinedKeyException exceptionWithObject:_gobjTypeToClassMapping
		                                                key:gobjType];

	return classInfo;
}

- (OGTKLibrary *)libraryInfoByNamespace:(OFString *)libNamespace
{
	return [_girNameToLibraryMapping objectForKey:libNamespace];
}

#pragma mark - Private methods - domain logic

- (OFString *)stripAsterisks:(OFString *)identifier
{
	OFCharacterSet *charSet = [OFCharacterSet characterSetWithCharactersInString:@"*"];
	size_t index = [identifier indexOfCharacterFromSet:charSet];

	if (index == OFNotFound)
		return identifier;

	return [identifier substringToIndex:index];
}

- (size_t)numberOfAsterisksIn:(OFString *)identifier
{
	OFCharacterSet *charSet = [OFCharacterSet characterSetWithCharactersInString:@"*"];
	size_t index = [identifier indexOfCharacterFromSet:charSet];

	if (index == OFNotFound)
		return 0;

	return identifier.length - index;
}

- (void)addDependenciesFromMethod:(OGTKMethod *)method to:(OGTKClass *)classInfo
{
	OFString *strippedReturnType = [self stripAsterisks:method.cReturnType];

	if ([self isTypeSwappable:strippedReturnType] &&
	    ![strippedReturnType isEqual:classInfo.cType])
		[classInfo addDependency:strippedReturnType];

	for (OGTKParameter *parameter in method.parameters) {
		OFString *strippedParameterCType = [self stripAsterisks:parameter.cType];

		if ([self isTypeSwappable:strippedParameterCType] &&
		    ![strippedParameterCType isEqual:classInfo.cType])
			[classInfo addDependency:strippedParameterCType];
	}
}

- (void)walkDependencyTreeFrom:(OGTKClass *)classInfo usingStack:(OFMutableDictionary *)stack
{
	if (classInfo.visited) {
		// OFLog(@"Class %@ aleady visited. Skipping…",
		// classInfo.cType);
		return;
	}

	// OFLog(@"Visiting class: %@.", classInfo.cType);
	classInfo.visited = true;

	// First follow parent classes - traverse to the topmost tree element
	OGTKClass *parentClassInfo = nil;

	if (classInfo.cParentType != nil)
		parentClassInfo = [_gobjTypeToClassMapping objectForKey:classInfo.cParentType];

	if (parentClassInfo != nil && [stack objectForKey:classInfo.cParentType] == nil) {

		[stack setObject:@"1" forKey:classInfo.cParentType];
		[self walkDependencyTreeFrom:parentClassInfo usingStack:stack];

		if (parentClassInfo.derivedFromInitiallyUnowned)
			classInfo.derivedFromInitiallyUnowned = true;

	} else if (parentClassInfo == nil) {
		// OFLog(@"Marked class %@ as topmost node. Parent cType is
		// %@.",
		//     classInfo.cName, classInfo.cParentType);
		classInfo.topMostGraphNode = true;

		if ([classInfo.cParentType isEqual:@"GInitiallyUnowned"])
			classInfo.derivedFromInitiallyUnowned = true;
	}

	// OFLog(@"Checking dependencies of %@.", classInfo.cType);
	// Then start to follow dependencies - leave out parent classes this
	// time
	for (OFString *dependencyGobjName in classInfo.dependsOnClasses) {

		// Add a forward declaration if the dependency is not the parent
		// class - we don't need an "#import" then
		if (![classInfo.cParentType isEqual:dependencyGobjName]) {

			[classInfo addForwardDeclarationForClass:dependencyGobjName];
		}

		OGTKClass *dependencyClassInfo =
		    [_gobjTypeToClassMapping objectForKey:dependencyGobjName];

		if (dependencyClassInfo == nil)
			continue;

		// We got a dependency to follow, so we are ready to visit that
		// dependency and follow its dependencies
		[stack setObject:@"1" forKey:dependencyGobjName];

		[self walkDependencyTreeFrom:dependencyClassInfo usingStack:stack];
	}

	[classInfo removeForwardDeclarationsFromDependencies];
}

#pragma mark - Shortcuts for singleton access

+ (OFString *)swapTypes:(OFString *)type
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper swapTypes:type];
}

+ (bool)isTypeSwappable:(OFString *)type
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper isTypeSwappable:type];
}

+ (bool)isGobjType:(OFString *)type
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper isGobjType:type];
}

+ (bool)isObjcType:(OFString *)type
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper isObjcType:type];
}

+ (OFString *)convertType:(OFString *)fromType withName:(OFString *)name toType:(OFString *)toType
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper convertType:fromType
	                        withName:name
	                          toType:toType
	                       ownership:GIRReturnValueOwnershipUnknown];
}

+ (OFString *)convertType:(OFString *)fromType
                 withName:(OFString *)name
                   toType:(OFString *)toType
                ownership:(GIROwnershipTransferType)ownership
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper convertType:fromType withName:name toType:toType ownership:ownership];
}

+ (OFString *)selfTypeMethodCall:(OFString *)type
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper selfTypeMethodCall:type];
}

+ (OFString *)getCTypeFromName:(OFString *)name
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper getCTypeFromName:name];
}

+ (OGTKClass *)classInfoByGobjType:(OFString *)gobjType
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper classInfoByGobjType:gobjType];
}

+ (OGTKLibrary *)libraryInfoByNamespace:(OFString *)libNamespace
{
	OGTKMapper *sharedMapper = [OGTKMapper sharedMapper];

	return [sharedMapper libraryInfoByNamespace:libNamespace];
}

@end
