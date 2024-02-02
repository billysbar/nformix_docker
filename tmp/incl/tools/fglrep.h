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
 *  Title:      fglrep.h
 *  Sccsid:     @(#)fglrep.h /main/development/3 05/15/95 20:11:38 
 *  Description:
 *              structs for 4gl reports
 *
 ***************************************************************************
 */

#ifndef FGLREP_H
#define FGLREP_H

struct aggdesc
{
    int2       aggtype;        /* see below */
    int2       aggsort;
    int4        aggcount;
};
typedef struct aggdesc aggdesc_t;

/*
 * aggdesc_t.aggtype values
 */
#define AGGCOUNT        1
#define AGGPERC         2
#define AGGTOTAL        3
#define AGGAVG          4
#define AGGMAX          5
#define AGGMIN          6

struct sortdesc
{
    int1       *s_dummy;
    int2       s_paramn;
    int2       s_order;
    int2       s_type;
    int2       s_len;
    int2       s_substrt;
    int2       s_aftgroup;
    int2       s_befgroup;
};
typedef struct sortdesc sortdesc_t;

#define SORTINC         8       /* sort table growth increment */

struct wwdesc
{
    FILE       *w_fp;           /* input stream */
    int1       *w_data;         /* start of input data when not stream */
    int1       *w_datap;        /* next int1 to get */
    int1       *w_buffer;       /* output buffer */
    struct value *w_stkptr;     /* location in 4gl stack */
    int2       w_type;         /* SQLCHAR, SQLVCHAR, SQLTEXT */
    int2       w_datasize;     /* size in bytes of data */
    int2       w_lmargin;      /* width of left margin */
    int2       w_rmargin;      /* last col to print in */
#ifdef ASIAN
    uint4 w_pbchar;             /* 0 or pushed-back character */
#else
    int2 w_pbchar;             /* 0 or pushed-back character */
#endif /* ASIAN */
    int2       w_bufsize;      /* size of w_buffer */
    int2       w_wordlen;      /* length of data in w_buffer */
    int2       w_stkcntr;      /* stack counter */
    int2       w_state;        /* see below */
    int2       w_status;       /* return value for 4gl status */
};
typedef struct wwdesc wwdesc_t;

/*
 * wwdesc_t.w_state values
 */
#define PR_INIT         000     /* initial state */
#define PR_GET          001     /* get next word */
#define PR_PRINT        002     /* print word */
#define PR_NEWLINE      004     /* do newline code */
#define PR_HEADER       010     /* do page header code */
#define PR_DONE         020     /* finished printing variable */
#define PR_CNTRL        030     /* for the ^L problem */

struct repdesc
{
    int4        rrecordnum;
    int2       pagenumber;
    int2       ln;
    int2       tmargin;
    int2       rmargin;
    int2       lmargin;
    int2       bmargin;
    int2       phlines;
    int2       fphlines;
    int2       colcount;
    int2       tot;
    int2       oktoinc;
    FILE       *outfp;
    int2       oftype;         /* 0 = stdout; 1 = file; 2 = pipe */
    int2       plength;
    int2       ptlines;
    struct aggdesc *_paggdesc;
    struct value *_paggvals;
    struct sortdesc *p_sortdesc;
    int1       *phbuff;         /* page header buffer */
    unsigned    phsz;           /* page header buffer size */
    unsigned    phix;           /* current location in page header buffer */
    int2       gotoindx;
    int2       gotostk[6];
    int2       needlmarg;
    int2       hdrstate;       /* pghdr processing state, see below */
    int1        topofpg;        /* top of form character */
    int2       ptexists;       /* user defined page trailer exists */
};
typedef struct repdesc repdesc_t;

/*
 * repdesc_t.hdrstate values
 */
#define P_NOPGHDR       0       /* no pghdr being processed */
#define P_EPHEVAL       1       /* early pghdr eval needed */
#define P_LPHEVAL       2       /* late pghdr eval needed */
#define P_PHFILL        3       /* pghdr being eval'ed and buffered */
#define P_BUFFULL       4       /* pghdr eval'ed and buffed, print pending */

/*
 * Report destinations
 */
#define P_DEFAULT       0       /* Default destination (SCREEN) */
#define P_PIPE          1       /* Report to PIPE -- unspecified mode */
#define P_PRINTER       2       /* Report to PRINTER */
#define P_SCREEN        3       /* Report to SCREEN */
#define P_FILE          4       /* Report to FILE */
#define P_PIPE_LINE     5       /* Report to PIPE IN LINE MODE */
#define P_PIPE_FORM     6       /* Report to PIPE IN FORM MODE */
#define P_VAR 		7	/* Report to int1 variable (can be any of
				   above. To be determined at run time.
				   For 7.30 Dynamic start report. */
/*
 * Define's for Dynamic Report Configuration for 7.30 release.
 */

typedef struct rp_call
{
    int2	rep_call_flg; /* See below for definition */	
    int2       tmargin;
    int2       rmargin;
    int2       lmargin;
    int2       bmargin;
    int2       plength;
    int1        topofpg;
}rep_call_t;

#define P_TMARGIN	000001 /* tmargin specified in START REPORT */
#define P_RMARGIN       000002 /* rmargin specified in START REPORT */
#define P_LMARGIN	000004 /* lmargin specified in START REPORT */
#define P_BMARGIN	000010 /* bmargin specified in START REPORT */
#define P_PLENGTH	000020 /* plength specified in START REPORT */
#define P_TOPOFPG	000040 /* topofpg specified in START REPORT */

/*
 * End Define's for Dynamic Report Configuration for 7.30 release.
 */

#endif /* FGLREP_H */
