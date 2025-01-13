/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import "OGTKParameter.h"
#import "OGTKUtil.h"

/**
 * Abstracts Parameter operations
 */
@implementation OGTKParameter
@synthesize cType = _cType, cName = _cName, documentation = _documentation;

- (void)dealloc
{
	[_cType release];
	[_cName release];
	[_documentation release];

	[super dealloc];
}

- (OFString *)type
{
	return [OGTKMapper swapTypes:_cType];
}

- (OFString *)name
{
	return [OGTKUtil convertUSSToCamelCase:_cName];
}

@end
