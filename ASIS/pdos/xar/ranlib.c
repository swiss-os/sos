/******************************************************************************
 * @file            ranlib.c
 *****************************************************************************/
#include    <limits.h>
#include    <stddef.h>
#include    <stdio.h>
#include    <stdlib.h>
#include    <string.h>

#include    "ar.h"
#include    "lib.h"
#include    "report.h"

#define     GET_INT32(arr)              ((int32_t) arr[0] | (((int32_t) arr[1]) << 8) | (((int32_t) arr[2]) << 16) | (((int32_t) arr[3]) << 24))

#define     GET_UINT16(arr)             ((uint32_t) arr[0] | (((uint32_t) arr[1]) << 8))
#define     GET_UINT32(arr)             ((uint32_t) arr[0] | (((uint32_t) arr[1]) << 8) | (((uint32_t) arr[2]) << 16) | (((uint32_t) arr[3]) << 24))

struct aout_exec {

    unsigned char a_info[4];
    unsigned char a_text[4];
    unsigned char a_data[4];
    unsigned char a_bss[4];
    unsigned char a_syms[4];
    unsigned char a_entry[4];
    unsigned char a_trsize[4];
    unsigned char a_drsize[4];

};

struct aout_nlist {

    unsigned char n_strx[4];
    unsigned char n_type;
    
    unsigned char n_other;
    unsigned char n_desc[2];
    
    unsigned char n_value[4];

};

struct coff_exec {

    unsigned char Machine[2];
    unsigned char NumberOfSections[2];
    
    unsigned char TimeDateStamp[4];
    unsigned char PointerToSymbolTable[4];
    unsigned char NumberOfSymbols[4];
    
    unsigned char SizeOfOptionalHeader[2];
    unsigned char Characteristics[2];

};

struct coff_symbol {

    char Name[8];
    unsigned char Value[4];
    
    unsigned char SectionNumber[2];
    unsigned char Type[2];
    
    unsigned char StorageClass[1];
    unsigned char NumberOfAuxSymbols[1];

};

struct elf32_exec {

    unsigned char e_ident[16];
    unsigned char e_type[2];
    unsigned char e_machine[2];
    unsigned char e_version[4];
    unsigned char e_entry[4];
    unsigned char e_phoff[4];
    unsigned char e_shoff[4];
    unsigned char e_flags[4];
    unsigned char e_ehsize[2];
    unsigned char e_phentsize[2];
    unsigned char e_phnum[2];
    unsigned char e_shentsize[2];
    unsigned char e_shnum[2];
    unsigned char e_shstrndx[2];

};

struct elf64_exec {

    unsigned char e_ident[16];
    unsigned char e_type[2];
    unsigned char e_machine[2];
    unsigned char e_version[4];
    unsigned char e_entry[8];
    unsigned char e_phoff[8];
    unsigned char e_shoff[8];
    unsigned char e_flags[4];
    unsigned char e_ehsize[2];
    unsigned char e_phentsize[2];
    unsigned char e_phnum[2];
    unsigned char e_shentsize[2];
    unsigned char e_shnum[2];
    unsigned char e_shstrndx[2];

};

struct elf32_shdr {
    
    unsigned char sh_name[4];
    unsigned char sh_type[4];
    unsigned char sh_flags[4];
    unsigned char sh_addr[4];
    unsigned char sh_offset[4];
    unsigned char sh_size[4];
    unsigned char sh_link[4];
    unsigned char sh_info[4];
    unsigned char sh_addralign[4];
    unsigned char sh_entsize[4];

};

struct elf64_shdr {
    
    unsigned char sh_name[4];
    unsigned char sh_type[4];
    unsigned char sh_flags[8];
    unsigned char sh_addr[8];
    unsigned char sh_offset[8];
    unsigned char sh_size[8];
    unsigned char sh_link[4];
    unsigned char sh_info[4];
    unsigned char sh_addralign[8];
    unsigned char sh_entsize[8];

};

