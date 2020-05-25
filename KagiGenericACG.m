//
//  KagiGenericACG.m
//  KagiGenericACG
//
//  Created by Ben Rister on Tue Apr 20 2004.
//  8/25/2004 Bug Reported by Noah Lieberman Changed if([format length]  > [theCode length])
// to if([format length] - 3 > [theCode length]) in method infoFromRegCode:(NSString*)code
//
//  10/1/2004  Bug reported by Kevin Patfield. 
//  Decode code does not work correctly for ASCII length '3' and in particular for 'R' operations.
//  Fix provided by Kevin Patfield. Added line 	
//    if(ASCIILength == 3)
//            ch /= 10;		
//  in method infoFromRegCode();
// Fixed the bug wherein while encoding the final reg code had an excess of "#"  character
// method getRegCodeForName
// @author 3/25/2005 Rupali Desai
//  Bug reported by Rory Prior
// Fixed a bug reported by Stefani, wherein some valid codes where interpreted as being invalid 
// by the Decode logic.
// Fix in method infoFromRegCode
// @author 3/25/2005 Rupali Desai


#import "KagiGenericACG.h"
#import "ACGBigNum.h"

/* input and output dictionary keys */
NSString* kACGUserSeed = @"UserSeed";
NSString* kACGRegCode = @"RegCode";
NSString* kACGSequenceNum = @"SequenceNum";
NSString* kACGConstant = @"Constant";
NSString* kACGDateString = @"DateString";

/* configuration parameters */
NSString* kACGSupplierID = @"SupplierID";
NSString* kACGSeedCombination = @"SeedCombo";
NSString* kACGUserSeedLength = @"SeedLength";
NSString* kACGMinEmailLength = @"MinEmailLength";
NSString* kACGMinNameLength = @"MinNameLength";
NSString* kACGMinHotSyncLength = @"MinHotSyncLength";
NSString* kACGConstantLength = @"ConstantLength";
NSString* kACGSequenceLength = @"SequenceLength";
NSString* kACGScrambleOrder = @"ScrambleOrder";
NSString* kACGASCIILength = @"ASCIILength";
NSString* kACGAlternateText = @"AltText";
NSString* kACGMathOps = @"MathOps";
NSString* kACGNewBase = @"NewBase";
NSString* kACGBaseCharacterSet = @"BaseCharSet";
NSString* kACGRegCodeFormat = @"RegCodeFormat";

@implementation KagiGenericACG

#pragma mark init

+ (id)acgWithConfigurationString:(NSString*)str {
    return [[[KagiGenericACG alloc] initWithConfigurationString:str] autorelease];
}
+ (id)acgWithConfigurationDictionary:(NSDictionary*)dict {
    return [[[KagiGenericACG alloc] initWithConfigurationDictionary:dict] autorelease];
}
+ (id)acgWithContentsOfFile:(NSString*)path {
    return [[[KagiGenericACG alloc] initWithContentsOfFile:path] autorelease];
}

- (id)initWithConfigurationString:(NSString*)str {
    NSArray* arr = [str componentsSeparatedByString:@"%"];
    NSEnumerator* e = [arr objectEnumerator];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSString* param;
    
    while(param = [e nextObject]) {
        NSArray* tmpArr = [param componentsSeparatedByString:@":"];
        [dict setObject:[tmpArr objectAtIndex:1] forKey:[self translateKey:[tmpArr objectAtIndex:0]]];
    }
    
    return [self initWithConfigurationDictionary:dict];
}

