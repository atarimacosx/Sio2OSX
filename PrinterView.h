//
//  PrinterView.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sun Mar 13 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PrintOutputController.h"


@interface PrinterView : NSView {
	PrintOutputController *controller;
	float pageLength;
	float vertPosition;
}
- (id)initWithFrame:(NSRect)frame:(PrintOutputController *)owner:(float)pageLen:(float)vert;
- (void)updateVerticlePosition:(float)vert;

@end