struct elf32_sym {

    unsigned char st_name[4];
    unsigned char st_value[4];
    unsigned char st_size[4];
    unsigned char st_info[1];
    unsigned char st_other[1];
    unsigned char st_shndx[2];

};

struct elf64_sym {

    unsigned char st_name[4];
    unsigned char st_info[1];
    unsigned char st_other[1];
    unsigned char st_shndx[2];
    unsigned char st_value[8];
    unsigned char st_size[8];

};

struct strtab {

    const char *name;
    long length, offset;

};

struct gstrtab {

    long count, max;
    struct strtab *strtabs;

};

static struct gstrtab gstrtab = { 0, 64, NULL };

static int add_strtab (struct gstrtab *gstrtab, struct strtab *strtab) {

    if (gstrtab->strtabs == NULL) {
    
        if ((gstrtab->strtabs = malloc (gstrtab->max * sizeof (*strtab))) == NULL) {
            return 1;
        }
    
    }
    
    if (gstrtab->count >= gstrtab->max) {
    
        void *tmp;
        
        gstrtab->max *= 2;
        
        if ((tmp = realloc (gstrtab->strtabs, gstrtab->max * sizeof (*strtab))) == NULL) {
            return 1;
        }
        
        gstrtab->strtabs = tmp;
    
    }
    
    gstrtab->strtabs[gstrtab->count] = *strtab;
    gstrtab->count++;
    
    return 0;

}

static void aout_get_symbols (void *object, long offset) {

    struct aout_exec *hdr = (struct aout_exec *) object;
    
    long sym_start = sizeof (*hdr) + GET_UINT32 (hdr->a_text) + GET_UINT32 (hdr->a_data) + GET_UINT32 (hdr->a_trsize) + GET_UINT32 (hdr->a_drsize);
    long strtab_start = sym_start + GET_UINT32 (hdr->a_syms);
    
    while (sym_start < strtab_start) {
    
        struct aout_nlist nlist;
        memcpy (&nlist, (char *) object + sym_start, sizeof (nlist));
        
        if (nlist.n_type == 5 || nlist.n_type == 7 || nlist.n_type == 9) {
        
            struct strtab *strtab;
            char *symname = (char *) object + strtab_start + GET_INT32 (nlist.n_strx);
            
            strtab = xmalloc (sizeof (*strtab));
            strtab->length = strlen (symname);
            
            strtab->name = xstrdup (symname);
            strtab->offset = offset;
            
            add_strtab (&gstrtab, strtab);
        
        }
        
        sym_start += sizeof (nlist);
    
    }

}

static void coff_get_symbols (void *object, long offset) {

    struct coff_exec *hdr = (struct coff_exec *) object;
    
    unsigned long sym_start = GET_UINT32 (hdr->PointerToSymbolTable);
    unsigned long sym_cnt = GET_UINT32 (hdr->NumberOfSymbols);
    unsigned long string_table_start = sym_start + (sizeof (struct coff_symbol) * sym_cnt);
    
    while (sym_cnt--) {
    
        struct coff_symbol sym;
        memcpy (&sym, (char *) object + sym_start, sizeof (sym));
        
        if (sym.StorageClass[0] == 2 && GET_UINT16 (sym.SectionNumber) != 0) {
        
            struct strtab *strtab;
            
            if (sym.Name[0] != 0) {
            
                int i, len;
                
                for (i = 0, len = 0; i < 8; i++) {
                
                    if (sym.Name[i] == '\0') {
                        break;
                    }
                    
                    len++;
                
                }
                
                strtab = xmalloc (sizeof (*strtab));
                strtab->length = len;
                
                strtab->name = xstrdup (sym.Name);
                strtab->offset = offset;
                
                add_strtab (&gstrtab, strtab);
            
            } else {
            
                unsigned char offset1 = (unsigned char) sym.Name[4];
                unsigned char offset2 = (unsigned char) sym.Name[5];
                unsigned char offset3 = (unsigned char) sym.Name[6];
                unsigned char offset4 = (unsigned char) sym.Name[7];
                
                long final_offset = ((uint32_t) offset1 | (((uint32_t) offset2) << 8) | (((uint32_t) offset3) << 16) | (((uint32_t) offset4) << 24));
                final_offset += string_table_start;
                
                strtab = xmalloc (sizeof (*strtab));
                strtab->length = strlen ((char *) object + final_offset);
                
                strtab->name = xstrdup ((char *) object + final_offset);
                strtab->offset = offset;
                
                add_strtab (&gstrtab, strtab);
            
            }
        
        }
        
        sym_start += sizeof (sym);
    
    }

}

