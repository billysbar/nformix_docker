/**************************************************************************/
/*                                                                        */
/*  Licensed Materials - Property of IBM                                  */
/*                                                                        */
/*  "Restricted Materials of IBM"                                         */
/*                                                                        */
/*  IBM Informix GLS                                                      */
/*  Copyright IBM Corporation 1996, 2008 All rights reserved.             */
/*                                                                        */
/**************************************************************************/

/*  Title:       gls.h
 *  Description: Header file for international support library
 */

#ifndef GLS_INCLUDED
#define GLS_INCLUDED

/* For Win64,gl_intptr represent 8 byte quantity..be it a pointer or simply 8 byte.This is because long is till 4 bytes on Win64 */

#ifdef _WIN64
typedef __int64 gl_intptr;
typedef unsigned __int64 gl_uintptr;
#else
typedef long gl_intptr;
typedef unsigned long gl_uintptr;
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__STDC__)
#include <stddef.h>
#include <string.h>
#else
#include <sys/types.h>
#endif

#include <stdio.h>


#if defined(_WIN32) || defined(_WIN64)
#	define GL_PASCAL __stdcall
#	define GL_CDECL  __cdecl
#	define GL_EPTR   *
#	ifdef GL_DLL
#		define GL_EXPORT __declspec(dllexport)
#	elif defined(GL_TOOLSBUILD) || defined(GL_STATICBUILD)
#		define GL_EXPORT
#	else
#		define GL_EXPORT __declspec(dllimport)
#	endif
#else
#	if defined(PCDOS) || defined(_WINDOWS)
#		define GL_PASCAL __pascal
#		define GL_CDECL  __cdecl
#		define GL_EPTR   __far *
#		ifdef GL_DLL
#			define GL_EXPORT __export
#		else
#			define GL_EXPORT
#		endif
#	else
#		define GL_PASCAL
#		define GL_CDECL
#		define GL_EPTR   *
#		define GL_EXPORT
#	endif
#endif

#define GL_LPTR *

#ifndef GLSARGS

#if defined(__STDC__) || defined(__cplusplus) || defined(PCDOS) || defined(_WIN32) || defined(_WINDOWS) || defined(_WIN64)
#define GL_PROTO(type, func, args)      type GL_PASCAL func args
#define GL_PROTO_CB(type, func, args)      type GL_CDECL func args
#define GL_PTR_PROTO(type, name, args)  type (GL_PASCAL *name) args
#else
#define GL_PROTO(type, func, args)      type func()
#define GL_PROTO_CB(type, func, args)      type func()
#define GL_PTR_PROTO(type, name, args)  type (*name)()
#endif

#endif /* GLSARGS */

#ifdef  GL_NT_STATIC /* NT Server & Blade */
#undef GL_EXPORT
#ifdef  GL_NT_ST_EXP /* NT Server exports it */
#define GL_EXPORT      __declspec(dllexport)
#else             /* NT Blade imports it */
#define GL_EXPORT      __declspec(dllimport)
#endif /*  GL_NT_ST_EXP */
#endif /*  GL_NT_STATIC */

#if defined(__STDC__) || defined(PCDOS) || defined(_WIN32) || defined(_WINDOWS) || defined(_WIN64)
#define GL_VOID       void
#define GL_VOIDPTR    void GL_EPTR
#define GL_VOIDARGS   void
#else
#define GL_VOID       int
#define GL_VOIDPTR    char GL_EPTR
#define GL_VOIDARGS
#endif

#if defined (_WIN32) && !defined (_WIN64)
#define GL_VERSION "glslib-4.50.TC5"
#define PLAT_BIT "32"
#else
#ifdef PCDOS
#define GL_VERSION "glslib-4.50.WC5"
#define PLAT_BIT "32"
#else
#ifdef M64ADDR
#define GL_VERSION "glslib-4.50.FC5"
#define PLAT_BIT "64"
#else
#ifdef HPUX_32BIT
#define GL_VERSION "glslib-4.50.HC5"
#define PLAT_BIT "32"
#else
#define GL_VERSION "glslib-4.50.UC5"
#define PLAT_BIT "32"
#endif
#endif
#endif
#endif

/* Version strings used by DLL version properties box */
#define  GL_VERSION_NUM      4,5,0,5
#if !defined (_WIN64)
#define  GL_VERSION_STR      "4.50.TC5"
#else
#define  GL_VERSION_STR      "4.50.FC5"
#endif

#define GL_NUMVER            450005   /* Numeric version of 4.50.UC5 */

#define  GL_CV_VERSION       "9"
#define  GL_LC_VERSION       "11"
#define  GL_CM_VERSION       "3"


#if (defined(PCDOS) || defined(_WINDOWS)) && !defined(_WIN32) && !defined(_WIN64)
#	define GL_STRCAT   _fstrcat
#	define GL_STRCHR   _fstrchr
#	define GL_STRCMP   _fstrcmp
#	define GL_STRCPY   _fstrcpy
#	define GL_STRCSPN  _fstrcspn
#	define GL_STRNCMP  _fstrncmp
#	define GL_STRPBRK  _fstrpbrk
#	define GL_STRRCHR  _fstrrchr
#	define GL_STRSPN   _fstrspn
#	define GL_STRSTR   _fstrstr
#	define GL_STRLEN   _fstrlen
#else
#	define GL_STRCAT   strcat
#	define GL_STRCHR   strchr
#	define GL_STRCMP   strcmp
#	define GL_STRCPY   strcpy
#	define GL_STRCSPN  strcspn
#	define GL_STRNCMP  strncmp
#	define GL_STRPBRK  strpbrk
#	define GL_STRRCHR  strrchr
#	define GL_STRSPN   strspn
#	define GL_STRSTR   strstr
#	define GL_STRLEN   strlen
#endif

/* size of wide character must be compatible with the linked-in object */

#ifndef GL_WCSIZE          /* accept previous definition if it exists */
#define GL_WCSIZE 4        /* may be 1, 2, or 4. */
#endif

/* success and failure indicators */
#define GL_SUCCESS  0
#define GL_FAILURE -1

/* category parameter values for gl_setlocale, same as .lco file order */
#define GL_ALL      1
#define GL_CTYPE    2
#define GL_COLLATE  3
#define GL_NUMERIC  4
#define GL_MONETARY 5
#define GL_TIME     6
#define GL_MESSAGES 7

#define GL_FIRST_CAT    GL_CTYPE
#define GL_LAST_CAT     GL_MESSAGES


#define GL_D_T_FMT      0       /* string for formatting data and time */

#define GL_DAY_1        1       /* Name of the first day of the week */
#define GL_DAY_2        2
#define GL_DAY_3        3
#define GL_DAY_4        4
#define GL_DAY_5        5
#define GL_DAY_6        6
#define GL_DAY_7        7

#define GL_ABDAY_1      8       /* Abbreviated name of the first day of the week */
#define GL_ABDAY_2      9
#define GL_ABDAY_3      10
#define GL_ABDAY_4      11
#define GL_ABDAY_5      12
#define GL_ABDAY_6      13
#define GL_ABDAY_7      14

#define GL_MON_1        15      /* Name of the first month */
#define GL_MON_2        16
#define GL_MON_3        17
#define GL_MON_4        18
#define GL_MON_5        19
#define GL_MON_6        20
#define GL_MON_7        21
#define GL_MON_8        22
#define GL_MON_9        23
#define GL_MON_10       24
#define GL_MON_11       25
#define GL_MON_12       26
#define GL_MON_13       27
#define GL_MON_14       28
#define GL_MON_15       29
#define GL_MON_16       30
#define GL_MON_17       31
#define GL_MON_18       32
#define GL_MON_19       33
#define GL_MON_20       34

#define GL_ABMON_1      35      /* Abbreviated name of the first month */
#define GL_ABMON_2      36
#define GL_ABMON_3      37
#define GL_ABMON_4      38
#define GL_ABMON_5      39
#define GL_ABMON_6      40
#define GL_ABMON_7      41
#define GL_ABMON_8      42
#define GL_ABMON_9      43
#define GL_ABMON_10     44
#define GL_ABMON_11     45
#define GL_ABMON_12     46
#define GL_ABMON_13     47
#define GL_ABMON_14     48
#define GL_ABMON_15     49
#define GL_ABMON_16     50
#define GL_ABMON_17     51
#define GL_ABMON_18     52
#define GL_ABMON_19     53
#define GL_ABMON_20     54

#define GL_RADIXCHAR    55      /* Radix character */
#define GL_THOUSEP      56      /* Separator for thousands */
#define GL_YESSTR       57      /* Affirmative response for yes/no queries */
#define GL_NOSTR        58      /* Negative response for yes/no queries */
#define GL_CRNCYSTR     59      /* Currency symbol */

#define GL_CODESET      60
#define GL_D_FMT        61
#define GL_T_FMT        62
#define GL_T_FMT_AMPM   63
#define GL_AM_STR       64
#define GL_PM_STR       65
#define GL_ERA          66
#define GL_ERA_D_FMT    67
#define GL_ERA_D_T_FMT  68
#define GL_ERA_T_FMT    69
#define GL_ALT_DIGITS   70
#define GL_YESEXPR      71
#define GL_NOEXPR       72
#define GL_CALENDAR     73

/* Type values for gl_mbstimeinfo */

#define GL_FULLDAY  1
#define GL_ABBRDAY  2
#define GL_FULLMON  3
#define GL_ABBRMON  4
#define GL_FULLERA  5
#define GL_ABBRERA  6
#define GL_ALTDGTS  7
#define GL_AMPMSTR  8

/* Type values for gl_mbsfmtexpand */

#define GL_DATE_FORMAT    1
#define GL_MONEY_FORMAT   2
#define GL_NUMBER_FORMAT  3

/* Type values for gl_getcentury algorithms*/
#define GL_PAST_CENT     'P'
#define GL_FUTURE_CENT   'F'
#define GL_CLOSEST_CENT  'C'
#define GL_PRESENT_CENT  'R'

/* Defines for conversion from codeset name to codeset number */

#define GL_MAX_CV_FNAME		12     /* "E000E000.cvo" */

#define GL_MAX_CS_NAME		21
#define GL_MAX_LC_NAME		(GL_MAX_CS_NAME + 11)

#define GL_MAX_NLS_FNAME 	36

/* GL_MAX_LC_FNAME and GL_MAX_LC_SPEC use GL_MAX_LC_NAME rather than
 * strlen("ll_TT/E000aaaa.lco") for compatibility with systems that
 * don't follow the GLS locale file naming scheme. This works because
 * GL_MAX_LC_NAME is larger than strlen("ll_TT/E000aaaa.lco").
 */
#define GL_MAX_LC_FNAME		310    /* "GL_CTYPE = <max-nls-fname> ; \
				           GL_COLLATE = <max-nls-fname> ; \
				           GL_MESSAGES = <max-nls-fname> ; \
				           GL_NUMERIC = <max-nls-fname> ; \
				           GL_MONETARY = <max-nls-fname> ; \
				           GL_TIME = <max-nls-fname> ; " */
#define GL_MAX_LC_SPEC 		285    /* "GL_CTYPE = <max-lc-name> ; \
				           GL_COLLATE = <max-lc-name> ; \
				           GL_MESSAGES = <max-lc-name> ; \
				           GL_NUMERIC = <max-lc-name> ; \
				           GL_MONETARY = <max-lc-name> ; \
				           GL_TIME = <max-lc-name> ; " */

#define GL_MAX_MSG_DNAME	10     /* "ll_TT/E000" */
#define GL_BAD_CS_NUM		(unsigned int) 0xE000

#define GL_EXT_GETENV   0
#define GL_EXT_ERRNO    1
#define GL_EXT_FCLOSE   2
#define GL_EXT_FEOF     3
#define GL_EXT_FERROR   4
#define GL_EXT_FGETC    5
#define GL_EXT_FGETS    6
#define GL_EXT_FOPEN    7
#define GL_EXT_FREE     8
#define GL_EXT_FSEEK    9
#define GL_EXT_FTELL    10
#define GL_EXT_FWRITE   11
#define GL_EXT_GETC     12
#define GL_EXT_MALLOC   13
#define GL_EXT_UNGETC   14
#define GL_EXT_PUTENV   15
#define GL_EXT_CURRDATE 16
#define GL_EXT_CURRTIME 17
#define GL_EXT_CALLOC   18
#define GL_EXT_REALLOC  19
#define GL_EXT_UCA      20
#define GL_EXT_LASTFUNC 20

/* Defines for error numbers */

#define GL_ERR_BASE     1 /* General Base gl_errno values */

