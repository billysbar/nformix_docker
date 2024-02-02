
#######################################################################
# APPLICATION: Example 25 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex25.4gl                            FORM: f_customer.per      # 
#                                                 f_statesel.per      # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of an         #
#          error log to record application errors. To illustrate the  #
#          error log entry, this program needs to encounter a database#
#          error at runtime. To ensure the presence of a database     #
#          error, this program creates a UNIQUE index on the "company"#
#          column of the customer table. When the user enters a new   #
#          company name that already exists in the database, the      #
#          program encounters the runtime error and makes an entry in #
#          the error log file "errlog". Before exiting, the program   #
#          drops the UNIQUE index on the "company" column.            #
#                                                                     #
#          To see the demonstration of the error log entry, the user  #
#          should:                                                    #
#             1. Choose "Add" from the CUSTOMER menu.                 #
#             2. Enter the company name: Athletic Supplies            #
#                (entering any existing company name will generate    #
#                 this error)                                         #
#             3. Press the Accept key (ESC by default) to save the    #
#                customer row.                                        #
#             4. Answer "y" to the prompt:                            #
#                 Are you sure you want to add another?               #
#          The program displays error -239 at the bottom of the       #
#          and returns the user to the CUSTOMER menu.                 #
#             5. Choose "Exit" from the CUSTOMER menu.                #
#             6. Press RETURN to return to the r4gl or i4gl menu.     #
#             7. View the error log file with a system text editor.   #
#                If your system editor is "vi", then the command:     #
#                   !vi errlog                                        #
#                brings up the file with the recent error log entry.  #
#                This entry shows the sqlcode value, the ISAM error,  #
#                and the error message text.                          #
#             8. When finished viewing the error log, leave the       #
#                system editor. If your system editor is "vi", then   #
#                the command:                                         #
#                    :q                                               #
#                exits the editor.                                    #
#             9. Press RETURN to return to the r4gl (or i4gl) menu.   #
#                                                                     # 
# FUNCTIONS:                                                          #
#   create_index() - creates a UNIQUE index on the company column of  #
#      the customer table. This index enables this example to demon-  #
#      strate locking conflicts.                                      #
#   drop_index() - drops the UNIQUE index on the company column of the#
#      customer table.                                                #
#   init_log(logname) - initializes an error log of "logname".        #
#   cust_menu3() - displays the CUSTOMER menu and allows user to      #
#      choose whether to add a new customer or query for an existing  #
#      customer. Differs from cust_menu2() in ex17.4gl file by calling#
#      browse_custs3() instead of browse_custs2().                    #
#   bang() - see description in ex3.4gl file.                         #
#   query_cust2() - see description in ex6.4gl file.                  #
#   browse_custs3(selstmt) - displays results of query on screen, one #
#      at a time and calls next_action4() to allow user to choose     #
#      next action. Differs from browse_custs2() in ex17.4gl file by  #
#      calling next_action4() intead of next_action3().               #
#   next_action4() - displays menu that allows user to choose the     #
#      action to take: see the next row, update the current row, or   #
#      delete the current row. Calls addupd_cust() both for an insert #
#      and an update and uses error logging in the insert, update,    #
#      delete functions.                                              #
#   addupd_cust(au_flag) - see description in ex9.4gl file.           #
#   state_popup() - see description in ex9.4gl file.                  #
#   insert_cust2() - uses error logging to list database errors       #
#      occurring during INSERT of customer row.                       #
#   update_cust3() - uses error logging to list database errors       #
#      occurring during UPDATE of customer row.                       #
#   delete_cust2() - uses error logging to list database errors       #
#      occurring during DELETE of customer row.                       #
#   verify_delete() - see description in ex6.4gl file.                #
#   log_entry(errstat,fname) - creates an error log entry noting the  #
#      "errstat" error that has occurred in the function "fname".     #
#   get_user() - see description in ex27.4gl file.                    #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex3.4gl file.            #
#   prompt_window(question,x,y) - see description in ex6.4gl file.    #
#   msg(str) - see description in ex6.4gl file.                       #
#   clear_lines(numlines,mrow)- see description in ex6.4gl  file.     #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  02/07/91    dam             Created example 25 file                #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer 	RECORD LIKE customer.*,
		gr_workcust	RECORD LIKE customer.*,
		g_username	CHAR(8)

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################

  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 5,
    MESSAGE LINE LAST

  DEFER INTERRUPT

--* Create an error log for this example called "errlog"
  CALL init_log("errlog")

  IF create_index() THEN

--* This example creates a unique index on the "company" column of the
--* customer table. With this index, the program can generate a database
--* error when the user tries to add a new customer with an existing
--* company name. This database error is displayed on the screen and
--* registered in the application's error log file: errlog.
------------------------
    OPEN WINDOW w_main AT 2,3
     WITH 18 ROWS, 75 COLUMNS
     ATTRIBUTE (BORDER)

    OPEN FORM f_customer FROM "f_customer"
    DISPLAY FORM f_customer
    CALL cust_menu3()
    CLEAR SCREEN

