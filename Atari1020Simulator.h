//
//  Atari1020Simulator.h
//  Atari800MacX
//
//  Created by Mark Grebe on Fri Aor 21 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrintablePath.h"
#import "PrinterProtocol.h"

typedef struct ATARI1020_PREF {
	int printWidth; 
    int formLength;
    int autoLinefeed; 
	float pen1Red;
	float pen1Blue;
	float pen1Green;
	float pen1Alpha;
	float pen2Red;
	float pen2Blue;
	float pen2Green;
	float pen2Alpha;
	float pen3Red;
	float pen3Blue;
	float pen3Green;
	float pen3Alpha;
	float pen4Red;
	float pen4Blue;
	float pen4Green;
	float pen4Alpha;
	int autoPageAdjust;
} ATARI1020_PREF;

@interface Atari1020Simulator : NSObject <PrinterProtocol> {
	int state;
	float leftMargin;
	float rightMargin;
	float horizPosition;
	float vertPosition;
	float horizOrigin;
	float vertOrigin;
	bool autoLineFeed;
	float lineSpacing;
	float formLength;

    int color;
    int rotation;
    int lineType;
    int charSize;
    float xAccum;
    float yAccum;
    float stepAccum;
    int intervalAccum;
	int charCount;
	char charBuffer[256];
	int axis;
	int scaleFactor;
	int internationalMode;
	
	bool autoPageAdjust;

	PrintablePath *printPath;
}

+ (Atari1020Simulator *)sharedInstance;
- (void)addChar:(unsigned char)character;
- (void)textIdleState:(unsigned char) character;
- (void)gotEscState:(unsigned char) character;
- (void)graphicsIdleState:(unsigned char) character;
- (void)textIdleState:(unsigned char) character;
- (void)graphicsIdleState:(unsigned char) character;
- (void)waitCrState:(unsigned char) character;
- (void)gotResetState:(unsigned char) character;
- (void)gotChangeColorState:(unsigned char) character;
- (void)gotRotatePrintState:(unsigned char) character;
- (void)gotLineTypeState:(unsigned char) character;
- (void)gotCharSizeState:(unsigned char) character;
- (void)checkAccums;
- (void)checkPositions;
- (void)checkPoints:(float *)horiz:(float *)vert;
- (void)gotDrawAbsoluteState:(unsigned char) character;
- (void)gotDrawAbsoluteYState:(unsigned char) character;
- (void)gotDrawRelativeState:(unsigned char) character;
- (void)gotDrawRelativeYState:(unsigned char) character;
- (void)gotMoveAbsoluteState:(unsigned char) character;
- (void)gotMoveAbsoluteYState:(unsigned char) character;
- (void)gotMoveRelativeState:(unsigned char) character;
- (void)gotMoveRelativeYState:(unsigned char) character;
- (void) gotPrintTextState:(unsigned char) character;
- (void)gotDrawAxisState:(unsigned char) character;
- (void)gotDrawAxisStepState:(unsigned char) character;
- (void)gotDrawAxisIntervalState:(unsigned char) character;
- (void)emptyPrintPath;
- (void)clearPrintPath;
- (void)executeLineFeed:(float)amount;


@end
