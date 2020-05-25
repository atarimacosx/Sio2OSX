/* Preferences.m - Preferences window 
   class and support functions for the
   Macintosh OS X SDL port of Atari800
   Mark Grebe <atarimac@cox.net>
   
   Based on the Preferences pane of the
   TextEdit application.

*/
#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "PrintOutputController.h"

extern ATARI825_PREF prefs825;
extern ATARI1020_PREF prefs1020;
extern EPSON_PREF prefsEpson;
extern SIO_PREF prefsSio;

static char workingDirectory[FILENAME_MAX], printDirStr[FILENAME_MAX];
static char diskImageDirStr[FILENAME_MAX],diskSetDirStr[FILENAME_MAX];
static char cassImageDirStr[FILENAME_MAX];

/*------------------------------------------------------------------------------
*  defaultValues - This method sets up the default values for the preferences
*-----------------------------------------------------------------------------*/
static NSDictionary *defaultValues() {
    static NSDictionary *dict = nil;
    
    strcpy(printDirStr, workingDirectory);
    strcpy(diskImageDirStr, workingDirectory);
    strcpy(cassImageDirStr, workingDirectory);
    strcpy(diskSetDirStr, workingDirectory);
    
    if (!dict) {
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSNumber numberWithBool:NO], IgnoreAtrWriteProtect,
				[NSNumber numberWithInt:2],MaxSerialSpeed,
				[NSNumber numberWithInt:0],DelayFactor,
				[NSNumber numberWithInt:0],SioHWType,
                [NSString stringWithString:@"open %s"],PrintCommand,
				[NSNumber numberWithInt:0],PrinterType,
				[NSNumber numberWithInt:0],Atari825CharSet,
				[NSNumber numberWithInt:11],Atari825FormLength,
				[NSNumber numberWithBool:YES],Atari825AutoLinefeed,
				[NSNumber numberWithInt:0],Atari1020PrintWidth,
				[NSNumber numberWithInt:11],Atari1020FormLength,
				[NSNumber numberWithBool:YES],Atari1020AutoLinefeed,
				[NSNumber numberWithBool:YES],Atari1020AutoPageAdjust,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen1Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen1Alpha,
				[NSNumber numberWithFloat:0.0],Atari1020Pen2Red,
				[NSNumber numberWithFloat:1.0],Atari1020Pen2Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen2Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen2Alpha,
				[NSNumber numberWithFloat:0.0],Atari1020Pen3Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen3Blue,
				[NSNumber numberWithFloat:1.0],Atari1020Pen3Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen3Alpha,
				[NSNumber numberWithFloat:1.0],Atari1020Pen4Red,
				[NSNumber numberWithFloat:0.0],Atari1020Pen4Blue,
				[NSNumber numberWithFloat:0.0],Atari1020Pen4Green,
				[NSNumber numberWithFloat:1.0],Atari1020Pen4Alpha,
                [NSString stringWithString:@""], DialAddress1, 
                [NSString stringWithString:@""], DialAddress2, 
                [NSString stringWithString:@""], DialAddress3, 
                [NSString stringWithString:@""], DialAddress4, 
                [NSString stringWithString:@""], DialAddress5, 
                [NSString stringWithString:@""], DialAddress6, 
                [NSString stringWithString:@""], DialAddress7, 
                [NSString stringWithString:@""], DialAddress8, 
                [NSString stringWithString:@""], DialAddress9, 
                [NSString stringWithString:@""], DialAddress10, 
                [NSString stringWithString:@""], DialAddress11, 
                [NSString stringWithString:@""], DialAddress12, 
                [NSString stringWithString:@""], DialAddress13, 
                [NSString stringWithString:@""], DialAddress14, 
                [NSString stringWithString:@""], DialAddress15, 
                [NSString stringWithString:@""], DialAddress16, 
                [NSString stringWithString:@""], DialAddress17, 
                [NSString stringWithString:@""], DialAddress18, 
                [NSString stringWithString:@""], DialAddress19, 
                [NSString stringWithString:@""], DialAddress20, 
                [NSNumber numberWithInt:23], DialPort1, 
                [NSNumber numberWithInt:23], DialPort2, 
                [NSNumber numberWithInt:23], DialPort3, 
                [NSNumber numberWithInt:23], DialPort4, 
                [NSNumber numberWithInt:23], DialPort5, 
                [NSNumber numberWithInt:23], DialPort6, 
                [NSNumber numberWithInt:23], DialPort7, 
                [NSNumber numberWithInt:23], DialPort8, 
                [NSNumber numberWithInt:23], DialPort9, 
                [NSNumber numberWithInt:23], DialPort10, 
                [NSNumber numberWithInt:23], DialPort11, 
                [NSNumber numberWithInt:23], DialPort12, 
                [NSNumber numberWithInt:23], DialPort13, 
                [NSNumber numberWithInt:23], DialPort14, 
                [NSNumber numberWithInt:23], DialPort15, 
                [NSNumber numberWithInt:23], DialPort16, 
                [NSNumber numberWithInt:23], DialPort17, 
                [NSNumber numberWithInt:23], DialPort18, 
                [NSNumber numberWithInt:23], DialPort19, 
                [NSNumber numberWithInt:23], DialPort20, 
				[NSNumber numberWithBool:NO], Enable850,
				[NSNumber numberWithInt:0],EpsonCharSet,
				[NSNumber numberWithInt:0],EpsonPrintPitch,
				[NSNumber numberWithInt:0],EpsonPrintWeight,
				[NSNumber numberWithInt:11],EpsonFormLength,
				[NSNumber numberWithBool:YES],EpsonAutoLinefeed,
				[NSNumber numberWithInt:NO],EpsonPrintSlashedZeros,
				[NSNumber numberWithInt:NO],EpsonAutoSkip,
				[NSNumber numberWithInt:NO],EpsonSplitSkip,
                [NSString stringWithCString:printDirStr], PrintDir, 
				[NSNumber numberWithBool:YES],ModemEcho,
				[NSNumber numberWithBool:NO],ModemAutoAnswer,
				[NSNumber numberWithInt:43],ModemEscapeCharacter,
				[NSString stringWithString:@"The BBS is not ready to accept connections.  Please try again later."], NetServerOffMsg,
				[NSString stringWithString:@"The BBS is currently connected to another client.  Please try again later."], NetServerBusyMsg,
				[NSNumber numberWithBool:NO], NetServerEnable,
				[NSNumber numberWithInt:23], NetServerPort,
				[NSNumber numberWithInt:PORT_850_NET_MODE], SerialPort1Mode,
				[NSNumber numberWithInt:PORT_850_OFF], SerialPort2Mode,
				[NSNumber numberWithInt:PORT_850_OFF], SerialPort3Mode,
				[NSNumber numberWithInt:PORT_850_OFF], SerialPort4Mode,
                [NSString stringWithString:@""], SerialPort1Port, 
                [NSString stringWithString:@""], SerialPort2Port, 
                [NSString stringWithString:@""], SerialPort3Port, 
                [NSString stringWithString:@""], SerialPort4Port, 
                [NSString stringWithCString:diskImageDirStr], DiskImageDir, 
                [NSString stringWithCString:cassImageDirStr], CassImageDir, 
                [NSString stringWithCString:diskSetDirStr], DiskSetDir, 
				[NSString stringWithString:@""], SerialPort,
				[NSString stringWithString:@""], UserName,
				[NSString stringWithString:@""], UserKey,
		nil];
    }
    return dict;
}

@implementation Preferences

static Preferences *sharedInstance = nil;