--* Drop the unique index on the "company" column of the
--* customer table. By dropping this index, the database schema
--* returns to the original state of the newdemo database.
------------------------
    CALL drop_index()
  ELSE
    LET ga_dsplymsg[1] = "Unable to create a unique index on the"
    LET ga_dsplymsg[2] = "  company column. Please check the 'errlog'"
    LET ga_dsplymsg[3] = "  file for more detailed information."
    CALL message_window(9, 15)
  END IF

END MAIN

########################################
FUNCTION create_index()
########################################
--* Purpose: Creates a unique index on the "company" column of the
--*            customer table. In the original schema, this column 
--*            is allowed to contain duplicate values.
--* Argument(s): NONE
--* Return Value(s): TRUE - if index is successfully created
--*                  FALSE - if error encountered during create
---------------------------------------

WHENEVER ERROR CONTINUE
  CREATE UNIQUE INDEX comp_ix ON customer (company)
WHENEVER ERROR STOP

  IF (status < 0) THEN
    IF (status <> -316) THEN   --* if index already exists: OK

--* NOTE: Make sure that calls to the log_entry() function pass the
--*       error status as SQLCA.SQLCODE, not "status". Although the
--*       "status" variable is set to the value of SQLCA.SQLCODE after
--*       database statements, it also registers the success of other 
--*       4GL statements. In this case, the ERROR statement will reset
--*       the value of "status" (to 0 is the ERROR is successful). 
--*       The SQLCA.SQLCODE variable only registers the success of 
--*       database-related operations.
------------------------
      CALL log_entry(SQLCA.SQLCODE, "create_index()")
      RETURN (FALSE)
    END IF
  END IF

  RETURN (TRUE)

END FUNCTION  -- create_index --

########################################
FUNCTION drop_index()
########################################
--* Purpose: Drops the unique index on the company column of the
--*            customer table. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

WHENEVER ERROR CONTINUE
  DROP INDEX comp_ix
WHENEVER ERROR STOP

  IF (status < 0) THEN
    ERROR status USING "-<<<<<<<<<<<",
	": Unable to drop company column index."

--* NOTE: Make sure that calls to the log_entry() function pass the
--*       error status as SQLCA.SQLCODE, not "status". Although the
--*       "status" variable is set to the value of SQLCA.SQLCODE after
--*       database statements, it also registers the success of other 
--*       4GL statements. In this case, the ERROR statement will reset
--*       the value of "status" (to 0 is the ERROR is successful). 
--*       The SQLCA.SQLCODE variable only registers the success of 
--*       database-related operations.
------------------------
    CALL log_entry(SQLCA.SQLCODE, "drop_index()")
  END IF

END FUNCTION  -- drop_index --

########################################
FUNCTION init_log(logname)
########################################
--* Purpose: Creates an error log file and gets the name of the
--*            application user for future error log entries.
--* Argument(s): logname - the name of the error log file to create
--* Return Value(s): NONE
---------------------------------------
  DEFINE	logname	CHAR(10)

  CALL STARTLOG(logname)

  CALL get_user() RETURNING g_username

END FUNCTION  -- init_log --

########################################
FUNCTION cust_menu3()
########################################
--* Purpose: Displays the CUSTOMER menu so the use can choose
--*            an action on the customer table. 
--*            Differs from cust_menu1() in Ex 9 by calling
--*            browse_custs3() instead of browse_cust() to display menu
--*            and by using a new insert routine which includes
--*            error logging.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	st_custs	CHAR(150)

  DISPLAY 
  "--------------------------------------------Press CTRL-W for Help----------"
    AT 3, 1
  MENU "CUSTOMER"
    COMMAND "Add" "Add new customer(s) to the database." HELP 10
      IF addupd_cust("A") THEN
--* Call insert routine which uses error logging
        CALL insert_cust2()
      END IF

      CLEAR FORM
      CALL clear_lines(2,16)
      CALL clear_lines(1,4)

    COMMAND "Query" "Look up customer(s) in the database." HELP 11
      CALL query_cust2() RETURNING st_custs
      IF st_custs IS NOT NULL THEN

--* browse_custs3() calls new version of menu routine called next_action4() 
	CALL browse_custs3(st_custs)
      END IF
      CALL clear_lines(1,4)

    COMMAND KEY ("!")
      CALL bang()

    COMMAND KEY ("E","e","X","x") "Exit" "Exit the program." HELP 100
      EXIT MENU
  END MENU

END FUNCTION  -- cust_menu3 --

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

