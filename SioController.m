#import <stdio.h>
#import <string.h>
#import <unistd.h>
#import <fcntl.h>
#import <errno.h>
#import <paths.h>
#import <sysexits.h>
#import <sys/param.h>
#import <sys/ioctl.h>
#import <sys/select.h>
#import <sys/types.h> 
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>

#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "MediaManager.h"
#import "PrintOutputController.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#import <IOKit/IOBSD.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach.h>

#import "SioController.h"

#define ACK_WAIT		(delayFactor ? (85  + ( 1000 * delayFactor-1)) : 0)
#define COMPLETE_WAIT	(delayFactor ? (255 + ( 1000 * delayFactor)) : 0)
#define POST_COMP_WAIT	(delayFactor ? (425 + ( 100 * delayFactor)) : 0)
#define LED_PERSIST		10000
#define XMIT_BLOCK_SIZE	10

#undef  DEBUG_PRO
#undef  DEBUG_VAPI

#define DEVC_SECTOR_START_WITH_ZERO         0x80
#define DEVC_FIRST_3_SECTORS_FULL_SIZE      0x40
#define DEVC_DEVICE_ACTIVATED               0x02
#define DEVC_FOURTY_TRACK_ON_EIGHTY_TRACK   0x01

typedef struct driveConfigMsg
{
	UInt8 trackCount;          
	UInt8 stepRate;    
	UInt8 sectorCountHi;  
	UInt8 sectorCountLo;  
	UInt8 headCount;
	UInt8 formatId;
	UInt8 bytesPerSectorHi;
	UInt8 bytesPerSectorLo;
    UInt8 bitfield;
	UInt8 unused[3];
	UInt8 checksum;
} DRIVE_CONFIG_MSG;


#define DEVS_ENHANCED_DENSITY           0x80
#define DEVS_DOUBLE_DENSITY             0x20
#define DEVS_MOTOR_ON                   0x10
#define DEVS_WRITE_PROTECT              0x08
#define DEVS_WRITE_ERROR                0x04
#define DEVS_DATA_FRAME_ERROR           0x02
#define DEVS_COMMAND_FRAME_ERROR        0x01

#define DEVS_HW_NOT_READY               0x80
#define DEVS_HW_WRITE_PROTECTED         0x40
#define DEVS_HW_RECORD_TYPE             0x20
#define DEVS_HW_RECORD_NOT_FOUND        0x10
#define DEVS_HW_CRC_ERROR               0x08
#define DEVS_HW_DATA_LOST_OR_TRACK0     0x04
#define DEVS_HW_DATA_REQUEST_OR_INDEX   0x02
#define DEVS_CONTROLLER_BUSY            0x01

// TBD need to shut down Cassette server if Serial cable is removed

typedef struct driveStatusMsg
{
    UInt8 deviceStatus;
    UInt8 hwStatus;
	UInt8 timeout;
	UInt8 unused;
	UInt8 checksum;
} DRIVE_STATUS_MSG;

typedef struct a850StatusMsg
{
    UInt8 errors;
    UInt8 lineState;
	UInt8 checksum;
} A850_STATUS_MSG;

typedef struct concurrentRespMsg
{
    UInt8 audf1;
    UInt8 audctl1;
    UInt8 audf2;
    UInt8 audctl2;
    UInt8 audf3;
    UInt8 audctl3;
    UInt8 audf4;
    UInt8 audctl4;
    UInt8 audioctl;
	UInt8 checksum;
} CONCURRENT_RESP_MSG;

typedef struct a850PollResponse
{
    UInt8 msg[12];
	UInt8 checksum;
} A850_POLL_RESPONSE;

typedef struct cassetteHeader
{
    UInt8 recordType[4];
    UInt8 lengthLo;
	UInt8 lengthHi;
	UInt8 aux1;
	UInt8 aux2;
} CASSETTE_HEADER;

typedef struct atariDirEnt {
	UInt8 flags;
	UInt8 secCountLow;
	UInt8 secCountHigh;
	UInt8 startSecLow;
	UInt8 startSecHigh;
	char name[11];
} ATARI_DIR_ENT;

static char sectorMap[128] = {
	0x02,0xc3,0x02,0x83,0x02,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xfe,0x01,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};

#undef OLD_850ROM
#ifdef OLD_850ROM
// Note, there is an extra byte to store checksum
static UInt8 bootHandler850[] = 
{
	0x00,0x03,0x00,0x05,0xc0,0xe4,0xa9,0x50,0x8d,0x00,0x03,0xad,0xe7,0x02,0x8d,0x04,
	0x03,0xad,0xe8,0x02,0x8d,0x05,0x03,0xa9,0xb4,0x8d,0x08,0x03,0xa9,0x05,0x8d,0x09,
	0x03,0x8d,0x06,0x03,0xa9,0x01,0x8d,0x01,0x03,0xa9,0x40,0x8d,0x03,0x03,0xa9,0x26,
	0x8d,0x02,0x03,0x20,0x59,0xe4,0x10,0x02,0x38,0x60,0xa2,0x88,0x18,0xbd,0xa7,0x05,
	0x6d,0xe7,0x02,0x9d,0xa7,0x05,0xbd,0xa8,0x05,0x6d,0xe8,0x02,0x9d,0xa8,0x05,0xca,
	0xca,0xd0,0xe9,0xa0,0x00,0x8c,0x59,0x06,0x20,0x44,0x06,0xb1,0x80,0xaa,0xc8,0xb1,
	0x80,0x48,0xbd,0xb2,0x05,0x91,0x80,0x88,0xbd,0xb1,0x05,0x91,0x80,0x68,0x20,0x31,
	0x06,0xd0,0xe8,0xa2,0x02,0x20,0x44,0x06,0xb1,0x80,0xaa,0xbd,0xb1,0x05,0x91,0x80,
	0xae,0x59,0x06,0xee,0x59,0x06,0xbd,0x4f,0x06,0x20,0x31,0x06,0xd0,0xea,0xa2,0x04,
	0x20,0x44,0x06,0xa5,0x0c,0x91,0x80,0xc8,0xa5,0x0d,0x91,0x80,0xad,0x2b,0x06,0x85,
	0x0c,0xad,0x2c,0x06,0x85,0x0d,0xa2,0x0c,0x4c,0xe9,0x03,0xb2,0x05,0xd5,0x04,0xfc,
	0x03,0x66,0x05,0xbf,0x06,0xb7,0x06,0xbb,0x06,0xe0,0x06,0xc7,0x04,0xe5,0x04,0xdf,
	0x06,0xdd,0x06,0xde,0x06,0xd7,0x06,0xd6,0x06,0x7e,0x05,0xe1,0x06,0xc3,0x06,0xc2,
	0x00,0x0d,0x05,0xef,0x04,0x1f,0x05,0x34,0x06,0x16,0x05,0x38,0x05,0xd2,0x06,0xd3,
	0x06,0xd4,0x06,0xd5,0x06,0x48,0x05,0xc7,0x06,0xd3,0x06,0xa5,0x05,0xa4,0x05,0xce,
	0x06,0xcc,0x06,0xcf,0x06,0xcd,0x06,0x59,0x05,0xb3,0x06,0xdf,0x06,0xae,0x05,0x0f,
	0x01,0xfa,0x04,0x72,0x05,0x23,0x02,0x94,0x05,0x26,0x04,0x39,0x00,0xd0,0x06,0xd1,
	0x06,0x29,0x05,0xff,0xff,0x1c,0x00,0x5b,0x01,0x67,0x00,0x0c,0x02,0x56,0x02,0x70,
	0x03,0x95,0x03,0x89,0x03,0x9c,0x03,0x71,0x02,0x86,0x04,0xb3,0x03,0xb4,0x05,0xfe,
	0x03,0x8d,0x5a,0x06,0x38,0xa5,0x80,0xed,0x5a,0x06,0x85,0x80,0xb0,0x02,0xc6,0x81,
	0xad,0x5a,0x06,0x60,0xbd,0xab,0x05,0x85,0x80,0xbd,0xac,0x05,0x85,0x81,0x60,0x0a,
	0xf9,0x05,0x85,0x0b,0x48,0x05,0x37,0x05,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00};

// Note, there is an extra byte to store checksum
static UInt8 deviceHandler850[] = 
{
    0x20,0x00,0x00,0xbd,0x02,0x03,0x10,0x03,0xa0,0x96,0x60,0xa5,0x2a,0x09,0x80,0x9d,
	0x02,0x0c,0xa9,0x00,0x9d,0x04,0x05,0x9d,0x06,0x03,0xa0,0x01,0x60,0x20,0x00,0x06,
	0xec,0x08,0x03,0xf0,0x0c,0xbd,0x04,0x05,0xf0,0x2f,0x20,0x0a,0x05,0xa0,0x80,0xd0,
	0x2d,0x20,0x0c,0x07,0xad,0x0e,0x03,0xf0,0xf8,0x78,0xad,0x10,0x06,0x8d,0x16,0x02,
	0xad,0x12,0x06,0x8d,0x17,0x02,0xa2,0x05,0xbd,0x14,0x08,0x9d,0x0a,0x02,0xca,0x10,
	0xf7,0x58,0xad,0x08,0x0a,0x8e,0x08,0x03,0xaa,0xa0,0x00,0x8c,0x0a,0x03,0xa9,0x00,
	0x9d,0x02,0x0b,0xa9,0x57,0x4c,0x18,0x05,0xbc,0x41,0x03,0xc0,0x05,0x90,0x03,0xa0,
	0x82,0x60,0x8d,0x1a,0x0d,0xb9,0x02,0x03,0x29,0x08,0xd0,0x03,0xa0,0x87,0x60,0x98,
	0xaa,0x86,0x21,0xbd,0x1c,0x0e,0x29,0x30,0xa8,0xf0,0x04,0xc9,0x20,0xb0,0x36,0xad,
	0x1a,0x0c,0xc9,0x9b,0xd0,0x19,0xbd,0x1c,0x07,0x29,0x40,0xf0,0x0e,0xa9,0x0d,0x20,
	0x1e,0x09,0x10,0x01,0x60,0xa6,0x21,0xa9,0x0a,0xd0,0x17,0xa9,0x0d,0xd0,0x13,0xc0,
	0x10,0xf0,0x04,0x29,0x7f,0x10,0x0b,0xc9,0x20,0x90,0x04,0xc9,0x7d,0x90,0x03,0xa0,
	0x01,0x60,0x8d,0x1a,0x23,0xbd,0x1c,0x03,0x29,0x03,0xf0,0x1e,0xc9,0x03,0xf0,0x0e,
	0xa8,0x20,0x20,0x0c,0x20,0x22,0x03,0x98,0x29,0x02,0xf0,0x0c,0x90,0x0c,0xad,0x1a,
	0x0a,0x09,0x80,0x8d,0x1a,0x05,0x30,0x02,0x90,0xf4,0xa6,0x21,0xec,0x08,0x09,0xf0,
	0x2d,0x20,0x24,0x05,0x7d,0x04,0x03,0xa8,0xad,0x1a,0x04,0x99,0x26,0x03,0xfe,0x04,
	0x03,0xc9,0x0d,0xf0,0x0a,0xa9,0x20,0xdd,0x04,0x09,0xf0,0x03,0xa0,0x01,0x60,0x20,
	0x0a,0x08,0xa0,0x80,0xa9,0x00,0x9d,0x04,0x07,0xa9,0x57,0x4c,0x18,0x05,0x20,0x0c,
	0x03,0xad,0x16,0x03,0xc9,0x1f,0xb0,0xf6,0x20,0x24,0x07,0x78,0x7d,0x04,0x04,0xa8,
	0xad,0x1a,0x04,0x99,0x26,0x03,0xbc,0x04,0x03,0x20,0x28,0x03,0x9d,0x04,0x03,0xee,
	0x16,0x03,0xa5,0x10,0xbc,0x1c,0x05,0x30,0x04,0x09,0x18,0xd0,0x02,0x09,0x08,0x85,
	0x10,0x8d,0x0e,0xd2,0xa0,0x00,0x8c,0x0e,0x12,0x58,0xc8,0x60,0x20,0x00,0x06,0xbd,
	0x02,0x03,0x29,0x04,0xd0,0x03,0xa0,0x83,0x60,0xec,0x08,0x0a,0xf0,0x03,0xa0,0x9a,
	0x60,0xa0,0x04,0xa2,0x06,0x58,0x20,0x0c,0x0d,0x78,0x20,0x2a,0x04,0xf0,0xf6,0xa5,
	0x2c,0x48,0xa5,0x2d,0x48,0xad,0x2c,0x0b,0x85,0x2c,0xad,0x2e,0x05,0x85,0x2d,0xa0,
	0x00,0xb1,0x2c,0x8d,0x1a,0x09,0x68,0x85,0x2d,0x68,0x85,0x2c,0x38,0xad,0x30,0x0a,
	0xe9,0x01,0x8d,0x30,0x05,0xb0,0x03,0xce,0x32,0x05,0xa2,0x02,0x20,0x34,0x05,0x58,
	0xa6,0x21,0xbd,0x1c,0x06,0x4a,0x4a,0x29,0x03,0xf0,0x23,0xc9,0x03,0xf0,0x1c,0xa8,
	0xad,0x1a,0x0e,0x20,0x22,0x03,0x98,0x29,0x02,0xf0,0x0e,0x90,0x0e,0xa6,0x21,0xa9,
	0x20,0x1d,0x06,0x0e,0x9d,0x06,0x03,0xd0,0x02,0x90,0xf2,0x20,0x20,0x07,0xa6,0x21,
	0xbd,0x1c,0x05,0x29,0x30,0xc9,0x20,0x90,0x06,0xad,0x1a,0x09,0xa0,0x01,0x60,0xa8,
	0x20,0x20,0x07,0xc9,0x0d,0xd0,0x04,0xa9,0x9b,0xd0,0x0f,0xc0,0x00,0xf0,0x0b,0xc9,
	0x20,0x90,0x04,0xc9,0x7d,0x90,0x03,0xbd,0x36,0x17,0xa0,0x01,0x60,0x20,0x00,0x06,
	0xbd,0x06,0x03,0x8d,0xea,0x02,0x8d,0x1a,0x06,0xa9,0x00,0x9d,0x06,0x05,0xec,0x08,
	0x03,0xf0,0x27,0xa9,0xea,0x8d,0x04,0x03,0xa9,0x02,0x8d,0x05,0x03,0xa9,0x02,0x8d,
	0x08,0x03,0xa9,0x00,0x8d,0x09,0x03,0xa0,0x40,0xa9,0x53,0x20,0x18,0x1d,0xad,0x1a,
	0x03,0x0d,0xea,0x02,0x8d,0xea,0x02,0xc0,0x00,0x60,0xa0,0x03,0xb9,0x38,0x0e,0x99,
	0xea,0x02,0x88,0xd0,0xf7,0xc8,0x60,0x20,0x00,0x0b,0xa5,0x22,0x29,0x0f,0xc9,0x09,
	0xb0,0x0d,0xa8,0x4a,0xb0,0x09,0xb9,0x3a,0x0f,0x48,0xb9,0x3c,0x04,0x48,0x60,0xa0,
	0x84,0x60,0xbd,0x02,0x08,0x30,0x03,0xa0,0x85,0x60,0x2c,0x08,0x08,0x70,0x03,0xa0,
	0x99,0x60,0x4a,0xb0,0x03,0xa0,0x97,0x60,0x4a,0x4a,0x90,0x4f,0xa5,0x2a,0xf0,0x20,
	0xa5,0x28,0x05,0x29,0xf0,0x1a,0x18,0xa5,0x24,0x8d,0x3e,0x1f,0x65,0x28,0x8d,0x40,
	0x05,0xa5,0x25,0x8d,0x42,0x05,0x65,0x29,0x8d,0x44,0x05,0x90,0x23,0xa0,0x98,0x60,
	0x20,0x24,0x08,0x69,0x7c,0x8d,0x3e,0x05,0xa9,0x7d,0x69,0x00,0x8d,0x42,0x07,0x18,
	0xad,0x3e,0x04,0x69,0x1f,0x8d,0x40,0x05,0xad,0x42,0x03,0x69,0x00,0x8d,0x44,0x05,
	0xa0,0x06,0x20,0x46,0x05,0x88,0x88,0xc0,0x02,0xd0,0xf7,0xa6,0x21,0xbd,0x02,0x0b,
	0x29,0x08,0xf0,0x08,0xa9,0x00,0x9d,0x04,0x09,0x9d,0x48,0x03,0x8d,0x09,0x03,0xa9,
	0x14,0x8d,0x04,0x03,0xa9,0x15,0x8d,0x05,0x03,0xbd,0x02,0x10,0x8d,0x0a,0x03,0xa9,
	0x09,0x8d,0x08,0x03,0xa0,0x40,0xa9,0x58,0x20,0x18,0x0f,0x10,0x01,0x60,0x78,0xa9,
	0x73,0x8d,0x0f,0xd2,0xad,0x4a,0x0c,0x8d,0x08,0xd2,0xa0,0x07,0xb9,0x14,0x08,0x99,
	0x00,0xd2,0x88,0x10,0xf7,0xa2,0x05,0xbd,0x0a,0x02,0x9d,0x14,0x0e,0xbd,0x4c,0x03,
	0x9d,0x0a,0x02,0xca,0x10,0xf1,0xad,0x16,0x02,0x8d,0x10,0x0c,0xa9,0x7e,0x8d,0x16,
	0x02,0xad,0x17,0x02,0x8d,0x12,0x0b,0xa9,0x7f,0x8d,0x17,0x02,0xa9,0x00,0xa0,0x02,
	0x99,0x30,0x0c,0x88,0x10,0xfa,0xa6,0x21,0xbd,0x02,0x08,0x29,0x04,0xf0,0x09,0xa5,
	0x10,0x09,0x20,0x8d,0x0e,0xd2,0x85,0x10,0x8e,0x08,0x10,0x8e,0x0e,0x03,0x58,0xd0,
	0x36,0xbd,0x02,0x06,0x30,0x03,0xa0,0x85,0x60,0x29,0x08,0xd0,0x03,0xa0,0x87,0x60,
	0xbd,0x04,0x0f,0xf0,0x22,0x20,0x4e,0x05,0xd0,0x1f,0xa0,0x7f,0x20,0x50,0x07,0xa9,
	0x42,0x20,0x52,0x05,0xd0,0x13,0xa9,0x41,0x20,0x52,0x07,0xd0,0x0c,0xa0,0x80,0x20,
	0x50,0x07,0xa5,0x2b,0x9d,0x36,0x05,0xa0,0x01,0xa6,0x21,0xbd,0x02,0x07,0x85,0x2a,
	0xc0,0x00,0x60,0xa9,0x00,0xa2,0x00,0xdd,0x1a,0x03,0xf0,0x08,0xe8,0xe8,0xe8,0xe0,
	0x20,0x90,0xf4,0x60,0xa9,0x52,0x8d,0x08,0x1b,0x9d,0x1a,0x03,0xa9,0x56,0x9d,0x1b,
	0x03,0xa9,0x57,0x9d,0x1c,0x03,0x18,0xad,0xe7,0x02,0x69,0xe2,0x8d,0xe7,0x02,0xad,
	0xe8,0x02,0x69,0x06,0x8d,0xe8,0x02,0xa2,0x04,0xa9,0x00,0x9d,0x02,0x25,0xca,0xd0,
	0xfa,0xe8,0x20,0x54,0x07,0x18,0xa5,0x08,0xd0,0x01,0x60,0x4c,0xff,0xff,0x2c,0x0e,
	0xd2,0x10,0x03,0x6c,0x10,0x11,0x48,0x8a,0x48,0x98,0x48,0xae,0x08,0x08,0xbd,0x02,
	0x03,0x48,0x8a,0x48,0x20,0x5a,0x06,0x68,0xaa,0x68,0x9d,0x02,0x06,0xa9,0x00,0x85,
	0x11,0x9d,0x04,0x07,0xf0,0x5a,0xd8,0x8a,0x48,0x98,0x48,0xa5,0x2c,0x48,0xa5,0x2d,
	0x48,0xad,0x5c,0x10,0x85,0x2c,0xad,0x5e,0x05,0x85,0x2d,0xad,0x0d,0xd2,0xa0,0x00,
	0x91,0x2c,0xad,0x0f,0xd2,0x8d,0x0a,0xd2,0x49,0xff,0x29,0xc0,0xae,0x08,0x16,0x1d,
	0x06,0x03,0x9d,0x06,0x03,0x68,0x85,0x2d,0x68,0x85,0x2c,0xa2,0x00,0x20,0x34,0x0b,
	0xa0,0x04,0xa2,0x06,0x20,0x2a,0x07,0xd0,0x12,0xa2,0x02,0x20,0x34,0x07,0xae,0x08,
	0x03,0xbd,0x06,0x03,0x09,0x10,0x9d,0x06,0x05,0xd0,0x05,0xa2,0x04,0x20,0x60,0x07,
	0x68,0xa8,0x68,0xaa,0x68,0x40,0xd8,0x8a,0x48,0x98,0x48,0xae,0x08,0x0e,0xbd,0x04,
	0x03,0xdd,0x48,0x03,0xd0,0x0f,0x8e,0x0e,0x05,0xa5,0x10,0x29,0xe7,0x85,0x10,0x8d,
	0x0e,0xd2,0x18,0x90,0xdb,0x20,0x24,0x0f,0x7d,0x48,0x03,0xa8,0xb9,0x26,0x04,0x8d,
	0x0d,0xd2,0xbc,0x48,0x06,0x20,0x28,0x03,0x9d,0x48,0x03,0xce,0x16,0x03,0xad,0x0e,
	0xd2,0x29,0x08,0xf0,0xf9,0xd0,0xb9,0x20,0x24,0x0c,0x69,0x26,0x8d,0x04,0x03,0xa9,
	0x00,0x8d,0x09,0x03,0x69,0x27,0x8d,0x05,0x03,0xbd,0x04,0x12,0x8d,0x0a,0x03,0xa9,
	0x40,0x8d,0x08,0x03,0x60,0xa5,0x11,0xf0,0x01,0x60,0x68,0x68,0xa0,0x80,0x60,0xa2,
	0x00,0x4a,0x90,0x01,0xe8,0xd0,0xfa,0x8a,0x4a,0x60,0x98,0x3d,0x1c,0x22,0x9d,0x1c,
	0x03,0x98,0x49,0xff,0x25,0x2a,0x1d,0x1c,0x08,0x9d,0x1c,0x03,0x60,0xad,0x1a,0x04,
	0x29,0x7f,0x8d,0x1a,0x05,0x60,0xc8,0x98,0xc9,0x20,0x90,0x02,0xa9,0x00,0x60,0x8a,
	0x38,0xe9,0x01,0x0a,0x0a,0x0a,0x0a,0x0a,0x60,0x18,0xbd,0x5c,0x18,0x69,0x01,0x9d,
	0x5c,0x05,0x90,0x03,0xfe,0x5e,0x05,0x60,0xb9,0x44,0x04,0xdd,0x44,0x03,0xf0,0x01,
	0x60,0xb9,0x40,0x06,0xdd,0x40,0x03,0x60,0x20,0x60,0x04,0x8a,0x18,0x69,0x04,0xa8,
	0xa2,0x00,0x20,0x2a,0x0a,0xf0,0x0e,0x90,0x0c,0xad,0x3e,0x07,0x99,0x40,0x03,0xad,
	0x42,0x03,0x99,0x44,0x03,0x60,0xa6,0x21,0xe0,0x05,0xb0,0x01,0x60,0x68,0x68,0xa0,
	0x82,0x60,0xa4,0x2a,0x8c,0x0a,0x03,0xa4,0x2b,0x8c,0x0b,0x03,0xa0,0x00,0x8d,0x02,
	0x03,0x8e,0x01,0x03,0x8c,0x03,0x03,0xa0,0x50,0x8c,0x00,0x03,0xa0,0x08,0x8c,0x06,
	0x03,0x4c,0x59,0xe4,0x62,0x31,0x64,0x02,0x66,0x02,0x68,0x02,0x6a,0x02,0x6c,0x02,
	0x4c,0x7a,0x03,0x00,0x6e,0x03,0x70,0x02,0x72,0x02,0x74,0x02,0x76,0x02,0x58,0x02,
	0x78,0x02,0x78,0x02,0x00};
