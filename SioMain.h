/*   SDLMain.m - main entry point for our Cocoa-ized SDL app
       Initial Version: Darrell Walisser <dwaliss1@purdue.edu>
       Non-NIB-Code & other changes: Max Horn <max@quendi.de>

       Macintosh OS X SDL port of Atari800
       Mark Grebe <atarimac@cox.net>

    Feel free to customize this file to suit your needs
*/

#import <Cocoa/Cocoa.h>

@interface SioMain : NSObject
+(void)loadFile:(NSString *)filename;
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
@end
