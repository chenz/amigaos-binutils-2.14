# This shell script emits a C file. -*- C -*-
# It does some substitutions.
cat >e${EMULATION_NAME}.c <<EOF
/* This file is is generated by a shell script.  DO NOT EDIT! */

/* emulate the original gld for the given ${EMULATION_NAME}
   Copyright (C) 1991, 1993 Free Software Foundation, Inc.
   Written by Steve Chamberlain steve@cygnus.com

This file is part of GLD, the Gnu Linker.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

#define TARGET_IS_${EMULATION_NAME}

#include "bfd.h"
#include "sysdep.h"
#include "bfdlink.h"
#include "getopt.h"

#include "ld.h"
#include "ldmain.h"
#include "ldmisc.h"
#include "ldexp.h"
#include "ldlang.h"
#include "ldfile.h"
#include "ldemul.h"
#include "ldctor.h"

#include "libamiga.h"

/* shared functions */
void amiga_add_options PARAMS ((int, char **, int, struct option **, int, struct option **));
bfd_boolean amiga_handle_option PARAMS ((int));
void amiga_after_parse PARAMS ((void));
void amiga_after_open PARAMS ((void));
void amiga_after_allocation PARAMS ((void));

/* amigaoslink.c variables */

/* 1 means, write out debug hunk, when producing a load file */
extern int write_debug_hunk;

/* This is the attribute to use for the next file */
extern int amiga_attribute;

/* generate a combined data+bss hunk */
extern int amiga_base_relative;

/* generate a resident executable */
extern int amiga_resident;

static void gld${EMULATION_NAME}_before_parse PARAMS ((void));
static char *gld${EMULATION_NAME}_get_script PARAMS ((int *isfile));

#if defined(TARGET_IS_amiga)

/* Handle amiga specific options */

enum {
  OPTION_IGNORE = 300,
  OPTION_AMIGA_CHIP,
  OPTION_AMIGA_FAST,
  OPTION_AMIGA_ATTRIBUTE,
  OPTION_AMIGA_DEBUG,
  OPTION_AMIGA_DATABSS_TOGETHER,
  OPTION_AMIGA_DATADATA_RELOC,
  OPTION_FLAVOR
};

void
amiga_add_options (ns, shortopts, nl, longopts, nrl, really_longopts)
     int ns ATTRIBUTE_UNUSED;
     char **shortopts ATTRIBUTE_UNUSED;
     int nl;
     struct option **longopts;
     int nrl ATTRIBUTE_UNUSED;
     struct option **really_longopts ATTRIBUTE_UNUSED;
{
  static const struct option xtra_long[] = {
    {"flavor", required_argument, NULL, OPTION_FLAVOR},
    {"amiga-datadata-reloc", no_argument, NULL, OPTION_AMIGA_DATADATA_RELOC},
    {"amiga-databss-together", no_argument, NULL, OPTION_AMIGA_DATABSS_TOGETHER},
    {"amiga-debug-hunk", no_argument, NULL, OPTION_AMIGA_DEBUG},
    {"attribute", required_argument, NULL, OPTION_AMIGA_ATTRIBUTE},
    {"fast", no_argument, NULL, OPTION_AMIGA_FAST},
    {"chip", no_argument, NULL, OPTION_AMIGA_CHIP},
    {NULL, no_argument, NULL, 0}
  };

  *longopts = (struct option *)
    xrealloc (*longopts, nl * sizeof (struct option) + sizeof (xtra_long));
  memcpy (*longopts + nl, &xtra_long, sizeof (xtra_long));
}

bfd_boolean
amiga_handle_option (optc)
     int optc;
{
  switch (optc)
    {
    default:
      return FALSE;

    case 0:
      /* Long option which just sets a flag.  */
      break;

    case OPTION_AMIGA_CHIP:
      amiga_attribute = MEMF_CHIP;
      break;

    case OPTION_AMIGA_FAST:
      amiga_attribute = MEMF_FAST;
      break;

    case OPTION_AMIGA_ATTRIBUTE:
      {
	char *end;
	amiga_attribute = strtoul (optarg, &end, 0);
	if (*end)
	  einfo ("%P%F: invalid number \`%s\'\n", optarg);
      }
      break;

    case OPTION_AMIGA_DEBUG:
      write_debug_hunk = 1; /* Write out debug hunk */
      break;

    case OPTION_AMIGA_DATABSS_TOGETHER:
      amiga_base_relative = 1; /* Combine data and bss */
      break;

    case OPTION_AMIGA_DATADATA_RELOC:
      amiga_resident = 1; /* Write out datadata_reloc array */
      break;

    case OPTION_FLAVOR:
      ldfile_add_flavor (optarg);
      break;
    }

  return TRUE;
}

