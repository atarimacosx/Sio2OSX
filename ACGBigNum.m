//
//  ACGBigNum.m
//  ACGTool
//
//  Created by Ben Rister on Thu Apr 22 2004.
//

#import "ACGBigNum.h"


@implementation ACGBigNum

#pragma mark init

- (id)init {
    return [self initWithUInt64:0];
}
- (id)initWithUInt64:(UInt64)i {
    if(self = [super init]) {
        digits = malloc(sizeof(UInt64));
        if(!digits) {
            [self release];
            return NULL;
        }
        *digits = i;
        numDigits = 1;
    }
    
    return self;
}
- (id)initWithDigits:(UInt64*)dig numDigits:(UInt8)num {
    if(self = [super init]) {
        digits = malloc(sizeof(UInt64)*num);
        if(!digits) {
            [self release];
            return NULL;
        }
        numDigits = num;
        
        int i;
        for(i=0;i<numDigits;i++) {
            digits[i] = dig[i];
        }
    }
    
    return self;
}
- (id)initWithString:(NSString*)str baseChars:(NSString*)chars {
    if([self init]) {
        ACGBigNum* base = [[[ACGBigNum alloc] initWithUInt64:[chars length]] autorelease];
        
        int i;
        for(i=0; i<[str length]; i++) {
            //shift the previous stuff over a place
            [self mul:base];
            
            //figure out how much this digit is worth
            int digit = [self valueForChar:[str characterAtIndex:i] baseChars:chars];
            ACGBigNum* digitQuant = [[ACGBigNum alloc] initWithUInt64:digit];
            
            //add it to ourselves
            [self add:digitQuant];
            
            //release the digit quantity, and prepare for next iter
            [digitQuant release];
        }
    }
    
    return self;
}

- (void) dealloc {
    free(digits);
    [super dealloc];
}

#pragma mark NSCopying protocol
- (id)copyWithZone:(NSZone *)zone {
    return [[ACGBigNum allocWithZone:zone] initWithDigits:digits numDigits:numDigits];
}

#pragma mark accessors
- (UInt64*)digits {
    return digits;
}
- (UInt8) numDigits {
    return numDigits;
}

#pragma mark math ops
- (void)add:(ACGBigNum*)num {
    UInt64* otherDigits = [num digits];
    UInt8 otherNumDigits = [num numDigits];
    
    [self makeThisManyDigits:otherNumDigits];
    
    int i; int carry=0;
    //keep going as long as:
    //  - there are digits in the other number, or
    //  - we have a carry and still have enough digits to carry it
    for(i=0; (i<numDigits && carry>0) || (i<otherNumDigits); i++) {
        UInt64 oldVal = digits[i];
        digits[i] += carry;
        if(i < otherNumDigits)
            digits[i] += otherDigits[i];
        
        if((oldVal > digits[i]) ||
           ((oldVal == digits[i]) && (i<otherNumDigits) && (otherDigits[i] != 0))) {
            carry = 1;
        } else {
            carry = 0;
        }
    }
    
    // i is now the index of the right array position for the carry to go
    // but if we still have a carry at this point, it means that we don't have enough digits
    if(carry > 0) {
        [self makeThisManyDigits:(i+1)];
        digits[i] += carry;
    }
}
- (void)sub:(ACGBigNum*)num {
    UInt64* otherDigits = [num digits];
    UInt8 otherNumDigits = [num numDigits];
    
    int i;
    for(i=0; (i<numDigits)&&(i<otherNumDigits); i++) {
        UInt64 oldVal = digits[i];
        digits[i] -= otherDigits[i];
        
        //check for borrow
        if(digits[i] > oldVal) {
            int j = i;
            UInt64 oldVal2;
            
            do {
                j++;
                NSAssert(j < numDigits, @"subtraction went negative");
                oldVal2 = digits[j];
                digits[j]--;
            } while(digits[j] > oldVal2);
        }
    }
    
    //check for underflow with excess digits
    for(i=numDigits; i<otherNumDigits; i++) {
        //only underflows if the excess digits aren't zero
        NSAssert(otherDigits[i] == 0, @"subtraction went negative");
    }
}
- (void)mul:(ACGBigNum*)num {
    if([num isZero] || [self isZero]) {
        [self keepOnlyLowestDigit];
        digits[0] = 0;
        return;
    }
    
    ACGBigNum* one = [[[ACGBigNum alloc] initWithUInt64:1] autorelease];
    ACGBigNum* base = [self copy];
    ACGBigNum* counter = [[num copy] autorelease];
    ACGBigNum* otherNum = [[[ACGBigNum alloc] init] autorelease];
    
    while(![counter isOne]) {
        UInt64* counterDigits = [counter digits];
        if((counterDigits[0]%2) != 0) {
            //not divisible by two
            [counter sub:one];
            [otherNum add:base];
        } else {
            //is divisible by two--
            //  double ourselves
            [base release];
            base = [self copy];
            [self add:base];
            //  halve the other number
            [counter divByTwo];
            //  and start over again
            [base release];
            base = [self copy];
        }
    }
    
    [base release];
    [self add:otherNum];
}
- (void)div:(UInt64)num remainder:(UInt64*)rem {
    ACGBigNum* origSelf = [self copy];
    //clear self out to zero as the quotient
    [self keepOnlyLowestDigit];
    digits[0] = 0;
    
    
    //find out how many times num goes into maxint for UInt64
    UInt64 test = 0;
    UInt64 test2 = (test-1) / num;              //this much goes into the quotient for each high bit
    ACGBigNum* quotientPerHi = [[[ACGBigNum alloc] initWithUInt64:test2] autorelease];
    UInt64 testRem = (test-1) - (test2*num) + 1;    //this much stays in self for each high bit
    ACGBigNum* stayPerHi = [[[ACGBigNum alloc] initWithUInt64:testRem] autorelease];
    
    // self is the quotient
    // origSelf is the number we're dividing (copy of original self)
    
    UInt64* origDigits;
    [origSelf clearExcessDigits];
    while ([origSelf numDigits] > 1) {
        origDigits = [origSelf digits];
        UInt8 origNumDigits = [origSelf numDigits];
        
        ACGBigNum* myDig = [[ACGBigNum alloc] initWithDigits:(origDigits+1) numDigits:(origNumDigits-1)];
        ACGBigNum* totalToStay = [myDig copy];
        [totalToStay mul:stayPerHi];
        ACGBigNum* totalToQuot = [myDig copy];
        [totalToQuot mul:quotientPerHi];
        
        [origSelf keepOnlyLowestDigit];
        [origSelf add:totalToStay];
        [self add:totalToQuot];
        [totalToStay release];
        [totalToQuot release];
        [myDig release];
        
        [origSelf clearExcessDigits];
    }
    
    origDigits = [origSelf digits];
    //see how many times num goes into the low bits
    UInt64 tmp = origDigits[0] / num;
    //increment the quotient by that much
    ACGBigNum* qd = [[ACGBigNum alloc] initWithUInt64:tmp];
    [self add:qd];
    [qd release];
    //and remove all but the remainder of that division
    ACGBigNum* nd = [[ACGBigNum alloc] initWithUInt64:(tmp*num)];
    [origSelf sub:nd];
    origDigits = [origSelf digits];
    
    if(rem)
        *rem = origDigits[0];
}
- (void)divByTwo {
    int i;
    for(i=0; i<numDigits; i++) {
        digits[i] = digits[i] >> 1;
        
        if((i+1) < numDigits) {
            if(digits[i+1]%2)
                digits[i] += ((UInt64)1)<<63;
        }
    }
}
- (void)pow:(UInt64)num {
    if(num==0) {
        [self keepOnlyLowestDigit];
        digits[0] = 1;
        return;
    }
    
    ACGBigNum* base = [[self copy] autorelease];
    
    while(num > 1) {
        [self mul:base];
        num--;
    }
}