######################################################################
FUNCTION query_cust2()
######################################################################
--* Purpose: Performs a CONSTRUCT and handles various eventualities.
--*   It returns NULL if the user cancels the query, otherwise it
--*   returns a SELECT statement which may be PREPAREd. This function 
--*   assumes the form f_customer has been displayed, and requires the 
--*   global ga_dsplymsg[] to be defined.
--* Argument(s): NONE
--* Return Value(s): selstmt - the SELECT statement containing the
--*			        WHERE clause with the search criteria
--*				(if the user entered search criteria)
--*			       NULL (if the user terminates with Interrupt)
---------------------------------------
  DEFINE	q_cust		CHAR(100),
		selstmt		CHAR(150)

  CALL clear_lines(1,4)
  DISPLAY "CUSTOMER QUERY-BY-EXAMPLE 2" AT 4, 24
  CALL clear_lines(2, 16)
  DISPLAY 
  " Enter search criteria and press Accept. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Cancel to exit w/out searching."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Set int_flag and allow user to enter search criteria on all 
--*   f_customer fields.  This CONSTRUCT stores resulting WHERE clause 
--*   string in q_cust and specifies help message 30 (from the
--*   "hlpmsgs" file) when user presses CTRL-W from any field.
------------------------
  LET int_flag = FALSE
  CONSTRUCT BY NAME q_cust ON customer.customer_num, customer.company,
			      customer.address1, customer.address2,
			      customer.city, customer.state,
			      customer.zipcode, customer.fname,
			      customer.lname, customer.phone
    HELP 30	

    AFTER CONSTRUCT  -- NOTE: the AFTER CONSTRUCT clause is a 4.1 feature

--* If int_flag is FALSE, then user pressed Accept key to end the
--*   query-by-example. 
------------------------
      IF (NOT int_flag) THEN
 	IF (NOT FIELD_TOUCHED(customer.*)) THEN

--* If no fields have been touched, user did not enter search criteria
--*   and by default WHERE clause will check for all rows.
--* NOTE: the FIELD_TOUCHED() function is a new 4.1 feature.
------------------------
	  LET ga_dsplymsg[1] = "You did not enter any search criteria."
	  IF NOT prompt_window("Do you really want to see all rows?", 9, 15)
 	  THEN

--* If user does not want to see all rows, return to first field and
--*   allow another query-by-example.
--* NOTE: the CONTINUE CONSTRUCT statement is a new 4.1 feature.
------------------------
	    CONTINUE CONSTRUCT
	  END IF
	END IF
      END IF
  END CONSTRUCT

  IF int_flag THEN

--* If the user ended the CONSTRUCT by pressing the Interrupt key,
--*   reset the int_flag, clear the user messages, notify the user,
--*   and return a NULL string for the SELECT statement.
------------------------
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    CALL msg("Customer query terminated.")
    LET selstmt = NULL
  ELSE

--* If the user ended the CONSTRUCT by pressing the Accept key,
--*   create the SELECT statement to find the specified rows
--*   by including the string created by the CONSTRUCT in the
--*   WHERE clause.
------------------------
    LET selstmt = "SELECT * FROM customer WHERE ", q_cust CLIPPED
  END IF
  CALL clear_lines(1,4)
  CALL clear_lines(2,16)

  RETURN (selstmt)

END FUNCTION  -- query_cust2 --


########################################
FUNCTION browse_custs3(selstmt)
########################################
--* Purpose: Prepares and executes the SELECT to find the specified
--*            customer rows then allows user to scroll through selected 
--*            Differs from browse_custs() in Ex 6 by calling
--*            next_action4() instead of next_action() to display menu.
--* Argument(s): selstmt - string containing SELECT statement to
--*			   execute
--* Return Value(s): NONE
---------------------------------------
  DEFINE	selstmt		CHAR(150),

		fnd_custs	SMALLINT,
		end_list	SMALLINT,
		num_found	SMALLINT

  PREPARE st_selcust FROM selstmt

  DECLARE c_cust CURSOR FOR st_selcust

  LET fnd_custs = FALSE
  LET end_list = FALSE
  INITIALIZE gr_workcust.* TO NULL

  FOREACH c_cust INTO gr_customer.*

    LET num_found = SQLCA.SQLERRD[3]
    IF num_found IS NULL THEN
      LET num_found = 0
    END IF
    DISPLAY " Number of Customers Selected: ", num_found USING "<<<<<<"
      AT 14,1 ATTRIBUTE (REVERSE, YELLOW)

    LET fnd_custs = TRUE
    DISPLAY BY NAME gr_customer.*

    IF NOT next_action4() THEN		

--* If next_action4() returns FALSE, then user has chosen "Exit".
--*    Make end_list FALSE because user has chosen "Exit" before the
--*    the last selected row was reached.
------------------------
      LET end_list = FALSE
      EXIT FOREACH
    ELSE

