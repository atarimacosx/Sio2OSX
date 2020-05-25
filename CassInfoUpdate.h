//
//  CassInfoUpdate.h
//  Sio2OSX
//
//  Created by Mark Grebe on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CassInfoUpdate : NSObject {
	int  myCurrent;
	int  myMax;
}

- (void) setInfo:(int) current:(int) max;
- (int) current;
- (int) max;
@end
