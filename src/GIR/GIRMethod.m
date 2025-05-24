/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRMethod.h"

@implementation GIRMethod

@synthesize name = _name;
@synthesize cIdentifier = _cIdentifier;
@synthesize version = _version;
@synthesize glibGetForProperty = _glibGetForProperty;
@synthesize glibSetForProperty = _glibSetForProperty;
@synthesize returnValue = _returnValue;
@synthesize doc = _doc;
@synthesize docDeprecated = _docDeprecated;
@synthesize deprecated = _deprecated;
@synthesize deprecatedVersion = _deprecatedVersion;
@synthesize invoker = _invoker;
@synthesize throws = _throws;
@synthesize introspectable = _introspectable;
@synthesize shadowedBy = _shadowedBy;
@synthesize shadows = _shadows;
@synthesize parameters = _parameters;
@synthesize instanceParameter = _instanceParameter;

- (instancetype)init
{
	self = [super init];

	@try {
		_elementTypeName = @"GIRMethod";
		_parameters = [[OFMutableArray alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_cIdentifier release];
	[_version release];
	[_glibGetForProperty release];
	[_glibSetForProperty release];
	[_returnValue release];
	[_deprecatedVersion release];
	[_invoker release];
	[_doc release];
	[_docDeprecated release];
	[_parameters release];
	[_instanceParameter release];

	[super dealloc];
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];

		if (![self tryParseWithKey:key andValue:value]) {
			[self logUnknownElement:key];
		}
	}
}

- (bool)tryParseWithKey:(OFString *)key andValue:(id)value
{
	// TODO: Use async parameters for async/block API
	if ([key isEqual:@"text"] || [key isEqual:@"source-position"] ||
	    [key isEqual:@"moved-to"] || [key isEqual:@"doc-version"] ||
	    [key isEqual:@"glib:finish-func"] || [key isEqual:@"glib:async-func"] ||
	    [key isEqual:@"glib:sync-func"]) {
		// Do nothing
	} else if ([key isEqual:@"name"]) {
		self.name = value;
	} else if ([key isEqual:@"c:identifier"]) {
		self.cIdentifier = value;
	} else if ([key isEqual:@"version"]) {
		self.version = value;

		// TODO Use attribute to define for which property this is a
		// getter or setter?
	} else if ([key isEqual:@"attribute"]) {
		// Do nothing right now.
	} else if ([key isEqual:@"glib:get-property"]) {
		self.glibGetForProperty = value;
	} else if ([key isEqual:@"glib:set-property"]) {
		self.glibSetForProperty = value;
	} else if ([key isEqual:@"return-value"]) {
		self.returnValue = [[[GIRReturnValue alloc] initWithDictionary:value] autorelease];
	} else if ([key isEqual:@"doc"]) {
		self.doc = [[[GIRDoc alloc] initWithDictionary:value] autorelease];
	} else if ([key isEqual:@"doc-deprecated"]) {
		self.docDeprecated = [[[GIRDoc alloc] initWithDictionary:value] autorelease];
	} else if ([key isEqual:@"deprecated"]) {
		self.deprecated = [value isEqual:@"1"];
	} else if ([key isEqual:@"deprecated-version"]) {
		self.deprecatedVersion = value;
	} else if ([key isEqual:@"invoker"]) {
		self.invoker = value;
	} else if ([key isEqual:@"throws"]) {
		self.throws = [value isEqual:@"1"];
	} else if ([key isEqual:@"introspectable"]) {
		self.introspectable = [value isEqual:@"1"];
	} else if ([key isEqual:@"shadowed-by"]) {
		self.shadowedBy = [value isEqual:@"1"];
	} else if ([key isEqual:@"shadows"]) {
		self.shadows = [value isEqual:@"1"];
	} else if ([key isEqual:@"parameters"]) {
		for (OFString *paramKey in value) {
			if ([paramKey isEqual:@"parameter"]) {
				[self processArrayOrDictionary:[value objectForKey:paramKey]
				                     withClass:[GIRParameter class]
				                      andArray:_parameters];
			} else if ([paramKey isEqual:@"instance-parameter"]) {
				self.instanceParameter = [[[GIRParameter alloc]
				    initWithDictionary:[value objectForKey:paramKey]] autorelease];
			}
		}
	} else {
		return false;
	}

	return true;
}

@end