--* If next_action4() returns TRUE, then user has chosen "Next".
--*   Make end_list TRUE to indicate that the user is moving
--*   towards the end of the list of rows
------------------------
      LET end_list = TRUE
    END IF
    LET gr_workcust.* = gr_customer.*
  END FOREACH

  CALL clear_lines(4, 14)

  IF NOT fnd_custs THEN 
    CALL msg("No customers match search criteria.") 
  END IF 

  IF end_list THEN 
    CALL msg("No more customer rows.") 
  END IF 

  CLEAR FORM

END FUNCTION  -- browse_custs3 --

########################################
FUNCTION next_action4()
########################################
--* Purpose: Displays a menu to allow user to choose action on
--*            customer row currently displaying. Differs
--*            from next_action2() in Ex 9 by calling
--*            new versions of update and delete routines.
--*            These new versions include error logging.
--* Argument(s): NONE
--* Return Value(s): TRUE - If user chooses to view next row
--*		     FALSE - If user chooses to change current row
--*			     or exit menu
---------------------------------------
  DEFINE nxt_action 	SMALLINT

  LET nxt_action = TRUE

  MENU "CUSTOMER MODIFICATION"
    COMMAND "Next" "View next selected customer." HELP 20
      EXIT MENU

    COMMAND "Update" "Update current customer on screen."
	HELP 21
      CALL clear_lines(1,14)  -- clear out "number selected" message
      IF addupd_cust("U") THEN
--* Call update routine which uses error logging
        CALL update_cust3()
      END IF
      CALL clear_lines(2,16)
      NEXT OPTION "Next" 
     
    COMMAND "Delete" "Delete current customer on screen."
	HELP 22
      CALL clear_lines(1,14)  -- clear out "number selected" message
--* Call delete routine which uses error logging
      CALL delete_cust2()
      IF gr_workcust.customer_num IS NOT NULL THEN	

	LET gr_customer.* = gr_workcust.*
	DISPLAY BY NAME gr_customer.*
      END IF
      NEXT OPTION "Next" 

    COMMAND KEY ("E","e","X","x") "Exit" "Return to CUSTOMER Menu"
	HELP 24
      LET nxt_action = FALSE
      EXIT MENU
  END MENU

  RETURN nxt_action

END FUNCTION  -- next_action4 --

########################################
FUNCTION addupd_cust(au_flag)
########################################
--* Purpose: Accepts user input for customer information.
--*            Can either accept info for a new customer or
--*	       allow update of existing info.
--* Argument(s): au_flag - "A" to indicate this is a new customer
--*	                   "U" to indicate this is an existing cust
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE 	au_flag		CHAR(1),

		cust_cnt	INTEGER,
		state_code	LIKE customer.state,
		orig_comp	LIKE customer.company

--* Convert argument to upper case and test if it is valid
  LET au_flag = UPSHIFT(au_flag)
  IF au_flag <> "A" AND au_flag <> "U" THEN
    ERROR "Incorrect argument to addupd_cust()."
    EXIT PROGRAM
  END IF

--* Display appropriate screen title and initialize records
  CALL clear_lines(1,4)
  IF au_flag = "A" THEN
    DISPLAY "CUSTOMER ADD" AT 4, 29
    INITIALIZE gr_customer.* TO NULL
  ELSE				--* au_flag = "U"
    DISPLAY "CUSTOMER UPDATE" AT 4, 29
--* Save current values of customer; if update is terminated, can 
--*    then redisplay original values.
------------------------
    LET gr_workcust.* = gr_customer.*
  END IF

  CALL clear_lines(2, 16)
  DISPLAY 
   " Press Accept to save new customer data. Press CTRL-W for Help."
    AT 16,1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY 
   " Press Cancel to exit w/out saving."
    AT 17,1 ATTRIBUTE (REVERSE, YELLOW)

--* The WITHOUT DEFAULTS clause allows INPUT to handle both a
--*  new customer (gr_customer is initialized to NULL) or an
--*  existing customer (gr_customer is initializes with data).
--*  Field validation does not have to be duplicated.
------------------------
  LET int_flag = FALSE
  INPUT BY NAME gr_customer.company, gr_customer.address1,
		gr_customer.address2, gr_customer.city,
		gr_customer.state, gr_customer.zipcode,
		gr_customer.fname, gr_customer.lname, gr_customer.phone 
    WITHOUT DEFAULTS

    BEFORE FIELD company
--* Save company field value before user is able to modify it
	LET orig_comp = gr_customer.company

    AFTER FIELD company
--* Prevent user from leaving company field empty.
      IF gr_customer.company IS NULL THEN
	ERROR "You must enter a company name. Please re-enter."
	NEXT FIELD company
      END IF

      LET cust_cnt = 0

--* Need to validate company name if:
--*    (a) this is an add
--*    (b) this is an update and the user has modified the company
------------------------
      IF (au_flag = "A") 
	OR (au_flag = "U" AND orig_comp <> gr_customer.company) 
      THEN
	SELECT COUNT(*) 
	INTO cust_cnt
	FROM customer
	WHERE company = gr_customer.company