#define GL_NOERRNO      0               /* No error has occurred             */
#define GL_EILSEQ       GL_ERR_BASE     /* Invalid MB sequence               */
#define GL_ENULLPTR     (GL_ERR_BASE+1) /* NULL Pointer to a function        */
#define GL_ENOMEM       (GL_ERR_BASE+2) /* memory allocation failure         */
#define GL_EINDEXRANGE  (GL_ERR_BASE+3) /* index out of bounds               */
#define GL_EINVPTR      (GL_ERR_BASE+4) /* End pointer < begin pointer       */
#define GL_ERANGE       (GL_ERR_BASE+5) /* BASE of number is out of range.   */
#define GL_EINVAL       (GL_ERR_BASE+6) /* Invalid wcs or mbs strings        */
#define GL_FILEERR      (GL_ERR_BASE+7) /* input file could not be read      */
#define GL_PARAMERR     (GL_ERR_BASE+8) /* parameter out of bounds           */
#define GL_CATASTROPHE  (GL_ERR_BASE+9) /* internal error; undefined result  */
#define GL_BADFILEFORM  (GL_ERR_BASE+10)/* file format was invalid           */
#define GL_INVALIDLOC   (GL_ERR_BASE+11)/* locale codesets are inconsistent  */
#define GL_EIO          (GL_ERR_BASE+12)/* I/O error                         */
#define GL_E2BIG        (GL_ERR_BASE+13)/* Operation would overflow buffer   */
#define GL_EBADF        (GL_ERR_BASE+14)/* Bad handle passed to function     */
#define GL_EOF          (GL_ERR_BASE+15)/* End of file on input stream       */
#define GL_EUNKNOWN     (GL_ERR_BASE+16)/* Unknown system error has occurred */
#define GL_UNLOADEDCAT  (GL_ERR_BASE+17)/* Can't copy from unloaded category */
#define GL_LOADEDCAT    (GL_ERR_BASE+18)/* Can't copy into a loaded category */
#define GL_ENOSYS       (GL_ERR_BASE+19)/* function is not supported         */
#define GL_ELOCTOOWIDE  (GL_ERR_BASE+20)/* has chars too wide for library    */
#define GL_INVALIDFMT   (GL_ERR_BASE+21)/* Invalid formatted argument string */
#define GL_EFRACRANGE   (GL_ERR_BASE+22)/* Fraction of  Second out of bounds */
#define GL_ESECONDRANGE (GL_ERR_BASE+23)/* Second out of bounds              */
#define GL_EMINUTERANGE (GL_ERR_BASE+24)/* Minute out of bounds              */
#define GL_EHOURRANGE   (GL_ERR_BASE+25)/* Hour out of bounds                */
#define GL_EDAYRANGE    (GL_ERR_BASE+26)/* Day number out of bounds          */
#define GL_EWKDAYRANGE  (GL_ERR_BASE+27)/* Week Day number out of bounds     */
#define GL_EYDAYRANGE   (GL_ERR_BASE+28)/* Year Day number out of bounds     */
#define GL_EMONTHRANGE  (GL_ERR_BASE+29)/* Month number out of bounds        */
#define GL_EYEARRANGE   (GL_ERR_BASE+30)/* Year number out of bounds         */
#define GL_EERAOFFRANGE (GL_ERR_BASE+31)/* Era Offset out of bounds          */
#define GL_BADFRAC      (GL_ERR_BASE+32)/* Fraction could not be scanned     */
#define GL_BADSECOND    (GL_ERR_BASE+33)/* Second could not be scanned       */
#define GL_BADMINUTE    (GL_ERR_BASE+34)/* Minute could not be scanned       */
#define GL_BADHOUR      (GL_ERR_BASE+35)/* Hour could not be scanned         */
#define GL_BADDAY       (GL_ERR_BASE+36)/* Month Day could not be scanned    */
#define GL_BADWKDAY     (GL_ERR_BASE+37)/* Week Day could not be scanned     */
#define GL_BADYDAY      (GL_ERR_BASE+38)/* Year Day could not be scanned     */
#define GL_BADMONTH     (GL_ERR_BASE+39)/* Month could not be scanned        */
#define GL_BADYEAR      (GL_ERR_BASE+40)/* Year could not be scanned         */
#define GL_BADERANAME   (GL_ERR_BASE+41)/* Invalid Era name                  */
#define GL_BADERAOFFSET (GL_ERR_BASE+42)/* Invalid Era offset                */
#define GL_BADFMTMOD    (GL_ERR_BASE+43)/* Invalid Format modifer            */
#define GL_BADFMTWP     (GL_ERR_BASE+44)/* Invalid width/precision           */
#define GL_BADINPUT     (GL_ERR_BASE+45)/* Input string doesn't match format */
#define GL_NOPOINT      (GL_ERR_BASE+46)/* Missing decimal point in input    */
#define GL_BADMONTHSTR  (GL_ERR_BASE+47)/* Month string could not be scanned */
#define GL_BADERASPEC   (GL_ERR_BASE+48)/* Couldn't load era from locale     */
#define GL_BADCALENDAR  (GL_ERR_BASE+49)/* Unsupported calendar in LC_TIME   */
#define GL_BADOBJVER    (GL_ERR_BASE+50)/* Wrong lc, cm or cv object version */
#define GL_BADALTDATE   (GL_ERR_BASE+51)/* Could not convert %Z information  */
#define GL_NOSYMMAP     (GL_ERR_BASE+52)/* character/symbol not in charmap   */
#define GL_BADSYM       (GL_ERR_BASE+53)/* invalid symbolic character name   */
#define GL_ELOCLOAD     (GL_ERR_BASE+54)/* Could not load locale             */
#define GL_TERMMISMAT   (GL_ERR_BASE+55)/* str termination params mis-match  */
#define GL_NOCTYPE      (GL_ERR_BASE+56)/* GL_CTYPE is not loaded  */
#define GL_LOCMISMAT    (GL_ERR_BASE+57)/* loaded codesets are not same  */

/* Defines for Ctype categories */

#define GL_UPPER          (gl_ctype_t) 0x0001
#define GL_LOWER          (gl_ctype_t) 0x0002
#define GL_ALPHA          (gl_ctype_t) 0x0004
#define GL_DIGIT          (gl_ctype_t) 0x0008
#define GL_SPACE          (gl_ctype_t) 0x0010
#define GL_CNTRL          (gl_ctype_t) 0x0020
#define GL_PUNCT          (gl_ctype_t) 0x0040
#define GL_GRAPH          (gl_ctype_t) 0x0080
#define GL_PRINT          (gl_ctype_t) 0x0100
#define GL_XDIGIT         (gl_ctype_t) 0x0200
#define GL_BLANK          (gl_ctype_t) 0x0400
#define GL_ALNUM          GL_ALPHA | GL_DIGIT
#define GL_USER_BIT_BASE  (gl_ctype_t) 0x0800

#define gl_errno(x)        (*_gl_ext_errno((gl_gen_expptr_t) (x)))
#define gl_get_errno(x)    (*_gl_ext_errno((gl_gen_expptr_t) (x)))
#define gl_set_errno(x,y)  (*_gl_ext_errno((gl_gen_expptr_t) (x))) = y


extern gl_uintptr gl_memory_usage;


/* Defines for glsatg.c functions */
#define GL_FORWARDPASS               1    /* For gl_passdirection() */
#define GL_BACKWARDPASS              2

#define GL_NOT_MB_COLL_ELEM          1    /* For gl_iscompchar() */
#define GL_IS_MB_COLL_ELEM           2
#define GL_IS_PART_OF_MB_COLL_ELEM   3

#define GL_NO_PRIMWEIGHT            -2    /* For gl_{next,prev}primweight() */

/* Defines for algorithmic codeset conversion */
#define GLCV_BUFSIZE 16    /* max size for target char without state */

/* Flags returned in gl_cv_res_t by ext fn */
#define GLCV_NULL    (unsigned int) 0x01  /* source is the null character,
                                           * otherwise normal */
#define GLCV_DATAERR (unsigned int) 0x02  /* invalid char, too little data, or undefined
                              conversion. Everything is ignored, the
                              operation is aborted, and an error code is
                              returned to the user. */
#define GLCV_CONVERR (unsigned int) 0x04   /* like the error field in
                                            * .cv files; the sub parameter
                                            * is asserted, otherwise normal */
#define GLCV_NOMORE  (unsigned int) 0x08   /* fn has completely processed
                                            * the input data */

/* macros to values cached for optimization of common cases */
#define GL_IS_SINGLE_BYTE(lc)        (((gl_lc_expptr_t)(lc))->single_byte)
#define GL_IS_CODESET_ORDER(lc)      (((gl_lc_expptr_t)(lc))->codeset_order)
#define GL_LC_SB_TOUPPER_TABLE(lc)   (((gl_lc_expptr_t)(lc))->sb_toupper_table)
#define GL_LC_SB_TOLOWER_TABLE(lc)   (((gl_lc_expptr_t)(lc))->sb_tolower_table)
#define GL_LC_SB_CTYPE_TABLE(lc)     (((gl_lc_expptr_t)(lc))->sb_ctype_table)
#define GL_LC_SB_COLLATION_TABLE(lc) (((gl_lc_expptr_t)(lc))->sb_collation_table)
#define GL_COLL_CHAR_RATIO(lc)       (((gl_lc_expptr_t)(lc))->coll_char_ratio)
#define GL_COLL_IGNORED(lc)          (((gl_lc_expptr_t)(lc))->coll_ignored)
#define GL_COLL_EQUIV_CLASS_MAP(lc)  (((gl_lc_expptr_t)(lc))->coll_equiv_class_map)
#define GL_IS_GLULOC(lc)             (((gl_lc_expptr_t)(lc))->glu_locale)

#define GL_CV_SB2SB_TABLE(cv) (((gl_cv_expptr_t)(cv))->sb2sb_table)

#define GL_TMP(l) (((gl_lc_expptr_t)(l))->gl_tmp)
#define GL_FGETWC_SB(l,fp) (((GL_TMP(l) = _gl_ext_fgetc(fp)) == EOF) \
			    ? (gl_set_errno((l), GL_EOF), GL_WEOF)  \
			    : GL_TMP(l))

/* Definition of gl_wchar_t. Uses a dash of type-safe linking. */

#if GL_WCSIZE == 1

typedef unsigned char gl_wchar_t;

#define gl_setlocale gl_setlocale_1
#define gl_createlocale gl_createlocale_1
#define gl_createlocale2 gl_createlocale2_1
#define gl_create_null_locale gl_create_null_locale_1

#elif GL_WCSIZE == 2

typedef unsigned short gl_wchar_t;

#define gl_setlocale gl_setlocale_2
#define gl_createlocale gl_createlocale_2
#define gl_createlocale2 gl_createlocale2_2
#define gl_create_null_locale gl_create_null_locale_2

#elif GL_WCSIZE == 4

#if defined(THINK_C) || defined(__MWERKS__)
typedef unsigned long gl_wchar_t;
#else
typedef unsigned int gl_wchar_t;
#endif

#define gl_setlocale gl_setlocale_4
#define gl_createlocale gl_createlocale_4
#define gl_createlocale2 gl_createlocale2_4
#define gl_create_null_locale gl_create_null_locale_4

#else

error GL_WCSIZE must be of size 1, 2, or 4

#endif /* GL_WCSIZE */


typedef unsigned int          gl_ctype_t;
typedef int                   gl_nl_item;   /* for gl_nl_langinfo() */
typedef unsigned char         gl_mchar_t;
typedef GL_VOIDPTR            gl_e_voidptr_t;
typedef GL_VOIDPTR            gl_cv_t;
typedef GL_VOIDPTR            gl_lc_t;
typedef GL_VOIDPTR            gl_cm_t;
typedef GL_VOIDPTR            gl_cvfns_ref_t;
typedef int           GL_EPTR gl_e_intptr_t;
typedef unsigned int  GL_EPTR gl_e_uintptr_t;
typedef char          GL_EPTR gl_e_charptr_t;
typedef unsigned char GL_EPTR gl_e_ucharptr_t;
typedef gl_mchar_t    GL_EPTR gl_e_mcharptr_t;
typedef gl_wchar_t    GL_EPTR gl_e_wcharptr_t;
typedef FILE          GL_EPTR gl_e_fileptr_t;
typedef gl_cv_t       GL_EPTR gl_iconvptr_t;
typedef gl_cv_t       GL_EPTR gl_cvptr_t;
typedef gl_lc_t       GL_EPTR gl_localeptr_t;
typedef gl_lc_t       GL_EPTR gl_lcptr_t;


typedef struct gl_gen_exports
    {
    int gl_lerrno;         /* errno value for gls functions */
    } gl_gen_exports_t;


typedef gl_gen_exports_t GL_EPTR gl_gen_expptr_t;

typedef struct gl_cv_exports
    {
    gl_gen_exports_t exp;
    gl_e_ucharptr_t sb2sb_table;
    } gl_cv_exports_t;


typedef gl_cv_exports_t GL_EPTR gl_cv_expptr_t;



/* Compile-time optimizations for single-byte library */

#if GL_WCSIZE == 1

#define gl_charoffset(lc, mbs, mbp, bytes) ((*(bytes))=1, 0)

#define gl_mbsnext(loc, mbs) ((gl_e_mcharptr_t) (mbs)+1)

#define gl_fgetwc(loc,fp) GL_FGETWC_SB(loc,fp)
#define gl_fgetmb(loc,mb,fp) (*(mb)=(gl_mchar_t)_gl_ext_fgetc(fp),\
        (char)(*(mb))==-1? (gl_set_errno(loc,GL_EOF), -1): 1 )
#define gl_mbscmp(loc, mbs1, mbs2)  \
	GL_STRCMP((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))
#define gl_mbsncmp(loc, mbs1, mbs2, n) \
	GL_STRNCMP((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2), (n))
#define gl_mblen(loc, mb, n) \
	    ((mb) != NULL \
	     ? (((n) >= 1) \
		? ((*(mb)) != '\0' \
		   ? 1 \
		   : 0 \
		  ) \
		: (gl_set_errno((loc), GL_EINVAL), -1) \
	       ) \
	     : 0 \
	    )
#define gl_mbtowc(loc, wc, mb, n) \
	      ((mb) \
	       ? ((n) \
	          ? ((*mb) ? (*(wc)=*(gl_mchar_t*)(mb), 1): (*(wc)=0, 0)) \
		  : (gl_set_errno(loc, GL_EINVAL), -1)) \
	       : 0 \
	      )
