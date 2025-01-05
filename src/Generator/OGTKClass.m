/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKClass.h"
#import "../Exceptions/OGTKReceivedNilExpectedStringException.h"

@implementation OGTKClass
@synthesize cName = _cName, cType = _cType, namespace = _namespace, parentName = _parentName,
            cParentType = _cParentType, cSymbolPrefix = _cSymbolPrefix,
            cNSSymbolPrefix = _cNSSymbolPrefix, cNSIdentifierPrefix = _cNSIdentifierPrefix,
            documentation = _documentation, dependsOnClasses = _dependsOnClasses,
            forwardDeclarationForClasses = _forwardDeclarationForClasses, visited = _visited,
            topMostGraphNode = _topMostGraphNode,
            derivedFromInitiallyUnowned = _derivedFromInitiallyUnowned;

- (instancetype)init
{
	self = [super init];

	@try {
		_constructors = [[OFMutableArray alloc] init];
		_functions = [[OFMutableArray alloc] init];
		_methods = [[OFMutableArray alloc] init];
		_dependsOnClasses = [[OFMutableSet alloc] init];
		_forwardDeclarationForClasses = [[OFMutableSet alloc] init];
		_visited = false;
		_topMostGraphNode = false;
		_derivedFromInitiallyUnowned = false;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_cName release];
	[_cType release];
	[_namespace release];
	[_parentName release];
	[_cParentType release];
	[_cSymbolPrefix release];
	[_cNSIdentifierPrefix release];
	[_cNSSymbolPrefix release];
	[_documentation release];
	[_constructors release];
	[_functions release];
	[_methods release];
	[_dependsOnClasses release];
	[_forwardDeclarationForClasses release];

	[super dealloc];
}

- (OFString *)type
{
	if (self.cType == nil)
		@throw [OGTKReceivedNilExpectedStringException exception];

	if ([self.cNSIdentifierPrefix isEqual:@"Gtk"] && [self.cType hasPrefix:@"Gtk"])
		return [OFString stringWithFormat:@"OGTK%@", _cName];

	if ([self.cNSIdentifierPrefix hasPrefix:@"G"] && [self.cType hasPrefix:@"G"])
		return [OFString stringWithFormat:@"O%@", self.cType];

	return [OFString stringWithFormat:@"OG%@", self.cType];
}

- (OFString *)gTypeMacro
{
	return [OFString stringWithFormat:@"%@_TYPE_%@", self.cNSIdentifierPrefix.uppercaseString,
	    self.cSymbolPrefix.uppercaseString];
}

- (OFString *)castGObjectMacro:(OFString *)variableName
{
	return [OFString stringWithFormat:@"G_TYPE_CHECK_INSTANCE_CAST(%@, %@, %@)", variableName,
	    _cType, _cType];
}

- (void)addConstructor:(OGTKMethod *)constructor
{
	if (constructor != nil) {
		[_constructors addObject:constructor];
	}
}

- (OFArray *)constructors
{
	return [[_constructors copy] autorelease];
}

- (bool)hasConstructors
{
	return (_constructors.count > 0);
}

- (void)addFunction:(OGTKMethod *)function
{
	if (function != nil) {
		[_functions addObject:function];
	}
}

- (void)addDependency:(OFString *)cType
{
	[_dependsOnClasses addObject:cType];
}

- (void)removeForwardDeclarationsFromDependencies
{
	[_dependsOnClasses minusSet:_forwardDeclarationForClasses];
}

- (OFComparisonResult)compare:(OGTKClass *)otherClass
{
	return [self.type compare:otherClass.type];
}

- (void)addForwardDeclarationForClass:(OFString *)cType
{
	[_forwardDeclarationForClasses addObject:cType];
}

- (OFArray *)functions
{
	return [[_functions copy] autorelease];
}

- (bool)hasFunctions
{
	return (_functions.count > 0);
}

- (void)addMethod:(OGTKMethod *)method
{
	if (method != nil) {
		[_methods addObject:method];
	}
}

- (OFArray *)methods
{
	return [[_methods copy] autorelease];
}

- (bool)hasMethods
{
	return (_methods.count > 0);
}

@end