- (BOOL)isZero {
    int i;
    for(i=0; i<numDigits; i++) {
        if(digits[i] != 0)
            return NO;
    }
    
    return YES;
}

- (BOOL)isOne {
    if(digits[0] != 1)
        return NO;
    
    int i;
    for(i=1; i<numDigits; i++) {
        if(digits[i] != 0)
            return NO;
    }
    
    return YES;
}

#pragma mark string ops
- (NSString*)extractStringWithBaseChars:(NSString*)baseChars {
    NSMutableString* string = [NSMutableString string];
    int base = [baseChars length];
    ACGBigNum* num = [self copy];
    
    while(![num isZero]) {
        UInt64 rem;
        [num div:base remainder:&rem];
        NSRange range; range.location=rem; range.length=1;
        [string insertString:[baseChars substringWithRange:range] atIndex:0];
    }
    
    [num release];
    return string;
}
- (int) valueForChar:(unichar)ch baseChars:(NSString*)chars {
    NSString* tmpStr = [NSString stringWithCharacters:&ch length:1];
    NSRange range = [chars rangeOfString:tmpStr];
    return range.location;
}

#pragma mark utils

- (void)makeThisManyDigits:(UInt8)newNumDigits {
    if(newNumDigits <= numDigits)
        return;
    
    UInt64* newDigits = malloc(newNumDigits*sizeof(UInt64));
    NSAssert(newDigits, @"couldn't allocate new digits");
    int i;
    
    for(i=0;i<numDigits; i++) {
        newDigits[i] = digits[i];
    }
    
    for(;i<newNumDigits;i++) {
        newDigits[i] = 0;
    }
    
    free(digits);
    digits = newDigits;
    numDigits = newNumDigits;
}

- (void)clearExcessDigits {
    int i = numDigits-1;
    
    while((i>0) && (digits[i] == 0)) {
        i--;
    }
    
    //i is now the index of the highest non-zero digit
    //throw away all the rest
    UInt8 newNumDigits = i+1;
    UInt64* newDigits = malloc(newNumDigits*sizeof(UInt64));
    NSAssert(newDigits, @"couldn't allocate new digits");
    
    for(i=0;i<newNumDigits; i++) {
        newDigits[i] = digits[i];
    }
    
    free(digits);
    digits = newDigits;
    numDigits = newNumDigits;
}

- (void)keepOnlyLowestDigit {
    UInt64* newDigits = malloc(sizeof(UInt64));
    newDigits[0] = digits[0];
    free(digits);
    digits = newDigits;
    numDigits = 1;
}

@end
