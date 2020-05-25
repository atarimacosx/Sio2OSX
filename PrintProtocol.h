//
//  PrintProtocol.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 19 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

@protocol PrintProtocol
-(void)setLocation:(NSPoint)location;
-(float)getYLocation;
-(float)getMinYLocation;
-(void)print:(NSRect)rect:(float)offset;
@end
