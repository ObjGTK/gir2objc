/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import <ObjFW/ObjFW.h>

#import "GIRBase.h"
#import "GIRConstructor.h"
#import "GIRDoc.h"
#import "GIRField.h"
#import "GIRFunction.h"
#import "GIRImplements.h"
#import "GIRMethod.h"
#import "GIRProperty.h"
#import "GIRVirtualMethod.h"

@interface GIRRecord: GIRBase
{
	GIRDoc *_doc;
	OFString *_name;
	OFString *_cType;
	bool _opaque;
	bool _pointer;
	OFString *_glibTypeName;
	OFString *_glibGetType;
	OFString *_cSymbolPrefix;
	bool _foreign;
	OFString *_glibIsGtypeStructFor;
	OFString *_nameOfCopyFunction;
	OFString *_nameOfFreeFunction;

	OFMutableArray *_fields;
	OFMutableArray *_functions;
	OFMutableArray *_methods;
	OFMutableArray *_constructors;
}

@property (nonatomic, retain) GIRDoc *doc;
@property (nonatomic, copy) OFString *name;
@property (nonatomic, copy) OFString *cType;
@property (nonatomic) bool opaque;
@property (nonatomic) bool pointer;
@property (nonatomic, copy) OFString *glibTypeName;
@property (nonatomic, copy) OFString *glibGetType;
@property (nonatomic, copy) OFString *cSymbolPrefix;
@property (nonatomic) bool foreign;
@property (nonatomic, copy) OFString *glibIsGtypeStructFor;
@property (nonatomic, copy) OFString *nameOfCopyFunction;
@property (nonatomic, copy) OFString *nameOfFreeFunction;

@property (nonatomic, retain) OFMutableArray *fields;
@property (nonatomic, retain) OFMutableArray *functions;
@property (nonatomic, retain) OFMutableArray *methods;
@property (nonatomic, retain) OFMutableArray *constructors;

@end
