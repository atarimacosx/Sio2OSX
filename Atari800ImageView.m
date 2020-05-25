/* Atari800ImageView.m - ImageView class to
   support Drag and Drop to the disk drive image.
   For the Macintosh OS X SDL port 
   of Atari800
   Mark Grebe <atarimac@cox.net>
   
*/
#import "Atari800ImageView.h"
#import "Preferences.h"
#import "MediaManager.h"
#import "SioController.h"

extern int driveState[NUMBER_OF_ATARI_DRIVES];
extern char driveFilename[NUMBER_OF_ATARI_DRIVES][FILENAME_MAX];

extern NSImage *disketteImage;

/* Subclass of NSIMageView to allow for drag and drop and other specific functions  */

@implementation Atari800ImageView

static char fileToCopy[FILENAME_MAX];

/*------------------------------------------------------------------------------
*  init - Registers for a drag and drop to this window. 
*-----------------------------------------------------------------------------*/
-(id) init
{
	id me;
	
	me = [super init];
	
	[ self registerForDraggedTypes:[NSArray arrayWithObjects:
            NSFilenamesPboardType, nil]]; // Register for Drag and Drop
			
	return(me);
}

/*------------------------------------------------------------------------------
*  mouseDown - Start a drag from one of the drives. 
*-----------------------------------------------------------------------------*/
- (void)mouseDown:(NSEvent *)theEvent
{
   int tag;
   NSImage *dragImage;
   NSPoint dragPosition;
   
   tag = [self tag];

   if (tag < 8) {
		if (driveState[tag] == DRIVE_READ_ONLY || 
			driveState[tag] == DRIVE_READ_WRITE) {
			// Write data to the pasteboard
			NSArray *fileList = [NSArray arrayWithObjects:[NSString stringWithCString:driveFilename[tag]], nil];
			NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
			[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
				owner:nil];
			[pboard setPropertyList:fileList forType:NSFilenamesPboardType];

			// Start the drag operation
			dragImage = disketteImage;
			dragPosition = [self convertPoint:[theEvent locationInWindow]
							fromView:nil];
			dragPosition.x -= 32;
			[self dragImage:dragImage 
				at:dragPosition
				offset:NSZeroSize
				event:theEvent
				pasteboard:pboard
				source:self
				slideBack:YES];

			}
		}
}

/*------------------------------------------------------------------------------
*  draggingSourceOperationMaskForLocal - Only allow drags to other drives,
*     not to the finder or elsewhere. 
*-----------------------------------------------------------------------------*/
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (isLocal)
		return NSDragOperationCopy | NSDragOperationMove;
	else
		return NSDragOperationNone;
}

/*------------------------------------------------------------------------------
*  draggedImage - Runs when a image has been dropped on another disk instance. 
*-----------------------------------------------------------------------------*/
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	int driveNo = [self tag];
	
	if (operation & NSDragOperationCopy)
		{
		/* If there is no disk in the destination drive, it's the same as a move */
		if (strcmp("Off",fileToCopy) == 0 || strcmp("Empty",fileToCopy) == 0)
			[[MediaManager sharedInstance] diskRemoveKey:(driveNo + 1)];
		else
			[[MediaManager sharedInstance] 
				diskNoInsertFile:[NSString stringWithCString:fileToCopy]:driveNo];
		}
	else if (operation & NSDragOperationMove)
		{
		[[MediaManager sharedInstance] diskRemoveKey:(driveNo + 1)];
		}
}

/*------------------------------------------------------------------------------
*  draggingEntered - Checks for a valid drag and drop to this disk drive. 
*-----------------------------------------------------------------------------*/
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    int filecount;
    NSString *suffix;
	BOOL isDir;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        /* Check for copy being valid */
        if (sourceDragMask & NSDragOperationCopy ||
		    sourceDragMask & NSDragOperationMove) {
            /* Check here for valid file types */
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            
            filecount = [files count];

			if (filecount != 1)
				return NSDragOperationNone;
			
            suffix = [[files objectAtIndex:0] pathExtension];
			[[NSFileManager defaultManager] fileExistsAtPath:[files objectAtIndex:0] 
											isDirectory:&isDir];
			if ([self tag] < 8)
				if (!([suffix isEqualToString:@"atr"] ||
					  [suffix isEqualToString:@"ATR"] ||
					  [suffix isEqualToString:@"atx"] ||
					  [suffix isEqualToString:@"ATX"] ||
					  [suffix isEqualToString:@"pro"] ||
					  [suffix isEqualToString:@"PRO"] ||
					isDir) ||
 					[[files objectAtIndex:0] 
						isEqualToString:[NSString stringWithCString:driveFilename[[self tag]]]])
					return NSDragOperationNone;
            }
		if (sourceDragMask & NSDragOperationMove)
			return NSDragOperationMove; 
		if (sourceDragMask & NSDragOperationCopy)
			return NSDragOperationCopy; 
    }
    return NSDragOperationNone;
}

/*------------------------------------------------------------------------------
*  performDragOperation - Executes the actual drap and drop of a filename onto
*     a disk drive. 
*-----------------------------------------------------------------------------*/
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	int driveNo;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    /* Check for filenames type drag */
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
       NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
       
       /* Load the first file into the emulator */
	   if ([self tag] < 8) {
			driveNo = [self tag];
			if (sourceDragMask & NSDragOperationCopy) {
				strcpy(fileToCopy,driveFilename[driveNo]);
				}				
				
			[[MediaManager sharedInstance] diskNoInsertFile:[files objectAtIndex:0]:driveNo];
			} 
    }
    return YES;
}

@end
