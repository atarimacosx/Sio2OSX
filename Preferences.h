/* Preferences.h - Header for Preferences 
   window class and support functions for the
   Macintosh OS X SDL port of Atari800
   Mark Grebe <atarimac@cox.net>
   
   Based on the Preferences pane of the
   TextEdit application.

*/
#import <Cocoa/Cocoa.h>
#import "Atari825Simulator.h"
#import "Atari1020Simulator.h"
#import "EpsonFX80Simulator.h"
#import "SioController.h"

/* Keys in the dictionary... */
#define SerialPort @"SerialPort"
#define IgnoreAtrWriteProtect @"IgnoreAtrWriteProtect"
#define MaxSerialSpeed @"MaxSerialSpeed"
#define DelayFactor @"DelayFactor"
#define SioHWType @"SioHWType"  
#define PrintCommand @"PrintCommand"
#define PrinterType @"PrinterType"
#define Atari825CharSet @"Atari825CharSet"
#define Atari825FormLength @"Atari825FormLength"
#define Atari825AutoLinefeed @"Atari825AutoLinefeed"
#define Atari1020PrintWidth @"Atari1020PrintWidth"
#define Atari1020FormLength @"Atari1020FormLength"
#define Atari1020AutoLinefeed @"Atari825AutoLinefeed"
#define Atari1020AutoPageAdjust @"Atari1020AutoPageAdjust"
#define Atari1020Pen1Red @"Atari1020Pen1Red"
#define Atari1020Pen1Blue @"Atari1020Pen1Blue"
#define Atari1020Pen1Green @"Atari1020Pen1Green"
#define Atari1020Pen1Alpha @"Atari1020Pen1Alpha"
#define Atari1020Pen2Red @"Atari1020Pen2Red"
#define Atari1020Pen2Blue @"Atari1020Pen2Blue"
#define Atari1020Pen2Green @"Atari1020Pen2Green"
#define Atari1020Pen2Alpha @"Atari1020Pen2Alpha"
#define Atari1020Pen3Red @"Atari1020Pen3Red"
#define Atari1020Pen3Blue @"Atari1020Pen3Blue"
#define Atari1020Pen3Green @"Atari1020Pen3Green"
#define Atari1020Pen3Alpha @"Atari1020Pen3Alpha"
#define Atari1020Pen4Red @"Atari1020Pen4Red"
#define Atari1020Pen4Blue @"Atari1020Pen4Blue"
#define Atari1020Pen4Green @"Atari1020Pen4Green"
#define Atari1020Pen4Alpha @"Atari1020Pen4Alpha"
#define DialAddress1 @"DialAddress1"
#define DialAddress2 @"DialAddress2"
#define DialAddress3 @"DialAddress3"
#define DialAddress4 @"DialAddress4"
#define DialAddress5 @"DialAddress5"
#define DialAddress6 @"DialAddress6"
#define DialAddress7 @"DialAddress7"
#define DialAddress8 @"DialAddress8"
#define DialAddress9 @"DialAddress9"
#define DialAddress10 @"DialAddress10"
#define DialAddress11 @"DialAddress11"
#define DialAddress12 @"DialAddress12"
#define DialAddress13 @"DialAddress13"
#define DialAddress14 @"DialAddress14"
#define DialAddress15 @"DialAddress15"
#define DialAddress16 @"DialAddress16"
#define DialAddress17 @"DialAddress17"
#define DialAddress18 @"DialAddress18"
#define DialAddress19 @"DialAddress19"
#define DialAddress20 @"DialAddress20"
#define DialPort1 @"DialPort1"
#define DialPort2 @"DialPort2"
#define DialPort3 @"DialPort3"
#define DialPort4 @"DialPort4"
#define DialPort5 @"DialPort5"
#define DialPort6 @"DialPort6"
#define DialPort7 @"DialPort7"
#define DialPort8 @"DialPort8"
#define DialPort9 @"DialPort9"
#define DialPort10 @"DialPort10"
#define DialPort11 @"DialPort11"
#define DialPort12 @"DialPort12"
#define DialPort13 @"DialPort13"
#define DialPort14 @"DialPort14"
#define DialPort15 @"DialPort15"
#define DialPort16 @"DialPort16"
#define DialPort17 @"DialPort17"
#define DialPort18 @"DialPort18"
#define DialPort19 @"DialPort19"
#define DialPort20 @"DialPort20"
#define Enable850 @"Enable850"
#define EpsonCharSet @"EpsonCharSet"
#define EpsonPrintPitch @"EpsonPrintPitch"
#define EpsonPrintWeight @"EpsonPrintWeight"
#define EpsonFormLength @"EpsonFormLength"
#define EpsonAutoLinefeed @"EpsonAutoLinefeed"
#define EpsonPrintSlashedZeros @"EpsonPrintSlashedZeros"
#define EpsonAutoSkip @"EpsonAutoSkip"
#define EpsonSplitSkip @"EpsonSplitSkip"
#define IgnoreHeaderWriteprotect @"IgnoreHeaderWriteprotect"
#define PrintDir @"PrintDir"
#define ModemEcho @"ModemEcho"
#define ModemAutoAnswer @"ModemAutoAnswer"
#define ModemEscapeCharacter @"ModemEscapeCharacter"
#define NetServerOffMsg @"NetServerOffMsg"
#define NetServerBusyMsg @"NetServerBusyMsg"
#define NetServerEnable @"NetServerEnable"
#define NetServerPort @"NetServerPort"
#define SerialPort1Mode @"SerialPort1Mode"
#define SerialPort2Mode @"SerialPort2Mode"
#define SerialPort3Mode @"SerialPort3Mode"
#define SerialPort4Mode @"SerialPort4Mode"
#define SerialPort1Port @"SerialPort1Port"
#define SerialPort2Port @"SerialPort2Port"
#define SerialPort3Port @"SerialPort3Port"
#define SerialPort4Port @"SerialPort4Port"
#define DiskImageDir @"DiskImageDir"
#define CassImageDir @"CassImageDir"
#define DiskSetDir @"DiskSetDir"
#define UserName @"UserName"
#define UserKey @"UserKey"