#define gl_wctomb(loc, mb, wc) (*(mb)=wc, 1)
#define gl_wcstombs(loc, mb, wc, n) _gl_is_wcstombs(loc, mb, wc, n)
#define gl_mbscat(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? ((gl_e_mcharptr_t)GL_STRCAT((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbscpy(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? ((gl_e_mcharptr_t)GL_STRCPY((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbschr(loc, mbs, mbc) \
	    ((mbs && mbc) \
	     ? (gl_set_errno(loc,0), (gl_e_mcharptr_t)GL_STRCHR((gl_e_charptr_t)(mbs), (int)(*mbc))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbsrchr(loc, mbs, mbc) \
	    ((mbs && mbc) \
	     ? (gl_set_errno(loc,0), (gl_e_mcharptr_t)GL_STRRCHR((gl_e_charptr_t)(mbs), (int)(*mbc))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbscspn(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? ((int)GL_STRCSPN((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), -1) \
	    )
#define gl_mbsspn(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? ((int)GL_STRSPN((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), -1) \
	    )
#define gl_mbspbrk(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? (gl_set_errno(loc,0), (gl_e_mcharptr_t)GL_STRPBRK((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbsmbs(loc, mbs1, mbs2) \
	    ((mbs1 && mbs2) \
	     ? (gl_set_errno(loc,0), (gl_e_mcharptr_t)GL_STRSTR((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_mbsprev(loc, mbs, mbp) \
	    ((mbs && mbp) \
	     ? (((mbp) <= (mbs)) \
	      ? (gl_set_errno(loc,GL_EINVPTR), (gl_e_mcharptr_t)NULL) \
	      : (gl_e_mcharptr_t)((mbp)-1)) \
	     : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL) \
	    )
#define gl_getmbsi(loc, mbs, i) \
	    (((i) <0) \
	     ? (gl_set_errno(loc,GL_EINDEXRANGE), (gl_e_mcharptr_t)NULL) \
	     : ((mbs) ? (gl_e_mcharptr_t)((mbs)+(i)) \
	      : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	    )
#define gl_putmbsi(loc, mbs, i, mbc) \
	    (((i) <0) \
	      ? (gl_set_errno(loc,GL_EINDEXRANGE), (gl_e_mcharptr_t)NULL) \
	      : (((mbs) && (mbc)) \
		 ? (((mbs)[i]=(*mbc)), (gl_e_mcharptr_t)((mbs)+(i))) \
		 : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	    )

#else

#define gl_charoffset(lc, mbs, mbp, bytes) \
            (GL_IS_SINGLE_BYTE(lc) \
             ? ((*(bytes))=1, 0) \
             : gl_full_charoffset((lc),(mbs),(mbp),(bytes)) \
            )

#define gl_mbsnext(loc, mbs) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? (gl_e_mcharptr_t) (mbs)+1 \
	     : gl_full_mbsnext((loc),(mbs)) \
	    )
#define gl_fgetwc(loc,fp) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? GL_FGETWC_SB(loc,fp) \
	     : gl_full_fgetwc(loc,fp) \
	    )
#define gl_fgetmb(loc,mb,fp) \
            (GL_IS_SINGLE_BYTE(loc) \
             ? (*(mb)=(gl_mchar_t)_gl_ext_fgetc(fp), \
                ((char)(*(mb))==-1) \
		 ? (_gl_ext_feof(fp) ? (gl_set_errno(loc,GL_EOF), -1) : 1) \
		 : 1) \
	     : gl_full_fgetmb(loc,mb,fp) \
	    )
#define gl_mbscmp(loc, mbs1, mbs2) \
	    (gl_mb_loc_min(loc) == 1 \
	     ? (GL_STRCMP((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	     : (gl_full_mbscmp(loc, mbs1, mbs2)) \
	    )
#define gl_mbsncmp(loc, mbs1, mbs2, n) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? GL_STRNCMP((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2), (n))\
	     : gl_full_mbsncmp((loc), (mbs1), (mbs2), (n)) \
	    )
#define gl_mblen(loc, mb, n) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mb) != NULL \
	         ? (((n) >= 1) \
		    ? ((*(mb)) != '\0' \
		       ? 1 \
		       : 0 \
		      ) \
		    : (gl_set_errno((loc), GL_EINVAL), -1) \
	           ) \
	         : 0 \
	        ) \
	     : gl_full_mblen((loc), (mb), (n)) \
	    )
#define gl_mbtowc(loc, wc, mb, n) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ?((mb) \
	       ? ((n) \
	          ? ((*mb) ? (*(wc)=*(gl_mchar_t*)(mb), 1): (*(wc)=0, 0)) \
		  : (gl_set_errno(loc, GL_EINVAL), -1)) \
	       : 0) \
	     : gl_full_mbtowc((loc), (wc), (mb), (n)) \
	    )
#define gl_wctomb(loc, mb, wc) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? (*(mb)=wc, 1) \
	     : gl_full_wctomb((loc), (mb), (wc)) \
	    )
#define gl_wcstombs(loc, mb, wc, n) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? _gl_is_wcstombs((loc), (mb), (wc), (n)) \
	     : gl_full_wcstombs((loc), (mb), (wc), (n)) \
	    )
#define gl_mbscat(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? ((gl_e_mcharptr_t)GL_STRCAT((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbscat((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbscpy(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? ((gl_e_mcharptr_t)GL_STRCPY((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbscpy((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbschr(loc, mbs, mbc) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs && mbc) \
	        ? (gl_set_errno(loc,0), \
		   (gl_e_mcharptr_t)GL_STRCHR((gl_e_charptr_t)(mbs), (int)(*mbc))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbschr((loc), (mbs), (mbc)) \
	    )
#define gl_mbsrchr(loc, mbs, mbc) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs && mbc) \
	        ? (gl_set_errno(loc,0), \
		   (gl_e_mcharptr_t)GL_STRRCHR((gl_e_charptr_t)(mbs), (int)(*mbc))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbsrchr((loc), (mbs), (mbc)) \
	    )
#define gl_mbscspn(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? ((int)GL_STRCSPN((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), -1)) \
	     : gl_full_mbscspn((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbsspn(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? ((int)GL_STRSPN((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), -1)) \
	     : gl_full_mbsspn((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbspbrk(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? (gl_set_errno(loc,0), \
		   (gl_e_mcharptr_t)GL_STRPBRK((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbspbrk((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbsmbs(loc, mbs1, mbs2) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs1 && mbs2) \
	        ? (gl_set_errno(loc,0), \
		   (gl_e_mcharptr_t)GL_STRSTR((gl_e_charptr_t)(mbs1), (gl_e_charptr_t)(mbs2))) \
	        : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbsmbs((loc), (mbs1), (mbs2)) \
	    )
#define gl_mbsprev(loc, mbs, mbp) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? ((mbs && mbp) \
		? (((mbp) <= (mbs)) \
		   ? (gl_set_errno(loc,GL_EINVPTR), (gl_e_mcharptr_t)NULL) \
		   : (gl_e_mcharptr_t)((mbp)-1)) \
		: (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)) \
	     : gl_full_mbsprev((loc), (mbs), (mbp)) \
	    )
#define gl_getmbsi(loc, mbs, i) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? (((i) <0) \
		? (gl_set_errno(loc,GL_EINDEXRANGE), (gl_e_mcharptr_t)NULL) \
		: ((mbs) ? (gl_e_mcharptr_t)((mbs)+(i)) \
		         : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)))\
	     : gl_full_getmbsi((loc), (mbs), (i)) \
	    )
#define gl_putmbsi(loc, mbs, i, mbc) \
	    (GL_IS_SINGLE_BYTE(loc) \
	     ? (((i) <0) \
		? (gl_set_errno(loc,GL_EINDEXRANGE), (gl_e_mcharptr_t)NULL) \
		: (((mbs) && (mbc)) \
		   ? (((mbs)[i]=(*mbc)), (gl_e_mcharptr_t)((mbs)+(i))) \
		   : (gl_set_errno(loc,GL_ENULLPTR), (gl_e_mcharptr_t)NULL)))\
	     : gl_full_putmbsi((loc), (mbs), (i), (mbc)) \
	    )

#endif


typedef struct gl_coll_equiv_class_map
    {
    gl_mchar_t *from;
    gl_mchar_t *to;
    } gl_coll_equiv_class_map_t;

/* NOTE: gl_exports is a private gls type. No external use. Caveat emptor. */
typedef struct gl_loc_exports  {
	gl_gen_exports_t gen;     /* common exports in iconv and locale structure */
	GL_PTR_PROTO(int, mbscoll,  (gl_lc_t loc, gl_e_mcharptr_t text1,
		gl_e_mcharptr_t text2));
	GL_PTR_PROTO(int, mbfscoll,  (gl_lc_t loc, gl_e_mcharptr_t text1,
		int bytelen1, gl_e_mcharptr_t text2, int bytelen2));
	GL_PTR_PROTO(int, mbsxfrm,  (gl_lc_t loc, char GL_EPTR dst,
		gl_e_mcharptr_t mbs, int maxbytes));
	GL_PTR_PROTO(int, mbstowcs, (gl_lc_t loc, gl_e_wcharptr_t wcs,
		gl_e_mcharptr_t mbs, int n));
	GL_PTR_PROTO(int, mbfstowcfs, (gl_lc_t loc, gl_e_wcharptr_t wcs,
		gl_e_mcharptr_t mbs, int bytelen, int n));
	int gl_tmp;            /* temporary area for gls macros */
	double case_conv_ratio;
	double coll_char_ratio;
        unsigned char  *sb_toupper_table;
        unsigned char  *sb_tolower_table;
        unsigned short *sb_ctype_table;
        unsigned char  *sb_collation_table;
	int single_byte;
	int codeset_order;
	gl_mchar_t **coll_ignored;
	gl_coll_equiv_class_map_t *coll_equiv_class_map;
	int glu_locale;
} gl_loc_exports_t;          /* defines functions switched between multi-byte,
                              * single-byte, and/or native mode */

typedef gl_loc_exports_t GL_EPTR gl_lc_expptr_t;


/* NOTE: gl_exports is a private gls type. No external use. Caveat emptor. */
typedef struct gl_cmap_exports {
	gl_gen_exports_t gen;     /* common exports in iconv and locale structure */
} gl_cmap_exports_t;          /* defines functions switched between multi-byte,
                               * single-byte, and/or native mode */

typedef gl_cmap_exports_t GL_EPTR gl_cm_expptr_t;


/* codeset conversion state */
typedef struct gl_cv_state
    {
    int first_frag;
    int last_frag;
    int source_state;
    int target_state;
    void GL_EPTR ext_state;
    } gl_cv_state_t;


/* codeset conversion result for external algorithmic conversions */
typedef struct gl_cv_res
    {
    int flags;              /* see above GLCV_* definitions */
    int src_len;            /* amount consumed from input buffer, could be 0 */
    int dst_len;            /* amount written to dst_buf */
    char dst_buf[GLCV_BUFSIZE];
    } gl_cv_res_t;


typedef GL_PTR_PROTO(void, gl_cvmfn_t, (gl_e_mcharptr_t data, size_t inlen,
                gl_cv_state_t GL_EPTR state, gl_cv_res_t GL_EPTR cv_result));

typedef struct gl_cv_funcdef
    {
    gl_e_charptr_t from_name;
    gl_e_charptr_t to_name;
    gl_cvmfn_t mtom_fn;
    int src_maxlen, src_minlen;
    int dst_maxlen, dst_minlen;
    float exp_ratio;
    } gl_cv_funcdef_t;

/* structure for gl_localeconv() */
typedef struct gl_conv
    {
    gl_e_mcharptr_t decimal_point;
    gl_e_wcharptr_t w_decimal_point;
    gl_e_mcharptr_t thousands_sep;
    gl_e_wcharptr_t w_thousands_sep;
    gl_e_charptr_t  grouping;
    gl_e_mcharptr_t int_curr_symbol;
    gl_e_wcharptr_t w_int_curr_symbol;
    gl_e_mcharptr_t currency_symbol;
    gl_e_wcharptr_t w_currency_symbol;
    gl_e_mcharptr_t mon_decimal_point;
    gl_e_wcharptr_t w_mon_decimal_point;
    gl_e_mcharptr_t mon_thousands_sep;
    gl_e_wcharptr_t w_mon_thousands_sep;
    gl_e_charptr_t  mon_grouping;
    gl_e_mcharptr_t positive_sign;
    gl_e_wcharptr_t w_positive_sign;
    gl_e_mcharptr_t negative_sign;
    gl_e_wcharptr_t w_negative_sign;
    gl_e_mcharptr_t num_positive_sign;
    gl_e_wcharptr_t w_num_positive_sign;
    gl_e_mcharptr_t num_negative_sign;
    gl_e_wcharptr_t w_num_negative_sign;
    char int_frac_digits;
    char frac_digits;
    char p_cs_precedes;
    char p_sep_by_space;
    char n_cs_precedes;
    char n_sep_by_space;
    char p_sign_posn;
    char n_sign_posn;
    } gl_conv_t;


/* time pointer */
typedef struct gl_tm
    {
    long  tm_usec;    /* microseconds (0-999999) */
    int   tm_sec;     /* seconds (0-59) */
    int   tm_min;     /* minutes (0-59) */
    int   tm_hour;    /* hour (0-23) */
    int   tm_mday;    /* day of month (1-31) */
    int   tm_mon;     /* month of year (0-11) */
    int   tm_year;    /* year starting at 1900 */
    int   tm_wday;    /* day of week (0-6) */
    int   tm_yday;    /* day of year (0-365) */
    int   tm_isdst;
    gl_e_charptr_t tm_zone;
    long tm_gmtoff;
    } gl_tm_t;





/* Switched function macros */

#define gl_mbscoll(lc, mbs1, mbs2) \
                     ( GL_IS_CODESET_ORDER(lc) ? \
                           gl_mbscmp((lc), (mbs1), (mbs2)) : \
                           ((((gl_lc_expptr_t)lc)->mbscoll)((lc),(mbs1),(mbs2))) \
		     )
#define gl_mbsxfrm(lc, dst, mbs, maxbytes) \
		  ((((gl_lc_expptr_t)lc)->mbsxfrm)((lc),(dst),(mbs),(maxbytes)))
#define gl_mbslen(loc, mbs) \
		     ( GL_IS_SINGLE_BYTE(loc) ? \
		           ((int)GL_STRLEN((gl_e_charptr_t)(mbs))) : \
		           (_gl_im_mbslen((loc),(mbs))) \
		     )
#define gl_mbstowcs(loc, wcs, mbs, n) ((((gl_lc_expptr_t)loc)->mbstowcs)((loc), (wcs), (mbs), (n)))


#define gl_ismctype(lc, mb, class) \
    ( GL_LC_SB_CTYPE_TABLE(lc) ? \
	((int) GL_LC_SB_CTYPE_TABLE(lc)[*((gl_mchar_t *) (mb))] & (class) ) : \
	_gl_im_ismctype((lc), (mb), (class)) \
    )
#define gl_ismalpha(lc, mb)	gl_ismctype((lc), (mb), GL_ALPHA)
#define gl_ismupper(lc, mb)	gl_ismctype((lc), (mb), GL_UPPER)
#define gl_ismlower(lc, mb)	gl_ismctype((lc), (mb), GL_LOWER)
#define gl_ismdigit(lc, mb)	gl_ismctype((lc), (mb), GL_DIGIT)
#define gl_ismalnum(lc, mb)	gl_ismctype((lc), (mb), GL_ALNUM)
#define gl_ismspace(lc, mb)	gl_ismctype((lc), (mb), GL_SPACE)
#define gl_ismcntrl(lc, mb)	gl_ismctype((lc), (mb), GL_CNTRL)
#define gl_ismpunct(lc, mb)	gl_ismctype((lc), (mb), GL_PUNCT)
#define gl_ismgraph(lc, mb)	gl_ismctype((lc), (mb), GL_GRAPH)
#define gl_ismprint(lc, mb)	gl_ismctype((lc), (mb), GL_PRINT)
#define gl_ismxdigit(lc, mb)	gl_ismctype((lc), (mb), GL_XDIGIT)
#define gl_ismblank(lc, mb)	gl_ismctype((lc), (mb), GL_BLANK)

#define gl_iswctype(lc, wc, class) \
    ( GL_LC_SB_CTYPE_TABLE(lc) ? \
	( ((gl_wchar_t) (wc)) <= ((gl_wchar_t) 0xff) ? \
	    ((int) GL_LC_SB_CTYPE_TABLE(lc)[(gl_wchar_t) (wc)] & (class)) : \
	    (gl_set_errno(lc, GL_EILSEQ), 0) ) : \
        _gl_im_iswctype((lc), (gl_wchar_t) (wc), (class)) \
    )
#define gl_iswalpha(lc, wc)	gl_iswctype((lc), (wc), GL_ALPHA)
#define gl_iswupper(lc, wc)	gl_iswctype((lc), (wc), GL_UPPER)
#define gl_iswlower(lc, wc)	gl_iswctype((lc), (wc), GL_LOWER)
#define gl_iswdigit(lc, wc)	gl_iswctype((lc), (wc), GL_DIGIT)
#define gl_iswalnum(lc, wc)	gl_iswctype((lc), (wc), GL_ALNUM)
#define gl_iswspace(lc, wc)	gl_iswctype((lc), (wc), GL_SPACE)
#define gl_iswcntrl(lc, wc)	gl_iswctype((lc), (wc), GL_CNTRL)
#define gl_iswpunct(lc, wc)	gl_iswctype((lc), (wc), GL_PUNCT)
#define gl_iswgraph(lc, wc)	gl_iswctype((lc), (wc), GL_GRAPH)
#define gl_iswprint(lc, wc)	gl_iswctype((lc), (wc), GL_PRINT)
#define gl_iswxdigit(lc, wc)	gl_iswctype((lc), (wc), GL_XDIGIT)
#define gl_iswblank(lc, wc)	gl_iswctype((lc), (wc), GL_BLANK)


/* Misc. macros */

/* End-of-file wide character indicator */
#define GL_WEOF ((gl_wchar_t) ~0)

/* Maximum number of bytes necessary to store one character in any codeset */
#define GL_MB_MAX sizeof(gl_wchar_t)

/* Minimum number of bytes necessary to store one character in any codeset */
#define GL_MB_MIN 1

/* The maximum size of a symbolic character name.
 * The max symbol name is 70. This is multiplied by 2 because theoretically
 * every character may be escaped. The extra 2 is for the enclosing angle
 * brackets. This value does not include space for the null terminator
 */
#define GL_MAX_SYM_BYTES (70*2)+2

/* The minimum size of a symbolic character name including angle brackets */
#define GL_MIN_SYM_CHAR_NAME 3

/* The macro to apply to the return value of either gl_tomupper or gl_tomlower
 * which extracts the number of bytes read from srcmb.
 */
#define GL_CASE_CONV_SRC_BYTES(x) \
	(((unsigned short) (x)) >> 8)

/* The macro to apply to the return value of either gl_tomupper or gl_tomlower
 * which extracts the number of bytes written to dstmb.
 */
#define GL_CASE_CONV_DST_BYTES(x) \
	(((unsigned short) (x)) & ((unsigned short) 0xff))


/* Prototypes */

/* functions that can be defined outside GLS library */
GL_PROTO_CB(gl_e_voidptr_t GL_EXPORT, _gl_ext1_malloc, (gl_e_voidptr_t, size_t));
GL_PROTO_CB(gl_e_voidptr_t GL_EXPORT, _gl_ext1_calloc, (gl_e_voidptr_t, size_t, size_t));
GL_PROTO_CB(gl_e_voidptr_t GL_EXPORT, _gl_ext1_realloc, (gl_e_voidptr_t, gl_e_voidptr_t, size_t));
GL_PROTO_CB(void GL_EXPORT, _gl_ext1_free, (gl_e_voidptr_t, gl_e_voidptr_t));
GL_PROTO(gl_e_voidptr_t GL_EXPORT, _gl_ext_malloc, (size_t));
GL_PROTO(gl_e_voidptr_t GL_EXPORT, _gl_ext_calloc, (size_t, size_t));
GL_PROTO(gl_e_voidptr_t GL_EXPORT, _gl_ext_realloc, (gl_e_voidptr_t, size_t));
GL_PROTO(void GL_EXPORT, _gl_ext_free, (gl_e_voidptr_t));
GL_PROTO(gl_e_charptr_t GL_EXPORT, _gl_ext_getenv, (gl_e_charptr_t));
GL_PROTO(int GL_EXPORT, _gl_ext_putenv, (gl_e_charptr_t));
GL_PROTO(gl_e_intptr_t GL_EXPORT, _gl_ext_errno, (gl_gen_expptr_t));
GL_PROTO(gl_e_fileptr_t  GL_EXPORT, _gl_ext_fopen, (gl_e_charptr_t filename,
	gl_e_charptr_t type));
GL_PROTO(void GL_EXPORT, _gl_ext_fclose, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_fgetc, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_getc, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_ungetc, (int c, gl_e_fileptr_t stream));
GL_PROTO(gl_e_charptr_t GL_EXPORT, _gl_ext_fgets, (gl_e_charptr_t s, int n,
	gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_fwrite, (gl_e_charptr_t ptr, int size, int nitems,
	gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_feof, (gl_e_fileptr_t stream));
GL_PROTO(gl_e_voidptr_t GL_EXPORT, _gl_ext_UCA, (GL_VOIDARGS));
GL_PROTO(int GL_EXPORT, _gl_ext_ferror, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, _gl_ext_fseek, (gl_e_fileptr_t stream, long offset, int
	origin));
GL_PROTO(long GL_EXPORT, _gl_ext_ftell, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, gl_setextfunc, (gl_lc_t loc, int func,
	gl_uintptr (GL_EPTR funcptr)(GL_VOIDARGS)));

/* Use GLU for Unicode */
#ifndef GLU_DISABLED
#define GLU_ENABLED
#endif

#ifdef GLU_ENABLED
GL_PROTO(void GL_EXPORT, gl_useglu, (int mode));
#endif /* GLU_ENABLED */

/* library information */
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_version, (void));
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_cm_version, (void));
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_lc_version, (void));
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_cv_version, (void));

/* locale object creation/deletion */
GL_PROTO(int GL_EXPORT, gl_createlocale, (gl_lcptr_t loc));
GL_PROTO(int GL_EXPORT, gl_createlocale2, (gl_lcptr_t loc, gl_e_charptr_t path));
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_setlocale, (gl_lc_t l, int category,
				    gl_e_charptr_t locale_name));
GL_PROTO(int GL_EXPORT, gl_lc_load, (gl_lcptr_t lc, gl_e_charptr_t lc_spec,
                               gl_e_charptr_t registry, gl_e_charptr_t lc_dir));
GL_PROTO(void GL_EXPORT, gl_lc_unload, (gl_lc_t l));
GL_PROTO(int GL_EXPORT, gl_create_null_locale, (gl_lcptr_t loc));
GL_PROTO(void GL_EXPORT, gl_free_nonshared_loc, (gl_lc_t loc));
GL_PROTO(void GL_EXPORT, gl_free_category, (gl_lc_t loc, int category));
GL_PROTO(void GL_EXPORT, gl_make_null_category, (gl_lc_t loc, int category));
GL_PROTO(int GL_EXPORT, gl_copy_cat, (gl_lc_t dst, gl_lc_t src, int category));

/* codeset information */
GL_PROTO(int GL_EXPORT, gl_mb_loc_max, (gl_lc_t loc));
GL_PROTO(int GL_EXPORT, gl_mb_loc_min, (gl_lc_t loc));


/* User-defined character classification */

GL_PROTO(gl_ctype_t GL_EXPORT, gl_ctype, (gl_lc_t loc, gl_e_charptr_t classname));
GL_PROTO(int GL_EXPORT, _gl_im_ismctype, (gl_lc_t loc, gl_e_mcharptr_t text, gl_ctype_t charclass));
GL_PROTO(int GL_EXPORT, _gl_im_iswctype, (gl_lc_t loc, gl_wchar_t wc, gl_ctype_t charclass));

/* Case conversion functions */

#define gl_towupper(lc, srcwc) \
   ( GL_LC_SB_TOUPPER_TABLE(lc) ? \
     ( ((gl_wchar_t) (srcwc)) <= ((gl_wchar_t) 0xff) ? \
       ((gl_wchar_t) GL_LC_SB_TOUPPER_TABLE(lc)[(gl_wchar_t) (srcwc)]) : \
       (gl_set_errno(lc, GL_EILSEQ), ((gl_wchar_t) (srcwc))) ) : \
     _gl_im_towupper((lc), (gl_wchar_t) (srcwc)) \
   )
#define gl_towlower(lc, srcwc) \
   ( GL_LC_SB_TOLOWER_TABLE(lc) ? \
     ( ((gl_wchar_t) (srcwc)) <= ((gl_wchar_t) 0xff) ? \
       ((gl_wchar_t) GL_LC_SB_TOLOWER_TABLE(lc)[(gl_wchar_t) (srcwc)]) : \
       (gl_set_errno(lc, GL_EILSEQ), ((gl_wchar_t) (srcwc))) ) : \
     _gl_im_towlower((lc), (gl_wchar_t) (srcwc)) \
   )

/* Heavy casting to avoid lint warnings: this is just ((1 << 8) | 1) */
#define GL_SBTOMRETVAL \
   ((unsigned short) ((((unsigned long) 1) << 8) | ((unsigned short) 1)))

#define gl_tomupper(lc, dstmb, srcmb) \
   ( GL_LC_SB_TOUPPER_TABLE(lc) ? \
     ((*((gl_mchar_t *) (dstmb))) = \
      GL_LC_SB_TOUPPER_TABLE(lc)[*((gl_mchar_t *) (srcmb))], GL_SBTOMRETVAL) : \
     _gl_im_tomupper((lc), (dstmb), (srcmb)) \
   )
#define gl_tomlower(lc, dstmb, srcmb) \
   ( GL_LC_SB_TOLOWER_TABLE(lc) ? \
     ((*((gl_mchar_t *) (dstmb))) = \
      GL_LC_SB_TOLOWER_TABLE(lc)[*((gl_mchar_t *) (srcmb))], GL_SBTOMRETVAL) : \
     _gl_im_tomlower((lc), (dstmb), (srcmb)) \
   )

GL_PROTO(gl_wchar_t GL_EXPORT, _gl_im_towupper, (gl_lc_t loc, gl_wchar_t wc));
GL_PROTO(gl_wchar_t GL_EXPORT, _gl_im_towlower, (gl_lc_t loc, gl_wchar_t wc));
GL_PROTO(unsigned short GL_EXPORT, _gl_im_tomupper, (gl_lc_t loc, gl_e_mcharptr_t dst, gl_e_mcharptr_t src));
GL_PROTO(unsigned short GL_EXPORT, _gl_im_tomlower, (gl_lc_t loc, gl_e_mcharptr_t dst, gl_e_mcharptr_t src));
GL_PROTO(int GL_EXPORT, gl_tombsupper, (gl_lc_t loc, gl_e_mcharptr_t dstmbs, gl_e_mcharptr_t srcmbs));
GL_PROTO(int GL_EXPORT, gl_tombslower, (gl_lc_t loc, gl_e_mcharptr_t dstmbs, gl_e_mcharptr_t srcmbs));
GL_PROTO(int GL_EXPORT, gl_towcsupper, (gl_lc_t loc, gl_wchar_t *dstwcs, gl_wchar_t *srcwcs));
GL_PROTO(int GL_EXPORT, gl_towcslower, (gl_lc_t loc, gl_wchar_t *dstwcs, gl_wchar_t *srcwcs));
GL_PROTO(int GL_EXPORT, gl_case_conv_outbuflen, (gl_lc_t lc, int inbufsize));

/* Multibyte/wide character conversions */

GL_PROTO(int GL_EXPORT, gl_full_mbtowc, (gl_lc_t loc, gl_e_wcharptr_t wc, gl_e_mcharptr_t text, int n));
GL_PROTO(int GL_EXPORT, gl_full_wctomb, (gl_lc_t loc, gl_e_mcharptr_t dest, gl_wchar_t wc));
GL_PROTO(int GL_EXPORT, _gl_is_wcstombs, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_wcharptr_t wcs, int n));
GL_PROTO(int GL_EXPORT, gl_full_wcstombs, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_wcharptr_t wcs, int n));

/* Functions required for backward compatibility */
GL_PROTO(int GL_EXPORT, is_wcstombs, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_wcharptr_t wcs, int n));
GL_PROTO(int GL_EXPORT, im_ismctype, (gl_lc_t loc, gl_e_mcharptr_t text, gl_ctype_t charclass));
GL_PROTO(int GL_EXPORT, im_iswctype, (gl_lc_t loc, gl_wchar_t wc, gl_ctype_t charclass));
GL_PROTO(unsigned short GL_EXPORT, im_tomlower, (gl_lc_t loc, gl_e_mcharptr_t dst, gl_e_mcharptr_t src));
GL_PROTO(gl_wchar_t GL_EXPORT, im_towlower, (gl_lc_t loc, gl_wchar_t wc));

/* Length functions */

GL_PROTO(int GL_EXPORT, _gl_im_mbslen, (gl_lc_t loc, gl_e_mcharptr_t mbs));
GL_PROTO(int GL_EXPORT, gl_wcslen, (gl_e_wcharptr_t wcs));
GL_PROTO(int GL_EXPORT, gl_wcsbytes, (gl_e_wcharptr_t wcs));
GL_PROTO(int GL_EXPORT, gl_mbsbytes, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(int GL_EXPORT, gl_full_mblen, (gl_lc_t loc, gl_e_mcharptr_t text, int n));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbsnext, (gl_lc_t loc, gl_e_mcharptr_t text));
GL_PROTO(int GL_EXPORT, gl_wclen, (gl_lc_t loc, gl_wchar_t wc));

/* Time Functions */
GL_PROTO(int GL_EXPORT, gl_mbsfinterval,
      (gl_lc_t loc, gl_e_mcharptr_t s, int maxsize, gl_e_mcharptr_t format,
       struct gl_tm GL_EPTR timptr));

GL_PROTO(int GL_EXPORT, gl_mbsftime,
      (gl_lc_t loc, gl_e_mcharptr_t s, int maxsize, gl_e_mcharptr_t format,
       struct gl_tm GL_EPTR timptr));

GL_PROTO(gl_e_mcharptr_t  GL_EXPORT, gl_mbsptime,
      (gl_lc_t loc, gl_e_mcharptr_t s, gl_e_mcharptr_t format,
       struct gl_tm GL_EPTR tmptr, int calg));

GL_PROTO(int GL_EXPORT, gl_wcsftime,
      (gl_lc_t loc, gl_e_wcharptr_t s, int maxsize, gl_e_wcharptr_t format,
       struct gl_tm GL_EPTR timptr));

GL_PROTO(gl_e_wcharptr_t  GL_EXPORT, gl_wcsptime,
      (gl_lc_t loc, gl_e_wcharptr_t s, gl_e_wcharptr_t format,
       struct gl_tm GL_EPTR tmptr, int calg));

GL_PROTO(gl_e_mcharptr_t  GL_EXPORT, gl_mbsptime_internal,
      (gl_lc_t loc, gl_e_mcharptr_t s, gl_e_mcharptr_t format,
       struct gl_tm GL_EPTR tmptr, short mdy[3], int calg));

GL_PROTO(gl_e_wcharptr_t  GL_EXPORT, gl_wcsptime_internal,
      (gl_lc_t loc, gl_e_wcharptr_t s, gl_e_wcharptr_t format,
       struct gl_tm GL_EPTR tmptr, short mdy[3], int calg));

GL_PROTO(int GL_EXPORT, gl_getcentury,
      (gl_lc_t loc, int month, int day, int year, int calg));

GL_PROTO(int GL_EXPORT, gl_getcentury_internal,
      (gl_lc_t loc, int month, int day, int year,
       int ref_month, int ref_day, int ref_year, int calg));

GL_PROTO(int GL_EXPORT, gl_mbstimeinfo_ext,
      (gl_lc_t loc, int infotype, gl_mchar_t GL_EPTR GL_EPTR GL_EPTR strs,
       int GL_EPTR count, void GL_EPTR(GL_PASCAL GL_EPTR fptr_malloc)(size_t)));

GL_PROTO(int GL_EXPORT, gl_mbstimeinfo,
      (gl_lc_t loc, int infotype, gl_mchar_t GL_EPTR GL_EPTR GL_EPTR strs,
       int GL_EPTR count));

GL_PROTO(int GL_EXPORT, gl_mbsfmtexpand,
      (gl_lc_t loc, int fmttype, gl_mchar_t GL_EPTR format));

GL_PROTO(gl_e_mcharptr_t  GL_EXPORT, gl_get_ltime_fmts,
      (gl_lc_t loc, int field));

GL_PROTO(int  GL_EXPORT, gl_get_era_count,
      (gl_lc_t loc));

/* Collation routines */

#define gl_wcscoll(lc, wcs1, wcs2) ( GL_IS_CODESET_ORDER(lc) ? \
                                           gl_wcscmp((wcs1), (wcs2)) : \
                                           gl_full_wcscoll((lc), (wcs1), (wcs2)) )
