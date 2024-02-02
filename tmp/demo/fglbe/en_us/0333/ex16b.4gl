
#######################################################################
# APPLICATION: Example 16b - 4GL Examples Manual                      # 
#                                                                     # 
# FILE: ex16b.4gl                           FORM: f_menu2.per         # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program illustrates how to create a vertical menu     #
#          using an INPUT ARRAY statement. When the user moves the    #
#          cursor to a menu selection, the entire line of the array   #
#          is highlighted in reverse.                                 #
#                                                                     # 
# FUNCTIONS:                                                          #
#   dsply_menu() - displays the f_menu2 form that contains the        #
#       the generic vertical menu form.                               #
#   init_menu() - initializes the global menu structure with the      #
#       menu options to be displayed.                                 #
#   init_opnum() - initializes the global menu structure with the     #
#       menu option numbers to be displayed.                          #
#   choose_option(total_options) - implements the INPUT ARRAY         #
#       statement that simulates the DISPLAY ARRAY and the vertical   #
#       menu selection.                                               #
#   cust_maint() - displays a message indicating that the routine     #
#       called was under the Customer Maintenance menu option.        #
#   stock_maint() - displays a message indicating that the routine    #
#       called was under the Stock Maintenance menu option.           #
#   order_maint() - displays a message indicating that the routine    #
#       called was under the Order Maintenance menu option.           #
#   manuf_maint() - displays a message indicating that the routine    #
#       called was under the Manufacturer Maintenance menu option.    #
#   ccall_maint() - displays a message indicating that the routine    #
#       called was under the Customer Call Maintenance menu option.   #
#   state_maint() - displays a message indicating that the routine    #
#       called was under the State Maintenance menu option.           #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/23/91    dam             Created example 16b                    #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	ga_menu ARRAY[20] OF RECORD 
		  x  		CHAR(1),
		  option_num  	CHAR(3),
		  option_name  	CHAR(35)
            	END RECORD,

		g_menutitle	CHAR(25)

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################

--* Set help message file to "hlpmsgs" and set Comment and Message
--*   lines for work with f_menu2 form. Also redefine Form line.
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    COMMENT LINE FIRST,
    MESSAGE LINE LAST,
    FORM LINE 2

  DEFER INTERRUPT

  CALL dsply_menu()

END MAIN

########################################
FUNCTION dsply_menu()
########################################
--* Purpose: Controls execution of the vertical menu implemented 
--*            with an INPUT ARRAY statement. The menu options are
--*            stored in a global array (ga_menu) and displayed
--*            on the f_menu2 form's screen array.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	dsply		SMALLINT,
		option_no	SMALLINT,
		total_options	SMALLINT

--* Open a window to display the vertical menu in f_menu2
  OPEN WINDOW w_menu2 AT 3,3
    WITH 16 ROWS, 75 COLUMNS
    ATTRIBUTE (BORDER)

  OPEN FORM f_menu FROM "f_menu2"
  DISPLAY FORM f_menu

--* Notify user how to use the menu
  DISPLAY " Use F3, F4, and arrow keys to move cursor to desired option."
    AT 15, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY 
  " Press Accept to choose option, Cancel to exit menu. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Initialize global menu array (ga_menu) with menu options and menu
--*   title (g_menutitle). Return the number of valid options.
------------------------
  CALL init_menu() RETURNING total_options

--* Display menu title on f_menu2 form
  DISPLAY g_menutitle TO menu_title

  LET dsply = TRUE
  WHILE dsply

--* Obtain selected menu option from choose_option() function
    LET option_no = choose_option(total_options)
    IF (option_no > 0) THEN
      CASE option_no
--* Call appropriate 4GL function to implement selected menu option
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
	WHEN 7  --* Exit option
	  LET dsply = FALSE
      END CASE
    ELSE
--* If choose_option() returned zero, user wants to exit menu.
      LET dsply = FALSE
    END IF
  END WHILE

  CLOSE FORM f_menu
  CLOSE WINDOW w_menu2

END FUNCTION  -- dsply_menu --

########################################
FUNCTION init_menu()
########################################
--* Purpose: Initializes the generic vertical menu form (f_menu2)
--*            with the menu options and title of the menu.
--* Argument(s): NONE
--* Return Value(s): number of menu options in menu
---------------------------------------
  DEFINE	total_options	SMALLINT

  LET g_menutitle = "4GL Test MAIN MENU 2"

  LET ga_menu[1].option_name = "Customer Maintenance"
  LET ga_menu[2].option_name = "Order Maintenance"
  LET ga_menu[3].option_name = "Stock Maintenance"
  LET ga_menu[4].option_name = "Manufacturer Maintenance"
  LET ga_menu[5].option_name = "Customer Calls Maintenance"
  LET ga_menu[6].option_name = "State Maintenance"
  LET ga_menu[7].option_name = "Exit MAIN MENU"

  LET total_options = 7
  CALL init_opnum(total_options)

  RETURN total_options