@interface Preferences : NSObject {
	IBOutlet id ignoreAtrWriteProtectButton;
	IBOutlet id maxSerialSpeedPulldown;
	IBOutlet id delayFactorPulldown;
	IBOutlet id sioHWTypePulldown;
    IBOutlet id prefTabView;
    IBOutlet id diskImageDirField;
    IBOutlet id cassImageDirField;
    IBOutlet id diskSetDirField;
    IBOutlet id printCommandField;
	IBOutlet id printerTypePulldown;
	IBOutlet id printerTabView;
	IBOutlet id atari825CharSetPulldown;
	IBOutlet id atari825FormLengthField;
	IBOutlet id atari825FormLengthStepper;
	IBOutlet id atari825AutoLinefeedButton;
	IBOutlet id atari1020PrintWidthPulldown;
	IBOutlet id atari1020FormLengthField;
	IBOutlet id atari1020FormLengthStepper;
	IBOutlet id atari1020AutoLinefeedButton;
	IBOutlet id atari1020AutoPageAdjustButton;
	IBOutlet id atari1020Pen1Pot;
	IBOutlet id atari1020Pen2Pot;
	IBOutlet id atari1020Pen3Pot;
	IBOutlet id atari1020Pen4Pot;
	IBOutlet id epsonCharSetPulldown;
	IBOutlet id epsonPrintPitchPulldown;
	IBOutlet id epsonPrintWeightPulldown;
	IBOutlet id epsonFormLengthField;
	IBOutlet id epsonFormLengthStepper;
	IBOutlet id epsonAutoLinefeedButton;
	IBOutlet id epsonPrintSlashedZerosButton;
	IBOutlet id epsonAutoSkipButton;
	IBOutlet id epsonSplitSkipButton;
    IBOutlet id printDirField;
	IBOutlet id port1Pulldown;
	IBOutlet id port2Pulldown;
	IBOutlet id port3Pulldown;
	IBOutlet id port4Pulldown;
	IBOutlet id serverOffField;
	IBOutlet id serverBusyField;
	IBOutlet id serverEnabledButton;
	IBOutlet id serverPortField;
	IBOutlet id escapeEnabledButton;
	IBOutlet id escapeCharacterField;
	IBOutlet id modemEchoButton;
	IBOutlet id autoAnswerButton;
	IBOutlet id dialAddress1Field;
	IBOutlet id dialAddress2Field;
	IBOutlet id dialAddress3Field;
	IBOutlet id dialAddress4Field;
	IBOutlet id dialAddress5Field;
	IBOutlet id dialAddress6Field;
	IBOutlet id dialAddress7Field;
	IBOutlet id dialAddress8Field;
	IBOutlet id dialAddress9Field;
	IBOutlet id dialAddress10Field;
	IBOutlet id dialAddress11Field;
	IBOutlet id dialAddress12Field;
	IBOutlet id dialAddress13Field;
	IBOutlet id dialAddress14Field;
	IBOutlet id dialAddress15Field;
	IBOutlet id dialAddress16Field;
	IBOutlet id dialAddress17Field;
	IBOutlet id dialAddress18Field;
	IBOutlet id dialAddress19Field;
	IBOutlet id dialAddress20Field;
	IBOutlet id dialPort1Field;
	IBOutlet id dialPort2Field;
	IBOutlet id dialPort3Field;
	IBOutlet id dialPort4Field;
	IBOutlet id dialPort5Field;
	IBOutlet id dialPort6Field;
	IBOutlet id dialPort7Field;
	IBOutlet id dialPort8Field;
	IBOutlet id dialPort9Field;
	IBOutlet id dialPort10Field;
	IBOutlet id dialPort11Field;
	IBOutlet id dialPort12Field;
	IBOutlet id dialPort13Field;
	IBOutlet id dialPort14Field;
	IBOutlet id dialPort15Field;
	IBOutlet id dialPort16Field;
	IBOutlet id dialPort17Field;
	IBOutlet id dialPort18Field;
	IBOutlet id dialPort19Field;
	IBOutlet id dialPort20Field;
	
