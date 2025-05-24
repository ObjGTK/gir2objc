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

@interface GIRConstructor: GIRBase <GIRMethodMapping>
{
	OFString *_name;
	OFString *_cIdentifier;
	OFString *_version;
	OFString *_deprecatedVersion;
	OFString *_shadowedBy;
	OFString *_shadows;
	bool _introspectable;
	bool _deprecated;
	bool _throws;
	GIRDoc *_doc;
	GIRDoc *_docDeprecated;
	GIRReturnValue *_returnValue;
	OFMutableArray *_parameters;
	GIRParameter *_instanceParameter;
}

@property (nonatomic, copy) OFString *name;
@property (nonatomic, copy) OFString *cIdentifier;
@property (nonatomic, copy) OFString *version;
@property (nonatomic, copy) OFString *deprecatedVersion;
@property (nonatomic, copy) OFString *shadowedBy;
@property (nonatomic, copy) OFString *shadows;
@property (nonatomic) bool introspectable;
@property (nonatomic) bool deprecated;
@property (nonatomic) bool throws;
@property (nonatomic, retain) GIRDoc *doc;
@property (nonatomic, retain) GIRDoc *docDeprecated;
@property (nonatomic, retain) GIRReturnValue *returnValue;
@property (nonatomic, retain) OFMutableArray *parameters;
@property (nonatomic, retain) GIRParameter *instanceParameter;

@end
