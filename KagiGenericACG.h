//
//  KagiGenericACG.h
//  KagiGenericACG
//
//  Created by Ben Rister on Tue Apr 20 2004.
//

#import <Foundation/Foundation.h>

/* input/output dictionary keys */
extern NSString* kACGName;
extern NSString* kACGEmail;
extern NSString* kACGHotSyncUsername;
extern NSString* kACGUserSeed;
extern NSString* kACGRegCode;
extern NSString* kACGSequenceNum;
extern NSString* kACGConstant;
extern NSString* kACGDateString;

/* configuration parameters */
extern NSString* kACGSupplierID;
extern NSString* kACGSeedCombination;
extern NSString* kACGUserSeedLength;
extern NSString* kACGMinEmailLength;
extern NSString* kACGMinNameLength;
extern NSString* kACGMinHotSyncLength;
extern NSString* kACGConstantLength;
extern NSString* kACGSequenceLength;
extern NSString* kACGScrambleOrder;
extern NSString* kACGASCIILength;
extern NSString* kACGAlternateText;
extern NSString* kACGMathOps;
extern NSString* kACGNewBase;
extern NSString* kACGBaseCharacterSet;
extern NSString* kACGRegCodeFormat;

/* typedefs/enums */
typedef enum {
    ee = 0,
    en = 1,
    ne = 2,
    nn = 3,
    hh = 4
} ACGSeedCombination;

@interface KagiGenericACG : NSObject {
    NSString* supplierID;
    ACGSeedCombination seedCombination;
    int userSeedLength;
    int minEmailLength;
    int minNameLength;
    int minHotSyncLength;
    int constantLength;
    NSString* constant;
    int sequenceLength;
    NSMutableArray* scrambleOrder;
    int ASCIILength;
    NSString* alternateText;
    NSMutableArray* mathOps;
    int newBase;
    NSString* baseCharacterSet;
    NSString* regCodeFormat;
}

//init

+ (id)acgWithConfigurationString:(NSString*)str;
+ (id)acgWithConfigurationDictionary:(NSDictionary*)dict;
+ (id)acgWithContentsOfFile:(NSString*)path;
- (id)initWithConfigurationString:(NSString*)str;
- (id)initWithConfigurationDictionary:(NSDictionary*)dict;
- (id)initWithContentsOfFile:(NSString*)path;

// accessors
- (NSString*) supplierID;
- (void) setSupplierID:(NSString*)str;
- (ACGSeedCombination) seedCombination;
- (void) setSeedCombination:(ACGSeedCombination)c;
- (int) userSeedLength;
- (void) setUserSeedLength:(int)l;
- (int) minEmailLength;
- (void) setMinEmailLength:(int)l;
- (int) minNameLength;
- (void) setMinNameLength:(int)l;
- (int) minHotSyncLength;
- (void) setMinHotSyncLength:(int)l;
- (int) constantLength;
- (void) setConstantLength:(int)l;
- (NSString*) constant;
- (void) setConstant:(NSString*)str;
- (int) sequenceLength;
- (void) setSequenceLength:(int)l;
- (NSArray*) scrambleOrder;
- (void) setScrambleOrder:(NSArray*)arr;
- (int) ASCIILength;
- (void) setASCIILength:(int)l;
- (NSString*) alternateText;
- (void) setAlternateText:(NSString*)txt;
- (NSArray*) mathOps;
- (void) setMathOps:(NSArray*)arr;
- (int) newBase;
- (void) setNewBase:(int)i;
- (NSString*) baseCharacterSet;
- (void) setBaseCharacterSet:(NSString*)str;
- (int) baseFormatDigits;
- (NSString*) regCodeFormat;
- (void) setRegCodeFormat:(NSString*)str;

// file I/O

- (BOOL) saveConfigToFile:(NSString*)path;
- (NSDictionary*) readConfigFromFile:(NSString*)path;

// standard ACG operations

- (NSString*)getRegCodeForName:(NSString*)name email:(NSString*)email hotSync:(NSString*)hotSync;
- (NSString*)getRegCodeForUserSeed:(NSString*)seed  sequenceNumber:(unsigned int)seq;
- (BOOL)regCode:(NSString*)code matchesName:(NSString*)name  email:(NSString*)email hotSync:(NSString*)hotSync;
- (NSDictionary*)infoFromRegCode:(NSString*)code;

// utilities
- (NSString*)translateKey:(NSString*)key;
- (ACGSeedCombination)decodeSeedCombo:(NSString*)str;
- (NSString*)encodeSeedCombo:(ACGSeedCombination)combo;
- (NSString*)getUserSeedForName:(NSString*)name email:(NSString*)email hotSync:(NSString*)hotSync;
- (NSString*)capitalizeAndStrip:(NSString*)rawUserSeed;
- (unichar) calculateChecksum:(NSString*)number;
- (int) valueForChar:(unichar)ch;
- (NSString*) getConfigurationString;

@end