    NSMutableArray *modems;
    NSMutableDictionary *curValues;	// Current, confirmed values for the preferences
    NSDictionary *origValues;	// Values read from preferences at startup
    NSMutableDictionary *displayedValues;	// Values displayed in the UI
}

+ (id)objectForKey:(id)key;	/* Convenience for getting global preferences */
+ (void)saveDefaults;		/* Convenience for saving global preferences */
- (void)saveDefaults;		/* Save the current preferences */

+ (Preferences *)sharedInstance;

+ (void)setWorkingDirectory:(char *)dir;  /* Save the base directory of the application */
+ (char *)getWorkingDirectory;  /* Get the base directory of the application */

- (NSDictionary *)preferences;	/* The current preferences; contains values for the documented keys */

- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */
- (void)commitDisplayedValues;	/* The displayed values are made current */
- (void)discardDisplayedValues;	/* The displayed values are replaced with current prefs and updateUI is called */

- (void)revert:(id)sender;	/* Reverts the displayed values to the current preferences */
- (void)ok:(id)sender;		/* Calls commitUI to commit the displayed values as current */
- (void)revertToDefault:(id)sender;    

- (void)miscChanged:(id)sender;	/* Action message for most of the misc items in the UI to get displayedValues  */
- (void)portChanged:(id)sender;
- (void)addModem:(char *)modemName:(BOOL)first;
- (void)browsePrint:(id)sender; 
- (void)browseDiskDir:(id)sender; 
- (void)browseCassDir:(id)sender; 
- (void)browseDiskSetDir:(id)sender; 
- (void)transferValuesToAtari825;
- (void)transferValuesToAtari1020;
- (void)transferValuesToEpson;
- (void)transferValuesToSio;
- (void)transferValuesFromSio:(SIO_PREF_RET *)prefs;
- (void)transferUserStrings:(NSString *)name:(NSString *)key;
- (NSString *)getUserName;
- (NSString *)getUserKey;
- (BOOL)checkRegistration;
- (void)windowWillClose:(NSNotification *)notification;

+ (NSDictionary *)preferencesFromDefaults;
+ (void)savePreferencesToDefaults:(NSDictionary *)dict;

@end
