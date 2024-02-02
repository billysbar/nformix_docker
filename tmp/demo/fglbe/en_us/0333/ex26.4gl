
####################################################################### 
# APPLICATION: Example 26 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex26.4gl                            FORM: f_logo.per,         # 
#                                                 f_customer.per,     # 
#                                                 f_orders.per,       # 
#                                                 f_stock.per         # 
#                                                                     # 
# PURPOSE: This program demonstrates how to program an application    #
#          using multiple windows. It creates a screen with 3         #
#          windows: an application window that displays the current   #
#          time, a menu window that displays the current menu, and a  #
#          form window that displays the current form.                #
#                                                                     # 
# STATEMENTS:                                                         # 
#          CURRENT WINDOW                                             # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   dsply_screen() - opens the 3 application windows.                 #
#   close_screen() - closes the 3 application windows.                #
#   menu_main() - makes the menu window (w_menu) current and displays #
#      the MAIN menu in it.                                           #
#   curr_wndw(wndw) - makes a new app window current.                 #
#   sub_menu() - makes a form window (w_form) current and displays    #
#      the specified form in it. Also displays the form's menu in     #
#      this window.                                                   #
#   new_time() - makes the application window (w_app) current and     #
#      displays the updated system time in it.                        #
#   dummymsg() - development routine that displays message:           #
#                  "Function not implemented yet."                    #
#   bang() - see description in ex3.4gl file.                         #
#   dsply_logo(sleep_secs) - see description in ex1.4gl file.         #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     # 
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  02/11/91    dam             Created ex26.4gl file                  #
#  04/12/91    dec             Gave help file a unique name           #
#  04/12/91    dec             Fixed size of time window, regularized #
#                              calls to dummymsg, moved things around #
#                              made dsply_screen() call a new_time()  #
#                              and new_time() call curr_wndw(), added #
#                              lots of new_time() calls.              #
#######################################################################

########################################
MAIN
########################################

  DEFER INTERRUPT

--* Display application logo for 3 seconds
  CALL dsply_logo(3)
  CLEAR SCREEN

--* Display three-windowed screen and put main menu in one of these
--*   windows
------------------------
  CALL dsply_screen()
  CALL menu_main()

--* Close application windows
  CALL close_screen()
  CLEAR SCREEN
END MAIN

########################################
FUNCTION dsply_screen()
########################################
--* Purpose: Displays the three application windows:
--*            w_app - displays the demo name and the current time
--*            w_menu - displays the current menu (initially the
--*                     main menu)
--*	       w_form - displays the current application form
--*                     (initially blank)
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  OPEN WINDOW w_app AT 2,3
    WITH 2 ROWS, 19 COLUMNS
    ATTRIBUTE(BORDER, MESSAGE LINE LAST)

  DISPLAY " IBM INFORMIX-4GL Demo " 
    AT 1, 1 ATTRIBUTE(REVERSE, RED)
  DISPLAY "Time:" AT 2, 2
  CALL new_time()

  OPEN WINDOW w_menu AT 2,23
    WITH 2 ROWS, 56 COLUMNS
    ATTRIBUTE(BORDER)

  OPEN WINDOW w_form AT 5,3
    WITH 16 ROWS, 76 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 1, 
	      MESSAGE LINE LAST, PROMPT LINE LAST)
 
END FUNCTION  -- dsply_screen --

########################################
FUNCTION close_screen()
########################################
--* Purpose: Closes the three application windows.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  CLOSE WINDOW w_form
  CLOSE WINDOW w_menu
  CLOSE WINDOW w_app

END FUNCTION  -- close_screen --

