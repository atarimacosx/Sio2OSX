/*   SioMain.m - main entry point for our Cocoa-ized SDL app
       Initial Version: Darrell Walisser <dwaliss1@purdue.edu>
       Non-NIB-Code & other changes: Max Horn <max@quendi.de>
    
       Macintosh OS X SDL port of Atari800
       Mark Grebe <atarimac@cox.net>
   

    Feel free to customize this file to suit your needs
*/
#import "SioMain.h"
#import "Preferences.h"
#import "MediaManager.h"
#import "SioController.h"
#import <sys/param.h> /* for MAXPATHLEN */
#import <unistd.h>

static int    gArgc;
static char  **gArgv;
static BOOL   started=NO;
int fileToLoad = FALSE;
static char startupFile[FILENAME_MAX];
extern FILE *logFile;
extern 	void Cleanup_USB_Notifications(void);
NSTimer *regTimer = nil;

void SioMainCloseWindow() {
	[[NSApp keyWindow] performClose:NSApp];
}

/* A helper category for NSString */
@interface NSString (ReplaceSubString)
- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString;
@end

/* The main class of the application, the application's delegate */
@implementation SioMain

/* Called when the internal event loop has just started running */
- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    started = YES;
	
    /* Display media status window */
	[[MediaManager sharedInstance] mediaStatusWindowShow:nil];

    /* Hand off to main application code */
	[[SioController sharedInstance] start];

    if (fileToLoad) 
		[SioMain loadFile:[NSString stringWithCString:startupFile]];

	/* Time out the appliation if it isn't registered */
	if (![[Preferences sharedInstance] checkRegistration]) {
		regTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:[MediaManager sharedInstance] 
							selector:@selector(applicationTimedOut:) userInfo:nil repeats:NO];
		}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[[SioController sharedInstance] returnPrefs];
	[[Preferences sharedInstance] saveDefaults];
	if (logFile)
		fclose(logFile);
	Cleanup_USB_Notifications();
	return(YES);
}

/*------------------------------------------------------------------------------
*  application openFile - Open a file dragged to the application.
*-----------------------------------------------------------------------------*/
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if (started)
        [SioMain loadFile:filename];
    else {
        fileToLoad = TRUE;
        [filename getCString:startupFile];
    }

    return(FALSE);
}

/*------------------------------------------------------------------------------
*  loadFile - Load a file into the emulator at startup.
*-----------------------------------------------------------------------------*/
+(void)loadFile:(NSString *)filename
{
    NSString *suffix;
	BOOL isDir;
    
    suffix = [filename pathExtension];
	
	[[NSFileManager defaultManager] fileExistsAtPath:filename 
											isDirectory:&isDir];
    
    if (isDir)
        [[MediaManager sharedInstance] diskInsertFile:filename];
    if ([suffix isEqualToString:@"atr"] || [suffix isEqualToString:@"ATR"] ||
		[suffix isEqualToString:@"atx"] || [suffix isEqualToString:@"ATX"] ||
		[suffix isEqualToString:@"pro"] || [suffix isEqualToString:@"PRO"])
        [[MediaManager sharedInstance] diskInsertFile:filename];
    else if ([suffix isEqualToString:@"set"] || [suffix isEqualToString:@"SET"])
        [[MediaManager sharedInstance] diskSetLoadFile:filename];
}

@end


@implementation NSString (ReplaceSubString)

- (NSString *)stringByReplacingRange:(NSRange)aRange with:(NSString *)aString
{
    unsigned int bufferSize;
    unsigned int selfLen = [self length];
    unsigned int aStringLen = [aString length];
    unichar *buffer;
    NSRange localRange;
    NSString *result;

    bufferSize = selfLen + aStringLen - aRange.length;
    buffer = NSAllocateMemoryPages(bufferSize*sizeof(unichar));
    
    /* Get first part into buffer */
    localRange.location = 0;
    localRange.length = aRange.location;
    [self getCharacters:buffer range:localRange];
    
    /* Get middle part into buffer */
    localRange.location = 0;
    localRange.length = aStringLen;
    [aString getCharacters:(buffer+aRange.location) range:localRange];
     
    /* Get last part into buffer */
    localRange.location = aRange.location + aRange.length;
    localRange.length = selfLen - localRange.location;
    [self getCharacters:(buffer+aRange.location+aStringLen) range:localRange];
    
    /* Build output string */
    result = [NSString stringWithCharacters:buffer length:bufferSize];
    
    NSDeallocateMemoryPages(buffer, bufferSize);
    
    return result;
}

@end



#ifdef main
#  undef main
#endif

/* Set the working directory to the .app's parent directory */
void setupWorkingDirectory()
{
    char parentdir[MAXPATHLEN];
    char *c;

    strncpy ( parentdir, gArgv[0], sizeof(parentdir) );
    c = (char*) parentdir;

    while (*c != '\0')     /* go to end */
        c++;
    
    while (*c != '/')      /* back up to parent */
        c--;
    
    *c++ = '\0';             /* cut off last part (binary name) */
  
    assert ( chdir (parentdir) == 0 );   /* chdir to the binary app's parent */
    assert ( chdir ("../../") == 0 ); /* chdir to the .app's parent */
}



/* Main entry point to executable - should *not* be SDL_main! */
int main (int argc, char **argv)
{
    /* Copy the arguments into a global variable */
    int i;
    
    /* This is passed if we are launched by double-clicking */
    if ( argc >= 2 && strncmp (argv[1], "-psn", 4) == 0 ) {
        gArgc = 1;
    } else {
        gArgc = argc;
    }
    gArgv = (char**) malloc (sizeof(*gArgv) * (gArgc+1));
    assert (gArgv != NULL);
    for (i = 0; i < gArgc; i++)
        gArgv[i] = argv[i];
    gArgv[i] = NULL;

    /* Set the working directory to the .app's parent directory */
    setupWorkingDirectory();
	
    /* Set the working directory for preferences, so defaults for 
       directories are set correctly */
    [Preferences setWorkingDirectory:gArgv[0]];\
	
     NSApplicationMain (argc, (const char **) argv);

    return 0;
}