END FUNCTION  -- init_menu --

########################################
FUNCTION init_opnum(total_options)
#########################################
--* Purpose: Initializes the menu option numbers in the global menu
--*   array ga_menu. The initialization of the option numbers is 
--*   separated from the initialization of menu option names (in 
--*   the init_menu() function) because the menu option names must 
--*   be initialized for each vertical menu (a new init_menu() 
--*   function) while the menu option numbers will always be
--*   initialized to integers from 1 to the number of menu options. 
--*   This function will not have to be rewritten for each vertical 
--*   menu.
--* Argument(s): total_options - the number of valid menu options for
--*                              this vertical menu.
--* Return Value(s): NONE
---------------------------------------
  DEFINE	total_options	SMALLINT,

		i		SMALLINT

  FOR i = 1 TO total_options
    IF i < 10 THEN
--* If the option number contains only one digit, store the number at
--*   the second position of the option number character string.
------------------------
      LET ga_menu[i].option_num[2] = i
    ELSE
--* If the option number contains two digits, store the number at
--*   the first and second positions of the option number character string.
------------------------
      LET ga_menu[i].option_num[1,2] = i
    END IF
--* Store a trailing ")" so the option number has the form 
--*   1), 2), etc. This trailing ")" is why the option_num field is
--*   defined as character rather than integer.
------------------------
    LET ga_menu[i].option_num[3] = ")"
  END FOR
  
END FUNCTION  -- init_opnum --

########################################
FUNCTION choose_option(total_options)
########################################
--* Purpose: Implements the INPUT ARRAY for the generic vertical menu
--*            and determines which option the user has selected.
--* Argument(s): total_options - the number of valid menu options for
--*                              this vertical menu.
--* Return Value(s): the option number selected from the vertical
--*                     menu
--*                  zero if the user ends the INPUT ARRAY with
--*                     Cancel key
---------------------------------------
  DEFINE	total_options		SMALLINT,

		curr_pa			SMALLINT,
		curr_sa			SMALLINT,
		total_pa		SMALLINT,
		lastkey			SMALLINT

--* Redefine Delete and Insert keys (in array) so that they
--*   are, in effect, turned off. CONTROL-A is always interpreted
--*   by 4GL as the Edit Mode Toggle so the Delete or Insert keys will
--*   never have an effect
------------------------
  OPTIONS
    DELETE KEY CONTROL-A,
    INSERT KEY CONTROL-A

--* Initialize size of program array so ARR_COUNT() can keep track
  CALL SET_COUNT(total_options)

--* Display menu options on the generic vertical menu form
  LET int_flag = FALSE
  INPUT ARRAY ga_menu WITHOUT DEFAULTS FROM sa_menu.* HELP 121

--* Obtain current screen array and program array positions
    BEFORE ROW
      LET curr_pa = ARR_CURR()
      LET total_pa = ARR_COUNT()
      LET curr_sa = SCR_LINE()

--* Displaying current line of program array to current line of screen
--*   array in reverse video creates a "highlighted" current line 
------------------------
      DISPLAY ga_menu[curr_pa].* TO sa_menu[curr_sa].*
	ATTRIBUTE (REVERSE)

    AFTER FIELD x
--* The field x is a "resting place" for the cursor. The IF statement
--*   effectively erases any input the user might make.
------------------------
      IF ga_menu[curr_pa].x IS NOT NULL THEN
	LET ga_menu[curr_pa].x = NULL
	DISPLAY BY NAME ga_menu[curr_pa].x
      END IF

--* Prevent the user from moving off the end of the program array. Editing
--*   is not permitted on a vertical menu. The user must be prevented from 
--*   adding new lines. Turning off the Input key prevents new lines
--*   from within the array. This code prevents new lines at the end of 
--*   the array. 
--* NOTE: the FGL_LASTKEY() and FGL_KEYVAL() functions are new 4.1 features.
------------------------
      IF curr_pa = total_pa THEN
	LET lastkey = FGL_LASTKEY()
	IF ( (lastkey = FGL_KEYVAL("down"))
	    OR (lastkey = FGL_KEYVAL("return"))
	    OR (lastkey = FGL_KEYVAL("tab"))
	    OR (lastkey = FGL_KEYVAL("right")) )
	THEN
	  ERROR "No more menu options in this direction."
	  NEXT FIELD x
	END IF
      END IF
      
    AFTER ROW
--* Obtain current screen array and program array positions
      LET curr_pa = ARR_CURR()
      LET curr_sa = SCR_LINE()

--* Displaying current line of program array to current line of screen
--*   array in normal video turns off the "highlighted" current line 
------------------------
      DISPLAY ga_menu[curr_pa].* TO sa_menu[curr_sa].*

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    RETURN (0)
  END IF

  RETURN (curr_pa)

END FUNCTION  -- choose_option --

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


