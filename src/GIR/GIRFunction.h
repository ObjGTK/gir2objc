/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import <ObjFW/ObjFW.h>

#import "GIRBase.h"
#import "GIRDoc.h"
#import "GIRMethodMapping.h"
#import "GIRParameter.h"
#import "GIRReturnValue.h"

@interface GIRFunction: GIRBase <GIRMethodMapping>
{
	OFString *_name;
	OFString *_cIdentifier;
	OFString *_movedTo;
	OFString *_version;
	bool _introspectable;
	bool _deprecated;
	OFString *_deprecatedVersion;
	bool _throws;
	GIRDoc *_docDeprecated;
	GIRDoc *_doc;
	GIRReturnValue *_returnValue;
	OFMutableArray *_parameters;
	GIRParameter *_instanceParameter;
}

@property (nonatomic, copy) OFString *name;
@property (nonatomic, copy) OFString *cIdentifier;
@property (nonatomic, copy) OFString *movedTo;
@property (nonatomic, copy) OFString *version;
@property (nonatomic) bool introspectable;
@property (nonatomic) bool deprecated;
@property (nonatomic, copy) OFString *deprecatedVersion;
@property (nonatomic) bool throws;
@property (nonatomic, retain) GIRDoc *docDeprecated;
@property (nonatomic, retain) GIRDoc *doc;
@property (nonatomic, retain) GIRReturnValue *returnValue;
@property (nonatomic, retain) OFMutableArray *parameters;
@property (nonatomic, retain) GIRParameter *instanceParameter;

@end