#define     GET_ELF_UINT16(arr)         (endianess ? (((uint32_t) arr[0] << 8) | (((uint32_t) arr[1]))) : ((uint32_t) arr[0] | (((uint32_t) arr[1]) << 8)))

#define     GET_ELF_UINT32(arr)         (endianess ? (((uint32_t) arr[0] << 24) | (((uint32_t) arr[1]) << 16) | (((uint32_t) arr[2]) << 8) | (((uint32_t) arr[3])))                 \
    : ((uint32_t) arr[0] | (((uint32_t) arr[1]) << 8) | (((uint32_t) arr[2]) << 16) | (((uint32_t) arr[3]) << 24)))

#define     GET_ELF_UINT64(arr)                                                                                                                                                                                                                 \
    (endianess ? (((uint64_t) arr[0]) << 56) | (((uint64_t) arr[1]) << 48) | (((uint64_t) arr[2]) << 40) | (((uint64_t) arr[3]) >> 32) | (((uint64_t) arr[4]) << 24) | (((uint64_t) arr[5]) << 16) | (((uint64_t) arr[6]) << 8) | (((uint64_t) arr[7]))  \
        : ((uint64_t) arr[0]) | (((uint64_t) arr[1]) << 8) | (((uint64_t) arr[2]) << 16) | (((uint64_t) arr[3]) << 24) | (((uint64_t) arr[4]) << 32) | (((uint64_t) arr[5]) << 40) | (((uint64_t) arr[6]) << 48) | (((uint64_t) arr[7]) << 56))

static void elf32_get_symbols (void *object, long offset, int endianess) {

    struct elf32_exec *hdr = (struct elf32_exec *) object;
    
    unsigned long e_shnum = GET_ELF_UINT16 (hdr->e_shnum);
    unsigned long e_shoff = GET_ELF_UINT32 (hdr->e_shoff);
    unsigned long e_shentsize = GET_ELF_UINT16 (hdr->e_shentsize);
    
    unsigned long sh_link, sh_offset, sh_entsize, sh_size;
    unsigned long sym_strtab_size, i, j, st_name;
    
    struct elf32_shdr strtabhdr;
    struct elf32_shdr shdr;
    struct elf32_sym elf_symbol;
    
    struct strtab *strtab;
    char *sym_strtab;
    
    for (i = 1; i < e_shnum; i++) {
    
        memcpy (&shdr, (char *) object + e_shoff + i * e_shentsize, sizeof (shdr));
        
        if (GET_ELF_UINT32 (shdr.sh_type) != 2) {
            continue;
        }
        
        sh_link = GET_ELF_UINT32 (shdr.sh_link);
        sh_offset = GET_ELF_UINT32 (shdr.sh_offset);
        
        if (sh_link == 0 || sh_link >= e_shnum) {
            continue;
        }
        
        memcpy (&strtabhdr, (char *) object + e_shoff + sh_link * e_shentsize, sizeof (strtabhdr));
        
        if (GET_ELF_UINT32 (strtabhdr.sh_type) != 3) {
            continue;
        }
        
        sym_strtab_size = GET_ELF_UINT32 (strtabhdr.sh_size);
        sym_strtab = (char *) object + GET_ELF_UINT32 (strtabhdr.sh_offset);
        
        if ((sh_entsize = GET_ELF_UINT32 (shdr.sh_entsize)) < sizeof (elf_symbol)) {
            continue;
        }
        
        sh_size = GET_ELF_UINT32 (shdr.sh_size);
        
        for (j = 1; j < sh_size / sh_entsize; j++) {
        
            memcpy (&elf_symbol, (char *) object + sh_offset + j * sh_entsize, sizeof (elf_symbol));
            
            if ((st_name = GET_ELF_UINT32 (elf_symbol.st_name)) >= sym_strtab_size) {
                continue;
            }
            
            if (GET_ELF_UINT16 (elf_symbol.st_shndx) == 0 || (elf_symbol.st_info[0] >> 4) != 1) {
                continue;
            }
            
            if (sym_strtab[st_name] != '\0') {
            
                strtab = xmalloc (sizeof (*strtab));
                strtab->offset = offset;
                
                strtab->name = xstrdup (sym_strtab + st_name);
                strtab->length = strlen (strtab->name);
                
                add_strtab (&gstrtab, strtab);
            
            }
        
        }
    
    }

}

