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
 *  Title:      fgllib.h
 *  Sccsid:     @(#)fgllib.h /main/development/2 04/06/95 18:21:52 
 *  Description:
 *              Declarations of 4GL library functions
 *
 ***************************************************************************
 */

#ifndef FGLLIB_H
#define FGLLIB_H

#if __STDC__ == 1
#define USE_PROTOTYPES
#endif /* __STDC__ */

#ifdef USE_PROTOTYPES

/*
 * 4GL Library Functions
 */
extern mint  arg_val(mint nargs);
extern mint  arr_count(mint nargs);
extern mint  arr_curr(mint nargs);
extern mint  cursor_name(mint nargs);
extern mint  downshift(mint nargs);
extern mint  err_get(mint nargs);
extern mint  err_print(mint nargs);
extern mint  err_quit(mint nargs);
extern mint  errorlog(mint nargs);
extern mint  fgl_currfield(mint nargs);
extern mint  fgl_drawbox(mint nargs);
extern mint  fgl_errorlog(mint nargs);
extern mint  fgl_getenv(mint nargs);
extern mint  fgl_getfldbuf(mint nargs);
extern mint  fgl_getkey(mint nargs);
extern mint  fgl_keyval(mint nargs);
extern mint  fgl_lastkey(mint nargs);
extern mint  fgl_nextfield(mint nargs);
extern mint  fgl_putfldbuf(mint nargs);
extern mint  fgl_scr_size(mint nargs) ;
extern mint  fgl_setcurrline(mint nargs);
extern mint  fgl_startlog(mint nargs);
extern mint  field_touched(mint nargs);
extern mint  get_fldbuf(mint nargs);
extern mint  infield(mint nargs);
extern mint  length(mint nargs);
extern mint  num_args(mint nargs);
extern mint  scr_line(mint nargs);
extern mint  set_count(mint nargs);
extern mint  showhelp(mint nargs);
extern mint  startlog(mint nargs);
extern mint  upshift(mint nargs);
extern mint  fgl_isdynarr_allocated(mint nargs);
extern mint  fgl_dynarr_extentsize(mint nargs);

#ifdef MLS
extern mint  fgl_english(mint nargs);
extern mint  fgl_labeleq(mint nargs);
extern mint  fgl_labelge(mint nargs);
extern mint  fgl_labelglb(mint nargs);
extern mint  fgl_labelgt(mint nargs);
extern mint  fgl_labelle(mint nargs);
extern mint  fgl_labellt(mint nargs);
extern mint  fgl_labellub(mint nargs);
#endif /* MLS */

#else /* USE_PROTOTYPES */

/*
 * 4GL Library Functions
 */
extern mint  arg_val();
extern mint  arr_count();
extern mint  arr_curr();
extern mint  cursor_name();
extern mint  downshift();
extern mint  err_get();
extern mint  err_print();
extern mint  err_quit();
extern mint  errorlog();
extern mint  fgl_currfield();
extern mint  fgl_drawbox();
extern mint  fgl_errorlog();
extern mint  fgl_getenv();
extern mint  fgl_getfldbuf();
extern mint  fgl_getkey();
extern mint  fgl_keyval();
extern mint  fgl_lastkey();
extern mint  fgl_nextfield();
extern mint  fgl_putfldbuf();
extern mint  fgl_scr_size() ;
extern mint  fgl_setcurrline();
extern mint  fgl_startlog();
extern mint  field_touched();
extern mint  get_fldbuf();
extern mint  infield();
extern mint  length();
extern mint  num_args();
extern mint  scr_line();
extern mint  set_count();
extern mint  showhelp();
extern mint  startlog();
extern mint  upshift();
extern mint  fgl_isdynarr_allocated();
extern mint  fgl_dynarr_extentsize();

#ifdef MLS
extern mint  fgl_english();
extern mint  fgl_labeleq();
extern mint  fgl_labelge();
extern mint  fgl_labelglb();
extern mint  fgl_labelgt();
extern mint  fgl_labelle();
extern mint  fgl_labellt();
extern mint  fgl_labellub();
#endif /* MLS */

#endif /* USE_PROTOTYPES */

#endif /* FGLLIB_H */
