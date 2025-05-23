/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRNamespace.h"

@implementation GIRNamespace

@synthesize name = _name, version = _version, sharedLibrary = _sharedLibrary,
            cSymbolPrefixes = _cSymbolPrefixes, cIdentifierPrefixes = _cIdentifierPrefixes,
            classes = _classes, functions = _functions, enumerations = _enumerations,
            constants = _constants, interfaces = _interfaces;

- (instancetype)init
{
	self = [super init];

	@try {
		_elementTypeName = @"GIRNamespace";
		_classes = [[OFMutableArray alloc] init];
		_functions = [[OFMutableArray alloc] init];
		_enumerations = [[OFMutableArray alloc] init];
		_constants = [[OFMutableArray alloc] init];
		_interfaces = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_version release];
	[_sharedLibrary release];
	[_cSymbolPrefixes release];
	[_cIdentifierPrefixes release];
	[_classes release];
	[_functions release];
	[_enumerations release];
	[_constants release];
	[_interfaces release];

	[super dealloc];
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];

		if ([key isEqual:@"text"] || [key isEqual:@"callback"] ||
		    [key isEqual:@"bitfield"] || [key isEqual:@"alias"] ||
		    [key isEqual:@"function-macro"] || [key isEqual:@"docsection"] ||
		    [key isEqual:@"union"] || [key isEqual:@"c:prefix"]) {
			// Do nothing
		} else if ([key isEqual:@"name"]) {
			self.name = value;
		} else if ([key isEqual:@"version"]) {
			self.version = value;
		} else if ([key isEqual:@"shared-library"]) {
			self.sharedLibrary = value;
		} else if ([key isEqual:@"c:symbol-prefixes"]) {
			self.cSymbolPrefixes = value;
		} else if ([key isEqual:@"c:identifier-prefixes"]) {
			self.cIdentifierPrefixes = value;
		} else if ([key isEqual:@"class"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRClass class]
			                      andArray:_classes];
		} else if ([key isEqual:@"record"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRRecord class]
			                      andArray:_classes];
		} else if ([key isEqual:@"function"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRFunction class]
			                      andArray:_functions];
		} else if ([key isEqual:@"enumeration"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIREnumeration class]
			                      andArray:_enumerations];
		} else if ([key isEqual:@"constant"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRConstant class]
			                      andArray:_constants];
		} else if ([key isEqual:@"interface"]) {
			[self processArrayOrDictionary:value
			                     withClass:[GIRInterface class]
			                      andArray:_interfaces];
		} else if ([key isEqual:@"glib:boxed"]) {
			// TODO: This is important for memory managemant and needs to be handled
		} else {
			[self logUnknownElement:key];
		}
	}
}

@end