--* Company validation asks for confirmation if the specified company
--*  name already exists in the customer table. User probably doesn't
--*  want two customers with the same name (but might).
------------------------
	IF (cust_cnt > 0) THEN
	  LET ga_dsplymsg[1] = "This company name already exists in the "
	  LET ga_dsplymsg[2] = "              database."
	  IF NOT prompt_window ("Are you sure you want to add another?", 9, 15) 
	  THEN
	    LET gr_customer.company = orig_comp
	    NEXT FIELD company
	  END IF
	END IF
      END IF
	  
    AFTER FIELD lname
--* Make sure user enters a last name if a first name has been entered
      IF (gr_customer.lname IS NULL) AND (gr_customer.fname IS NOT NULL) THEN
	ERROR "You must enter a last name with a first name."
	NEXT FIELD fname
      END IF

    BEFORE FIELD state
--* Display message indicating existence of state popup window.
      MESSAGE 
	"Enter state code or press F5 (CTRL-F) for a list."
      
    AFTER FIELD state
--* Prevent user from leaving empty state field.
      IF gr_customer.state IS NULL THEN
	ERROR "You must enter a state code. Please try again."
	NEXT FIELD state
      END IF

--* Verify that state code entered is valid: does it exist in state
--*   table?
------------------------
      SELECT COUNT(*)
      INTO cust_cnt
      FROM state
      WHERE code = gr_customer.state

      IF (cust_cnt = 0) THEN
	  ERROR 
      "Unknown state code. Use F5 (CTRL-F) to see valid codes."
	  LET gr_customer.state = NULL
	  NEXT FIELD state
      END IF

      MESSAGE ""

    ON KEY (CONTROL-F, F5)
      IF INFIELD(state) THEN
--* If cursor is in state field, implement state popup window,
--*   returning state_code value.
------------------------
	CALL state_popup() RETURNING state_code

--* If state_code is NULL, user did not choose a code from popup
	IF state_code IS NULL THEN
	  NEXT FIELD state
        END IF
--* Display selected code on screen
	LET gr_customer.state = state_code
	DISPLAY BY NAME gr_customer.state

        MESSAGE ""
--* By default, ON KEY returns cursor to state field. Want cursor
--*  to move on to zipcode field.
------------------------
	NEXT FIELD zipcode
      END IF

    ON KEY (CONTROL-W)
--* This ON KEY clause implements field-level help for the f_customer
--*   form. Clause checks current position of cursor and calls
--*   appropriate help message (from "hlpmsgs" file) with the SHOWHELP()
--*   built-in function.
------------------------
      IF INFIELD(company) THEN
        CALL SHOWHELP(50)
      END IF
      IF INFIELD(address1) OR INFIELD(address2) THEN
        CALL SHOWHELP(51)
      END IF
      IF INFIELD(city) THEN
        CALL SHOWHELP(52)
      END IF
      IF INFIELD(state) THEN
        CALL SHOWHELP(53)
      END IF
      IF INFIELD(zipcode) THEN
        CALL SHOWHELP(54)
      END IF
      IF INFIELD(fname) OR INFIELD(lname) THEN
        CALL SHOWHELP(55)
      END IF
      IF INFIELD(phone) THEN
        CALL SHOWHELP(56)
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    IF au_flag = "U" THEN

--* If user pressed Interrupt on an update, return form to its
--*   pre-update values
------------------------
      LET gr_customer.* = gr_workcust.*
      DISPLAY BY NAME gr_customer.*
    END IF
    CALL msg("Customer input terminated.")
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- addupd_cust -- 

########################################
FUNCTION state_popup()
########################################
--* Purpose: Implements the state popup on the f_statesel form. 
--* Argument(s): NONE
--* Return Value(s): code - code of state row chosen
--*                                     OR
--*                              NULL if no state rows exist or
--*                                   user pressed Interrupt key
---------------------------------------
  DEFINE 	pa_state  ARRAY[60] OF RECORD 
		   	code 	LIKE state.code,
		   	sname 	LIKE state.sname
		END RECORD,
		idx 		INTEGER,
		state_cnt	INTEGER,
		array_sz	SMALLINT,
		over_size	SMALLINT

  LET array_sz = 60		--* match size of pa_state array

--* Open new window for popup and display f_statesel form
  OPEN WINDOW w_statepop AT 7, 3
    WITH 15 ROWS, 45 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_statesel FROM "f_statesel"
  DISPLAY FORM f_statesel

--* Display user instructions for popup
  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select a state."
    AT 2,2

--* c_statepop cursor will contain all state rows, ordered by code
  DECLARE c_statepop CURSOR FOR
    SELECT code, sname
    FROM state
    ORDER BY code

  LET over_size = FALSE
  LET state_cnt = 1

