/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "OGTKLibraryWriter.h"
#import "../Exceptions/OGTKIncorrectConfigException.h"
#import "../GIR/GIRInclude.h"
#import "OGTKClass.h"
#import "OGTKClassWriter.h"
#import "OGTKLibrary.h"
#import "OGTKMapper.h"
#import "OGTKTemplate.h"
#include <sys/stat.h>

@implementation OGTKLibraryWriter

@synthesize libraryDescription = _libraryDescription, mapper = _mapper, outputDir = _outputDir;

+ (void)copyFilesFromDir:(OFString *)sourceDir
                            toDir:(OFString *)destDir
    applyOnFileContentMethodNamed:(OFString *)methodName
                 usingReplaceDict:(OFDictionary *)replaceDict
                  usingRenameDict:(OFDictionary *)renameDict
{
	OFFileManager *fileMgr = [OFFileManager defaultManager];

	if (![fileMgr directoryExistsAtPath:sourceDir])
		return;

	OFArray *srcDirContents = [fileMgr contentsOfDirectoryAtPath:sourceDir];

	for (OFString *srcFilePath in srcDirContents) {

		OFString *srcFile =
		    [sourceDir stringByAppendingPathComponent:[srcFilePath lastPathComponent]];

		// Rename source file while copying if rename information given
		OFString *destFileName = [srcFilePath lastPathComponent];
		if (renameDict != nil && [renameDict valueForKey:destFileName] != nil)
			destFileName = [renameDict valueForKey:destFileName];

		OFString *destFile = [destDir stringByAppendingPathComponent:destFileName];

		// src is a directory
		if ([fileMgr directoryExistsAtPath:srcFile]) {
			if (![fileMgr directoryExistsAtPath:destFile])
				[fileMgr createDirectoryAtPath:destFile];

			[self copyFilesFromDir:srcFile
			                            toDir:destFile
			    applyOnFileContentMethodNamed:methodName
			                 usingReplaceDict:replaceDict
			                  usingRenameDict:renameDict];

			continue;
		}

		// else: src is a file
		if ([fileMgr fileExistsAtPath:destFile]) {
			// OFLog(@"File [%@] already exists in destination [%@].
			// "
			//       @"Removing existing file...",
			//     srcFile, destFile);

			@try {
				[fileMgr removeItemAtPath:destFile];
			} @catch (id exception) {
				OFLog(@"Error removing file [%@]. Skipping file.", destFile);
				continue;
			}
		}

		// Apply method on contents of file if method given
		SEL selector;
		if (methodName != nil) {
			selector =
			    sel_registerName([methodName cStringWithEncoding:OFStringEncodingUTF8]);
		}

		if (methodName != nil && replaceDict != nil && [self respondsToSelector:selector]) {
			// OFLog(@"Applying method [%@] on file [%@] and copying
			// "
			//       @"to [%@]...",
			//     methodName, srcFile, destFile);

			OFString *fileContents = [OFString stringWithContentsOfFile:srcFile];
			fileContents = [self performSelector:selector
			                          withObject:fileContents
			                          withObject:replaceDict];
			[fileContents writeToFile:destFile];

			// Otherwise just copy
		} else {
			// OFLog(
			//     @"Copying file [%@] to [%@]...", srcFile,
			//     destFile);
			[fileMgr copyItemAtPath:srcFile toPath:destFile];
		}

		if ([[destFile lastPathComponent] isEqual:@"autogen.sh"]) {
			chmod([destFile UTF8String], 0755);
		}
	}
}

+ (void)copyFilesFromDir:(OFString *)sourceDir toDir:(OFString *)destDir
{
	[self copyFilesFromDir:sourceDir
	                            toDir:destDir
	    applyOnFileContentMethodNamed:nil
	                 usingReplaceDict:nil
	                  usingRenameDict:nil];
}

