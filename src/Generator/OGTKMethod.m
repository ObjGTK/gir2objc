/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2024 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2024 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKMethod.h"
#import "OGTKMapper.h"
#import "OGTKUtil.h"

@implementation OGTKMethod
@synthesize name = _name, cIdentifier = _cIdentifier, cReturnType = _cReturnType,
            cOwnershipTransferType = _cOwnershipTransferType, documentation = _documentation,
            returnValueDocumentation = _returnValueDocumentation,
            cInstanceParameter = _cInstanceParameter, parameters = _parameters, throws = _throws,
            isGetter = _isGetter, isSetter = _isSetter, isClassMethod = _isClassMethod;

- (instancetype)init
{
	self = [super init];

	_throws = false;

	return self;
}

- (void)dealloc
{
	[_name release];
	[_cIdentifier release];
	[_cReturnType release];
	[_documentation release];
	[_returnValueDocumentation release];
	[_cInstanceParameter release];
	[_parameters release];

	[super dealloc];
}

- (OFString *)name
{
	return [OGTKUtil convertUSSToCamelCase:_name];
}

- (OFString *)sig
{
	// C method with no parameters
	if (_parameters.count == 0) {
		return self.name;
	}
	// C method with only one parameter
	else if (_parameters.count == 1) {
		OGTKParameter *p = [_parameters objectAtIndex:0];

		return [self signatureForFirstParameter:p methodName:self.name];
	}
	// C method with multiple parameters
	else {
		OFMutableString *output = [OFMutableString string];

		bool first = true;
		for (OGTKParameter *p in _parameters) {
			if (first) {
				first = false;
				[output appendString:[self signatureForFirstParameter:p
				                                           methodName:self.name]];
			} else {
				[output appendFormat:@" %@:(%@)%@",
				        [OGTKUtil convertUSSToCamelCase:p.name], p.type, p.name];
			}
		}

		return output;
	}
}

- (OFString *)signatureForFirstParameter:(OGTKParameter *)p methodName:(OFString *)methodName
{
	// Add the parameter name only when it's the same as the beginning of the method
	// name Otherwise assume the method name already contains a named parameter.
	if ([methodName.lowercaseString containsString:p.name.lowercaseString]) {
		OFRange range = [methodName.lowercaseString rangeOfString:p.cName.lowercaseString];
		if (range.location == 0)
			return [OFString stringWithFormat:@"%@With%@:(%@)%@", methodName,
			                 [OGTKUtil convertUSSToCapCase:p.name], p.type, p.name];
		else
			return [OFString stringWithFormat:@"%@:(%@)%@", methodName, p.type, p.name];
	}

	// If the method name does not contain a hint to the parameter name
	// add it to have a sensible ObjC selector.
	return [OFString stringWithFormat:@"%@With%@:(%@)%@", methodName,
	                 [OGTKUtil convertUSSToCapCase:p.name], p.type, p.name];
}

- (OFString *)nameOfTheOnlyParameter
{
	if (self.parameters.count != 1)
		return nil;

	OGTKParameter *param = self.parameters.firstObject;
	return param.name;
}

- (OFString *)returnType
{
	return [OGTKMapper swapTypes:_cReturnType];
}

- (bool)returnsVoid
{
	return [_cReturnType isEqual:@"void"];
}

@end
