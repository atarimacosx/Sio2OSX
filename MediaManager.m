/* MediaManager.m - Window and menu support
   class to handle disk, cartridge, cassette,
   and executable file management and support 
   functions for the Macintosh OS X SDL port 
   of Atari800
   Mark Grebe <atarimac@cox.net>
   
   Based on the Preferences pane of the
   TextEdit application.

*/
#import <Cocoa/Cocoa.h>
#import "MediaManager.h"
#import "Preferences.h"
#import "PrintOutputController.h"
#import "SioController.h"
#import "stdio.h"
#import <sys/stat.h>
#import <unistd.h>

extern int driveState[NUMBER_OF_ATARI_DRIVES];
extern char driveFilename[NUMBER_OF_ATARI_DRIVES][FILENAME_MAX];
extern char diskImageDefaultDirectory[FILENAME_MAX];
extern char cassImageDefaultDirectory[FILENAME_MAX];
extern char diskSetDefaultDirectory[FILENAME_MAX];
extern int currPrinter;
extern NSTimer *regTimer;

@implementation MediaManager

static MediaManager *sharedInstance = nil;

static NSImage *off810Image;
static NSImage *empty810Image;
static NSImage *closed810Image;
static NSImage *read810Image;
static NSImage *write810Image;
static NSImage *lockImage;
static NSImage *lockoffImage;
static NSImage *atari825Image;
static NSImage *atari1020Image;
static NSImage *epsonImage;
static NSImage *textImage;
static NSImage *on410Image;
static NSImage *off410Image;
static NSImage *on850Image;
static NSImage *off850Image;
NSImage *disketteImage;

+ (MediaManager *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
	char filename[FILENAME_MAX];
	
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        sharedInstance = self;
        /* load the nib and all the windows */
        if (!diskFmtMatrix) {
			if (![NSBundle loadNibNamed:@"MediaManager" owner:self])  {
				NSLog(@"Failed to load MediaManager.nib");
				NSBeep();
				return nil;
                }
            }
	[[diskFmtMatrix window] setExcludedFromWindowsMenu:YES];
	[[diskFmtMatrix window] setMenu:nil];
	[[errorButton window] setExcludedFromWindowsMenu:YES];
	[[errorButton window] setMenu:nil];
	[[d1DiskImageView window] setExcludedFromWindowsMenu:NO];
	[[cassNameField window] setExcludedFromWindowsMenu:YES];
	[[cassNameField window] setMenu:nil];

    off810Image = [NSImage imageNamed:@"atari810off"];
    empty810Image = [NSImage imageNamed:@"atari810emtpy"];
    closed810Image = [NSImage imageNamed:@"atari810closed"];
    read810Image = [NSImage imageNamed:@"atari810read"];
    write810Image = [NSImage imageNamed:@"atari810write"];

    lockImage = [NSImage imageNamed:@"lock"];
    
    lockoffImage = [NSImage alloc];
    [lockoffImage initWithSize: NSMakeSize(11.0,14.0)];
    [lockoffImage setBackgroundColor:[NSColor textBackgroundColor]];

    epsonImage = [NSImage imageNamed:@"epson"];
    atari825Image = [NSImage imageNamed:@"atari825"];
    atari1020Image = [NSImage imageNamed:@"atari1020"];
    textImage = [NSImage imageNamed:@"text"];

    on410Image = [NSImage imageNamed:@"cassetteon"];
    off410Image = [NSImage imageNamed:@"cassetteoff"];

	disketteImage = [NSImage alloc];
    strcpy(filename, "Contents/Resources/diskette.tiff");    
    disketteImage = [NSImage imageNamed:@"diskette"];

    on850Image = [NSImage imageNamed:@"850on"];
    off850Image = [NSImage imageNamed:@"850off"];

	cassPresent = NO;
	cassPlaying = NO;
	}

    return sharedInstance;
}

- (void)dealloc {
	[super dealloc];
}

- (NSWindow *) window {
	return([d1DiskImageView window]);
	}
	
/*------------------------------------------------------------------------------
*  mediaStatusWindowShow - This method makes the media status window visable
*-----------------------------------------------------------------------------*/
- (void)mediaStatusWindowShow:(id)sender
{
	[[d1DiskImageView window] center];
    [[d1DiskImageView window] makeKeyAndOrderFront:self];
	[[d1DiskImageView window] setTitle:@"Sio2OSX"];
	[self updateInfo];
}

