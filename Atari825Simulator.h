//
//  Atari825Simulator.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 19 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrintableString.h"
#import "PrintableGraphics.h"
#import "PrinterProtocol.h"

typedef struct ATARI825_PREF {
	int charSet; 
    int formLength;
    int autoLinefeed; 
} ATARI825_PREF;

@interface Atari825Simulator : NSObject <PrinterProtocol> {
	int state;
	int style;
	int pitch;
	NSFont *styles[16];
	float leftMargin;
	float rightMargin;
	float compressedRightMargin;
	float startHorizPosition;
	float nextHorizPosition;
	float vertPosition;
	bool autoLineFeed;
	float lineSpacing;
	float formLength;
	bool expandedMode;
	bool compressedMode;
	bool underlineMode;
	bool proportionalMode;
	float horizWidth;
	float propCharSetback;
	int countryMode;
	int skipOverPerf;
	bool splitPerfSkip;

	PrintableString *printBuffer;
}

+ (Atari825Simulator *)sharedInstance;
- (void)addChar:(unsigned short)unicharacter;
- (void)idleState:(char) character;
- (void)escState:(char) character;
- (void)bsState:(char) character;

-(void)setStyle;
-(void)emptyPrintBuffer;
-(void)executeLineFeed:(float)amount;


@end