+ (Preferences *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

/* The next few factory methods are conveniences, working on the shared instance
*/
+ (id)objectForKey:(id)key {
    return [[[self sharedInstance] preferences] objectForKey:key];
}

+ (void)saveDefaults {
    [[self sharedInstance] saveDefaults];
}

/*------------------------------------------------------------------------------
*  setWorkingDirectory - Sets the working directory to the folder containing the
*     app.
*-----------------------------------------------------------------------------*/
+ (void)setWorkingDirectory:(char *)dir {
    char *c = workingDirectory;

    strncpy ( workingDirectory, dir, sizeof(workingDirectory) );
    
    while (*c != '\0')     /* go to end */
        c++;
    
    while (*c != '/')      /* back up to parent */
        c--;
    c--;
    while (*c != '/')      /* And three more times... */
        c--;
    c--;
    while (*c != '/')      
        c--;
    c--;
    while (*c != '/')      
        c--;
        
    *c = '\0';             /* cut off last part  */
    
    }

/*------------------------------------------------------------------------------
*  getWorkingDirectory - Gets the working directory which is the folder 
*     containing the app.
*-----------------------------------------------------------------------------*/
+ (char *)getWorkingDirectory {
	return(workingDirectory);
    }
        
/*------------------------------------------------------------------------------
*  saveDefaults - Called by the main app class to save the preferences when the
*     program exits.
*-----------------------------------------------------------------------------*/
- (void)saveDefaults {
    NSDictionary *prefs;
	
        // Get the changed prefs back from emulator
	[self commitDisplayedValues];
	prefs = [self preferences];
	
    if (![origValues isEqual:prefs]) [Preferences savePreferencesToDefaults:prefs];
}

/*------------------------------------------------------------------------------
*  Constructor
*-----------------------------------------------------------------------------*/
- (id)init {
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        curValues = [[[self class] preferencesFromDefaults] copyWithZone:[self zone]];
        origValues = [curValues retain];
        [self transferValuesToSio];
        [self transferValuesToAtari825];
        [self transferValuesToAtari1020];
        [self transferValuesToEpson];
        [self discardDisplayedValues];
		modems = [NSMutableArray array];
		[modems retain];
        sharedInstance = self;
		if (![NSBundle loadNibNamed:@"Preferences" owner:self])  {
			NSLog(@"Failed to load Preferences.nib");
			NSBeep();
			return nil;
		}
    }
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  Destructor
*-----------------------------------------------------------------------------*/
- (void)dealloc {
	[super dealloc];
}

/*------------------------------------------------------------------------------
* preferences - Method to return pointer to current preferences.
*-----------------------------------------------------------------------------*/
- (NSDictionary *)preferences {
    return curValues;
}

/*------------------------------------------------------------------------------
* showPanel - Method to display the preferences window.
*-----------------------------------------------------------------------------*/
- (void)showPanel:(id)sender {
	/* Transfer the changed prefs values back from emulator */
	[[SioController sharedInstance] returnPrefs];
	[self commitDisplayedValues];
	[self updateUI];

	[[prefTabView window] setExcludedFromWindowsMenu:YES];
	[[prefTabView window] setMenu:nil];
        [self updateUI];
        [self miscChanged:self];
        [[prefTabView window] center];
            
    [NSApp runModalForWindow:[prefTabView window]];
}


/*------------------------------------------------------------------------------
* updateUI - Method to update the display, based on the stored values.
*-----------------------------------------------------------------------------*/
- (void)updateUI {
	NSColor *pen1, *pen2, *pen3, *pen4;
	int i,j,index, sioIndex;

    if (!prefTabView) return;	/* UI hasn't been loaded... */

    [printDirField setStringValue:[displayedValues objectForKey:PrintDir]];
    [diskImageDirField setStringValue:[displayedValues objectForKey:DiskImageDir]];
    [cassImageDirField setStringValue:[displayedValues objectForKey:CassImageDir]];
    [diskSetDirField setStringValue:[displayedValues objectForKey:DiskSetDir]];
   
	[ignoreAtrWriteProtectButton setState:[[displayedValues objectForKey:IgnoreAtrWriteProtect] boolValue] ? NSOnState : NSOffState];
	[maxSerialSpeedPulldown selectItemAtIndex:[[displayedValues objectForKey:MaxSerialSpeed] intValue]];
	[delayFactorPulldown selectItemAtIndex:[[displayedValues objectForKey:DelayFactor] intValue]];
	[sioHWTypePulldown selectItemAtIndex:[[displayedValues objectForKey:SioHWType] intValue]];
	[printerTypePulldown selectItemAtIndex:[[displayedValues objectForKey:PrinterType] intValue]];
    [printCommandField setStringValue:[displayedValues objectForKey:PrintCommand]];
	[printerTabView selectTabViewItemAtIndex:[[displayedValues objectForKey:PrinterType] intValue]];
	[atari825CharSetPulldown selectItemAtIndex:[[displayedValues objectForKey:Atari825CharSet] intValue]];
	[atari825FormLengthField setIntValue:[[displayedValues objectForKey:Atari825FormLength] intValue]];
	[atari825FormLengthStepper setIntValue:[[displayedValues objectForKey:Atari825FormLength] intValue]];
	[atari825AutoLinefeedButton setState:[[displayedValues objectForKey:Atari825AutoLinefeed] boolValue] ? NSOnState : NSOffState];
	[atari1020PrintWidthPulldown selectItemAtIndex:[[displayedValues objectForKey:Atari1020PrintWidth] intValue]];
	[atari1020FormLengthField setIntValue:[[displayedValues objectForKey:Atari1020FormLength] intValue]];
	[atari1020FormLengthStepper setIntValue:[[displayedValues objectForKey:Atari1020FormLength] intValue]];
	[atari1020AutoLinefeedButton setState:[[displayedValues objectForKey:Atari1020AutoLinefeed] boolValue] ? NSOnState : NSOffState];
	[atari1020AutoPageAdjustButton setState:[[displayedValues objectForKey:Atari1020AutoPageAdjust] boolValue] ? NSOnState : NSOffState];
	pen1 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen1Red] floatValue] 
						green:[[displayedValues objectForKey:Atari1020Pen1Green] floatValue] 
						blue:[[displayedValues objectForKey:Atari1020Pen1Blue] floatValue]
						alpha:[[displayedValues objectForKey:Atari1020Pen1Alpha] floatValue]];
	[atari1020Pen1Pot setColor:pen1];
	pen2 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen2Red] floatValue] 
						green:[[displayedValues objectForKey:Atari1020Pen2Green] floatValue] 
						blue:[[displayedValues objectForKey:Atari1020Pen2Blue] floatValue]
						alpha:[[displayedValues objectForKey:Atari1020Pen2Alpha] floatValue]];
	[atari1020Pen2Pot setColor:pen2];
	pen3 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen3Red] floatValue] 
						green:[[displayedValues objectForKey:Atari1020Pen3Green] floatValue] 
						blue:[[displayedValues objectForKey:Atari1020Pen3Blue] floatValue]
						alpha:[[displayedValues objectForKey:Atari1020Pen3Alpha] floatValue]];
	[atari1020Pen3Pot setColor:pen3];
	pen4 = [NSColor colorWithCalibratedRed:[[displayedValues objectForKey:Atari1020Pen4Red] floatValue] 
						green:[[displayedValues objectForKey:Atari1020Pen4Green] floatValue] 
						blue:[[displayedValues objectForKey:Atari1020Pen4Blue] floatValue]
						alpha:[[displayedValues objectForKey:Atari1020Pen4Alpha] floatValue]];
	[atari1020Pen4Pot setColor:pen4];
	[epsonCharSetPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonCharSet] intValue]];
	[epsonPrintPitchPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonPrintPitch] intValue]];
	[epsonPrintWeightPulldown selectItemAtIndex:[[displayedValues objectForKey:EpsonPrintWeight] intValue]];
	[epsonFormLengthField setIntValue:[[displayedValues objectForKey:EpsonFormLength] intValue]];
	[epsonFormLengthStepper setIntValue:[[displayedValues objectForKey:EpsonFormLength] intValue]];
	[epsonAutoLinefeedButton setState:[[displayedValues objectForKey:EpsonAutoLinefeed] boolValue] ? NSOnState : NSOffState];
	[epsonPrintSlashedZerosButton setState:[[displayedValues objectForKey:EpsonPrintSlashedZeros] boolValue] ? NSOnState : NSOffState];
	[epsonAutoSkipButton setState:[[displayedValues objectForKey:EpsonAutoSkip] boolValue] ? NSOnState : NSOffState];
	[epsonSplitSkipButton setState:[[displayedValues objectForKey:EpsonSplitSkip] boolValue] ? NSOnState : NSOffState];
	
	[dialAddress1Field setStringValue:[displayedValues objectForKey:DialAddress1]];
	[dialAddress2Field setStringValue:[displayedValues objectForKey:DialAddress2]];
	[dialAddress3Field setStringValue:[displayedValues objectForKey:DialAddress3]];
	[dialAddress4Field setStringValue:[displayedValues objectForKey:DialAddress4]];
	[dialAddress5Field setStringValue:[displayedValues objectForKey:DialAddress5]];
	[dialAddress6Field setStringValue:[displayedValues objectForKey:DialAddress6]];
	[dialAddress7Field setStringValue:[displayedValues objectForKey:DialAddress7]];
	[dialAddress8Field setStringValue:[displayedValues objectForKey:DialAddress8]];
	[dialAddress9Field setStringValue:[displayedValues objectForKey:DialAddress9]];
	[dialAddress10Field setStringValue:[displayedValues objectForKey:DialAddress10]];
	[dialAddress11Field setStringValue:[displayedValues objectForKey:DialAddress11]];
	[dialAddress12Field setStringValue:[displayedValues objectForKey:DialAddress12]];
	[dialAddress13Field setStringValue:[displayedValues objectForKey:DialAddress13]];
	[dialAddress14Field setStringValue:[displayedValues objectForKey:DialAddress14]];
	[dialAddress15Field setStringValue:[displayedValues objectForKey:DialAddress15]];
	[dialAddress16Field setStringValue:[displayedValues objectForKey:DialAddress16]];
	[dialAddress17Field setStringValue:[displayedValues objectForKey:DialAddress17]];
	[dialAddress18Field setStringValue:[displayedValues objectForKey:DialAddress18]];
	[dialAddress19Field setStringValue:[displayedValues objectForKey:DialAddress19]];
	[dialAddress20Field setStringValue:[displayedValues objectForKey:DialAddress20]];
	[dialPort1Field setIntValue:[[displayedValues objectForKey:DialPort1] intValue]];
	[dialPort2Field setIntValue:[[displayedValues objectForKey:DialPort2] intValue]];
	[dialPort3Field setIntValue:[[displayedValues objectForKey:DialPort3] intValue]];
	[dialPort4Field setIntValue:[[displayedValues objectForKey:DialPort4] intValue]];
	[dialPort5Field setIntValue:[[displayedValues objectForKey:DialPort5] intValue]];
	[dialPort6Field setIntValue:[[displayedValues objectForKey:DialPort6] intValue]];
	[dialPort7Field setIntValue:[[displayedValues objectForKey:DialPort7] intValue]];
	[dialPort8Field setIntValue:[[displayedValues objectForKey:DialPort8] intValue]];
	[dialPort9Field setIntValue:[[displayedValues objectForKey:DialPort9] intValue]];
	[dialPort10Field setIntValue:[[displayedValues objectForKey:DialPort10] intValue]];
	[dialPort11Field setIntValue:[[displayedValues objectForKey:DialPort11] intValue]];
	[dialPort12Field setIntValue:[[displayedValues objectForKey:DialPort12] intValue]];
	[dialPort13Field setIntValue:[[displayedValues objectForKey:DialPort13] intValue]];
	[dialPort14Field setIntValue:[[displayedValues objectForKey:DialPort14] intValue]];
	[dialPort15Field setIntValue:[[displayedValues objectForKey:DialPort15] intValue]];
	[dialPort16Field setIntValue:[[displayedValues objectForKey:DialPort16] intValue]];
	[dialPort17Field setIntValue:[[displayedValues objectForKey:DialPort17] intValue]];
	[dialPort18Field setIntValue:[[displayedValues objectForKey:DialPort18] intValue]];
	[dialPort19Field setIntValue:[[displayedValues objectForKey:DialPort19] intValue]];
	[dialPort20Field setIntValue:[[displayedValues objectForKey:DialPort20] intValue]];
	
	[serverOffField setStringValue:[displayedValues objectForKey:NetServerOffMsg]];
	[serverBusyField setStringValue:[displayedValues objectForKey:NetServerBusyMsg]];
	[serverEnabledButton setState:[[displayedValues objectForKey:NetServerEnable] boolValue] ? NSOnState : NSOffState]; 
	[serverPortField setIntValue:[[displayedValues objectForKey:NetServerPort] intValue]];
	[modemEchoButton setState:[[displayedValues objectForKey:ModemEcho] boolValue] ? NSOnState : NSOffState]; 
	[autoAnswerButton setState:[[displayedValues objectForKey:ModemAutoAnswer] boolValue] ? NSOnState : NSOffState];
	if ([[displayedValues objectForKey:ModemEscapeCharacter] intValue] <= 127) {
		[escapeEnabledButton setState:NSOnState];
		[escapeCharacterField setIntValue:[[displayedValues objectForKey:ModemEscapeCharacter] intValue]];
		}
	else {
		[escapeEnabledButton setState:NSOffState];
		[escapeCharacterField setStringValue:@"255"];
		}
		
   	for (i=0;i<4;i++) {
		NSPopUpButton *pulldown;
		NSString *portName = [displayedValues objectForKey:SerialPort];
		NSString *portSubName;
		
		switch(i) {	
			case 0:
				pulldown = port1Pulldown;
				break;
			case 1:
				pulldown = port2Pulldown;
				break;
			case 2:
				pulldown = port3Pulldown;
				break;
			case 3:
				pulldown = port4Pulldown;
				break;
			}
			[pulldown removeAllItems];
			[pulldown addItemWithTitle:@"No Connection"];
			[pulldown addItemWithTitle:@"Internet Modem"];
		for (j=0;j<[modems count];j++) {
			NSString *modem = [modems objectAtIndex:j];
			portSubName = [portName substringFromIndex:([portName length] - [modem length])];
			[pulldown addItemWithTitle:modem];
			if ([modem isEqual:portSubName]) {
				sioIndex = j+2;
				[[pulldown itemAtIndex:j+2] setTarget:nil];
				}
			}
		}
	if ([[displayedValues objectForKey:SerialPort1Mode] intValue] == PORT_850_OFF)
		[port1Pulldown selectItemAtIndex:0];
	else if ([[displayedValues objectForKey:SerialPort1Mode] intValue] == PORT_850_NET_MODE)
		[port1Pulldown selectItemAtIndex:1];
	else {
		index = [port1Pulldown indexOfItemWithTitle:[displayedValues objectForKey:SerialPort1Port]];
		if (index == -1 || index == sioIndex) {
			[displayedValues setObject:[NSNumber numberWithInt:PORT_850_OFF] forKey:SerialPort1Mode];
			index = 0;
			}
		[port1Pulldown selectItemAtIndex:index];
		}
	if ([[displayedValues objectForKey:SerialPort2Mode] intValue] == PORT_850_OFF)
		[port2Pulldown selectItemAtIndex:0];
	else if ([[displayedValues objectForKey:SerialPort2Mode] intValue] == PORT_850_NET_MODE)
		[port2Pulldown selectItemAtIndex:1];
	else {
		index = [port2Pulldown indexOfItemWithTitle:[displayedValues objectForKey:SerialPort2Port]];
		if (index == -1 || index == sioIndex) {
			[displayedValues setObject:[NSNumber numberWithInt:PORT_850_OFF] forKey:SerialPort2Mode];
			index = 0;
			}
		[port2Pulldown selectItemAtIndex:index];
		}
	if ([[displayedValues objectForKey:SerialPort3Mode] intValue] == PORT_850_OFF)
		[port3Pulldown selectItemAtIndex:0];
	else if ([[displayedValues objectForKey:SerialPort3Mode] intValue] == PORT_850_NET_MODE)
		[port3Pulldown selectItemAtIndex:1];
	else {
		index = [port3Pulldown indexOfItemWithTitle:[displayedValues objectForKey:SerialPort3Port]];
		if (index == -1 || index == sioIndex) {
			[displayedValues setObject:[NSNumber numberWithInt:PORT_850_OFF] forKey:SerialPort3Mode];
			index = 0;
			}
		[port3Pulldown selectItemAtIndex:index];
		}
	if ([[displayedValues objectForKey:SerialPort4Mode] intValue] == PORT_850_OFF)
		[port4Pulldown selectItemAtIndex:0];
	else if ([[displayedValues objectForKey:SerialPort4Mode] intValue] == PORT_850_NET_MODE)
		[port4Pulldown selectItemAtIndex:1];
	else {
		index = [port4Pulldown indexOfItemWithTitle:[displayedValues objectForKey:SerialPort4Port]];
		if (index == -1 || index == sioIndex) {
			[displayedValues setObject:[NSNumber numberWithInt:PORT_850_OFF] forKey:SerialPort4Mode];
			index = 0;
			}
		[port4Pulldown selectItemAtIndex:index];
		}
}

