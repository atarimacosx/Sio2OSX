//
//  LedUpdate.m
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "LedUpdate.h"

@implementation LedUpdate

+ (id) withOn:(BOOL) on
{
	return([[LedUpdate alloc] init:on]);
}

- (id)init:(BOOL) on 
{
        [self init];
		myOn = on;
		return self;
}

- (id)init 
{
        [super init];
		return self;
}

- (void) setState:(int) drive:(BOOL) read:(int) sector
{
	myRead = read;
	myDrive = drive;
	mySector = sector;
}

- (BOOL) on
{
	return myOn;
}

- (int) drive
{
	return myDrive;
}

- (BOOL) read
{
	return myRead;
}

- (int)  sector
{
	return mySector;
}
@end