void 
amiga_after_parse ()
{
  ldfile_sort_flavors();
}

void 
amiga_after_open ()
{
  ldctor_build_sets ();
}

static void
amiga_assign_attribute (inp)
     lang_input_statement_type *inp;
{
  asection *s;

  if (inp->the_bfd->xvec->flavour==bfd_target_amiga_flavour)
    {
      for (s=inp->the_bfd->sections;s!=NULL;s=s->next)
	amiga_per_section(s)->attribute=inp->amiga_attribute;
    }
}

void
amiga_after_allocation ()
{
  if (0) /* Does not work at the moment */
    lang_for_each_input_file (amiga_assign_attribute);
}

#endif

static void
gld${EMULATION_NAME}_before_parse ()
{
  write_debug_hunk = 0;

#if defined(TARGET_IS_amiga_bss)
  amiga_base_relative = 1;
#endif

#ifndef TARGET_ /* I.e., if not generic.  */
  ldfile_output_architecture = bfd_arch_${ARCH};
#endif /* not TARGET_ */
}

static char *
gld${EMULATION_NAME}_get_script (isfile)
     int *isfile;
EOF

if test -n "$COMPILE_IN"
then
# Scripts compiled in.

# sed commands to quote an ld script as a C string.
sc="-f stringify.sed"

cat >>e${EMULATION_NAME}.c <<EOF
{
  *isfile = 0;

  if (link_info.relocateable == TRUE && config.build_constructors == TRUE)
    return
EOF
sed $sc ldscripts/${EMULATION_NAME}.xu                     >> e${EMULATION_NAME}.c
echo '  ; else if (link_info.relocateable == TRUE) return' >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xr                     >> e${EMULATION_NAME}.c
echo '  ; else if (!config.text_read_only) return'         >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xbn                    >> e${EMULATION_NAME}.c
echo '  ; else if (!config.magic_demand_paged) return'     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xn                     >> e${EMULATION_NAME}.c
echo '  ; else return'                                     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.x                      >> e${EMULATION_NAME}.c
echo '; }'                                                 >> e${EMULATION_NAME}.c

else
# Scripts read from the filesystem.

cat >>e${EMULATION_NAME}.c <<EOF
{
  *isfile = 1;

  if (link_info.relocateable == TRUE && config.build_constructors == TRUE)
    return "ldscripts/${EMULATION_NAME}.xu";
  else if (link_info.relocateable == TRUE)
    return "ldscripts/${EMULATION_NAME}.xr";
  else if (!config.text_read_only)
    return "ldscripts/${EMULATION_NAME}.xbn";
  else if (!config.magic_demand_paged)
    return "ldscripts/${EMULATION_NAME}.xn";
  else
    return "ldscripts/${EMULATION_NAME}.x";
}
EOF

fi

cat >>e${EMULATION_NAME}.c <<EOF

struct ld_emulation_xfer_struct ld_${EMULATION_NAME}_emulation = 
{
  gld${EMULATION_NAME}_before_parse,	/* before_parse */
  syslib_default,			/* syslib */
  hll_default,				/* hll */
  amiga_after_parse,			/* after_parse */
  amiga_after_open,			/* after_open */
  amiga_after_allocation,		/* after_allocation */
  set_output_arch_default,		/* set_output_arch */
  ldemul_default_target,		/* choose_target */
  before_allocation_default,		/* before_allocation */
  gld${EMULATION_NAME}_get_script,	/* get_script */
  "${EMULATION_NAME}",			/* emulation_name */
  "${OUTPUT_FORMAT}",			/* target_name */
  NULL,					/* finish */
  NULL,					/* create_output_section_statements */
  NULL,					/* open_dynamic_library */
  NULL,					/* place_orphan */
  NULL,					/* set_symbols */
  NULL,					/* parse_args */
  amiga_add_options,			/* add_options */
  amiga_handle_option,			/* handle_option */
  NULL,					/* unrecognized file */
  NULL,					/* list_options */
  NULL,					/* recognized_file */
  NULL,					/* find potential_libraries */
  NULL					/* new_vers_pattern */
};
EOF
