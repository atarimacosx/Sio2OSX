/* SioController.h - Window and menu support
   class to handle disk and printer management
   for Sio2OSX.
   Mark Grebe <atarimac@cox.net>
   
*/

#import <Cocoa/Cocoa.h>
#import "LedUpdate.h"
#import "CassStatusUpdate.h"
#import "CassInfoUpdate.h"
#import <termios.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <dirent.h>

#define DRIVE_POWER_OFF			0
#define DRIVE_NO_DISK			1
#define DRIVE_READ_ONLY			2
#define DRIVE_READ_WRITE		3
#define NUMBER_OF_ATARI_DRIVES  8
#define	ATR_SIGNATURE_1			0x96
#define	ATR_SIGNATURE_2			0x02
#define MAX_MODEMS				8

#define PORT_850_OFF					0
#define PORT_850_NET_MODE				1
#define PORT_850_SERIAL_MODE			2

#define NUM_850_PORTS			4

#define NUM_STORED_NAMES		20
#define STORED_ADDR_LEN			80

typedef struct ATR_Header {
	unsigned char signatureByte1;
	unsigned char signatureByte2;
	unsigned char sectorCountLow;
	unsigned char sectorCountHigh;
	unsigned char sectorSizeLow;
	unsigned char sectorSizeHigh;
	unsigned char highSectorCountLow;
	unsigned char highSectorCountHigh;
	unsigned char reserved[7];
	unsigned char writeProtect;
} ATR_HEADER;

typedef struct atrDiskInfo {
	BOOL directory;
	DIR *dir;
	FILE *file;
	FILE *writeFile;
	int dirCurrentFile;
	int sectorCount;
	int sectorSize;
	int bootSectorsType;
	int imageType;
	void *addedInfo;
	int io_success;
	} AtrDiskInfo;

/* stores dup sector information for PRO images */
#define MAX_PRO_PHANTOM_SEC  6

typedef struct tagpro_phantom_sec_info_t {
	int phantom_count;
	int sec_offset[MAX_PRO_PHANTOM_SEC];
	unsigned char sec_status[MAX_PRO_PHANTOM_SEC];
} pro_phantom_sec_info_t;

typedef struct tagpro_additional_info_t {
	int max_sector;
	unsigned char *count;
	pro_phantom_sec_info_t *phantom;
	unsigned char sec_stat_buff[4];
} pro_additional_info_t;

#define MAX_VAPI_PHANTOM_SEC  		18
#define VAPI_BYTES_PER_TRACK        26042.0 
#define VAPI_USEC_PER_ROT			208242   /* 0.55873023 usec/cycle */
#define VAPI_USEC_PER_TRACK_STEP 	19951 /*70937*/
#define VAPI_USEC_HEAD_SETTLE		39186
#define VAPI_USEC_TRACK_READ_DELTA	0 /* 797 */
#define VAPI_USEC_CMD_ACK_TRANS 	1776
#define VAPI_USEC_SECTOR_READ		15738
#define VAPI_USEC_MISSING_SECTOR	(2*VAPI_USEC_PER_ROT + 8075)
#define VAPI_USEC_BAD_SECTOR_NUM	850
#define VAPI_USEC_ACK_WAIT			250

/* stores dup sector information for VAPI images */
typedef struct tagvapi_sec_info_t {
	unsigned int sec_count;
	unsigned int sec_offset[MAX_VAPI_PHANTOM_SEC];
	unsigned char sec_status[MAX_VAPI_PHANTOM_SEC];
	unsigned int sec_rot_pos[MAX_VAPI_PHANTOM_SEC];
} vapi_sec_info_t;

typedef struct tagvapi_additional_info_t {
	vapi_sec_info_t *sectors;
	int sec_stat_buff[4];
	int vapi_delay_time;
} vapi_additional_info_t;

/* VAPI Format Header */
typedef struct tagvapi_file_header_t {
	unsigned char signature[4];
	unsigned char majorver;
	unsigned char minorver;
	unsigned char reserved1[22];
	unsigned char startdata[4];
	unsigned char reserved[16];
} vapi_file_header_t;

typedef struct tagvapi_track_header_t {
	unsigned char  next[4];
	unsigned char  type[2];
	unsigned char  reserved1[2];
	unsigned char  tracknum;
	unsigned char  reserved2;
	unsigned char  sectorcnt[2];
	unsigned char  reserved3[8];
	unsigned char  startdata[4];
	unsigned char  reserved4[8];
} vapi_track_header_t;

typedef struct tagvapi_sector_list_header_t {
	unsigned char  sizelist[4];
	unsigned char  type;
	unsigned char  reserved[3];
} vapi_sector_list_header_t;