/*------------------------------------------------------------------------------
*  displayError - This method displays an error dialog box with the passed in
*     error message.
*-----------------------------------------------------------------------------*/
- (void)displayError:(NSString *)errorMsg {
    [errorField setStringValue:errorMsg];
    [NSApp beginSheet:[errorButton window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [errorButton window]];
    // Sheet is up here.
    [NSApp endSheet: [errorButton window]];
    [[errorButton window] orderOut: self];
}

/*------------------------------------------------------------------------------
*  displayError2 - This method displays an error dialog box with the passed in
*     error messages.
*-----------------------------------------------------------------------------*/
- (void)displayError2:(NSString *)errorMsg1:(NSString *)errorMsg2 {
    [error2Field1 setStringValue:errorMsg1];
    [error2Field2 setStringValue:errorMsg2];
    [NSApp beginSheet:[error2Button window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [error2Button window]];
    // Sheet is up here.
    [NSApp endSheet: [error2Button window]];
    [[error2Button window] orderOut: self];
}

/*------------------------------------------------------------------------------
*  displayExpired - This method displays an error dialog box indicating the test
*     version of the program has expired.
*-----------------------------------------------------------------------------*/
- (void)displayExpired {
    [NSApp beginSheet:[expiredButton window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [expiredButton window]];
    // Sheet is up here.
    [NSApp endSheet: [expiredButton window]];
    [[expiredButton window] orderOut: self];
}

/*------------------------------------------------------------------------------
*  displaySpeed - This method displays the current SIO speed.
*-----------------------------------------------------------------------------*/
- (void)displaySpeed:(NSNumber *) speed;
{
	if (speed != 0)
		[speedField setIntValue:[speed intValue]];
	else
		[speedField setStringValue:@""];
}

/*------------------------------------------------------------------------------
*  updateInfo - This method is used to update the disk management window GUI.
*-----------------------------------------------------------------------------*/
- (void)updateInfo {
    int noDisks = TRUE;
    int i;
    for (i=0;i<8;i++) {
        if (driveState[i] == DRIVE_POWER_OFF)
            strcpy(driveFilename[i],"Off");
        switch(i) {
            case 0:
                if (driveState[0] == DRIVE_POWER_OFF || 
					driveState[0] == DRIVE_NO_DISK)
                    [removeD1Item setTarget:nil];
                else {
                    [removeD1Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 1:
                if (driveState[1] == DRIVE_POWER_OFF || 
					driveState[1] == DRIVE_NO_DISK)
                    [removeD2Item setTarget:nil];
                else {
                    [removeD2Item setTarget:self];
                    noDisks = FALSE;
                    }
            case 2:
                if (driveState[2] == DRIVE_POWER_OFF || 
					driveState[2] == DRIVE_NO_DISK)
                    [removeD3Item setTarget:nil];
                else {
                    [removeD3Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 3:
                if (driveState[3] == DRIVE_POWER_OFF || 
					driveState[3] == DRIVE_NO_DISK)
                    [removeD4Item setTarget:nil];
                else {
                    [removeD4Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 4:
                if (driveState[4] == DRIVE_POWER_OFF || 
					driveState[4] == DRIVE_NO_DISK)
                    [removeD5Item setTarget:nil];
                else {
                    [removeD5Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 5:
                if (driveState[5] == DRIVE_POWER_OFF || 
					driveState[5] == DRIVE_NO_DISK)
                    [removeD6Item setTarget:nil];
                else {
                    [removeD6Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 6:
                if (driveState[6] == DRIVE_POWER_OFF || 
					driveState[6] == DRIVE_NO_DISK)
                    [removeD7Item setTarget:nil];
                else {
                    [removeD7Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            case 7:
                if (driveState[7] == DRIVE_POWER_OFF || 
					driveState[7] == DRIVE_NO_DISK)
                    [removeD8Item setTarget:nil];
                else {
                    [removeD8Item setTarget:self];
                    noDisks = FALSE;
                    }
                break;
            }
        }

    if (noDisks) 
        [removeMenu setTarget:nil];
    else 
        [removeMenu setTarget:self];
	[self updateMediaStatusWindow];
}

/*------------------------------------------------------------------------------
*  browseFileInDirectory - This allows the user to chose a file to read in from
*     the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseFileInDirectory:(NSString *)directory {
    NSOpenPanel *openPanel = nil;
    
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModalForDirectory:directory file:nil types:nil] == NSOKButton)
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }

/*------------------------------------------------------------------------------
*  browseFileTypeInDirectory - This allows the user to chose a file of a 
*     specified typeto read in from the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) browseFileTypeInDirectory:(NSString *)directory:(NSArray *) filetypes:(BOOL) directories {
    NSOpenPanel *openPanel = nil;
	
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:directories];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModalForDirectory:directory file:nil 
            types:filetypes] == NSOKButton)
        return([[openPanel filenames] objectAtIndex:0]);
    else
        return nil;
    }

/*------------------------------------------------------------------------------
*  saveFileInDirectory - This allows the user to chose a filename to save in from
*     the specified directory.
*-----------------------------------------------------------------------------*/
- (NSString *) saveFileInDirectory:(NSString *)directory:(NSString *)type {
    NSSavePanel *savePanel = nil;
    
    savePanel = [NSSavePanel savePanel];
    
    [savePanel setRequiredFileType:type];
    
    if ([savePanel runModalForDirectory:directory file:nil] == NSOKButton)
        return([savePanel filename]);
    else
        return nil;
    }

/*------------------------------------------------------------------------------
*  cancelDisk - This method handles the cancel button from the disk image
*     creation window.
*-----------------------------------------------------------------------------*/
- (IBAction)cancelDisk:(id)sender
{
    [NSApp stopModal];
    [[diskFmtMatrix window] close];
}


/*------------------------------------------------------------------------------
*  createDisk - This method responds to the create disk button push in the disk
*     creation window, and actually creates the disk image.
*-----------------------------------------------------------------------------*/
- (IBAction)createDisk:(id)sender
{
    UInt32 bytesInBootSector;
    UInt32 bytesPerSector;
    UInt32 sectors;
    UInt32 imageLength;
    FILE *image = NULL;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    ATR_HEADER atrHeader;
    int diskMounted;
    int i;
    
    bytesInBootSector = ([diskFmtDDBytesPulldown indexOfSelectedItem] + 1) * 128;
    bytesPerSector = ([diskFmtCusBytesPulldown indexOfSelectedItem] + 1) * 128;
    sectors = [diskFmtCusSecField intValue];
    
    if (sectors <= 3)
        imageLength = sectors * bytesInBootSector / 16;
    else
        imageLength = ((sectors - 3) * bytesPerSector + 3 * bytesInBootSector) / 16;
    
    filename = [self saveFileInDirectory:[NSString stringWithCString:diskImageDefaultDirectory]:@"atr"];
    if (filename != nil) {
        [filename getCString:cfilename];
        image = fopen(cfilename, "wb");
        if (image == NULL) {
            [self displayError:@"Unable to Create Disk Image!"];
            }
        else {
            atrHeader.signatureByte1 = ATR_SIGNATURE_1;
            atrHeader.signatureByte2 = ATR_SIGNATURE_2;
            atrHeader.sectorSizeLow = bytesPerSector & 0x00ff;
            atrHeader.sectorSizeHigh = (bytesPerSector & 0xff00) >> 8;
            atrHeader.sectorCountLow = imageLength & 0x00ff;
            atrHeader.sectorCountHigh = (imageLength & 0xff00) >> 8;
            atrHeader.highSectorCountLow = (imageLength & 0x00ff0000) >> 16;
            atrHeader.highSectorCountHigh = (imageLength & 0xff000000) >> 24;
            for (i=0;i<8;i++)
                atrHeader.reserved[i] = 0;
            atrHeader.writeProtect = 0;
            
            fwrite(&atrHeader, sizeof(ATR_HEADER), 1, image);
            
            for (i = 0; i < imageLength; i++)
                fwrite("\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000",16,1,image);
                
            fflush(image);
            fclose(image);
            }
        }
        
    if ([diskFmtInsertNewButton state] == NSOnState) {
        diskMounted = [[SioController sharedInstance] 
                      mount:[diskFmtInsertDrivePulldown indexOfSelectedItem]:cfilename:0];
        if (!diskMounted)
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
    
    [NSApp stopModal];
    [[diskFmtMatrix window] close];
}

/*------------------------------------------------------------------------------
*  diskInsert - This method inserts a floppy disk in the specified drive in
*     response to a menu.
*-----------------------------------------------------------------------------*/
- (IBAction)diskInsert:(id)sender
{
    int diskNum = [sender tag] - 1;
    int readOnly;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    int diskMounted;
    
    readOnly = (driveState[diskNum] == DRIVE_READ_ONLY ? TRUE : FALSE);
    filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:diskImageDefaultDirectory]:
				  [NSArray arrayWithObjects:@"atr",@"ATR",@"atx",@"ATX",@"pro","@PRO",nil]:YES];
    
    if (filename != nil) {
        [[SioController sharedInstance] dismount:diskNum];
        [filename getCString:cfilename];
        diskMounted = [[SioController sharedInstance] mount:diskNum:cfilename:readOnly];
        if (!diskMounted)
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskRotate - This method rotates the floppy disks between drivers in
*     response to a menu.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRotate:(id)sender
{
    [[SioController sharedInstance] rotateDisks];
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskInsertFile - This method inserts a floppy disk into drive 1, given its
*     filename.
*-----------------------------------------------------------------------------*/
- (void)diskInsertFile:(NSString *)filename
{
    int readOnly;
    char cfilename[FILENAME_MAX];
    int diskMounted;
    
    readOnly = (driveState[0] == DRIVE_READ_ONLY ? TRUE : FALSE);
    if (filename != nil) {
        [[SioController sharedInstance] dismount:0];
        [filename getCString:cfilename];
        diskMounted = [[SioController sharedInstance] mount:0:cfilename:readOnly];
        if (!diskMounted)
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskNoInsertFile - This method inserts a floppy disk into a drive, given its
*     filename and the drives number.
*-----------------------------------------------------------------------------*/
- (void)diskNoInsertFile:(NSString *)filename:(int) driveNo
{
    int readOnly;
    char cfilename[FILENAME_MAX];
    int diskMounted;
    
    readOnly = (driveState[driveNo] == DRIVE_READ_ONLY ? TRUE : FALSE);
    if (filename != nil) {
        [[SioController sharedInstance] dismount:driveNo];
        [filename getCString:cfilename];
        diskMounted = [[SioController sharedInstance] mount:driveNo:cfilename:readOnly];
        if (!diskMounted)
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskInsertKey - This method inserts a floppy disk in the specified drive in
*     response to a keyboard shortcut.
*-----------------------------------------------------------------------------*/
- (IBAction)diskInsertKey:(int)diskNum
{
    int readOnly;
    NSString *filename;
    char cfilename[FILENAME_MAX];
    int diskMounted;
    
    readOnly = (driveState[diskNum] == DRIVE_READ_ONLY ? TRUE : FALSE);
    filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:diskImageDefaultDirectory]:
				  [NSArray arrayWithObjects:@"atr",@"ATR",@"atx",@"ATX",@"pro",@"PRO",nil]:YES];
   
    if (filename != nil) {
		[[SioController sharedInstance] dismount:diskNum-1];
        [filename getCString:cfilename];
        diskMounted = [[SioController sharedInstance] mount:diskNum-1:cfilename:readOnly];
        if (!diskMounted)
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskRemove - This method removes a floppy disk in the specified drive in
*     response to a menu.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemove:(id)sender
{
    int diskNum = [sender tag] - 1;

    [[SioController sharedInstance] dismount:diskNum];
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskRemoveKey - This method removes a floppy disk in the specified drive in
*     response to a keyboard shortcut.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemoveKey:(int)diskNum
{
    [[SioController sharedInstance] dismount:diskNum-1];
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskRemoveAll - This method removes disks from all of the floppy drives.
*-----------------------------------------------------------------------------*/
- (IBAction)diskRemoveAll:(id)sender
{
    int i;

    for (i=0;i<8;i++)
        [[SioController sharedInstance] dismount:i];
    [self updateInfo];
}

/*------------------------------------------------------------------------------
*  Save - This method saves the names of the mounted disks to a file
*      chosen by the user.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetSave:(id)sender
{
    NSString *filename;
    char *diskfilename;
    char dirname[FILENAME_MAX];
    char cfilename[FILENAME_MAX+1];
    FILE *f;
    int i;

    filename = [self saveFileInDirectory:[NSString stringWithCString:diskSetDefaultDirectory]:@"set"];
    
    if (filename == nil)
        return;
                    
    [filename getCString:cfilename];

    getcwd(dirname, FILENAME_MAX);

    f = fopen(cfilename, "w");
    if (f) {
        for (i=0;i<8;i++) {
			if (strncmp(driveFilename[i], dirname, strlen(dirname)) == 0)
				diskfilename = &driveFilename[i][strlen(dirname)+1];
			else
				diskfilename = driveFilename[i];
		
            fputs(diskfilename,f);
            fprintf(f,"\n");
            }
        fclose(f);
        }
}

/*------------------------------------------------------------------------------
*  diskSetLoad - This method mounts the set of disk images from a file
*      chosen by the user.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetLoad:(id)sender
{
    NSString *filename;
    char cfilename[FILENAME_MAX+1];
    char diskname[FILENAME_MAX+1];
    FILE *f;
    int i, mounted, readOnly;
    int numMountErrors = 0;
    int mountErrors[8];

    filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:diskSetDefaultDirectory]:
				  [NSArray arrayWithObjects:@"set",@"SET", nil]:NO];
    
    if (filename == nil)
        return;
    
    [filename getCString:cfilename];
    f = fopen(cfilename, "r");
    if (f) {
        for (i=0;i<8;i++) {
            fgets(diskname,FILENAME_MAX,f);
            if (strlen(diskname) != 0)
                diskname[strlen(diskname)-1] = 0;
            if ((strcmp(diskname,"Off") != 0) && (strcmp(diskname,"Empty") != 0)) {
                readOnly = (driveState[i] == DRIVE_READ_ONLY ? TRUE : FALSE);
                [[SioController sharedInstance] dismount:i];
                mounted = [[SioController sharedInstance] mount:i:diskname:readOnly];
                if (!mounted) {
                    numMountErrors++;
                    mountErrors[i] = 1;
                    }
                else
                    mountErrors[i] = 0;
                }
            else
                mountErrors[i] = 0;
            }
        fclose(f);
        if (numMountErrors != 0) 
            [self displayError:@"Unable to Mount Disk Image!"];
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  diskSetLoad - This method mounts the set of disk images from a file
*      specified by the filename parameter.
*-----------------------------------------------------------------------------*/
- (IBAction)diskSetLoadFile:(NSString *)filename
{
    char cfilename[FILENAME_MAX+1];
    char diskname[FILENAME_MAX+1];
    FILE *f;
    int i, readOnly;

    [filename getCString:cfilename];
    f = fopen(cfilename, "r");
    if (f) {
        for (i=0;i<8;i++) {
            fgets(diskname,FILENAME_MAX,f);
            if (strlen(diskname) != 0)
                diskname[strlen(diskname)-1] = 0;
            if ((strcmp(diskname,"Off") != 0) && (strcmp(diskname,"Empty") != 0)) {
                readOnly = (driveState[i] == DRIVE_READ_ONLY ? TRUE : FALSE);
                [[SioController sharedInstance] dismount:i];
                [[SioController sharedInstance] mount:i:diskname:readOnly];
                }
            }
        fclose(f);
        [self updateInfo];
        }
}

/*------------------------------------------------------------------------------
*  miscUpdate - This method handles control updates in the disk image creation
*     window.
*-----------------------------------------------------------------------------*/
- (IBAction)miscUpdate:(id)sender
{
    if (sender == diskFmtMatrix) {
        switch([[diskFmtMatrix selectedCell] tag]) {
            case 0:
                [diskFmtCusBytesPulldown selectItemAtIndex:0];
                [diskFmtCusSecField setIntValue:720];
                [diskFmtDDBytesPulldown selectItemAtIndex:0];
                [diskFmtCusBytesPulldown setEnabled:NO];
                [diskFmtCusSecField setEnabled:NO];
                [diskFmtDDBytesPulldown setEnabled:NO];
                break;
            case 1:
                [diskFmtCusBytesPulldown selectItemAtIndex:0];
                [diskFmtCusSecField setIntValue:1040];
                [diskFmtDDBytesPulldown selectItemAtIndex:0];
                [diskFmtCusBytesPulldown setEnabled:NO];
                [diskFmtCusSecField setEnabled:NO];
                [diskFmtDDBytesPulldown setEnabled:NO];
                break;
            case 2:
                [diskFmtCusBytesPulldown selectItemAtIndex:1];
                [diskFmtCusSecField setIntValue:720];
                [diskFmtDDBytesPulldown selectItemAtIndex:0];
                [diskFmtCusBytesPulldown setEnabled:NO];
                [diskFmtCusSecField setEnabled:NO];
                [diskFmtDDBytesPulldown setEnabled:YES];
                break;
            case 3:
                [diskFmtCusBytesPulldown setEnabled:YES];
                [diskFmtCusSecField setEnabled:YES];
                [diskFmtDDBytesPulldown setEnabled:YES];
                break;
            }
        }
    else if (sender == diskFmtInsertNewButton) {
        if ([diskFmtInsertNewButton state] == NSOnState)
            [diskFmtInsertDrivePulldown setEnabled:YES];
        else
            [diskFmtInsertDrivePulldown setEnabled:NO];        
        }
}

/*------------------------------------------------------------------------------
*  errorOK - This method handles the OK button press from the error window.
*-----------------------------------------------------------------------------*/
- (IBAction)errorOK:(id)sender;
{
    [NSApp stopModal];
    [[errorButton window] close];
}

/*------------------------------------------------------------------------------
*  error2OK - This method handles the OK button press from the error2 window.
*-----------------------------------------------------------------------------*/
- (IBAction)error2OK:(id)sender;
{
    [NSApp stopModal];
    [[error2Button window] close];
}

/*------------------------------------------------------------------------------
*  errorOK - This method handles the OK button press from the error window.
*-----------------------------------------------------------------------------*/
- (IBAction)expiredOK:(id)sender;
{
    [NSApp stopModal];
    [[expiredButton window] close];
}

/*------------------------------------------------------------------------------
*  showCreatePanel - This method displays a window which allows the creation of
*     blank floppy images.
*-----------------------------------------------------------------------------*/
- (IBAction)showCreatePanel:(id)sender
{
    [diskFmtMatrix selectCellWithTag:0];
    [diskFmtCusBytesPulldown setEnabled:NO];
    [diskFmtCusSecField setEnabled:NO];
    [diskFmtDDBytesPulldown setEnabled:NO];
    [diskFmtInsertDrivePulldown setEnabled:NO];
    [diskFmtCusBytesPulldown selectItemAtIndex:0];
    [diskFmtCusSecField setIntValue:720];
    [diskFmtDDBytesPulldown selectItemAtIndex:0];
    [diskFmtInsertNewButton setState:NSOffState];
    [NSApp beginSheet:[diskFmtMatrix window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [diskFmtMatrix window]];
    // Sheet is up here.
    [NSApp endSheet: [diskFmtMatrix window]];
    [[diskFmtMatrix window] orderOut: self];
}

/*------------------------------------------------------------------------------
*  diskStatusChange - This is called when a drive Insert/Eject is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskStatusChange:(id)sender
{
	int driveNo = [sender tag];
	
	if (driveState[driveNo] == DRIVE_NO_DISK) {
		[self diskInsertKey:(driveNo+1)];
		}
	else {
		[self diskRemoveKey:(driveNo+1)];
		}
}

/*------------------------------------------------------------------------------
*  diskStatusPower - This is called when a drive On/Off is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskStatusPower:(id)sender
{
	int driveNo = [sender tag];
	
	if (driveState[driveNo] == DRIVE_POWER_OFF) {
		driveState[driveNo] = DRIVE_NO_DISK;
        strcpy(driveFilename[driveNo],"Empty");
		}
	else {
		if (driveState[driveNo] == DRIVE_READ_ONLY || 
			driveState[driveNo] == DRIVE_READ_WRITE) 
			[[SioController sharedInstance] dismount:driveNo];
		[[SioController sharedInstance] turnDriveOff:driveNo];
		}
	[self updateInfo];
}

/*------------------------------------------------------------------------------
*  diskStatusProtect - This is called when a drive Lock/Unlock is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)diskStatusProtect:(id)sender
{
    char tempFilename[FILENAME_MAX];
	int driveNo = [sender tag];
	int status;
	
	status = driveState[driveNo];
	
    strcpy(tempFilename, driveFilename[driveNo]);
	[[SioController sharedInstance] dismount:driveNo];
	
	if (status == DRIVE_READ_WRITE) {
		[[SioController sharedInstance] mount:driveNo:tempFilename:TRUE];
		}
	else {
		[[SioController sharedInstance] mount:driveNo:tempFilename:FALSE];
		}
	[self updateInfo];
}

/*------------------------------------------------------------------------------
*  updateMediaStatusWindow - Update the media status window when something
*      changes.
*-----------------------------------------------------------------------------*/
- (void) updateMediaStatusWindow
{
	char *ptr;

	[selectPrinterPulldown setEnabled:YES];
	[selectTextMenuItem setTarget:[PrintOutputController sharedInstance]];
	[selectAtari825MenuItem setTarget:[PrintOutputController sharedInstance]];
	[selectAtari1020MenuItem setTarget:[PrintOutputController sharedInstance]];
	[selectEpsonMenuItem setTarget:[PrintOutputController sharedInstance]];
	switch(currPrinter)
		{
		case 0:
			[printerImageNameField setStringValue:@"Text"];
			[printerImageView setImage:textImage];
			[printerPreviewItem setTarget:nil];
			[printerPreviewButton setEnabled:NO];
			[selectTextItem setState:NSOnState];
			[selectAtari825Item setState:NSOffState];
			[selectAtari1020Item setState:NSOffState];
			[selectEpsonItem setState:NSOffState];
			[resetPrinterButton setTarget:[SioController sharedInstance]];
			[resetPrinterMenuItem setTarget:[SioController sharedInstance]];
			break;
		case 1:
			[printerImageNameField setStringValue:@"Atari 825"];
			[printerImageView setImage:atari825Image];
			[printerPreviewItem setTarget:[PrintOutputController sharedInstance]];
			[printerPreviewButton setEnabled:YES];
			[selectTextItem setState:NSOffState];
			[selectAtari825Item setState:NSOnState];
			[selectAtari1020Item setState:NSOffState];
			[selectEpsonItem setState:NSOffState];
			[resetPrinterButton setTarget:[PrintOutputController sharedInstance]];
			[resetPrinterMenuItem setTarget:[PrintOutputController sharedInstance]];
			break;
		case 2:
			[printerImageNameField setStringValue:@"Atari 1020"];
			[printerImageView setImage:atari1020Image];
			[printerPreviewItem setTarget:[PrintOutputController sharedInstance]];
			[printerPreviewButton setEnabled:YES];
			[selectTextItem setState:NSOffState];
			[selectAtari825Item setState:NSOffState];
			[selectAtari1020Item setState:NSOnState];
			[selectEpsonItem setState:NSOffState];
			[resetPrinterButton setTarget:[PrintOutputController sharedInstance]];
			[resetPrinterMenuItem setTarget:[PrintOutputController sharedInstance]];
			break;
		case 3:
			[printerImageNameField setStringValue:@"Epson FX80"];
			[printerImageView setImage:epsonImage];
			[printerPreviewItem setTarget:[PrintOutputController sharedInstance]];
			[printerPreviewButton setEnabled:YES];
			[selectTextItem setState:NSOffState];
			[selectAtari825Item setState:NSOffState];
			[selectAtari1020Item setState:NSOffState];
			[selectEpsonItem setState:NSOnState];
			[resetPrinterButton setTarget:[PrintOutputController sharedInstance]];
			[resetPrinterMenuItem setTarget:[PrintOutputController sharedInstance]];
			break;
		}
	
	switch(driveState[0]) {
		case DRIVE_POWER_OFF:
			[d1DiskImageNameField setStringValue:@"Off"];
			[d1DiskImagePowerButton setTitle:@"On"];
			[d1DiskImageInsertButton setTitle:@"Insert"];
			[d1DiskImageInsertButton setEnabled:NO];
			[d1DiskImageProtectButton setTitle:@"Lock"];
			[d1DiskImageProtectButton setEnabled:NO];
			[d1DiskImageView setImage:off810Image];
			[d1DiskImageLockView setImage:lockoffImage];
			break;
			[d1DiskImageSectorField setStringValue:@""];
		case DRIVE_NO_DISK:
			[d1DiskImageNameField setStringValue:@"Empty"];
			[d1DiskImagePowerButton setTitle:@"Off"];
			[d1DiskImageInsertButton setTitle:@"Insert"];
			[d1DiskImageInsertButton setEnabled:YES];
			[d1DiskImageProtectButton setTitle:@"Lock"];
			[d1DiskImageProtectButton setEnabled:NO];
			[d1DiskImageView setImage:empty810Image];
			[d1DiskImageLockView setImage:lockoffImage];
			[d1DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[0];
			[d1DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d1DiskImagePowerButton setTitle:@"Off"];
			[d1DiskImageInsertButton setTitle:@"Eject"];
			[d1DiskImageInsertButton setEnabled:YES];
			if (driveState[0] == DRIVE_READ_WRITE) {
				[d1DiskImageProtectButton setTitle:@"Lock"];
				[d1DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d1DiskImageProtectButton setTitle:@"Unlk"];
				[d1DiskImageLockView setImage:lockImage];
				}
			[d1DiskImageProtectButton setEnabled:YES];
			[d1DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[1]) {
		case DRIVE_POWER_OFF:
			[d2DiskImageNameField setStringValue:@"Off"];
			[d2DiskImagePowerButton setTitle:@"On"];
			[d2DiskImageInsertButton setTitle:@"Insert"];
			[d2DiskImageInsertButton setEnabled:NO];
			[d2DiskImageProtectButton setTitle:@"Lock"];
			[d2DiskImageProtectButton setEnabled:NO];
			[d2DiskImageView setImage:off810Image];
			[d2DiskImageLockView setImage:lockoffImage];
			[d2DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d2DiskImageNameField setStringValue:@"Empty"];
			[d2DiskImagePowerButton setTitle:@"Off"];
			[d2DiskImageInsertButton setTitle:@"Insert"];
			[d2DiskImageInsertButton setEnabled:YES];
			[d2DiskImageProtectButton setTitle:@"Lock"];
			[d2DiskImageProtectButton setEnabled:NO];
			[d2DiskImageView setImage:empty810Image];
			[d2DiskImageLockView setImage:lockoffImage];
			[d2DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[1];
			[d2DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d2DiskImagePowerButton setTitle:@"Off"];
			[d2DiskImageInsertButton setTitle:@"Eject"];
			[d2DiskImageInsertButton setEnabled:YES];
			if (driveState[1] == DRIVE_READ_WRITE) {
				[d2DiskImageProtectButton setTitle:@"Lock"];
				[d2DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d2DiskImageProtectButton setTitle:@"Unlk"];
				[d2DiskImageLockView setImage:lockImage];
				}
			[d2DiskImageProtectButton setEnabled:YES];
			[d2DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[2]) {
		case DRIVE_POWER_OFF:
			[d3DiskImageNameField setStringValue:@"Off"];
			[d3DiskImagePowerButton setTitle:@"On"];
			[d3DiskImageInsertButton setTitle:@"Insert"];
			[d3DiskImageInsertButton setEnabled:NO];
			[d3DiskImageProtectButton setTitle:@"Lock"];
			[d3DiskImageProtectButton setEnabled:NO];
			[d3DiskImageView setImage:off810Image];
			[d3DiskImageLockView setImage:lockoffImage];
			[d3DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d3DiskImageNameField setStringValue:@"Empty"];
			[d3DiskImagePowerButton setTitle:@"Off"];
			[d3DiskImageInsertButton setTitle:@"Insert"];
			[d3DiskImageInsertButton setEnabled:YES];
			[d3DiskImageProtectButton setTitle:@"Lock"];
			[d3DiskImageProtectButton setEnabled:NO];
			[d3DiskImageView setImage:empty810Image];
			[d3DiskImageLockView setImage:lockoffImage];
			[d3DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[2];
			[d3DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d3DiskImagePowerButton setTitle:@"Off"];
			[d3DiskImageInsertButton setTitle:@"Eject"];
			[d3DiskImageInsertButton setEnabled:YES];
			if (driveState[2] == DRIVE_READ_WRITE) {
				[d3DiskImageProtectButton setTitle:@"Lock"];
				[d3DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d3DiskImageProtectButton setTitle:@"Unlk"];
				[d3DiskImageLockView setImage:lockImage];
				}
			[d3DiskImageProtectButton setEnabled:YES];
			[d3DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[3]) {
		case DRIVE_POWER_OFF:
			[d4DiskImageNameField setStringValue:@"Off"];
			[d4DiskImagePowerButton setTitle:@"On"];
			[d4DiskImageInsertButton setTitle:@"Insert"];
			[d4DiskImageInsertButton setEnabled:NO];
			[d4DiskImageProtectButton setTitle:@"Lock"];
			[d4DiskImageProtectButton setEnabled:NO];
			[d4DiskImageView setImage:off810Image];
			[d4DiskImageLockView setImage:lockoffImage];
			[d4DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d4DiskImageNameField setStringValue:@"Empty"];
			[d4DiskImagePowerButton setTitle:@"Off"];
			[d4DiskImageInsertButton setTitle:@"Insert"];
			[d4DiskImageInsertButton setEnabled:YES];
			[d4DiskImageProtectButton setTitle:@"Lock"];
			[d4DiskImageProtectButton setEnabled:NO];
			[d4DiskImageView setImage:empty810Image];
			[d4DiskImageLockView setImage:lockoffImage];
			[d4DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[3];
			[d4DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d4DiskImagePowerButton setTitle:@"Off"];
			[d4DiskImageInsertButton setTitle:@"Eject"];
			[d4DiskImageInsertButton setEnabled:YES];
			if (driveState[3] == DRIVE_READ_WRITE) {
				[d4DiskImageProtectButton setTitle:@"Lock"];
				[d4DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d4DiskImageProtectButton setTitle:@"Unlk"];
				[d4DiskImageLockView setImage:lockImage];
				}
			[d4DiskImageProtectButton setEnabled:YES];
			[d4DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[4]) {
		case DRIVE_POWER_OFF:
			[d5DiskImageNameField setStringValue:@"Off"];
			[d5DiskImagePowerButton setTitle:@"On"];
			[d5DiskImageInsertButton setTitle:@"Insert"];
			[d5DiskImageInsertButton setEnabled:NO];
			[d5DiskImageProtectButton setTitle:@"Lock"];
			[d5DiskImageProtectButton setEnabled:NO];
			[d5DiskImageView setImage:off810Image];
			[d5DiskImageLockView setImage:lockoffImage];
			[d5DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d5DiskImageNameField setStringValue:@"Empty"];
			[d5DiskImagePowerButton setTitle:@"Off"];
			[d5DiskImageInsertButton setTitle:@"Insert"];
			[d5DiskImageInsertButton setEnabled:YES];
			[d5DiskImageProtectButton setTitle:@"Lock"];
			[d5DiskImageProtectButton setEnabled:NO];
			[d5DiskImageView setImage:empty810Image];
			[d5DiskImageLockView setImage:lockoffImage];
			[d5DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[4];
			[d5DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d5DiskImagePowerButton setTitle:@"Off"];
			[d5DiskImageInsertButton setTitle:@"Eject"];
			[d5DiskImageInsertButton setEnabled:YES];
			if (driveState[4] == DRIVE_READ_WRITE) {
				[d5DiskImageProtectButton setTitle:@"Lock"];
				[d5DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d5DiskImageProtectButton setTitle:@"Unlk"];
				[d5DiskImageLockView setImage:lockImage];
				}
			[d5DiskImageProtectButton setEnabled:YES];
			[d5DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[5]) {
		case DRIVE_POWER_OFF:
			[d6DiskImageNameField setStringValue:@"Off"];
			[d6DiskImagePowerButton setTitle:@"On"];
			[d6DiskImageInsertButton setTitle:@"Insert"];
			[d6DiskImageInsertButton setEnabled:NO];
			[d6DiskImageProtectButton setTitle:@"Lock"];
			[d6DiskImageProtectButton setEnabled:NO];
			[d6DiskImageView setImage:off810Image];
			[d6DiskImageLockView setImage:lockoffImage];
			[d6DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d6DiskImageNameField setStringValue:@"Empty"];
			[d6DiskImagePowerButton setTitle:@"Off"];
			[d6DiskImageInsertButton setTitle:@"Insert"];
			[d6DiskImageInsertButton setEnabled:YES];
			[d6DiskImageProtectButton setTitle:@"Lock"];
			[d6DiskImageProtectButton setEnabled:NO];
			[d6DiskImageView setImage:empty810Image];
			[d6DiskImageLockView setImage:lockoffImage];
			[d6DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[5];
			[d6DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d6DiskImagePowerButton setTitle:@"Off"];
			[d6DiskImageInsertButton setTitle:@"Eject"];
			[d6DiskImageInsertButton setEnabled:YES];
			if (driveState[5] == DRIVE_READ_WRITE) {
				[d6DiskImageProtectButton setTitle:@"Lock"];
				[d6DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d6DiskImageProtectButton setTitle:@"Unlk"];
				[d6DiskImageLockView setImage:lockImage];
				}
			[d6DiskImageProtectButton setEnabled:YES];
			[d6DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[6]) {
		case DRIVE_POWER_OFF:
			[d7DiskImageNameField setStringValue:@"Off"];
			[d7DiskImagePowerButton setTitle:@"On"];
			[d7DiskImageInsertButton setTitle:@"Insert"];
			[d7DiskImageInsertButton setEnabled:NO];
			[d7DiskImageProtectButton setTitle:@"Lock"];
			[d7DiskImageProtectButton setEnabled:NO];
			[d7DiskImageView setImage:off810Image];
			[d7DiskImageLockView setImage:lockoffImage];
			[d7DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d7DiskImageNameField setStringValue:@"Empty"];
			[d7DiskImagePowerButton setTitle:@"Off"];
			[d7DiskImageInsertButton setTitle:@"Insert"];
			[d7DiskImageInsertButton setEnabled:YES];
			[d7DiskImageProtectButton setTitle:@"Lock"];
			[d7DiskImageProtectButton setEnabled:NO];
			[d7DiskImageView setImage:empty810Image];
			[d7DiskImageLockView setImage:lockoffImage];
			[d7DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[6];
			[d7DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d7DiskImagePowerButton setTitle:@"Off"];
			[d7DiskImageInsertButton setTitle:@"Eject"];
			[d7DiskImageInsertButton setEnabled:YES];
			if (driveState[6] == DRIVE_READ_WRITE) {
				[d7DiskImageProtectButton setTitle:@"Lock"];
				[d7DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d7DiskImageProtectButton setTitle:@"Unlk"];
				[d7DiskImageLockView setImage:lockImage];
				}
			[d7DiskImageProtectButton setEnabled:YES];
			[d7DiskImageView setImage:closed810Image];
			break;
		}
	switch(driveState[7]) {
		case DRIVE_POWER_OFF:
			[d8DiskImageNameField setStringValue:@"Off"];
			[d8DiskImagePowerButton setTitle:@"On"];
			[d8DiskImageInsertButton setTitle:@"Insert"];
			[d8DiskImageInsertButton setEnabled:NO];
			[d8DiskImageProtectButton setTitle:@"Lock"];
			[d8DiskImageProtectButton setEnabled:NO];
			[d8DiskImageView setImage:off810Image];
			[d8DiskImageLockView setImage:lockoffImage];
			[d8DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_NO_DISK:
			[d8DiskImageNameField setStringValue:@"Empty"];
			[d8DiskImagePowerButton setTitle:@"Off"];
			[d8DiskImageInsertButton setTitle:@"Insert"];
			[d8DiskImageInsertButton setEnabled:YES];
			[d8DiskImageProtectButton setTitle:@"Lock"];
			[d8DiskImageProtectButton setEnabled:NO];
			[d8DiskImageView setImage:empty810Image];
			[d8DiskImageLockView setImage:lockoffImage];
			[d8DiskImageSectorField setStringValue:@""];
			break;
		case DRIVE_READ_WRITE:
		case DRIVE_READ_ONLY:
			ptr = driveFilename[7];
			[d8DiskImageNameField setStringValue:[NSString stringWithCString:ptr]];
			[d8DiskImagePowerButton setTitle:@"Off"];
			[d8DiskImageInsertButton setTitle:@"Eject"];
			[d8DiskImageInsertButton setEnabled:YES];
			if (driveState[7] == DRIVE_READ_WRITE) {
				[d8DiskImageProtectButton setTitle:@"Lock"];
				[d8DiskImageLockView setImage:lockoffImage];
				}
			else {
				[d8DiskImageProtectButton setTitle:@"Unlk"];
				[d8DiskImageLockView setImage:lockImage];
				}
			[d8DiskImageProtectButton setEnabled:YES];
			[d8DiskImageView setImage:closed810Image];
			break;
		}

	if ([[SioController sharedInstance] getEnable850]) {
		[serial850ImageView setImage:on850Image];
		[serial850PowerButton setTitle:@"Off"];
		}
	else {
		[serial850ImageView setImage:off850Image];
		[serial850PowerButton setTitle:@"On"];
		}
}

- (void) updateLed:(LedUpdate *) update
{
	int on = [update on];
	int drive = [update drive];
	
	[self statusLed:drive:on:[update read]];
	[self sectorLed:drive:[update sector]:on];
}

/*------------------------------------------------------------------------------
*  statusLed - Turn the status LED on or off on a drive, different color for
*    read and write.
*-----------------------------------------------------------------------------*/
- (void) statusLed:(int)diskNo:(int)on:(int)read
{		
	if (on) {
		if (read) {
		    switch(diskNo) {
				case 0:
					[d1DiskImageView setImage:read810Image];
					break;
				case 1:
					[d2DiskImageView setImage:read810Image];
					break;
				case 2:
					[d3DiskImageView setImage:read810Image];
					break;
				case 3:
					[d4DiskImageView setImage:read810Image];
					break;
				case 4:
					[d5DiskImageView setImage:read810Image];
					break;
				case 5:
					[d6DiskImageView setImage:read810Image];
					break;
				case 6:
					[d7DiskImageView setImage:read810Image];
					break;
				case 7:
					[d8DiskImageView setImage:read810Image];
					break;
				}
			}
		else {
		    switch(diskNo) {
				case 0:
					[d1DiskImageView setImage:write810Image];
					break;
				case 1:
					[d2DiskImageView setImage:write810Image];
					break;
				case 2:
					[d3DiskImageView setImage:write810Image];
					break;
				case 3:
					[d4DiskImageView setImage:write810Image];
					break;
				case 4:
					[d5DiskImageView setImage:write810Image];
					break;
				case 5:
					[d6DiskImageView setImage:write810Image];
					break;
				case 6:
					[d7DiskImageView setImage:write810Image];
					break;
				case 7:
					[d8DiskImageView setImage:write810Image];
					break;
				}
			}
		}
	else {
	    switch(diskNo) {
			case 0:
				[d1DiskImageView setImage:closed810Image];
				break;
			case 1:
				[d2DiskImageView setImage:closed810Image];
				break;
			case 2:
				[d3DiskImageView setImage:closed810Image];
				break;
			case 3:
				[d4DiskImageView setImage:closed810Image];
				break;
			case 4:
				[d5DiskImageView setImage:closed810Image];
				break;
			case 5:
				[d6DiskImageView setImage:closed810Image];
				break;
			case 6:
				[d7DiskImageView setImage:closed810Image];
				break;
			case 7:
				[d8DiskImageView setImage:closed810Image];
				break;
			}
		}
}

/*------------------------------------------------------------------------------
*  sectorLed - Turn the sector number display on a drive on or off.
*-----------------------------------------------------------------------------*/
- (void) sectorLed:(int)diskNo:(int)sectorNo:(int)on
{
	char sectorString[8];
	
	if (on) {
		sprintf(sectorString,"  %03d",sectorNo);
	    switch(diskNo) {
			case 0:
				[d1DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 1:
				[d2DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 2:
				[d3DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 3:
				[d4DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 4:
				[d5DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 5:
				[d6DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 6:
				[d7DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			case 7:
				[d8DiskImageSectorField setStringValue:[NSString stringWithCString:sectorString]];
				break;
			}
	}
	else {
	    switch(diskNo) {
			case 0:
				[d1DiskImageSectorField setStringValue:@""];
				break;
			case 1:
				[d2DiskImageSectorField setStringValue:@""];
				break;
			case 2:
				[d3DiskImageSectorField setStringValue:@""];
				break;
			case 3:
				[d4DiskImageSectorField setStringValue:@""];
				break;
			case 4:
				[d5DiskImageSectorField setStringValue:@""];
				break;
			case 5:
				[d6DiskImageSectorField setStringValue:@""];
				break;
			case 6:
				[d7DiskImageSectorField setStringValue:@""];
				break;
			case 7:
				[d8DiskImageSectorField setStringValue:@""];
				break;
			}
	}
}

/*------------------------------------------------------------------------------
*  getDiskImageView - Return the image view for a particular drive.
*-----------------------------------------------------------------------------*/
- (NSImageView *) getDiskImageView:(int)tag
{
	switch(tag)
	{
		case 0:
		default:
			return(d1DiskImageView);
		case 1:
			return(d2DiskImageView);
		case 2:
			return(d3DiskImageView);
		case 3:
			return(d4DiskImageView);
		case 4:
			return(d5DiskImageView);
		case 5:
			return(d6DiskImageView);
		case 6:
			return(d7DiskImageView);
		case 7:
			return(d8DiskImageView);
	}
}

/*------------------------------------------------------------------------------
*  closeKeyWindow - Called to close the front window in the application.  
*      Placed in this class for lack of a better place. :)
*-----------------------------------------------------------------------------*/
-(void)closeKeyWindow:(id)sender
{
	[[NSApp keyWindow] performClose:NSApp];
}

- (void)addModem:(char *)modemName:(BOOL)first
{
	NSString *string = [NSString stringWithCString:modemName];
	
	if (first)
		[sioPortPulldown removeAllItems];
	[sioPortPulldown addItemWithTitle:string];
}

- (void)selectModem:(int)modemIndex
{
	[sioPortPulldown selectItemAtIndex:modemIndex];
}

- (IBAction)modemChange:(id)sender
{
	[[SioController sharedInstance] modemChange:[sioPortPulldown indexOfSelectedItem]];
}

- (IBAction)cassToStart:(id)sender
{
	if (cassPresent && !cassPlaying) {
		[[SioController sharedInstance] adjustCassBlock:0];
		}
}

- (IBAction)cassRewind:(id)sender
{
	if (cassPresent && !cassPlaying) {
		[[SioController sharedInstance] adjustCassBlock:-1];
		}
}

- (IBAction)cassFastForward:(id)sender
{
	if (cassPresent && !cassPlaying) {
		[[SioController sharedInstance] adjustCassBlock:1];
		}
}

- (IBAction)cassPlay:(id)sender
{
	if (cassPresent) {
		if (cassPlaying) {
			[[SioController sharedInstance] stopCassette];
			[cassStatusField setStringValue:@"Stopping"];
			while (cassPlaying) {
				usleep(100000);
				}
			[cassStatusField setStringValue:@""];
			[cassRewindButton setEnabled:YES];
			[cassFastForwardButton setEnabled:YES];
			[cassToStartButton setEnabled:YES];
			}
		else {
			cassPlaying = YES;
			[cassRewindButton setEnabled:NO];
			[cassFastForwardButton setEnabled:NO];
			[cassToStartButton setEnabled:NO];
			[NSThread detachNewThreadSelector:@selector(runCassServer) 
				toTarget:[SioController sharedInstance] withObject:nil];
			}
		}
}

- (IBAction)cassInsert:(id)sender
{
    NSString *filename;
    char cassName[FILENAME_MAX+1];
	int numBlocks;
    
	if (cassPresent) {
		[[SioController sharedInstance] cassUnmount];
		[cassInsertButton setTitle:@"Insert"];
		[cassImage setImage:off410Image];
		[cassCurrentField setStringValue:@"-"];
		[cassMinField setStringValue:@"-"];
		[cassMaxField setStringValue:@"-"];
		[cassProgressIndicator setDoubleValue:0.0];
		[cassStatusField setStringValue:@""];
		[cassRewindButton setEnabled:NO];
		[cassFastForwardButton setEnabled:NO];
		[cassToStartButton setEnabled:NO];
		[cassPlayButton setEnabled:NO];
		cassPresent = NO;
		}
	else {
		filename = [self browseFileTypeInDirectory:
                  [NSString stringWithCString:cassImageDefaultDirectory]:
				  [NSArray arrayWithObjects:@"cas",@"CAS", nil]:NO];
		if (filename != nil) {
			[filename getCString:cassName];
			if ((numBlocks = [[SioController sharedInstance] cassMount:cassName]) == 0)
				[self displayCassError:@"Unable to Insert Cassette!"];
			else
				{
				[cassImage setImage:on410Image];
				[cassMaxField setIntValue:numBlocks];
				[cassMinField setIntValue:1];
				[cassCurrentField setIntValue:1];
				[cassProgressIndicator setDoubleValue:0.0];
				[cassStatusField setStringValue:@""];
				[cassNameField setStringValue:filename];
				[cassInsertButton setTitle:@"Eject"];
				[cassRewindButton setEnabled:YES];
				[cassFastForwardButton setEnabled:YES];
				[cassToStartButton setEnabled:YES];
				[cassPlayButton setEnabled:YES];
				cassPresent = YES;
				}
			}
		}

}

- (IBAction)cassDone:(id)sender
{
	if (cassPlaying) {
		[[SioController sharedInstance] stopCassette];
		[cassStatusField setStringValue:@"Stopping"];
		while (cassPlaying) {
			usleep(100000);
			}
		[cassStatusField setStringValue:@""];
		}
    [NSApp stopModal];
    [[cassNameField window] close];
}

- (IBAction)cassStart:(id)sender
{
	[[SioController sharedInstance] pauseDiskServer:YES];
    [NSApp beginSheet:[cassNameField window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [cassNameField window]];
	[[SioController sharedInstance] pauseDiskServer:NO];
    [NSApp endSheet: [cassNameField window]];
    [[cassNameField window] orderOut: self];
}

/*------------------------------------------------------------------------------
*  displayCassError - This method displays an error dialog box with the passed 
*     in error message.
*-----------------------------------------------------------------------------*/
- (void)displayCassError:(NSString *)errorMsg {
    [errorField setStringValue:errorMsg];
    [NSApp beginSheet:[errorButton window]
            modalForWindow: [cassNameField window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow: [errorButton window]];
    // Sheet is up here.
    [NSApp endSheet: [errorButton window]];
    [[errorButton window] orderOut: self];
}

- (void)updateCassetteInfo:(CassInfoUpdate *)update;
{
	float blocksDone, blocksTotal;
	
	[cassCurrentField setIntValue:[update current]];
	blocksDone = [update current] - 1;
	blocksTotal = [update max];
	[cassProgressIndicator setDoubleValue:(100*(blocksDone/blocksTotal))];
}

- (void)updateCassStatus:(CassStatusUpdate *)update;
{
	char stat[80];
	if ([update gap]) 
		sprintf(stat,"InterBlock Gap %d\n",[update block]);
	else
		sprintf(stat,"Sending Block %d\n",[update block]);
	[cassStatusField setStringValue:[NSString stringWithCString:stat]];
}

- (void)notifyCassStopped
{
	[cassStatusField setStringValue:@""];
	[cassPlayButton setState:NSOffState];
	cassPlaying = NO;
}

/*------------------------------------------------------------------------------
*  serial850Power - This is called when a 850 On/Off is pressed.
*-----------------------------------------------------------------------------*/
- (IBAction)serial850Power:(id)sender
{
	if ([[SioController sharedInstance] getEnable850]) {
		[[SioController sharedInstance] setEnable850:NO];
		}
	else {
		[[SioController sharedInstance] setEnable850:YES];
		}
	[self updateInfo];
}


- (void)applicationTimedOut:(NSTimer*)theTimer
{
    [NSApp runModalForWindow: [endButton window]];
	[[NSApplication sharedApplication] terminate:self];
}

/*------------------------------------------------------------------------------
*  timedoutOK - This method handles the OK button press from the timedout window.
*-----------------------------------------------------------------------------*/
- (IBAction)timedoutOK:(id)sender
{
    [NSApp stopModal];
    [[endButton window] close];
}

- (IBAction)regValidate:(id)sender
{
    [NSApp stopModalWithCode:1];
    [[userNameField window] close];
}

- (IBAction)regCancel:(id)sender
{
    [NSApp stopModalWithCode:0];
    [[userNameField window] close];
}

- (IBAction) registration:(id)sender
{
	[userNameField setStringValue:[[Preferences sharedInstance] getUserName]];
	[userKeyField setStringValue:[[Preferences sharedInstance] getUserKey]];
    [NSApp beginSheet:[userNameField window]
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    // Sheet is up here.
    if ([NSApp runModalForWindow: [userNameField window]]) {
		[NSApp endSheet: [userNameField window]];
		[[userNameField window] orderOut: self];
		[[Preferences sharedInstance] transferUserStrings:[userNameField stringValue]:[userKeyField stringValue]];
		if (![[Preferences sharedInstance] checkRegistration]) {
			[[Preferences sharedInstance] transferUserStrings:@"":@""];
			[self displayError:@"Invalid Registration"];
			}
		else {
			[regTimer invalidate];
			}
		}
	else {
		 [NSApp endSheet: [userNameField window]];
		 [[userNameField window] orderOut: self];
		 }

}


@end
