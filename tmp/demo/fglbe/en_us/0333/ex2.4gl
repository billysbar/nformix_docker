
#######################################################################
# APPLICATION: Example 2 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex2.4gl                             FORM: none                # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of a message  #
#          window.                                                    #
#                                                                     # 
# STATEMENTS:                                                         # 
#          OPEN WINDOW WITH rows  PROMPT              GLOBALS         # 
#          CLOSE WINDOW           INITIALIZE                          # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   message_window(x,y) - displays the contents of a global array     #
#      called "ga_dsplymsg" in a window. Window size is determined    #
#      by the number of lines in the "ga_dsplymsg" array that are     #
#      non-null. Window position is determined by the "x" (column)    #
#      and "y" (row) arguments.                                       #
#   init_msgs() - clears out the global "ga_dsplymsg" array.          #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  12/27/90    dam             Added header to file                   #
#######################################################################

GLOBALS
# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)
END GLOBALS

########################################
MAIN
########################################
  DEFINE 	i		SMALLINT,
		dbstat		INTEGER

--* Simulate an actual status value by setting dbstat to -3720.
--*  In a full application, this value would be stored in the
--*  4GL status variable.
------------------------
  LET dbstat = -3720

--* Clear out the ga_dsplymsg array
  INITIALIZE ga_dsplymsg TO NULL

--* Store each line of the message text in a line of the
--*   ga_dsplymsgs array
------------------------
  LET ga_dsplymsg[1] = "The record has not been inserted into the"
  LET ga_dsplymsg[2] = "    database due to an error: ", 
	dbstat USING "-<<<<<<<<<<<"

  CALL message_window(3,4)
END MAIN

#######################################
FUNCTION message_window(x,y)
#######################################
--* Purpose: Displays a window containing user-defined text.
--*            The global array ga_dsplymsg contains this text.
--* Argument(s): x - x coordinate (column) of window's position
--*              y - y coordinate (row) of window's position
--* Return Value(s): NONE
---------------------------------------
  DEFINE numrows	SMALLINT,
	 x,y		SMALLINT,

  	 rownum,i	SMALLINT,
	 answer		CHAR(1),
	 array_sz	SMALLINT  -- size of the ga_dsplymsg array


--* The array_sz variable contains the size of the global message
--*   array, ga_dsplymsg. If the size of this array needs to be
--*   changed in the future, the developer only needs to change
--*   the value of array_sz to update the message_window() function 
------------------------
  LET array_sz = 5
  LET numrows = 4		-- numrows value:
				--        1 (for the window header)
				--        1 (for the window border)
				--        1 (for the empty line before
				--            the first line of message)
				--        1 (for the empty line after
				--            the last line of message)
--* Count the number of non-null (non-blank) lines currently
--*   stored in ga_dsplymsg
------------------------
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      LET numrows = numrows + 1
    END IF
  END FOR

--* Open the message window at the coordinates passed in as function
--*   arguments.
------------------------
  OPEN WINDOW w_msg AT x, y
    WITH numrows ROWS, 52 COLUMNS
    ATTRIBUTE (BORDER, PROMPT LINE LAST)

  DISPLAY " APPLICATION MESSAGE" AT 1, 17
   ATTRIBUTE (REVERSE, BLUE)

  LET rownum = 3		-- * start text display at third line

--* Display non-null lines of ga_dsplymsg in the message window.
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      DISPLAY ga_dsplymsg[i] CLIPPED AT rownum, 2
      LET rownum = rownum + 1
    END IF
  END FOR

  PROMPT " Press RETURN to continue." FOR answer
  CLOSE WINDOW w_msg

--* Clear out ga_dsplymsg array so it is ready for the next user call
  CALL init_msgs()

END FUNCTION  -- message_window --

########################################
FUNCTION init_msgs()
########################################
--* Purpose: Clears out the global message array ga_dsplymsg.
--*    It is called in the message_window() and prompt_window() 
--*    functions after each of these functions display the contents 
--*    of the ga_dsplymsg array.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	i	SMALLINT

  FOR i = 1 TO 5
    LET ga_dsplymsg[i] = NULL
  END FOR

END FUNCTION  -- init_msgs --


