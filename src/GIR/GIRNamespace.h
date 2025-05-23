/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import <ObjFW/ObjFW.h>

#import "GIRBase.h"
#import "GIRClass.h"
#import "GIRConstant.h"
#import "GIREnumeration.h"
#import "GIRFunction.h"
#import "GIRInterface.h"
#import "GIRRecord.h"

@interface GIRNamespace: GIRBase
{
	OFString *_name;
	OFString *_version;
	OFString *_sharedLibrary;
	OFString *_cSymbolPrefixes;
	OFString *_cIdentifierPrefixes;
	OFMutableArray *_classes;
	OFMutableArray *_functions;
	OFMutableArray *_enumerations;
	OFMutableArray *_constants;
	OFMutableArray *_interfaces;
}

@property (nonatomic, copy) OFString *name;
@property (nonatomic, copy) OFString *version;

/**
 * @brief A comma separated list of shared libraries
 *
 */
@property (nonatomic, copy) OFString *sharedLibrary;
@property (nonatomic, copy) OFString *cSymbolPrefixes;
@property (nonatomic, copy) OFString *cIdentifierPrefixes;
@property (nonatomic, retain) OFMutableArray *classes;
@property (nonatomic, retain) OFMutableArray *functions;
@property (nonatomic, retain) OFMutableArray *enumerations;
@property (nonatomic, retain) OFMutableArray *constants;
@property (nonatomic, retain) OFMutableArray *interfaces;

@end
