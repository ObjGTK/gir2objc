/*
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2021-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "OGTKTemplate.h"
#import "../Exceptions/OGTKReceivedNilExpectedStringException.h"
#import "OGTKClass.h"
#import "OGTKMapper.h"

@interface OGTKTemplate ()

- (OFString *)ACSnippetsForDependencies:(OFMutableSet OF_GENERIC(GIRInclude *) *)dependencies
                        forLibraryNamed:(OFString *)parentLibName;

- (OFString *)ACSnippetForIncludesOf:(OFString *)dependencyName
                     forLibraryNamed:(OFString *)parentLibName;

- (OFString *)ACSnippetForPackage:(OFString *)dependencyName
                  forLibraryNamed:(OFString *)parentLibName;

- (OFString *)shortNameFromPackageName:(OFString *)packageName;

@end

@implementation OGTKTemplate

@synthesize snippetDir = _snippetDir, sharedMapper = _sharedMapper;

OFString *const kACArgWithTemplateFile = @"acargwith.tmpl";
OFString *const kACOCCheckingTemplateFile = @"acocchecking.tmpl";
OFString *const kPkgCheckModulesTemplateFile = @"pkgcheckmodules.tmpl";

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithSnippetDir:(OFString *)snippetDir sharedMapper:(OGTKMapper *)sharedMapper
{
	self = [super init];

	@try {
		if (snippetDir == nil || sharedMapper == nil)
			@throw [OFInvalidArgumentException exception];

		_snippetDir = [snippetDir copy];
		_sharedMapper = [sharedMapper retain];

	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_snippetDir release];
	[_sharedMapper release];

	[super dealloc];
}

- (OFDictionary *)dictWithReplaceValuesForBuildFilesOfLibrary:(OGTKLibrary *)libraryInfo
                                                  sourceFiles:(OFString *)sourceFiles
{
	OFString *authorMail;
	if (libraryInfo.authorMail != nil)
		authorMail = libraryInfo.authorMail;
	else
		authorMail = @"unkown@host.com";

	OFString *acOCChecking = [self ACSnippetsForDependencies:libraryInfo.dependencies
	                                         forLibraryNamed:libraryInfo.name];

	OFMutableString *acArgWith = [OFMutableString string];
	OFMutableString *pkgCheckModules = [OFMutableString string];
	for (OFString *packageName in libraryInfo.packages.allObjects.sortedArray) {
		[pkgCheckModules appendString:@"\n\n"];
		[pkgCheckModules appendString:[self ACSnippetForPackage:packageName
		                                        forLibraryNamed:libraryInfo.name]];

		[acArgWith appendString:@"\n\n"];
		[acArgWith appendString:[self ACSnippetForIncludesOf:packageName
		                                     forLibraryNamed:libraryInfo.name]];
	}

	OFString *ocDependencies = [self OCDependenciesFor:libraryInfo.dependencies];

	OFDictionary *dict = [OFDictionary
	    dictionaryWithKeysAndObjects:@"%%LIBNAME%%", libraryInfo.name, @"%%LIBVERSION%%",
	    libraryInfo.version, @"%%LIBAUTHOREMAIL%%", authorMail, @"%%UCLIBNAME%%",
	    [libraryInfo.name uppercaseString], @"%%LCLIBNAME%%",
	    [libraryInfo.name lowercaseString], @"%%VERSIONLIBMAJOR%%", libraryInfo.versionMajor,
	    @"%%VERSIONLIBMINOR%%", libraryInfo.versionMinor, @"%%ACOCCHECKING%%", acOCChecking,
	    @"%%ACARGWITH%%", acArgWith, @"%%PKGCHECKMODULES%%", pkgCheckModules,
	    @"%%OCDEPENDENCIES%%", ocDependencies, @"%%SOURCEFILES%%", sourceFiles, nil];

	return dict;
}

- (OFDictionary *)dictWithRenamesForBuildFilesOfLibrary:(OGTKLibrary *)libraryInfo
{
	OFDictionary *dict =
	    [OFDictionary dictionaryWithKeysAndObjects:@"Template.oc.in",
	                  [OFString stringWithFormat:@"%@.oc.in", libraryInfo.name], nil];

	return dict;
}

- (OFString *)ACSnippetsForDependencies:(OFMutableSet OF_GENERIC(GIRInclude *) *)dependencies
                        forLibraryNamed:(OFString *)parentLibName
{
	OFString *fileName =
	    [self.snippetDir stringByAppendingPathComponent:kACOCCheckingTemplateFile];

	OFMutableString *result = [OFMutableString string];

	for (GIRInclude *dependency in dependencies.allObjects.sortedArray) {
		OFString *objfwPackageSnippet = [OFString stringWithContentsOfFile:fileName];

		OGTKLibrary *libraryInfo =
		    [self.sharedMapper libraryInfoByNamespace:dependency.name];

		if (libraryInfo == nil)
			continue;

		OFString *libraryName = libraryInfo.name;

		objfwPackageSnippet =
		    [objfwPackageSnippet stringByReplacingOccurrencesOfString:@"%%DEPNAME%%"
		                                                   withString:libraryName];

		objfwPackageSnippet = [objfwPackageSnippet
		    stringByReplacingOccurrencesOfString:@"%%LIBNAME%%"
		                              withString:[parentLibName uppercaseString]];

		[result appendString:objfwPackageSnippet];
		[result appendString:@"\n\n"];
	}

	[result deleteEnclosingWhitespaces];
	[result makeImmutable];

	return result;
}

- (OFString *)OCDependenciesFor:(OFMutableSet OF_GENERIC(GIRInclude *) *)dependencies
{
	OFMutableString *result = [OFMutableString string];

	for (GIRInclude *dependency in dependencies.allObjects.sortedArray) {
		OGTKLibrary *libraryInfo =
		    [self.sharedMapper libraryInfoByNamespace:dependency.name];

		if (libraryInfo == nil)
			continue;

		[result appendFormat:@"package_depends_on %@\n", libraryInfo.name];
	}

	[result makeImmutable];
	return result;
}

- (OFString *)ACSnippetForIncludesOf:(OFString *)packageName forLibraryNamed:(OFString *)libName
{
	if (packageName == nil)
		@throw
		    [OGTKReceivedNilExpectedStringException exceptionForParameter:@"packageName"];
	if (libName == nil)
		@throw [OGTKReceivedNilExpectedStringException exceptionForParameter:@"libName"];

	OFString *fileName =
	    [self.snippetDir stringByAppendingPathComponent:kACArgWithTemplateFile];
	OFMutableString *snippet = [OFMutableString stringWithContentsOfFile:fileName];

	OFString *shortName = [self shortNameFromPackageName:packageName];
	libName = [libName uppercaseString];

	[snippet replaceOccurrencesOfString:@"%%DEPNAME%%" withString:packageName];

	[snippet replaceOccurrencesOfString:@"%%LCDEPNAME%%"
	                         withString:[shortName lowercaseString]];

	[snippet replaceOccurrencesOfString:@"%%UCDEPNAME%%"
	                         withString:[shortName uppercaseString]];

	[snippet replaceOccurrencesOfString:@"%%LIBNAME%%" withString:libName];

	[snippet makeImmutable];

	return snippet;
}

- (OFString *)ACSnippetForPackage:(OFString *)dependencyName
                  forLibraryNamed:(OFString *)parentLibName
{
	OFString *fileName =
	    [self.snippetDir stringByAppendingPathComponent:kPkgCheckModulesTemplateFile];
	OFMutableString *snippet = [OFMutableString stringWithContentsOfFile:fileName];

	OFString *shortName = [self shortNameFromPackageName:dependencyName];
	parentLibName = [parentLibName uppercaseString];

	[snippet replaceOccurrencesOfString:@"%%LCPKGNAME%%"
	                         withString:[shortName lowercaseString]];

	[snippet replaceOccurrencesOfString:@"%%PKGNAME%%" withString:dependencyName];

	[snippet
	    replaceOccurrencesOfString:@"%%PKGVERSION%%"
	                    withString:[OFString stringWithFormat:@"$(pkg-config --modversion %@)",
	                                         dependencyName]];

	[snippet replaceOccurrencesOfString:@"%%LIBNAME%%" withString:parentLibName];

	[snippet makeImmutable];

	return snippet;
}

- (OFString *)shortNameFromPackageName:(OFString *)packageName
{
	OFCharacterSet *charSet =
	    [OFCharacterSet characterSetWithCharactersInString:@"+0123456789"];
	OFRange range = [packageName rangeOfCharacterFromSet:charSet];

	OFMutableString *shortName;
	if (range.location != OFNotFound) {
		shortName =
		    [OFMutableString stringWithString:[packageName substringToIndex:range.location]];
		[shortName replaceOccurrencesOfString:@"-" withString:@""];
		[shortName replaceOccurrencesOfString:@"_" withString:@""];
	} else
		return packageName;

	[shortName makeImmutable];

	return shortName;
}

@end