static void elf64_get_symbols (void *object, long offset, int endianess) {

    struct elf64_exec *hdr = (struct elf64_exec *) object;
    
    unsigned long e_shnum = GET_ELF_UINT16 (hdr->e_shnum);
    unsigned long e_shoff = GET_ELF_UINT64 (hdr->e_shoff);
    unsigned long e_shentsize = GET_ELF_UINT16 (hdr->e_shentsize);
    
    unsigned long sh_link, sh_offset, sh_entsize, sh_size;
    unsigned long sym_strtab_size, i, j, st_name;
    
    struct elf64_shdr strtabhdr;
    struct elf64_shdr shdr;
    struct elf64_sym elf_symbol;
    
    struct strtab *strtab;
    char *sym_strtab;
    
    for (i = 1; i < e_shnum; i++) {
    
        memcpy (&shdr, (char *) object + e_shoff + i * e_shentsize, sizeof (shdr));
        
        if (GET_ELF_UINT32 (shdr.sh_type) != 2) {
            continue;
        }
        
        sh_link = GET_ELF_UINT32 (shdr.sh_link);
        sh_offset = GET_ELF_UINT64 (shdr.sh_offset);
        
        if (sh_link == 0 || sh_link >= e_shnum) {
            continue;
        }
        
        memcpy (&strtabhdr, (char *) object + e_shoff + sh_link * e_shentsize, sizeof (strtabhdr));
        
        if (GET_ELF_UINT32 (strtabhdr.sh_type) != 3) {
            continue;
        }
        
        sym_strtab_size = GET_ELF_UINT64 (strtabhdr.sh_size);
        sym_strtab = (char *) object + GET_ELF_UINT64 (strtabhdr.sh_offset);
        
        if ((sh_entsize = GET_ELF_UINT64 (shdr.sh_entsize)) < sizeof (elf_symbol)) {
            continue;
        }
        
        sh_size = GET_ELF_UINT64 (shdr.sh_size);
        
        for (j = 1; j < sh_size / sh_entsize; j++) {
        
            memcpy (&elf_symbol, (char *) object + sh_offset + j * sh_entsize, sizeof (elf_symbol));
            
            if ((st_name = GET_ELF_UINT32 (elf_symbol.st_name)) >= sym_strtab_size) {
                continue;
            }
            
            if (GET_ELF_UINT16 (elf_symbol.st_shndx) == 0 || (elf_symbol.st_info[0] >> 4) != 1) {
                continue;
            }
            
            if (sym_strtab[st_name] != '\0') {
            
                strtab = xmalloc (sizeof (*strtab));
                strtab->offset = offset;
                
                strtab->name = xstrdup (sym_strtab + st_name);
                strtab->length = strlen (strtab->name);
                
                add_strtab (&gstrtab, strtab);
            
            }
        
        }
    
    }

}

