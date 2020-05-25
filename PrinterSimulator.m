//
//  PrinterSimulator.m
//  Atari800MacX
//
//  Created by Mark Grebe on Sun Apr 03 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//
#import "PrinterSimulator.h"

@implementation PrinterSimulator
- (void)printChar:(char) character
{
}

-(void)reset
{
}

-(float)getVertPosition
{
	return(0.0);
}

-(float)getFormLength
{
	return(0.0);
}

-(NSColor *)getPenColor
{
	return(nil);
}

-(bool)isAutoPageAdjustEnabled
{
	return(NO);
}

-(void)executeLineFeed
{
}

-(void)executeRevLineFeed
{
}

-(void)executeFormFeed
{
}

-(void)executePenChange
{
}

-(void)topBlankForm;
{
}


@end
