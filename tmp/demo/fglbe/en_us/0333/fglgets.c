/* ========================================================================

	This module defines a C function for reading stream input using
	the fgets() function from the standard C library.  The main
	use intended is to read from standard input so that a 4GL program
	can act as a UNIX filter; however any ascii file may be read.

	In 4GL notation the interface to this module is

		DEFINE	input_line, file_pathname CHAR(255)
		CALL fglgets(file_pathname) RETURNING input_line

	fglgets() returns the next input line, to a maximum of 255
	bytes, from the specified file.

	The input file will be standard input in any of three cases:
	
		* the filename parameter is not specified
		* the filename parameter is a null string (or all-blank)
		* the filename parameter is "stdin"

	Otherwise the specified file is opened mode "r" (if necessary).
	A file is only opened once.  Its name and file pointer are
	saved and used on subsequent calls for that name.  Several files
	may be opened concurrently (see MAXOPEN below).

	The function returns the line of data as a string result.  The
	terminating newline is not returned.  Thus a blank string is
	returned where the file contains a null line.

	This function should not be used for interactive input. The
	reason is that stdout is not flushed prior to input, so a
	prompt string written with DISPLAY may not be seen by the user.
	For interactive applications use PROMPT or INPUT.

	The function has a result code which can have any of the
	following values:

		0	successful read
	      100	end of file
	       -1	UNIX would not open the file (fopen returned NULL)
	       -2	too many files open
	       -3	malloc failed, we couldn't save the filename
	       -4	too many parameters to fglgets()

	When the return code is other than 0, the returned string is
	always null (all-blank).  However, to retrieve the return code
	the 4GL program must call fglgetret(), which returns an integer.

====================================================================== */

#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#define MAXOPEN 8
#define MAXSTR 256	/* includes the null - max data is 255!!! */

static short nfiles = 0;	/* how many filenames we know about */
static char *fnames[MAXOPEN];	/* ->saved filename strings for compares */
static FILE *files[MAXOPEN];	/* saved fileptrs for open files */
static short retcode = 100;	/* return code with initial value */

/* =======================================================================
	This function performs a 4gl "ibm_lib4gl_popQuotedStr" or argument fetch.
	4GL has the peculiarity that the ibm_lib4gl_popQuotedStr() operation will
	truncate or extend the passed string to the length of the
	receiving buffer.  This means that because we ALLOW strings up
	to 255 bytes, we always GET strings of EXACTLY 255 bytes --
	padded with blanks.  Here we "pop" the value and trim off the
	off the trailing spaces.

	Late note: if we used ibm_lib4gl_popVarChar() instead of ibm_lib4gl_popQuotedStr the
	blanks are stripped automatically.
*/
void getquote(str,len)
	char *str;	/* place to put the string */
	int len;	/* length of string expected */
{
	register char *p;
	register int n;
	ibm_lib4gl_popQuotedStr(str,len);
	for( p = str, n = len-1 ;
			(n >= 0) && (p[n] <= ' ');
							--n )
		;
 	p[n+1] = '\0';
}

/* =======================================================================
    This function returns the last retcode, using 4GL conventions.
*/
int fglgetret(numargs)
	int numargs;		/* number of parameters (ignored) */
{
	ibm_lib4gl_returnInt2(retcode);
	return(1);		/* number of values pushed */
}

/* =======================================================================
    The steps of the operation are as follows:
	1. check number of parameters; if >1 return null & -4
	2. get filename string to scratch string space
	3. if we do not have stdin,
	    a. if we have never seen this filename before,
		  i. if we have our limit of files, return null & -2
		 ii. if unix will not open it, return null & -1
		iii. if we cannot save the filename string, return null & -3
		 iv. else save filename and matching FILE*
	    b. else pick up FILE* matching filename
	4. else pick up FILE* of stdin
	5. apply fgets(astring,MAXSTR,file) and note result
	6. if fgets() returned NULL, return null & 100
	7. check for and zap the trailing newline, return line & 0
*/
int fglgets(numargs)
	int numargs;		/* number of parameters in 4gl call */
{
	register int ret;	/* running success flag --> sqlcode */
	register int j;		/* misc index */
	register char *ptr;	/* misc ptr to string space */
	FILE* afile;		/* selected file */
	char astring[MAXSTR];	/* scratch string space */

	astring[0] = '\0';	/* default parameter is null string */
	ret = 0;		/* default result is whoopee */
	afile = stdin;		/* default file is stdin */

	switch (numargs)
	{
	case 1:			/* one parameter, pop as string */
		getquote(astring,MAXSTR);
	case 0:			/* no parameters, ok, astring is null */
		break;
	default:		/* too many parameters, clear stack */
		for( j = numargs; j; --j)
			ibm_lib4gl_popQuotedStr(astring,MAXSTR);
		ret = -4;
	}

	if ( (ret == 0)			/* parameters ok and.. */
	&&   (astring[0])		/* ..non-blank string passed.. */
	&&   (strcmp(astring,"stdin")) )/* ..but not "stdin".. */
	{				/* ..look for string in our list */
		for ( j = nfiles-1;
				(j >= 0) && (strcmp(astring,fnames[j]));
					--j )
			;
		if (j >= 0)		/* it was there (strcmp returned 0) */
			afile = files[j];
		else			/* it was not; try to open it */
		{
			if ((j = nfiles) < MAXOPEN)
			{	 	/* not too many files, try fopen */
				afile = fopen(astring,"r");
				if (afile == NULL)
					ret = -1;
			}
			else ret = -2;
			if (ret == 0)	/* fopen worked, get space for name */
			{
				ptr = (char *)malloc(1+strlen(astring));
				if (ptr == NULL) ret = -3;
			}
			if (ret == 0)	/* have space, copy name & save */
			{
				files[j] = afile;
				fnames[j] = ptr;
				strcpy(ptr,astring);
				++nfiles;
			}
		}
	}

	if (ret == 0)			/* we have a file to use */
	{
		ptr = fgets(astring,MAXSTR,afile);
		if (ptr != NULL)	/* we did read some data */
		{			/* check for newline, remove */
			ptr = astring + strlen(astring) -1;
			if ('\n' == *ptr) *ptr = '\0';
		}
		else ret = 100;		/* set eof return code */
	}

	if (ret)			/* not a success */
		astring[0] = '\0';	/* .. ensure null string return */

	retcode = ret;			/* save return for fglgetret() */
	ibm_lib4gl_returnQuotedStr(astring);		/* set string RETURN value.. */
	return(1);			/* .. and tell 4gl how many pushed */
}		
