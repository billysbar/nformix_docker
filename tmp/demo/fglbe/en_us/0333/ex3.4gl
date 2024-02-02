
#######################################################################
# APPLICATION: Example 3 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex3.4gl                             FORM: none                # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of a simple   #
#          4GL menu.                                                  #
#                                                                     # 
# STATEMENTS:                                                         # 
#          MENU		RUN	OPTIONS - HELP FILE                   #
#          EXIT MENU    CASE                                          #
#                                                                     # 
# FUNCTIONS:                                                          #
#   dsply_option(option_num) - creates a string that describes the    #
#       position of the menu option selected by the user ("first, ...)#
#       and then calls message_window() to display the option called. #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   bang() - provides a prompt for an operating system command and    #
#      then executes this command.                                    #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/04/91    dam             Created Example 3 file                 #
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

  OPTIONS
    HELP FILE "hlpmsgs",   -- CTRL-W from a field gets help from this file
    PROMPT LINE LAST	   -- redefine the Prompt line to the last line

--* Display a line under the menu telling the user how to get help
  DISPLAY 
    "---------------------------------------Press CTRL-W for Help----------"
    AT 3, 1

--* The DEMO MENU consists of five options, each of which has a
--*   option-specific help message. Help messages are accessed
--*   with CONTROL-W. The menu also defines a "hidden" key
--*   feature: pressing "!" followed by an operating system command
--*   will execute the operating system command.
--* NOTE: having two menu options with the same first letter ("First" and
--*   "Fourth") is a new 4.1 feature.
-------------------------
  MENU "DEMO MENU"
    COMMAND "First" "This is the first option of the menu." HELP 1
      CALL dsply_option(1)
    COMMAND "Second" "This is the second option of the menu." HELP 2
      CALL dsply_option(2)
    COMMAND "Third" "This is the third option of the menu." HELP 3
      CALL dsply_option(3)
    COMMAND "Fourth" "This is the fourth option of the menu." HELP 4
      CALL dsply_option(4)
    COMMAND KEY ("!")
      CALL bang()
    COMMAND "Exit" "Exit the program." HELP 100
      EXIT MENU
  END MENU

  CLEAR SCREEN
END MAIN

#######################################
FUNCTION dsply_option(option_num)
#######################################
--* Purpose: Displays a window containing the name of the option
--*            selected by the user.
--* Argument(s): option_num - number representing the option selected
--* Return Value(s): NONE
---------------------------------------
  DEFINE	option_num	SMALLINT,

		option_name	CHAR(6)  -- name of selected option

  CASE option_num
    WHEN 1
      LET option_name = "First"
    WHEN 2
      LET option_name = "Second"
    WHEN 3
      LET option_name = "Third"
    WHEN 4
      LET option_name = "Fourth"
  END CASE

--* Set up global message array, ga_dsplymsg, and call message_window()
--*   to display option description.
---------------------------------------
  LET ga_dsplymsg[1] = "You have selected the ", option_name CLIPPED, 
			" option from the"
  LET ga_dsplymsg[2] = "                  DEMO menu."
  CALL message_window(6, 4)

END FUNCTION  -- dsply_option --

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
FUNCTION bang()
########################################
--* Purpose: Executes an operating system command
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	cmd 		CHAR(80),
		key_stroke 	CHAR(1)

--* Prompt user with operating system prompt of "unix! "
    LET key_stroke = "!"
    WHILE key_stroke = "!"

--* Use PROMPT command to accept user's command
       PROMPT "unix! " FOR cmd

--* Run user's command
       RUN cmd

--* If user presses any key accept "!", WHILE loop exits
       PROMPT "Type RETURN to continue." FOR CHAR key_stroke
    END WHILE

END FUNCTION  -- bang --

