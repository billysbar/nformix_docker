/***************************************************************************
 *
 *                         INFORMIX SOFTWARE, INC.
 *
 *                            PROPRIETARY DATA
 *
 *      THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
 *      INFORMIX SOFTWARE, INC.  THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
 *      CONFIDENCE.  INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
 *      DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
 *      SIGNED BY AN OFFICER OF INFORMIX SOFTWARE, INC.
 *
 *      THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
 *      SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
 *      UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
 *
 *
 *  Title:      sqlfm.h
 *  Sccsid:     @(#)sqlfm.h /main/development/4 08/29/95 17:32:39 
 *  Description:
 *              declarations for menu and forms statements in Informix-4GL
 *
 ***************************************************************************
 */

#ifndef ASIAN
#define ASIAN
#endif /* ASIAN */

#ifndef MAXIDLENGTH
#define MAXIDLENGTH     256  /* change this value equal to what is present in rdsmac.h */
#endif
#include "ifxtypes.h"
#ifndef SQLFM_H
#define SQLFM_H

struct fieldcb
{
    int2       row;
    int2       col;
    int2       up;
    int2       down;
    int2       left;
    int2       right;
    int2       ifld;
    int2       ibind;
    int2       irecix;
};

#include "fglmnu.h"

typedef struct command _EFCOMMAND;
typedef struct shallowmenu _EFMENU;

struct _EDEDIT
{
    int1       *_EFeditor;      /* editor name in USING clause */
    mint         _EFkey;         /* key in EDIT KEY clause */
    mint         _EFrow;         /* row in AT clause */
    mint         _EFcol;         /* column in AT clause */
    mint         _EFnrows;       /* number of rows in AT clause */
    mint         _EFncols;       /* number of columns in AT clause */
    mint         _EFattr;        /* edit attribute */
};                              /* used by INPUT, INPUT ARRAY, CONSTRUCT */
typedef struct _EDEDIT _EFEDIT;

struct _EFFIELD
{
    int1       *_EFfldname;     /* field name */
    int2       _EFfldsub;      /* user's screen array subscript */
};
typedef struct _EFFIELD _EFFIELD;

struct _EFBAF
{                               /* BEFORE/AFTER field sublist */
    int1       *_EFbaname;      /* name of field */
    int2       _EFbefore;      /* BEFORE action number */
    int2       _EFafter;       /* AFTER action number */
};
typedef struct _EFBAF _EFBAF;

struct icb_str
{                               /* INPUT control block */
    _EFBAF     *_EFbatab;       /* BEFORE/AFTER table */
    mint        *_EFrowbat;      /* row BEFORE/AFTER table */
    mint        *_EFkeys;        /* ON KEY table */
    int1       *_EFnext;        /* NEXT FIELD name */
    int2       _EFaction;      /* action selector */
    int4        _EFflags;       /* see below for values */
#ifdef ASIAN
    int4    _EFhelp;            /* help number */
#else
    int2   _EFhelp;            /* help number */
#endif /* ASIAN */
    int2       _EFibind;       /* var number in bindlist */
    int2       _EFifld;        /* fld number in fldlst */
    int2       _EFrecix;       /* fld's index in rec's rixparts */
    int2       _EFmodf;        /* 1 = field has been modified */
    int2       _EFentcnt;      /* 1 = verify pass */
    int2       _EFx;           /* location of cursor */
    int2       _EFy;           /* location of cursor */
    mint         _EFdlen;        /* data size in _EFbug */
    int1       *_EFbuf;         /* data buffer, used in _efget */
    int1       *_EFverbuf;      /* extra buffer of verification */
    int1       *_EFfmtstr;      /* format string, used in _efget */

    mint   _EFretkey;/* returned key in ibm_efm_inputCVarsInBindList */
    mint   _EFfldix; /* index of current field, ibm_efm_inputCVarsInBindList */
    mint   _EFstate; /* state machine index, ibm_efm_inputCVarsInBindList */

    mint         _EFarkey;       /* returned key in _efarinkey */
    mint         _EFarstate;     /* state index, _efarinput */
    mint         _EFrcnt;        /* # of rows in screen array */

    mint         _EFcrow;        /* current row in C array */
    mint         _EFfmrow;       /* current row in screen array */
    mint         _EFcrcnt;       /* # of rows in C array with data */
    mint         _EFmaxcount;    /* for MAXCOUNT attribute */

    mint         _EFsibind;
    mint         _EFsifld;
    mint         _EFsrecix;      /* field state info saved */

    int1        _EFcurrec[MAXIDLENGTH + 1];  /* current record of the icb */
    int1        _EFcurfld[MAXIDLENGTH + 1];  /* current field of the icb */

