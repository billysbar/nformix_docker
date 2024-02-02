
#######################################################################
# APPLICATION: Example 13a - 4GL Examples Manual                      # 
#                                                                     # 
# FILE: ex13a.4gl                        FORM: none                   #
#                                        ASSOCIATED FILES: ex13.4gl   #
#                                                          fgiusr.c   #
#                                                          fglgets.c  #
#                                                                     # 
# PURPOSE: This program is a test scaffold for the real example 13,   #
#          the file fglgets.c -- a C function that reads lines from   #
#          ascii files.  The fglgets.c function reads a line and      #
#          echoes it back to either stdin (standard input) or an ASCII#
#          file. This program is called with the RUN statment by the  #
#          ex13.4gl file.                                             #
#                                                                     # 
# STATEMENTS:                                                         # 
#          CALL ... RETURNING                                         # 
#          NUM_ARGS() built-in function                               # 
#          ARG_VAL() built-in function                                # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   fdump(fname)  - uses fglgets() to read lines from the file        #
#     "fname" and displays them with DISPLAY.                         #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/28/91    dec             tidy up code                           #
#  02/27/91    dam             added front-end to program             #
#  02/14/91    dam             updated file header                    #
#  12/27/90    dec             initial draft                          #
#######################################################################

########################################
MAIN
########################################
  DEFINE 	arg 	SMALLINT, 
		fstat	SMALLINT,
		anarg 	CHAR(80)

--* If the program was called with no arguments, get fdump()
--*   to blank and call fdump to control reading of stdin
------------------------
    IF NUM_ARGS() = 0 THEN
	LET anarg = " "
	CALL fdump(anarg) RETURNING fstat
    ELSE
--* For each argument provided to program, provide arg to fdump()
--*   and call fdump() to control reading of file 
------------------------
	FOR arg = 1 TO NUM_ARGS()
--* Get argument passed to program
	    LET anarg = ARG_VAL(arg)
	    CALL fdump(anarg) RETURNING fstat
	    IF fstat <> NOTFOUND THEN
		EXIT FOR
	    END IF
	END FOR
    END IF
    IF fstat <> NOTFOUND THEN -- quit due to a problem, diagnose
	CASE fstat
	WHEN -1
	    DISPLAY "\nUnable to open file ", anarg CLIPPED, ".\n"
	WHEN -2
	    DISPLAY "\nToo many files open in fglgets().\n"
	WHEN -3
	    DISPLAY "\nCall to malloc() failed. Couldn't open the file.\n"
	WHEN -4
	    DISPLAY "\nToo many parameters to fglgets().\n"
	OTHERWISE
	    DISPLAY "\nUnknown return ",fstat," from fglgets().\n"
	END CASE
        PROMPT "Press RETURN to continue." FOR anarg
    END IF

END MAIN

########################################
FUNCTION fdump(fname)
########################################
--* Purpose: Controls calling of C function fglgets() to read
--*            either a file or stdin. 
--* Argument(s): fname - name of file to read
--*                            OR
--*                      blank if reading stdin
--* Return Value(s): success code for fglgets() 
---------------------------------------
  DEFINE 	fname	CHAR(80),

		inline  CHAR(255),
		ret	SMALLINT

--* Read one line of file or stdin
    CALL fglgets(fname) RETURNING inline

--* Check success code of fglgets()
    LET ret = fglgetret()
    IF ret = 0 THEN	-- successful read of first line

--* If reading a file, notify user that file is being read
        IF fname <> " " THEN
	    DISPLAY "-------------- dumping file ",
		    fname CLIPPED,
	    	    "----------------"
        END IF
--* Read successive lines of file or stdin until fglgetret()
--*   indicates no success
------------------------
        WHILE ret = 0
	    DISPLAY inline CLIPPED
	    CALL fglgets(fname) RETURNING inline
	    LET ret = fglgetret() 
        END WHILE
--* If reading a file, notify user when function reaches
--*   end-of-file.
------------------------
	IF ret = NOTFOUND AND fname <> " " THEN
	    DISPLAY "\n-------------- end file ",
		    fname CLIPPED,
	            "----------------\n"
	    SLEEP 3
	END IF
    END IF
    RETURN ret
END FUNCTION  -- fdump --
