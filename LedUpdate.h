//
//  LedUpdate.h
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LedUpdate : NSObject {
	BOOL myOn;
	int  myDrive;
	BOOL myRead;
	int  mySector;
}

+ (id) withOn:(BOOL) on;
- (id)init:(BOOL) on; 
- (void) setState:(int) drive:(BOOL) read:(int) sector;
- (BOOL) on;
- (int) drive;
- (BOOL) read;
- (int)  sector;
@end