- (id)initWithConfigurationDictionary:(NSDictionary*)dict {
    if(self = [super init]) {
        NSEnumerator* e = [dict keyEnumerator];
        NSString* key;
        
        while(key = [e nextObject]) {
            id val = [dict objectForKey:key];
            if([key isEqualToString:kACGSupplierID])
                supplierID = [[val copy] retain];
            else if([key isEqualToString:kACGSeedCombination])
                seedCombination = [self decodeSeedCombo:val];
            else if([key isEqualToString:kACGUserSeedLength])
                userSeedLength = [val intValue];
            else if([key isEqualToString:kACGMinEmailLength])
                minEmailLength = [val intValue];
            else if([key isEqualToString:kACGMinNameLength])
                minNameLength = [val intValue];
            else if([key isEqualToString:kACGMinHotSyncLength])
                minHotSyncLength = [val intValue];
            else if([key isEqualToString:kACGConstantLength])
                constantLength = [val intValue];
            else if([key isEqualToString:kACGConstant])
                constant = [[val copy] retain];
            else if([key isEqualToString:kACGSequenceLength])
                sequenceLength = [val intValue];
            else if([key isEqualToString:kACGScrambleOrder])
                scrambleOrder = [[val componentsSeparatedByString:@",,"] mutableCopy];
            else if([key isEqualToString:kACGASCIILength])
                ASCIILength = [val intValue];
            else if([key isEqualToString:kACGAlternateText])
                alternateText = [[val copy] retain];
            else if([key isEqualToString:kACGMathOps])
                mathOps = [[val componentsSeparatedByString:@",,"] mutableCopy];
            else if([key isEqualToString:kACGNewBase])
                newBase = [val intValue];
            else if([key isEqualToString:kACGBaseCharacterSet])
                baseCharacterSet = [[val copy] retain];
            else if([key isEqualToString:kACGRegCodeFormat])
                regCodeFormat = [[val copy] retain];
        }
        
        //fix up some common problems with the configs
        [scrambleOrder removeObject:@""];
        [mathOps removeObject:@""];
    }
    
    return self;
}

- (id)initWithContentsOfFile:(NSString*)path {
    return [self initWithConfigurationDictionary:[self readConfigFromFile:path]];
}

#pragma mark accessors
- (NSString*) supplierID {
    return supplierID;
}
- (void) setSupplierID:(NSString*)str {
    [supplierID autorelease];
    supplierID = [str copy];
}
- (ACGSeedCombination) seedCombination {
    return seedCombination;
}
- (void) setSeedCombination:(ACGSeedCombination)c {
    seedCombination = c;
}
- (int) userSeedLength {
    return userSeedLength;
}
- (void) setUserSeedLength:(int)l {
    userSeedLength = l;
}
- (int) minEmailLength {
    return minEmailLength;
}
- (void) setMinEmailLength:(int)l {
    minEmailLength = l;
}
- (int) minNameLength {
    return minNameLength;
}
- (void) setMinNameLength:(int)l {
    minNameLength = l;
}
- (int) minHotSyncLength {
    return minHotSyncLength;
}
- (void) setMinHotSyncLength:(int)l {
    minHotSyncLength = l;
}
- (int) constantLength {
    return constantLength;
}
- (void) setConstantLength:(int)l {
    constantLength = l;
}
- (NSString*) constant {
    return constant;
}
- (void) setConstant:(NSString*)str {
    [constant autorelease];
    constant = [str copy];
}
- (int) sequenceLength {
    return sequenceLength;
}
- (void) setSequenceLength:(int)l {
    sequenceLength = l;
}
- (NSArray*) scrambleOrder {
    return scrambleOrder;
}
- (void) setScrambleOrder:(NSArray*)arr {
    [scrambleOrder autorelease];
    scrambleOrder = [arr copy];
}
- (int) ASCIILength {
    return ASCIILength;
}
- (void) setASCIILength:(int)l {
    ASCIILength = l;
}
- (NSString*) alternateText {
    return alternateText;
}
- (void) setAlternateText:(NSString*)txt {
    [alternateText autorelease];
    alternateText = [txt copy];
}
- (NSArray*) mathOps {
    return mathOps;
}
- (void) setMathOps:(NSArray*)arr {
    [mathOps autorelease];
    mathOps = [arr copy];
}
- (int) newBase {
    return newBase;
}
- (void) setNewBase:(int)i {
    newBase = i;
}
- (NSString*) baseCharacterSet {
    return baseCharacterSet;
}
- (void) setBaseCharacterSet:(NSString*)str {
    [baseCharacterSet autorelease];
    baseCharacterSet = [str copy];
}
- (int) baseFormatDigits {
    int i;
    int numDigits = 255;
    
    NSString* savedFormat = [self regCodeFormat];
    [self setRegCodeFormat:@"#"];
    
    // do this 10 times to make sure we got the shortest string with high probability
    for(i=0; i<10; i++) {
        // create a random user seed
        NSString* alphabet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        NSMutableString* tmpUserSeed = [NSMutableString string];
        while([tmpUserSeed length] < [self userSeedLength]) {
            [tmpUserSeed appendString:[alphabet substringWithRange:NSMakeRange(random()%26,1)]];
        }
        
        // calculate the reg code
        NSString* regCode = [self getRegCodeForUserSeed:tmpUserSeed sequenceNumber:random()%10];
        if([regCode length] < numDigits)
            numDigits = [regCode length];
    }
    
    [self setRegCodeFormat:savedFormat];
    
    return numDigits;
}
- (NSString*) regCodeFormat {
    return regCodeFormat;
}
- (void) setRegCodeFormat:(NSString*)str {
    [regCodeFormat autorelease];
    regCodeFormat = [str copy];
}

