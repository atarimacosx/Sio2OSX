/* Atari800MediaWindow.h - Window class external
   to the SDL library to support Drag and Drop
   to the Window. For the Macintosh OS X SDL port 
   of Atari800
   Mark Grebe <atarimac@cox.net>
   
   Based on the QuartzWindow.c implementation of
   libSDL.

*/
#import <Cocoa/Cocoa.h>
#import "Atari800MediaWindow.h"

extern int mediaStatusWindowOpen;

/* Subclass of NSWindow to allow for drag and drop and other specific functions  */
@implementation Atari800MediaWindow

/*------------------------------------------------------------------------------
*  init -
*-----------------------------------------------------------------------------*/
-(id) init
{
	id me;
	
	me = [super init];
	
	return(me);
}

/*------------------------------------------------------------------------------
*  init -
*-----------------------------------------------------------------------------*/
- (BOOL)windowShouldClose:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
	return YES;
}

/*------------------------------------------------------------------------------
*  selectAll - All window classes need this in this program, even if they have
*   nothing to select, since this method is send to the key window whenever
*   the Select All menu item is chosen.
*-----------------------------------------------------------------------------*/
- (void)selectAll:(id)sender
{
}

@end