#else
// Note, there is an extra byte to store checksum
static UInt8 bootHandler850[] = 
{
    0x00,0x03,0x00,0x05,0xc0,0xe4,0xa9,0x50,0x8d,0x00,0x03,0xad,0xe7,0x02,0x8d,0x04,
    0x03,0xad,0xe8,0x02,0x8d,0x05,0x03,0xa9,0x91,0x8d,0x08,0x03,0xa9,0x05,0x8d,0x09,
    0x03,0x8d,0x06,0x03,0xa9,0x01,0x8d,0x01,0x03,0xa9,0x40,0x8d,0x03,0x03,0xa9,0x26,
    0x8d,0x02,0x03,0x20,0x59,0xe4,0x10,0x02,0x38,0x60,0xa2,0x84,0x18,0xbd,0xa7,0x05,
    0x6d,0xe7,0x02,0x9d,0xa7,0x05,0xbd,0xa8,0x05,0x6d,0xe8,0x02,0x9d,0xa8,0x05,0xca,
    0xca,0xd0,0xe9,0xa0,0x00,0x8c,0x55,0x06,0x20,0x40,0x06,0xb1,0x80,0xaa,0xc8,0xb1,
    0x80,0x48,0xbd,0xb2,0x05,0x91,0x80,0x88,0xbd,0xb1,0x05,0x91,0x80,0x68,0x20,0x2d,
    0x06,0xd0,0xe8,0xa2,0x02,0x20,0x40,0x06,0xb1,0x80,0xaa,0xbd,0xb1,0x05,0x91,0x80,
    0xae,0x55,0x06,0xee,0x55,0x06,0xbd,0x4b,0x06,0x20,0x2d,0x06,0xd0,0xea,0xa2,0x04,
    0x20,0x40,0x06,0xa5,0x0c,0x91,0x80,0xc8,0xa5,0x0d,0x91,0x80,0xad,0x27,0x06,0x85,
    0x0c,0xad,0x28,0x06,0x85,0x0d,0xa2,0x0c,0x4c,0xe9,0x03,0x8f,0x05,0xc2,0x04,0xfc,
    0x03,0x43,0x05,0x9c,0x06,0x94,0x06,0x98,0x06,0xbd,0x06,0xb4,0x04,0xbc,0x06,0xba,
    0x06,0xbb,0x06,0xb4,0x06,0xb3,0x06,0x5b,0x05,0xbe,0x06,0xa0,0x06,0xc8,0x00,0xf0,
    0x04,0xd2,0x04,0x02,0x05,0x11,0x06,0xf9,0x04,0x15,0x05,0xaf,0x06,0xb0,0x06,0xb1,
    0x06,0xb2,0x06,0x25,0x05,0xa4,0x06,0xb0,0x06,0x82,0x05,0x81,0x05,0xab,0x06,0xa9,
    0x06,0xac,0x06,0xaa,0x06,0x36,0x05,0x90,0x06,0xbc,0x06,0x8b,0x05,0x15,0x01,0xdd,
    0x04,0x4f,0x05,0x23,0x02,0x71,0x05,0x13,0x04,0xad,0x06,0xae,0x06,0x0c,0x05,0xff,
    0xff,0x25,0x00,0x5e,0x01,0x6d,0x00,0x0c,0x02,0x56,0x02,0x70,0x03,0x95,0x03,0x89,
    0x03,0x9c,0x03,0x71,0x02,0x73,0x04,0xb3,0x03,0x91,0x05,0xfe,0x03,0x8d,0x56,0x06,
    0x38,0xa5,0x80,0xed,0x56,0x06,0x85,0x80,0xb0,0x02,0xc6,0x81,0xad,0x56,0x06,0x60,
    0xbd,0xab,0x05,0x85,0x80,0xbd,0xac,0x05,0x85,0x81,0x60,0x0a,0xe6,0x05,0x85,0x0b,
    0x48,0x05,0x37,0x05,0x00,0x00};

// Note, there is an extra byte to store checksum
static UInt8 deviceHandler850[] = 
{
    0x20,0x00,0x00,0xbd,0x02,0x03,0x10,0x03,0xa0,0x96,0x60,0xa5,0x2a,0xa8,0x29,0x0c,
    0xd0,0x03,0xa0,0x84,0x60,0x98,0x09,0x80,0x9d,0x02,0x15,0xa9,0x00,0x9d,0x04,0x05,
    0x9d,0x06,0x03,0xa0,0x01,0x60,0x20,0x00,0x06,0xec,0x08,0x03,0xf0,0x0c,0xbd,0x04,
    0x05,0xf0,0x2c,0x20,0x0a,0x05,0xa0,0x80,0xd0,0x2a,0xad,0x0c,0x07,0xf0,0xfb,0x78,
    0xad,0x0e,0x06,0x8d,0x16,0x02,0xad,0x10,0x06,0x8d,0x17,0x02,0xa2,0x05,0xbd,0x12,
    0x08,0x9d,0x0a,0x02,0xca,0x10,0xf7,0x58,0xad,0x08,0x0a,0x8e,0x08,0x03,0xaa,0xa0,
    0x00,0x8c,0x0a,0x03,0xa9,0x00,0x9d,0x02,0x0b,0xa9,0x57,0x4c,0x16,0x05,0xbc,0x41,
    0x03,0xc0,0x05,0x90,0x03,0xa0,0x82,0x60,0x8d,0x18,0x0d,0xb9,0x02,0x03,0x29,0x08,
    0xd0,0x03,0xa0,0x87,0x60,0x98,0xaa,0x86,0x21,0xbd,0x1a,0x0e,0x29,0x30,0xa8,0xf0,
    0x04,0xc9,0x20,0xb0,0x36,0xad,0x18,0x0c,0xc9,0x9b,0xd0,0x19,0xbd,0x1a,0x07,0x29,
    0x40,0xf0,0x0e,0xa9,0x0d,0x20,0x1c,0x09,0x10,0x01,0x60,0xa6,0x21,0xa9,0x0a,0xd0,
    0x17,0xa9,0x0d,0xd0,0x13,0xc0,0x10,0xf0,0x04,0x29,0x7f,0x10,0x0b,0xc9,0x20,0x90,
    0x04,0xc9,0x7d,0x90,0x03,0xa0,0x01,0x60,0x8d,0x18,0x23,0xbd,0x1a,0x03,0x29,0x03,
    0xf0,0x1e,0xc9,0x03,0xf0,0x0e,0xa8,0x20,0x1e,0x0c,0x20,0x20,0x03,0x98,0x29,0x02,
    0xf0,0x0c,0x90,0x0c,0xad,0x18,0x0a,0x09,0x80,0x8d,0x18,0x05,0x30,0x02,0x90,0xf4,
    0xa6,0x21,0xec,0x08,0x09,0xf0,0x2d,0x20,0x22,0x05,0x7d,0x04,0x03,0xa8,0xad,0x18,
    0x04,0x99,0x24,0x03,0xfe,0x04,0x03,0xc9,0x0d,0xf0,0x0a,0xa9,0x20,0xdd,0x04,0x09,
    0xf0,0x03,0xa0,0x01,0x60,0x20,0x0a,0x08,0xa0,0x80,0xa9,0x00,0x9d,0x04,0x07,0xa9,
    0x57,0x4c,0x16,0x05,0xad,0x14,0x03,0xc9,0x1f,0xb0,0xf9,0x20,0x22,0x07,0x78,0x7d,
    0x04,0x04,0xa8,0xad,0x18,0x04,0x99,0x24,0x03,0xbc,0x04,0x03,0x20,0x26,0x03,0x9d,
    0x04,0x03,0xee,0x14,0x03,0xa5,0x10,0xbc,0x1a,0x05,0x30,0x04,0x09,0x18,0xd0,0x02,
    0x09,0x08,0x85,0x10,0x8d,0x0e,0xd2,0xa0,0x00,0x8c,0x0c,0x12,0x58,0xc8,0x60,0x20,
    0x00,0x06,0xbd,0x02,0x03,0x29,0x04,0xd0,0x03,0xa0,0x83,0x60,0xec,0x08,0x0a,0xf0,
    0x03,0xa0,0x9a,0x60,0xa0,0x04,0xa2,0x06,0x58,0x78,0x20,0x28,0x0e,0xf0,0xf9,0xa5,
    0x2c,0x48,0xa5,0x2d,0x48,0xad,0x2a,0x0b,0x85,0x2c,0xad,0x2c,0x05,0x85,0x2d,0xa0,
    0x00,0xb1,0x2c,0x8d,0x18,0x09,0x68,0x85,0x2d,0x68,0x85,0x2c,0x38,0xad,0x2e,0x0a,
    0xe9,0x01,0x8d,0x2e,0x05,0xb0,0x03,0xce,0x30,0x05,0xa2,0x02,0x20,0x32,0x05,0x58,
    0xa6,0x21,0xbd,0x1a,0x06,0x4a,0x4a,0x29,0x03,0xf0,0x23,0xc9,0x03,0xf0,0x1c,0xa8,
    0xad,0x18,0x0e,0x20,0x20,0x03,0x98,0x29,0x02,0xf0,0x0e,0x90,0x0e,0xa6,0x21,0xa9,
    0x20,0x1d,0x06,0x0e,0x9d,0x06,0x03,0xd0,0x02,0x90,0xf2,0x20,0x1e,0x07,0xa6,0x21,
    0xbd,0x1a,0x05,0x29,0x30,0xc9,0x20,0x90,0x06,0xad,0x18,0x09,0xa0,0x01,0x60,0xa8,
    0x20,0x1e,0x07,0xc9,0x0d,0xd0,0x04,0xa9,0x9b,0xd0,0x0f,0xc0,0x00,0xf0,0x0b,0xc9,
    0x20,0x90,0x04,0xc9,0x7d,0x90,0x03,0xbd,0x34,0x17,0xa0,0x01,0x60,0x20,0x00,0x06,
    0xbd,0x06,0x03,0x8d,0xea,0x02,0x8d,0x18,0x06,0xa9,0x00,0x9d,0x06,0x05,0xec,0x08,
    0x03,0xf0,0x27,0xa9,0xea,0x8d,0x04,0x03,0xa9,0x02,0x8d,0x05,0x03,0xa9,0x02,0x8d,
    0x08,0x03,0xa9,0x00,0x8d,0x09,0x03,0xa0,0x40,0xa9,0x53,0x20,0x16,0x1d,0xad,0x18,
    0x03,0x0d,0xea,0x02,0x8d,0xea,0x02,0xc0,0x00,0x60,0xa0,0x03,0xb9,0x36,0x0e,0x99,
    0xea,0x02,0x88,0xd0,0xf7,0xc8,0x60,0x20,0x00,0x0b,0xa5,0x22,0x29,0x0f,0xc9,0x09,
    0xb0,0x0d,0xa8,0x4a,0xb0,0x09,0xb9,0x38,0x0f,0x48,0xb9,0x3a,0x04,0x48,0x60,0xa0,
    0x84,0x60,0xbd,0x02,0x08,0x30,0x03,0xa0,0x85,0x60,0x2c,0x08,0x08,0x70,0x03,0xa0,
    0x99,0x60,0x4a,0xb0,0x03,0xa0,0x97,0x60,0x4a,0x4a,0x90,0x4f,0xa5,0x2a,0xf0,0x20,
    0xa5,0x28,0x05,0x29,0xf0,0x1a,0x18,0xa5,0x24,0x8d,0x3c,0x1f,0x65,0x28,0x8d,0x3e,
    0x05,0xa5,0x25,0x8d,0x40,0x05,0x65,0x29,0x8d,0x42,0x05,0x90,0x23,0xa0,0x98,0x60,
    0x20,0x22,0x08,0x69,0x78,0x8d,0x3c,0x05,0xa9,0x79,0x69,0x00,0x8d,0x40,0x07,0x18,
    0xad,0x3c,0x04,0x69,0x1f,0x8d,0x3e,0x05,0xad,0x40,0x03,0x69,0x00,0x8d,0x42,0x05,
    0xa0,0x06,0x20,0x44,0x05,0x88,0x88,0xc0,0x02,0xd0,0xf7,0xa6,0x21,0xbd,0x02,0x0b,
    0x29,0x08,0xf0,0x08,0xa9,0x00,0x9d,0x04,0x09,0x9d,0x46,0x03,0x8d,0x09,0x03,0xa9,
    0x12,0x8d,0x04,0x03,0xa9,0x13,0x8d,0x05,0x03,0xbd,0x02,0x10,0x8d,0x0a,0x03,0xa9,
    0x09,0x8d,0x08,0x03,0xa0,0x40,0xa9,0x58,0x20,0x16,0x0f,0x10,0x01,0x60,0x78,0xa9,
    0x73,0x8d,0x0f,0xd2,0xad,0x48,0x0c,0x8d,0x08,0xd2,0xa0,0x07,0xb9,0x12,0x08,0x99,
    0x00,0xd2,0x88,0x10,0xf7,0xa2,0x05,0xbd,0x0a,0x02,0x9d,0x12,0x0e,0xbd,0x4a,0x03,
    0x9d,0x0a,0x02,0xca,0x10,0xf1,0xad,0x16,0x02,0x8d,0x0e,0x0c,0xa9,0x7a,0x8d,0x16,
    0x02,0xad,0x17,0x02,0x8d,0x10,0x0b,0xa9,0x7b,0x8d,0x17,0x02,0xa9,0x00,0xa0,0x02,
    0x99,0x2e,0x0c,0x88,0x10,0xfa,0xa6,0x21,0xbd,0x02,0x08,0x29,0x04,0xf0,0x09,0xa5,
    0x10,0x09,0x20,0x8d,0x0e,0xd2,0x85,0x10,0x8e,0x08,0x10,0x8e,0x0c,0x03,0x58,0xd0,
    0x36,0xbd,0x02,0x06,0x30,0x03,0xa0,0x85,0x60,0x29,0x08,0xd0,0x03,0xa0,0x87,0x60,
    0xbd,0x04,0x0f,0xf0,0x22,0x20,0x4c,0x05,0xd0,0x1f,0xa0,0x7f,0x20,0x4e,0x07,0xa9,
    0x42,0x20,0x50,0x05,0xd0,0x13,0xa9,0x41,0x20,0x50,0x07,0xd0,0x0c,0xa0,0x80,0x20,
    0x4e,0x07,0xa5,0x2b,0x9d,0x34,0x05,0xa0,0x01,0xa6,0x21,0xbd,0x02,0x07,0x85,0x2a,
    0xc0,0x00,0x60,0xa9,0x00,0xa2,0x00,0xdd,0x1a,0x03,0xf0,0x08,0xe8,0xe8,0xe8,0xe0,
    0x20,0x90,0xf4,0x60,0xa9,0x52,0x8d,0x08,0x1b,0x9d,0x1a,0x03,0xa9,0x54,0x9d,0x1b,
    0x03,0xa9,0x55,0x9d,0x1c,0x03,0x18,0xad,0xe7,0x02,0x69,0xc0,0x8d,0xe7,0x02,0xad,
    0xe8,0x02,0x69,0x06,0x8d,0xe8,0x02,0xa2,0x04,0xa9,0x00,0x9d,0x02,0x25,0xca,0xd0,
    0xfa,0xe8,0x20,0x52,0x07,0x18,0xa5,0x08,0xd0,0x01,0x60,0x4c,0xff,0xff,0x2c,0x0e,
    0xd2,0x10,0x03,0x6c,0x0e,0x11,0x48,0xa9,0x7f,0x8d,0x0e,0xd2,0xa5,0x10,0x8d,0x0e,
    0xd2,0x68,0x40,0xd8,0x8a,0x48,0x98,0x48,0xa5,0x2c,0x48,0xa5,0x2d,0x48,0xad,0x58,
    0x1b,0x85,0x2c,0xad,0x5a,0x05,0x85,0x2d,0xad,0x0d,0xd2,0xa0,0x00,0x91,0x2c,0xad,
    0x0f,0xd2,0x8d,0x0a,0xd2,0x49,0xff,0x29,0xc0,0xae,0x08,0x16,0x1d,0x06,0x03,0x9d,
    0x06,0x03,0x68,0x85,0x2d,0x68,0x85,0x2c,0xa2,0x00,0x20,0x32,0x0b,0xa0,0x04,0xa2,
    0x06,0x20,0x28,0x07,0xd0,0x12,0xa2,0x02,0x20,0x32,0x07,0xae,0x08,0x03,0xbd,0x06,
    0x03,0x09,0x10,0x9d,0x06,0x05,0xd0,0x05,0xa2,0x04,0x20,0x5c,0x07,0x68,0xa8,0x68,
    0xaa,0x68,0x40,0xd8,0x8a,0x48,0x98,0x48,0xae,0x08,0x0e,0xbd,0x04,0x03,0xdd,0x46,
    0x03,0xd0,0x0f,0x8e,0x0c,0x05,0xa5,0x10,0x29,0xe7,0x85,0x10,0x8d,0x0e,0xd2,0x18,
    0x90,0xdb,0x20,0x22,0x0f,0x7d,0x46,0x03,0xa8,0xb9,0x24,0x04,0x8d,0x0d,0xd2,0xbc,
    0x46,0x06,0x20,0x26,0x03,0x9d,0x46,0x03,0xce,0x14,0x03,0xad,0x0e,0xd2,0x29,0x08,
    0xf0,0xf9,0xd0,0xb9,0x20,0x22,0x0c,0x69,0x24,0x8d,0x04,0x03,0xa9,0x00,0x8d,0x09,
    0x03,0x69,0x25,0x8d,0x05,0x03,0xbd,0x04,0x12,0x8d,0x0a,0x03,0xa9,0x40,0x8d,0x08,
    0x03,0x60,0xa2,0x00,0x4a,0x90,0x01,0xe8,0xd0,0xfa,0x8a,0x4a,0x60,0x98,0x3d,0x1a,
    0x18,0x9d,0x1a,0x03,0x98,0x49,0xff,0x25,0x2a,0x1d,0x1a,0x08,0x9d,0x1a,0x03,0x60,
    0xad,0x18,0x04,0x29,0x7f,0x8d,0x18,0x05,0x60,0xc8,0x98,0xc9,0x20,0x90,0x02,0xa9,
    0x00,0x60,0x8a,0x38,0xe9,0x01,0x0a,0x0a,0x0a,0x0a,0x0a,0x60,0xfe,0x58,0x17,0xd0,
    0x03,0xfe,0x5a,0x05,0x60,0xb9,0x42,0x04,0xdd,0x42,0x03,0xf0,0x01,0x60,0xb9,0x3e,
    0x06,0xdd,0x3e,0x03,0x60,0x20,0x5c,0x04,0x8a,0x18,0x69,0x04,0xa8,0xa2,0x00,0x20,
    0x28,0x0a,0xf0,0x0e,0x90,0x0c,0xad,0x3c,0x07,0x99,0x3e,0x03,0xad,0x40,0x03,0x99,
    0x42,0x03,0x60,0xa6,0x21,0xe0,0x05,0xb0,0x01,0x60,0x68,0x68,0xa0,0x82,0x60,0xa4,
    0x2a,0x8c,0x0a,0x03,0xa4,0x2b,0x8c,0x0b,0x03,0xa0,0x00,0x8d,0x02,0x03,0x8e,0x01,
    0x03,0x8c,0x03,0x03,0xa0,0x50,0x8c,0x00,0x03,0xa0,0x08,0x8c,0x06,0x03,0x4c,0x59,
    0xe4,0x5e,0x31,0x60,0x02,0x62,0x02,0x64,0x02,0x66,0x02,0x68,0x02,0x4c,0x76,0x03,
    0x00,0x6a,0x03,0x6c,0x02,0x6e,0x02,0x70,0x02,0x72,0x02,0x56,0x02,0x74,0x02,0x74,
    0x02,0x00};
