/*********************************************************************/
/*                                                                   */
/*  This Program Written by Alica Okano.                             */
/*  Released to the Public Domain as discussed here:                 */
/*  http://creativecommons.org/publicdomain/zero/1.0/                */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*  pecoff.h - header file for PE/COFF support                       */
/*                                                                   */
/*********************************************************************/

/*
Documentation of format can be found here:
https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
*/

/*
ARM example:
000080  50450000 C0010300 6628FF65 00000000  PE......f(.e....
000090  00000000 E0000E02 0B010238 00020000  ...........8....
0000A0  00040000 00000000 00100000 00100000  ................
0000B0  00000000 00000100 00100000 00020000  ................
0000C0  04000000 01000000 02000000 00000000  ................
optional header appears to start at 0x98
*/

/*
x64 example:
000040  50450000 64860500 00000000 00000000  PE..d...........
000050  00000000 F0002202 0B02000F 00D20200  ......".........
000060  006A0100 00745000 00100000 00100000  .j...tP.........
000070  00004000 00000000 00100000 00020000  ..@.............
000080  04000000 01000000 04000000 00000000  ................
000090  00105500 00040000 869C0400 03004001  ..U...........@.
0000A0  00002000 00000000 00100000 00000000  .. .............

optional header appears to start at 0x58
difference likely due to different linkers being used at the time.

data_dir starts at c8:

0000C0  00000000 10000000 00000000 00000000  ................
0000D0  00E05400 F6030000 00000000 00000000  ..T.............
0000E0  00000000 00000000 00000000 00000000  ................
0000F0  00F05400 B01A0000 00000000 00000000  ..T.............
000100  00000000 00000000 00000000 00000000  ................
000110  00000000 00000000 00000000 00000000  ................

so relocations start at f0 (5th element, 8 bytes per entry)

giving 54f000 as virtual address and 1ab0 as size

*/


#ifdef __LONG64__
typedef unsigned int U32;
#else
typedef unsigned long U32;
#endif

/* In image files there is signature "PE\0\0" at e_lfanew
 * after which is the COFF header. */
typedef struct {
    unsigned short Machine;
    unsigned short NumberOfSections;
    U32 TimeDateStamp;
    U32 PointerToSymbolTable; /* Deprecated, ignore. */
    U32 NumberOfSymbols; /* Deprecated, ignore. */
    unsigned short SizeOfOptionalHeader;
    unsigned short Characteristics;
} Coff_hdr;

/* Machine values. */
#define IMAGE_FILE_MACHINE_UNKNOWN 0
#define IMAGE_FILE_MACHINE_AMD64 0x8664
#define IMAGE_FILE_MACHINE_I386 0x14c
#define IMAGE_FILE_MACHINE_ARM 0x1c0
#define IMAGE_FILE_MACHINE_THUMB 0x1c2
#define IMAGE_FILE_MACHINE_M68K 0x268
#define IMAGE_FILE_MACHINE_ARMNT 0x1c4
#define IMAGE_FILE_MACHINE_ARM64 0xaa64
#define IMAGE_FILE_MACHINE_LOONGARCH64 0x6264

/* Characteristics flags. */
#define IMAGE_FILE_RELOCS_STRIPPED         0x0001
#define IMAGE_FILE_EXECUTABLE_IMAGE        0x0002
#define IMAGE_FILE_LARGE_ADDRESS_AWARE     0x0020
/* Reserved flag 0x0040. */
#define IMAGE_FILE_32BIT_MACHINE           0x0100
#define IMAGE_FILE_DEBUG_STRIPPED          0x0200
#define IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP 0x0400
#define IMAGE_FILE_NET_RUN_FROM_SWAP       0x0800
#define IMAGE_FILE_SYSTEM                  0x1000
#define IMAGE_FILE_DLL                     0x2000
#define IMAGE_FILE_UP_SYSTEM_ONLY          0x4000

