//
//  CassStatusUpdate.m
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CassStatusUpdate.h"

@implementation CassStatusUpdate

- (id)init 
{
	[super init];
	return self;
}

- (void) setStatus:(BOOL) gap:(int) block;
{
	myGap = gap;
	myBlock = block;
}

- (BOOL) gap
{
	return myGap;
}

- (int) block
{
	return myBlock;
}
@end
