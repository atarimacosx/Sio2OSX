//
//  PrintableGraphics.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 26 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrintProtocol.h"


@interface PrintableGraphics : NSData <PrintProtocol> {
	NSPoint printLocation;
	unsigned char *graphBytes;
	unsigned graphLength;
	float pixelWidth;
	float pixelHeight;
	unsigned columnBits;
}
- (id)initWithBytes:(const void *)bytes length:(unsigned)length width:(float)width height:(float) height bits:(unsigned)bits;
@end