GL_PROTO(int GL_EXPORT, gl_full_wcscoll, (gl_lc_t l, gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(int GL_EXPORT, gl_wcscmp, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(int GL_EXPORT, gl_wcsncmp, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2, int n));
GL_PROTO(int GL_EXPORT, gl_full_mbscmp, (gl_lc_t loc, gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2));
GL_PROTO(int GL_EXPORT, gl_full_mbsncmp, (gl_lc_t loc, gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2, int nc));
GL_PROTO(int GL_EXPORT, gl_wcsxfrm, (gl_lc_t loc, gl_e_charptr_t dst, gl_e_wcharptr_t wcs, int nb));
GL_PROTO(int GL_EXPORT, gl_full_mbsxfrm, (gl_lc_t loc, char *dst, gl_e_mcharptr_t mbs, int nb));

/* Codeset conversion */

GL_PROTO(int GL_EXPORT, gl_cv_open, (gl_iconvptr_t cd, gl_e_charptr_t to_lc_spec,
        gl_e_charptr_t from_lc_spec));
GL_PROTO(int GL_EXPORT, gl_iconv_open, (gl_iconvptr_t cd, gl_e_charptr_t targetfile,
        gl_e_charptr_t sourcefile));
GL_PROTO(int GL_EXPORT, gl_iconv_open1, (gl_iconvptr_t cd, gl_e_charptr_t filename));
GL_PROTO(int GL_EXPORT, gl_cv_load, (gl_iconvptr_t cv,
                                  gl_e_charptr_t to_lc_spec,
                                  gl_e_charptr_t from_lc_spec,
                                  gl_e_charptr_t registry,
                                  gl_e_charptr_t cv_dir));
GL_PROTO(int GL_EXPORT, gl_cv_unload, (gl_cv_t cd));
GL_PROTO(int GL_EXPORT, gl_miconv, (gl_cv_t cd, gl_e_mcharptr_t GL_EPTR inmbs, gl_e_intptr_t inlen,
	gl_e_mcharptr_t GL_EPTR outmbs, gl_e_intptr_t outlen, gl_e_intptr_t sub));
GL_PROTO(int GL_EXPORT, gl_cv_mconv, (gl_cv_t cd, gl_cv_state_t GL_EPTR st,
        gl_e_mcharptr_t GL_EPTR inmbs, gl_e_intptr_t inlen, gl_e_mcharptr_t GL_EPTR outmbs,
        gl_e_intptr_t outlen, gl_e_intptr_t sub));
GL_PROTO(double GL_EXPORT, gl_iconv_expansion, (gl_cv_t cd));
GL_PROTO(int GL_EXPORT, gl_cv_outbuflen, (gl_cv_t cd, int inbufsize));
GL_PROTO(int GL_EXPORT, gl_mconvlen, (gl_cv_t cd, gl_cv_state_t GL_EPTR st,
        gl_e_mcharptr_t GL_EPTR inmbs, gl_e_intptr_t inlen, gl_e_intptr_t outlen, gl_e_intptr_t sub));
GL_PROTO(gl_cvfns_ref_t GL_EXPORT, gl_add_cvfns, (gl_cvfns_ref_t prev_ref,
        gl_cv_funcdef_t GL_EPTR fndef));
GL_PROTO(int GL_EXPORT, gl_cv_fnopen, (gl_iconvptr_t cd, gl_e_charptr_t to_lc_spec,
        gl_e_charptr_t from_lc_spec, gl_cvfns_ref_t fns_ref));

/* String handling functions */

GL_PROTO(int GL_EXPORT, gl_wcsntslen, (gl_lc_t l, gl_e_wcharptr_t wcs));
GL_PROTO(int GL_EXPORT, gl_mbsntslen, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(int GL_EXPORT, gl_mbsntsbytes, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(int GL_EXPORT, gl_wcswidth, (gl_lc_t l, gl_e_wcharptr_t wcs, int n));
GL_PROTO(int GL_EXPORT, gl_mbswidth, (gl_lc_t l,gl_e_mcharptr_t mbs, int n));
GL_PROTO(int GL_EXPORT, gl_wcspwidth, (gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t p));
GL_PROTO(int GL_EXPORT, gl_mbspwidth, (gl_lc_t l,gl_e_mcharptr_t mbs, gl_e_mcharptr_t p));
GL_PROTO(int GL_EXPORT, gl_wcwidth, (gl_lc_t l, gl_wchar_t wc));
GL_PROTO(int GL_EXPORT, gl_mbwidth, (gl_lc_t l, gl_e_mcharptr_t mb));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_getmbsi, (gl_lc_t l,gl_e_mcharptr_t mbs, int i));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_putmbsi, (gl_lc_t l, gl_e_mcharptr_t mbs, int i, gl_e_mcharptr_t mdc));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbsprev, (gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t mbp));
GL_PROTO(int GL_EXPORT, gl_mbsterm, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(int GL_EXPORT, gl_ismbsterm, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(void GL_EXPORT, gl_wcsntstrunc, (gl_lc_t l, gl_e_wcharptr_t wcs));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_mbsntstrunc, (gl_lc_t l, gl_e_mcharptr_t mbs));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcscat, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbscat, (gl_lc_t l, gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcsncat, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2, int n));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_mbsncat, (gl_lc_t l,gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2, int n));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcscpy, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbscpy, (gl_lc_t l ,gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcsncpy, (gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2, int n));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_mbsncpy, (gl_lc_t l,gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2, int n));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbschr, (gl_lc_t l ,gl_e_mcharptr_t mbs, gl_e_mcharptr_t mb));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbsrchr, (gl_lc_t l ,gl_e_mcharptr_t mbs, gl_e_mcharptr_t mb));
GL_PROTO(int GL_EXPORT, gl_full_mbscspn, (gl_lc_t l, gl_e_mcharptr_t mbs1,gl_e_mcharptr_t mbs2));
GL_PROTO(int GL_EXPORT, gl_full_mbsspn, (gl_lc_t l,gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbspbrk, (gl_lc_t l, gl_e_mcharptr_t mbsp1, gl_e_mcharptr_t mbsp2));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_full_mbsmbs, (gl_lc_t l,gl_e_mcharptr_t mbs1, gl_e_mcharptr_t mbs2));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcschr,
      (gl_lc_t loc, gl_e_wcharptr_t wcs, gl_wchar_t wc));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcsrchr,
      (gl_lc_t loc, gl_e_wcharptr_t wcs, gl_wchar_t wc));