#endif
int driveState[NUMBER_OF_ATARI_DRIVES];
char driveFilename[NUMBER_OF_ATARI_DRIVES][FILENAME_MAX];
char diskImageDefaultDirectory[FILENAME_MAX];
char cassImageDefaultDirectory[FILENAME_MAX];
char diskSetDefaultDirectory[FILENAME_MAX];
char printerOutputDefaultDirectory[FILENAME_MAX];
int currPrinter;
SIO_PREF prefsSio;
FILE *logFile = NULL;

#define LOGICAL_SECTORS		0
#define PHYSICAL_SECTORS	1
#define SIO2PC_SECTORS		2

void SioControllerLogPrint(char *format, ... )
{
	va_list args;
	
	if (!logFile) {
		NSString *home;
		char filename[FILENAME_MAX];
		
		home = NSHomeDirectory();
		[home getCString:filename];
		strcat(filename,"/Sio2OSXLog.txt");
		logFile = fopen(filename,"w");
		if (!logFile) {
			return;
			}
		}

	va_start(args, format);
	vfprintf(logFile,format,args);
	fflush(logFile);
	va_end(args);
}

/* Global variables for USB device notification */
static IONotificationPortRef    gNotifyPort;
static io_iterator_t            gAddedIter;
static io_iterator_t            gRemovedIter;

/*------------------------------------------------------------------------------
* UsbDeviceAdded - Process an USB Device added notification
*-----------------------------------------------------------------------------*/
void UsbDeviceAdded(void *refCon, io_iterator_t iterator)
{
    io_service_t                usbDevice;
	static int					first = TRUE;

    while (usbDevice = IOIteratorNext(iterator))
    {
	} 
	
	if (first)
		first = FALSE;
	else {
		[[SioController sharedInstance] rescanModems:YES];
		}
}

/*------------------------------------------------------------------------------
* UsbDeviceRemoved - Process an USB Device removed notification
*-----------------------------------------------------------------------------*/
void UsbDeviceRemoved(void *refCon, io_iterator_t iterator)
{
    io_service_t                usbDevice;
	static int					first = TRUE;

    while (usbDevice = IOIteratorNext(iterator))
    {
	}
	
	if (first)
		first = FALSE;
	else {
		[[SioController sharedInstance] rescanModems:NO];
		}
}

/*------------------------------------------------------------------------------
* Setup_USB_Notifications - Setup so that we are notified if a USB
*   device is plugged in.
*-----------------------------------------------------------------------------*/
int Setup_USB_Notifications(void)
{
    mach_port_t             masterPort;
    CFMutableDictionaryRef  matchingDict;
    CFRunLoopSourceRef      runLoopSource;
    kern_return_t           result;

    //Create a master port for communication with the I/O Kit
    result = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (result || !masterPort)
    {
        printf("ERR: Couldn’t create a master I/O Kit port(%08x)\n", result);
        return -1;
    }

    //Set up matching dictionary for class IOUSBDevice and its subclasses
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (!matchingDict)
    {
        printf("Couldn’t create a USB matching dictionary\n");
        mach_port_deallocate(mach_task_self(), masterPort);
        return -1;
    }

    //To set up asynchronous notifications, create a notification port and 
    //add its run loop event source to the program’s run loop
    gNotifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, 
                        kCFRunLoopCommonModes);

    //Retain additional dictionary references because each call to
    //IOServiceAddMatchingNotification consumes one reference
    matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
    matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);

    //Now set up two notifications: one to be called when a USB device
    //is first matched by the I/O Kit and another to be called when the
    //device is terminated
    //Notification of first match
    result = IOServiceAddMatchingNotification(gNotifyPort,
                    kIOFirstMatchNotification, matchingDict,
                    UsbDeviceAdded, NULL, &gAddedIter);
					
    //Iterate over set of matching devices to access already-present devices
    //and to arm the notification 
    UsbDeviceAdded(NULL, gAddedIter);
	
    //Notification of termination

    result = IOServiceAddMatchingNotification(gNotifyPort,
                    kIOTerminatedNotification, matchingDict,
                    UsbDeviceRemoved, NULL, &gRemovedIter);

    //Iterate over set of matching devices to release each one and to 
    //arm the notification

    UsbDeviceRemoved(NULL, gRemovedIter);
	return(0);
}

/*------------------------------------------------------------------------------
* Clenup_USB_Notifications - Cleanup notification structures on quiting.
*-----------------------------------------------------------------------------*/
void Cleanup_USB_Notifications(void)
{
    IONotificationPortDestroy(gNotifyPort);
    if (gAddedIter)
    {
        IOObjectRelease(gAddedIter);
        gAddedIter = 0;
    }

    if (gRemovedIter)
    {
        IOObjectRelease(gRemovedIter);
        gRemovedIter = 0;
    }
}


@implementation SioController

static SioController *sharedInstance = nil;

+ (SioController *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {
	[self dealloc];
    } else {
        [super init];
        maxSpeed = 3;
        currentSpeed = 1;
        sharedInstance = self;
		offline = NO;
		printerFile = NULL;
		diskServerPause = 0;
		cassFile = NULL;
		diskServerStarted = NO;
		diskServerExited = NO;
		modemChanged = NO;
		onUpdate = [LedUpdate withOn:YES];
		offUpdate = [LedUpdate withOn:NO];
		cassStatusUpdate = [[CassStatusUpdate alloc] init];
		cassInfoUpdate = [[CassInfoUpdate alloc] init];
		enable850 = YES;
		strncpy(netServerBusyMessage,"The BBS is currently connected to another client.  Please try again later.\n",255);
		strncpy(netServerNotReadyMessage,"The BBS is not ready to accept connections.  Please try again later.\n",255);
		[self init850State];

		Setup_USB_Notifications();
	}
	
    return sharedInstance;
}

- (void) init850State
{
	int i;

	concurrentMode = NO;
	concurrentPort = 0;
	for (i=0;i<NUM_850_PORTS;i++) {
		baud850[i] = B300;
		bits850[i] = 8;
		stopBits850[i] = 1;
		dsrHandshake850[i] = NO;
		ctsHandshake850[i] = NO;
		dsrLast[i] = NO;
		ctsLast[i] = NO;
		crxLast[i] = NO;
		port850fd[i] = -1;
		port850Mode[i] = PORT_850_OFF;
		}
	port850Mode[0] = PORT_850_NET_MODE;
	netATMode = YES;
	netCarrierDetected = NO;
	netTerminalReady = NO;
	netServerFd = -1;
	netServerStarted = NO;
	netServerExit = NO;
	netServerExited = NO;
	modemCharCount = 0;
	modemEcho = YES;
	modemEscapeCharacter = '+';
	modemAutoAnswer = NO;
	modemAtascii = NO;	
}

- (void)dealloc {
	[super dealloc];
}

- (void) updatePreferences
{
	int i,j;
	static BOOL firstTime = YES;

	[mutex lock];
	maxSpeed = prefsSio.maxSerialSpeed;
	delayFactor = prefsSio.delayFactor;
	ignoreAtrWriteProtect = prefsSio.ignoreAtrWriteProtect;
	sioHWType = prefsSio.sioHWType;
	if (currPrinter != prefsSio.currPrinter)
		PrintOutputControllerSelectPrinter(prefsSio.currPrinter);
	currPrinter = prefsSio.currPrinter;
	strcpy(diskSetDefaultDirectory,prefsSio.diskSetDir);
	strcpy(diskImageDefaultDirectory,prefsSio.diskImageDir);
	strcpy(cassImageDefaultDirectory,prefsSio.cassImageDir);
	strcpy(printerOutputDefaultDirectory,prefsSio.printDir);
	strcpy(printerCommand,prefsSio.printerCommand);
	strcpy(serialPort,prefsSio.serialPort);
	for (i=0;i<NUM_STORED_NAMES;i++) {
		strcpy(storedNameAddr[i], prefsSio.storedNameAddr[i]);
		storedNamePort[i] = prefsSio.storedNamePort[i];
		if (storedNameAddr[i][0] == 0)
			storedNameInUse[i] = NO;
		else
			storedNameInUse[i] = YES;
		}
	strcpy(netServerNotReadyMessage, prefsSio.netServerNotReadyMessage);
	strcpy(netServerBusyMessage, prefsSio.netServerBusyMessage);
	if (!firstTime) {
		// If we have changed server port or if it is enabled, then restart
		if (netServerNetPort != prefsSio.netServerNetPort || 
			netServerEnable != prefsSio.netServerEnable) {
			if (netServerStarted) {
				[self stopNetServer];
				if (netCarrierDetected) {
					close(port850fd[netServerPort]);
					port850fd[netServerPort] = -1;
					netCarrierDetected = NO;
					}
				}
			netServerNetPort = prefsSio.netServerNetPort;
			netServerEnable = prefsSio.netServerEnable;
			[self startNetServer];
			}
		}
	else {
		netServerNetPort = prefsSio.netServerNetPort;
		netServerEnable = prefsSio.netServerEnable;
		}
	
	if (firstTime) {
		modemEcho = prefsSio.modemEcho;
		modemEscapeCharacter = prefsSio.modemEscapeCharacter;
		modemAutoAnswer = prefsSio.modemAutoAnswer;
		enable850 = prefsSio.enable850;
		for (i=0;i<NUM_850_PORTS;i++) {
			port850Mode[i] = prefsSio.port850Mode[i];
			strcpy(port850Port[i],prefsSio.port850Port[i]);
			}
		firstTime = FALSE;
		}
	else {
		BOOL changes[NUM_850_PORTS];
		
		// Check if anything changed on each port 
		for (i=0;i<NUM_850_PORTS;i++) {
			changes[i] = NO;
			if ((port850Mode[i] != prefsSio.port850Mode[i]) ||
				(port850Mode[i] == PORT_850_SERIAL_MODE &&
				 strcmp(port850Port[i],prefsSio.port850Port[i])==0))
				 changes[i] = YES;
			}
		// Close out the old stuff on the changed ports.....
		for (i=0;i<NUM_850_PORTS;i++) {
			if (changes[i]) {
				if (port850Mode[i] == PORT_850_NET_MODE) {
					if (netServerStarted) {
						[self stopNetServer];
						if (netCarrierDetected) {
							close(port850fd[netServerPort]);
							port850fd[netServerPort] = -1;
							netCarrierDetected = NO;
							}
						}
					}
				else if (port850Mode[i] == PORT_850_SERIAL_MODE) {
					close(port850fd[i]);
					}
				}
			}
		// Open the new stuff on the changed ports.....
		for (i=0;i<NUM_850_PORTS;i++) {
			port850Mode[i] = prefsSio.port850Mode[i];
			strcpy(port850Port[i],prefsSio.port850Port[i]);
			if (changes[i]) {
				if (prefsSio.port850Mode[i] == PORT_850_NET_MODE) {
					[self startNetServer];
					}
				else if (prefsSio.port850Mode[i] == PORT_850_SERIAL_MODE) {
					for (j=0;j<modemCount;j++) {
						if (strcmp(modemNames[j],port850Port[i])==0)
							{
							port850fd[i] = [self openSerialPort:bsdPaths[j]:B300];
							}
						}
					}
				}
			}
		}
	[mutex unlock];
}

// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
- (kern_return_t) findModems:(io_iterator_t *) matchingServices
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
        SioControllerLogPrint("IOMasterPort returned %d\n", kernResult);
        
    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
        SioControllerLogPrint("IOServiceMatching returned a NULL dictionary.\n");
    else {
        CFDictionarySetValue(classesToMatch,
                            CFSTR(kIOSerialBSDTypeKey),
                            CFSTR(kIOSerialBSDRS232Type));
    }
    
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult)
        SioControllerLogPrint("IOServiceGetMatchingServices returned %d\n", kernResult);
        
    return kernResult;
}
    
// Given an iterator across a set of modems, return a list of the
// modems BSD paths.
// If no modems are found the path name is set to an empty string.
- (int) getModemPaths:(io_iterator_t )serialPortIterator 
{
    io_object_t		modemService;
    kern_return_t	kernResult = KERN_FAILURE;
	int modems = 0;
	
    while ((modemService = IOIteratorNext(serialPortIterator)) && modems < MAX_MODEMS)
    {
        CFTypeRef	modemNameAsCFString;
        CFTypeRef	bsdPathAsCFString;

        kernResult = KERN_SUCCESS;
		modems++;

        modemNameAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                              CFSTR(kIOTTYDeviceKey),
                                                              kCFAllocatorDefault,
                                                              0);
        if (modemNameAsCFString)
        {
            Boolean result;

            result = CFStringGetCString(modemNameAsCFString,
										modemNames[modems-1],
                                        FILENAME_MAX, 
                                        kCFStringEncodingASCII);
            CFRelease(modemNameAsCFString);
            
        }

        bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (bsdPathAsCFString)
        {
            Boolean result;
            
            result = CFStringGetCString(bsdPathAsCFString,
										bsdPaths[modems-1],
                                        FILENAME_MAX, 
                                        kCFStringEncodingASCII);
            CFRelease(bsdPathAsCFString);
        }

        (void) IOObjectRelease(modemService);
    }
	
    return modems;
}

// Given the path to a serial device, open the device and configure it.
// Return the file descriptor associated with the device.
- (int) openSerialPort:(const char *) bsdPath:(int)initialBaud
{
    int 		newFileDescriptor = -1;
    struct termios	options;

    newFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY);
    if (newFileDescriptor == -1)
    {
        SioControllerLogPrint("Error opening serial port %s - %s(%d).\n",
               bsdPath, strerror(errno), errno);
        goto error;
    }
    
    SioControllerLogPrint("Opened serial port %s.\n",bsdPath);

    // Get the current options and save them for later reset
    if (tcgetattr(newFileDescriptor, &gOriginalTTYAttrs) == -1)
    {
        SioControllerLogPrint("openSerialPort - Error getting tty attributes %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }


    // Set raw input/output, one second timeout
    options = gOriginalTTYAttrs;
	cfmakeraw(&options);
    options.c_cflag = (CREAD | CLOCAL | CS8);
    options.c_lflag = 0;
    options.c_iflag = 0;
    options.c_oflag = 0;
    options.c_cc[ VMIN ] = 1;
    options.c_cc[ VTIME ] = 0;
    
    cfsetospeed(&options,initialBaud);
    cfsetispeed(&options,initialBaud);
    
    // Set the options
    if (tcsetattr(newFileDescriptor, TCSANOW, &options) == -1)
    {
        SioControllerLogPrint("openSerialPort - Error setting tty attributes %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }

    // Success
    return newFileDescriptor;
    
    // Failure path
error:
    if (newFileDescriptor != -1)
        close(newFileDescriptor);
    return -1;
}

// Given the file descriptor for a serial device, close that device.
- (void) closeSerialPort: (int) descriptor: (BOOL) reset
{
	if (reset) {
		if (tcsetattr(fileDescriptor, TCSANOW, &gOriginalTTYAttrs) == -1)
			{
			SioControllerLogPrint("closeSerialPort - Error resetting tty attributes - %s(%d).\n",
				strerror(errno), errno);
			}
		}
	
    close(descriptor);
}

// Set the speed on a serial port
- (void) setSerialPortSpeed: (int) descriptor : (int) speed
{
    struct termios	options;
    speed_t             portSpeed;
    
    // Get the current options and save them for later reset
    if (tcgetattr(descriptor, &options) == -1)
    {
        SioControllerLogPrint("setSerialPortSpeed - Error getting tty attributes - %s(%d).\n",
		strerror(errno), errno);
        return;
    }
    
    switch(speed) {
        case 0:
				SioControllerLogPrint("Setting serial port speed to 600\n");
				[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(displaySpeed:) 
										withObject:[NSNumber numberWithInt:600] waitUntilDone:NO];
                portSpeed = B600;
                break;
        case 1:
        default:
				SioControllerLogPrint("Setting serial port speed to 19200\n");
				[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(displaySpeed:) 
										withObject:[NSNumber numberWithInt:19200] waitUntilDone:NO];
                portSpeed = B19200;
                break;
        case 2:
				SioControllerLogPrint("Setting serial port speed to 38400\n");
				[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(displaySpeed:) 
										withObject:[NSNumber numberWithInt:38400] waitUntilDone:NO];
                portSpeed = B38400;
                break;
        case 3:
				SioControllerLogPrint("Setting serial port speed to 57600\n");
				[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(displaySpeed:) 
										withObject:[NSNumber numberWithInt:57600] waitUntilDone:NO];
                portSpeed = B57600;
                break;
        }
    
    cfsetospeed(&options,portSpeed);
    cfsetispeed(&options,portSpeed);
    if (tcsetattr(descriptor, TCSAFLUSH, &options) == -1)
    {
        SioControllerLogPrint("setSerialPortSpeed - Error resetting tty attributes - %s(%d).\n",
            strerror(errno), errno);
    }
    tcflush(descriptor ,TCIFLUSH); /* Clear out garbage */
    currentSpeed = speed;
}

- (UInt8) checksum: (UInt8 *) buffer: (UInt32) count
{
	UInt16 sum = 0;
	UInt32 i;
	
	for (i=0;i<count;i++)
		sum =((sum+buffer[i]) >> 8) + ((sum+buffer[i]) & 0xFF);
	return((UInt8) sum);
}

- (void) writeBlocks:(UInt8 *) buffer: (int) count: (int) blockSize
{
	int left = count;
	int xmitCount = blockSize;
	
	while (left > 0)
		{
		if (left < blockSize)
			xmitCount = left;
		write(fileDescriptor,buffer,xmitCount);
		left -= xmitCount;
		buffer += xmitCount;
		}
}

- (void) sendAck: (UInt8) c
{
	write(fileDescriptor,&c,1);
	tcdrain(fileDescriptor);
}

- (void) processDiskWriteCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 sectorBuff[257];
	UInt32 sector = cmd[2] + 256*cmd[3];
	int size;
	int i;
	
    if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Write sector %d - Error Drive Off\n",unit,(int) sector);
        return;
		}
	[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_READ_ONLY || 
        driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Write sector %d - Error Read Only/No Disk\n",unit,(int) sector);
        return;
        }
    if (sector > diskInfo[unit-1]->sectorCount) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Write sector %d - Error Bad Sector #\n",unit,(int) sector);
        return;
        }
	[self sendAck:'A'];
	[onUpdate setState:unit-1:0:sector];
	[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateLed:) 
										withObject:onUpdate waitUntilDone:NO];
	ledPersistence[unit-1] = LED_PERSIST;

	if (sector < 4)
		size = 128;
	else
		size = diskInfo[unit-1]->sectorSize;	
	for (i=0;i<size+1;i++)
		read(fileDescriptor,&sectorBuff[i],1);
	if (sectorBuff[size] != [self checksum:sectorBuff:size]) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Write sector %d - Error Bad Checksum #\n",unit,(int) sector);
		return;
		}
	
	if (diskInfo[unit-1]->directory)
		[self writeDirSector:unit-1:sector:sectorBuff];
	else
		[self writeSector:unit-1:sector:sectorBuff];
	[self sendAck:'A'];
	[self sendAck:'C'];
	SioControllerLogPrint("Disk %d Write sector %d\n",unit,(int) sector);
}