+ (OFString *)forFileContent:(OFString *)content replaceUsing:(OFDictionary *)replaceDict
{
	for (OFString *search in replaceDict) {
		content =
		    [content stringByReplacingOccurrencesOfString:search
		                                       withString:[replaceDict valueForKey:search]];
	}

	return content;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithLibrary:(OGTKLibrary *)libraryDescription
                         mapper:(OGTKMapper *)sharedMapper
                      outputDir:(OFString *)outputDir
{
	self = [super init];

	@try {
		_libraryDescription = libraryDescription;
		[_libraryDescription retain];

		_mapper = sharedMapper;
		[_mapper retain];

		_outputDir = [outputDir copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_libraryDescription release];
	[_mapper release];
	[_outputDir release];

	[super dealloc];
}

- (OFString *)sourceOutputDir
{
	return [_outputDir stringByAppendingPathComponent:@"src"];
}

- (void)writeClassFiles
{
	OFMutableDictionary *classesDict = _mapper.objcTypeToClassMapping;

	OFLog(
	    @"Going to generate and write class files for library %@...", _libraryDescription.name);

	// Write the classes
	for (OFString *className in classesDict) {
		OGTKClass *classDescription = [classesDict objectForKey:className];

		if ([_libraryDescription.namespace isEqual:classDescription.namespace]) {

			OGTKClassWriter *classWriter =
			    [[OGTKClassWriter alloc] initWithClass:classDescription
			                                   library:_libraryDescription
			                                    mapper:_mapper];

			[classWriter generateFilesInDir:self.sourceOutputDir];

			[classWriter release];
		}
	}
}

- (void)writeLibraryAdditionsWithSourcesFromDir:(OFString *)baseClassPath
{
	if (baseClassPath == nil)
		@throw [OGTKIncorrectConfigException exception];

	// Write the umbrella header file for the lib
	[self generateUmbrellaHeaderFileWithAdditionalHeadersFromDir:baseClassPath];

	if (!_libraryDescription.hasAdditionalSourceFiles)
		return;

	OFLog(@"Going to copy additional source files specific for library %@...",
	    _libraryDescription.name);

	[OGTKLibraryWriter
	    copyFilesFromDir:[baseClassPath
	                         stringByAppendingPathComponent:_libraryDescription.identifier]
	               toDir:self.sourceOutputDir];
}

- (void)generateUmbrellaHeaderFileWithAdditionalHeadersFromDir:(OFString *)additionalHeaderDir
{
	OFString *libName = _libraryDescription.name;
	OFMutableString *output = [OFMutableString string];

	OFString *fileName = [OFString stringWithFormat:@"%@-Umbrella.h", libName];
	OFString *license = [OGTKClassWriter generateLicense:fileName];
	[output appendString:license];

	[output appendString:@"\n#import <ObjFW/ObjFW.h>\n\n"];

	if (additionalHeaderDir != nil) {
		@try {
			OFString *headerDir = [additionalHeaderDir
			    stringByAppendingPathComponent:_libraryDescription.identifier];

			[output appendString:[self stringForFilesInDir:headerDir
			                                    addingFormat:@"#import \"%@\"\n"
			                         lookingForFileExtension:@".h"]];

		} @catch (OFReadFailedException *e) {
			// Do nothing, set flag to not try to copy anything
			// later
			_libraryDescription.hasAdditionalSourceFiles = false;

			// OFLog(@"No additional source files for library %@, "
			//       @"generating header file for generated sources
			//       "
			//       @"only.",
			//     libName);
		}

		[output appendString:@"\n"];
	}

	[output appendString:@"// Generated classes\n"];

	OFMutableDictionary *objCClassesDict = _mapper.objcTypeToClassMapping;
	OFArray *sortedKeys = [[objCClassesDict allKeys] sortedArray];

	for (OFString *objCClassName in sortedKeys) {
		OGTKClass *classDescription = [objCClassesDict objectForKey:objCClassName];
		if ([_libraryDescription.namespace isEqual:classDescription.namespace])
			[output appendFormat:@"#import \"%@.h\"\n", objCClassName];
	}

	OFString *hFilePath = [self.sourceOutputDir stringByAppendingPathComponent:fileName];

	[output writeToFile:hFilePath];
}

- (OFString *)stringForFilesInDir:(OFString *)dirPath
                     addingFormat:(OFConstantString *)format
          lookingForFileExtension:(OFString *)fileExtension;
{
	OFMutableString *string = [OFMutableString string];

	OFFileManager *fileMgr = [OFFileManager defaultManager];

	if (![fileMgr directoryExistsAtPath:dirPath]) {
		@throw [OFReadFailedException exceptionWithObject:dirPath
		                                  requestedLength:0
		                                            errNo:0];
	}

	OFArray *srcDirContents = [fileMgr contentsOfDirectoryAtPath:dirPath];
	OFArray *sortedDirContents = [srcDirContents sortedArray];

	for (OFString *srcFile in sortedDirContents) {
		OFString *additionalFile = [srcFile lastPathComponent];
		if ([additionalFile containsString:fileExtension]) {
			[string appendFormat:format, additionalFile];
		}
	}

	[string makeImmutable];
	return string;
}

- (void)templateAndCopyBuildFilesFromDir:(OFString *)templateDir
                    usingSnippetsFromDir:(OFString *)templateSnippetsDir
{
	OFString *sourceFiles = [self stringForFilesInDir:self.sourceOutputDir
	                                     addingFormat:@"%@ \\\n\t"
	                          lookingForFileExtension:@".m"];

	OGTKTemplate *templating = [[OGTKTemplate alloc] initWithSnippetDir:templateSnippetsDir
	                                                       sharedMapper:self.mapper];
	[templating autorelease];

	OFDictionary *replaceDict =
	    [templating dictWithReplaceValuesForBuildFilesOfLibrary:self.libraryDescription
	                                                sourceFiles:sourceFiles];

	OFDictionary *renameDict =
	    [templating dictWithRenamesForBuildFilesOfLibrary:self.libraryDescription];

	[OGTKLibraryWriter copyFilesFromDir:templateDir
	                              toDir:self.outputDir
	      applyOnFileContentMethodNamed:@"forFileContent:replaceUsing:"
	                   usingReplaceDict:replaceDict
	                    usingRenameDict:renameDict];
}

@end
