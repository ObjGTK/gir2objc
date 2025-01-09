#import <ObjFW/ObjFW.h>
#import "../GIR/GIRClass.h"

OF_ASSUME_NONNULL_BEGIN

@interface OGTKClassNoTypeException: OFException

{
	GIRClass *_girClass;
}

@property (retain, nonatomic) GIRClass *girClass;

+ (instancetype)exceptionForGirClass:(GIRClass *)girClass;
- (instancetype)initForGirClass:(GIRClass *)girClass;
- (OFString *)description;

@end

OF_ASSUME_NONNULL_END
