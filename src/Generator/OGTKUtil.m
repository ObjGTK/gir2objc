/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKUtil.h"

#import "../Exceptions/OGTKReceivedNilExpectedStringException.h"
#import "OFDictionary+OGTKJsonDictionaryOfFile.h"
#import "OGTKMapper.h"

/* Reference for static linking */
void _reference_to_category_of_ofdictionary(void)
{
	_OFDictionary_OGTKJsonDictionaryOfFile_reference = 1;
}

@implementation OGTKUtil

static OFMutableDictionary *dictGlobalConf;
static OFMutableDictionary *dictLibraryConf;
static OFString *myDataDir;

+ (OFString *)convertUSSToCamelCase:(OFString *)input
{
	OFString *output = [self convertUSSToCapCase:input];

	if ([output length] > 1) {
		return [OFString stringWithFormat:@"%@%@",
		    [[output substringToIndex:1] lowercaseString], [output substringFromIndex:1]];
	} else {
		return [output lowercaseString];
	}
}

+ (OFString *)convertUSSToCapCase:(OFString *)input
{
	if (input == nil)
		return nil;

	OFMutableString *output = [[[OFMutableString alloc] init] autorelease];
	OFArray *inputItems = [input componentsSeparatedByString:@"_"];

	bool previousItemWasSingleChar = false;

	for (OFString *item in inputItems) {
		if ([item length] > 1) {
			// Special case where we don't strand single characters
			if (previousItemWasSingleChar) {
				[output appendString:item];
			} else {
				[output appendFormat:@"%@%@",
				    [[item substringToIndex:1] uppercaseString],
				    [item substringFromIndex:1]];
			}
			previousItemWasSingleChar = false;
		} else {
			[output appendString:[item uppercaseString]];
			previousItemWasSingleChar = true;
		}
	}

	return output;
}

+ (OFString *)convertFunctionToInit:(OFString *)func nameOfFirstParameter:(OFString *)paramName
{
	paramName = [self convertUSSToCapCase:paramName];

	OFRange range = [func rangeOfString:@"New"];
	if (range.location == OFNotFound) {
		range = [func rangeOfString:@"new"];
	}

	if (range.location == OFNotFound) {
		OFString *outputFormat = [OFString stringWithFormat:@"%@%@",
		    [[func substringToIndex:1] uppercaseString], [func substringFromIndex:1]];

		if (paramName != nil)
			return [OFString stringWithFormat:@"initWith%@%@", paramName, outputFormat];

		return [OFString stringWithFormat:@"init%@", outputFormat];
	} else {
		if (paramName != nil)
			return [OFString stringWithFormat:@"initWith%@%@", paramName,
			    [func substringFromIndex:range.location + 3]];

		return [OFString
		    stringWithFormat:@"init%@", [func substringFromIndex:range.location + 3]];
	}
}

+ (OFString *)getFunctionCallForConstructorOfType:(OFString *)cType
                                  withConstructor:(OFString *)cCtor
{
	return [OFString stringWithFormat:@"[super initWithGObject:%@]", cCtor];
}

+ (bool)isUppercase:(OFString *)character
{
	OFUnichar myCharacter = [character characterAtIndex:0];
	if (myCharacter >= 'A' && myCharacter <= 'Z')
		return true;

	return false;
}

+ (void)setDataDir:(OFString *)dataDir
{
	if ([[OFFileManager defaultManager] directoryExistsAtPath:dataDir])
		myDataDir = [dataDir retain];
	else
		myDataDir = @".";
}

+ (OFString *)dataDir
{
	if (myDataDir != nil)
		return [[myDataDir copy] autorelease];

	return @".";
}

+ (id)globalConfigValueFor:(OFString *)key
{
	if (dictGlobalConf == nil) {

		dictGlobalConf = [[OFMutableDictionary alloc] ogtk_initWithJsonDictionaryOfFile:
		        [myDataDir stringByAppendingPathComponent:@"Config/global_conf.json"]];
	}

	return [dictGlobalConf objectForKey:key];
}

+ (id)libraryConfigFor:(OFString *)libraryIdentifier
{
	if (dictLibraryConf == nil) {
		dictLibraryConf = [[OFMutableDictionary alloc] ogtk_initWithJsonDictionaryOfFile:
		        [myDataDir stringByAppendingPathComponent:@"Config/library_conf.json"]];
	}

	return [dictLibraryConf objectForKey:libraryIdentifier];
}

@end