/*------------------------------------------------------------------------------
* miscChanged - Method to get everything from User Interface when an event 
*        occurs.  Should probably be broke up by tab, since it is so huge.
*-----------------------------------------------------------------------------*/
- (void)miscChanged:(id)sender {
    int anInt;
	NSColor *penColor;
	float penRed, penBlue, penGreen, penAlpha;
    
    static NSNumber *yes = nil;
    static NSNumber *no = nil;
    static NSNumber *zero = nil;
    static NSNumber *one = nil;
    static NSNumber *two = nil;
    static NSNumber *three = nil;
    static NSNumber *four = nil;
    static NSNumber *five = nil;
    static NSNumber *six = nil;
    static NSNumber *seven = nil;
    static NSNumber *eight = nil;
    static NSNumber *nine = nil;
   
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
        zero = [[NSNumber alloc] initWithInt:0];
        one = [[NSNumber alloc] initWithInt:1];
        two = [[NSNumber alloc] initWithInt:2];
        three = [[NSNumber alloc] initWithInt:3];
        four = [[NSNumber alloc] initWithInt:4];
        five = [[NSNumber alloc] initWithInt:5];
        six = [[NSNumber alloc] initWithInt:6];
        seven = [[NSNumber alloc] initWithInt:7];
        eight = [[NSNumber alloc] initWithInt:8];
        nine = [[NSNumber alloc] initWithInt:9];
    }

    if ([ignoreAtrWriteProtectButton state] == NSOnState)
        [displayedValues setObject:yes forKey:IgnoreAtrWriteProtect];
    else
        [displayedValues setObject:no forKey:IgnoreAtrWriteProtect];
		
     switch([maxSerialSpeedPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:MaxSerialSpeed];
            break;
        case 1:
            [displayedValues setObject:one forKey:MaxSerialSpeed];
            break;
        case 2:
            [displayedValues setObject:two forKey:MaxSerialSpeed];
            break;
		}
   
     switch([delayFactorPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:DelayFactor];
            break;
        case 1:
            [displayedValues setObject:one forKey:DelayFactor];
            break;
        case 2:
            [displayedValues setObject:two forKey:DelayFactor];
            break;
        case 3:
            [displayedValues setObject:three forKey:DelayFactor];
            break;
        case 4:
            [displayedValues setObject:four forKey:DelayFactor];
            break;
        case 5:
            [displayedValues setObject:five forKey:DelayFactor];
            break;
        case 6:
            [displayedValues setObject:six forKey:DelayFactor];
            break;
        case 7:
            [displayedValues setObject:seven forKey:DelayFactor];
            break;
        case 8:
            [displayedValues setObject:eight forKey:DelayFactor];
            break;
        case 9:
            [displayedValues setObject:nine forKey:DelayFactor];
            break;
		}
   
     switch([sioHWTypePulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:SioHWType];
            break;
        case 1:
            [displayedValues setObject:one forKey:SioHWType];
            break;
        case 2:
            [displayedValues setObject:two forKey:SioHWType];
            break;
		}
   
    switch([printerTypePulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:PrinterType];
            break;
        case 1:
            [displayedValues setObject:one forKey:PrinterType];
            break;
        case 2:
            [displayedValues setObject:two forKey:PrinterType];
            break;
        case 3:
            [displayedValues setObject:three forKey:PrinterType];
            break;
		}
    [displayedValues setObject:[printCommandField stringValue] forKey:PrintCommand];   
	[printerTabView selectTabViewItemAtIndex:[printerTypePulldown indexOfSelectedItem]];
    switch([atari825CharSetPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:Atari825CharSet];
            break;
        case 1:
            [displayedValues setObject:one forKey:Atari825CharSet];
            break;
        case 2:
            [displayedValues setObject:two forKey:Atari825CharSet];
            break;
        case 3:
            [displayedValues setObject:three forKey:Atari825CharSet];
            break;
        case 4:
            [displayedValues setObject:four forKey:Atari825CharSet];
            break;
        case 5:
            [displayedValues setObject:five forKey:Atari825CharSet];
            break;
		}
    anInt = [atari825FormLengthStepper intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:Atari825FormLength];
	[atari825FormLengthField setIntValue:anInt];
    if ([atari825AutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:Atari825AutoLinefeed];
    else
        [displayedValues setObject:no forKey:Atari825AutoLinefeed];

    anInt = [atari1020FormLengthStepper intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:Atari1020FormLength];
	[atari1020FormLengthField setIntValue:anInt];
    if ([atari1020AutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:Atari1020AutoLinefeed];
    else
        [displayedValues setObject:no forKey:Atari1020AutoLinefeed];
    if ([atari1020AutoPageAdjustButton state] == NSOnState)
        [displayedValues setObject:yes forKey:Atari1020AutoPageAdjust];
    else
        [displayedValues setObject:no forKey:Atari1020AutoPageAdjust];
    switch([atari1020PrintWidthPulldown indexOfSelectedItem]) {
        case 0:
            [displayedValues setObject:zero forKey:Atari1020PrintWidth];
            break;
        case 1:
            [displayedValues setObject:one forKey:Atari1020PrintWidth];
            break;
		}
	penColor = [atari1020Pen1Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen1Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen1Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen1Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen1Alpha];
	penColor = [atari1020Pen2Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen2Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen2Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen2Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen2Alpha];
	penColor = [atari1020Pen3Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen3Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen3Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen3Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen3Alpha];
	penColor = [atari1020Pen4Pot color];
	[penColor getRed:&penRed green:&penGreen blue:&penBlue alpha:&penAlpha];
	[displayedValues setObject:[NSNumber numberWithFloat:penRed] forKey:Atari1020Pen4Red];
	[displayedValues setObject:[NSNumber numberWithFloat:penBlue] forKey:Atari1020Pen4Blue];
	[displayedValues setObject:[NSNumber numberWithFloat:penGreen] forKey:Atari1020Pen4Green];
	[displayedValues setObject:[NSNumber numberWithFloat:penAlpha] forKey:Atari1020Pen4Alpha];
	
    switch([epsonCharSetPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonCharSet];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonCharSet];
            break;
        case 2:
            [displayedValues setObject:two forKey:EpsonCharSet];
            break;
        case 3:
            [displayedValues setObject:three forKey:EpsonCharSet];
            break;
        case 4:
            [displayedValues setObject:four forKey:EpsonCharSet];
            break;
        case 5:
            [displayedValues setObject:five forKey:EpsonCharSet];
            break;
        case 6:
            [displayedValues setObject:six forKey:EpsonCharSet];
            break;
        case 7:
            [displayedValues setObject:seven forKey:EpsonCharSet];
            break;
        case 8:
            [displayedValues setObject:eight forKey:EpsonCharSet];
            break;
		}	
	anInt = [epsonFormLengthStepper intValue];
    [displayedValues setObject:[NSNumber numberWithInt:anInt] forKey:EpsonFormLength];
	[epsonFormLengthField setIntValue:anInt];
    if ([epsonAutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonAutoLinefeed];
    else
        [displayedValues setObject:no forKey:EpsonAutoLinefeed];
    switch([epsonPrintPitchPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonPrintPitch];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonPrintPitch];
            break;
		}
    switch([epsonPrintWeightPulldown indexOfSelectedItem]) {
        case 0:
		default:
            [displayedValues setObject:zero forKey:EpsonPrintWeight];
            break;
        case 1:
            [displayedValues setObject:one forKey:EpsonPrintWeight];
            break;
		}
    if ([epsonAutoLinefeedButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonAutoLinefeed];
    else
        [displayedValues setObject:no forKey:EpsonAutoLinefeed];
    if ([epsonPrintSlashedZerosButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonPrintSlashedZeros];
    else
        [displayedValues setObject:no forKey:EpsonPrintSlashedZeros];
    if ([epsonAutoSkipButton state] == NSOnState)
		{
        [displayedValues setObject:yes forKey:EpsonAutoSkip];
		[epsonSplitSkipButton setEnabled:YES];
		}
    else
		{
        [displayedValues setObject:no forKey:EpsonAutoSkip];
		[epsonSplitSkipButton setEnabled:NO];
		}
    if ([epsonSplitSkipButton state] == NSOnState)
        [displayedValues setObject:yes forKey:EpsonSplitSkip];
    else
        [displayedValues setObject:no forKey:EpsonSplitSkip];

    [displayedValues setObject:[printDirField stringValue] forKey:PrintDir];
    [displayedValues setObject:[diskImageDirField stringValue] forKey:DiskImageDir];
    [displayedValues setObject:[cassImageDirField stringValue] forKey:CassImageDir];
    [displayedValues setObject:[diskSetDirField stringValue] forKey:DiskSetDir];
	
    [displayedValues setObject:[dialAddress1Field stringValue] forKey:DialAddress1];
    [displayedValues setObject:[dialAddress2Field stringValue] forKey:DialAddress2];
    [displayedValues setObject:[dialAddress3Field stringValue] forKey:DialAddress3];
    [displayedValues setObject:[dialAddress4Field stringValue] forKey:DialAddress4];
    [displayedValues setObject:[dialAddress5Field stringValue] forKey:DialAddress5];
    [displayedValues setObject:[dialAddress6Field stringValue] forKey:DialAddress6];
    [displayedValues setObject:[dialAddress7Field stringValue] forKey:DialAddress7];
    [displayedValues setObject:[dialAddress8Field stringValue] forKey:DialAddress8];
    [displayedValues setObject:[dialAddress9Field stringValue] forKey:DialAddress9];
    [displayedValues setObject:[dialAddress10Field stringValue] forKey:DialAddress10];
    [displayedValues setObject:[dialAddress11Field stringValue] forKey:DialAddress11];
    [displayedValues setObject:[dialAddress12Field stringValue] forKey:DialAddress12];
    [displayedValues setObject:[dialAddress13Field stringValue] forKey:DialAddress13];
    [displayedValues setObject:[dialAddress14Field stringValue] forKey:DialAddress14];
    [displayedValues setObject:[dialAddress15Field stringValue] forKey:DialAddress15];
    [displayedValues setObject:[dialAddress16Field stringValue] forKey:DialAddress16];
    [displayedValues setObject:[dialAddress17Field stringValue] forKey:DialAddress17];
    [displayedValues setObject:[dialAddress18Field stringValue] forKey:DialAddress18];
    [displayedValues setObject:[dialAddress19Field stringValue] forKey:DialAddress19];
    [displayedValues setObject:[dialAddress20Field stringValue] forKey:DialAddress20];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort1Field intValue]] forKey:DialPort1];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort2Field intValue]] forKey:DialPort2];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort3Field intValue]] forKey:DialPort3];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort4Field intValue]]forKey:DialPort4];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort5Field intValue]] forKey:DialPort5];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort6Field intValue]] forKey:DialPort6];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort7Field intValue]] forKey:DialPort7];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort8Field intValue]] forKey:DialPort8];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort9Field intValue]] forKey:DialPort9];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort10Field intValue]] forKey:DialPort10];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort11Field intValue]] forKey:DialPort11];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort12Field intValue]] forKey:DialPort12];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort13Field intValue]] forKey:DialPort13];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort14Field intValue]] forKey:DialPort14];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort15Field intValue]] forKey:DialPort15];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort16Field intValue]] forKey:DialPort16];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort17Field intValue]] forKey:DialPort17];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort18Field intValue]] forKey:DialPort18];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort19Field intValue]] forKey:DialPort19];
    [displayedValues setObject:[NSNumber numberWithInt:[dialPort20Field intValue]] forKey:DialPort20];

    [displayedValues setObject:[serverOffField stringValue] forKey:NetServerOffMsg];
    [displayedValues setObject:[serverBusyField stringValue] forKey:NetServerBusyMsg];
    if ([serverEnabledButton state] == NSOnState)
        [displayedValues setObject:yes forKey:NetServerEnable];
    else
        [displayedValues setObject:no forKey:NetServerEnable];
    [displayedValues setObject:[NSNumber numberWithInt:[serverPortField intValue]] forKey:NetServerPort];
    if ([modemEchoButton state] == NSOnState)
        [displayedValues setObject:yes forKey:ModemEcho];
    else
        [displayedValues setObject:no forKey:ModemEcho];
    if ([autoAnswerButton state] == NSOnState)
        [displayedValues setObject:yes forKey:ModemAutoAnswer];
    else
        [displayedValues setObject:no forKey:ModemAutoAnswer];
    if ([escapeEnabledButton state] == NSOnState) {
		if ([escapeCharacterField intValue] > 127) {
			[displayedValues setObject:[NSNumber numberWithInt:43] forKey:ModemEscapeCharacter];
			[escapeCharacterField setStringValue:@"43"];
			}
		else
			[displayedValues setObject:[NSNumber numberWithInt:[escapeCharacterField intValue]] forKey:ModemEscapeCharacter];
		}
	else {
		[displayedValues setObject:[NSNumber numberWithInt:255] forKey:ModemEscapeCharacter];
		[escapeCharacterField setStringValue:@"255"];
		}

}

