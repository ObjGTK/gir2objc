/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRInclude.h"

@implementation GIRInclude

@synthesize name = _name, version = _version;

- (id)init
{
	self = [super init];

	_elementTypeName = @"GIRInclude";

	return self;
}

- (void)dealloc
{
	[_name release];
	[_version release];

	[super dealloc];
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];

		if ([key isEqual:@"text"] || [key isEqual:@"type"] || [key isEqual:@"constant"] ||
		    [key isEqual:@"callback"]) {
			// Do nothing
		} else if ([key isEqual:@"name"]) {
			self.name = value;
		} else if ([key isEqual:@"version"]) {
			self.version = value;
		} else {
			[self logUnknownElement:key];
		}
	}
}

- (OFComparisonResult)compare:(GIRInclude *)otherInclude
{
	return [self.name compare:otherInclude.name];
}

@end