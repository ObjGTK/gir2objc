/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "GIRField.h"

@implementation GIRField

@synthesize name = _name;
@synthesize isPrivate = _isPrivate;
@synthesize readable = _readable;
@synthesize bits = _bits;
@synthesize type = _type;
@synthesize array = _array;

- (instancetype)init
{
	self = [super init];

	_elementTypeName = @"GIRField";

	return self;
}

- (void)parseDictionary:(OFDictionary *)dict
{
	for (OFString *key in dict) {
		id value = [dict objectForKey:key];

		if ([key isEqual:@"text"] || [key isEqual:@"doc"] || [key isEqual:@"callback"] ||
		    [key isEqual:@"introspectable"]) {
			// Do nothing
		} else if ([key isEqual:@"name"]) {
			self.name = value;
		} else if ([key isEqual:@"private"]) {
			self.isPrivate = [value isEqual:@"1"];
		} else if ([key isEqual:@"readable"]) {
			self.readable = [value isEqual:@"1"];
		} else if ([key isEqual:@"writable"]) {
			self.writable = [value isEqual:@"1"];
		} else if ([key isEqual:@"bits"]) {
			self.bits = [value longLongValue];
		} else if ([key isEqual:@"type"]) {
			self.type = [[[GIRType alloc] initWithDictionary:value] autorelease];
		} else if ([key isEqual:@"array"]) {
			self.array = [[[GIRArray alloc] initWithDictionary:value] autorelease];
		} else {
			[self logUnknownElement:key];
		}
	}
}

- (void)dealloc
{
	[_name release];
	[_type release];
	[_array release];

	[super dealloc];
}

@end