- (void)addModem:(char *)modemName:(BOOL)first
{
	NSString *string = [NSString stringWithCString:modemName];
#if 0	
	NSString *portName = [displayedValues objectForKey:SerialPort];
	NSString *portSubName = [portName substringFromIndex:([portName length] - [string length])];
	
	if (first) {
		[port1Pulldown removeAllItems];
		[port1Pulldown addItemWithTitle:@"No Connection"];
		[port1Pulldown addItemWithTitle:@"Internet Modem"];
		[port2Pulldown removeAllItems];
		[port2Pulldown addItemWithTitle:@"No Connection"];
		[port2Pulldown addItemWithTitle:@"Internet Modem"];
		[port3Pulldown removeAllItems];
		[port3Pulldown addItemWithTitle:@"No Connection"];
		[port3Pulldown addItemWithTitle:@"Internet Modem"];
		[port4Pulldown removeAllItems];
		[port4Pulldown addItemWithTitle:@"No Connection"];
		[port4Pulldown addItemWithTitle:@"Internet Modem"];
		}
	if (![string isEqual:portSubName]) {
		[port1Pulldown addItemWithTitle:string];
		[port2Pulldown addItemWithTitle:string];
		[port3Pulldown addItemWithTitle:string];
		[port4Pulldown addItemWithTitle:string];
		}
#else
	if (first) {
		[modems removeAllObjects];
		}
	[modems addObject:string];
#endif		
}