--* Read each state row into the pa_state array
  FOREACH c_statepop INTO pa_state[state_cnt].*

--* Increment array index to get ready for next row
    LET state_cnt = state_cnt + 1

--* If new array index is bigger than size of pa_state, set over_size
--*   to TRUE and stop reading state rows
------------------------
    IF state_cnt > array_sz THEN
	LET over_size = TRUE
	EXIT FOREACH
    END IF
  END FOREACH

--* If array index is still one, FOREACH loop never executed: have
--*  no manufact rows in table.
------------------------
  IF state_cnt = 1 THEN
    CALL msg("No states exist in database.")
    LET idx = 1
--* Return a NULL code to indicate no state rows exist
    LET pa_state[idx].code = NULL
  ELSE
--* If over_size is TRUE, notify user that not all rows can display
    IF over_size THEN
	MESSAGE "State array full: can only display ", 
	    array_sz USING "<<<<<<"
    END IF
 
--* Initialize size of program array so ARR_COUNT() can track it
    CALL SET_COUNT(state_cnt - 1)

--* Set int_flag to FALSE to make sure it correctly indicates Interrupt
    LET int_flag = FALSE

--* Display contents of pa_state program array in sa_state screen
--*   array (the screen array is defined within the f_statesel form)
------------------------
    DISPLAY ARRAY pa_state TO sa_state.* 

--* Once the DISPLAY ARRAY ends, obtains last position of cursor
--*   within the array. This position is the selected state.
------------------------
    LET idx = ARR_CURR()

    IF int_flag THEN
      LET int_flag = FALSE
      CALL msg("No state selected.")
--* If user ended DISPLAY ARRAY with Interrupt, return NULL state code
      LET pa_state[idx].code = NULL
    END IF
  END IF

  CLOSE WINDOW w_statepop
--* Use idx as index into program array to get selected code
  RETURN pa_state[idx].code

END FUNCTION  -- state_popup --


########################################
FUNCTION insert_cust2()
########################################
--* Purpose: Adds a new row to the customer table. This version
--*            makes an entry in the error log if the INSERT fails.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Insert a new customer row with values stored in gr_customer global
--*  record.
------------------------
WHENEVER ERROR CONTINUE
  INSERT INTO CUSTOMER 
  VALUES (0, gr_customer.fname, gr_customer.lname, 
	  gr_customer.company, gr_customer.address1, 
	  gr_customer.address2, gr_customer.city, 
	  gr_customer.state, gr_customer.zipcode, 
	  gr_customer.phone)
WHENEVER ERROR STOP

  IF (status < 0) THEN

--* NOTE: Make sure that calls to the log_entry() function pass the
--*       error status as SQLCA.SQLCODE, not "status". Although the
--*       "status" variable is set to the value of SQLCA.SQLCODE after
--*       database statements, it also registers the success of other 
--*       4GL statements. In this case, the ERROR statement will reset
--*       the value of "status" (to 0 is the ERROR is successful). 
--*       The SQLCA.SQLCODE variable only registers the success of 
--*       database-related operations.
------------------------
    ERROR status USING "-<<<<<<<<<<<", ": Unable to complete customer insert."
    CALL log_entry(SQLCA.SQLCODE, "insert_cust2()")   

  ELSE
    LET gr_customer.customer_num = SQLCA.SQLERRD[2]
    DISPLAY BY NAME gr_customer.customer_num

    LET ga_dsplymsg[1] = "Customer has been entered in the database."
    LET ga_dsplymsg[2] = "  Number: ", 
		      gr_customer.customer_num USING "<<<<<<<<<<<", 
		      "  Name: ", gr_customer.company
    CALL message_window(9, 15)
  END IF

END FUNCTION  -- insert_cust2 --

########################################
FUNCTION update_cust3()
########################################
--* Purpose: Updates a single customer row with the contents of the
--*            gr_customer global record. This version
--*            makes an entry in the error log if the UPDATE fails.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

WHENEVER ERROR CONTINUE
  UPDATE customer SET customer.* = gr_customer.*
  WHERE customer_num = gr_customer.customer_num
WHENEVER ERROR STOP

  IF (status < 0) THEN

--* NOTE: Make sure that calls to the log_entry() function pass the
--*       error status as SQLCA.SQLCODE, not "status". Although the
--*       "status" variable is set to the value of SQLCA.SQLCODE after
--*       database statements, it also registers the success of other 
--*       4GL statements. In this case, the ERROR statement will reset
--*       the value of "status" (to 0 is the ERROR is successful). 
--*       The SQLCA.SQLCODE variable only registers the success of 
--*       database-related operations.
------------------------
    ERROR status USING "-<<<<<<<<<<<",
	": Unable to complete customer update."
    CALL log_entry(SQLCA.SQLCODE, "update_cust3()")
  END IF

