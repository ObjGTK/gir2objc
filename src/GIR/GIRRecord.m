/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2025 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2025 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRRecord.h"

@implementation GIRRecord

@synthesize doc = _doc, name = _name, cType = _cType, opaque = _opaque, pointer = _pointer,
            glibTypeName = _glibTypeName, glibGetType = _glibGetType,
            cSymbolPrefix = _cSymbolPrefix, foreign = _foreign,
            glibIsGtypeStructFor = _glibIsGtypeStructFor, nameOfCopyFunction = _nameOfCopyFunction,
            nameOfFreeFunction = _nameOfFreeFunction, fields = _fields, functions = _functions,
            methods = _methods, constructors = _constructors;

- (instancetype)init
{
	self = [super init];

	@try {
		_elementTypeName = @"GIRRecord";
		_fields = [[OFMutableArray alloc] init];
		_functions = [[OFMutableArray alloc] init];
		_methods = [[OFMutableArray alloc] init];
		_constructors = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_doc release];
	[_name release];
	[_cType release];
	[_cType release];
	[_glibTypeName release];
	[_glibGetType release];
	[_cSymbolPrefix release];
	[_glibIsGtypeStructFor release];
	[_nameOfCopyFunction release];
	[_nameOfFreeFunction release];

	[_fields release];
	[_functions release];
	[_methods release];
	[_constructors release];

	[super dealloc];
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];
		if ([key isEqual:@"text"] || [key isEqual:@"source-position"] ||
		    [key isEqual:@"disguised"] || [key isEqual:@"deprecated"] ||
		    [key isEqual:@"deprecated-version"] || [key isEqual:@"version"] ||
		    [key isEqual:@"doc-deprecated"] || [key isEqual:@"functioninline"] ||
		    [key isEqual:@"functioninline"] || [key isEqual:@"union"] ||
		    [key isEqual:@"methodinline"]) {
			// Do nothing
		} else if ([key isEqual:@"doc"]) {
			self.doc = [[[GIRDoc alloc] initWithDictionary:value] autorelease];
		} else if ([key isEqual:@"name"]) {
			self.name = value;
		} else if ([key isEqual:@"c:type"]) {
			self.cType = value;
		} else if ([key isEqual:@"opaque"]) {
			self.opaque = [value isEqual:@"1"];
		} else if ([key isEqual:@"pointer"]) {
			self.pointer = [value isEqual:@"1"];
		} else if ([key isEqual:@"glib:type-name"]) {
			self.glibTypeName = value;
		} else if ([key isEqual:@"glib:get-type"]) {
			self.glibGetType = value;
		} else if ([key isEqual:@"c:symbol-prefix"]) {
			self.cSymbolPrefix = value;
		} else if ([key isEqual:@"foreign"]) {
			self.foreign = [value isEqual:@"1"];
		} else if ([key isEqual:@"glib:is-gtype-struct-for"]) {
			self.glibIsGtypeStructFor = value;
		} else if ([key isEqual:@"copyFunction"]) {
			self.nameOfCopyFunction = value;
		} else if ([key isEqual:@"freeFunction"]) {
			self.nameOfFreeFunction = value;
		} else if ([key isEqual:@"constructor"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRConstructor class]
			                      andArray:_constructors];
		} else if ([key isEqual:@"field"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRField class]
			                      andArray:_fields];
		} else if ([key isEqual:@"method"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRMethod class]
			                      andArray:_methods];
		} else if ([key isEqual:@"function"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRFunction class]
			                      andArray:_functions];
		} else {
			[self logUnknownElement:key];
		}
	}
}

@end
