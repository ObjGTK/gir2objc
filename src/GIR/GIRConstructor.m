/*
 * GIRConstructor.m
 * This file is part of ObjGTK
 *
 * Copyright (C) 2017 - Tyler Burton
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/*
 * Modified by the ObjGTK Team, 2021. See the AUTHORS file for a
 * list of people on the ObjGTK Team.
 * See the ChangeLog files for a list of changes.
 */

#import "GIRConstructor.h"

@implementation GIRConstructor

@synthesize name;
@synthesize cIdentifier;
@synthesize version;
@synthesize deprecatedVersion;
@synthesize shadowedBy;
@synthesize shadows;
@synthesize introspectable;
@synthesize deprecated;
@synthesize throws;
@synthesize doc;
@synthesize docDeprecated;
@synthesize returnValue;
@synthesize parameters;
@synthesize instanceParameters;

- (id)init
{
    self = [super init];

    elementTypeName = @"GIRConstructor";
    parameters = [[OFMutableArray alloc] init];

    return self;
}

- (id)initWithDictionary:(OFDictionary*)dict
{
    self = [self init];

    [self parseDictionary:dict];

    return self;
}

- (void)parseDictionary:(OFDictionary*)dict
{
    for (OFString* key in dict) {
        id value = [dict objectForKey:key];

        if ([key isEqual:@"text"] || [key isEqual:@"source-position"]) {
            // Do nothing
        } else if ([key isEqual:@"name"]) {
            self.name = value;
        } else if ([key isEqual:@"c:identifier"]) {
            self.cIdentifier = value;
        } else if ([key isEqual:@"version"]) {
            self.version = value;
        } else if ([key isEqual:@"deprecated-version"]) {
            self.deprecatedVersion = value;
        } else if ([key isEqual:@"shadowed-by"]) {
            self.shadowedBy = value;
        } else if ([key isEqual:@"shadows"]) {
            self.shadows = value;
        } else if ([key isEqual:@"introspectable"]) {
            self.introspectable = [value isEqual:@"1"];
        } else if ([key isEqual:@"deprecated"]) {
            self.deprecated = [value isEqual:@"1"];
        } else if ([key isEqual:@"throws"]) {
            self.throws = [value isEqual:@"1"];
        } else if ([key isEqual:@"doc"]) {
            self.doc = [[GIRDoc alloc] initWithDictionary:value];
        } else if ([key isEqual:@"doc-deprecated"]) {
            self.doc = [[GIRDoc alloc] initWithDictionary:value];
        } else if ([key isEqual:@"return-value"]) {
            self.returnValue =
                [[GIRReturnValue alloc] initWithDictionary:value];
        } else if ([key isEqual:@"parameters"]) {
            for (OFString* paramKey in value) {
                if ([paramKey isEqual:@"parameter"]) {
                    [self processArrayOrDictionary:[value objectForKey:paramKey]
                                         withClass:[GIRParameter class]
                                          andArray:parameters];
                } else if ([paramKey isEqual:@"instance-parameter"]) {
                    [self processArrayOrDictionary:[value objectForKey:paramKey]
                                         withClass:[GIRParameter class]
                                          andArray:instanceParameters];
                }
            }
        } else {
            [self logUnknownElement:key];
        }
    }
}

- (void)dealloc
{
    [name release];
    [cIdentifier release];
    [version release];
    [deprecatedVersion release];
    [shadowedBy release];
    [shadows release];
    [doc release];
    [docDeprecated release];
    [parameters release];
    [instanceParameters release];
    [super dealloc];
}

@end