static void hunk_get_symbols (void *object, unsigned long bytes, long offset) {

    unsigned char *pos = (unsigned char *) object + 4;
    unsigned long name_size, size;
    
    struct strtab *strtab;
    
    name_size = array_to_integer (pos, 4, 1);
    name_size *= 4;
    
    pos = pos + 4 + name_size;
    
    while (pos < (unsigned char *) object + bytes) {
    
        if (pos[2] == 0x03 && pos[3] == 0xE7){
            break;
        }
        
        if (pos[2] == 0x03 && pos[3] == 0xF2) {
        
            pos += 4;
            continue;
        
        }
        
        if (pos[2] == 0x03 && (pos[3] == 0xE8 || pos[3] == 0xE9 || pos[3] == 0xEA || pos[3] == 0xEB)) {
        
            pos += 4;
            
            if (pos[3] != 0xEB) {
            
                size = array_to_integer (pos, 4, 1);
                size *= 4;
                
                pos = pos + 4 + size;
            
            }
            
            continue;
        
        }
        
        if (pos[2] == 0x03 && pos[3] == 0xEF) {
        
            unsigned char symbol_type;
            unsigned long num_ref;
            
            char *symname;
            pos += 4;
            
            while (1) {
            
                name_size = array_to_integer (pos, 4, 1);
                pos += 4;
                
                if (name_size == 0) {
                    break;
                }
                
                symbol_type = (name_size >> 24) & 0xff;
                
                name_size &= 0xffffff;
                name_size *= 4;
                
                symname = xstrndup ((char *) pos, name_size);
                pos += name_size;
                
                if (symbol_type == 1 || symbol_type == 2) {
                
                    if (symbol_type == 1) {
                    
                        strtab = xmalloc (sizeof (*strtab));
                        strtab->length = strlen (symname);
                        
                        strtab->name = xstrdup (symname);
                        strtab->offset = offset;
                        
                        add_strtab (&gstrtab, strtab);
                    
                    }
                    
                    pos += 4;
                
                } else if (symbol_type == 129 || symbol_type == 130 || symbol_type == 136) {
                
                    if (symbol_type == 130) {
                        pos += 4;
                    }
                    
                    num_ref = array_to_integer (pos, 4, 1);
                    num_ref *= 4;
                    
                    pos = pos + 4 + num_ref;
                
                }
                
                free (symname);
            
            }
            
            continue;
        
        }
        
        if (pos[2] == 0x03 && pos[3] == 0xEC) {
        
            pos += 4;
            
            while (1) {
            
                size = array_to_integer (pos, 4, 1) * 4;
                pos += 4;
                
                if (size == 0) {
                    break;
                }
                
                pos = pos + size + 4;
            
            }
            
            continue;
        
        }
    
    }

}

#define     RECORD_TYPE_EXTDEF          0x8C
#define     RECORD_TYPE_PUBDEF          0x90