/*------------------------------------------------------------------------------
* portChanged - Handles changes for 850 port assignments.
*-----------------------------------------------------------------------------*/
- (void)portChanged:(id)sender {
	int index = [sender indexOfSelectedItem];
	int tag = [sender tag];
	int newMode;
	
	if (index > PORT_850_NET_MODE)
		newMode = PORT_850_SERIAL_MODE;
	else
		newMode = index;
	
	switch (tag) {
		case 0:
			[displayedValues setObject:[NSNumber numberWithInt:newMode] forKey:SerialPort1Mode];
			if (newMode == PORT_850_SERIAL_MODE)
				[displayedValues setObject:[sender titleOfSelectedItem] forKey:SerialPort1Port];
			break;
		case 1:
			[displayedValues setObject:[NSNumber numberWithInt:newMode] forKey:SerialPort2Mode];
			if (newMode == PORT_850_SERIAL_MODE)
				[displayedValues setObject:[sender titleOfSelectedItem] forKey:SerialPort2Port];
			break;
		case 2:
			[displayedValues setObject:[NSNumber numberWithInt:newMode] forKey:SerialPort3Mode];
			if (newMode == PORT_850_SERIAL_MODE)
				[displayedValues setObject:[sender titleOfSelectedItem] forKey:SerialPort3Port];
			break;
		case 3:
			[displayedValues setObject:[NSNumber numberWithInt:newMode] forKey:SerialPort4Mode];
			if (newMode == PORT_850_SERIAL_MODE)
				[displayedValues setObject:[sender titleOfSelectedItem] forKey:SerialPort4Port];
			break;
		}
	// Only allow one connection to the internet modem
	if (newMode == PORT_850_NET_MODE) {
		if (tag != 0 && [[displayedValues objectForKey:SerialPort1Mode] intValue] == PORT_850_NET_MODE)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort1Mode];
		if (tag != 1 && [[displayedValues objectForKey:SerialPort2Mode] intValue] == PORT_850_NET_MODE)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort2Mode];
		if (tag != 2 && [[displayedValues objectForKey:SerialPort3Mode] intValue] == PORT_850_NET_MODE)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort3Mode];
		if (tag != 3 && [[displayedValues objectForKey:SerialPort4Mode] intValue] == PORT_850_NET_MODE)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort4Mode];
		}
	// Only allow one connection to each serial device
	if (newMode == PORT_850_SERIAL_MODE) {
		if (tag != 0 && [port1Pulldown indexOfSelectedItem] == index)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort1Mode];
		if (tag != 1 && [port2Pulldown indexOfSelectedItem] == index)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort2Mode];
		if (tag != 2 && [port3Pulldown indexOfSelectedItem] == index)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort3Mode];
		if (tag != 3 && [port4Pulldown indexOfSelectedItem] == index)
			[displayedValues setObject:[NSNumber numberWithInt:0] forKey:SerialPort4Mode];
		}
		
	[self updateUI];
}

/*------------------------------------------------------------------------------
* browseDir - Method which allows user to choose a directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseDir {
    NSOpenPanel *openPanel;
    
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    if ([openPanel runModalForTypes:nil] == NSOKButton)
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }

/* The following methods allow the user to choose the default directories
    for files */
    
