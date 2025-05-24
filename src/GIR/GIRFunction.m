/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRFunction.h"

@implementation GIRFunction

@synthesize name = _name;
@synthesize cIdentifier = _cIdentifier;
@synthesize movedTo = _movedTo;
@synthesize version = _version;
@synthesize introspectable = _introspectable;
@synthesize deprecated = _deprecated;
@synthesize deprecatedVersion = _deprecatedVersion;
@synthesize throws = _throws;
@synthesize docDeprecated = _docDeprecated;
@synthesize doc = _doc;
@synthesize returnValue = _returnValue;
@synthesize parameters = _parameters;
@synthesize instanceParameter = _instanceParameter;

- (id)init
{
	self = [super init];

	@try {
		_elementTypeName = @"GIRFunction";
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
	[_movedTo release];
	[_version release];
	[_deprecatedVersion release];
	[_docDeprecated release];
	[_doc release];
	[_returnValue release];
	[_parameters release];
	[_instanceParameter release];

	[super dealloc];
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];

		if ([key isEqual:@"text"] || [key isEqual:@"source-position"] ||
		    [key isEqual:@"shadowed-by"] || [key isEqual:@"shadows"] ||
		    [key isEqual:@"doc-version"] || [key isEqual:@"glib:finish-func"] ||
		    [key isEqual:@"glib:async-func"] || [key isEqual:@"glib:sync-func"]) {
			// Do nothing
		} else if ([key isEqual:@"name"]) {
			self.name = value;
		} else if ([key isEqual:@"c:identifier"]) {
			self.cIdentifier = value;
		} else if ([key isEqual:@"moved-to"]) {
			self.movedTo = value;
		} else if ([key isEqual:@"version"]) {
			self.version = value;
		} else if ([key isEqual:@"introspectable"]) {
			self.introspectable = [value isEqual:@"1"];
		} else if ([key isEqual:@"deprecated"]) {
			self.deprecated = [value isEqual:@"1"];
		} else if ([key isEqual:@"deprecated-version"]) {
			self.deprecatedVersion = value;
		} else if ([key isEqual:@"throws"]) {
			self.throws = [value isEqual:@"1"];
		} else if ([key isEqual:@"doc-deprecated"]) {
			self.doc = [[[GIRDoc alloc] initWithDictionary:value] autorelease];
		} else if ([key isEqual:@"doc"]) {
			self.doc = [[[GIRDoc alloc] initWithDictionary:value] autorelease];
		} else if ([key isEqual:@"return-value"]) {
			self.returnValue =
			    [[[GIRReturnValue alloc] initWithDictionary:value] autorelease];
		} else if ([key isEqual:@"parameters"]) {
			for (OFString *paramKey in value) {
				if ([paramKey isEqual:@"parameter"]) {
					[self processArrayOrDictionary:[value objectForKey:paramKey]
					                     withClass:[GIRParameter class]
					                      andArray:_parameters];
				} else if ([paramKey isEqual:@"instance-parameter"]) {
					self.instanceParameter = [[[GIRParameter alloc]
					    initWithDictionary:[value objectForKey:paramKey]]
					    autorelease];
				}
			}
		} else {
			[self logUnknownElement:key];
		}
	}
}

@end