- (void) processDiskHappyWriteCommand:(int) unit: (UInt8 *) cmd
{
#if 0
	UInt8 sectorBuff[257];
	UInt32 sector = cmd[2] + 256*cmd[3];
	int i;
	int size;
	
	if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Happy Write sector %d - Error Drive Off\n",unit,(int) sector);
        return;
		}
	[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_READ_ONLY || 
        driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Happy Write sector %d - Error Read Only or No Disk\n",unit,(int) sector);
        return;
        }
    if (sector > diskInfo[unit-1]->sectorCount) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Happy Write sector %d - Bad Sector #\n",unit,(int) sector);
        return;
        }
	[self sendAck:'A'];
	[onUpdate setState:unit-1:0:sector];
	[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateLed:) 
										withObject:onUpdate waitUntilDone:NO];
	ledPersistence[unit-1] = LED_PERSIST;	

	if (sector < 4)
		size = 128;
	else
		size = diskInfo[unit-1]->sectorSize;	
	SioControllerLogPrint("Disk %d Happy Write sector %d\n",unit,(int) sector);
    [self setSerialPortSpeed:fileDescriptor:2];
	for (i=0;i<size+1;i++)
		read(fileDescriptor,&sectorBuff[i],1);
	if (sectorBuff[size] != [self checksum:sectorBuff:size]) {
		[self sendAck:'N'];
		[self setSerialPortSpeed:fileDescriptor:1];
		SioControllerLogPrint("Disk %d Happy Write sector %d - Error Bad Checksum\n",unit,(int) sector);
		return;
		}

	if (diskInfo[unit-1]->directory)
		[self writeDirSector:unit-1:sector:sectorBuff];
	else
		[self writeSector:unit-1:sector:sectorBuff];
	[self sendAck:'A'];
    [self setSerialPortSpeed:fileDescriptor:1];
	[self sendAck:'C'];
#else
	[self sendAck:'N'];
#endif
}

- (void) processDiskReadCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 sectorBuff[257];
	UInt32 sector = cmd[2] + 256*cmd[3];
	int size, i;
	
    if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Read sector %d - Error Drive Off\n",unit,(int) sector);
		if (enable850 && unit==1) {
			[self microDelay:ACK_WAIT];
			if (sector > 3) {
				[self sendAck:'N'];
				SioControllerLogPrint("Disk %d Read sector %d - Error Bad Sector\n",unit,(int) sector);
				return;
				}
			[self sendAck:'A'];
			[self microDelay:COMPLETE_WAIT];
			[self sendAck:'C'];
			[self microDelay:POST_COMP_WAIT];
			bcopy(&bootHandler850[(sector-1)*128],sectorBuff,128);
			sectorBuff[128] = [self checksum:sectorBuff:128];
			write(fileDescriptor,sectorBuff,128+1);
			SioControllerLogPrint("850 Read sector %d\n",(int) sector);
			tcdrain(fileDescriptor);
			}
        return;
		}
	if (diskInfo[unit-1]->imageType == IMAGE_TYPE_VAPI) 
		[self microDelay:VAPI_USEC_ACK_WAIT];
	else
		[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Read sector %d - Error No Disk\n",unit,(int) sector);
        return;
        }
    if (sector > diskInfo[unit-1]->sectorCount) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Read sector %d - Error Bad Sector\n",unit,(int) sector);
        return;
        }
	[self sendAck:'A'];
	[onUpdate setState:unit-1:1:sector];
	[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateLed:) 
										withObject:onUpdate waitUntilDone:NO];
	ledPersistence[unit-1] = LED_PERSIST;	

	if (diskInfo[unit-1]->directory) {
		[self microDelay:COMPLETE_WAIT];
		[self sendAck:'C'];
		[self microDelay:POST_COMP_WAIT];
		if (sector < 4)
			size = 128;
		else
			size = diskInfo[unit-1]->sectorSize;
		[self readDirSector:unit-1:sector:sectorBuff];
		sectorBuff[size] = [self checksum:sectorBuff:size];
		[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
		SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
		tcdrain(fileDescriptor);
	} else if (diskInfo[unit-1]->imageType == IMAGE_TYPE_ATR) {
		[self microDelay:COMPLETE_WAIT];
		[self sendAck:'C'];
		[self microDelay:POST_COMP_WAIT];
		if (sector < 4)
			size = 128;
		else
			size = diskInfo[unit-1]->sectorSize;
		[self readSector:unit-1:sector:sectorBuff];
		sectorBuff[size] = [self checksum:sectorBuff:size];
		[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
		SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
		tcdrain(fileDescriptor);
	} else if (diskInfo[unit-1]->imageType == IMAGE_TYPE_VAPI) {
		vapi_additional_info_t *info;
		vapi_sec_info_t *secinfo;
		UInt32 secindex = 0;
		static int lasttrack = 0;
		UInt32 time;
		unsigned int currpos, delay, rotations, bestdelay;
		unsigned char beststatus;
		int fromtrack, trackstostep, j;
		AtrDiskInfo *disk = diskInfo[unit-1];
		FILE *f = disk->file;
		
		info = (vapi_additional_info_t *)disk->addedInfo;
		info->vapi_delay_time = 0;
		disk->io_success = -1;
		size = [self seekSector:disk:sector];
		
		if (sector > disk->sectorCount) {
#ifdef DEBUG_VAPI
			SioControllerLogPrint("bad sector num:%d\n", sector);
#endif
			info->sec_stat_buff[0] = 9;
			info->sec_stat_buff[1] = 0xFF; 
			info->sec_stat_buff[2] = 0xe0;
			info->sec_stat_buff[3] = 0;
			disk->io_success = sector;
			[self microDelay:VAPI_USEC_BAD_SECTOR_NUM];
			[self sendAck:'E'];
			sectorBuff[size] = [self checksum:sectorBuff:size];
			[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
			SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
			return;
		}
		
		secinfo = &info->sectors[sector-1];
		fromtrack = lasttrack;
		lasttrack = (sector-1)/18;
		
		if (secinfo->sec_count == 0) {
#ifdef DEBUG_VAPI
			SioControllerLogPrint("missing sector:%d\n", sector);
#endif
			info->sec_stat_buff[0] = 0xC;
			info->sec_stat_buff[1] = 0xEF; 
			info->sec_stat_buff[2] = 0xe0;
			info->sec_stat_buff[3] = 0;
			disk->io_success = sector;
			[self microDelay:VAPI_USEC_MISSING_SECTOR];
			[self sendAck:'E'];
			sectorBuff[size] = [self checksum:sectorBuff:size];
			[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
			SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
			return;
		}
		
		trackstostep = abs((sector-1)/18 - fromtrack);
		time = [self getUpTimeUsec];
		time += VAPI_USEC_ACK_WAIT;
		if (trackstostep)
			time += trackstostep * VAPI_USEC_PER_TRACK_STEP + VAPI_USEC_HEAD_SETTLE ;
		rotations = time/VAPI_USEC_PER_ROT;
		currpos = time - rotations*VAPI_USEC_PER_ROT;
#ifdef DEBUG_VAPI
		SioControllerLogPrint(" sector:%d sector count :%d time %u\n", sector,secinfo->sec_count,[self getUpTimeUsec]);
#endif
		
		bestdelay = 10 * VAPI_USEC_PER_ROT;
		beststatus = 0;
		for (j=0;j<secinfo->sec_count;j++) {
			if (secinfo->sec_rot_pos[j]  < currpos)
				delay = (VAPI_USEC_PER_ROT - currpos) + secinfo->sec_rot_pos[j];
			else
				delay = secinfo->sec_rot_pos[j] - currpos; 
#ifdef DEBUG_VAPI
			SioControllerLogPrint("%d %d %d %d %d %x\n",j,secinfo->sec_rot_pos[j],
					  ([self getUpTimeUsec]) - ((([self getUpTimeUsec])/VAPI_USEC_PER_ROT)*VAPI_USEC_PER_ROT),
					  currpos,delay,secinfo->sec_status[j]);
#endif
			if (delay < bestdelay) {
				bestdelay = delay;
				beststatus = secinfo->sec_status[j];
				secindex = j;
			}
		}
		if (trackstostep)
			info->vapi_delay_time = bestdelay + trackstostep * VAPI_USEC_PER_TRACK_STEP + 
			VAPI_USEC_HEAD_SETTLE   +  VAPI_USEC_TRACK_READ_DELTA + VAPI_USEC_SECTOR_READ;
		else
			info->vapi_delay_time = bestdelay + VAPI_USEC_SECTOR_READ;
#ifdef DEBUG_VAPI
		SioControllerLogPrint("Bestdelay = %d VapiDelay = %d\n",bestdelay,info->vapi_delay_time);
		if (secinfo->sec_count > 1)
			SioControllerLogPrint("duplicate sector:%d dupnum:%d delay:%d",sector, secindex,info->vapi_delay_time);
#endif
		fseek(f,secinfo->sec_offset[secindex],SEEK_SET);
		info->sec_stat_buff[0] = 0x8 | ((secinfo->sec_status[secindex] == 0xFF) ? 0 : 0x04);
		info->sec_stat_buff[1] = secinfo->sec_status[secindex];
		info->sec_stat_buff[2] = 0xe0;
		info->sec_stat_buff[3] = 0;
		if (secinfo->sec_status[secindex] != 0xFF) {
			disk->io_success = sector;
			info->vapi_delay_time += VAPI_USEC_PER_ROT + VAPI_USEC_SECTOR_READ;
#ifdef DEBUG_VAPI
			SioControllerLogPrint("bad sector:%d 0x%0X delay:%d\n", sector, secinfo->sec_status[secindex],info->vapi_delay_time );
#endif
			fread(sectorBuff, 1, size, f);
			disk->io_success = sector;
			if (secinfo->sec_status[secindex] == 0xB7) {
				for (i=0;i<128;i++) {
					if (sectorBuff[i] == 0x33)
						sectorBuff[i] = random() & 0xFF;
				}
			}
			[self microDelay:(info->vapi_delay_time - VAPI_USEC_ACK_WAIT)];
			[self sendAck:'E'];
			SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
			sectorBuff[size] = [self checksum:sectorBuff:size];
			[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
			return;
		}
		[self microDelay:(info->vapi_delay_time-VAPI_USEC_ACK_WAIT)];
		[self sendAck:'C'];
		if (sector < 4)
			size = 128;
		else
			size = disk->sectorSize;
		fread(sectorBuff, 1, size, disk->file);
		sectorBuff[size] = [self checksum:sectorBuff:size];
		[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
		disk->io_success = 0;
		SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
		tcdrain(fileDescriptor);		
	} else { /* IMAGE_TYPE_PRO */
		pro_additional_info_t *info;
		pro_phantom_sec_info_t *phantom;
		unsigned char *count;
		AtrDiskInfo *disk = diskInfo[unit-1];
		FILE *f = disk->file;
		
		disk->io_success = -1;
		size = [self seekSector:disk:sector];
		info = (pro_additional_info_t *) disk->addedInfo;
		phantom = &info->phantom[sector-1];
		count = info->count;
		fread(sectorBuff, 1, 12, f);
		/* handle duplicate sectors */
		if (phantom->phantom_count != 0) {
			int dupnum = count[sector];
#ifdef DEBUG_PRO
			SioControllerLogPrint("duplicate sector:%d dupnum:%d\n",sector, dupnum);
#endif
			count[sector] = (count[sector]+1) % (phantom->phantom_count+1);
			if (dupnum != 0)  { 
				fseek(f, phantom->sec_offset[dupnum], SEEK_SET);
				/* read sector header */
				fread(sectorBuff, 1, 12, f);
				memcpy(info->sec_stat_buff,sectorBuff,4);
				if (phantom->sec_status[dupnum] != 0xFF) {
					fread(sectorBuff, 1, size, f);
					disk->io_success = sector;
#ifdef DEBUG_PRO
					SioControllerLogPrint("bad sector:%d dupnum %d\n", sector,dupnum);
#endif
					[self microDelay:COMPLETE_WAIT];
					[self sendAck:'E'];
					SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
					return;
				}
			} 
		} else {
			/* bad sector */
			if (sectorBuff[1] != 0xff) {
				memcpy(info->sec_stat_buff,sectorBuff,4);
				fread(sectorBuff, 1, size, f);
				disk->io_success = sector;
#ifdef DEBUG_PRO
				SioControllerLogPrint("bad sector:%d\n", sector);
#endif
				[self microDelay:COMPLETE_WAIT];
				[self sendAck:'E'];
				[self microDelay:POST_COMP_WAIT];
				sectorBuff[size] = [self checksum:sectorBuff:size];
				[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
				SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
				tcdrain(fileDescriptor);
				return;
			}
		}
		[self microDelay:COMPLETE_WAIT];
		[self sendAck:'C'];
		[self microDelay:POST_COMP_WAIT];
		if (sector < 4)
			size = 128;
		else
			size = disk->sectorSize;
		fread(sectorBuff, 1, size, disk->file);
		sectorBuff[size] = [self checksum:sectorBuff:size];
		[self writeBlocks:sectorBuff:size+1:XMIT_BLOCK_SIZE];
		disk->io_success = 0;
		SioControllerLogPrint("Disk %d Read sector %d\n",unit,(int) sector);
		tcdrain(fileDescriptor);
	}
}

- (void) processDiskHappyReadCommand:(int) unit: (UInt8 *) cmd
{
	[self sendAck:'N'];
}

- (void) processDiskStatusCommand:(int) unit: (UInt8 *) cmd
{
    DRIVE_STATUS_MSG diskStatus;
	UInt8 *Buffer = (UInt8 *) &diskStatus;
        
    if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d DiskStatus - Drive Off\n",unit);
		if (enable850 && unit==1) {
			[self microDelay:ACK_WAIT];
			[self sendAck:'A'];
			[self microDelay:COMPLETE_WAIT];
			diskStatus.deviceStatus = DEVS_MOTOR_ON;
			diskStatus.hwStatus = 255;
			diskStatus.timeout = 1;
			diskStatus.unused = 0;
			diskStatus.checksum = [self checksum:Buffer:sizeof(DRIVE_STATUS_MSG)-1];
			[self sendAck:'C'];
			write(fileDescriptor,Buffer,sizeof(DRIVE_STATUS_MSG));
			tcdrain(fileDescriptor);
			SioControllerLogPrint("850 DiskStatus\n");
			}
        return;
		}
	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];

	// TBD need to check this with real disk 
    if (driveState[unit-1] == DRIVE_NO_DISK) {
		diskStatus.deviceStatus = DEVS_MOTOR_ON;
		diskStatus.hwStatus = 255 & ~DEVS_HW_NOT_READY;
		diskStatus.timeout = 1;
		diskStatus.unused = 0;
		}
    else { 
		if (diskInfo[unit-1]->io_success != 0  && diskInfo[unit-1]->imageType == IMAGE_TYPE_PRO &&
			driveState[unit-1] != DRIVE_NO_DISK) {
			pro_additional_info_t *info;
			info = (pro_additional_info_t *)  diskInfo[unit-1]->addedInfo;
			diskStatus.deviceStatus = info->sec_stat_buff[0];
			diskStatus.hwStatus = info->sec_stat_buff[1];
			diskStatus.timeout = info->sec_stat_buff[2];
			diskStatus.unused = info->sec_stat_buff[3];
		} else if (diskInfo[unit-1]->io_success != 0  && diskInfo[unit-1]->imageType == IMAGE_TYPE_VAPI &&
				   driveState[unit-1] != DRIVE_NO_DISK) {
			vapi_additional_info_t *info;
			info = (vapi_additional_info_t *)  diskInfo[unit-1]->addedInfo;
			diskStatus.deviceStatus = info->sec_stat_buff[0];
			diskStatus.hwStatus = info->sec_stat_buff[1];
			diskStatus.timeout = info->sec_stat_buff[2];
			diskStatus.unused = info->sec_stat_buff[3];
		} else {
			diskStatus.deviceStatus = DEVS_MOTOR_ON;
			diskStatus.hwStatus = 255;
			if (driveState[unit-1] == DRIVE_READ_ONLY)
				diskStatus.deviceStatus |= DEVS_WRITE_PROTECT; 
			if (diskInfo[unit-1]->sectorSize == 256)
				diskStatus.deviceStatus |= DEVS_DOUBLE_DENSITY;
			if (diskInfo[unit-1]->sectorCount == 1040)
				diskStatus.deviceStatus |= DEVS_ENHANCED_DENSITY;
			diskStatus.timeout = 1;
			diskStatus.unused = 0;
		}
	}
    diskStatus.checksum = [self checksum:Buffer:sizeof(DRIVE_STATUS_MSG)-1];
	[self sendAck:'C'];
	[self microDelay:POST_COMP_WAIT];
#if defined(DEBUG_PRO) || defined(DEBUG_VAPI)
    SioControllerLogPrint("Status %02X %02X %02X %02X %02X %02X \n",
						  Buffer[0],Buffer[1],Buffer[2],Buffer[3],Buffer[4],Buffer[5]);
#endif	
	write(fileDescriptor,Buffer,sizeof(DRIVE_STATUS_MSG));
	tcdrain(fileDescriptor);
    SioControllerLogPrint("Disk %d DiskStatus\n",unit);
}

- (void) processDiskGetConfigCommand:(int) unit: (UInt8 *) cmd
{
    DRIVE_CONFIG_MSG diskConfig;
	UInt8 *Buffer = (UInt8 *) &diskConfig;
	UInt8 tracks = 1;
	UInt8 heads = 1;
	int spt;
        
	if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Disk Get Config - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
	if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Disk Get Config - Error No Disk\n",unit);
        return;
        }
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
        
	spt = diskInfo[unit-1]->sectorCount;
	if (spt % 40 == 0) {
		/* standard disk */
		tracks = 40;
		spt /= 40;
		if (spt > 26 && spt % 2 == 0) {
			/* double-sided */
			heads = 2;
			spt /= 2;
			if (spt > 26 && spt % 2 == 0) {
				/* double-sided, 80 tracks */
				tracks = 80;
				spt /= 2;
      			}
	       	}
		}
	diskConfig.trackCount = tracks;
	diskConfig.stepRate = 3;   // MDG changed to fix MyIDE problem???   
	diskConfig.sectorCountHi = (UInt8) (spt >> 8); 
	diskConfig.sectorCountLo = (UInt8) (spt & 0xFF);      
	diskConfig.headCount = (UInt8) (heads - 1);
	diskConfig.formatId = 
        (diskInfo[unit-1]->sectorSize == 128 && 
         diskInfo[unit-1]->sectorCount <= 720) ? 0 : 4;
	diskConfig.bytesPerSectorHi = 
        (UInt8) (diskInfo[unit-1]->sectorSize >> 8);
	diskConfig.bytesPerSectorLo = 
        (UInt8) (diskInfo[unit-1]->sectorSize & 0xFF);
	diskConfig.bitfield = DEVC_DEVICE_ACTIVATED; 
	diskConfig.unused[0] = 192;
	diskConfig.unused[1] = 0;
	diskConfig.unused[2] = 0;
    diskConfig.checksum = 
		[self checksum:Buffer:sizeof(DRIVE_CONFIG_MSG)-1];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,sizeof(DRIVE_CONFIG_MSG));
	tcdrain(fileDescriptor);
	SioControllerLogPrint("Disk %d Disk Get Config\n",unit);
}

- (void) processDiskSetConfigCommand:(int) unit: (UInt8 *) cmd
{
	DRIVE_CONFIG_MSG diskConfig;
	UInt8 *Buffer = (UInt8 *) &diskConfig;
	int i;
        
    if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Disk Set Config - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_NO_DISK) {
		SioControllerLogPrint("Disk %d Disk Set Config - Error No Disk\n",unit);
		[self sendAck:'N'];
        return;
        }
	[self sendAck:'A'];
	for (i=0;i<13;i++)
		read(fileDescriptor,&Buffer[i],1);
	if (Buffer[12] != [self checksum:Buffer:12]) {
		[self sendAck:'N'];
		SioControllerLogPrint("Disk %d Disk Set Config - Error Bad Checksum\n",unit);
		return;
		}
    // We don't do anything with the data from the command
	[self sendAck:'A'];
	[self sendAck:'C'];
	SioControllerLogPrint("Disk %d Disk Set Config\n",unit);
}

- (void) processDiskHappyConfigCommand:(int) unit: (UInt8 *) cmd
{  
#if 0     
	if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Disk Happy Config - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
	if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Disk Happy Config - Error No Disk\n",unit);
        return;
        }
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
	[self sendAck:'C'];
	SioControllerLogPrint("Disk %d Disk Happy Config\n",unit);
#else
	[self sendAck:'N'];
#endif	
}

- (void) processDiskFormatCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 formatBuff[257];

	if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Format - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Format - Error No Disk\n",unit);
        return;
        }
	if (diskInfo[unit-1]->directory) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Format - Error Can't format a Sharepoint\n",unit);
        return;
		}
	[self sendAck:'A'];
//    [self zeroSectors:unit-1];
	[self microDelay:COMPLETE_WAIT];
	[self sendAck:'C'];
	[self microDelay:POST_COMP_WAIT];
    memset(formatBuff,0,256);
    formatBuff[0] = 0xFF;
    formatBuff[1] = 0xFF;
    if (diskInfo[unit-1]->sectorSize == 128)  {
	    formatBuff[128] = [self checksum:formatBuff:128];
		[self writeBlocks:formatBuff:129:XMIT_BLOCK_SIZE];
        }
    else {
	    formatBuff[256] = [self checksum:formatBuff:256];
		[self writeBlocks:formatBuff:257:XMIT_BLOCK_SIZE];
        }
	tcdrain(fileDescriptor);
	SioControllerLogPrint("Disk %d Format\n",unit);
}