- (void)browsePrint:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [printDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseDiskDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [diskImageDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseCassDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [cassImageDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

- (void)browseDiskSetDir:(id)sender {
    NSString *dirname;
    
    dirname = [self browseDir];
    if (dirname != nil) {
        [diskSetDirField setStringValue:dirname];
        [self miscChanged:self];
        }
    }

/**** Commit/revert etc ****/

- (void)commitDisplayedValues {
    if (curValues != displayedValues) {
        [curValues release];
        curValues = [displayedValues copyWithZone:[self zone]];
    }
}

- (void)discardDisplayedValues {
    if (curValues != displayedValues) {
        [displayedValues release];
        displayedValues = [curValues mutableCopyWithZone:[self zone]];
        [self updateUI];
    }
}

- (void)transferValuesToAtari825
	{
	prefs825.charSet = [[curValues objectForKey:Atari825CharSet] intValue];
	prefs825.formLength = [[curValues objectForKey:Atari825FormLength] intValue];
	prefs825.autoLinefeed = [[curValues objectForKey:Atari825AutoLinefeed] intValue];
	}
	
- (void)transferValuesToAtari1020
	{
	prefs1020.printWidth = [[curValues objectForKey:Atari1020PrintWidth] intValue];
	prefs1020.formLength = [[curValues objectForKey:Atari1020FormLength] intValue];
	prefs1020.autoLinefeed = [[curValues objectForKey:Atari1020AutoLinefeed] intValue];
	prefs1020.autoPageAdjust = [[curValues objectForKey:Atari1020AutoPageAdjust] intValue];
	prefs1020.pen1Red = [[curValues objectForKey:Atari1020Pen1Red] floatValue];
	prefs1020.pen1Blue = [[curValues objectForKey:Atari1020Pen1Blue] floatValue];
	prefs1020.pen1Green = [[curValues objectForKey:Atari1020Pen1Green] floatValue];
	prefs1020.pen1Alpha = [[curValues objectForKey:Atari1020Pen1Alpha] floatValue];
	prefs1020.pen2Red = [[curValues objectForKey:Atari1020Pen2Red] floatValue];
	prefs1020.pen2Blue = [[curValues objectForKey:Atari1020Pen2Blue] floatValue];
	prefs1020.pen2Green = [[curValues objectForKey:Atari1020Pen2Green] floatValue];
	prefs1020.pen2Alpha = [[curValues objectForKey:Atari1020Pen2Alpha] floatValue];
	prefs1020.pen3Red = [[curValues objectForKey:Atari1020Pen3Red] floatValue];
	prefs1020.pen3Blue = [[curValues objectForKey:Atari1020Pen3Blue] floatValue];
	prefs1020.pen3Green = [[curValues objectForKey:Atari1020Pen3Green] floatValue];
	prefs1020.pen3Alpha = [[curValues objectForKey:Atari1020Pen3Alpha] floatValue];
	prefs1020.pen4Red = [[curValues objectForKey:Atari1020Pen4Red] floatValue];
	prefs1020.pen4Blue = [[curValues objectForKey:Atari1020Pen4Blue] floatValue];
	prefs1020.pen4Green = [[curValues objectForKey:Atari1020Pen4Green] floatValue];
	prefs1020.pen4Alpha = [[curValues objectForKey:Atari1020Pen4Alpha] floatValue];
	}
	
- (void)transferValuesToEpson
	{
	prefsEpson.charSet = [[curValues objectForKey:EpsonCharSet] intValue];
	prefsEpson.formLength = [[curValues objectForKey:EpsonFormLength] intValue];
	prefsEpson.printPitch = [[curValues objectForKey:EpsonPrintPitch] intValue];
	prefsEpson.printWeight = [[curValues objectForKey:EpsonPrintWeight] intValue];
	prefsEpson.autoLinefeed = [[curValues objectForKey:EpsonAutoLinefeed] intValue];
	prefsEpson.printSlashedZeros = [[curValues objectForKey:EpsonPrintSlashedZeros] intValue];
	prefsEpson.autoSkip = [[curValues objectForKey:EpsonAutoSkip] intValue];
	prefsEpson.splitSkip = [[curValues objectForKey:EpsonSplitSkip] intValue];
	}

- (void)transferValuesToSio {
    prefsSio.currPrinter = [[curValues objectForKey:PrinterType] intValue]; 
    prefsSio.maxSerialSpeed = [[curValues objectForKey:MaxSerialSpeed] intValue] + 1; 
    prefsSio.delayFactor = [[curValues objectForKey:DelayFactor] intValue]; 
    prefsSio.sioHWType = [[curValues objectForKey:SioHWType] intValue]; 
    prefsSio.ignoreAtrWriteProtect = [[curValues objectForKey:IgnoreAtrWriteProtect] intValue]; 
    [[curValues objectForKey:PrintDir] getCString:prefsSio.printDir]; 
    [[curValues objectForKey:DiskImageDir] getCString:prefsSio.diskImageDir]; 
    [[curValues objectForKey:CassImageDir] getCString:prefsSio.cassImageDir]; 
    [[curValues objectForKey:DiskSetDir] getCString:prefsSio.diskSetDir]; 
    [[curValues objectForKey:PrintCommand] getCString:prefsSio.printerCommand]; 
    [[curValues objectForKey:SerialPort] getCString:prefsSio.serialPort]; 
	[[curValues objectForKey:DialAddress1] getCString:prefsSio.storedNameAddr[0]];
	[[curValues objectForKey:DialAddress2] getCString:prefsSio.storedNameAddr[1]];
	[[curValues objectForKey:DialAddress3] getCString:prefsSio.storedNameAddr[2]];
	[[curValues objectForKey:DialAddress4] getCString:prefsSio.storedNameAddr[3]];
	[[curValues objectForKey:DialAddress5] getCString:prefsSio.storedNameAddr[4]];
	[[curValues objectForKey:DialAddress6] getCString:prefsSio.storedNameAddr[5]];
	[[curValues objectForKey:DialAddress7] getCString:prefsSio.storedNameAddr[6]];
	[[curValues objectForKey:DialAddress8] getCString:prefsSio.storedNameAddr[7]];
	[[curValues objectForKey:DialAddress9] getCString:prefsSio.storedNameAddr[8]];
	[[curValues objectForKey:DialAddress10] getCString:prefsSio.storedNameAddr[9]];
	[[curValues objectForKey:DialAddress11] getCString:prefsSio.storedNameAddr[10]];
	[[curValues objectForKey:DialAddress12] getCString:prefsSio.storedNameAddr[11]];
	[[curValues objectForKey:DialAddress13] getCString:prefsSio.storedNameAddr[12]];
	[[curValues objectForKey:DialAddress14] getCString:prefsSio.storedNameAddr[13]];
	[[curValues objectForKey:DialAddress15] getCString:prefsSio.storedNameAddr[14]];
	[[curValues objectForKey:DialAddress16] getCString:prefsSio.storedNameAddr[15]];
	[[curValues objectForKey:DialAddress17] getCString:prefsSio.storedNameAddr[16]];
	[[curValues objectForKey:DialAddress18] getCString:prefsSio.storedNameAddr[17]];
	[[curValues objectForKey:DialAddress19] getCString:prefsSio.storedNameAddr[18]];
	[[curValues objectForKey:DialAddress20] getCString:prefsSio.storedNameAddr[19]];
	prefsSio.storedNamePort[0] = [[curValues objectForKey:DialPort1] intValue];
	prefsSio.storedNamePort[1] = [[curValues objectForKey:DialPort2] intValue];
	prefsSio.storedNamePort[2] = [[curValues objectForKey:DialPort3] intValue];
	prefsSio.storedNamePort[3] = [[curValues objectForKey:DialPort4] intValue];
	prefsSio.storedNamePort[4] = [[curValues objectForKey:DialPort5] intValue];
	prefsSio.storedNamePort[5] = [[curValues objectForKey:DialPort6] intValue];
	prefsSio.storedNamePort[6] = [[curValues objectForKey:DialPort7] intValue];
	prefsSio.storedNamePort[7] = [[curValues objectForKey:DialPort8] intValue];
	prefsSio.storedNamePort[8] = [[curValues objectForKey:DialPort9] intValue];
	prefsSio.storedNamePort[9] = [[curValues objectForKey:DialPort10] intValue];
	prefsSio.storedNamePort[10] = [[curValues objectForKey:DialPort11] intValue];
	prefsSio.storedNamePort[11] = [[curValues objectForKey:DialPort12] intValue];
	prefsSio.storedNamePort[12] = [[curValues objectForKey:DialPort13] intValue];
	prefsSio.storedNamePort[13] = [[curValues objectForKey:DialPort14] intValue];
	prefsSio.storedNamePort[14] = [[curValues objectForKey:DialPort15] intValue];
	prefsSio.storedNamePort[15] = [[curValues objectForKey:DialPort16] intValue];
	prefsSio.storedNamePort[16] = [[curValues objectForKey:DialPort17] intValue];
	prefsSio.storedNamePort[17] = [[curValues objectForKey:DialPort18] intValue];
	prefsSio.storedNamePort[18] = [[curValues objectForKey:DialPort19] intValue];
	prefsSio.storedNamePort[19] = [[curValues objectForKey:DialPort20] intValue];
	[[curValues objectForKey:NetServerBusyMsg] getCString:prefsSio.netServerBusyMessage];
	[[curValues objectForKey:NetServerOffMsg] getCString:prefsSio.netServerNotReadyMessage];
	prefsSio.netServerEnable = [[curValues objectForKey:NetServerEnable] boolValue];
	prefsSio.netServerNetPort = [[curValues objectForKey:NetServerPort] intValue];
	prefsSio.modemEcho =  [[curValues objectForKey:ModemEcho] boolValue];
	prefsSio.modemAutoAnswer = [[curValues objectForKey:ModemAutoAnswer] boolValue];
	prefsSio.modemEscapeCharacter = [[curValues objectForKey:ModemEscapeCharacter] intValue];
	prefsSio.port850Mode[0] = [[curValues objectForKey:SerialPort1Mode] intValue];
	prefsSio.port850Mode[1] = [[curValues objectForKey:SerialPort2Mode] intValue];
	prefsSio.port850Mode[2] = [[curValues objectForKey:SerialPort3Mode] intValue];
	prefsSio.port850Mode[3] = [[curValues objectForKey:SerialPort4Mode] intValue];
	[[curValues objectForKey:SerialPort1Port] getCString:prefsSio.port850Port[0]];
	[[curValues objectForKey:SerialPort2Port] getCString:prefsSio.port850Port[1]];
	[[curValues objectForKey:SerialPort3Port] getCString:prefsSio.port850Port[2]];
	[[curValues objectForKey:SerialPort4Port] getCString:prefsSio.port850Port[3]];
	prefsSio.enable850 =  [[curValues objectForKey:Enable850] boolValue];
	[[SioController sharedInstance] updatePreferences];
	}

- (void)transferValuesFromSio:(SIO_PREF_RET *)prefs{ 
    static NSNumber *zero = nil;
    static NSNumber *one = nil;
    static NSNumber *two = nil;
    static NSNumber *three = nil;
   
    if (!zero) {
        zero = [[NSNumber alloc] initWithInt:0];
        one = [[NSNumber alloc] initWithInt:1];
        two = [[NSNumber alloc] initWithInt:2];
        three = [[NSNumber alloc] initWithInt:3];
     }
    [displayedValues setObject:[NSString stringWithCString:prefs->serialPort] forKey:SerialPort]; 
    switch(prefs->currPrinter) {
        case 0:
            [displayedValues setObject:zero forKey:PrinterType];
            break;
        case 1:
            [displayedValues setObject:one forKey:PrinterType];
            break;
        case 2:
            [displayedValues setObject:two forKey:PrinterType];
            break;
        case 3:
            [displayedValues setObject:three forKey:PrinterType];
            break;
		}
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[0]] forKey:DialAddress1];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[1]] forKey:DialAddress2];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[2]] forKey:DialAddress3];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[3]] forKey:DialAddress4];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[4]] forKey:DialAddress5];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[5]] forKey:DialAddress6];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[6]] forKey:DialAddress7];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[7]] forKey:DialAddress8];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[8]] forKey:DialAddress9];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[9]] forKey:DialAddress10];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[10]] forKey:DialAddress11];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[11]] forKey:DialAddress12];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[12]] forKey:DialAddress13];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[13]] forKey:DialAddress14];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[14]] forKey:DialAddress15];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[15]] forKey:DialAddress16];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[16]] forKey:DialAddress17];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[17]] forKey:DialAddress18];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[18]] forKey:DialAddress19];
	[displayedValues setObject:[NSString stringWithCString:prefs->storedNameAddr[19]] forKey:DialAddress20];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[0]] forKey:DialPort1];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[1]] forKey:DialPort2];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[2]] forKey:DialPort3];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[3]] forKey:DialPort4];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[4]] forKey:DialPort5];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[5]] forKey:DialPort6];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[6]] forKey:DialPort7];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[7]] forKey:DialPort8];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[8]] forKey:DialPort9];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[9]] forKey:DialPort10];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[10]] forKey:DialPort11];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[11]] forKey:DialPort12];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[12]] forKey:DialPort13];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[13]] forKey:DialPort14];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[14]] forKey:DialPort15];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[15]] forKey:DialPort16];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[16]] forKey:DialPort17];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[17]] forKey:DialPort18];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[18]] forKey:DialPort19];
	[displayedValues setObject:[NSNumber numberWithShort:prefs->storedNamePort[19]] forKey:DialPort20];
	[displayedValues setObject:[NSNumber numberWithBool:prefs->enable850] forKey:Enable850];
    }
	
