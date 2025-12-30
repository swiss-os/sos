/******************************************************************************
 * @file            forc4to8.c
 *
 * Released to the public domain.
 *
 * Anyone and anything may copy, edit, publish, use, compile, sell and
 * distribute this work and all its parts in any form for any purpose,
 * commercial and non-commercial, without any restrictions, without
 * complying with any conditions and by any means.
 *****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "xmalloc.h"
#include "bytearray.h"
#include "elf.h"

#include "elf_bytearray.h"

static int endianess = LITTLE_ENDIAN;

#define READ_MEM_INCREMENT 60000 /* 1/2 of size of a certain archive file. */

int read_file_into_memory (const char *filename, unsigned char **memory_p, size_t *size_p)
{
    size_t mem_size = READ_MEM_INCREMENT;
    size_t read_bytes = 0;
    size_t change;
    unsigned char *memory;
    FILE *infile;

    if ((infile = fopen (filename, "rb")) == NULL) return 1;

    memory = xmalloc (mem_size + 2);
    while ((change = fread (memory + read_bytes, 1, mem_size - read_bytes, infile)) > 0) {

        read_bytes += change;
        if (read_bytes == mem_size) {
            mem_size += READ_MEM_INCREMENT;
            memory = xrealloc (memory, mem_size + 2);
        }

    }

    /* Protection against corrupted string tables. */
    memory[read_bytes] = '\0';
    memory[read_bytes + 1] = '\0';

    fclose (infile);
    *memory_p = memory;
    *size_p = read_bytes;

    return 0;
}

#define CHECK_READ(memory_position, size_to_read) \
    do { if (((memory_position) - file + (size_to_read) > file_size) \
             || (memory_position) < file) { fprintf (stderr, "corrupted input file\n"); free (file); exit (EXIT_FAILURE); } } while (0)

#define ld_error printf
#define ld_fatal_error printf