- (void) processDiskFormatEDCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 formatBuff[129];

	if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Format ED - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
	if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Format ED - Error No Disk\n",unit);
        return;
        }
	if (diskInfo[unit-1]->directory) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Format ED - Error Can't format a Sharepoint\n",unit);
        return;
		}
	[self sendAck:'A'];
//    [self zeroSectors:unit-1];
	[self microDelay:COMPLETE_WAIT];
	[self sendAck:'C'];
	[self microDelay:POST_COMP_WAIT];
    memset(formatBuff,0,129);
    formatBuff[0] = 0xFF;
    formatBuff[1] = 0xFF;
    formatBuff[128] = [self checksum:formatBuff:128];
	[self writeBlocks:formatBuff:129:XMIT_BLOCK_SIZE];
	tcdrain(fileDescriptor);
	SioControllerLogPrint("Disk %d Format ED\n",unit);
}

- (void) processDiskHighSpeedCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 Buffer[2];
        
    if (driveState[unit-1] == DRIVE_POWER_OFF) {
		SioControllerLogPrint("Disk %d Disk High Speeed - Error Drive Off\n",unit);
        return;
		}
	[self microDelay:ACK_WAIT];
    if (driveState[unit-1] == DRIVE_NO_DISK) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Disk High Speeed - Error No Disk\n",unit);
        return;
        }
    if (maxSpeed == 1) {
	    [self sendAck:'N'];
		SioControllerLogPrint("Disk %d Disk High Speeed - Error High Speed Disabled\n",unit);
        return;
        }
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
        
    Buffer[0] = (maxSpeed==2)?0x10:0x08;
    Buffer[1] = Buffer[0];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,2);
	tcdrain(fileDescriptor);
	SioControllerLogPrint("Disk %d Disk High Speeed\n",unit);
    [self setSerialPortSpeed:fileDescriptor:((maxSpeed==2)?2:3)];
}

- (void) outputPrinterByte:(UInt8) byte
{
	if (byte == 0x9b)
		byte = 0x0D;
	if (currPrinter == 0) {
		if (!printerFile)
			{
			strcpy(textFileName,printerOutputDefaultDirectory);
			strcat(textFileName,"/");
			strcat(textFileName,"TextPrint_XXXXXX\0");
			printerFile = fdopen(mkstemp(textFileName), "w");
		    }
		fwrite(&byte, 1, 1, printerFile);
        }
    else 
        PrintOutputControllerPrintChar(byte);             
}

- (IBAction) onResetPrinter:(id)sender
{
	char command[256 + FILENAME_MAX];
	if (printerFile)
		{
		fclose(printerFile);
		printerFile = NULL;
		sprintf(command, printerCommand, textFileName);
		system(command);
		}
}

- (void) printerOffline:(BOOL)isOffline
{
	offline = isOffline;
}

- (void) processPrinterWriteCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 printBuff[41];
	int i;
	
    if (!offline) {
		[self microDelay:ACK_WAIT];
		[self sendAck:'A'];
		for (i=0;i<41;i++)
			read(fileDescriptor,&printBuff[i],1);
		if (printBuff[40] != [self checksum:printBuff:40]) {
			SioControllerLogPrint("Printer Write - Error Bad Checksum\n");
			return;
			}
		for (i=0;i<40;i++) {
			[self outputPrinterByte:printBuff[i]];
			if (printBuff[i] == 0x9b)
				break;
			}
		[self sendAck:'A'];
		[self sendAck:'C'];
		SioControllerLogPrint("Printer Write\n");
		}
	else {
		SioControllerLogPrint("Printer Write - Printer Offline\n");
		}
}

- (void) processApeTimeCommand:(int) unit: (UInt8 *) cmd
{
    UInt8 apeTime[7];
	struct tm *localTime;
	time_t macTime;
        
	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
    
	time(&macTime);
	localTime = localtime(&macTime);
	
	apeTime[0] = localTime->tm_mday;
	apeTime[1] = localTime->tm_mon+1;
	if (localTime->tm_year >= 100)
		localTime->tm_year -= 100;
	apeTime[2] = localTime->tm_year;
	apeTime[3] = localTime->tm_hour;
	apeTime[4] = localTime->tm_min;
	apeTime[5] = localTime->tm_sec;
	apeTime[6] = [self checksum:apeTime:6];
	[self sendAck:'C'];
	write(fileDescriptor,apeTime,7);
	tcdrain(fileDescriptor);
	SioControllerLogPrint("Ape Time Command\n");
}

- (void) processPrinterStatusCommand:(int) unit: (UInt8 *) cmd
{
    DRIVE_STATUS_MSG printerStatus;
	UInt8 *Buffer = (UInt8 *) &printerStatus;

	if (!offline) {
		[self microDelay:ACK_WAIT];
		[self sendAck:'A'];
		[self microDelay:COMPLETE_WAIT];
        
		printerStatus.deviceStatus = 0;
		printerStatus.hwStatus = 0xFF;
		printerStatus.timeout = 1;
		printerStatus.unused = 0;
		printerStatus.checksum = [self checksum:Buffer:sizeof(DRIVE_STATUS_MSG)-1];
		[self sendAck:'C'];
		write(fileDescriptor,Buffer,sizeof(DRIVE_STATUS_MSG));
		tcdrain(fileDescriptor);
		SioControllerLogPrint("Printer %d DeviceStatus\n",unit);
		}
	else {
		SioControllerLogPrint("Printer Write - Printer Offline\n");
		}
}
- (void) process850WriteCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 serialBuff[65];
	int i;

	if (cmd[2] == 0) {
		[self microDelay:ACK_WAIT];
		[self sendAck:'A'];
		[self microDelay:COMPLETE_WAIT];
		[self sendAck:'C'];
		if (concurrentPort = unit-1)
			concurrentMode = NO;
		SioControllerLogPrint("850 %d Exit Concurrent Mode Command\n",unit);
		}
	else {
		[self microDelay:ACK_WAIT];
		[self sendAck:'A'];
		for (i=0;i<65;i++)
			read(fileDescriptor,&serialBuff[i],1);
		if (serialBuff[64] != [self checksum:serialBuff:64]) {
			SioControllerLogPrint("850 %d Block Write - Error Bad Checksum\n",unit);
			return;
			}
		[self sendAck:'A'];
		[self sendAck:'C'];
		SioControllerLogPrint("850 %d Block Write Command\n",unit);
		if (port850Mode[unit-1] == PORT_850_NET_MODE &&	netATMode) {
			for (i=0;i<cmd[2];i++) {
				[self modemATModeProcess:serialBuff[i]];
				}
			}
		else {
			if (port850fd[unit-1] != -1) 
				write(port850fd[unit-1],serialBuff,cmd[2]);
			}
		}
}

- (void) process850StatusCommand:(int) unit: (UInt8 *) cmd
{
    A850_STATUS_MSG a850Status;
	UInt8 *Buffer = (UInt8 *) &a850Status;

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
    
	a850Status.lineState = 0x0;
	// We don't have a way of reporting errors
	a850Status.errors = 0;
	
	if (dsrLast[unit-1]) {
		a850Status.lineState |= 0x40;
		}
	if (ctsLast[unit-1]) {
		a850Status.lineState |= 0x10;
		}
	if (crxLast[unit-1]) {
		a850Status.lineState |= 0x04;
		}
	
	if (port850Mode[unit-1] == PORT_850_SERIAL_MODE) {
	    if (port850fd[unit-1] != -1) {
			int status;
			
			status = 0;
			if (ioctl(port850fd[unit-1], TIOCMGET, &status) == -1)
				{
				SioControllerLogPrint("850 Serial - Error getting handshake lines for 850 port %d\n",unit);
				}
			if (status & TIOCM_DSR) {
				dsrLast[unit-1] = YES;
				}
			else {
				dsrLast[unit-1] = NO;
				}
			if (status & TIOCM_CTS) {
				ctsLast[unit-1] = YES;
				}
			else {
				ctsLast[unit-1] = NO;
				}
			if (status & TIOCM_CD) {
				crxLast[unit-1] = YES;
				}
			else {
				crxLast[unit-1] = NO;
				}
			}
		else {
			dsrLast[unit-1] = NO;
			ctsLast[unit-1] = NO;
			crxLast[unit-1] = NO;
			}
		}
	else if (port850Mode[unit-1] == PORT_850_NET_MODE) {
		dsrLast[unit-1] = YES;
		ctsLast[unit-1] = YES;
		if (netCarrierDetected) {
			crxLast[unit-1] = YES;
			}
		else {
			crxLast[unit-1] = NO;
			}	
		}
	else {
		dsrLast[unit-1] = NO;
		ctsLast[unit-1] = NO;
		crxLast[unit-1] = NO;
		}
		
	if (dsrLast[unit-1]) {
		a850Status.lineState |= 0x80;
		}
	if (ctsLast[unit-1]) {
		a850Status.lineState |= 0x20;
		}
	if (crxLast[unit-1]) {
		a850Status.lineState |= 0x08;
		}

	a850Status.checksum = [self checksum:Buffer:sizeof(A850_STATUS_MSG)-1];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,sizeof(A850_STATUS_MSG));
	tcdrain(fileDescriptor);
	SioControllerLogPrint("850 %d DeviceStatus %02x\n",unit,a850Status.lineState);
}

- (void) process850ConcurrentCommand:(int) unit: (UInt8 *) cmd
{
	CONCURRENT_RESP_MSG concurrentResponse;
	UInt8 *Buffer = (UInt8 *) &concurrentResponse;
	UInt16 pokeyValue;

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
	
	// Lie to the Atari, and always keep it at 19200, since unlike the 850,
	// we don't just wire the serial port to the computer, but actually process
	// the values.
	pokeyValue = 0x0029;  
	
	concurrentResponse.audf1 = (pokeyValue & 0xff);
	concurrentResponse.audctl1 = 0xa0;
	concurrentResponse.audf2 = (pokeyValue >> 8);
	concurrentResponse.audctl2 = 0xa0;
	concurrentResponse.audf3 = (pokeyValue & 0xff);
	concurrentResponse.audctl3 = 0xa0;
	concurrentResponse.audf4 = (pokeyValue >> 8);
	concurrentResponse.audctl4 = 0xa0;
	concurrentResponse.audioctl = 0x78;
	concurrentResponse.checksum = [self checksum:Buffer:sizeof(CONCURRENT_RESP_MSG)-1];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,sizeof(CONCURRENT_RESP_MSG));
	tcdrain(fileDescriptor);

	// TBD, need to test what happens if we are in 2 or 3x speed up for disks.
	concurrentMode = YES;
	concurrentPort = unit-1;
	SioControllerLogPrint("850 %d Concurrent Mode Command\n",unit);
}

- (void) process850BaudCommand:(int) unit: (UInt8 *) cmd
{
	static int baudRates [16] = 
		{B300,45,B50,57,B75,B110,B134,B150,B300,B600,B1200,B1800,B2400,B4800,B9600,B19200};

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
    
	[self sendAck:'C'];
	
	if (cmd[2] & 0x80)
		stopBits850[unit-1] = 2;
	else
		stopBits850[unit-1] = 1;
	
	switch(cmd[2] & 0x30) {
		case 0x00:
			bits850[unit-1] = 8;
			break;
		case 0x10:
			bits850[unit-1] = 7;
			break;
		case 0x20:
			bits850[unit-1] = 6;
			break;
		case 0x30:
			bits850[unit-1] = 5;
			break;
		}
		
	baud850[unit-1] = baudRates[cmd[2] & 0x0f];
	
	if (cmd[3] & 0x04)
		dsrHandshake850[unit-1] = YES;
	else
		dsrHandshake850[unit-1] = NO;
	if (cmd[3] & 0x02)
		ctsHandshake850[unit-1] = YES;
	else
		ctsHandshake850[unit-1] = NO;

	if (port850Mode[unit-1] == PORT_850_SERIAL_MODE &&
	    port850fd[unit-1] != -1) {
		struct termios	options;
    
		// Get the current options and save them for later reset
		if (tcgetattr(port850fd[unit-1], &options) == -1)
			{
			SioControllerLogPrint("process850BaudCommand %d - Error getting tty attributes - %s(%d).\n",
				unit,strerror(errno), errno);
			return;
			}	
	    
		cfsetospeed(&options,baud850[unit-1]);
		cfsetispeed(&options,baud850[unit-1]);
		
		options.c_cflag = (CREAD | CLOCAL);
	    switch(bits850[unit-1]) {
			case 8:
				options.c_cflag |= CS8;
				break;
			case 7:
				options.c_cflag |= CS7;
				break;
			case 6:
				options.c_cflag |= CS6;
				break;
			case 5:
				options.c_cflag |= CS5;
				break;
			}
		
		if(stopBits850[unit-1] == 2) {
			options.c_cflag |= CSTOPB;
			}

		if (tcsetattr(port850fd[unit-1], TCSAFLUSH, &options) == -1)
			{
			SioControllerLogPrint("process850BaudCommand %d - Error resetting tty attributes - %s(%d).\n",
				unit,strerror(errno), errno);
			}
		}
	
	SioControllerLogPrint("850 %d Baud Command %d %d %d %d %d\n",unit,
						  baud850[unit-1], bits850[unit-1], stopBits850[unit-1],
						  dsrHandshake850[unit-1],ctsHandshake850[unit-1]);
}

- (void) process850AttributesCommand:(int) unit: (UInt8 *) cmd
{
	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];
    
	[self sendAck:'C'];
	// only take action if we are hooked up to a serial port
	if (port850Mode[unit-1] == PORT_850_SERIAL_MODE &&
		port850fd[unit-1] != -1) {
		int status=0;
		if (ioctl(port850fd[unit-1], TIOCMGET, &status) == -1)
			{
			SioControllerLogPrint("850 Serial - Error getting handshake lines for 850 port %d\n",unit);
			}
		
		if (cmd[2] & 0x80) {
			if (cmd[2] & 0x40) {
				status |= TIOCM_DTR;
				}
			else {
				status &= ~TIOCM_DTR;
				}
			}
		
		if (cmd[2] & 0x20) {
			if (cmd[2] & 0x10) {
				status |= TIOCM_RTS;
				}
			else {
				status &= ~TIOCM_RTS;
				}
			}
				
		if (ioctl(port850fd[unit-1], TIOCMSET, &status) == -1)
			{
			SioControllerLogPrint("850 Serial - Error setting handshake lines for 850 port %d\n",unit);
			}
		}
	else if (port850Mode[unit-1] == PORT_850_NET_MODE) {
		if (cmd[2] & 0x80) {
			if ((cmd[2] & 0x40)) {
				netTerminalReady = YES;
				}
			else {
				netTerminalReady = NO;
				if (netCarrierDetected) {
					close(port850fd[unit-1]);
					port850fd[unit-1] = -1;
					netCarrierDetected = NO;
					}
				}
			}
		}
	SioControllerLogPrint("850 %d Attributes Command %x\n",unit,cmd[2]);
}

- (void) process850PollCommand:(int) unit: (UInt8 *) cmd
{
	A850_POLL_RESPONSE pollResponse;	
	UInt8 *Buffer = (UInt8 *) &pollResponse;

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];

	pollResponse.msg[0] = 0x50;
	pollResponse.msg[1] = 1;
	pollResponse.msg[2] = '!';
	pollResponse.msg[3] = 0x40;
	pollResponse.msg[4] = 0x00;
	pollResponse.msg[5] = 0x05;
	pollResponse.msg[6] = 2;
	pollResponse.msg[7] = 0;
	pollResponse.msg[8] = (sizeof(bootHandler850)-1) & 0xff;
	pollResponse.msg[9] = (sizeof(bootHandler850)-1) >> 8;
	pollResponse.msg[10] = 0;
	pollResponse.msg[11] = 0;

	pollResponse.checksum = [self checksum:Buffer:12];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,13);
	tcdrain(fileDescriptor);
	SioControllerLogPrint("850 Poll\n");
}

- (void) process850BootCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 *Buffer = (UInt8 *) &bootHandler850;
	int bootSize = sizeof(bootHandler850)-1;

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];

	Buffer[bootSize] = [self checksum:Buffer:bootSize];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,bootSize+1);
	tcdrain(fileDescriptor);
	SioControllerLogPrint("850 Boot\n");
}

- (void) process850HandlerCommand:(int) unit: (UInt8 *) cmd
{
	UInt8 *Buffer = (UInt8 *) &deviceHandler850;
	int handlerSize = sizeof(deviceHandler850)-1;

	[self microDelay:ACK_WAIT];
	[self sendAck:'A'];
	[self microDelay:COMPLETE_WAIT];

	Buffer[handlerSize] = [self checksum:Buffer:handlerSize];
	[self sendAck:'C'];
	write(fileDescriptor,Buffer,handlerSize+1);
	tcdrain(fileDescriptor);
	SioControllerLogPrint("850 Handler\n");
}

- (void) processInvalidCommand:(int) unit: (UInt8 *) cmd
{
	[self microDelay:ACK_WAIT];
	[self sendAck:'N'];
	SioControllerLogPrint("Invalid Command %02x %02x %02x %02x %02x\n",
							 cmd[0],cmd[1],cmd[2],cmd[3],cmd[4]);
}

- (void) processCommand:(UInt8 *) cmd
{
	int unit = cmd[0] - '0';
//	printf("recv cmd unit %d ('%c'=0x%x), cmd %x %x %x\n",unit,cmd[0],cmd[0],cmd[1],cmd[2],cmd[3]);

	[mutex lock];
	if (unit >=1 && unit <=8) {
		switch(cmd[1]) {
			case 'R':
				[self processDiskReadCommand:unit:cmd];
				break;
			case 'W':
			case 'P':
				[self processDiskWriteCommand:unit:cmd];
				break;
			case 'S':
				[self processDiskStatusCommand:unit:cmd];
				break;
			case 'H':
				[self processDiskHappyConfigCommand:unit:cmd];
				break;
			case 'N':
				[self processDiskGetConfigCommand:unit:cmd];
				break;
			case 'O':
				[self processDiskSetConfigCommand:unit:cmd];
				break;
			case '!':
				[self processDiskFormatCommand:unit:cmd];
				break;
			case '"':
				[self processDiskFormatEDCommand:unit:cmd];
				break;
			case '?':
				[self processDiskHighSpeedCommand:unit:cmd];
				break;
 			case 'r':
				[self processDiskHappyReadCommand:unit:cmd];
				break;
			case 'w':
				[self processDiskHappyWriteCommand:unit:cmd];
				break;
			case 0x93:
				[self processApeTimeCommand:unit:cmd];
				break;
			default:
				[self processInvalidCommand:unit:cmd];
				break;
		}
	}
	else if (unit==16 || unit==17) {
		switch(cmd[1]) {
			case 'W':
			case 'P':
				[self processPrinterWriteCommand:unit:cmd];
				break;
			case 'S':
				[self processPrinterStatusCommand:unit:cmd];
				break;
			default:
				[self processInvalidCommand:unit:cmd];
				break;
			}
	}
	else if (unit==21) {
		switch(cmd[1]) {
			case 0x93:
				[self processApeTimeCommand:unit:cmd];
				break;
			}
	}
	else if (enable850 && (unit>=32 && unit<=35)) {
		unit -= 31;
		switch(cmd[1]) {
			case 'W':
				[self process850WriteCommand:unit:cmd];
				break;
			case 'S':
				[self process850StatusCommand:unit:cmd];
				break;
			case 'X':
				[self process850ConcurrentCommand:unit:cmd];
				break;
			case 'B':
				[self process850BaudCommand:unit:cmd];
				break;
			case 'A':
				[self process850AttributesCommand:unit:cmd];
				break;
			case '?':
				[self process850PollCommand:unit:cmd];
				break;
			case '!':
				[self process850BootCommand:unit:cmd];
				break;
			case '&':
				[self process850HandlerCommand:unit:cmd];
				break;
			default:
				[self processInvalidCommand:unit:cmd];
				break;
			}
	}
	else {
	}
    [mutex unlock];
}

- (BOOL) isExpired
{
	struct tm *localTime;
	time_t macTime;
        
	time(&macTime);
	localTime = localtime(&macTime);
	
	if ((localTime->tm_year > 106) ||
	     ((localTime->tm_year == 106) &&
		 (((localTime->tm_mon == 0) && (localTime->tm_mday > 29)) ||
		  (localTime->tm_mon > 0))))
		return YES;
	else
		return NO;
}