GL_PROTO(int GL_EXPORT, gl_wcsspn,
      (gl_lc_t loc, gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(int GL_EXPORT, gl_wcscspn,
      (gl_lc_t loc, gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcswcs,
      (gl_lc_t loc, gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wcspbrk,
      (gl_lc_t loc, gl_e_wcharptr_t wcs1, gl_e_wcharptr_t wcs2));

/* Locale information functions */

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_nl_langinfo, (gl_lc_t loc, int item));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT, gl_wc_nl_langinfo, (gl_lc_t loc, int item));
typedef struct gl_conv GL_EPTR gl_e_glconvptr_t;
/* the above typedef is only to get around Microsoft Visual C++ 2.0
   parse problem with the following line */
GL_PROTO(gl_e_glconvptr_t GL_EXPORT, gl_localeconv, (gl_lc_t loc));

/* Numeric functions */

GL_PROTO(long GL_EXPORT, gl_wcstol, (gl_lc_t loc, gl_e_wcharptr_t wcs, gl_e_wcharptr_t GL_EPTR endptr,
		int base, int grouping));
GL_PROTO(long GL_EXPORT, gl_mbstol, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_mcharptr_t GL_EPTR endptr, int base,
               	int grouping));
GL_PROTO(unsigned long GL_EXPORT, gl_wcstoul, (gl_lc_t loc, gl_e_wcharptr_t wcs,
		gl_e_wcharptr_t GL_EPTR endptr, int base, int grouping));
GL_PROTO(unsigned long GL_EXPORT, gl_mbstoul, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_mcharptr_t GL_EPTR endptr,
               	int base, int grouping));
GL_PROTO(void GL_EXPORT, gl_ltowcs, (gl_lc_t loc, gl_e_wcharptr_t wcs, size_t maxsize,
               	long int int_data, int base, int grouping));
GL_PROTO(void GL_EXPORT, gl_ltombs, (gl_lc_t loc, gl_e_mcharptr_t mbs, size_t maxsize,
		long int int_data, int base, int grouping));
GL_PROTO(void GL_EXPORT, gl_ultowcs, (gl_lc_t loc, gl_e_wcharptr_t wcs, size_t maxsize,
                unsigned long int int_data, int base, int grouping));
GL_PROTO(void GL_EXPORT, gl_ultombs, (gl_lc_t loc, gl_e_mcharptr_t mbs, size_t maxsize,
                unsigned long int_data, int base, int grouping));
GL_PROTO(double GL_EXPORT, gl_wcstod, (gl_lc_t loc, gl_e_wcharptr_t wcs, gl_e_wcharptr_t GL_EPTR endptr,
                int grouping));
GL_PROTO(double GL_EXPORT, gl_mbstod, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_mcharptr_t GL_EPTR endptr,
                int grouping));


/* float/currency string conversion functions */
/* The Borland C compiler has problems with the following prototype when
   set up with a GL_PROTO macro */
