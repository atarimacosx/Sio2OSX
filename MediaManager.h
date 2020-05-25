/* MediaManager.h - Window and menu support
   class to handle disk, cartridge, cassette,
   and executable file management and support 
   functions for the Macintosh OS X SDL port 
   of Atari800
   Mark Grebe <atarimac@cox.net>
   
   Based on the Preferences pane of the
   TextEdit application.

*/

#import <Cocoa/Cocoa.h>
#import "LedUpdate.h"
#import "CassInfoUpdate.h"
#import "CassStatusUpdate.h"

@interface MediaManager : NSObject
{
    IBOutlet id diskFmtCusBytesPulldown;
    IBOutlet id diskFmtCusSecField;
    IBOutlet id diskFmtDDBytesPulldown;
    IBOutlet id diskFmtInsertDrivePulldown;
    IBOutlet id diskFmtInsertNewButton;
    IBOutlet id diskFmtMatrix;
    IBOutlet id removeMenu;
    IBOutlet id removeD1Item;
    IBOutlet id removeD2Item;
    IBOutlet id removeD3Item;
    IBOutlet id removeD4Item;
    IBOutlet id removeD5Item;
    IBOutlet id removeD6Item;
    IBOutlet id removeD7Item;
    IBOutlet id removeD8Item;
	IBOutlet id selectPrinterPulldown;
	IBOutlet id selectPrinterMenu;
	IBOutlet id selectTextItem;
	IBOutlet id selectTextMenuItem;
	IBOutlet id selectAtari825Item;
	IBOutlet id selectAtari825MenuItem;
	IBOutlet id selectAtari1020Item;
	IBOutlet id selectAtari1020MenuItem;
	IBOutlet id selectEpsonItem;
	IBOutlet id selectEpsonMenuItem;
	IBOutlet id resetPrinterButton;
	IBOutlet id resetPrinterMenuItem;
    IBOutlet id errorButton;
    IBOutlet id errorField;
    IBOutlet id error2Button;
    IBOutlet id error2Field1;
    IBOutlet id error2Field2;
    IBOutlet id expiredButton;
	IBOutlet id d1DiskImageInsertButton;
	IBOutlet id d1DiskImageNameField;
	IBOutlet id d1DiskImageNumberField;
	IBOutlet id d1DiskImageSectorField;
	IBOutlet id d1DiskImagePowerButton;
	IBOutlet id d1DiskImageProtectButton;
	IBOutlet id d1DiskImageView;
	IBOutlet id d1DiskImageLockView;
	IBOutlet id d2DiskImageInsertButton;
	IBOutlet id d2DiskImageNameField;
	IBOutlet id d2DiskImageNumberField;
	IBOutlet id d2DiskImageSectorField;
	IBOutlet id d2DiskImagePowerButton;
	IBOutlet id d2DiskImageProtectButton;
	IBOutlet id d2DiskImageView;
	IBOutlet id d2DiskImageLockView;
	IBOutlet id d3DiskImageInsertButton;
	IBOutlet id d3DiskImageNameField;
	IBOutlet id d3DiskImageNumberField;
	IBOutlet id d3DiskImageSectorField;
	IBOutlet id d3DiskImagePowerButton;
	IBOutlet id d3DiskImageProtectButton;
	IBOutlet id d3DiskImageView;
	IBOutlet id d3DiskImageLockView;
	IBOutlet id d4DiskImageInsertButton;
	IBOutlet id d4DiskImageNameField;
	IBOutlet id d4DiskImageNumberField;
	IBOutlet id d4DiskImageSectorField;
	IBOutlet id d4DiskImagePowerButton;
	IBOutlet id d4DiskImageProtectButton;
	IBOutlet id d4DiskImageView;
	IBOutlet id d4DiskImageLockView;
	IBOutlet id d5DiskImageInsertButton;
	IBOutlet id d5DiskImageNameField;
	IBOutlet id d5DiskImageNumberField;
	IBOutlet id d5DiskImageSectorField;
	IBOutlet id d5DiskImagePowerButton;
	IBOutlet id d5DiskImageProtectButton;
	IBOutlet id d5DiskImageView;
	IBOutlet id d5DiskImageLockView;
	IBOutlet id d6DiskImageInsertButton;
	IBOutlet id d6DiskImageNameField;
	IBOutlet id d6DiskImageNumberField;
	IBOutlet id d6DiskImageSectorField;
	IBOutlet id d6DiskImagePowerButton;
	IBOutlet id d6DiskImageProtectButton;
	IBOutlet id d6DiskImageView;
	IBOutlet id d6DiskImageLockView;
	IBOutlet id d7DiskImageInsertButton;
	IBOutlet id d7DiskImageNameField;
	IBOutlet id d7DiskImageNumberField;
	IBOutlet id d7DiskImageSectorField;
	IBOutlet id d7DiskImagePowerButton;
	IBOutlet id d7DiskImageProtectButton;
	IBOutlet id d7DiskImageView;
	IBOutlet id d7DiskImageLockView;
	IBOutlet id d8DiskImageInsertButton;
	IBOutlet id d8DiskImageNameField;
	IBOutlet id d8DiskImageNumberField;
	IBOutlet id d8DiskImageSectorField;
	IBOutlet id d8DiskImagePowerButton;
	IBOutlet id d8DiskImageProtectButton;
	IBOutlet id d8DiskImageView;
	IBOutlet id d8DiskImageLockView;
	IBOutlet id printerImageView;
	IBOutlet id printerImageNameField;
	IBOutlet id printerPreviewButton;
	IBOutlet id printerPreviewItem;
	IBOutlet id speedField;
	IBOutlet id sioPortPulldown;
	IBOutlet id cassNameField;
	IBOutlet id cassImage;
	IBOutlet id cassProgressIndicator;
	IBOutlet id cassCurrentField;
	IBOutlet id cassMinField;
	IBOutlet id cassMaxField;
	IBOutlet id cassInsertButton;
	IBOutlet id cassPlayButton;
	IBOutlet id cassRewindButton;
	IBOutlet id cassFastForwardButton;
	IBOutlet id cassToStartButton;
	IBOutlet id cassStatusField;
	IBOutlet id endButton;
	IBOutlet id userNameField;
	IBOutlet id userKeyField;
	BOOL cassPresent;
	BOOL cassPlaying;
	IBOutlet id serial850PowerButton;
	IBOutlet id serial850ImageView;
}
+ (MediaManager *)sharedInstance;
- (void)displayError:(NSString *)errorMsg;
- (void)displayError2:(NSString *)errorMsg1:(NSString *)errorMsg2;
- (void)displayExpired;
- (void)displaySpeed:(NSNumber *) speed;
- (void)updateInfo;
- (NSString *) browseFileInDirectory:(NSString *)directory;
- (NSString *) browseFileTypeInDirectory:(NSString *)directory:(NSArray *) filetypes:(BOOL) directories;
- (NSString *) saveFileInDirectory:(NSString *)directory:(NSString *)type;
- (IBAction)cancelDisk:(id)sender;
- (IBAction)createDisk:(id)sender;
- (IBAction)diskInsert:(id)sender;
- (IBAction)diskRotate:(id)sender;
- (void)diskInsertFile:(NSString *)filename;
- (void)diskNoInsertFile:(NSString *)filename:(int) driveNo;
- (IBAction)diskInsertKey:(int)diskNum;
- (IBAction)diskRemove:(id)sender;
- (IBAction)diskRemoveKey:(int)diskNum;
- (IBAction)diskSetSave:(id)sender;
- (IBAction)diskSetLoad:(id)sender;
- (IBAction)diskSetLoadFile:(NSString *)filename;
- (IBAction)diskRemove:(id)sender;
- (IBAction)diskRemoveAll:(id)sender;
- (IBAction)miscUpdate:(id)sender;
- (IBAction)errorOK:(id)sender;
- (IBAction)error2OK:(id)sender;
- (IBAction)expiredOK:(id)sender;
- (IBAction)showCreatePanel:(id)sender;
- (void) mediaStatusWindowShow:(id)sender;
- (IBAction)diskStatusChange:(id)sender;
- (IBAction)diskStatusPower:(id)sender;
- (IBAction)diskStatusProtect:(id)sender;
- (void) updateMediaStatusWindow;
- (void) updateLed:(LedUpdate *) update;
- (void) statusLed:(int)diskNo:(int)on:(int)read;
- (void) sectorLed:(int)diskNo:(int)sectorNo:(int)on;
- (NSImageView *) getDiskImageView:(int)tag;
- (NSWindow *) window;
- (void)closeKeyWindow:(id)sender;
- (void)addModem:(char *)modemName:(BOOL)first;
- (void)selectModem:(int)modemIndex;
- (IBAction)modemChange:(id)sender;
- (IBAction)cassToStart:(id)sender;
- (IBAction)cassRewind:(id)sender;
- (IBAction)cassFastForward:(id)sender;
- (IBAction)cassPlay:(id)sender;
- (IBAction)cassInsert:(id)sender;
- (IBAction)cassDone:(id)sender;
- (IBAction)cassStart:(id)sender;
- (IBAction)serial850Power:(id)sender;
- (void)displayCassError:(NSString *)errorMsg;
- (void)updateCassetteInfo:(CassInfoUpdate *)update;
- (void)updateCassStatus:(CassStatusUpdate *)update;
- (void)notifyCassStopped;
- (void)applicationTimedOut:(NSTimer*)theTimer;
- (IBAction)timedoutOK:(id)sender;
- (IBAction) registration:(id)sender;
- (IBAction)regValidate:(id)sender;
- (IBAction)regCancel:(id)sender;
@end