/* PE/COFF optional header (magic is MAGIC_PE32). */
typedef struct {
    unsigned short Magic; /* 0 */
    unsigned char MajorLinkerVersion; /* 2 */
    unsigned char MinorLinkerVersion; /* 3 */
    U32 SizeOfCode; /* 4 */
    U32 SizeOfInitializedData; /* 8 */
    U32 SizeOfUninitializedData; /* 12 */
    U32 AddressOfEntryPoint; /* Relative to ImageBase. */ /* 16 */
    U32 BaseOfCode; /* 20 */
#if !defined(TARGET_64BIT) || defined(SHIMCM32)
    U32 BaseOfData; /* 24 */
#endif
    /* Extension fields. */
#if defined(W32HACK) || defined(SHIMCM32)
    U32 ImageBase; /* 28 */
#else
    unsigned char *ImageBase; /* 24 or 28 */
#endif
    U32 SectionAlignment; /* 32 */
    U32 FileAlignment; /* 36 */
    unsigned short MajorOperatingSystemVersion; /* 40 */
    unsigned short MinorOperatingSystemVersion; /* 42 */
    unsigned short MajorImageVersion; /* 44 */
    unsigned short MinorImageVersion; /* 46 */
    unsigned short MajorSubsystemVersion; /* 48 */
    unsigned short MinorSubsystemVersion; /* 50 */
    U32 Win32VersionValue; /* Reserved, should be 0. */ /* 52 */
    U32 SizeOfImage; /* 56 */
    U32 SizeOfHeaders; /* 60 */
    U32 CheckSum; /* 64 */
    unsigned short Subsystem; /* 68 */
    unsigned short DllCharacteristics; /* 70 */
    U32 SizeOfStackReserve; /* 72 */
#if (defined(TARGET_64BIT) && !defined(SHIMCM32)) || defined(XXXZSHIM)
    U32 dummy1; /* 76 */
#endif
    U32 SizeOfStackCommit; /* 76 or 80 */
#if (defined(TARGET_64BIT) && !defined(SHIMCM32)) || defined(XXXZSHIM)
    U32 dummy2; /* 80 or 84 */
#endif
    U32 SizeOfHeapReserve; /* 80 or 88 */
#if (defined(TARGET_64BIT) && !defined(SHIMCM32)) || defined(XXXZSHIM)
    U32 dummy3; /* 84 or 92 */
#endif
    U32 SizeOfHeapCommit; /* 84 or 96 */
#if (defined(TARGET_64BIT) && !defined(SHIMCM32)) || defined(XXXZSHIM)
    U32 dummy4; /* 88 or 100 */
#endif
    U32 LoaderFlags; /* Reserved, should be 0. */ /* 88 or 104 */
    U32 NumberOfRvaAndSizes; /* Number of data directories. */ /* 92 or 108 */
} Pe32_optional_hdr; /* total length 96 or 112 */

#define MAGIC_PE32     0x10B
#define MAGIC_PE32PLUS 0x20B

typedef struct {
    U32 VirtualAddress;
    U32 Size;
} IMAGE_DATA_DIRECTORY;

/* Indexes of data directories. */
#define DATA_DIRECTORY_EXPORT_TABLE 0
#define DATA_DIRECTORY_IMPORT_TABLE 1
#define DATA_DIRECTORY_REL 5

typedef struct {
    U32 Characteristics; /* Reserved. */
    U32 TimeDateStamp;
    unsigned short MajorVersion;
    unsigned short MinorVersion;
    U32 Name;
    U32 Base; /* Subtract from ordinals from Import tables. */
    U32 NumberOfFunctions;
    U32 NumberOfNames; /* How many functions are exported by name. */
    U32 AddressOfFunctions;
    U32 AddressOfNames;
    U32 AddressOfNameOrdinals;
} IMAGE_EXPORT_DIRECTORY;

typedef struct {
    U32 OriginalFirstThunk;
    U32 TimeDateStamp;
    U32 ForwarderChain;
    U32 Name; /* DLL name RVA. */
    U32 FirstThunk;
} IMAGE_IMPORT_DESCRIPTOR;

typedef struct {
    U32 PageRva;
    U32 BlockSize; /* Number of all bytes in the block. */
} Base_relocation_block;

/* Relocation types. */
#define IMAGE_REL_BASED_ABSOLUTE 0 /* Skip this relocation. */
#define IMAGE_REL_BASED_HIGHLOW  3
#define IMAGE_REL_BASED_ARM_MOV32 5
#define IMAGE_REL_BASED_THUMB_MOV32 7
#define IMAGE_REL_BASED_DIR64 10

typedef struct {
    unsigned char Name[8];
    U32 VirtualSize;
    U32 VirtualAddress;
    U32 SizeOfRawData;
    U32 PointerToRawData;
    U32 PointerToRelocations;
    U32 PointerToLinenumbers; /* Deprecated, ignore. */
    unsigned short NumberOfRelocations;
    unsigned short NumberOfLinenumbers; /* Deprecated, ignore. */
    U32 Characteristics;
} Coff_section;

/* Section Characteristics. */
#define IMAGE_SCN_CNT_CODE           0x00000020
#define IMAGE_SCN_INITIALIZED_DATA   0x00000040
#define IMAGE_SCN_UNINITIALIZED_DATA 0x00000080