#pragma mark file I/O

- (BOOL) saveConfigToFile:(NSString*)path {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if(supplierID)
        [dict setObject:supplierID forKey:kACGSupplierID];
    [dict setObject:[self encodeSeedCombo:seedCombination] forKey:kACGSeedCombination];
    [dict setObject:[[NSNumber numberWithInt:userSeedLength] stringValue] forKey:kACGUserSeedLength];
    [dict setObject:[[NSNumber numberWithInt:minEmailLength] stringValue] forKey:kACGMinEmailLength];
    [dict setObject:[[NSNumber numberWithInt:minNameLength] stringValue] forKey:kACGMinNameLength];
    [dict setObject:[[NSNumber numberWithInt:minHotSyncLength] stringValue] forKey:kACGMinHotSyncLength];
    [dict setObject:[[NSNumber numberWithInt:constantLength] stringValue] forKey:kACGConstantLength];
    [dict setObject:constant forKey:kACGConstant];
    [dict setObject:[[NSNumber numberWithInt:sequenceLength] stringValue] forKey:kACGSequenceLength];
    if(scrambleOrder)
        [dict setObject:[scrambleOrder componentsJoinedByString:@",,"] forKey:kACGScrambleOrder];
    [dict setObject:[[NSNumber numberWithInt:ASCIILength] stringValue] forKey:kACGASCIILength];
    if(alternateText)
        [dict setObject:alternateText forKey:kACGAlternateText];
    if(mathOps)
        [dict setObject:[mathOps componentsJoinedByString:@",,"] forKey:kACGMathOps];
    [dict setObject:[[NSNumber numberWithInt:newBase] stringValue] forKey:kACGNewBase];
    if(baseCharacterSet)
        [dict setObject:baseCharacterSet forKey:kACGBaseCharacterSet];
    if(regCodeFormat)
        [dict setObject:regCodeFormat forKey:kACGRegCodeFormat];
    
    return [dict writeToFile:path atomically:YES];
}
- (NSDictionary*) readConfigFromFile:(NSString*)path {
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

#pragma mark standard ACG operations

- (NSString*)getRegCodeForName:(NSString*)name email:(NSString*)email hotSync:(NSString*)hotSync {
    return [self getRegCodeForUserSeed:[self getUserSeedForName:name email:email hotSync:hotSync] sequenceNumber:0];
}
- (NSString*)getRegCodeForUserSeed:(NSString*)seed sequenceNumber:(unsigned int)seq {
    if(!seed)
        return alternateText;
    if([seed length] != userSeedLength)
        return @"Seed isn't the right length";
    
    // used to keep memory consumption down on some steps
    NSAutoreleasePool* pool;
    
    //create a date string for today
    NSCalendarDate* today = [NSCalendarDate date];
    NSString* dateStr = [[NSNumber numberWithInt:[today dayOfYear]] stringValue];
    dateStr = [dateStr stringByAppendingString:[[NSNumber numberWithInt:([today yearOfCommonEra]%10)] stringValue]];
    while([dateStr length] < 4) {
        NSString* zeroString = @"0";
        dateStr = [zeroString stringByAppendingString:dateStr];
    }
    
    //create sequence number 000
    NSMutableString* sequence = [NSMutableString stringWithString:[[NSNumber numberWithUnsignedInt:seq] stringValue]];
    if([sequence length] > sequenceLength)
        return @"Sequence number too long";
    while([sequence length] < sequenceLength)
        [sequence insertString:@"0" atIndex:0];
    
    //scramble seed characters
    NSMutableString* scrambledSeed = [NSMutableString string];
    NSEnumerator* e = [scrambleOrder objectEnumerator];
    NSString* scrambleCode;
    while(scrambleCode = [e nextObject]) {
        unichar ch = [scrambleCode characterAtIndex:0];
        int idx = [[scrambleCode substringFromIndex:1] intValue];
        unichar newCh;
        switch(ch) {
            case 'U':
                newCh = [seed characterAtIndex:idx];
                break;
            case 'C':
                newCh = [constant characterAtIndex:idx];
                break;
            case 'S':
                newCh = [sequence characterAtIndex:idx];
                break;
            case 'D':
                newCh = [dateStr characterAtIndex:idx];
                break;
            default:
                return @"Invalid scramble code";
                break;
        }
        [scrambledSeed appendString:[NSString stringWithCharacters:&newCh length:1]];
    }
    
    //perform math operations
    NSMutableString* bigBase10Number = [NSMutableString string];
    int i;
    if([mathOps count] < [scrambledSeed length])
        return @"Too few math ops for scrambled seed length";
    pool = [[NSAutoreleasePool alloc] init];
    for(i=0; i<[scrambledSeed length]; i++) {
        NSString* mathOp = [mathOps objectAtIndex:i];
        unichar op = [mathOp characterAtIndex:([mathOp length]-1)];
        int value = [[mathOp substringToIndex:([mathOp length]-1)] intValue];
        unichar ch = [scrambledSeed characterAtIndex:i];
        
        int newVal;
        
        switch(op) {
            case 'A':
                newVal = ch + value;
                break;
            case 'S':
                newVal = ch - value;
                break;
            case 'M':
                newVal = ch * value;
                break;
            case 'R':
                newVal = (ch%10)*10 + (ch/10);
                if(ASCIILength == 3)
                    newVal *= 10;
                break;
            default:
                return @"Invalid math op code";
        }
        
        //convert to string, pad to ASCIILength characters if necessary
        NSString* charString = [[NSNumber numberWithInt:newVal] stringValue];
        while([charString length] < ASCIILength) {
            NSString* zeroString = @"0";
            charString = [zeroString stringByAppendingString:charString];
        }
        
        //append to bigBase10Number
        [bigBase10Number appendString:charString];
    }
    [pool release];
    
    //convert bigBase10Number to newBase
    ACGBigNum* bigNum = [[[ACGBigNum alloc] initWithString:bigBase10Number baseChars:@"0123456789"] autorelease];
    NSString* bigNewBaseNumber = [bigNum extractStringWithBaseChars:baseCharacterSet];
    
    //calculate checksum
    unichar checksum = [self calculateChecksum:bigNewBaseNumber];
    NSString* checksumStr = [NSString stringWithCharacters:&checksum length:1];
    
    //format it like the registration code
    NSMutableString* newCode = [regCodeFormat mutableCopy];
    for(i=0; i<[bigNewBaseNumber length]; i++) {
	
        NSRange theRange = [newCode rangeOfString:@"#"];
        NSRange tmpRange; tmpRange.location = i; tmpRange.length = 1;
        if(theRange.location == NSNotFound) {
            tmpRange.length = [bigNewBaseNumber length] - i;
            [newCode appendString:[bigNewBaseNumber substringWithRange:tmpRange]];
            break;
        }
        
        [newCode replaceCharactersInRange:theRange withString:[bigNewBaseNumber substringWithRange:tmpRange]];
    }
    // find [] block if it exists, handle appropriately
    {
        NSRange origRange = [regCodeFormat rangeOfString:@"["];
        NSRange tmpRange = [regCodeFormat rangeOfString:@"]"];
        if((origRange.location != NSNotFound) && (tmpRange.location != NSNotFound)) {
            origRange.length = tmpRange.location - origRange.location + 1;
            
            if([[newCode substringWithRange:origRange] isEqualToString:[regCodeFormat substringWithRange:origRange]]) {
                //if they're equal, then we didn't change anything within it
                //remove it from the code
                [newCode deleteCharactersInRange:origRange];
            }
        }
    }
    
    
    [newCode replaceOccurrencesOfString:@"^" withString:checksumStr options:NSLiteralSearch range:NSMakeRange(0,[newCode length])];
	
	// replace any extra # character in the reg code Bug Fix  3/25/2005 
	{
	
	   NSRange tmpRange = [newCode rangeOfString:@"#"];
	   if (tmpRange.location != NSNotFound) {
	  
	     [newCode deleteCharactersInRange:tmpRange];
	   }
	}
	    
    return newCode;
}

- (BOOL)regCode:(NSString*)code matchesName:(NSString*)name  email:(NSString*)email hotSync:(NSString*)hotSync {
    NSDictionary* info = [self infoFromRegCode:code];
    if(!info)
        return NO;
    
    NSString* realSeed = [self getUserSeedForName:name email:email hotSync:hotSync];
    NSString* codeSeed = [info objectForKey:kACGUserSeed];
    
    return [realSeed isEqualToString:codeSeed];
}
- (NSDictionary*)infoFromRegCode:(NSString*)code {
    //unformat the code
    NSMutableString* format = [regCodeFormat mutableCopy];
    NSMutableString* bigNewBaseNumber = [NSMutableString string];
    NSMutableString* theCode = [code mutableCopy];
    unichar checksum = 0;
    
	//if([format length] - 4 > [theCode length])
//        return NULL;
    // 3/25/2005 Fix bug wherein some codes were interpreted as invalid
	
    while(([format length] > 0) && ([theCode length] > 0)) {
        unichar ch = [format characterAtIndex:0];
        if(ch == '#') {
            [bigNewBaseNumber appendString:[theCode substringWithRange:NSMakeRange(0,1)]];
			 [format deleteCharactersInRange:NSMakeRange(0,1)];
			[theCode deleteCharactersInRange:NSMakeRange(0,1)];
        } else if(ch == '^') {
            unichar tmpChecksum = [theCode characterAtIndex:0];
            if((checksum != 0) && (tmpChecksum != checksum))
                return NULL;
            checksum = tmpChecksum;
			 [format deleteCharactersInRange:NSMakeRange(0,1)];
        [theCode deleteCharactersInRange:NSMakeRange(0,1)];
        }
		else if(ch == '[' || ch == ']') {
			
			 [format deleteCharactersInRange:NSMakeRange(0,1)];
		}
		else {
		
			 [format deleteCharactersInRange:NSMakeRange(0,1)];
        [theCode deleteCharactersInRange:NSMakeRange(0,1)];
		}
        
       
    }
    //anything left just gets appended to the code
    [bigNewBaseNumber appendString:theCode];
    
    //calculate checksum and verify
    if((checksum == 0) || (checksum != [self calculateChecksum:bigNewBaseNumber]))
        return NULL;
    
    //convert to base 10
    ACGBigNum* bigNum = [[[ACGBigNum alloc] initWithString:bigNewBaseNumber baseChars:baseCharacterSet] autorelease];
    NSString* bigBase10Number = [bigNum extractStringWithBaseChars:@"0123456789"];
    
    //unperform math operations
    NSMutableString* scrambledSeed = [NSMutableString string];
    int i;
    //number length should be a multiple of ASCIILength
    while(([bigBase10Number length] % ASCIILength) != 0) {
        NSString* zero = @"0";
        bigBase10Number = [zero stringByAppendingString:bigBase10Number];
    }
    //need to have enough math ops for the number
    if([mathOps count] < ([bigBase10Number length]/ASCIILength))
        return NULL;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    for(i=0; i<[bigBase10Number length]; i+=ASCIILength) {
        //extract number from string
        NSString* charString = [bigBase10Number substringWithRange:NSMakeRange(i,ASCIILength)];
        int ch = [charString intValue];
        
        NSString* mathOp = [mathOps objectAtIndex:(i/ASCIILength)];
        unichar op = [mathOp characterAtIndex:([mathOp length]-1)];
        int value = [[mathOp substringToIndex:([mathOp length]-1)] intValue];
        
        unichar newVal;
        
        switch(op) {
            case 'A':
                newVal = ch - value;
                break;
            case 'S':
                newVal = ch + value;
                break;
            case 'M':
                if((ch%value) != 0)
                    return NULL;
                newVal = ch / value;
                break;
            case 'R':
	    	if(ASCIILength == 3)				
                    ch /= 10;			
                newVal = (ch%10)*10 + (ch/10);
                break;
            default:
                return NULL;
        }

        [scrambledSeed appendString:[NSString stringWithCharacters:&newVal length:1]];
    }
    [pool release];
    
    //descramble the seed
    NSMutableString* codeUserSeed = [NSMutableString string];
    NSMutableString* codeConstant = [NSMutableString string];
    NSMutableString* codeSequence = [NSMutableString string];
    NSMutableString* codeDate = [NSMutableString string];
    
    for(i=0; i<userSeedLength; i++) {
        NSString* source = @"U";
        NSString* scrambleCode = [source stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
        int idx = [scrambleOrder indexOfObject:scrambleCode];
        [codeUserSeed appendString:[scrambledSeed substringWithRange:NSMakeRange(idx,1)]];
    }
    for(i=0; i<sequenceLength; i++) {
        NSString* source = @"S";
        NSString* scrambleCode = [source stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
        int idx = [scrambleOrder indexOfObject:scrambleCode];
        [codeSequence appendString:[scrambledSeed substringWithRange:NSMakeRange(idx,1)]];
    }
    for(i=0; i<constantLength; i++) {
        NSString* source = @"C";
        NSString* scrambleCode = [source stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
        int idx = [scrambleOrder indexOfObject:scrambleCode];
        [codeConstant appendString:[scrambledSeed substringWithRange:NSMakeRange(idx,1)]];
    }
    for(i=0; i<4; i++) {
        NSString* source = @"D";
        NSString* scrambleCode = [source stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
        int idx = [scrambleOrder indexOfObject:scrambleCode];
        [codeDate appendString:[scrambledSeed substringWithRange:NSMakeRange(idx,1)]];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        codeUserSeed, kACGUserSeed,
        codeSequence, kACGSequenceNum,
        codeConstant, kACGConstant,
        codeDate, kACGDateString,
        NULL];
}

#pragma mark utilities
- (NSString*)translateKey:(NSString*)str {
    if([str isEqualToString:@"SUPPLIERID"])
        return kACGSupplierID;
    else if([str isEqualToString:@"E"])
        return kACGMinEmailLength;
    else if([str isEqualToString:@"N"])
        return kACGMinNameLength;
    else if([str isEqualToString:@"H"])
        return kACGMinHotSyncLength;
    else if([str isEqualToString:@"COMBO"])
        return kACGSeedCombination;
    else if([str isEqualToString:@"SDLGTH"])
        return kACGUserSeedLength;
    else if([str isEqualToString:@"CONSTLGTH"])
        return kACGConstantLength;
    else if([str isEqualToString:@"CONSTVAL"])
        return kACGConstant;
    else if([str isEqualToString:@"SEQL"])
        return kACGSequenceLength;
    else if([str isEqualToString:@"ALTTEXT"])
        return kACGAlternateText;
    else if([str isEqualToString:@"SCRMBL"])
        return kACGScrambleOrder;
    else if([str isEqualToString:@"ASCDIG"])
        return kACGASCIILength;
    else if([str isEqualToString:@"MATH"])
        return kACGMathOps;
    else if([str isEqualToString:@"BASE"])
        return kACGNewBase;
    else if([str isEqualToString:@"BASEMAP"])
        return kACGBaseCharacterSet;
    else if([str isEqualToString:@"REGFRMT"])
        return kACGRegCodeFormat;
    else
        return str;
}
- (ACGSeedCombination)decodeSeedCombo:(NSString*)str {
    if([str isEqualToString:@"ee"])
        return ee;
    else if([str isEqualToString:@"en"])
        return en;
    else if([str isEqualToString:@"ne"])
        return ne;
    else if([str isEqualToString:@"nn"])
        return nn;
    else if([str isEqualToString:@"hh"])
        return hh;
    else
        NSAssert(false, @"Bad seed combo string");
    
    //to make compiler shut up
    return 0;
}
- (NSString*)encodeSeedCombo:(ACGSeedCombination)combo {
    switch (combo) {
        case ee:
            return @"ee";
        case en:
            return @"en";
        case ne:
            return @"ne";
        case nn:
            return @"nn";
        case hh:
            return @"hh";
        default:
            return NULL;
    }
}
- (NSString*)getUserSeedForName:(NSString*)name email:(NSString*)email hotSync:(NSString*)hotSync {
    NSString* userSeed;
    switch(seedCombination) {
        case ee:
            userSeed = email;
            if([email length] < minEmailLength)
                return NULL;
            break;
        case en:
            userSeed = [email stringByAppendingString:name];
            if([email length] < minEmailLength)
                return NULL;
            if([name length] < minNameLength)
                return NULL;
            break;
        case ne:
            userSeed = [name stringByAppendingString:email];
            if([email length] < minEmailLength)
                return NULL;
            if([name length] < minNameLength)
                return NULL;
            break;
        case nn:
            userSeed = name;
            if([name length] < minNameLength)
                return NULL;
            break;
        case hh:
            userSeed = hotSync;
            if([hotSync length] < minHotSyncLength)
                return NULL;
            break;
        default:
            return NULL;
    }
    
    userSeed = [self capitalizeAndStrip:userSeed];
    
    userSeed = [userSeed stringByPaddingToLength:userSeedLength withString:userSeed startingAtIndex:0];
    
    return userSeed;
}

- (NSString*)capitalizeAndStrip:(NSString*)rawUserSeed {
    rawUserSeed = [rawUserSeed uppercaseString];
    NSMutableString* newUserSeed = [NSMutableString string];
    NSCharacterSet* digCharSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet* letCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSRange range;
    range.length=1;
    for(range.location=0; range.location<[rawUserSeed length]; range.location++) {
        unichar ch = [rawUserSeed characterAtIndex:range.location];
        if([digCharSet characterIsMember:ch] || [letCharSet characterIsMember:ch])
            [newUserSeed appendString:[rawUserSeed substringWithRange:range]];
    }
    
    return newUserSeed;
}

- (unichar) calculateChecksum:(NSString*)number {
    int idx = [number length] - 1;
    int weight = 2;
    UInt64 sum = 0;
    
    while(idx >= 0) {
        sum += [self valueForChar:[number characterAtIndex:idx]] * weight;
        if(weight == 1)
            weight = 2;
        else
            weight = 1;
        idx--;
    }
    
    sum %= newBase;
    
    return [baseCharacterSet characterAtIndex:sum];
}

- (int) valueForChar:(unichar)ch {
    NSString* tmpStr = [NSString stringWithCharacters:&ch length:1];
    NSRange range = [baseCharacterSet rangeOfString:tmpStr];
    return range.location;
}

- (NSString*) getConfigurationString {
    return [NSString stringWithFormat:@"SUPPLIERID:%@%%E:%d%%N:%d%%H:%d%%COMBO:%@%%SDLGTH:%d%%CONSTLGTH:%d%%CONSTVAL:%@%%SEQL:%d%%ALTTEXT:%@%%SCRMBL:%@,,%%ASCDIG:%d%%MATH:%@,,%%BASE:%d%%BASEMAP:%@%%REGFRMT:%@",
        supplierID, minEmailLength, minNameLength, minHotSyncLength, [self encodeSeedCombo:seedCombination], userSeedLength, constantLength, constant, sequenceLength, alternateText,
        [scrambleOrder componentsJoinedByString:@",,"], ASCIILength, [mathOps componentsJoinedByString:@",,"], newBase, baseCharacterSet, regCodeFormat];
}




@end

