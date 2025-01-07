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
            returnValueDocumentation = _returnValueDocumentation, parameters = _parameters,
            throws = _throws, isGetter = _isGetter, isSetter = _isSetter;

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
	[_parameters release];

	[super dealloc];
}

- (OFString *)name
{
	OFString *name = [OGTKUtil convertUSSToCamelCase:_name];

	if([name isEqual:@"release"])
		return @"decreaseCount";
	else if([name isEqual:@"retain"])
		return @"increaseCount";

	return name;
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

		return [OFString stringWithFormat:@"%@:(%@)%@", self.name, p.type, p.name];
	}
	// C method with multiple parameters
	else {
		OFMutableString *output = [OFMutableString stringWithFormat:@"%@With", self.name];

		bool first = true;
		for (OGTKParameter *p in _parameters) {
			if (first) {
				first = false;
				[output appendFormat:@"%@:(%@)%@",
				    [OGTKUtil convertUSSToCapCase:p.name], p.type, p.name];
			} else {
				[output appendFormat:@" %@:(%@)%@",
				    [OGTKUtil convertUSSToCamelCase:p.name], p.type, p.name];
			}
		}

		return output;
	}
}

- (OFString *)nameOfTheOnlyParameter 
{
	if(self.parameters.count != 1)
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