########################################
FUNCTION curr_wndw(wndw)
########################################
--* Purpose: Makes a specified window current. When a window
--*            is current, it is "on top" of any other open
--*            windows and the cursor is in it.
--* Argument(s): wndw - "M" - make the w_menu window current
--*	                "F" - make the w_form window current
--*	                "A" - make the w_app window current
--* Return Value(s): NONE
---------------------------------------
  DEFINE wndw	CHAR(1)

  CASE wndw
    WHEN "M"
      CURRENT WINDOW IS w_menu
    WHEN "F"
      CURRENT WINDOW IS w_form
    WHEN "A"
      CURRENT WINDOW IS w_app
  END CASE

END FUNCTION  -- curr_wndw --

########################################
FUNCTION new_time()
########################################
--* Purpose: Displays the current system time in the application
--*            window (w_app).
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE the_time	DATETIME HOUR TO MINUTE

--* Make the w_app window current
  CALL curr_wndw("A")

--* Get the current time and display it in w_app window
  LET the_time = CURRENT
  DISPLAY the_time AT 2,8

END FUNCTION  -- new_time --

########################################
FUNCTION dummymsg()
########################################
--* Purpose: Displays the message
--*            "Function Not Implemented Yet"
--*	     in the form window (w_form). This function is called as
--*          a placeholder when a menu option is not yet implemented.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  CALL curr_wndw("F")
  CALL msg("Function Not Implemented Yet")

END FUNCTION  -- dummymsg --

########################################
FUNCTION menu_main()
########################################
--* Purpose: Displays the MAIN menu and implements the
--*            options with a generic sub menu routine.
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------

--* Make the menu window (w_menu) current
  CALL curr_wndw("M")

--* The MAIN menu provides options for the user to take
--*   when the application first begins.
------------------------
  MENU "MAIN"
    COMMAND "Customer" "Enter and maintain customer data."
      CALL sub_menu("C")
      CALL curr_wndw("M")

    COMMAND "Orders" "Enter and maintain orders."
      CALL sub_menu("O")
      CALL curr_wndw("M")

    COMMAND "Stock" "Enter and maintain stock list."
      CALL sub_menu("S")
      CALL curr_wndw("M")

    COMMAND KEY ("!")
      CALL bang()
      CALL curr_wndw("M")

    COMMAND KEY ("E", "e", "X", "x") "Exit" 
	"Exit program and return to operating system."
      EXIT MENU
  END MENU

END FUNCTION  -- menu_main --

########################################
FUNCTION sub_menu(menuopt)
########################################
--* Purpose: Displays a specified menu and form. This function
--*            stores the names and options for these menus in 
--*            an array and uses a generic menu statement to
--*            display a sub-menu. 
--* Argument(s): menuopt - "C" to display customer sub-menu and form
--*	                   "O" to display orders sub-menu and form
--*	                   "S" to display stock sub-menu and form
--* Return Value(s): NONE
---------------------------------------
  DEFINE menuopt	CHAR(1),

	 s_menu ARRAY[3] OF RECORD
  		menuname 	CHAR(10),
		option1 	CHAR(15), 
		optdesc1 	CHAR(50),
		option2 	CHAR(15), 
		optdesc2 	CHAR(50),
		option3 	CHAR(15), 
		optdesc3 	CHAR(50)
	 END RECORD,

	 idx 		SMALLINT,
	 form_name	CHAR(10)

--* Load the menu array with the title and option names for the
--*   three sub-menus: CUSTOMERS, ORDERS, and STOCK.
------------------------
  LET s_menu[1].menuname = "CUSTOMERS"
  LET s_menu[1].option1 = "Add"
  LET s_menu[1].optdesc1 = "Add new customer(s) to the database."
  LET s_menu[1].option2 = "Query"
  LET s_menu[1].optdesc2 = "Look up customers information."
  LET s_menu[1].option3 = "Report"
  LET s_menu[1].optdesc3 = "Create customer reports."
  
  LET s_menu[2].menuname = "ORDERS"
  LET s_menu[2].option1 = "Place"
  LET s_menu[2].optdesc1 = "Add new order to database and print invoice."
  LET s_menu[2].option2 = "Query"
  LET s_menu[2].optdesc2 = "Look up and display order information."
  LET s_menu[2].option3 = "Report"
  LET s_menu[2].optdesc3 = "Create order reports."

  LET s_menu[3].menuname = "STOCK"
  LET s_menu[3].option1 = "Add"
  LET s_menu[3].optdesc1 = "Add new stock item(s) to the database."
  LET s_menu[3].option2 = "Query"
  LET s_menu[3].optdesc2 = "Look up and display stock information."
  LET s_menu[3].option3 = "Report"
  LET s_menu[3].optdesc3 = "Create stock reports."

