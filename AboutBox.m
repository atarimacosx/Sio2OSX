/* AboutBox.m - AboutBox window 
   class and support functions for the
   Macintosh OS X SDL port of Stella
   Mark Grebe <atarimac@cox.net>
*/
/* $Id: AboutBox.m,v 1.2 2005/06/04 02:04:06 markgrebe Exp $ */

#import "AboutBox.h"
#import "Preferences.h"


@implementation AboutBox

static AboutBox *sharedInstance = nil;

+ (AboutBox *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init 
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
    }
    
    return sharedInstance;
}

/*------------------------------------------------------------------------------
*  showPanel - Display the About Box.
*-----------------------------------------------------------------------------*/
- (IBAction)showPanel:(id)sender
{
    NSRect creditsBounds;
	NSString *userName;
	
    if (!appNameField)
    {
        NSWindow *theWindow;
        NSString *creditsPath;
        NSMutableAttributedString *creditsString;
        NSString *appName;
        NSString *versionString;
        NSDictionary *infoDictionary;
        CFBundleRef localInfoBundle;
        NSDictionary *localInfoDict;

        if (![NSBundle loadNibNamed:@"AboutBox" owner:self])
        {
            NSLog( @"Failed to load AboutBox.nib" );
            NSBeep();
            return;
        }
        theWindow = [appNameField window];

        // Get the info dictionary (Info.plist)
        infoDictionary = [[NSBundle mainBundle] infoDictionary];

		        
        // Get the localized info dictionary (InfoPlist.strings)
        localInfoBundle = CFBundleGetMainBundle();
        localInfoDict = (NSDictionary *)
                        CFBundleGetLocalInfoDictionary( localInfoBundle );

        // Setup the app name field
        appName = @"Sio2OSX";
        [appNameField setStringValue:appName];

        // Set the about box window title
        [theWindow setTitle:[NSString stringWithFormat:@"About %@", appName]];

        // Setup the version field
        versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
        [versionField setStringValue:[NSString stringWithFormat:@"Version %@", 
                                                          versionString]];

        // Setup our credits
        creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" 
                                             ofType:@"html"];

        creditsString = [[NSMutableAttributedString alloc] initWithPath:creditsPath
        documentAttributes:nil];
        
        [creditsString addAttribute:NSForegroundColorAttributeName
               value: NSColor.controlTextColor
                               range: NSMakeRange( 0, creditsString.length-1)];

        [creditsField replaceCharactersInRange:NSMakeRange( 0, 0 ) 
                      withRTF:[creditsString RTFFromRange:
                               NSMakeRange( 0, [creditsString length] ) 
                                             documentAttributes:nil]];

        // Prepare some scroll info
		creditsBounds = [creditsField bounds];
        maxScrollHeight = creditsBounds.size.height*2.75;

        // Setup the window
        [theWindow setExcludedFromWindowsMenu:YES];
        [theWindow setMenu:nil];
        [theWindow center];
		
    }
	
	// Setup the registration info
    [registrationField setStringValue:@""];

    if (![[appNameField window] isVisible])
    {
        currentPosition = 0;
        restartAtTop = NO;
        [creditsField scrollPoint:NSMakePoint( 0, 0 )];
    }
    
    // Show the window
	[NSApp runModalForWindow:[appNameField window]];
    [[appNameField window] close];
	
}

- (void)OK:(id)sender
{
	[NSApp stopModal];
}

@end

