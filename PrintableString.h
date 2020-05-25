//
//  NSPrintableString.h
//  Atari800MacX
//
//  Created by Mark Grebe on Sat Mar 19 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrintProtocol.h"

@interface PrintableString : NSMutableAttributedString <PrintProtocol> {
	NSMutableAttributedString * _contents;
	NSPoint printLocation;
}
-(id)init;
-(id)initWithAttributedSting:(NSAttributedString *)attributedString;
-(NSString *)string;
-(NSDictionary *)attributesAtIndex:(unsigned)location
				  effectiveRange:(NSRange *)range;
-(void)replaceCharactersInRange:(NSRange)range
				  withString:(NSString *)string;
-(void)setAttributes:(NSDictionary *)attributes
				  range:(NSRange)range;
-(void)dealloc;

@end
