//
//  ACGBigNum.h
//  ACGTool
//
//  Created by Ben Rister on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>


@interface ACGBigNum : NSObject {
    UInt64* digits;
    UInt8 numDigits;
}

- (id)init;
- (id)initWithUInt64:(UInt64)i;
- (id)initWithDigits:(UInt64*)dig numDigits:(UInt8)num;
- (id)initWithString:(NSString*)str baseChars:(NSString*)chars;

//NSCopying protocol
- (id)copyWithZone:(NSZone *)zone;

//accessors
- (UInt64*)digits;
- (UInt8)numDigits;

//math ops
- (void)add:(ACGBigNum*)num;
- (void)sub:(ACGBigNum*)num;
- (void)mul:(ACGBigNum*)num;
- (void)div:(UInt64)num remainder:(UInt64*)rem;
- (void)divByTwo;
- (void)pow:(UInt64)num;
- (BOOL)isZero;
- (BOOL)isOne;

//string ops
- (NSString*)extractStringWithBaseChars:(NSString*)baseChars;
- (int) valueForChar:(unichar)ch baseChars:(NSString*)chars;

//utils
- (void)makeThisManyDigits:(UInt8)newNumDigits;
- (void)clearExcessDigits;
- (void)keepOnlyLowestDigit;

@end