- (void)transferUserStrings:(NSString *)name:(NSString *)key
{
	[displayedValues setObject:name forKey:UserName];
	[displayedValues setObject:key forKey:UserKey];
}

- (BOOL)checkRegistration
{
	NSString *config = @"SUPPLIERID:markgrebe%E:1%N:5%H:1%COMBO:nn%SDLGTH:15%CONSTLGTH:2%CONSTVAL:S1%SEQL:2%ALTTEXT:Contact markgrebe@kagi.com to obtain your registration code%SCRMBL:U3,,U12,,C1,,D1,,S0,,U4,,U6,,U11,,C0,,S1,,U7,,U5,,U1,,D0,,D2,,U10,,U8,,U0,,U13,,U9,,U2,,U14,,D3,,%ASCDIG:2%MATH:4A,,2S,,4A,,1A,,R,,1M,,2S,,R,,3A,,R,,1M,,3A,,2S,,8S,,2A,,1M,,2S,,6A,,R,,4S,,1M,,3A,,7S,,%BASE:30%BASEMAP:TE7D95GK2FWXHUQLNY3JA8P4C1RM60%REGFRMT:SIO-^#####-#####-#####-#####-#####-#####-##[-#]";
	KagiGenericACG *acg = [KagiGenericACG acgWithConfigurationString: config];
	BOOL result = [acg regCode:[displayedValues objectForKey:UserKey] matchesName:[displayedValues objectForKey:UserName] email:@"" hotSync:@""];

	if(result) {
	   [self commitDisplayedValues]; 
       return YES;
	   }
	else 
	   return NO;
}

- (NSString *)getUserName
{
	return([displayedValues objectForKey:UserName]);
}

- (NSString *)getUserKey
{
	return([displayedValues objectForKey:UserKey]);
}

/* Handle the OK, cancel, and Revert buttons */

