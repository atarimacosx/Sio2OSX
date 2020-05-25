//
//  CassInfoUpdate.m
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CassInfoUpdate.h"

@implementation CassInfoUpdate

- (id)init 
{
	[super init];
	return self;
}

- (void) setInfo:(int) current:(int) max;
{
	myCurrent = current;
	myMax = max;
}

- (int) current
{
	return myCurrent;
}

- (int)  max
{
	return myMax;
}
@end