END FUNCTION  -- update_cust3 --

########################################
FUNCTION delete_cust2()
########################################
--* Purpose: Deletes a single customer row identified by the 
--*            gr_customer global record. This version
--*            makes an entry in the error log if the DELETE fails.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  IF (prompt_window("Are you sure you want to delete this?", 10, 15)) THEN

    IF verify_delete() THEN

WHENEVER ERROR CONTINUE
      DELETE FROM customer 
      WHERE customer_num = gr_customer.customer_num
WHENEVER ERROR STOP

      IF (status < 0) THEN

--* NOTE: Make sure that calls to the log_entry() function pass the
--*       error status as SQLCA.SQLCODE, not "status". Although the
--*       "status" variable is set to the value of SQLCA.SQLCODE after
--*       database statements, it also registers the success of other 
--*       4GL statements. In this case, the ERROR statement will reset
--*       the value of "status" (to 0 is the ERROR is successful). 
--*       The SQLCA.SQLCODE variable only registers the success of 
--*       database-related operations.
------------------------
	ERROR status USING "-<<<<<<<<<<<",
	  ": Unable to complete customer delete."
	CALL log_entry(SQLCA.SQLCODE, "delete_cust2()")
      ELSE
	CALL msg("Customer has been deleted.")
	CLEAR FORM
      END IF
    ELSE
      LET ga_dsplymsg[1] = "Customer ", 
		gr_customer.customer_num USING "<<<<<<<<<<<",
		" has placed orders and cannot be"
      LET ga_dsplymsg[2] = "                  deleted."
      CALL message_window(7, 8)
    END IF
  END IF

END FUNCTION  -- delete_cust2 --

########################################
FUNCTION verify_delete()
########################################
--* Purpose: Checks database for orders and calls for current
--*            customer. Customer is identified by the gr_customer record.
--* Argument(s): NONE
--* Return Value(s): TRUE - no orders or calls exist
--*                  FALSE - orders or calls exist; don't DELETE
---------------------------------------
  DEFINE 	cust_cnt	INTEGER

  LET cust_cnt = 0

--* Count number of orders rows for current customer
  SELECT COUNT(*) 
  INTO cust_cnt
  FROM orders
  WHERE customer_num = gr_customer.customer_num

  IF (cust_cnt IS NOT NULL) AND (cust_cnt > 0) THEN
    RETURN (FALSE)
  END IF

--* Count number of cust_calls rows for current customer
  LET cust_cnt = 0
  SELECT COUNT(*)
  INTO cust_cnt
  FROM cust_calls
  WHERE customer_num = gr_customer.customer_num

  IF (cust_cnt > 0) THEN
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- verify_delete --

  
#######################################
FUNCTION log_entry(errstat, fname)
#######################################
--* Purpose: Makes an entry to the error log file created by
--*            the init_log() function. An entry contains:
--*	          o  the name of the application user at the time of
--*                  the error
--*	          o  the name of the function where the error
--*                  occurred
--*	          o  the value of the status variable
--*	          o  the current ISAM error (if any)
--*	          o  the error message text
--* Argument(s): errstat - the value of the status variable
--*	         fname - the name of the function in which the error
--*                      occurred 
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	errstat 	INTEGER,
		fname		CHAR(20),

		isam_err	INTEGER,	
		errtxt		CHAR(70),
		errline 	CHAR(225),
		uname		CHAR(8)


--* This assignment from SQLCA has to be made before the call to
--* get_user() because the get_user() function performs another database
--* operation. When this database operation is performed, it resets the
--* values of the SQLCA record. This statement saves the value from the
--* previous unsuccessful database access.
------------------------
  LET isam_err = SQLCA.SQLERRD[2]

--* Get the error message text for the status value
  CALL ERR_GET(errstat) RETURNING errtxt

--* Build the error log entry as a string
  LET errline = "User: ", g_username, "      Function: ",
	fname CLIPPED, "\n", "Error Number: ", 
	errstat USING "-<<<<<<<<<<<", "  ISAM Error: ", 
	isam_err USING "-<<<<<<<<<<<", "\n", "Error: ",
	errtxt CLIPPED, "\n", 
	"--------------------------------------------------"

--* Send the error log entry to the error log
  CALL ERRORLOG(errline CLIPPED)

END FUNCTION  -- log_entry --

########################################
FUNCTION get_user()
########################################
--* Purpose: Gets the USER value for the current user.  This 
--*            name can be obtained from the database engine 
--*            by selecting it with the SQL USER function.  
--*            The trick is to select it from a table that is 
--*            sure to exist, in a way that will yield precisely one
--*            row of output.
--* Argument(s): NONE
--* Return Value(s): the name of the current application user
---------------------------------------

    DEFINE uid LIKE informix.sysusers.username

    SELECT USER INTO uid
    FROM informix.systables 	-- table guaranteed to exist
    WHERE tabname = "systables" -- row sure to exist and be singular

    RETURN uid