static void omf_get_symbols (void *object, char *filename, unsigned long bytes, long offset) {

    unsigned char *pos = (unsigned char *) object;
    
    unsigned char record_type;
    unsigned short record_len;
    
    unsigned char *pubdef_name, *pubdef_name_end;
    unsigned char pubdef_name_len;
    
    unsigned char *extdef_name, *extdef_name_end;
    unsigned char extdef_name_len;
    
    struct strtab *strtab;
    int big_fields;
    
    while (pos < (unsigned char *) object + bytes) {
    
        record_type = pos[0];
        
        big_fields = record_type & 1;
        record_type &= ~1;

        record_len = array_to_integer (pos + 1, 2, 0);
        if (record_len > (bytes - 3))
        {
            report_at (program_name,
                       0,
                       REPORT_FATAL_ERROR,
                       "%s: record length hex %x too long",
                       filename,
                       record_len);
            exit (EXIT_FAILURE);
        }
        
        {
        
            unsigned char checksum = 0;
            unsigned long i;
            
            for (i = 0; i < (unsigned long) record_len + 3; i++) {
                checksum += pos[i];
            }
            
            if (checksum != 0) {
                report_at (program_name, 0, REPORT_WARNING, "%s: invalid checksum", filename);
            }
        
        }
        
        pos += 3;
        
        if (record_type == RECORD_TYPE_EXTDEF) {
        
            extdef_name_end = (extdef_name = pos) + record_len - 1;
            
            while (extdef_name != extdef_name_end) {
            
                extdef_name_len = extdef_name[0];
                
                if (extdef_name + 1 + extdef_name_len + 1 > extdef_name_end) {
                
                    report_at (program_name, 0, REPORT_FATAL_ERROR, "%s: incorrect string length", filename);
                    exit (EXIT_FAILURE);
                
                }
                
                strtab = xmalloc (sizeof (*strtab));
                strtab->length = extdef_name_len;
                
                strtab->name = xstrndup ((char *) extdef_name + 1, extdef_name_len);
                strtab->offset = offset;
                
                /*report_at (program_name, 0, REPORT_WARNING, "Got length of %#x for %s", extdef_name_len, strtab->name);*/
                
                add_strtab (&gstrtab, strtab);
                extdef_name = extdef_name + 1 + extdef_name_len + 1;
            
            }
        
        } else if (record_type == RECORD_TYPE_PUBDEF) {
        
            pubdef_name_end = (pubdef_name = pos) + record_len - 3;
            
            if (big_fields) {
            
                report_at (program_name, 0, REPORT_INTERNAL_ERROR, "%s: big fields not supported for record %#x", filename, record_type);
                exit (EXIT_FAILURE);
            
            }
            
            while (pubdef_name != pubdef_name_end) {
            
                pubdef_name_len = pubdef_name[2];
                
                if (pubdef_name + 2 + 1 + pubdef_name_len + 1 > pubdef_name_end) {
                
                    report_at (program_name, 0, REPORT_FATAL_ERROR, "%s: incorrect string length", filename);
                    exit (EXIT_FAILURE);
                
                }
                
                strtab = xmalloc (sizeof (*strtab));
                strtab->length = pubdef_name_len;
                
                strtab->name = xstrndup ((char *) pubdef_name + 3, pubdef_name_len);
                strtab->offset = offset;
                
                /*report_at (program_name, 0, REPORT_WARNING, "Got length of %#x for %s", pubdef_name_len, strtab->name);*/
                
                add_strtab (&gstrtab, strtab);
                pubdef_name = pubdef_name + 2 + 1 + pubdef_name_len + 1;
            
            }
        
        }
        
        pos += record_len;
    
    }

}