typedef struct tagvapi_sector_header_t {
	unsigned char  sectornum;
	unsigned char  sectorstatus;
	unsigned char  sectorpos[2];
	unsigned char  startdata[4];
} vapi_sector_header_t;

#define VAPI_32(x) (x[0] + (x[1] << 8) + (x[2] << 16) + (x[3] << 24))
#define VAPI_16(x) (x[0] + (x[1] << 8))

#define IMAGE_TYPE_ATR  1
#define IMAGE_TYPE_PRO  2
#define IMAGE_TYPE_VAPI 3

typedef struct SIO_PREF {
	int ignoreAtrWriteProtect;
	int maxSerialSpeed; 
    int sioHWType;
	int currPrinter;
	int delayFactor;
	char printDir[FILENAME_MAX]; 
    char diskImageDir[FILENAME_MAX];
    char cassImageDir[FILENAME_MAX];
    char diskSetDir[FILENAME_MAX];
    char serialPort[FILENAME_MAX];
	char printerCommand[256];
	char netServerBusyMessage[256];
	char netServerNotReadyMessage[256];
	BOOL netServerEnable;
	int netServerNetPort;
	BOOL modemEcho;
	UInt8 modemEscapeCharacter;
	BOOL modemAutoAnswer;
	char storedNameAddr[NUM_STORED_NAMES][STORED_ADDR_LEN];
	UInt16 storedNamePort[NUM_STORED_NAMES];
	int port850Mode[NUM_850_PORTS];
	char port850Port[NUM_850_PORTS][FILENAME_MAX];
	BOOL enable850;
} SIO_PREF;

typedef struct SIO_PREF_RET {
	int currPrinter;
    char serialPort[FILENAME_MAX];
	char storedNameAddr[NUM_STORED_NAMES][STORED_ADDR_LEN];
	UInt16 storedNamePort[NUM_STORED_NAMES];
	BOOL enable850;
} SIO_PREF_RET;