#if defined (__STDC__) || defined (PCDOS) || defined(_WIN32) || defined(_WINDOWS) || defined(_WIN64)
int GL_EXPORT GL_CDECL gl_wcsfmon(gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...);
gl_e_wcharptr_t GL_EXPORT GL_CDECL gl_wcspmon(gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_wcsprintf(gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_wcsscanf(gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_mbsfmon(gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...);
gl_e_mcharptr_t GL_EXPORT GL_CDECL gl_mbspmon(gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_mbsprintf(gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_mbsscanf(gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...);
#else
GL_PROTO(int GL_EXPORT, gl_wcsfmon, (gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...));
GL_PROTO(gl_e_wcharptr_t GL_EXPORT GL_CDECL, gl_wcspmon, (gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_wcsprintf, (gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_wcsscanf, (gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_mbsfmon, (gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT GL_CDECL, gl_mbspmon, (gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_mbsprintf, (gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_mbsscanf, (gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...));
#endif




/* Input and output functions */

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_fputmb, (gl_lc_t loc, gl_e_mcharptr_t mb, gl_e_fileptr_t fp));
GL_PROTO(gl_wchar_t GL_EXPORT, gl_fputwc, (gl_lc_t loc, gl_wchar_t wc, gl_e_fileptr_t fp));
GL_PROTO(int GL_EXPORT, gl_fputmbs, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_fileptr_t fp));
GL_PROTO(int GL_EXPORT, gl_fputwcs, (gl_lc_t loc, gl_e_wcharptr_t wcs, gl_e_fileptr_t fp));
GL_PROTO(int GL_EXPORT, gl_full_fgetmb, (gl_lc_t loc, gl_e_mcharptr_t mb, gl_e_fileptr_t fp));
GL_PROTO(gl_wchar_t GL_EXPORT, gl_full_fgetwc, (gl_lc_t loc, gl_e_fileptr_t fp));
GL_PROTO(gl_e_mcharptr_t GL_EXPORT, gl_fgetmbs, (gl_lc_t loc, gl_e_mcharptr_t mbs, int n, gl_e_fileptr_t fp));
GL_PROTO(gl_e_wcharptr_t  GL_EXPORT, gl_fgetwcs, (gl_lc_t loc, gl_e_wcharptr_t wcs, int n, gl_e_fileptr_t fp));

GL_PROTO(int GL_EXPORT, gl_getmb, (gl_lc_t loc, gl_mchar_t *buf,
				GL_PTR_PROTO(int, fp, (void *v)), void *v,
				int *bytes_read));

GL_PROTO(int GL_EXPORT, gl_putmb, (gl_lc_t loc, gl_mchar_t *buf, int buflen,
				GL_PTR_PROTO(int, fp, (gl_mchar_t mb, void *v)),
				void *v, int *bytes_written));

/* gl_charoffset() function */

GL_PROTO(int GL_EXPORT, gl_full_charoffset, (gl_lc_t loc, gl_e_mcharptr_t mbs, gl_e_mcharptr_t mbp, gl_e_intptr_t len));

#if defined(GL_DLL)
GL_PROTO(void GL_EXPORT, gl_fclose, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, gl_feof, (gl_e_fileptr_t stream));
GL_PROTO(int GL_EXPORT, gl_ferror, (gl_e_fileptr_t stream));
GL_PROTO(gl_e_fileptr_t GL_EXPORT, gl_fopen, (gl_e_charptr_t file, gl_e_charptr_t
	mode));
GL_PROTO(int GL_EXPORT, gl_fseek, (gl_e_fileptr_t stream, long offset, int
	origin));
GL_PROTO(long GL_EXPORT, gl_ftell, (gl_e_fileptr_t stream));
#else
#define gl_fclose(x)    fclose((x))
#define gl_feof(x)      feof((x))
#define gl_ferror(x)    ferror((x))
#define gl_fopen(x,y)   fopen((x),(y))
#define gl_fseek(x,y,z) fseek((x),(y),(z))
#define gl_ftell(x)     ftell((x))
#endif

/* Codeset name to codeset number conversion functions */

GL_PROTO(unsigned short GL_EXPORT, gl_lc_spec2cs_num, (gl_gen_expptr_t expptr,
                                         gl_e_charptr_t spec,
					 gl_e_charptr_t registry));
GL_PROTO(void GL_EXPORT, gl_cs_nums2cv_fname, (gl_gen_expptr_t expptr,
                                 unsigned short from_cs_number,
                                 unsigned short to_cs_number,
                                 gl_e_charptr_t buf,
				 gl_e_charptr_t lc_path));
GL_PROTO(int GL_EXPORT, gl_lc_spec2lc_fname, (gl_gen_expptr_t expptr,
                                gl_e_charptr_t buf,
                                gl_e_charptr_t spec,
				gl_e_charptr_t registry,
				gl_e_charptr_t lc_path));
GL_PROTO(int GL_EXPORT, gl_lc_spec2msg_dname, (gl_gen_expptr_t expptr,
                                 gl_e_charptr_t buf,
                                 gl_e_charptr_t spec,
                                 gl_e_charptr_t registry,
				 gl_e_charptr_t lc_path));
GL_PROTO(int GL_EXPORT,  gl_lc_fname2lc_pieces, (gl_gen_expptr_t expptr,
					      gl_e_charptr_t fname,
					      gl_e_charptr_t lname,
					      gl_e_charptr_t cname,
					      gl_e_charptr_t mname));
GL_PROTO(int GL_EXPORT,  gl_lc_pieces2lc_spec, (gl_gen_expptr_t expptr,
					     gl_e_charptr_t lname,
					     gl_e_charptr_t cname,
					     gl_e_charptr_t mname,
					     gl_e_charptr_t lc_spec));
GL_PROTO(int GL_EXPORT,  gl_lc_spec2lc_norm, (gl_gen_expptr_t expptr,
					     gl_e_charptr_t lc_spec,
					     gl_e_charptr_t lc_norm,
					     gl_e_charptr_t registry));

GL_PROTO(void GL_EXPORT,  gl_cache_registry, (gl_gen_expptr_t expptr,
					   gl_e_charptr_t registry));

GL_PROTO(void GL_EXPORT, gl_free_registry_cache, (GL_VOIDARGS));

GL_PROTO(unsigned short GL_EXPORT, gl_cs_nums2ccsid, (gl_gen_expptr_t expptr,
                                 unsigned short cs_number));
GL_PROTO(unsigned short GL_EXPORT, gl_ccsid2cs_nums, (gl_gen_expptr_t expptr,
                                 unsigned short ccsid));

#ifdef GLU_ENABLED
GL_PROTO(int GL_EXPORT, gl_init_glu, (gl_gen_expptr_t expptr));
GL_PROTO(int GL_EXPORT, gl_init_glu_oninit, (gl_gen_expptr_t expptr));

GL_PROTO(int GL_EXPORT, gl_init_glu_dll, (gl_gen_expptr_t expptr));
#endif /* GLU_ENABLED */

GL_PROTO(int GL_EXPORT, gl_is_lc_spec, (gl_gen_expptr_t expptr,
                              gl_e_charptr_t lc_spec));

GL_PROTO(int GL_EXPORT, gl_lc_fname2lc_spec, (gl_gen_expptr_t expptr,
		              gl_e_charptr_t lc_fname,
                              gl_e_charptr_t lc_spec,
                              gl_e_charptr_t lc_path));

GL_PROTO(int GL_EXPORT, gl_lc_spec2category, (gl_gen_expptr_t expptr,
                              gl_e_charptr_t lc_spec,
                              int category,
                              gl_e_charptr_t lc_short,
                              gl_e_charptr_t registry));

GL_PROTO(int GL_EXPORT, gl_lc_spec2lc_short, (gl_gen_expptr_t expptr,
                              gl_e_charptr_t lc_spec,
                              gl_e_charptr_t lc_short,
                              gl_e_charptr_t registry));

GL_PROTO(int GL_EXPORT, gl_lc_short2lc_long, (gl_gen_expptr_t expptr,
                              gl_e_charptr_t lc_spec,
                              gl_e_charptr_t lc_long,
                              gl_e_charptr_t registry));

/* memory management functions */
GL_PROTO(void GL_EXPORT, gl_destroystring, (gl_e_charptr_t string));

/* charmap functions */
GL_PROTO(int GL_EXPORT, gl_mbstosyms, (gl_cm_t cm,
				    char *syms,
				    int max_sym_bytes,
				    gl_mchar_t** mbs,
				    int len));
GL_PROTO(int GL_EXPORT, gl_wcstosyms, (gl_cm_t cm,
				    char *syms,
				    int max_sym_bytes,
				    gl_wchar_t** wcs,
				    int len));
GL_PROTO(int GL_EXPORT, gl_symstombs, (gl_cm_t cm,
				   gl_mchar_t* mbs,
				   int max_mbs_bytes,
				   char **syms));
GL_PROTO(int GL_EXPORT, gl_symstowcs, (gl_cm_t cm,
				   gl_wchar_t* wcs,
				   int max_wcs_chars,
				   char **syms));
GL_PROTO(int GL_EXPORT, gl_mbtosymlist, (gl_cm_t cm,
				      char *symlist,
				      int listlen,
				      gl_mchar_t *mb,
				      int mblen));
GL_PROTO(int GL_EXPORT, gl_cm_load, (gl_cm_t *cm,
				  char *cm_spec,
				  char *registry,
				  char *cm_dir));
GL_PROTO(void GL_EXPORT, gl_cm_unload, (gl_cm_t cm));
GL_PROTO(int GL_EXPORT, gl_mb_cm_max, (gl_cm_t cm));
GL_PROTO(int GL_EXPORT, gl_mb_cm_min, (gl_cm_t cm));
GL_PROTO(int GL_EXPORT, gl_cm_mblen, (gl_cm_t cm,
				   gl_e_mcharptr_t text,
				   int n));
GL_PROTO(int GL_EXPORT, gl_cm_cmpver, (gl_cm_t));
GL_PROTO(int GL_EXPORT, gl_cm_srcver, (gl_cm_t));
GL_PROTO(gl_e_charptr_t GL_EXPORT, gl_cm_csname, (gl_cm_t));
GL_PROTO(int GL_EXPORT, _gl_ext_currdate, (short GL_EPTR));
GL_PROTO(int GL_EXPORT, _gl_ext_currtime, (gl_tm_t GL_EPTR));


/* ATG LIKE/MATCHES for NCHAR functions */
GL_PROTO(int GL_EXPORT, gl_mbsCollBound, (gl_lc_t lc, gl_mchar_t *in,
                                          int mode, gl_mchar_t *out, int maxbytes));
GL_PROTO(int GL_EXPORT, gl_mbsSortKeyCollBound, (gl_lc_t lc, gl_mchar_t *in,
                                          int mode, gl_mchar_t *out, int maxbytes));
GL_PROTO(int GL_EXPORT, gl_getpassdirection, (gl_lc_t lc, int passnum));
GL_PROTO(int GL_EXPORT, gl_iscompchar, (gl_lc_t lc, gl_mchar_t *s));
GL_PROTO(int GL_EXPORT, gl_iscompchar_thai, (gl_lc_t lc, gl_mchar_t *s));
GL_PROTO(int GL_EXPORT, gl_nextprimweight, (gl_lc_t lc, gl_mchar_t *c,
                                            int iscomplete, gl_mchar_t *w));
GL_PROTO(int GL_EXPORT, gl_prevprimweight, (gl_lc_t lc, gl_mchar_t *c,
                                            int iscomplete, gl_mchar_t *w));
GL_PROTO(int GL_EXPORT, gl_IsSpecialLocale, (gl_lc_t lc));


/* #ifdef IFX_USE_OBSOLETE_GLS_MACROS
** gcousins: I amthe macro IFX_USE_OBSOLETE_GLS_MACROS and 
** IFX_USE_OBSOLETE_GLS_TYPEDEFS will be intorduced in the next major 
** version of GLS and will be removed (including the contents of the ifdef code)
** from the next major version after that.
*/

/*
** DZ 1994-11-10: Defines for backward compatibility.
** Use of these should be avoided if possible as they may go away in a
** future release.
** JL 2003-08-08: Old macros made invisible by default, and list extended.
*/

#define get_gl_errno(x)     gl_get_errno(x)
#define set_gl_errno(x,y)   gl_set_errno((x),(y))
#if defined (__STDC__) || defined (PCDOS) || defined(_WIN32) || defined(_WINDOWS) || defined(_WIN64)
int GL_EXPORT GL_CDECL gl_wcsfnum(gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_wcspnum(gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_mbsfnum(gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...);
int GL_EXPORT GL_CDECL gl_mbspnum(gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...);
#else
GL_PROTO(int GL_EXPORT, gl_wcsfnum, (gl_lc_t l, gl_e_wcharptr_t wcs, int maxchars, gl_e_wcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_wcspnum, (gl_lc_t l, gl_e_wcharptr_t wcs, gl_e_wcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_mbsfnum, (gl_lc_t l, gl_e_mcharptr_t mbs, int maxbytes, gl_e_mcharptr_t format, ...));
GL_PROTO(int GL_EXPORT, gl_mbspnum, (gl_lc_t l, gl_e_mcharptr_t mbs, gl_e_mcharptr_t format, ...));
#endif
#define gl_destroylocale                  gl_lc_unload
#define gl_cs_from_spec(spec)             gl_lc_spec2cs_num(0,(spec),0)
#define gl_loc_fname_from_spec(spec,buf)  gl_lc_spec2lc_fname(0,(spec),(buf),0,0)
#define gl_cs_fname_from_cs_nums(a,b,c)   gl_cs_nums2cv_fname(0,(a),(b),(c),0)
#define gl_iconv_close                    gl_cv_unload
#define gl_cv_close                       gl_cv_unload
#define gl_smiconv                        gl_cv_mconv
#define gl_cv_conv                        gl_cv_mconv

/* #endif *//* IFX_USE_OBSOLETE_GLS_MACROS */

/* #ifdef IFX_USE_OBSOLETE_GLS_TYPEDEFS */

/*
** DZ 1994-11-10: Types for backward compatibility.
** Use of these should be avoided if possible as they may go away in a
** future release.
** JL 2003-08-08: Old types made invisible by default, and list extended.
*/

#ifdef IFX_USE_OBSOLETE_GLS_TYPEDEFS_LOCALE_T
	typedef gl_lc_t		locale_t;
#endif /* IFX_USE_OBSOLETE_GLS_TYPEDEFS_LOCALE_T */

#define glconv	gl_conv
typedef gl_cv_t		gl_iconv_t;
typedef gl_mchar_t	mchar_t;
typedef gl_wchar_t	gl_wint_t;
typedef gl_conv_t glconv_t;
typedef gl_cv_res_t conv_res_t;
typedef gl_cv_state_t conv_state_t;
typedef gl_cmap_exports_t GL_EPTR cm_expptr_t;
typedef gl_cmap_exports_t cmap_exports_t;
typedef gl_loc_exports_t GL_EPTR lc_expptr_t;
typedef gl_loc_exports_t loc_exports_t;
typedef gl_cv_exports_t GL_EPTR iconv_expptr_t;
typedef gl_cv_exports_t iconv_exports_t;
typedef gl_gen_exports_t gen_exports_t;

/* #endif */ /* IFX_USE_OBSOLETE_GLS_TYPEDEFS */

/***************************************************************************
 *
 * The remainder of this include file contains prototypes and macros
 * related to user level functions
 *
 ***************************************************************************
 */

/* success and failure indicators */
#define IFX_GL_SUCCESS  0
#define IFX_GL_FAILURE -1

/* Defines for error numbers mapped to error numbers in gls.h */

#define IFX_GL_NOERRNO      GL_NOERRNO      /* No error has occurred             */
#define IFX_GL_EILSEQ       GL_EILSEQ       /* Invalid MB sequence               */
#define IFX_GL_ENULLPTR     GL_ENULLPTR     /* NULL Pointer to a function        */
#define IFX_GL_ENOMEM       GL_ENOMEM       /* memory allocation failure         */
#define IFX_GL_EINDEXRANGE  GL_EINDEXRANGE  /* index out of bounds               */
#define IFX_GL_EINVPTR      GL_EINVPTR      /* End pointer < begin pointer       */
#define IFX_GL_ERANGE       GL_ERANGE       /* BASE of number is out of range.   */
#define IFX_GL_EINVAL       GL_EINVAL       /* Invalid wcs or mbs strings        */
#define IFX_GL_FILEERR      GL_FILEERR      /* input file could not be read      */
#define IFX_GL_PARAMERR     GL_PARAMERR     /* parameter out of bounds           */
#define IFX_GL_CATASTROPHE  GL_CATASTROPHE  /* internal error; undefined result  */
#define IFX_GL_BADFILEFORM  GL_BADFILEFORM  /* file format was invalid           */
#define IFX_GL_INVALIDLOC   GL_INVALIDLOC   /* locale codesets are inconsistent  */
#define IFX_GL_EIO          GL_EIO          /* I/O error                         */
#define IFX_GL_E2BIG        GL_E2BIG        /* Operation would overflow buffer   */
#define IFX_GL_EBADF        GL_EBADF        /* Bad handle passed to function     */
#define IFX_GL_EOF          GL_EOF          /* End of file on input stream       */
#define IFX_GL_EUNKNOWN     GL_EUNKNOWN     /* Unknown system error has occurred */
#define IFX_GL_UNLOADEDCAT  GL_UNLOADEDCAT  /* Can't copy from unloaded category */
#define IFX_GL_LOADEDCAT    GL_LOADEDCAT    /* Can't copy into a loaded category */
#define IFX_GL_ENOSYS       GL_ENOSYS       /* function is not supported         */
#define IFX_GL_ELOCTOOWIDE  GL_ELOCTOOWIDE  /* has chars too wide for library    */
#define IFX_GL_INVALIDFMT   GL_INVALIDFMT   /* Invalid formatted argument string */
#define IFX_GL_EFRACRANGE   GL_EFRACRANGE   /* Fraction of  Second out of bounds */
#define IFX_GL_ESECONDRANGE GL_ESECONDRANGE /* Second out of bounds              */
#define IFX_GL_EMINUTERANGE GL_EMINUTERANGE /* Minute out of bounds              */
#define IFX_GL_EHOURRANGE   GL_EHOURRANGE   /* Hour out of bounds                */
#define IFX_GL_EDAYRANGE    GL_EDAYRANGE    /* Day number out of bounds          */
#define IFX_GL_EWKDAYRANGE  GL_EWKDAYRANGE  /* Week Day number out of bounds     */
#define IFX_GL_EYDAYRANGE   GL_EYDAYRANGE   /* Year Day number out of bounds     */
#define IFX_GL_EMONTHRANGE  GL_EMONTHRANGE  /* Month number out of bounds        */
#define IFX_GL_EYEARRANGE   GL_EYEARRANGE   /* Year number out of bounds         */
#define IFX_GL_EERAOFFRANGE GL_EERAOFFRANGE /* Era Offset out of bounds          */
#define IFX_GL_BADFRAC      GL_BADFRAC      /* Fraction could not be scanned     */
#define IFX_GL_BADSECOND    GL_BADSECOND    /* Second could not be scanned       */
#define IFX_GL_BADMINUTE    GL_BADMINUTE    /* Minute could not be scanned       */
#define IFX_GL_BADHOUR      GL_BADHOUR      /* Hour could not be scanned         */
#define IFX_GL_BADDAY       GL_BADDAY       /* Month Day could not be scanned    */
#define IFX_GL_BADWKDAY     GL_BADWKDAY     /* Week Day could not be scanned     */
#define IFX_GL_BADYDAY      GL_BADYDAY      /* Year Day could not be scanned     */
#define IFX_GL_BADMONTH     GL_BADMONTH     /* Month could not be scanned        */
#define IFX_GL_BADYEAR      GL_BADYEAR      /* Year could not be scanned         */
#define IFX_GL_BADERANAME   GL_BADERANAME   /* Invalid Era name                  */
#define IFX_GL_BADERAOFFSET GL_BADERAOFFSET /* Invalid Era offset                */
#define IFX_GL_BADFMTMOD    GL_BADFMTMOD    /* Invalid Format modifer            */
#define IFX_GL_BADFMTWP     GL_BADFMTWP     /* Invalid width/precision           */
#define IFX_GL_BADINPUT     GL_BADINPUT     /* Input string doesn't match format */
#define IFX_GL_NOPOINT      GL_NOPOINT      /* Missing decimal point in input    */
#define IFX_GL_BADMONTHSTR  GL_BADMONTHSTR  /* Month string could not be scanned */
#define IFX_GL_BADFMTMOD    GL_BADFMTMOD    /* Invalid Format modifer            */
#define IFX_GL_BADFMTWP     GL_BADFMTWP     /* Invalid width/precision           */
#define IFX_GL_BADINPUT     GL_BADINPUT     /* Input string doesn't match format */
#define IFX_GL_NOPOINT      GL_NOPOINT      /* Missing decimal point in input    */
#define IFX_GL_BADMONTHSTR  GL_BADMONTHSTR  /* Month string could not be scanned */
#define IFX_GL_BADERASPEC   GL_BADERASPEC   /* Couldn't load era from locale     */
#define IFX_GL_BADCALENDAR  GL_BADCALENDAR  /* Unsupported calendar in LC_TIME   */
#define IFX_GL_BADOBJVER    GL_BADOBJVER    /* Wrong lc, cm or cv object version */
#define IFX_GL_BADALTDATE   GL_BADALTDATE   /* Could not convert %Z information  */
#define IFX_GL_NOSYMMAP     GL_NOSYMMAP     /* character/symbol not in charmap   */
#define IFX_GL_BADSYM       GL_BADSYM       /* invalid symbolic character name   */
#define IFX_GL_ELOCLOAD     GL_ELOCLOAD     /* Could not load locale             */
#define IFX_GL_TERMMISMAT   GL_TERMMISMAT   /* str termination params mis-match  */
#define IFX_GL_NOCTYPE      GL_NOCTYPE      /* GL_CTYPE is not loaded */
#define IFX_GL_LOCMISMAT    GL_LOCMISMAT    /* loaded codesets are not same */

/* Misc. macros */

/* The macro to apply to the return value of either gl_tomupper or gl_tomlower
 * which extracts the number of bytes read from srcmb.
 */
#define IFX_GL_CASE_CONV_SRC_BYTES(x) \
	(((unsigned short) (x)) >> 8)

/* The macro to apply to the return value of either gl_tomupper or gl_tomlower
 * which extracts the number of bytes written to dstmb.
 */
#define IFX_GL_CASE_CONV_DST_BYTES(x) \
	(((unsigned short) (x)) & ((unsigned short) 0xff))

/*
 * Additional macros
 */
#define IFX_GL_NULL   (-1)
#define IFX_GL_NO_LIMIT   IFX_GL_MB_MAX
#define IFX_GL_IS_CODESET_ORDER GL_IS_CODESET_ORDER(gl_locale)
#define IFX_GL_IS_SINGLE_BYTE GL_IS_SINGLE_BYTE(gl_locale)
#define IFX_GL_MB_MAX GL_MB_MAX
#define IFX_GL_PROC_CS ((char *)gl_nl_langinfo(gl_locale, GL_CODESET))

/*
 * Prototypes for internal implementations
 */

/* Character Classification functions */

GL_PROTO(int GL_EXPORT, _ifx_gl_im_ismctype, (gl_lc_t lc,
					      gl_mchar_t * mbs1,
					      int bytelen1,
					      gl_ctype_t ctype));

/* Character Case Conversion */


GL_PROTO(unsigned short GL_EXPORT, _ifx_gl_im_tomupper, (gl_lc_t loc,
						      gl_e_mcharptr_t dst,
						      gl_e_mcharptr_t src,
						      int bytelen));

GL_PROTO(unsigned short GL_EXPORT, _ifx_gl_im_tomlower, (gl_lc_t loc,
						      gl_e_mcharptr_t dst,
						      gl_e_mcharptr_t src,
						      int bytelen));

#define ifx_gl_case_conv_outbuflen(x) gl_case_conv_outbuflen((gl_locale), (x))

/* Character/String Comparison */

GL_PROTO(int GL_EXPORT, _ifx_gl_wcscoll, (gl_lc_t lc,
				       gl_wchar_t * wcs1,
				       int charlen1,
				       gl_wchar_t * wcs2,
				       int charlen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_full_wcscoll, (gl_lc_t l,
					gl_e_wcharptr_t wcs1,
					int wclen1,
					gl_e_wcharptr_t wcs2,
					int wclen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_im_mbfscoll, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_mbfscoll_exp, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_mbfscoll_elem, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_mbfscoll_back, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_mbfscoll_exp_elem, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_thaismoncoll, (gl_lc_t loc,
					gl_e_mcharptr_t text1,
					int bytelen1,
					gl_e_mcharptr_t text2,
					int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcfscmp, (gl_e_wcharptr_t wcs1, int wclen1,
			    gl_e_wcharptr_t wcs2, int wclen2));

/* String Processing */

GL_PROTO(int GL_EXPORT, _ifx_gl_mbscat, (gl_lc_t lc,
				      gl_mchar_t * mbs1,
				      int bytelen1,
				      gl_mchar_t * mbs2,
				      int bytelen2));

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, _ifx_gl_mbschr, (gl_lc_t lc,
					       gl_mchar_t * mbs1,
					       int bytelen1,
					       gl_mchar_t * mbc,
					       int bytelenc));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbscpy, (gl_lc_t lc,
				      gl_mchar_t * mbs1,
				      gl_mchar_t * mbs2,
				      int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbscspn, (gl_lc_t lc,
				       gl_mchar_t * mbs1,
				       int bytelen1,
				       gl_mchar_t * mbs2,
				       int bytelen2));

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, _ifx_gl_mbsmbs, (gl_lc_t lc,
					       gl_mchar_t * mbs1,
					       int bytelen1,
					       gl_mchar_t * mbs2,
					       int bytelens));


GL_PROTO(int GL_EXPORT, _ifx_gl_mbsncat, (gl_lc_t lc,
				       gl_mchar_t * mbs1,
				       int bytelen1,
				       gl_mchar_t * mbs2,
				       int bytelen2,
				       int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsncpy, (gl_lc_t lc,
				       gl_mchar_t * mbs1,
				       gl_mchar_t * mbs2,
				       int bytelen2,
				       int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbscmp, (gl_lc_t lc,
				      gl_mchar_t * mbs1,
				      int bytelen1,
				      gl_mchar_t * mbs2,
				      int bytelen2 ));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsntslen, (gl_lc_t lc,
					 gl_mchar_t * mbs,
					 int bytelen));

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, _ifx_gl_mbspbrk, (gl_lc_t lc,
						gl_mchar_t * mbs1,
						int bytelen1,
						gl_mchar_t * mb,
						int bytelen2));

GL_PROTO(gl_e_mcharptr_t GL_EXPORT, _ifx_gl_mbsrchr, (gl_lc_t lc,
						gl_mchar_t * mbs1,
						int bytelen1,
						gl_mchar_t * mbc,
						int bytelenc));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsspn, (gl_lc_t lc,
				      gl_mchar_t * mbs1,
				      int bytelen1,
				      gl_mchar_t * mb2,
				      int bytelen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcscat, (gl_lc_t lc,
				      gl_wchar_t * wcs1,
				      int charlen1,
				      gl_wchar_t * wcs2,
				      int charlen2));

GL_PROTO(gl_e_wcharptr_t GL_EXPORT, _ifx_gl_wcschr, (gl_lc_t lc,
					       gl_wchar_t * wcs1,
					       int charlen1,
					       gl_wchar_t wc));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcscpy, (gl_lc_t lc,
				      gl_wchar_t * wcs1,
				      gl_wchar_t * wcs2,
				      int charlen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcscspn, (gl_lc_t lc,
				       gl_wchar_t * wcs1,
				       int charlen1,
				       gl_wchar_t * wcs2,
				       int charlen2));

GL_PROTO(int GL_EXPORT, _ifx_gl_full_mblen, (gl_lc_t lc,
					  gl_e_mcharptr_t mb,
					  int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsncat, (gl_lc_t lc,
				       gl_wchar_t * wcs1,
				       int charlen1,
				       gl_wchar_t * wcs2,
				       int charlen2,
				       int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsncpy, (gl_lc_t lc,
				       gl_wchar_t * wcs1,
				       gl_wchar_t * wcs2,
				       int charlen2,
				       int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsntslen, (gl_lc_t lc,
					 gl_wchar_t * wcs,
					 int wcslen));

GL_PROTO(gl_e_wcharptr_t GL_EXPORT, _ifx_gl_wcspbrk, (gl_lc_t lc,
					gl_wchar_t * wcs1,
					int charlen1,
					gl_wchar_t * wcs2,
					int charlen2));

GL_PROTO(gl_e_wcharptr_t GL_EXPORT, _ifx_gl_wcsrchr, (gl_lc_t lc,
				       gl_wchar_t * wcs,
				       int wcslen,
				       gl_wchar_t wc));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsspn, (gl_lc_t lc,
				      gl_wchar_t * wcs1,
				      int charlen1,
				      gl_wchar_t * wcs2,
				      int charlen2));

GL_PROTO(gl_e_wcharptr_t GL_EXPORT, _ifx_gl_wcswcs, (gl_lc_t lc,
				      gl_wchar_t * wcs1,
				      int charlen1,
				      gl_wchar_t * wcs2,
				      int charlen2));

/* Multi-byte/Wide-character Conversion */

GL_PROTO(int GL_EXPORT, _ifx_gl_full_mbtowc , (gl_lc_t lc,
					gl_wchar_t * wcp,
					gl_mchar_t * mb,
					int maxbytes));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_wcstombs, (gl_lc_t loc,
					   gl_e_mcharptr_t mbs,
					   gl_e_wcharptr_t wcs,
					   int wclen,
					   int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_full_wcstombs, (gl_lc_t loc,
					     gl_e_mcharptr_t mbs,
					     gl_e_wcharptr_t wcs,
					     int wclen,
					     int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_im_mbfstowcfs, (gl_lc_t loc,
					gl_e_wcharptr_t wcs,
					gl_e_mcharptr_t mbs,
					int bytelen,
					int n));

GL_PROTO(int GL_EXPORT, _ifx_gl_is_mbfstowcfs, (gl_lc_t loc,
					gl_e_wcharptr_t wcs,
					gl_e_mcharptr_t mbs,
					int bytelen,
					int n));

/* Multi-byte Memory Allocation */

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsntsbytes, (gl_lc_t lc,
					   gl_mchar_t *mbs,
					   int mbsbytes));

/* Multi-byte String Traversal and Indexing */


GL_PROTO(gl_e_mcharptr_t GL_EXPORT, _ifx_gl_full_mbsnext, (gl_lc_t lc,
						   	gl_mchar_t *mb,
						   	int mbsbytes));

GL_PROTO(int GL_EXPORT, _ifx_gl_im_mbfslen, (gl_lc_t loc,
					  gl_e_mcharptr_t mbs,
					  int bytelen));

/* Formatting */

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsprintf, (gl_lc_t lc,
					 gl_mchar_t *mbs,
					 int maxbytes,
					 gl_mchar_t *format,
					 ...));

GL_PROTO(int GL_EXPORT, _ifx_gl_mbsscanf, (gl_lc_t lc,
					gl_mchar_t *mbs,
					int maxbytes,
					gl_mchar_t *format,
					...));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsprintf, (gl_lc_t lc,
					 gl_wchar_t *wcs,
					 int maxchars,
					 gl_wchar_t *format,
					 ...));

GL_PROTO(int GL_EXPORT, _ifx_gl_wcsscanf, (gl_lc_t lc,
					gl_wchar_t *wcs,
					int maxchars,
					gl_wchar_t *format,
					...));
/* Input and Output functions */

GL_PROTO(int GL_EXPORT, _ifx_gl_putmb, (gl_lc_t lc,
				     gl_mchar_t *buf,
				     int buflen,
				     GL_PTR_PROTO(int, fp,
					      (gl_mchar_t mb, void *v)),
				     void *v,
				     int *bytes_written));

#define gl_uncache_registry() gl_free_registry_cache()

/* MAP implementation names to user callable names */

#define ifx_gl_getmb(a,b,c,d)    gl_getmb((gl_locale), (a),(b),(c),(d))
#define ifx_gl_putmb(a,b,c,d,e)  _ifx_gl_putmb((gl_locale), (a),(b),(c),(d),(e))

#define _ifx_gl_ismctype(lc, mb, mb_byte_limit, class)			      \
    ( GL_LC_SB_CTYPE_TABLE(lc) ?					      \
        (mb_byte_limit) > 0 ?						      \
	    (int) GL_LC_SB_CTYPE_TABLE(lc)[*((gl_mchar_t *)(mb))] & (class) : \
	    (gl_set_errno((lc), IFX_GL_EINVAL), 0) :			      \
	_ifx_gl_im_ismctype((lc), (mb), (mb_byte_limit), (class))		      \
    )

#define ifx_gl_ismalnum(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_ALNUM)
#define ifx_gl_ismalpha(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_ALPHA)
#define ifx_gl_ismblank(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_BLANK)
#define ifx_gl_ismcntrl(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_CNTRL)
#define ifx_gl_ismdigit(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_DIGIT)
#define ifx_gl_ismgraph(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_GRAPH)
#define ifx_gl_ismlower(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_LOWER)
#define ifx_gl_ismprint(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_PRINT)
#define ifx_gl_ismpunct(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_PUNCT)
#define ifx_gl_ismspace(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_SPACE)
#define ifx_gl_ismupper(a,b)  _ifx_gl_ismctype((gl_locale), (a),(b),GL_UPPER)
#define ifx_gl_ismxdigit(a,b) _ifx_gl_ismctype((gl_locale), (a),(b),GL_XDIGIT)

#define ifx_gl_iswalnum(a)    gl_iswctype((gl_locale), (a),GL_ALNUM)
#define ifx_gl_iswalpha(a)    gl_iswctype((gl_locale), (a),GL_ALPHA)
#define ifx_gl_iswblank(a)    gl_iswctype((gl_locale), (a),GL_BLANK)
#define ifx_gl_iswcntrl(a)    gl_iswctype((gl_locale), (a),GL_CNTRL)
#define ifx_gl_iswdigit(a)    gl_iswctype((gl_locale), (a),GL_DIGIT)
#define ifx_gl_iswgraph(a)    gl_iswctype((gl_locale), (a),GL_GRAPH)
#define ifx_gl_iswlower(a)    gl_iswctype((gl_locale), (a),GL_LOWER)
#define ifx_gl_iswprint(a)    gl_iswctype((gl_locale), (a),GL_PRINT)
#define ifx_gl_iswpunct(a)    gl_iswctype((gl_locale), (a),GL_PUNCT)
#define ifx_gl_iswspace(a)    gl_iswctype((gl_locale), (a),GL_SPACE)
#define ifx_gl_iswupper(a)    gl_iswctype((gl_locale), (a),GL_UPPER)
#define ifx_gl_iswxdigit(a)   gl_iswctype((gl_locale), (a),GL_XDIGIT)

#define ifx_gl_tomupper(dst_mb, src_mb, src_mb_byte_limit)		       \
    ( GL_LC_SB_TOUPPER_TABLE(gl_locale) ?				       \
        (src_mb_byte_limit) > 0 ?					       \
	    ((*((gl_mchar_t *) (dst_mb))) = 			               \
	        GL_LC_SB_TOUPPER_TABLE((gl_locale))[*((gl_mchar_t*)(src_mb))], \
							GL_SBTOMRETVAL) :      \
	    (gl_set_errno((gl_locale), IFX_GL_EINVAL), 0) :		       \
	_ifx_gl_im_tomupper(((gl_locale)), (dst_mb), (src_mb),		       \
							(src_mb_byte_limit))   \
    )

#define ifx_gl_tomlower(dst_mb, src_mb, src_mb_byte_limit)		       \
    ( GL_LC_SB_TOLOWER_TABLE(gl_locale) ?				       \
        (src_mb_byte_limit) > 0 ?					       \
	    ((*((gl_mchar_t *) (dst_mb))) = 			               \
	        GL_LC_SB_TOLOWER_TABLE((gl_locale))[*((gl_mchar_t*)(src_mb))], \
							GL_SBTOMRETVAL) :      \
	    (gl_set_errno((gl_locale), IFX_GL_EINVAL), 0) :		       \
	_ifx_gl_im_tomlower(((gl_locale)), (dst_mb), (src_mb),		       \
							(src_mb_byte_limit))   \
    )

#define ifx_gl_towlower(a)         gl_towlower((gl_locale), (a))
#define ifx_gl_towupper(a)         gl_towupper((gl_locale), (a))

#define ifx_gl_mbscoll(a,b,c,d)    _ifx_gl_mbscoll((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcscoll(a,b,c,d)    _ifx_gl_wcscoll((gl_locale), (a),(b),(c),(d))

#define ifx_gl_mbscat(a,b,c,d)     _ifx_gl_mbscat((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbschr(a,b,c,d)     _ifx_gl_mbschr((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbscpy(a,b,c)       _ifx_gl_mbscpy((gl_locale), (a),(b),(c))
#define ifx_gl_mbscspn(a,b,c,d)    _ifx_gl_mbscspn((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbslen(a,b)         _ifx_gl_mbslen((gl_locale), (a),(b))
#define ifx_gl_mbsmbs(a,b,c,d)     _ifx_gl_mbsmbs((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbsncat(a,b,c,d,e)  _ifx_gl_mbsncat((gl_locale), (a),(b),(c),(d),(e))
#define ifx_gl_mbsncpy(a,b,c,d)    _ifx_gl_mbsncpy((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbsntslen(a,b)      _ifx_gl_mbsntslen((gl_locale), (a),(b))
#define ifx_gl_mbspbrk(a,b,c,d)    _ifx_gl_mbspbrk((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbsrchr(a,b,c,d)    _ifx_gl_mbsrchr((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbsspn(a,b,c,d)     _ifx_gl_mbsspn((gl_locale), (a),(b),(c),(d))

#define ifx_gl_wcscat(a,b,c,d)     _ifx_gl_wcscat((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcschr(a,b,c)       _ifx_gl_wcschr((gl_locale), (a),(b),(c))
#define ifx_gl_wcscpy(a,b,c)       _ifx_gl_wcscpy((gl_locale), (a),(b),(c))
#define ifx_gl_wcscspn(a,b,c,d)    _ifx_gl_wcscspn((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcslen(a)           gl_wcslen((a))
#define ifx_gl_wcsncat(a,b,c,d,e)  _ifx_gl_wcsncat((gl_locale), (a),(b),(c),(d),(e))
#define ifx_gl_wcsncpy(a,b,c,d)    _ifx_gl_wcsncpy((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcsntslen(a,b)      _ifx_gl_wcsntslen((gl_locale), (a),(b))
#define ifx_gl_wcspbrk(a,b,c,d)    _ifx_gl_wcspbrk((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcsrchr(a,b,c)      _ifx_gl_wcsrchr((gl_locale), (a),(b),(c))
#define ifx_gl_wcsspn(a,b,c,d)     _ifx_gl_wcsspn((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wcswcs(a,b,c,d)     _ifx_gl_wcswcs((gl_locale), (a),(b),(c),(d))


#define ifx_gl_mbstowcs(a,b,c,d)  _ifx_gl_mbstowcs((gl_locale), (a),(b),(c),(d))
#define ifx_gl_mbtowc(a,b,c)      _ifx_gl_mbtowc((gl_locale), (a),(b),(c))
#define ifx_gl_wcstombs(a,b,c,d)  _ifx_gl_wcstombs((gl_locale), (a),(b),(c),(d))
#define ifx_gl_wctomb(a,b)        gl_wctomb((gl_locale),(a),(b))

#define ifx_gl_mb_loc_max()       gl_mb_loc_max((gl_locale))
#define ifx_gl_mbsntsbytes(a,b)   _ifx_gl_mbsntsbytes((gl_locale),(a),(b))

#define ifx_gl_mblen(a,b)         _ifx_gl_mblen((gl_locale), (a),(b))
#define ifx_gl_mbsnext(a,b)       _ifx_gl_mbsnext((gl_locale), (a),(b))
#define ifx_gl_mbsprev(a,b)       gl_mbsprev((gl_locale), (a),(b))

#define ifx_gl_lc_errno()         (*_gl_ext_errno((gl_gen_expptr_t) (gl_locale)))

/* MAP implementation names to appropriate real functions */

#if GL_WCSIZE == 1

#define _ifx_gl_wcstombs(loc, mb, wc, wclen, n) 			\
	    _ifx_gl_is_wcstombs((loc), (mb), (wc), (wclen), (n))

#define _ifx_gl_mblen(loc, mb, n)					\
	    ((mb) != NULL 						\
	     ? (((n) >= 1)						\
		? 1							\
		: (gl_set_errno((loc), GL_EINVAL), -1)			\
	       )							\
	     : 0							\
	    )

#define _ifx_gl_mbslen(loc, mbs, bytelen)				\
	    ((bytelen) == IFX_GL_NULL ?					\
			((int)GL_STRLEN((gl_e_charptr_t)(mbs))) : 	\
			(bytelen))

#define _ifx_gl_mbsnext(lc, mb, mb_byte_limit)				\
	    ((mb_byte_limit) > 0					\
	     ? (((gl_mchar_t *) (mb)) + 1)     			        \
	     : (gl_set_errno((lc), IFX_GL_EINVAL), (gl_mchar_t *) NULL) \
	    )

#else /* GL_WCSIZE */

#define _ifx_gl_wcstombs(loc, mb, wc, wclen, n) 			\
	    (GL_IS_SINGLE_BYTE(loc) 					\
	     ? _ifx_gl_is_wcstombs((loc), (mb), (wc), (wclen), (n))	\
	     : _ifx_gl_full_wcstombs((loc), (mb), (wc), (wclen), (n))	\
	    )

#define _ifx_gl_mblen(loc, mb, n)					\
	    (GL_IS_SINGLE_BYTE(loc)					\
	     ? ((mb) != NULL						\
		? (((n) >= 1)						\
		   ? 1							\
		   : (gl_set_errno((loc), GL_EINVAL), -1)		\
		  )							\
		: 0							\
	       )							\
	     : _ifx_gl_full_mblen((loc), (mb), (n))			\
	    )

#define _ifx_gl_mbslen(loc, mbs, bytelen)				\
	     ( GL_IS_SINGLE_BYTE(loc) ?					\
	           ((bytelen) == IFX_GL_NULL ?				\
			(gl_mbsbytes((loc), (mbs)) - gl_mb_loc_min(loc)) : \
			(bytelen))					\
	           : (_ifx_gl_im_mbfslen((loc),(mbs),(bytelen)))	\
	     )

#define _ifx_gl_mbsnext(lc, mb, mb_byte_limit)				\
	 (GL_IS_SINGLE_BYTE(lc)						\
	  ? (mb_byte_limit) > 0						\
	     ? (((gl_mchar_t *) (mb)) + 1)     			        \
	     : (gl_set_errno((lc), IFX_GL_EINVAL), (gl_mchar_t *) NULL) \
	  : _ifx_gl_full_mbsnext((lc), (mb), (mb_byte_limit))	        \
	 )


#endif /* GL_WCSIZE */

#define _ifx_gl_mbscoll(lc, mbs1, bytelen1, mbs2, bytelen2)		\
	    ( GL_IS_CODESET_ORDER(lc) ?					\
		_ifx_gl_mbscmp((lc), (mbs1), (bytelen1),		\
					(mbs2), (bytelen2)) 		\
		: ((((gl_lc_expptr_t)(lc))->mbfscoll)((lc),		\
				(mbs1), (bytelen1),			\
				(mbs2), (bytelen2)))			\
	    )

#define _ifx_gl_wcscoll(lc, wcs1, wclen1, wcs2, wclen2) 		\
	    ( GL_IS_CODESET_ORDER(lc) ? 				\
		_ifx_gl_wcfscmp((wcs1), (wclen1),	 		\
					(wcs2), (wclen2)) :		\
		_ifx_gl_full_wcscoll((lc), (wcs1), (wclen1),		\
					(wcs2), (wclen2))		\
	    )
#define _ifx_gl_mbstowcs(loc, wcs, mbs, bytelen, n)			\
	    ((((gl_lc_expptr_t)(loc))->mbfstowcfs)				\
			((loc), (wcs), (mbs), (bytelen), (n)))

#define _ifx_gl_mbtowc(loc,a,b,c)					\
	    _ifx_gl_full_mbtowc((loc),(a),(b),(c))


GL_PROTO(gl_e_voidptr_t GL_EXPORT, gls_assign_global_struct, (GL_VOIDARGS));
typedef struct gl_passthrough{
    void* pass;
}gl_passthrough_t;

/***************************************************************************
 *
 * End of user level definitions
 *
 ***************************************************************************
 */

#ifdef __cplusplus
}
#endif

#endif /* GLS_INCLUDED */