void ranlib (void) {

    FILE *tfp = tmpfile ();
    
    struct ar_header header;
    long i, j, len, read, val;
    
    unsigned char *object;
    void *contents;
    
    char temp[16];
    long offset = 0;
    
#if     UINT_MAX == 65535
    long bytes;
#else
    int bytes;
#endif
    
    for (;;) {
    
        struct ar_header hdr;
        long bytes, real_size;
        
        if (fread (&hdr, sizeof (hdr), 1, arfp) != 1) {
        
            if (feof (arfp)) {
                break;
            }
            
            report_at (program_name, 0, REPORT_ERROR, "failed whilst reading '%s'", state->outfile);
            return;
        
        }
        
        bytes = conv_dec (hdr.size, 10);
        real_size = bytes;
        
        if (bytes % 2) {
            bytes++;
        }
        
        if (memcmp (hdr.name, "/", 1) == 0) {
        
            fseek (arfp, bytes, SEEK_CUR);
            continue;
        
        }
        
        object = xmalloc (bytes);
        
        if (fread (object, bytes, 1, arfp) != 1) {
        
            free (object);
            
            report_at (program_name, 0, REPORT_ERROR, "failed to read %ld bytes from %s", bytes, state->outfile);
            exit (EXIT_FAILURE);
            
        
        }
        
        if (object[2] == 0x03 && object[3] == 0xE7) {
        
            hunk_get_symbols (object, real_size, offset + 8);
            free (object);
            
            offset += sizeof (hdr);
            offset += bytes;
            
            continue;
        
        }
        
        if (object[0] == 0x07 && object[1] == 0x01) {
        
            aout_get_symbols (object, offset + 8);
            free (object);
            
            offset += sizeof (hdr);
            offset += bytes;
            
            continue;
        
        }
        
        if ((object[0] == 0x4C && object[1] == 0x01) || (object[0] == 0x64 && object[1] == 0x86)) {
        
            coff_get_symbols (object, offset + 8);
            free (object);
            
            offset += sizeof (hdr);
            offset += bytes;
            
            continue;
        
        }
        
        if (object[0] == 0x7f && memcmp (object + 1, "ELF", 3) == 0) {

            int endianess = (object[5] == 2);

            if (object[4] == 2) {
                elf64_get_symbols (object, offset + 8, endianess);
            } else {
                elf32_get_symbols (object, offset + 8, endianess);
            }
            
            free (object);
            
            offset += sizeof (hdr);
            offset += bytes;
            
            continue;
        
        }
        
        if (object[0] == 0x80 /* RECORD_TYPE_THEADR */) {
        
            char filename[17] = { 0 };
            memcpy (filename, hdr.name, 16);
            
            for (i = 16; i >= 0; --i) {
            
                if (filename[i] == ' ') {
                    filename[i] = '\0';
                }
            
            }
            
            omf_get_symbols (object, filename, real_size, offset + 8);
            free (object);
            
            offset += sizeof (hdr);
            offset += bytes;
            
            continue;
        
        }
        
        free (object);
        
        offset += sizeof (hdr);
        offset += bytes;
    
    }
    
    fseek (arfp, 8, SEEK_SET);
    bytes = 0;
    
    for (i = 0; i < gstrtab.count; ++i) {
        bytes += gstrtab.strtabs[i].length + 5;
    }
    
    for (i = 0; i < gstrtab.count; ++i) {
    
        gstrtab.strtabs[i].offset += bytes;
        
        if (bytes % 2) {
            gstrtab.strtabs[i].offset++;
        }
    
    }
    
    if (fwrite ("!<arch>\n", 8, 1, tfp) != 1) {
    
        fclose (tfp);
        
        report_at (program_name, 0, REPORT_ERROR, "failed whilst writing ar header");
        return;
    
    }
    
    memset (temp, ' ', 16);
    temp[0] = '0';
    
    len = 1;
    memcpy (header.name, "/", len);
    
    while (len < 16) {
        header.name[len++] = ' ';
    }
    
    memcpy (header.mtime, temp, 12);
    memcpy (header.owner, temp, 6);
    memcpy (header.group, temp, 6);
    memcpy (header.mode, temp, 8);
    
#if     UINT_MAX == 65535
    len = sprintf (temp, "%ld", bytes + 4);
#else
    len = sprintf (temp, "%d", bytes + 4);
#endif
    
    temp[len] = ' ';
    memcpy (header.size, temp, 10);
    
    header.endsig[0] = '`';
    header.endsig[1] = '\n';
    
    if (fwrite (&header, sizeof (header), 1, tfp) != 1) {
    
        fclose (tfp);
        
        report_at (program_name, 0, REPORT_ERROR, "failed whilst writing header");
        return;
    
    }
    
    val = gstrtab.count;
    
    for (i = 0; i < 4; ++i) {
        temp[4 - 1 - i] = (val >> (CHAR_BIT * i)) & UCHAR_MAX;
    }
    
    if (fwrite (temp, 4, 1, tfp) != 1) {
        exit (EXIT_FAILURE);
    }
    
    for (i = 0; i < gstrtab.count; ++i) {
    
        val = gstrtab.strtabs[i].offset + 4 + sizeof (header);
        
        for (j = 0; j < 4; ++j) {
            temp[4 - 1 - j] = (val >> (CHAR_BIT * j)) & UCHAR_MAX;
        }
        
        if (fwrite (temp, 4, 1, tfp) != 1) {
            exit (EXIT_FAILURE);
        }
    
    }
    
    for (i = 0; i < gstrtab.count; ++i) {
    
        const char *name = gstrtab.strtabs[i].name;
        long length = gstrtab.strtabs[i].length;
        
        if (fwrite (name, length, 1, tfp) != 1) {
            exit (EXIT_FAILURE);
        }
        
        temp[0] = '\0';
        
        if (fwrite (temp, 1, 1, tfp) != 1) {
            exit (EXIT_FAILURE);
        }
    
    }
    
    if (bytes % 2) {
    
        temp[0] = '\0';
        
        if (fwrite (temp, 1, 1, tfp) != 1) {
            exit (EXIT_FAILURE);
        }
    
    }
    
    for (;;) {
    
        struct ar_header hdr;
        
        if (fread (&hdr, sizeof (hdr), 1, arfp) != 1) {
        
            if (feof (arfp)) {
                break;
            }
            
            report_at (program_name, 0, REPORT_ERROR, "failed whilst reading '%s'", state->outfile);
            return;
        
        }
        
        bytes = conv_dec (hdr.size, 10);
        
        if (bytes % 2) {
            bytes++;
        }
        
        if (memcmp (hdr.name, "/", 1) == 0) {
        
            fseek (arfp, bytes, SEEK_CUR);
            continue;
        
        }
        
        if (fwrite (&hdr, sizeof (hdr), 1, tfp) != 1) {
        
            fclose (tfp);
            
            report_at (program_name, 0, REPORT_ERROR, "failed whilst writing header");
            exit (EXIT_FAILURE);
        
        }
        
        contents = xmalloc (512);
        
        for (;;) {
        
            if (bytes == 0 || feof (arfp)) {
                break;
            } else if (bytes >= 512) {
                read = 512;
            } else {
                read = bytes;
            }
            
            if (fread (contents, read, 1, arfp) != 1) {
            
                free (contents);
                fclose (tfp);
                
                report_at (NULL, 0, REPORT_ERROR, "failed to read %ld bytes from %s", bytes, state->outfile);
                exit (EXIT_FAILURE);
            
            }
            
            bytes -= read;
            
            if (fwrite (contents, read, 1, tfp) != 1) {
            
                free (contents);
                fclose (tfp);
                
                report_at (NULL, 0, REPORT_ERROR, "failed to write temp file");
                exit (EXIT_FAILURE);
            
            }
        
        }
        
        free (contents);
    
    }
    
    fclose (arfp);
    remove (state->outfile);
    
    if ((arfp = fopen (state->outfile, "w+b")) == NULL) {
    
        fclose (tfp);
        
        report_at (program_name, 0, REPORT_ERROR, "failed to open %s for writing", state->outfile);
        exit (EXIT_FAILURE);
    
    }
    
    contents = xmalloc (512);
    bytes = ftell (tfp);
    
    fseek (arfp, 0, SEEK_SET);
    fseek (tfp, 0, SEEK_SET);
    
    for (;;) {
    
        if (bytes == 0 || feof (tfp)) {
            break;
        } else if (bytes >= 512) {
            read = 512;
        } else {
            read = bytes;
        }
        
        if (fread (contents, read, 1, tfp) != 1) {
            
            free (contents);
            fclose (tfp);
            
            report_at (program_name, 0, REPORT_ERROR, "failed whilst reading temp file");
            return;
        
        }
        
        bytes -= read;
        
        if (fwrite (contents, read, 1, arfp) != 1) {
        
            free (contents);
            fclose (tfp);
            
            report_at (program_name, 0, REPORT_ERROR, "failed whilst writing %s", state->outfile);
            exit (EXIT_FAILURE);
        
        }
    
    }
    
    free (contents);
    fclose (tfp);

}