- (void)ok:(id)sender {
    [self miscChanged:self];
    [self commitDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
    [self transferValuesToSio];
    [self transferValuesToAtari825];
    [self transferValuesToAtari1020];
    [self transferValuesToEpson];
}

- (void)revertToDefault:(id)sender {
    curValues = [defaultValues() mutableCopyWithZone:[self zone]];
    
    [self discardDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
    [self transferValuesToSio];
    [self transferValuesToAtari825];
    [self transferValuesToAtari1020];
    [self transferValuesToEpson];
}

- (void)revert:(id)sender {
    [self discardDisplayedValues];
    [NSApp stopModal];
    [[prefTabView window] close];
}


/**** Code to deal with defaults ****/
   
#define getBoolDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithBool:[defaults boolForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getIntDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithInt:[defaults integerForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getFloatDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithFloat:[defaults floatForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getStringDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSString stringWithString:[defaults stringForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}
      
/* Read prefs from system defaults */
+ (NSDictionary *)preferencesFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    getStringDefault(SerialPort);
	getIntDefault(MaxSerialSpeed);
	getIntDefault(DelayFactor);
	getIntDefault(SioHWType);
    getStringDefault(PrintCommand);
	getIntDefault(PrinterType);
	getIntDefault(Atari825CharSet); 
	getIntDefault(Atari825FormLength); 
	getBoolDefault(Atari825AutoLinefeed); 
	getIntDefault(Atari1020PrintWidth); 
	getIntDefault(Atari1020FormLength); 
	getBoolDefault(Atari1020AutoLinefeed); 
	getBoolDefault(Atari1020AutoPageAdjust); 
	getFloatDefault(Atari1020Pen1Red); 
	getFloatDefault(Atari1020Pen1Blue); 
	getFloatDefault(Atari1020Pen1Green); 
	getFloatDefault(Atari1020Pen1Alpha); 
	getFloatDefault(Atari1020Pen2Red); 
	getFloatDefault(Atari1020Pen2Blue); 
	getFloatDefault(Atari1020Pen2Green); 
	getFloatDefault(Atari1020Pen2Alpha); 
	getFloatDefault(Atari1020Pen3Red); 
	getFloatDefault(Atari1020Pen3Blue); 
	getFloatDefault(Atari1020Pen3Green); 
	getFloatDefault(Atari1020Pen3Alpha); 
	getFloatDefault(Atari1020Pen4Red); 
	getFloatDefault(Atari1020Pen4Blue);
	getFloatDefault(Atari1020Pen4Green); 
	getFloatDefault(Atari1020Pen4Alpha);
	getStringDefault(DialAddress1); 
	getStringDefault(DialAddress2); 
	getStringDefault(DialAddress3); 
	getStringDefault(DialAddress4); 
	getStringDefault(DialAddress5); 
	getStringDefault(DialAddress6); 
	getStringDefault(DialAddress7); 
	getStringDefault(DialAddress8); 
	getStringDefault(DialAddress9); 
	getStringDefault(DialAddress10); 
	getStringDefault(DialAddress11); 
	getStringDefault(DialAddress12); 
	getStringDefault(DialAddress13); 
	getStringDefault(DialAddress14); 
	getStringDefault(DialAddress15); 
	getStringDefault(DialAddress16); 
	getStringDefault(DialAddress17); 
	getStringDefault(DialAddress18); 
	getStringDefault(DialAddress19); 
	getStringDefault(DialAddress20); 
	getIntDefault(DialPort1); 
	getIntDefault(DialPort2); 
	getIntDefault(DialPort3); 
	getIntDefault(DialPort4); 
	getIntDefault(DialPort5); 
	getIntDefault(DialPort6); 
	getIntDefault(DialPort7); 
	getIntDefault(DialPort8); 
	getIntDefault(DialPort9); 
	getIntDefault(DialPort10); 
	getIntDefault(DialPort11); 
	getIntDefault(DialPort12); 
	getIntDefault(DialPort13); 
	getIntDefault(DialPort14); 
	getIntDefault(DialPort15); 
	getIntDefault(DialPort16); 
	getIntDefault(DialPort17); 
	getIntDefault(DialPort18); 
	getIntDefault(DialPort19); 
	getIntDefault(DialPort20); 
	getBoolDefault(Enable850);
	getIntDefault(EpsonCharSet); 
	getIntDefault(EpsonPrintPitch); 
	getIntDefault(EpsonPrintWeight); 
	getIntDefault(EpsonFormLength); 
	getBoolDefault(EpsonAutoLinefeed); 
	getBoolDefault(EpsonPrintSlashedZeros); 
	getBoolDefault(EpsonAutoSkip); 
	getBoolDefault(EpsonSplitSkip); 
    getBoolDefault(IgnoreAtrWriteProtect);
	getBoolDefault(ModemEcho); 
	getBoolDefault(ModemAutoAnswer); 
	getIntDefault(ModemEscapeCharacter); 
	getStringDefault(NetServerOffMsg);
	getStringDefault(NetServerBusyMsg);
	getBoolDefault(NetServerEnable);
	getIntDefault(NetServerPort);
    getStringDefault(PrintDir);
	getIntDefault(SerialPort1Mode);
	getIntDefault(SerialPort2Mode);
	getIntDefault(SerialPort3Mode);
	getIntDefault(SerialPort4Mode);
    getStringDefault(SerialPort1Port);
    getStringDefault(SerialPort2Port);
    getStringDefault(SerialPort3Port);
    getStringDefault(SerialPort4Port);
    getStringDefault(DiskImageDir);
    getStringDefault(CassImageDir);
    getStringDefault(DiskSetDir);
    getStringDefault(UserName);
    getStringDefault(UserKey);
    return dict;
}

#define setBoolDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setBool:[[dict objectForKey:name] boolValue] forKey:name];}

#define setIntDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setInteger:[[dict objectForKey:name] intValue] forKey:name];}

#define setFloatDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setFloat:[[dict objectForKey:name] floatValue] forKey:name];}

#define setStringDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setObject:[dict objectForKey:name] forKey:name];}

#define setArrayDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setObject:[dict objectForKey:name] forKey:name];}

/* Save preferences to system defaults */
+ (void)savePreferencesToDefaults:(NSDictionary *)dict {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    setStringDefault(SerialPort);
	setIntDefault(DelayFactor);
	setIntDefault(SioHWType);
    setStringDefault(PrintCommand);
	setIntDefault(PrinterType);
	setIntDefault(Atari825CharSet); 
	setIntDefault(Atari825FormLength); 
	setBoolDefault(Atari825AutoLinefeed); 
	setIntDefault(Atari1020PrintWidth); 
	setIntDefault(Atari1020FormLength); 
	setBoolDefault(Atari1020AutoLinefeed); 
	setBoolDefault(Atari1020AutoPageAdjust); 
	setFloatDefault(Atari1020Pen1Red); 
	setFloatDefault(Atari1020Pen1Blue); 
	setFloatDefault(Atari1020Pen1Green); 
	setFloatDefault(Atari1020Pen1Alpha); 
	setFloatDefault(Atari1020Pen2Red); 
	setFloatDefault(Atari1020Pen2Blue); 
	setFloatDefault(Atari1020Pen2Green); 
	setFloatDefault(Atari1020Pen2Alpha); 
	setFloatDefault(Atari1020Pen3Red); 
	setFloatDefault(Atari1020Pen3Blue); 
	setFloatDefault(Atari1020Pen3Green); 
	setFloatDefault(Atari1020Pen3Alpha); 
	setFloatDefault(Atari1020Pen4Red); 
	setFloatDefault(Atari1020Pen4Blue);
	setFloatDefault(Atari1020Pen4Green); 
	setFloatDefault(Atari1020Pen4Alpha); 
	setStringDefault(DialAddress1); 
	setStringDefault(DialAddress2); 
	setStringDefault(DialAddress3); 
	setStringDefault(DialAddress4); 
	setStringDefault(DialAddress5); 
	setStringDefault(DialAddress6); 
	setStringDefault(DialAddress7); 
	setStringDefault(DialAddress8); 
	setStringDefault(DialAddress9); 
	setStringDefault(DialAddress10); 
	setStringDefault(DialAddress11); 
	setStringDefault(DialAddress12); 
	setStringDefault(DialAddress13); 
	setStringDefault(DialAddress14); 
	setStringDefault(DialAddress15); 
	setStringDefault(DialAddress16); 
	setStringDefault(DialAddress17); 
	setStringDefault(DialAddress18); 
	setStringDefault(DialAddress19); 
	setStringDefault(DialAddress20); 
	setIntDefault(DialPort1); 
	setIntDefault(DialPort2); 
	setIntDefault(DialPort3); 
	setIntDefault(DialPort4); 
	setIntDefault(DialPort5); 
	setIntDefault(DialPort6); 
	setIntDefault(DialPort7); 
	setIntDefault(DialPort8); 
	setIntDefault(DialPort9); 
	setIntDefault(DialPort10); 
	setIntDefault(DialPort11); 
	setIntDefault(DialPort12); 
	setIntDefault(DialPort13); 
	setIntDefault(DialPort14); 
	setIntDefault(DialPort15); 
	setIntDefault(DialPort16); 
	setIntDefault(DialPort17); 
	setIntDefault(DialPort18); 
	setIntDefault(DialPort19); 
	setIntDefault(DialPort20); 
	setBoolDefault(Enable850);
	setIntDefault(EpsonCharSet); 
	setIntDefault(EpsonPrintPitch); 
	setIntDefault(EpsonPrintWeight); 
	setIntDefault(EpsonFormLength); 
	setBoolDefault(EpsonAutoLinefeed); 
	setBoolDefault(EpsonPrintSlashedZeros); 
	setBoolDefault(EpsonAutoSkip); 
	setBoolDefault(EpsonSplitSkip); 
    setBoolDefault(IgnoreAtrWriteProtect);
	setBoolDefault(ModemEcho); 
	setBoolDefault(ModemAutoAnswer); 
	setIntDefault(ModemEscapeCharacter); 
	setStringDefault(NetServerOffMsg);
	setStringDefault(NetServerBusyMsg);
	setBoolDefault(NetServerEnable);
	setIntDefault(NetServerPort);
    setStringDefault(PrintDir);
	setIntDefault(SerialPort1Mode);
	setIntDefault(SerialPort2Mode);
	setIntDefault(SerialPort3Mode);
	setIntDefault(SerialPort4Mode);
    setStringDefault(SerialPort1Port);
    setStringDefault(SerialPort2Port);
    setStringDefault(SerialPort3Port);
    setStringDefault(SerialPort4Port);
    setStringDefault(DiskImageDir);
    setStringDefault(CassImageDir);
    setStringDefault(DiskSetDir);
    setStringDefault(UserName);
    setStringDefault(UserKey);
    [defaults synchronize];
}

/**** Window delegation ****/

// We do this to catch the case where the user enters a value into one of the text fields but closes the window without hitting enter or tab.

- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *window = [notification object];
    (void)[window makeFirstResponder:window];
}

@end