END FUNCTION  -- get_user --

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

#######################################
FUNCTION prompt_window(question, x,y)
#######################################
--* Purpose: Displays a window containing user-defined text
--*            and a user-defined prompt which can be answered
--*            Yes or No.
--* Argument(s): question - text of prompt for user
--*              x - x coordinate (column) of window's position
--*              y - y coordinate (row) of window's position
--* Return Value(s): NONE
---------------------------------------
  DEFINE question	CHAR(48),
	 x,y		SMALLINT,

	 numrows	SMALLINT,
  	 rownum,i	SMALLINT,
	 answer		CHAR(1),
	 yes_ans	SMALLINT,
	 invalid_resp	SMALLINT,
	 ques_lngth	SMALLINT,
	 unopen		SMALLINT,
	 array_sz	SMALLINT,
	 local_stat	SMALLINT

--* The array_sz variable contains the size of the global message
--*   array, ga_dsplymsg. If the size of this array needs to be
--*   changed in the future, the developer only needs to change
--*   the value of array_sz to update the prompt_window() function 
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
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      LET numrows = numrows + 1
    END IF
  END FOR

--* Repeat attempt to open window until it is successful
  LET unopen = TRUE
  WHILE unopen

--* Set compiler flag so that runtime error checking is turned off
WHENEVER ERROR CONTINUE

--* Open the prompt window at the coordinates passed in as function
--*   arguments. 
------------------------
    OPEN WINDOW w_prompt AT x, y
      WITH numrows ROWS, 52 COLUMNS
      ATTRIBUTE (BORDER, PROMPT LINE LAST)

--* Set compiler flag so that runtime error checking is turned back on
WHENEVER ERROR STOP

--* If OPEN WINDOW was not successful, find out why.
    LET local_stat = status
    IF (local_stat < 0) THEN

--* If status is -1138 or -1144, window coordinates don't fit
--*   on current screen. Change window coordinates to 3,3
------------------------
      IF (local_stat = -1138) OR (local_stat = -1144) THEN
	MESSAGE "prompt_window() error: changing coordinates to 3,3."
	SLEEP 2
	LET x = 3
	LET y = 3
      ELSE

--* If status is any other error, cannot recover
	MESSAGE "prompt_window() error: ", local_stat USING "-<<<<<<<<<<<"
	SLEEP 2
	EXIT PROGRAM
      END IF
    ELSE
      LET unopen = FALSE
    END IF
  END WHILE

  DISPLAY " APPLICATION PROMPT" AT 1, 17
   ATTRIBUTE (REVERSE, BLUE)

--* Display non-null lines of ga_dsplymsg in the message window.
  LET rownum = 3		-- start text display at third line
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      DISPLAY ga_dsplymsg[i] CLIPPED AT rownum, 2
      LET rownum = rownum + 1
    END IF
  END FOR

--* Create prompt message using "question" argument and appending
--*   the string "(n/y)" to the end (if there is room).
------------------------
  LET yes_ans = FALSE
  LET ques_lngth = LENGTH(question)
  IF ques_lngth <= 41 THEN 	-- room enough to add "(n/y): " string
    LET question [ques_lngth + 2, ques_lngth + 7] = "(n/y):" 
  END IF

--* Repeat prompt until user answers either "Y", "y", "N", or "n".
--*   Set yes_ans to TRUE is user answers YES and to FALSE for NO.
------------------------
  LET invalid_resp = TRUE
  WHILE invalid_resp
    PROMPT question CLIPPED, " " FOR answer
    IF answer MATCHES "[nNyY]" THEN
      LET invalid_resp = FALSE
      IF answer MATCHES "[yY]" THEN
	LET yes_ans = TRUE
      END IF
    END IF
  END WHILE

--* Clear out ga_dsplymsg array so it is ready for the next user call
  CALL init_msgs()
  CLOSE WINDOW w_prompt

--* Return user's response: TRUE = Yes, FALSE = No
  RETURN (yes_ans)

END FUNCTION  -- prompt_window --

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
FUNCTION clear_lines(numlines, mrow)
########################################
--* Purpose: Clears out a specified number of lines, starting
--*            at "mrow". 
--* Argument(s): numlines - number of lines to clear
--*              mrow - first row to clear
--* Return Value(s): NONE
---------------------------------------
  DEFINE	numlines	SMALLINT,
		mrow		SMALLINT,

		i		SMALLINT

  FOR i = 1 TO numlines
--* Use mrow to indicate the x coordinate (row) to clear
    DISPLAY 
      "                                                                      "
      AT mrow,1
--* Increment x coordinate by one for next row
    LET mrow = mrow + 1
  END FOR

END FUNCTION  -- clear_lines --