--* Make the form window (w_form) current
  CALL curr_wndw("F")

--* Identify the form to display for the particular sub-menu
--*   and the sub-menu's index in the menu array.
------------------------
  CASE menuopt
    WHEN "C"
      LET form_name = "f_customer" 
      LET idx = 1
    WHEN "O"
      LET form_name = "f_orders" 
      LET idx = 2
    WHEN "S"
      LET form_name = "f_stock"
      LET idx = 3
  END CASE

--* Display the appropriate form for the option in the form window.
--* NOTE: using a variable as a form file name is a new 4.1 feature.
------------------------
  OPEN FORM the_option FROM form_name
  DISPLAY FORM the_option

--* Make the menu window (w_menu) current
  CALL curr_wndw("M")
    
--* Display the appropriate menu title and options. These items are
--*   obtained by indexing into the menu array. These options are
--*   not currently implemented. Instead a dummy function
--*   is called in place of the actual function.
--* NOTE: using variables as menu titles and option names are new 
--*       4.1 features.
------------------------
  MENU s_menu[idx].menuname
    COMMAND s_menu[idx].option1 s_menu[idx].optdesc1 
       CALL dummymsg()
    COMMAND s_menu[idx].option2 s_menu[idx].optdesc2
       CALL dummymsg()
    COMMAND s_menu[idx].option3 s_menu[idx].optdesc3
       CALL dummymsg()
    COMMAND KEY ("!")
       CALL bang()
    COMMAND KEY ("E", "e", "X", "x") "Exit" "Return to MAIN Menu."
      CLEAR WINDOW w_form
      EXIT MENU
  END MENU

--* Update the current time in the application window (w_app)
  CALL new_time()

END FUNCTION  -- sub_menu --

#######################################
FUNCTION dsply_logo(sleep_secs)
#######################################
--* Purpose: Displays an application logo on the screen for a 
--*            specified number of seconds.
--* Form: f_logo.per
--* Argument(s): sleep_secs - number of seconds to display logo
--* Return Value(s): NONE
---------------------------------------
  DEFINE sleep_secs	SMALLINT,

  	 thedate 	DATE

--* Open the f_logo form (allocate resources) and display the form
--*  on the screen
------------------------
  OPEN FORM app_logo FROM "f_logo"
  DISPLAY FORM app_logo

  DISPLAY " IBM INFORMIX-4GL By Example Application" AT 2,15
    ATTRIBUTE (REVERSE, GREEN)

--* Initialize the application date then display it in the appdate
--*   field on the f_logo form.
------------------------
  LET thedate = TODAY
  DISPLAY thedate TO formonly.appdate

--* Pause execution for "sleep_secs" seconds so that the f_logo form 
--*   remains on the screen.
------------------------
  SLEEP sleep_secs
  CLOSE FORM app_logo
  
END FUNCTION  -- dsply_logo --

########################################
FUNCTION msg(str)
########################################
--* Purpose: Displays a "str" string of 78 characters in the Message
--*            line for 3 seconds then clears the Message line.
--* Argument(s): str - text to display
--* Return Value(s): NONE
---------------------------------------
  DEFINE	str	CHAR(78)

  MESSAGE str 
  SLEEP 3
  MESSAGE ""

END FUNCTION  -- msg --

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


