//
//  CassStatusUpdate.h
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CassStatusUpdate : NSObject {
	BOOL  myGap;
	int   myBlock;
}

- (void) setStatus:(BOOL) gap:(int) block;
- (BOOL) gap;
- (int) block;
@end
