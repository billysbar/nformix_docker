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
 *  Title:	fgiusr.c
 *  Sccsid:	@(#)fgiusr.c	7.2	7/8/90  13:50:19
 *  Description:
 *		definition of user C functions
 *
 ***************************************************************************
 */

/***************************************************************************
 *
 * This table is for user-defined C functions.
 *
 * Each initializer has the form:
 *
 *	"name", name, nargs,
 *
 * Variable # of arguments:
 *
 *	set nargs to -(maximum # args)
 *
 * Be sure to declare name before the table and to leave the
 * line of 0's at the end of the table.
 *
 * Example:
 *
 *	You want to call your C function named "mycfunc" and it expects
 *	2 arguments.  You must declare it:
 *
 *		int mycfunc();
 *
 *	and then insert an initializer for it in the table:
 *
 *		"mycfunc", mycfunc, 2,
 *
 ***************************************************************************
 */

#include "fgicfunc.h"

int fglgets();
int fglgetret();

cfunc_t usrcfuncs[] = 
    {
    "fglgets", fglgets, -1,
    "fglgetret", fglgetret, 0,
    0, 0, 0
    };
