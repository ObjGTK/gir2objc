/*
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2021-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "GIRReturnValue.h"
#import "GIRParameter.h"
#import <ObjFW/ObjFW.h>

@protocol GIRMethodMapping <OFObject>

@property (nonatomic, copy) OFString *_Nonnull name;
@property (nonatomic, copy) OFString *_Nonnull cIdentifier;
@property (nonatomic, retain) OFMutableArray OF_GENERIC(GIRParameter *) *_Nullable parameters;
@property (nonatomic, retain) GIRParameter *_Nullable instanceParameter;
@property (nonatomic, retain) GIRReturnValue *_Nonnull returnValue;
@property (nonatomic, retain) GIRDoc *_Nullable doc;
@property (nonatomic) bool throws;

@end
