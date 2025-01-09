#import "OGTKClassNoTypeException.h"

@implementation OGTKClassNoTypeException

@synthesize girClass = _girClass;

- (instancetype)initForGirClass:(GIRClass *)girClass
{
	self = [super init];

	@try {
		_girClass = [girClass retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

+ (instancetype)exceptionForGirClass:(GIRClass *)girClass
{
	return [[[self alloc] initForGirClass:girClass] autorelease];
}

- (void)dealloc
{
	[_girClass release];
	[super dealloc];
}

- (OFString *)description
{
	return [OFString
	    stringWithFormat:@"Found no C/GLib type for GIR class named: %@", _girClass.name];
}

@end
