/***************************************************************************
 *
 *			   INFORMIX SOFTWARE, INC.
 *
 *			      PROPRIETARY DATA
 *
 *	THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF 
 *	INFORMIX SOFTWARE, INC.  THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
 *	CONFIDENCE.  INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR 
 *	DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT 
 *	SIGNED BY AN OFFICER OF INFORMIX SOFTWARE, INC.
 *
 *	THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
 *	SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE. 
 *	UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
 *
 *
 *  Title:	fglapi.h
 *  Sccsid:	@(#)fglapi.h	11.1	9/15/94  11:30:49
 *  Description:
 *		Macro definitions for calling 4GL functions from C
 *
 ***************************************************************************
 */
#include "ifxtypes.h"
extern mint status;			/* 4GL global status variable */
extern mint int_flag;			/* 4GL global interrupt flag */
extern mint quit_flag;			/* 4GL global quit flag */

extern mint p4gl_call();
extern mint p4gl_start();
extern mint i4gl_start();

#ifndef INFORMIX_RDS

/* 
 * macros for calling Informix-4GL functions from C
 */
#define fgl_start(pathname)		i4gl_start()
#define fgl_end				i4gl_end
#define fgl_exitfm			i4gl_exitfm
#define fgl_call(funcname, nparams)	funcname(nparams)

#else

/*
 * macros for calling Informix-RDS functions from C
 */

#define fgl_start(pathname)		p4gl_start(pathname)
#define fgl_end				p4gl_end
#define fgl_exitfm			p4gl_exitfm

/*
 * B27070:
 * The fgl_call() macro must convert the funcname argument into a string.
 * ANSI C preprocessors do it with the # (stringize) operator.  Most pre-ANSI
 * preprocessors will substitute macro argument names even when they appear
 * in quotes in the replacement text of a macro.  If your compiler does not
 * define __STDC__ but the preprocessor does support the ANSI preprocessor
 * syntax and semantics, then
 * Either: modify this header to define HAS_STRINGIZE_OPERATOR
 * Or:     use -DHAS_STRINGIZE_OPERATOR when compiling code with this header.
 * You will know this is your problem if you create a custom p-code runner
 * (fglgo, fgldb) and you run a program which makes an fgl_call() and you get
 * error message -1338 referring to function "funcname".
 */
#ifdef __STDC__
#undef HAS_STRINGIZE_OPERATOR
#define HAS_STRINGIZE_OPERATOR
#endif /* __STDC__ */

#ifdef HAS_STRINGIZE_OPERATOR
#define fgl_call(funcname, nparams)	p4gl_call(#funcname, nparams)
#else
#define fgl_call(funcname, nparams)	p4gl_call("funcname", nparams)
#endif /* HAS_STRINGIZE_OPERATOR */

#endif	/* INFORMIX_RDS */
