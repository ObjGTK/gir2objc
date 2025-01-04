/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKMethod.h"
#import <ObjFW/ObjFW.h>

/**
 * Abstracts Class operations
 */
@interface OGTKClass: OFObject
{
	OFString *_cName;
	OFString *_cType;
	OFString *_namespace;
	OFString *_parentName;
	OFString *_cParentType;
	OFString *_cSymbolPrefix;
	OFString *_cNSSymbolPrefix;
	OFString *_cNSIdentifierPrefix;
	OFString *_documentation;
	OFMutableArray *_constructors;
	OFMutableArray *_functions;
	OFMutableArray *_methods;
	OFMutableSet *_dependsOnClasses;
	OFMutableSet *_forwardDeclarationForClasses;
	bool _visited;
	bool _topMostGraphNode;
	bool _derivedFromInitiallyUnowned;
}

@property (copy, nonatomic) OFString *cName;
@property (copy, nonatomic) OFString *cType;
@property (copy, nonatomic) OFString *namespace;
@property (readonly, nonatomic) OFString *type;
@property (copy, nonatomic) OFString *parentName;
@property (copy, nonatomic) OFString *cParentType;
@property (copy, nonatomic) OFString *cSymbolPrefix;
@property (copy, nonatomic) OFString *cNSSymbolPrefix;
@property (copy, nonatomic) OFString *cNSIdentifierPrefix;
@property (copy, nonatomic) OFString *documentation;
@property (readonly, nonatomic) OFArray *constructors;
@property (readonly, nonatomic) bool hasConstructors;
@property (readonly, nonatomic) OFArray *functions;
@property (readonly, nonatomic) bool hasFunctions;
@property (readonly, nonatomic) OFArray *methods;
@property (readonly, nonatomic) bool hasMethods;
@property (readonly, nonatomic) OFMutableSet *dependsOnClasses;
@property (readonly, nonatomic) OFMutableSet *forwardDeclarationForClasses;
@property bool visited;
@property bool topMostGraphNode;
@property bool derivedFromInitiallyUnowned;

/**
 * @brief      Return the Gobject cast macro for this class
 */
- (OFString *)castGObjectMacro:(OFString *)variableName;
- (void)addConstructor:(OGTKMethod *)ctor;
- (void)addFunction:(OGTKMethod *)fun;
- (void)addMethod:(OGTKMethod *)meth;
- (void)addDependency:(OFString *)cType;
- (void)removeForwardDeclarationsFromDependencies;
- (OFComparisonResult)compare:(OGTKClass *)otherClass;
- (void)addForwardDeclarationForClass:(OFString *)cType;

@end