@interface SioController : NSObject
{
    NSLock *mutex;
    int fileDescriptor;
    struct termios gOriginalTTYAttrs;
    AtrDiskInfo *diskInfo[NUMBER_OF_ATARI_DRIVES];
    int diskReadWrite[NUMBER_OF_ATARI_DRIVES];
    int diskWriteProtect[NUMBER_OF_ATARI_DRIVES];
    int maxSpeed;
    int currentSpeed;
	int ledPersistence[NUMBER_OF_ATARI_DRIVES];
	int ignoreAtrWriteProtect;
	int sioHWType;
	char serialPort[FILENAME_MAX];
	FILE *printerFile;
	char textFileName[FILENAME_MAX];
	char printerCommand[256];
	BOOL offline;
    char bsdPaths[MAX_MODEMS][FILENAME_MAX];
    char modemNames[MAX_MODEMS][FILENAME_MAX];
	int modemCount;
	int modemIndex;
	BOOL modemChanged;
	int currPort;
	int delayFactor;
	int diskServerPause;
	BOOL diskServerStarted;
	BOOL diskServerExited;
	FILE *cassFile;
	int numCassBlocks;
	int currCassBlock;
	BOOL cassShouldStop;
	LedUpdate *onUpdate;
	LedUpdate *offUpdate;
	CassStatusUpdate *cassStatusUpdate;
	CassInfoUpdate *cassInfoUpdate;
	BOOL concurrentMode;
	int enable850;
	int baud850[NUM_850_PORTS];
	int bits850[NUM_850_PORTS];
	int stopBits850[NUM_850_PORTS];
	BOOL dsrHandshake850[NUM_850_PORTS];
	BOOL ctsHandshake850[NUM_850_PORTS];
	int port850Mode[NUM_850_PORTS];
	char port850Port[NUM_850_PORTS][FILENAME_MAX];
	int port850fd[NUM_850_PORTS];
	BOOL dsrLast[NUM_850_PORTS];
	BOOL ctsLast[NUM_850_PORTS];
	BOOL crxLast[NUM_850_PORTS];
	char netServerBusyMessage[256];
	char netServerNotReadyMessage[256];
	BOOL netATMode;
	BOOL netCarrierDetected;
	BOOL netTerminalReady;
	int netServerPort;
	int netServerNetPort;
	BOOL netServerEnable;
	BOOL atariBbsConnected;
	BOOL atariBbsClientConnected;
	int modemCharCount;
	int concurrentPort;
	int netServerFd;
	BOOL netServerStarted;
	BOOL netServerExit;
	BOOL netServerExited;
	BOOL storedNameInUse[NUM_STORED_NAMES];
	char storedNameAddr[NUM_STORED_NAMES][STORED_ADDR_LEN];
	UInt16 storedNamePort[NUM_STORED_NAMES];
	BOOL modemEcho;
	UInt8 modemEscapeCharacter;
	BOOL modemAutoAnswer;
	BOOL modemAtascii;
}
+ (SioController *)sharedInstance;
- (void) init850State;
- (void) updatePreferences;
- (kern_return_t) findModems:(io_iterator_t *) matchingServices;
- (int) getModemPaths:(io_iterator_t )serialPortIterator; 
- (int) openSerialPort:(const char *)bbsdPath:(int)initialBaud;
- (void) closeSerialPort: (int) descriptor: (BOOL) reset;
- (void) setSerialPortSpeed: (int) fileDescriptor : (int) speed;
- (UInt8) checksum: (UInt8 *) buffer: (UInt32) count;
- (void) writeBlocks:(UInt8 *) buffer: (int) count: (int) blockSize;
- (void) processDiskWriteCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskHappyWriteCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskReadCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskHappyReadCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskStatusCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskHappyConfigCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskGetConfigCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskFormatCommand:(int) unit: (UInt8 *) cmd;
- (void) processDiskFormatEDCommand:(int) unit: (UInt8 *) cmd;
- (void) processCommand:(UInt8 *) cmd;
- (void) outputPrinterByte:(UInt8) byte;
- (IBAction) onResetPrinter:(id)sender;
- (void) printerOffline:(BOOL)isOffline;
- (void) processPrinterWriteCommand:(int) unit: (UInt8 *) cmd;
- (void) processPrinterStatusCommand:(int) unit: (UInt8 *) cmd;
- (void) process850WriteCommand:(int) unit: (UInt8 *) cmd;
- (void) process850StatusCommand:(int) unit: (UInt8 *) cmd;
- (void) process850ConcurrentCommand:(int) unit: (UInt8 *) cmd;
- (void) process850BaudCommand:(int) unit: (UInt8 *) cmd;
- (void) process850AttributesCommand:(int) unit: (UInt8 *) cmd;
- (void) process850PollCommand:(int) unit: (UInt8 *) cmd;
- (void) process850BootCommand:(int) unit: (UInt8 *) cmd;
- (void) process850HandlerCommand:(int) unit: (UInt8 *) cmd;
- (BOOL) isExpired;
- (void) runDiskServer;
- (void) runNetServer;
- (char *) modemParseNamePort:(char *)string:(UInt16 *)port;
- (BOOL) modemDial:(char *)address:(UInt16)port;
- (void) modemATModeProcess:(unsigned char) c;
- (void) modemSendOK;
- (void) modemSendNoCarrier;
- (void) modemSendConnect;
- (void) modemSendString:(char *)string;
- (void) modemDisplayStored;
- (void) modemSendHelp;
- (BOOL) getEnable850;
- (void) setEnable850:(BOOL)enable;
- (void) start;
- (void) startNetServer;
- (void) startSerialPorts;
- (void) stopNetServer;
- (void) rescanModems:(BOOL)attach;
- (void)modemChange:(int)index;
- (UInt32) getUpTimeUsec;
- (double) getUpTime;
- (void) microDelay:(UInt32) us;
- (int) mount:(int) diskno: (const char *)filename: (int) b_open_readonly;
- (int) mountVAPI:(int) diskno:(int) file_length;
- (int) mountPRO:(int) diskno:(int) file_length:(ATR_HEADER *) header;
- (void) dismount:(int) diskno;
- (void) turnDriveOff:(int) diskno;
- (int) rotateDisks;
- (int) readSector:(int) drive:(int) sector:(UInt8 *) buffer;
- (int) readDirSector:(int) drive:(int) sector:(UInt8 *) buffer;
- (struct dirent *) readDirEntry:(DIR *)directory;
- (int) writeSector:(int) drive:(int) sector:(UInt8 *) buffer;
- (int) writeDirSector:(int) drive:(int) sector:(UInt8 *) buffer;
- (void) zeroSectors:(int) drive;
- (int) seekSector:(AtrDiskInfo *) info:(int) sector;
- (void) macNameToAtariName:(char *) mac:(char *) atari;
- (void) filterAtariName:(char*) name;
- (void) atariNameToMacName:(char *) mac:(char *) atari;
- (void) returnPrefs;
- (void) pauseDiskServer:(BOOL) pause;
- (int) cassMount:(const char *)filename;
- (void) cassUnmount;
- (void) runCassServer;
- (void) stopCassette;
- (void) adjustCassBlock:(int) direction;
@end