    struct _efwindow *_EFwin;   /* window associated with icb */
    int4        _EFiattr;       /* attribute value for input */
    int4        _EFoattr;       /* attribute value for output */
    mint         _EFextattr ;    /* Extended attr value for 7.3x release */
    mint         _EFlnnum;       /* line num specified in PROMPT */
    mint         _EFcolnum;      /* column num specified in PROMPT */
    mint         _EFnxtrow;      /* row num specified in next row */
    mint         _EFnxtline;     /* line num specified in next row */
    int2       _EFrowstat;     /* using ICB_NEXT etc. */
    int2       _EFfldstat;     /* using ICB_NEXT etc. */
    mint        *_EFrowcount;    /* addr of var in ROW COUNT clause */
    _EFEDIT    *_EFedinfo;      /* Information about the editor */
    mint        *_EFcurfrm;      /* current form (actually a (_FORM *)) */
    mint         biggest_field;  /* largest field in construct statement */
    mint         totalspace;     /* total space required by construct */
    int1       *queryspace;     /* buffer for construct fields */
    struct icb_str *parent_icb; /* icb of fn which called construct */
    _EFFIELD   *cfldlist;       /* fields used in the construct */
    mint        *_EFlastfrm;     /* last form (actually a (_FORM *)) */
    struct fieldcb *_EFfcb;     /* field control block */
    int1       *wwpbp;          /* word-wrap previous buffer pointer */
    struct dispdesc *wwpddp;    /* word-wrap previous display descr ptr */
    int1       *wwcbp;          /* word-wrap current buffer pointer */
    struct dispdesc *wwcddp;    /* word-wrap current display descr ptr */
    int2       _EFrstrbuff;    /* will we restore buffer contents?  */
    int1       *wwcfbp;         /* word-wrap current field-segment buf ptr */
};
typedef struct icb_str _EFICB;

#define ICB_INIT        000001  /* first time initialization */
#define ICB_ARRAY       000002  /* INPUT ARRAY */
#define ICB_BEFORE      000004  /* before break in progress */
#define ICB_AFTER       000010  /* after break */
#define ICB_ONKEY       000020  /* on key break */
#define ICB_ROWBREAK    000040  /* row break */
#define ICB_NEWROW      000100  /* first time in new row */
#define ICB_ROWTOUCHED  000200  /* row has been touched */
#define ICB_FORCHAR     000400  /* prompt for int1 */
#define ICB_INSERT      001000  /* row is being inserted */
#define ICB_INSMODE     002000  /* insert mode */
#define ICB_FCHAR       004000  /* 1 = no data int1 yet */
#define ICB_NODEFAULT   010000  /* INPUT WITHOUT DEFAULTS */
#define ICB_VBREAK      020000  /* an output var has V_BREAK on */
#define ICB_INTRPT      040000  /* interrupt (Fgldb) */
#define ICB_CONSTRUCT  0100000  /* input for construct clause */
#define ICB_EXTINPUT   0200000  /* extended input on comment line */
#define ICB_KEEPINSM   0400000  /* keep insert mode flag */
#define ICB_NFNEXT    01000000  /* Construct: Next field next */
#define ICB_NFPREV    02000000  /* Construct: Next field previous */
#define ICB_BEFDONE   04000000  /* Before construct is complete */

#define ICB_INEXT       0
#define ICB_IPREVIOUS   1
#define ICB_IREPEAT     2
#define ICB_IDELETE     3
#define ICB_IINSERT     4
#define ICB_IABSOLUTE   5

struct _efwindow
{
    struct _efwindow *upper;    /* upper window */
    struct _efwindow *lower;    /* lower window */
    mint        *win;            /* curses window */
    mint        *swin;           /* curses subwindow */
    int1       *formname;       /* name of form file */
    mint        *winfrm;         /* form of window */
    int2       rows;           /* size of window - rows */
    int2       columns;        /* size of window - columns */
    int2       promptline;     /* prompt line position */
    int2       msgline;        /* message line position */
    int2       formline;       /* form position */
    int2       cmtline;        /* comment line position */
    mint         menuline;       /* menu line position */
    int2       flag;           /* window status */
#ifdef ASIAN
    int4    forecolor;          /* foreground color */
#else
    int2       forecolor;      /* foreground color */
#endif /* ASIAN */
    uint4 ucount;       /* count of use of MENU, INPUT, DISP */
};
typedef struct _efwindow _EFwindow;

#define WINPMODE        001     /* window in input mode */
#define WINMENU         002     /* window with menu */
#define WINDISP         004     /* window in display array */
#define WINFRM          010     /* win. opened with form */

#define WINMASK         007

#define WFIRST          0x0000  /* first line in window */
#define WLAST           0x4000  /* relative distance from last line of window */

struct _efarcb
{
    _EFwindow  *cbwindow;       /* current window */
    mint         crow;           /* saved current row in C array */
    mint         fmrow;          /* saved current row in screen array */
    mint         crcnt;          /* # of rows in C array with data */
};
typedef struct _efarcb _EFARCB;

struct _efflgtab
{
    _EFICB     *active_icb;     /* Pointer to the active icb */
    int2      *_EFfldflgs;     /* Status of field flags before input */
    struct _efflgtab *next;
};
typedef struct _efflgtab _EFFLGTAB;

/*
 * Mode parameters for RUN statements
 */
#define FGL_RUNWAIT     0
#define FGL_RUNRETURN   1
#define FGL_RUNNOWAIT   2
#define FGL_RUNFORMMODE 4
#define FGL_RUNLINEMODE 8
#define FGL_RUNMODE     (FGL_RUNFORMMODE|FGL_RUNLINEMODE)

/* These includes must come after the definitions above */
#ifndef NO_RECOMPILE
#include "fglsys.h"
#endif

#include "fgllib.h"

/* Bug # 111302 */
#define FGL_SETLINENO(x)  fgl_lineno = (x)

#endif /* SQLFM_H */