static int read_and_forc4to8_elf_object (unsigned char *file, size_t file_size, const char *filename)
{
    struct Elf32_Ehdr_internal ehdr;
    struct Elf32_Shdr_internal shdr;

    const char *section_name_string_table = NULL;
    Elf32_Word section_name_string_table_size;

    unsigned char *pos;

    Elf32_Half i;

    endianess = LITTLE_ENDIAN;

    pos = file;
    CHECK_READ (pos, SIZEOF_struct_Elf32_Ehdr_file);
    read_struct_Elf32_Ehdr (&ehdr, pos, endianess);

    if (ehdr.e_ident[EI_CLASS] != ELFCLASS32) {
        ld_error ("%s: Unsupported ELF file class", filename);
        return 1;
    }

    if (ehdr.e_ident[EI_DATA] == ELFDATA2LSB) {
        /* Nothing needs to be done. */
    } else if (ehdr.e_ident[EI_DATA] == ELFDATA2MSB) {
        endianess = BIG_ENDIAN;
        read_struct_Elf32_Ehdr (&ehdr, pos, endianess);
    } else {
        ld_error ("%s: Unsupported ELF data encoding", filename);
        return 1;
    }

    if (ehdr.e_ident[EI_VERSION] != EV_CURRENT) {
        ld_error ("%s: Unsupported ELF version", filename);
        return 1;
    }

    if (ehdr.e_type != ET_REL) {
        ld_error ("%s: e_type is not ET_REL", filename);
        return 1;
    }

    if (ehdr.e_machine != EM_S370) {
        printf ("only EM_S370 is supported\n");
        return 1;
    }

    if (ehdr.e_version != EV_CURRENT) {
        ld_error ("%s: e_version is not EV_CURRENT", filename);
        return 1;
    }

    if (ehdr.e_ehsize < SIZEOF_struct_Elf32_Ehdr_file) {
        ld_error ("%s: e_ehsize is too small", filename);
        return 1;
    }

    if (ehdr.e_shoff == 0 || ehdr.e_shentsize == 0 || ehdr.e_shnum == 0) {
        ld_error ("%s: missing section header table", filename);
        return 1;
    }

    if (ehdr.e_shentsize < SIZEOF_struct_Elf32_Shdr_file) {
        ld_error ("%s: e_shentsize is too small", filename);
        return 1;
    }

    if (ehdr.e_shstrndx == 0 || ehdr.e_shstrndx >= ehdr.e_shnum) {
        ld_error ("%s: missing section name string table", filename);
        return 1;
    }

    pos = file + ehdr.e_shoff;
    CHECK_READ (pos, ehdr.e_shentsize * ehdr.e_shnum);

    pos += ehdr.e_shentsize * ehdr.e_shstrndx;
    read_struct_Elf32_Shdr (&shdr, pos, endianess);

    if (shdr.sh_type != SHT_STRTAB) {
        ld_error ("section name string table does not have SHT_STRTAB type");
        return 1;
    }

    section_name_string_table_size = shdr.sh_size;
    pos = file + shdr.sh_offset;
    CHECK_READ (pos, section_name_string_table_size);
    section_name_string_table = (char *)pos;

    for (i = 1; i < ehdr.e_shnum; i++) {
        size_t j;
        size_t relocation_count;
        
        pos = file + ehdr.e_shoff + i * ehdr.e_shentsize;
        read_struct_Elf32_Shdr (&shdr, pos, endianess);

        if ((shdr.sh_type != SHT_RELA
             && shdr.sh_type != SHT_REL)
            || shdr.sh_size == 0) continue;

        if (shdr.sh_info >= ehdr.e_shnum) {
            ld_fatal_error ("%s: relocation section has invalid sh_info", filename);
        }


        if ((shdr.sh_type == SHT_RELA
             && shdr.sh_entsize != SIZEOF_struct_Elf32_Rela_file)
            || (shdr.sh_type == SHT_REL
                && shdr.sh_entsize != SIZEOF_struct_Elf32_Rel_file)) {
            printf ("relocation shdr.sh_entsize not yet supported\n");
            return 1;
        }

        pos = file + shdr.sh_offset;
        CHECK_READ (pos, shdr.sh_size);

        relocation_count = shdr.sh_size / shdr.sh_entsize;

        if (shdr.sh_type == SHT_RELA) {
            for (j = 0; j < relocation_count; j++) {
                struct Elf32_Rela_internal rela;
                Elf32_Word symbol_index;
                Elf32_Word rel_type;
                
                read_struct_Elf32_Rela (&rela, pos + shdr.sh_entsize * j, endianess);
                symbol_index = ELF32_R_SYM (rela.r_info);
                rel_type = ELF32_R_TYPE (rela.r_info);
                if (rel_type == R_386_32) {
                    rela.r_info = ELF32_R_INFO (symbol_index, R_390_64);
                    write_struct_Elf32_Rela (pos + shdr.sh_entsize * j, &rela, endianess);
                }
            }
        } else {
            for (j = 0; j < relocation_count; j++) {
                struct Elf32_Rel_internal rel;
                Elf32_Word symbol_index;
                Elf32_Word rel_type;
                
                read_struct_Elf32_Rel (&rel, pos + shdr.sh_entsize * j, endianess);
                symbol_index = ELF32_R_SYM (rel.r_info);
                rel_type = ELF32_R_TYPE (rel.r_info);
                if (rel_type == R_386_32) {
                    rel.r_info = ELF32_R_INFO (symbol_index, R_390_64);
                    write_struct_Elf32_Rel (pos + shdr.sh_entsize * j, &rel, endianess);
                }
            }
        }
    }

    return 0;
}

int main (int argc, char **argv)
{
    unsigned char *file;
    size_t file_size;
    FILE *outfile;
    const char *in_filename, *out_filename;
    
    if (argc != 3)
    {
        printf("usage: %s file output_file\n", argv[0]);
        return (0);
    }

    in_filename = argv[1];
    out_filename = argv[2];
    
    if (read_file_into_memory (in_filename, &file, &file_size)) {
        fprintf (stderr, "failed to read '%s'\n", in_filename);
        return EXIT_FAILURE;
    }

    if (read_and_forc4to8_elf_object (file, file_size, in_filename)) return 1;

    if (!(outfile = fopen (out_filename, "wb"))) {
        fprintf (stderr, "cannot open '%s' for writing\n", out_filename);
        free (file);
        return EXIT_FAILURE;
    }
    if (outfile) {
        if (fwrite (file, file_size, 1, outfile) != 1) {
            fprintf (stderr, "writing '%s' file failed\n", out_filename);
            free (file);
            return EXIT_FAILURE;
        }
        fclose (outfile);
    }
    
    free (file);
    
    return 0;
}
