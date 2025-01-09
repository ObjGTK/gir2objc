/*
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2021-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "OGTKLibrary.h"

@interface OGTKLibrary ()

- (OFArray *)splitVersion:(OFString *)versionString;

@end

@implementation OGTKLibrary
@synthesize namespace = _namespace, name = _name, version = _version, packages = _packages,
            authorMail = _authorMail, dependencies = _dependencies, cIncludes = _cIncludes,
            sharedLibraries = _sharedLibraries, excludeClasses = _excludeClasses,
            cNSIdentifierPrefix = _cNSIdentifierPrefix, cNSSymbolPrefix = _cNSSymbolPrefix,
            visited = _visited, hasAdditionalSourceFiles = _hasAdditionalSourceFiles;

- (instancetype)init
{
	self = [super init];

	@try {
		_dependencies = [[OFMutableSet alloc] init];
		_cIncludes = [[OFMutableSet alloc] init];
		_sharedLibraries = [[OFSet alloc] init];
		_visited = false;
		_hasAdditionalSourceFiles = true;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_namespace release];
	[_name release];
	[_version release];
	[_packages release];
	[_authorMail release];
	[_dependencies release];
	[_cIncludes release];
	[_sharedLibraries release];
	[_excludeClasses release];
	[_cNSIdentifierPrefix release];
	[_cNSSymbolPrefix release];

	[super dealloc];
}

- (OFString *)identifier
{
	if (_namespace == nil || _version == nil)
		return nil;

	return [OFString stringWithFormat:@"%@-%@", _namespace, _version];
}

- (OFString *)name
{
	if (_name != nil)
		return _name;

	return [OFString stringWithFormat:@"OG%@", _namespace];
}

- (OFString *)versionMinor
{
	return [[self splitVersion:_version] lastObject];
}

- (OFString *)versionMajor
{
	return [[self splitVersion:_version] firstObject];
}

- (OFArray *)splitVersion:(OFString *)versionString
{
	OFArray *versionParts = [versionString componentsSeparatedByString:@"."];

	OFString *versionMajor = versionParts.firstObject;

	OFMutableString *versionMinor = [[[OFMutableString alloc] init] autorelease];

	if (versionParts.count == 2)
		versionMinor = versionParts.lastObject;

	if (versionParts.count > 2) {
		for (size_t i = 1; i < versionParts.count; i++) {
			[versionMinor appendString:[versionParts objectAtIndex:i]];

			if (versionParts.count + 1 > i)
				[versionMinor appendString:@"."];
		}
	}

	OFArray *result =
	    [[[OFArray alloc] initWithObjects:versionMajor, versionMinor, nil] autorelease];

	return result;
}

- (void)addSharedLibrariesAsString:(OFString *)sharedLibrariesString
{
	OFSet *sharedLibrariesSet =
	    [OFSet setWithArray:[sharedLibrariesString componentsSeparatedByString:@","]];

	OFSet *sharedLibrariesResult =
	    [_sharedLibraries setByAddingObjectsFromSet:sharedLibrariesSet];

	[_sharedLibraries release];

	_sharedLibraries = [sharedLibrariesResult retain];
}

- (void)addDependency:(GIRInclude *)dependency
{
	[_dependencies addObject:dependency];
}

- (void)addCInclude:(GIRInclude *)cInclude
{
	[_cIncludes addObject:cInclude];
}

@end