- (void) runDiskServer;
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UInt8 Buffer[256];
    UInt8 sum;
    int status;
    int status2;
	int i;
	int badCount = 0;
	int readCount;
	unsigned long mics = 1UL;
	fd_set readSet;	
	struct timeval timeout;
	int escapeCount = 0;
	
	[NSThread setThreadPriority:1.0];
	while(1)
		{
		// Turn off RTS so that we work with the Atarimax Adapter.
		if (ioctl(fileDescriptor, TIOCMGET, &status) == -1)
		    {
			printf("Error getting handshake lines to turn off RTS %s - %s(%d).\n",
					bsdPaths[0], strerror(errno), errno);
			}
				
		status2 = status & ~TIOCM_RTS;
		if (ioctl(fileDescriptor, TIOCMSET, &status2) == -1)
		    {
			printf("Error setting handshake lines to turn off RTS %s - %s(%d).\n",
					bsdPaths[0], strerror(errno), errno);
			}
		if (ioctl(fileDescriptor, IOSSDATALAT, &mics) == -1)
			{
			// set latency to 1 microsecond
			printf("Error setting read latency %s - %s(%d).\n",
				bsdPaths[0], strerror(errno), errno);
			}
				
		SioControllerLogPrint("Waiting for Command...\n");
		while(1)
			{
			if (concurrentMode) {
			while(1) {
				if (diskServerPause) {
					while(diskServerPause)
						usleep(500);
					}
				if (ioctl(fileDescriptor, TIOCMGET, &status) == -1)
				    {
					status = 0;
					}
				if (!enable850)
					break;
				if (sioHWType == 0) {
					if (status & TIOCM_RNG) {
						break;
						}
					}
				else if (sioHWType == 1) {
					if (status & TIOCM_DSR)
						break;
					}
				else {
					if (status & TIOCM_CTS)
						break;
					}
				FD_ZERO(&readSet);
				FD_SET(fileDescriptor,&readSet);

				if (port850fd[concurrentPort] != -1) {
					FD_SET(port850fd[concurrentPort],&readSet);
					}
				timeout.tv_sec = 0;
				timeout.tv_usec = 0;
				readCount = select(MAX(fileDescriptor,port850fd[concurrentPort])+1,&readSet,NULL,NULL,&timeout);
				if (readCount != 0) {
					if (FD_ISSET(fileDescriptor,&readSet)) {
						read(fileDescriptor, Buffer, 1);
						if (port850Mode[concurrentPort] == PORT_850_NET_MODE && netATMode) {
							[self modemATModeProcess:Buffer[0]];
							}
						else if (port850fd[concurrentPort] != -1) {
							if (modemEscapeCharacter != 255) {
								if (Buffer[0] == modemEscapeCharacter) 
									escapeCount++;
								else
									escapeCount == 0;
								if (escapeCount == 3) {
									netATMode = YES;
									escapeCount = 0;
									[self modemSendOK];
									}
								else
									write(port850fd[concurrentPort] , Buffer, 1);
								}
							else
								write(port850fd[concurrentPort] , Buffer, 1);
							}
						}
					if (port850fd[concurrentPort] != -1) {
						if (FD_ISSET(port850fd[concurrentPort],&readSet)) {
							int count; 
							
							count = read(port850fd[concurrentPort], Buffer, 1);
							if (count == 0) {
								close(port850fd[concurrentPort]);
								port850fd[concurrentPort] = -1;
								netCarrierDetected = FALSE;
								SioControllerLogPrint("Internet Modem - Remote Connection Closed\n");
								netATMode = YES;
								[self modemSendNoCarrier];
								}
							else if (port850Mode[concurrentPort] == PORT_850_SERIAL_MODE || !netATMode) {
								write(fileDescriptor , Buffer, 1);
								tcdrain(fileDescriptor);
								}
							}
						}
					}
				usleep(500);
				if (modemChanged)
					break;
				for (i=0;i<NUMBER_OF_ATARI_DRIVES;i++) {
					if (ledPersistence[i]) {
						ledPersistence[i]--;
						if (ledPersistence[i] == 0) {
							[offUpdate setState:i:0:0];
							[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateLed:) 
															withObject:offUpdate waitUntilDone:NO];
							}
						}
					}
				}
			if (modemChanged)
				break;
			tcflush(fileDescriptor ,TCIFLUSH); /* Clear out pre-command garbage */
			for (i=0;i<5;i++)
				readCount = read(fileDescriptor, &Buffer[i], 1);
			if (readCount == 1) {
				sum = [self checksum:Buffer:4];
				if (sum == Buffer[4]) {
					[self processCommand:Buffer];
					badCount = 0;
					}
				else { 
					SioControllerLogPrint("Command Checksum Error %02x %02x %02x %02x %02x, check %02x\n",
						Buffer[0],Buffer[1],Buffer[2],Buffer[3],Buffer[4],sum);
					badCount++;
					if (badCount == 2) {
						if (currentSpeed == maxSpeed)
							[self setSerialPortSpeed:fileDescriptor:1];
						else
							[self setSerialPortSpeed:fileDescriptor:maxSpeed];
						badCount = 0;
						}
					}
				}
			} else {
			while(1)
				{
				if (diskServerPause) {
					while(diskServerPause)
						usleep(500);
					}
				if (ioctl(fileDescriptor, TIOCMGET, &status) == -1)
				    {
					status = 0;
					}
				if (sioHWType == 0) {
					if (status & TIOCM_RNG) {
						break;
						}
					}
				else if (sioHWType == 1) {
					if (status & TIOCM_DSR)
						break;
					}
				else {
					if (status & TIOCM_RTS)
						break;
					}
				usleep(500);
				if (modemChanged)
					break;
				for (i=0;i<NUMBER_OF_ATARI_DRIVES;i++) {
					if (ledPersistence[i]) {
						ledPersistence[i]--;
						if (ledPersistence[i] == 0) {
							[offUpdate setState:i:0:0];
							[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateLed:) 
															withObject:offUpdate waitUntilDone:NO];
							}
						}
					}
				}
			if (modemChanged)
				break;
			tcflush(fileDescriptor ,TCIFLUSH); /* Clear out pre-command garbage */
			for (i=0;i<5;i++)
				readCount = read(fileDescriptor, &Buffer[i], 1);
			if (readCount == 1) {
				sum = [self checksum:Buffer:4];
				if (sum == Buffer[4]) {
					[self processCommand:Buffer];
					badCount = 0;
					}
				else { 
					SioControllerLogPrint("Command Checksum Error %02x %02x %02x %02x %02x, check %02x\n",
						Buffer[0],Buffer[1],Buffer[2],Buffer[3],Buffer[4],sum);
					badCount++;
					if (badCount == 2) {
						if (currentSpeed == maxSpeed)
							[self setSerialPortSpeed:fileDescriptor:1];
						else
							[self setSerialPortSpeed:fileDescriptor:maxSpeed];
						badCount = 0;
						}
					}
				}
				}
			}
		if (modemCount == 0)
			[self closeSerialPort:fileDescriptor:NO];
		else
			[self closeSerialPort:fileDescriptor:YES];
		SioControllerLogPrint("Modem port closed.\n");
		modemChanged = NO;
		
		if (modemCount == 0) {
			diskServerExited = YES;
			[NSThread exit];
			}

		fileDescriptor = [self openSerialPort:bsdPaths[modemIndex]:B19200];
		if (-1 == fileDescriptor)
			return;
	
		// Save the serial port name for next time
		strcpy(serialPort, bsdPaths[modemIndex]);
	
		[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(displaySpeed:) 
								withObject:[NSNumber numberWithInt:19200] waitUntilDone:NO];
		}
    
    [pool release];
}

- (void) runNetServer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int newsockfd;
	unsigned int clilen;
    struct sockaddr_in serv_addr, cli_addr;
	int on=1;

    netServerFd = socket(AF_INET, SOCK_STREAM, 0);
    if (netServerFd < 0) {
		SioControllerLogPrint("Internet Modem - Error Creating Server Socket\n");
		return;
		}

	setsockopt(netServerFd, SOL_SOCKET, SO_REUSEPORT, &on, sizeof(on));
		
     bzero((char *) &serv_addr, sizeof(serv_addr));
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = INADDR_ANY;
     serv_addr.sin_port = htons(netServerNetPort);
     if (bind(netServerFd, (struct sockaddr *) &serv_addr,
              sizeof(serv_addr)) < 0) {
			  SioControllerLogPrint("Internet Modem - Error Binding Server Socket\n");
			  while (1) {
				if (netServerExit) {
					netServerExited = TRUE;
					netServerStarted = FALSE;
					netServerFd = -1;
					SioControllerLogPrint("Internet Modem - Server Exiting\n");
					[NSThread exit];
					}
				usleep(10000);
			}
		}
 	 
	 SioControllerLogPrint("Internet Modem - Server Starting Port %d\n",netServerNetPort);
	 while (1) {
		int on = TRUE;

		listen(netServerFd,1);
		ioctl(netServerFd,FIONBIO, &on);
		newsockfd = -1;
		
		clilen = sizeof(cli_addr);
		while (newsockfd == -1) {
			if (netServerExit) {
				netServerExited = TRUE;
				netServerStarted = FALSE;
				close(netServerFd);
				netServerFd = -1;
				SioControllerLogPrint("Internet Modem - Server Exiting\n");
				[NSThread exit];
				}
			newsockfd = accept(netServerFd, 
								(struct sockaddr *) &cli_addr, 
								&clilen);
		
			if (newsockfd != -1)
				usleep(10000);
		}
		if (!netTerminalReady) {
			write(newsockfd,netServerNotReadyMessage,strlen(netServerNotReadyMessage));
			close(newsockfd);
			continue;
			}
			
		if (netCarrierDetected) {
			write(newsockfd,netServerBusyMessage,strlen(netServerBusyMessage));
			close(newsockfd);
			continue;
			}
	
		port850fd[netServerPort] = newsockfd;
		netCarrierDetected = YES;
		[self modemSendString:"RING\n"];
		SioControllerLogPrint("Internet Modem - Server Accepting Call\n");
		if (modemAutoAnswer) {
			SioControllerLogPrint("Internet Modem - Auto Answer\n");
			[self modemSendConnect];
			netATMode = NO;
			}
		}

    [pool release];
}

- (void) modemSendOK
{
	[self modemSendString:"\nOK\n"];
}

- (void) modemSendError
{
	write(fileDescriptor,"\nERROR\n",9);
	tcdrain(fileDescriptor);
}

- (void) modemSendNoCarrier
{
	[self modemSendString:"\nNO CARRIER\n"];
}

- (void) modemSendConnect
{
		char connectMsg[80];

		sprintf(connectMsg, "\nCONNECT %d\n", baud850[netServerPort]);
		[self modemSendString:connectMsg];
}

- (void) modemSendString:(char *)string
{
	int count = strlen(string);
	int i;
	static char cr=0x0d;
	static char lf=0x0a;
	static char atcr=0x9b;

	for (i=0;i<count;i++) {
		if (string[i] == '\n') {
			if (modemAtascii) {
				write(fileDescriptor,&atcr,1);
				tcdrain(fileDescriptor);
				usleep(500);
				}
			else {
				write(fileDescriptor,&cr,1);
				tcdrain(fileDescriptor);
				usleep(500);
				write(fileDescriptor,&lf,1);
				tcdrain(fileDescriptor);
				usleep(500);
				}
			}
		else {
			write(fileDescriptor,&string[i],1);
			tcdrain(fileDescriptor);
			usleep(500);
			}
		}
}

- (void) modemDisplayStored
{
	int i;
	char Buffer[STORED_ADDR_LEN+4+6+1];
	
	[self modemSendString:"\nLoc Address\n"];
	[self modemSendString:"--- -----------------------------------\n"];
	
	[self modemSendString:"\n"];
	tcdrain(fileDescriptor);
	for (i=0;i<NUM_STORED_NAMES;i++) {
		if (storedNameInUse[i]) {
			sprintf(Buffer,"%3d %s %d\n",i+1,storedNameAddr[i],storedNamePort[i]);
			[self modemSendString:Buffer];
			}
		}
}

- (void) modemSendHelp
{
	char modemHelp[] = 
	"\nSIO2OSX Internet Modem Commands:\n"
        "ATA    : Answer (if auto-answer off)\n"
	"ATDP   : Dial stored host (ATDP HOST#)\n"
	"ATD    : Dial host by name [port]\n"
	"ATDT   : Dial host by name [port]\n"
	"ATEn   : Turn Echo On/Off(0=off,1=on)\n"
	"ATH    : Hang up any active connection\n"
	"ATI    : This information\n"
	"ATK    : Kill listening server\n"
	"ATO    : Resume active connection.\n"
	"ATR    : Restart server if enabled\n"
	"ATSn=  : Program modem register \"n\".\n"
	"         n=0 AutoAnswer 0=Off 1=On\n"
	"         n=2 Escape Char 0-127=Char\n"
	"                         255=Off\n"
	"ATZ    : Reset Modem\n"
	"AT&F   : Full reset of Internet Modem\n"
	"AT&V   : Display stored host names\n"
	"AT&Zn= : Store host name. (n = 1-20)\n"
	"+++    : Escape to terminal mode\n";
	
	[self modemSendString:modemHelp];
}

- (char *) modemParseNamePort:(char *)string:(UInt16 *)port
{
	char *name = string;

	if (*name == 0)
		return(NULL);
	
	while (*name == ' ' || *name == '\t') {
		name++;
		if (*name == 0)
			return(NULL);
		}
		
	string = name;
	
	while (*string != 0 && *string != ' ' && *string != '\t') {
		string ++;
		}
		
	if (*string == 0) {
		*port = 23;
		}
	else {
		*port = atoi(string);
		string[0] = 0;
		if (*port == 0)
			*port = 23;
		}
	return(name);
}

- (BOOL) modemDial:(char *)address:(UInt16)port
{
    struct sockaddr_in serv_addr;
    struct hostent *server;
	int sockfd;
   
	SioControllerLogPrint("Internet Modem - Dialing %d:%d\n",address,port);
	// TBD this probably should occur in a seperate thread.
	// TBD what about delays for bobterm dialing.
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
		[self modemSendNoCarrier];
		return(NO);
		}
    server = gethostbyname(address);
    if (server == NULL) {
		[self modemSendNoCarrier];
		return(NO);
		}
    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    bcopy((char *)server->h_addr, 
         (char *)&serv_addr.sin_addr.s_addr,
         server->h_length);
    serv_addr.sin_port = htons(port);
    if (connect(sockfd,(const struct sockaddr *)&serv_addr,sizeof(serv_addr)) < 0) { 
		SioControllerLogPrint("Internet Modem - Error Connecting to %s:%d\n",address,port);
		[self modemSendString:"\n"];
		usleep(1000000);
		[self modemSendNoCarrier];
		return(NO);
		}
	else {
		SioControllerLogPrint("Internet Modem - Connected to %s:%d\n",address,port);
		[self modemSendString:"\n"];
		usleep(1000000);
		[self modemSendConnect];
		netATMode = NO;
		netCarrierDetected = YES;
		port850fd[netServerPort] = sockfd;
		return(YES);
		}
}

- (void) modemATModeProcess:(unsigned char) c
{
	static char Buffer[256+5];
	
	if (modemEcho && concurrentMode) {
		write(fileDescriptor,&c,1);
		if (c == 0x0d) {
			unsigned char lf=0x0a;
			write(fileDescriptor,&lf,1);
			}
		tcdrain(fileDescriptor);
		}
	
	if (c == 0x08 || c==0x7e) {
		modemCharCount--;
		}
	else {
		Buffer[modemCharCount] = c;
		modemCharCount++;
		}
	
	if (c==0xd || c==0x9b) {
		if (c==0x9b)
			modemAtascii = YES;
		else
			modemAtascii = NO;
		modemCharCount--;
		Buffer[modemCharCount] = 0;
//		printf("Got command '%s'\n",Buffer);
		if (modemCharCount >= 3 && strncmp(Buffer,"ATA",3) == 0) {
			if (netCarrierDetected) {
				SioControllerLogPrint("Internet Modem - Answer\n");
				[self modemSendConnect];
				netATMode = NO;
				}
			else
				[self modemSendOK];
			}
		else if (modemCharCount >= 4 && strncmp(Buffer,"ATDP",4) == 0) {
			int storedNum = atoi(&Buffer[4]);
			if (storedNum > 0 && storedNum <= NUM_STORED_NAMES && storedNameInUse[storedNum-1]) {
				[self modemDial:storedNameAddr[storedNum-1]:storedNamePort[storedNum-1]];
				}
			}
		else if (modemCharCount >= 4 && 
		         ((strncmp(Buffer,"ATDT",4) == 0) || 
				  (strncmp(Buffer,"ATDI",4) == 0))) {
				UInt16 port;
				char *name;
				
				name = [self modemParseNamePort:&Buffer[4]:&port];
				if (name != NULL)
					[self modemDial:name:port];
			}
		else if (modemCharCount >= 3 && 
				  strncmp(Buffer,"ATD ",3) == 0) {
				UInt16 port;
				char *name;
				
				name = [self modemParseNamePort:&Buffer[3]:&port];
				if (name != NULL)
					[self modemDial:name:port];
			}
		else if (modemCharCount >= 3 && 
				  strncmp(Buffer,"ATE ",3) == 0) {
				int param = atoi(&Buffer[3]);
				
				if (param == 0) {
					modemEcho = NO;
					[self modemSendOK];
					}
				else if (param == 1) {
					modemEcho = YES;
					[self modemSendOK];
					}
				else
					[self modemSendError];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATH",3) == 0) {
			SioControllerLogPrint("Internet Modem - Hangup\n");
			if (netCarrierDetected) {
				close(port850fd[netServerPort]);
				port850fd[netServerPort] = -1;
				netCarrierDetected = NO;
				}
			[self modemSendOK];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATO",3) == 0) {
			if (netCarrierDetected) {
				SioControllerLogPrint("Internet Modem - Back Online\n");
				netATMode = NO;
				[self modemSendString:"\n"];
				[self modemSendConnect];
				}
			[self modemSendOK];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATI",3) == 0) {
			[self modemSendHelp];
			[self modemSendOK];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATK",3) == 0) {
			if (netServerStarted) {
				[self stopNetServer];
				if (netCarrierDetected) {
					close(port850fd[netServerPort]);
					port850fd[netServerPort] = -1;
					netCarrierDetected = NO;
					}
				}
			[self modemSendOK];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATR",3) == 0) {
			if (!netServerStarted)
				[self startNetServer];
			[self modemSendOK];
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATS",3) == 0) {
			char *value;
			int reg,regValue;

			value = &Buffer[3];
			while (*value != 0 && *value != '=')
				value++;
			
			if (*value != 0) {
				value++;
				
				regValue = atoi(value);
				reg = atoi(&Buffer[3]);
				SioControllerLogPrint("Internet Modem - Set Register %d to %d\n",reg,regValue);
				if (reg==0) {
					if (regValue == 0) {
						modemAutoAnswer == NO;
						}
					else {
						modemAutoAnswer == YES;
						}
					[self modemSendOK];
					}
				else if (reg==2) {
					if (regValue >=0 && regValue <= 255) {
						if (regValue <= 127) {
							modemEscapeCharacter = regValue;
							}
						else {
							modemEscapeCharacter = 255;
							}
						[self modemSendOK];
						}
					else
						[self modemSendError];
					}
				else
					[self modemSendError];
				}
			}
		else if (modemCharCount >= 3 && strncmp(Buffer,"ATZ",3) == 0) {
			SioControllerLogPrint("Internet Modem - Reset\n");
			if (netCarrierDetected) {
				close(port850fd[netServerPort]);
				port850fd[netServerPort] = -1;
				netCarrierDetected = NO;
				}
			modemEcho = prefsSio.modemEcho;
			modemEscapeCharacter = prefsSio.modemEscapeCharacter;
			modemAutoAnswer = prefsSio.modemAutoAnswer;
			[self modemSendOK];
			}
		else if (modemCharCount >= 4 && strncmp(Buffer,"AT&F",4) == 0) {
			SioControllerLogPrint("Internet Modem - Factory Reset\n");
			modemEscapeCharacter = '+';
			modemAutoAnswer = NO;
			modemEcho = YES;
			[self modemSendOK];
			}
		else if (modemCharCount >= 4 && strncmp(Buffer,"AT&V",4) == 0) {
			[self modemDisplayStored];
			[self modemSendOK];
			}
		else if (modemCharCount >= 4 && strncmp(Buffer,"AT&Z",4) == 0) {
			UInt16 port;
			char *name;
			int slot;

			name = &Buffer[4];
			while (*name != 0 && *name != '=')
				name++;
			
			if (*name != 0) {
				name++;
				
				name = [self modemParseNamePort:name:&port];
				if (name != NULL) {
					slot = atoi(&Buffer[4]);
					if (slot > 0 && slot <= NUM_STORED_NAMES) {
						strncpy(storedNameAddr[slot-1], name, STORED_ADDR_LEN);
						storedNamePort[slot-1] = port;
						storedNameInUse[slot-1] = YES;
						[self modemSendOK];
						}
					else
						[self modemSendError];
					}
				else
					[self modemSendError];
				}
			else
				[self modemSendError];
			}
		modemCharCount = 0;
		}
	
}

-(BOOL) getEnable850
{
	return enable850;
}

