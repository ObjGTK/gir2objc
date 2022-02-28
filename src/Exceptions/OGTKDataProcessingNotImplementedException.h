/*
 * Copyright 2022 Johannes Brakensiek <objfw at codingpastor.de>
 *
 * This software is licensed under the GNU General Public License
 * (version 2.0 or later). See the LICENSE file in this distribution.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@interface OGTKDataProcessingNotImplementedException: OFException
{
	OFString *_description;
}

@property (readonly, nonatomic) OFString *description;

+ (instancetype)exception OF_UNAVAILABLE;
+ (instancetype)exceptionWithDescription:(OFString *)description;
- (instancetype)init OF_UNAVAILABLE;
- (instancetype)initWithDescription:(OFString *)description;

@end

OF_ASSUME_NONNULL_END
