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
 *  Title:      fglmnu.h
 *  Sccsid:     @(#)fglmnu.h /main/development/1 03/08/95 15:15:17 
 *  Description:
 *              I4GL Menus -- structures visible in generated C code
 *
 ************************************************************************
 */

#ifndef FGLMNU_H
#define FGLMNU_H

#ifndef ISQL_MENUS

struct command
{
    int2       c_code;         /* response code */
#ifdef ASIAN
    int4        c_htext ;	/* help screen number */
#else
    int2       c_htext;        /* help screen number */
#endif
    int1       *c_word;         /* one word prompt */
    int1       *c_help;         /* help text for the command */
    int2       c_flags;        /* flags for command */
    int2       c_wlen;         /* length of the command string */
};

struct shallowmenu
{
    int1       *sm_context;     /* first word to display */
    struct command *sm_curcomm; /* pointer to current command */
    struct command *sm_first;   /* ptr to 1st elt in array of commands */
    struct command *sm_last;    /* the command before -1 code */
#ifdef ASIAN
    int4  sm_msg;               /* help text message number */
#else
    int2       sm_msg;         /* msg num in ISQL/I4GL/R4GL/UPSCOL menus */
#endif /* ASIAN */
    int2       sm_conlen;      /* length of *sm_context string */
};

#endif /* ISQL_MENUS */

#endif /* FGLMNU_H */