-(void) setEnable850:(BOOL)enable
{
	int i;
	
	if (enable) {
		[self startSerialPorts];
		[self startNetServer];
		}
	else {
		for (i=0;i<NUM_850_PORTS;i++) {
			if (port850Mode[i] == PORT_850_NET_MODE) {
				if (netServerStarted) {
					[self stopNetServer];
					if (netCarrierDetected) {
						close(port850fd[netServerPort]);
						port850fd[netServerPort] = -1;
						netCarrierDetected = NO;
						}
					}
				}
			else if (port850Mode[i] == PORT_850_SERIAL_MODE) {
				close(port850fd[i]);
				}
			}
		[self init850State];
		}
	enable850 = enable;
}

- (void)modemChange:(int)index
{
	modemIndex = index;
	modemChanged = YES;
}

- (void) start
{
    kern_return_t	kernResult; // on PowerPC this is an int (4 bytes)
    io_iterator_t	serialPortIterator;
	int i,j;
#if 0
    /* Check for expired version */
	if ([self isExpired]) {
		[[MediaManager sharedInstance] displayExpired];
		[[NSApplication sharedApplication] terminate:self];
		}
#endif 
    kernResult = [self findModems:&serialPortIterator];
	modemCount = [self getModemPaths:serialPortIterator];
    IOObjectRelease(serialPortIterator);	// Release the iterator.

    // Now open the modem port we found, initialize the modem then close it
    if (modemCount == 0) {
        SioControllerLogPrint("No serial port found.\n");
		[[MediaManager sharedInstance] addModem:"None":YES];
        return;
		}
	
	[[MediaManager sharedInstance] addModem:modemNames[0]:YES];
	[[Preferences sharedInstance] addModem:modemNames[0]:YES];
	for (i=1;i<modemCount;i++) {
		[[MediaManager sharedInstance] addModem:modemNames[i]:NO];
		[[Preferences sharedInstance] addModem:modemNames[i]:NO];
		}
	modemIndex = 0;
	for (j=0;j<modemCount;j++) {
		if (strcmp(serialPort,bsdPaths[j]) == 0)
			modemIndex = j;
		}

	[[MediaManager sharedInstance] selectModem:modemIndex];
			
    fileDescriptor = [self openSerialPort:bsdPaths[modemIndex]:B19200];
    if (-1 == fileDescriptor)
        return;
	
	// Save the serial port name for next time
	strcpy(serialPort, bsdPaths[modemIndex]);
	
	[[MediaManager sharedInstance] displaySpeed:[NSNumber numberWithInt:19200]];
	diskServerStarted = YES;
    [NSThread detachNewThreadSelector:@selector(runDiskServer) 
              toTarget:self withObject:nil];
	
	[self startSerialPorts];
	[self startNetServer];
        
    return;
}

- (void) startSerialPorts
{
	int i,j;

	for (i=0;i<NUM_850_PORTS;i++) {
		if (port850Mode[i] == PORT_850_SERIAL_MODE) {
			for (j=0;j<modemCount;j++) {
				if (strcmp(modemNames[j],port850Port[i])==0)
					{
					port850fd[i] = [self openSerialPort:bsdPaths[j]:B300];
//					printf("Opening %s unit %d fd %d\n",bsdPaths[j] ,i,port850fd[i]);
					}
				}
			}
		}
}

- (void) startNetServer
{
	int i;

	for (i=0;i<NUM_850_PORTS;i++) {
		if (port850Mode[i] == PORT_850_NET_MODE) {
			netServerPort = i;
			if (netServerEnable) {
				netServerStarted = YES;
				netServerExit = NO;
				netServerExited = NO;
				[NSThread detachNewThreadSelector:@selector(runNetServer) 
					toTarget:self withObject:nil];
				}
			break;
			}
		}
}

- (void) stopNetServer
{
	netServerExit = YES;
	while (!netServerExited) {
		usleep(500);
		}
}

- (void) rescanModems:(BOOL)attach
{
    kern_return_t	kernResult; // on PowerPC this is an int (4 bytes)
    io_iterator_t	serialPortIterator;
	int				oldModemCount;
	int				i,j;
	BOOL			modemFound = NO;
	
	oldModemCount = modemCount;

	if (attach) {
		if (!diskServerStarted) {
			[self start];
			}
		kernResult = [self findModems:&serialPortIterator];
		modemCount = [self getModemPaths:serialPortIterator];
		IOObjectRelease(serialPortIterator);	// Release the iterator.
		
		if (oldModemCount != modemCount) {
			[[MediaManager sharedInstance] addModem:modemNames[0]:YES];
			[[Preferences sharedInstance] addModem:modemNames[0]:YES];
			for (i=1;i<modemCount;i++) {
				[[MediaManager sharedInstance] addModem:modemNames[i]:NO];
				[[Preferences sharedInstance] addModem:modemNames[i]:NO];
				}

			modemIndex = 0;
			for (j=0;j<modemCount;j++) {
				if (strcmp(serialPort,bsdPaths[j]) == 0)
				modemIndex = j;
				modemFound = YES;
				}
			
			if (!modemFound) {
				modemChanged = YES;
				if (diskServerPause) { 
					diskServerPause =0;
					[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(cassDone:) 
															withObject:self waitUntilDone:NO];
					}
				}

			[[MediaManager sharedInstance] selectModem:modemIndex];
			
			}
		}
	else {
		kernResult = [self findModems:&serialPortIterator];
		modemCount = [self getModemPaths:serialPortIterator];
		IOObjectRelease(serialPortIterator);	// Release the iterator.

		if (oldModemCount != modemCount) {
			if (modemCount == 0) {
				modemChanged = YES;
				if (diskServerPause) { 
					diskServerPause =0;
					[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(cassDone:) 
															withObject:self waitUntilDone:NO];
					}
				while(1) {
					if (diskServerExited)
						break;
					usleep(500);
					}
				diskServerExited = NO;
				diskServerStarted = NO;
				SioControllerLogPrint("No serial port found.\n");
				[[MediaManager sharedInstance] addModem:"None":YES];
				[[MediaManager sharedInstance] displaySpeed:0];
				}
			else {
				[[Preferences sharedInstance] addModem:modemNames[0]:YES];
				[[MediaManager sharedInstance] addModem:modemNames[0]:YES];
				for (i=1;i<modemCount;i++) {
					[[MediaManager sharedInstance] addModem:modemNames[i]:NO];
					[[Preferences sharedInstance] addModem:modemNames[i]:NO];
					}

				modemIndex = 0;
				for (j=0;j<modemCount;j++) {
					if (strcmp(serialPort,bsdPaths[j]) == 0)
					modemIndex = j;
					modemFound = YES;
					}
			
				if (!modemFound) {
					modemChanged = YES;
					if (diskServerPause) { 
						diskServerPause =0;
						[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(cassDone:) 
															withObject:self waitUntilDone:NO];
						}
					}

				[[MediaManager sharedInstance] selectModem:modemIndex];
			
				}
			}
		}
	[[Preferences sharedInstance] updateUI];
}

- (double) getUpTime
{
    AbsoluteTime atime = UpTime();
    Nanoseconds nsecs = AbsoluteToNanoseconds(atime);
    double time = UnsignedWideToUInt64(nsecs);
    return time;
}

- (UInt32) getUpTimeUsec
{
	UInt64 time;
    AbsoluteTime atime = UpTime();
    Nanoseconds nsecs = AbsoluteToNanoseconds(atime);
	time = UnsignedWideToUInt64(nsecs)/1000;
	return((UInt32) time);
 }

- (void) microDelay:(UInt32) us
{		
	double now;
	double then;
	
	if (us==0)
		return;
	now = [self getUpTime];
	then = now + us*1000;
	while (now < then) {
		now = [self getUpTime];
		}
}

- (int) mount:(int) diskno: (const char *)filename: (int) readOnly
{
	struct stat fileStatus;
	UInt32 file_length;
	[mutex lock];
        
	if (diskInfo[diskno]) {
	    [self dismount:diskno];
        }

	stat(filename, &fileStatus);
	if (fileStatus.st_mode & S_IFDIR) {
		diskInfo[diskno] = (AtrDiskInfo *) calloc(1, sizeof(AtrDiskInfo));
		diskInfo[diskno]->directory = YES;
		if (readOnly)
			diskReadWrite[diskno] = FALSE;
		else
			diskReadWrite[diskno] = TRUE;
		if ((diskInfo[diskno]->dir = opendir(filename)) == NULL) {
			free(diskInfo[diskno]);
			diskInfo[diskno] = NULL;
			[mutex unlock];
			return(FALSE);
			}
		diskInfo[diskno]->sectorSize = 128;
		diskInfo[diskno]->sectorCount = 720;
		diskInfo[diskno]->dirCurrentFile = 64;
		strcpy(driveFilename[diskno], filename);
		if (diskReadWrite[diskno])
			driveState[diskno] = DRIVE_READ_WRITE;
		else
			driveState[diskno] = DRIVE_READ_ONLY;
		diskReadWrite[diskno] = TRUE;        
		}
	else {
		ATR_HEADER header;
		
		if (readOnly)
			diskReadWrite[diskno] = FALSE;
		else
			diskReadWrite[diskno] = TRUE;
    
		diskInfo[diskno] = (AtrDiskInfo *) calloc(1, sizeof(AtrDiskInfo));
		if (diskInfo[diskno] == NULL) {
			[mutex unlock];
			return(FALSE);
			}

		if (diskReadWrite[diskno]) {
			diskInfo[diskno]->file = fopen(filename, "rb+");
			if (!diskInfo[diskno]->file) {
				diskReadWrite[diskno] = 0;
				fclose(diskInfo[diskno]->file);
				diskInfo[diskno]->file = fopen(filename, "rb");
				}
			else
				diskReadWrite[diskno] = 1;    
			}
		else {
			diskInfo[diskno]->file = fopen(filename, "rb");
			}
    
		if (diskInfo[diskno]->file) {
			fseek(diskInfo[diskno]->file, 0L, SEEK_END);
			file_length = ftell(diskInfo[diskno]->file);
			fseek(diskInfo[diskno]->file, 0L, SEEK_SET);

			if (fread(&header, 1, sizeof(ATR_HEADER), diskInfo[diskno]->file) < 
				sizeof(ATR_HEADER)) {
				fclose(diskInfo[diskno]->file);
				free(diskInfo[diskno]);
				diskInfo[diskno] = NULL;
				[mutex unlock];
				return(FALSE);
				}
			}
		else {
			free(diskInfo[diskno]);
			diskInfo[diskno] = NULL;
			[mutex unlock];
			return(FALSE);
		}

		diskInfo[diskno]->bootSectorsType = LOGICAL_SECTORS;

		if ((header.signatureByte1 != ATR_SIGNATURE_1) || (header.signatureByte2 != ATR_SIGNATURE_2)) {
			// check for PRO or VAPI
			if (header.signatureByte1 == 'A' && header.signatureByte2 == 'T' && 
				header.sectorCountLow == '8' && header.sectorCountHigh == 'X') {
				diskWriteProtect[diskno] = 1;
				diskReadWrite[diskno] = FALSE;        
				driveState[diskno] = DRIVE_READ_ONLY;
				diskInfo[diskno]->imageType = IMAGE_TYPE_VAPI;
				diskInfo[diskno]->directory = NO;
				if ([self mountVAPI:diskno:file_length]) {
					strcpy(driveFilename[diskno], filename);
					[mutex unlock];
					return(TRUE);
				} else {
					free(diskInfo[diskno]);
					diskInfo[diskno] = NULL;
					[mutex unlock];
					return(FALSE);
				}
			} else if ((file_length-16)%(128+12) == 0 &&
						(header.signatureByte1*256 + header.signatureByte2 == (file_length-16)/(128+12)) &&
						header.sectorCountLow == 'P') {
				diskWriteProtect[diskno] = 1;
				diskReadWrite[diskno] = FALSE;        
				driveState[diskno] = DRIVE_READ_ONLY;
				diskInfo[diskno]->imageType = IMAGE_TYPE_PRO;
				diskInfo[diskno]->directory = NO;
				if ([self mountPRO:diskno:file_length:&header]) {
					strcpy(driveFilename[diskno], filename);
					[mutex unlock];
					return(TRUE);
				} else {
					free(diskInfo[diskno]);
					diskInfo[diskno] = NULL;
					[mutex unlock];
					return(FALSE);
				}
			} else {
				free(diskInfo[diskno]);
				diskInfo[diskno] = NULL;
				[mutex unlock];
				return(FALSE);
			}
		} else {
			diskInfo[diskno]->imageType = IMAGE_TYPE_ATR;
		}

		if (header.writeProtect)
			diskWriteProtect[diskno] = 1;
		else
			diskWriteProtect[diskno] = 0;

		diskInfo[diskno]->sectorSize = header.sectorSizeHigh << 8 |
											header.sectorSizeLow;

		diskInfo[diskno]->sectorCount = (header.highSectorCountHigh << 24 |
											header.highSectorCountLow << 16 |
											header.sectorCountHigh << 8 |
											header.sectorCountLow) >> 3;

		if (diskInfo[diskno]->sectorSize == 256) {
			if (diskInfo[diskno]->sectorCount & 1)
				diskInfo[diskno]->sectorCount += 3; 
			else {	
				UInt8 buffer[0x180];
				int i;
				
				fseek(diskInfo[diskno]->file, 0x190L, SEEK_SET);
				fread(buffer, 1, 0x180, diskInfo[diskno]->file);
				diskInfo[diskno]->bootSectorsType = SIO2PC_SECTORS;
				for (i = 0; i < 0x180; i++)
					if (buffer[i] != 0) {
						diskInfo[diskno]->bootSectorsType = PHYSICAL_SECTORS;
						break;
					}
				}
			diskInfo[diskno]->sectorCount >>= 1;
			}

		diskInfo[diskno]->directory = NO;
		        
		strcpy(driveFilename[diskno], filename);
        
		if (!ignoreAtrWriteProtect && diskWriteProtect[diskno])
			diskReadWrite[diskno] = FALSE;        

		if (diskReadWrite[diskno])
			driveState[diskno] = DRIVE_READ_WRITE;
		else
			driveState[diskno] = DRIVE_READ_ONLY;
		}
    [mutex unlock];
	return(TRUE);
}

- (int) mountVAPI:(int) diskno:(int) file_length
{
	vapi_additional_info_t *info;
	vapi_file_header_t fileheader;
	vapi_track_header_t trackheader;
	ULONG trackoffset, totalsectors;
	FILE *f = diskInfo[diskno]->file;
	
	diskInfo[diskno]->sectorSize = 128;
	diskInfo[diskno]->sectorCount = 720;
	fseek(f,0,SEEK_SET);
	if (fread(&fileheader,1,sizeof(fileheader),f) != sizeof(fileheader)) {
		fclose(f);
		SioControllerLogPrint("VAPI: Bad File Header");
		return(FALSE);
	}
	trackoffset = VAPI_32(fileheader.startdata);	
	if (trackoffset > file_length) {
		fclose(f);
		SioControllerLogPrint("VAPI: Bad Track Offset");
		return(FALSE);
	}
#ifdef DEBUG_VAPI
	SioControllerLogPrint("VAPI File Version %d.%d\n",fileheader.majorver,fileheader.minorver);
#endif
	/* Read all of the track headers to get the total sector count */
	totalsectors = 0;
	while (trackoffset > 0 && trackoffset < file_length) {
		UInt32 next;
		UInt16 tracktype;
		
		fseek(f,trackoffset,SEEK_SET);
		if (fread(&trackheader,1,sizeof(trackheader),f) != sizeof(trackheader)) {
			fclose(f);
			SioControllerLogPrint("VAPI: Bad Track Header");
			return(FALSE);
		}
		next = VAPI_32(trackheader.next);
		tracktype = VAPI_16(trackheader.type);
		if (tracktype == 0) {
			totalsectors += VAPI_16(trackheader.sectorcnt);
		}
		trackoffset += next;
	}
	
	info = malloc(sizeof(vapi_additional_info_t));
	diskInfo[diskno]->addedInfo = info;
	info->sectors = malloc(diskInfo[diskno]->sectorCount * 
								sizeof(vapi_sec_info_t));
	memset(info->sectors, 0, diskInfo[diskno]->sectorCount * 
		   sizeof(vapi_sec_info_t));
	
	/* Now read all the sector data */
	trackoffset = VAPI_32(fileheader.startdata);
	while (trackoffset > 0 && trackoffset < file_length) {
		ULONG sectorcnt, seclistdata,next;
		vapi_sector_list_header_t sectorlist;
		vapi_sector_header_t sectorheader;
		vapi_sec_info_t *sector;
		UInt16 tracktype;
		int j;
		
		fseek(f,trackoffset,SEEK_SET);
		if (fread(&trackheader,1,sizeof(trackheader),f) != sizeof(trackheader)) {
			free(info->sectors);
			free(info);
			fclose(f);
			SioControllerLogPrint("VAPI: Bad Track Header while reading sectors");
			return(FALSE);
		}
		next = VAPI_32(trackheader.next);
		sectorcnt = VAPI_16(trackheader.sectorcnt);
		tracktype = VAPI_16(trackheader.type);
		seclistdata = VAPI_32(trackheader.startdata) + trackoffset;
#ifdef DEBUG_VAPI
		SioControllerLogPrint("Track %d: next %x type %d seccnt %d secdata %x\n",trackheader.tracknum,
				  trackoffset + next,VAPI_16(trackheader.type),sectorcnt,seclistdata);
#endif
		if (tracktype == 0) {
			if (seclistdata > file_length) {
				free(info->sectors);
				free(info);
				fclose(f);
				SioControllerLogPrint("VAPI: Bad Sector List Offset");
				return(FALSE);
			}
			fseek(f,seclistdata,SEEK_SET);
			if (fread(&sectorlist,1,sizeof(sectorlist),f) != sizeof(sectorlist)) {
				free(info->sectors);
				free(info);
				fclose(f);
				SioControllerLogPrint("VAPI: Bad Sector List");
				return(FALSE);
			}
#ifdef DEBUG_VAPI
			SioControllerLogPrint("Size sec list %x type %d\n",VAPI_32(sectorlist.sizelist),sectorlist.type);
#endif
			for (j=0;j<sectorcnt;j++) {
				double percent_rot;
				
				if (fread(&sectorheader,1,sizeof(sectorheader),f) != sizeof(sectorheader)) {
					free(info->sectors);
					free(info);
					fclose(f);
					SioControllerLogPrint("VAPI: Bad Sector Header");
					return(FALSE);
				}
				if (sectorheader.sectornum > 18)  {
					fclose(f);
					SioControllerLogPrint("VAPI: Bad Sector Index: Track %d Sec Num %d Index %d",
							  trackheader.tracknum,j,sectorheader.sectornum);
					return(FALSE);
				}
				sector = &info->sectors[trackheader.tracknum * 18 + sectorheader.sectornum - 1];
				
				percent_rot = ((double) VAPI_16(sectorheader.sectorpos))/VAPI_BYTES_PER_TRACK;
				sector->sec_rot_pos[sector->sec_count] = (unsigned int) (percent_rot * VAPI_USEC_PER_ROT);
				sector->sec_offset[sector->sec_count] = VAPI_32(sectorheader.startdata) + trackoffset;
				sector->sec_status[sector->sec_count] = ~sectorheader.sectorstatus;
				sector->sec_count++;
				if (sector->sec_count > MAX_VAPI_PHANTOM_SEC) {
					free(info->sectors);
					free(info);
					fclose(f);
					SioControllerLogPrint("VAPI: Too many Phantom Sectors");
					return(FALSE);
				}
#ifdef DEBUG_VAPI
				SioControllerLogPrint("Sector %d status %x position %f %d %d data %x\n",sectorheader.sectornum,
						  sector->sec_status[sector->sec_count-1],percent_rot,
						  sector->sec_rot_pos[sector->sec_count-1],
						  VAPI_16(sectorheader.sectorpos),
						  sector->sec_offset[sector->sec_count-1]);				
#endif				
			}
		} else {
			SioControllerLogPrint("Unknown VAPI track type Track:%d Type:%d",trackheader.tracknum,tracktype);
		}
		trackoffset += next;
	}		
	return(TRUE);
}

