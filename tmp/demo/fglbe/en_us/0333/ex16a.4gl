
#######################################################################
# APPLICATION: Example 16a - 4GL Examples Manual                      # 
#                                                                     # 
# FILE: ex16a.4gl                           FORM: f_menu.per          # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program illustrates how to create a vertical menu     #
#          using a simple INPUT statement and a form with menu        #
#          options.                                                   #
#                                                                     # 
# FUNCTIONS:                                                          #
#   main_menu() - displays the f_menu form that contains the vertical #
#      menu: 4GL Test MAIN MENU.                                      #
#   cust_maint() - displays a message indicating that the routine     #
#       called was under the Customer Maintenance menu option.        #
#   stock_maint() - displays a message indicating that the routine    #
#       called was under the Stock Maintenance menu option.           #
#   order_maint() - displays a message indicating that the routine    #
#       called was under the Order Maintenance menu option.           #
#   manuf_maint() - displays a message indicating that the routine    #
#       called was under the Manufacturer Maintenance option.         #
#   ccall_maint() - displays a message indicating that the routine    #
#       called was under the Customer Call Maintenance option.        #
#   state_maint() - displays a message indicating that the routine    #
#       called was under the State Maintenance menu option.           #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/24/91    dam             Created example 16a                    #
#######################################################################

DATABASE stores2

GLOBALS

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################
--* Set help message file to "hlpmsgs" and set Form and Comment lines
--*   to work with the f_menu form.
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE FIRST,
    COMMENT LINE 2

  DEFER INTERRUPT

  CALL main_menu()

END MAIN

########################################
FUNCTION main_menu()
########################################
--* Purpose: Controls execution of the vertical menu implemented
--*            with a simple INPUT statement. The menu options 
--*            are stored directly in the f_menu form
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	dsply		SMALLINT,
		option_num	SMALLINT

  LET dsply = TRUE

--* Open a window to display the vertical menu in f_menu
  OPEN WINDOW w_menu AT 2, 3
    WITH 19 ROWS, 70 COLUMNS
    ATTRIBUTE (BORDER, MESSAGE LINE LAST)
   
  OPEN FORM f_menu FROM "f_menu"
  DISPLAY FORM f_menu

--* Notify user how to use the menu
  DISPLAY 
  " Enter a menu option number and press Accept or RETURN."
    AT 18, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY 
  " Choose option 7 to exit the menu. Press CTRL-W for Help." 
    AT 19, 1 ATTRIBUTE (REVERSE, YELLOW)

  WHILE dsply 

--* Accept menu option number as input. Help message 120 provides
--*   field-level help on what the user is to enter.
------------------------
    LET int_flag = FALSE
    INPUT BY NAME option_num HELP 120

--* If user pressed Cancel key, exit from loop and program
    IF int_flag THEN
      LET dsply = FALSE
    ELSE
--* Call appropriate 4GL function to implement selected menu option
      CASE option_num
	WHEN 1
	  CALL cust_maint()
	WHEN 2
	  CALL order_maint()
	WHEN 3
	  CALL stock_maint()
	WHEN 4
	  CALL manuf_maint()
	WHEN 5
	  CALL ccall_maint()
	WHEN 6
	  CALL state_maint()
	WHEN 7
          LET dsply = FALSE
	OTHERWISE
--* If user did not enter a valid number, display an error
          ERROR "Invalid menu choice. Please try again."
      END CASE
    END IF
  END WHILE

  CLOSE FORM f_menu
  CLOSE WINDOW w_menu

END FUNCTION -- main_menu --
      
########################################
FUNCTION cust_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the Customer Maintenance option. In an actual
--*            application, this function would implement the 
--*            Customer Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "  implement the Customer Maintenance option."
  CALL message_window(6,12)

END FUNCTION  -- cust_maint --

########################################
FUNCTION stock_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the Stock Maintenance option. In an actual
--*            application, this function would implement the 
--*            Stock Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "  implement the Stock Maintenance option."
  CALL message_window(6,12)

END FUNCTION  -- stock_maint --

########################################
FUNCTION order_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the Order Maintenance option. In an actual
--*            application, this function would implement the 
--*            Order Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "  implement the Order Maintenance option."
  CALL message_window(6,12)

END FUNCTION  -- order_maint --

########################################
FUNCTION manuf_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the Manufacturer Maintenance option. In an actual
--*            application, this function would implement the 
--*            Manufacturer Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "implement the Manufacturer Maintenance option."
  CALL message_window(6,12)

END FUNCTION  -- manuf_maint --

########################################
FUNCTION ccall_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the Customer Calls Maintenance option. In an actual
--*            application, this function would implement the 
--*            Customer Calls Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "  implement the Customer Calls Maintenance"
  LET ga_dsplymsg[3] = "  option."
  CALL message_window(6,12)

END FUNCTION  -- ccall_maint --

########################################
FUNCTION state_maint()
########################################
--* Purpose: Displays a message indicating that user has selected
--*            the State Maintenance option. In an actual
--*            application, this function would implement the 
--*            State Maintenance task.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  LET ga_dsplymsg[1] = "This function would contain the statements to"
  LET ga_dsplymsg[2] = "  implement the State Maintenance option."
  CALL message_window(6,12)

END FUNCTION  -- state_maint --

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


