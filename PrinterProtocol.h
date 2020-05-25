//
//  PrintProtocol.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 19 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>

@protocol PrinterProtocol
- (void)printChar:(char) character;
-(void)reset;
-(float)getVertPosition;
-(float)getFormLength;
-(NSColor *)getPenColor;
-(void)executeLineFeed;
-(void)executeRevLineFeed;
-(void)executeFormFeed;
-(void)executePenChange;
-(void)topBlankForm;
-(bool)isAutoPageAdjustEnabled;
@end