- (int) mountPRO:(int) diskno:(int) file_length:(ATR_HEADER *) header
{
	pro_additional_info_t *info;
	int count;
	FILE *f = diskInfo[diskno]->file;

	SioControllerLogPrint("Pro type '%c'",header->sectorCountHigh);
	
	diskInfo[diskno]->sectorSize = 128;
	if (header->sectorCountHigh == '3') {
		diskInfo[diskno]->sectorCount = header->highSectorCountHigh + header->highSectorCountLow * 256;
#ifdef DEBUG_PRO
		SioControllerLogPrint("Sector count %d\n",diskInfo[diskno]->sectorCount);
#endif
		info = malloc(sizeof(pro_additional_info_t));
		diskInfo[diskno]->addedInfo = info;
		info->count = malloc(diskInfo[diskno]->sectorCount);
		memset(info->count, 0, diskInfo[diskno]->sectorCount);
		info->phantom = malloc(diskInfo[diskno]->sectorCount * 
									sizeof(pro_phantom_sec_info_t));
		
		for (count = 0;count < diskInfo[diskno]->sectorCount;count++) {
			unsigned char sec_header[12];
			int phantom_count;
			pro_phantom_sec_info_t *phantom;
			int j;
			
			fseek(f,16+((128+12) * count),SEEK_SET);
			fread(sec_header, 1, 12, f);
			phantom_count = sec_header[5];
			phantom = &info->phantom[count];
			phantom->phantom_count = phantom_count;
			
			for (j=0;j<=phantom_count;j++) {
				int index;
				unsigned char sec_header2[12];
				
				index = sec_header[6+j]; 
				if (index==0)
					phantom->sec_offset[j] = 16 + count * (128+12);
				else
					phantom->sec_offset[j] = 
					16 + (diskInfo[diskno]->sectorCount + index -1) * (128+12);
				if (phantom->sec_offset[j] + 128 > file_length) {
					free(info->phantom);
					free(info->count);
					free(info);
					fclose(f);
					SioControllerLogPrint("PRO: Bad Image");
					return(FALSE);
				}
				fseek(f,phantom->sec_offset[j],SEEK_SET);
				fread(sec_header2,1,12,f);
				phantom->sec_status[j] = sec_header2[1];
			}
		}
		info->max_sector = (file_length-16)/(128+12);
	} else if (header->sectorCountHigh == '2') {
		diskInfo[diskno]->sectorCount = header->signatureByte2 + header->signatureByte1 * 256;
#ifdef DEBUG_PRO
		SioControllerLogPrint("Sector count %d\n",diskInfo[diskno]->sectorCount);
#endif
		info = malloc(sizeof(pro_additional_info_t));
		diskInfo[diskno]->addedInfo = info;
		info->count = malloc(diskInfo[diskno]->sectorCount);
		memset(info->count, 0, diskInfo[diskno]->sectorCount);
		info->phantom = malloc(diskInfo[diskno]->sectorCount * 
									sizeof(pro_phantom_sec_info_t));
		
		for (count = 0;count < diskInfo[diskno]->sectorCount;count++) {
			unsigned char sec_header[12];
			int phantom_count;
			pro_phantom_sec_info_t *phantom;
			int j;
			
			fseek(f,16+((128+12) * count),SEEK_SET);
			fread(sec_header, 1, 12, f);
			phantom_count = sec_header[5];
			phantom = &info->phantom[count];
			phantom->phantom_count = phantom_count;
			diskInfo[diskno]->sectorCount -= phantom_count;
			
			for (j=1;j<=phantom_count;j++) {
				int index;
				unsigned char sec_header2[12];
				
				index = sec_header[6+j]; 
				phantom->sec_offset[j] = 
				16 + (diskInfo[diskno]->sectorCount + index -1) * (128+12);
				if (phantom->sec_offset[j] + 128 > file_length) {
					free(info->phantom);
					free(info->count);
					free(info);
					fclose(f);
					SioControllerLogPrint("PRO: Bad Image");
					return(FALSE);
				}
				fseek(f,phantom->sec_offset[j],SEEK_SET);
				fread(sec_header2,1,12,f);
				phantom->sec_status[j] = sec_header2[1];
			}
		}
		info->max_sector = (file_length-16)/(128+12);
	}
	return(TRUE);
}

- (void) dismount:(int) diskno
{
    [mutex lock];
	if (diskInfo[diskno]) {
		if (diskInfo[diskno]->file) 
			fclose(diskInfo[diskno]->file);
		if (diskInfo[diskno]->directory)
			closedir(diskInfo[diskno]->dir);
		free(diskInfo[diskno]);
		diskInfo[diskno] = NULL;
		driveState[diskno] = DRIVE_NO_DISK;
		strcpy(driveFilename[diskno], "Empty");
	}
    [mutex unlock];
}

- (void) turnDriveOff:(int) diskno
{
    [mutex lock];
	driveState[diskno] = DRIVE_POWER_OFF;
	strcpy(driveFilename[diskno], "Off");
    [mutex unlock];
}

- (int) rotateDisks
{
	char tempNames[NUMBER_OF_ATARI_DRIVES][FILENAME_MAX];
	char tempState[NUMBER_OF_ATARI_DRIVES];
	int i;
	int status = TRUE;

    [mutex lock];
	for (i = 0; i < NUMBER_OF_ATARI_DRIVES; i++) {
		strcpy(tempNames[i], driveFilename[i]);
		tempState[i] = driveState[i];
		[self dismount:i];
		}

	for (i = 1; i < NUMBER_OF_ATARI_DRIVES; i++) {
		if (tempState[i] != DRIVE_POWER_OFF && tempState[i] != DRIVE_NO_DISK) {
			if ([self mount:i-1:tempNames[i]:FALSE] == FALSE)
				status = FALSE;
			}
		}

	i = NUMBER_OF_ATARI_DRIVES - 1;
	while (i >= 0 && (tempState[i] == DRIVE_POWER_OFF || tempState[i] == DRIVE_NO_DISK) )
		i--;

	if (i >= 0)	{
		if ([self mount:i:tempNames[0]:FALSE] == FALSE)
			status = FALSE;
		}

    [mutex unlock];
	return status;
}

- (int) readSector:(int) drive:(int) sector:(UInt8 *) buffer
{
	int size;
	AtrDiskInfo *info = diskInfo[drive];

   	if (sector > info->sectorCount) 
		return -1;
	
	size = [self seekSector:info:sector];
	fread(buffer, 1, size, info->file);
	return 0;
}

- (struct dirent *) readDirEntry:(DIR *)directory
{
	struct dirent *newEntry;
	
	do {
		newEntry = readdir(directory);
		if (newEntry == NULL)
			return(NULL);
	} while (newEntry->d_name[0] == '.');
	return(newEntry);
}

- (int) readDirSector:(int) drive:(int) sector:(UInt8 *) buffer
{
	int dirSec;
	char filename[FILENAME_MAX];
	
	AtrDiskInfo *info = diskInfo[drive];

   	if (sector > info->sectorCount) 
		return -1;
	if (sector == 360) {
		memcpy(buffer,sectorMap,128);
		}
	else if (sector >=361 && sector <= 368) {
		int entCount, startEnt;
		int sectorCount, fileStart;
		struct stat fileStatus;
		struct dirent *dirEntry;
		ATARI_DIR_ENT atariDirEntry;
		
		memset(buffer,0,128);
		rewinddir(info->dir);
		/* Read dir entries until we get to the sector we are 
		   interested in.  If we run out, then just return */
		dirSec = sector-361;
		for (entCount=0;entCount<8*dirSec;entCount++) {
			if ([self readDirEntry:info->dir] == NULL) {
				return(0);
				}
			}
		/* Now read the dir entries for the sector we are
		   interested in */
		/* If it's the first sector, then leave an empty entry for
		   writing, and one for up directory */
		if (dirSec == 0) {
			atariDirEntry.flags = 0x80;
			memcpy(buffer,&atariDirEntry,sizeof(atariDirEntry));
			atariDirEntry.flags = 0x42;
			atariDirEntry.secCountHigh = 0;
			atariDirEntry.secCountLow = 1;
			atariDirEntry.startSecHigh = 0;
			atariDirEntry.startSecLow = 5;
			memcpy(atariDirEntry.name,"UP         ",11);
			memcpy(buffer+16,&atariDirEntry,sizeof(atariDirEntry));
			startEnt = 2;
			}
		else {
			startEnt = 0;
			}
		for (entCount = startEnt;entCount < 8;entCount++) {
			dirEntry = [self readDirEntry:info->dir];
			if (dirEntry==NULL)
				return(0);
			strcpy(filename,driveFilename[drive]);
			strcat(filename,"/");
			strcat(filename,dirEntry->d_name);
			if (stat(filename,&fileStatus)) {
				atariDirEntry.flags = 0x80;
				}
			else {
				sectorCount = (fileStatus.st_size+124)/125;
				atariDirEntry.secCountHigh = sectorCount>>8;
				atariDirEntry.secCountLow = sectorCount & 0xff;
				fileStart = dirSec*8 + entCount + 4;
				atariDirEntry.startSecHigh = fileStart>>8;
				atariDirEntry.startSecLow = fileStart & 0xff;
				[self macNameToAtariName:dirEntry->d_name:atariDirEntry.name];
				atariDirEntry.flags = 0x42;
				memcpy(buffer+16*entCount,&atariDirEntry,sizeof(atariDirEntry));
				}
			
			}
		}
	else if (sector == 5) {
		int dirNameLen = strlen(driveFilename[drive]) - 1;
		while (driveFilename[drive][dirNameLen] != '/')
			dirNameLen --;
		if (dirNameLen == 0)
			driveFilename[drive][1] = 0;
		else
			driveFilename[drive][dirNameLen] = 0;
		[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateInfo) 
										withObject:nil waitUntilDone:NO];
		memset(buffer,0,128);
		closedir(info->dir);
		info->dir = opendir(driveFilename[drive]);
		}
	else if (sector >= 6 && sector<4+64) {
		int fileno = sector-4;
		struct dirent *dirEntry;
		struct stat fileStatus;
		int entCount;
		int numRead;

		if (fileno != info->dirCurrentFile) {
			if (info->file) 
				fclose(info->file);
			rewinddir(info->dir);
			for(entCount=0;entCount<fileno-1;entCount++) 
				dirEntry=[self readDirEntry:info->dir];
			if (dirEntry==NULL) {
				memset(buffer,0,128);
				return 0;
				}
			strcpy(filename,driveFilename[drive]);
			strcat(filename,"/");
			strcat(filename,dirEntry->d_name);
			stat(filename, &fileStatus);
			if (fileStatus.st_mode & S_IFDIR) {
				closedir(info->dir);
				info->dir = opendir(filename);
				strcpy(driveFilename[drive],filename);
				memset(buffer,0,128);
				[[MediaManager sharedInstance] performSelectorOnMainThread:@selector(updateInfo) 
												withObject:nil waitUntilDone:NO];
				return 0;
				}
			else {
				info->file = fopen(filename,"r");
				if (info->file == NULL) {
					memset(buffer,0,128);
					return 0;
					}
				info->dirCurrentFile = fileno;
				}
			}
		numRead = fread(buffer, 1, 125, info->file);
		buffer[125]=fileno<<2;
		buffer[126]=sector;
		buffer[127]=numRead;
		if ( numRead<125 ) {
			buffer[126]=0;
			fclose(info->file);
			info->file = NULL;
			info->dirCurrentFile = 64;
			}
		}
	else
		memset(buffer,0,128);
    return 0;
}

- (int) writeDirSector:(int) drive:(int) sector:(UInt8 *) buffer
{
	char filename[FILENAME_MAX];
	char macname[FILENAME_MAX];
	
	AtrDiskInfo *info = diskInfo[drive];

   	if (sector > info->sectorCount) 
		return -1;
	if (sector == 361) {
		ATARI_DIR_ENT *atariDirEntry;
		
		atariDirEntry = (ATARI_DIR_ENT *) buffer;
		if (atariDirEntry->flags & 1) {
			if (info->writeFile)
				fclose(info->writeFile);
			[self atariNameToMacName:macname:atariDirEntry->name];
			strcpy(filename,driveFilename[drive]);
			strcat(filename,"/");
			strcat(filename,macname);
			info->writeFile = fopen(filename,"w");
			}
		else {
			if (info->writeFile)
				fclose(info->writeFile);
			}
		}
	else if ((sector >= 68 && sector<360) || (sector>368 && sector<=720)) {
		if (info->writeFile)
			fwrite(buffer,1,buffer[127],info->writeFile);
		}

    return 0;
}

- (int) writeSector:(int) drive:(int) sector:(UInt8 *) buffer
{
	int size;
	AtrDiskInfo *info = diskInfo[drive];

   	if (sector > info->sectorCount) 
		return -1;
		
	size = [self seekSector:info:sector];
	fwrite(buffer, 1, size, info->file);
	return 0;
}

- (void) zeroSectors:(int) drive
{
    UInt8 sectorBuffer[256];
	AtrDiskInfo *info = diskInfo[drive];
	int i;

    memset(sectorBuffer,0,256);

    for (i=1;i<=info->sectorCount;i++) 
        {
        [self writeSector:drive:i:sectorBuffer];
        }
}

- (int) seekSector:(AtrDiskInfo *) info:(int) sector
{
	UInt32 offset;
	int size;

	if (info->imageType == IMAGE_TYPE_ATR) {
		if (sector < 4) {
			size = 128;
			offset = sizeof(ATR_HEADER) + 
            (sector - 1) * 
            (info->bootSectorsType == PHYSICAL_SECTORS ? 256 : 128);
		}
		else {
			size = info->sectorSize;
			offset = sizeof(ATR_HEADER) +  
            (info->bootSectorsType == LOGICAL_SECTORS ? 0x180 : 0x300) + 
            (sector - 4) * size;
		}
		
		fseek(info->file, 0L, SEEK_END);
		if (offset < 0 || offset > ftell(info->file)) {
		}
		else
			fseek(info->file, offset, SEEK_SET);
	} else if (info->imageType == IMAGE_TYPE_VAPI) {
		vapi_additional_info_t *vapi_info;
		vapi_sec_info_t *secinfo;
		
		size = 128;
		vapi_info = info->addedInfo;
		if (info == NULL)
			offset = 0;
		else if (sector > info->sectorCount)
			offset = 0;
		else {
			secinfo = &vapi_info->sectors[sector-1];
			if (secinfo->sec_count == 0  )
				offset = 0;
			else
				offset = secinfo->sec_offset[0];
			fseek(info->file, offset, SEEK_SET);
		}
	} else {
		size = 128;
		offset = 16 + (128+12)*(sector -1); /* returns offset of header */
		fseek(info->file, offset, SEEK_SET);
	}

	return size;
}

- (void) macNameToAtariName:(char *)mac:(char *)atari
{
	char *extension;
    int nameLen, extensionLen, i;

    for (i=0;i<strlen(mac);i++) 
        {
        if (islower(mac[i]))
            mac[i] -= 32;
        }

    if ((extension = strchr(mac,'.')) == NULL) {
        nameLen = strlen(mac);
        extensionLen = 0;
        }
    else {
        *extension = 0;
        extension++;
        nameLen = strlen(mac);
        extensionLen = strlen(extension);
    }

    if (nameLen <= 8) {
        memcpy(atari,mac,nameLen);
        for (i=0;i<8-nameLen;i++) 
            atari[nameLen+i] = ' ';
        }
    else
        memcpy(atari,mac,8);

    if (extensionLen <= 3) {
        memcpy(atari+8,extension,extensionLen);
        for (i=0;i<3-extensionLen;i++) 
            atari[8+extensionLen+i] = ' ';
        }
    else
        memcpy(atari+8,extension,3);
}

- (void) filterAtariName:(char*) name
{
	int length,i,j;
	char *dest = name;
	char c;

	length = strlen(name);
	for (i=0,j=0;i<length;i++) {
		c = name[i] & 0x7F;

		if ( c == ' ' )
			continue;

		if ( !isprint( c ) ||
		     c == '*' || c == ':' || c =='\"' || c == ',' ||
			 c == '.' || c == '|' || c == '?' || c == '/' ||
			 c == '\\')
			c = '_';
		dest[j++] = c;
		}
	dest[j] = 0;
}

- (void) atariNameToMacName:(char *) mac:(char *) atari
{
	char name[ 9 ];
	char extension[ 4 ];

	strncpy( name, (const char *) atari, 8 );
	name[ 8 ] = '\0';

	strncpy( extension, (const char *) atari + 8, 3 );
	extension[ 3 ] = '\0';

	[self filterAtariName:name];
	[self filterAtariName:extension];

	if ( !*name )
		strcpy( name, "out" );

	strcpy( mac, name );

	if ( *extension )
	{
		strcat( mac, "." );
		strcat( mac, extension );
	}
}

- (void) returnPrefs
{
	SIO_PREF_RET prefs;
	int i;
	
	strcpy(prefs.serialPort, serialPort);
	prefs.currPrinter = currPrinter;
	for (i=0;i< NUM_STORED_NAMES; i++) {
		if (storedNameInUse[i]) {
			strcpy(prefs.storedNameAddr[i],storedNameAddr[i]);
			prefs.storedNamePort[i] = storedNamePort[i];
			}
		else {
			prefs.storedNameAddr[i][0]=0;
			prefs.storedNamePort[i] = 23;
			}
		}
	prefs.enable850 = enable850;
	[[Preferences sharedInstance] transferValuesFromSio:&prefs];
}

- (void) pauseDiskServer:(BOOL) pause
{
	if (pause)
		diskServerPause = 1;
	else
		diskServerPause = 0;
}

- (int) cassMount:(const char *)filename
{
	CASSETTE_HEADER header;

	cassFile = fopen(filename, "rb");
	if (cassFile == NULL)
		return 0;
	fread(&header, 1, sizeof(CASSETTE_HEADER), cassFile);
	if (header.recordType[0] != 'F' ||
	    header.recordType[1] != 'U' ||
	    header.recordType[2] != 'J' ||
	    header.recordType[3] != 'I')
		return 0;

	/* Skip the description */
	fseek(cassFile, (header.lengthHi << 8) + header.lengthLo, SEEK_CUR);
	
	/* Find out how many total data blocks are in the file */
	numCassBlocks = 0;
	while (1)
		{
		if (fread(&header, 1, sizeof(CASSETTE_HEADER), cassFile) != 
					sizeof(CASSETTE_HEADER))
			break;
		if (header.recordType[0] == 'd' &&
			header.recordType[1] == 'a' &&
			header.recordType[2] == 't' &&
			header.recordType[3] == 'a') {
				numCassBlocks++;
			}
		fseek(cassFile, (header.lengthHi << 8) + header.lengthLo, SEEK_CUR);
		}
		
	/* Go back to the start of the file */
	fseek(cassFile, 0, SEEK_SET);
	currCassBlock = 1;
		
	return numCassBlocks;
}

- (void) cassUnmount
{
	fclose(cassFile);
	cassFile = NULL;
}

- (void) runCassServer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CASSETTE_HEADER header;
	UInt32 gap, waitTime;
	UInt8 data[8192];
	UInt32 length;
	int seekCassBlock = 1;
	int i;
		
	/* Go back to the start of the file */
	fseek(cassFile, 0, SEEK_SET);
	cassShouldStop = NO;
	
	[NSThread setThreadPriority:1.0];
    [self setSerialPortSpeed:fileDescriptor:0];
	while (seekCassBlock < currCassBlock) {
		fread(&header, 1, sizeof(CASSETTE_HEADER), cassFile);
		length = (header.lengthHi << 8) + header.lengthLo; 
		if (header.recordType[0] == 'd' &&
			header.recordType[1] == 'a' &&
			header.recordType[2] == 't' &&
			header.recordType[3] == 'a') {
			seekCassBlock++;
			}
		fseek(cassFile, length, SEEK_CUR);
		}
	
	while(fread(&header, 1, sizeof(CASSETTE_HEADER), cassFile) == sizeof(CASSETTE_HEADER))
		{
		length = (header.lengthHi << 8) + header.lengthLo; 
		if (header.recordType[0] == 'd' &&
			header.recordType[1] == 'a' &&
			header.recordType[2] == 't' &&
			header.recordType[3] == 'a') {
			[cassStatusUpdate setStatus:YES:currCassBlock];
			[[MediaManager sharedInstance] updateCassStatus:cassStatusUpdate];
			gap = header.aux1 + 256 * header.aux2;
			if (gap > 500) {
				while (gap) {
					if (cassShouldStop) {
						[self setSerialPortSpeed:fileDescriptor:1];
						[[MediaManager sharedInstance] notifyCassStopped];
						[NSThread exit];
						}
					if (gap>500)
						waitTime = 500;
					else
						waitTime = gap;
					usleep(waitTime*1000);
					gap -= waitTime;
					}
				}
			else
				usleep(gap*1000);
			[cassStatusUpdate setStatus:NO:currCassBlock];
			[[MediaManager sharedInstance] updateCassStatus:cassStatusUpdate];
			fread(data, 1, length, cassFile);
			for (i=0;i<length;i++) {
				if (cassShouldStop) {
					[self setSerialPortSpeed:fileDescriptor:1];
					[[MediaManager sharedInstance] notifyCassStopped];
					[NSThread exit];
					}
				write(fileDescriptor,&data[i],1);
				usleep(15000);
				}
			tcdrain(fileDescriptor);
			SioControllerLogPrint("Cassette Sent block %d\n",currCassBlock);
			currCassBlock++;
			[cassInfoUpdate setInfo:currCassBlock:numCassBlocks];
			[[MediaManager sharedInstance] updateCassetteInfo:cassInfoUpdate];
			}
		else
			{
			fseek(cassFile, length, SEEK_CUR);
			}
		}
    [self setSerialPortSpeed:fileDescriptor:1];
	[[MediaManager sharedInstance] notifyCassStopped]; 

    [pool release];
}

- (void) stopCassette
{
	cassShouldStop = YES;
}

- (void) adjustCassBlock:(int) direction
{
	if (direction == 0) {
		currCassBlock = 1;
		}
	else if (direction < 0) {
		if (currCassBlock > 1)
			currCassBlock--;
		}
	else {
		if (currCassBlock < numCassBlocks)
			currCassBlock++;
		}
	[cassInfoUpdate setInfo:currCassBlock:numCassBlocks];
	[[MediaManager sharedInstance] updateCassetteInfo:cassInfoUpdate];
}
@end



