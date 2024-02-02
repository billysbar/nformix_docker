
#######################################################################
# APPLICATION: Example 17 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex17.4gl                            FORM: f_customer.per      # 
#                                                 f_statesel.per      # 
#                                                 f_custcall.per      # 
#                                                 f_edit.per          # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of DATETIME fields by    #
#          accessing the cust_calls table. When the user selects the  #
#          "Calls" option from the CUSTOMER MODIFICATION menu, the    #
#          program allows the user to either receive a new call or    #
#          view existing calls.                                       #
#                                                                     # 
# FUNCTIONS:                                                          #
#   cust_menu2() - displays the CUSTOMER menu and allows user to      #
#      choose whether to add a new customer or query for an existing  #
#      customer. Differs from cust_menu1() in ex9.4gl file by calling #
#      browse_custs2() instead of browse_custs1().                    #
#   bang() - see description in ex3.4gl file.                         #
#   query_cust2() - see description in ex6.4gl file.                  #
#   browse_custs2(selstmt) - displays results of query on screen, one #
#      at a time and calls next_action3() to allow user to choose     #
#      next action. Differs from browse_custs1() in ex9.4gl file by   #
#      calling next_action3() intead of next_action2().               #
#   next_action3() - displays menu that allows user to choose the     #
#      action to take: see the next row, update the current row,      #
#      delete the current row, or see customer calls.                 #
#   addupd_cust(au_flag) - see description in ex9.4gl file.           #
#   state_popup() - see description in ex9.4gl file.                  #
#   insert_cust() - see description in ex9.4gl file.                  #
#   update_cust() - see description in ex6.4gl file.                  #
#   delete_cust() - see description in ex6.4gl file.                  #
#   verify_delete() - see description in ex6.4gl file.                #
#   open_calls() - opens the window and displays the form for the     #
#      Customer calls screen (f_custcall).                            #
#   call_menu() - displays the CUSTOMER CALLS menu that allows the    #
#      user to choose whether to receive a new call or update an      #
#      existing call.                                                 #
#   addupd_call(au_flag) - combines the add and update operations on  #
#      the cust_calls table into a single routine. This enables the   #
#      required field validation to be contained in a single routine. #
#   input_call() - accepts user input for customer call information.  #
#   browse_calls(cust_num) - displays customer call info on screen,   #
#      on at a time, then calls nxtact_call() to allow user to choose #
#      next action.                                                   #
#   nxtact_call() - displays CUSTOMER CALL MODIFICATION menu and      #
#      allows user to choose whether to view the next call or update  #
#      the currently displaying call.                                 #
#   get_timeflds(the_dtime) - breaks a DATETIME value into three      #
#      fields: time, AM/PM flag, and date.                            #
#   get_datetime(pr_time,am_pm,yr_mon) - creates a DATETIME value     #
#      from three fields: time, AM/PM flag, and date.                 #
#   init_time() - initializes the time and AM/PM fields to the        #
#      current system time.                                           #
#   edit_descr(edit_flag) - displays a form (f_edit) to allow the     #
#      user to edit a CHAR(240) field.                                #
#   insert_call() - adds a new cust_call row to the database.         #
#   update_call() - performs database UPDATE of cust_call.            #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   prompt_window(question,x,y) - see description in ex4.4gl file.    #
#   msg(str) - see description in ex5.4gl file.                       #
#   clear_lines(numlines,mrow)- see description in ex6.4gl file.      #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/28/91    dam             Created example 17 file                #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer 	RECORD LIKE customer.*,
		gr_workcust	RECORD LIKE customer.*,
		gr_custcalls	RECORD LIKE cust_calls.*,
		gr_viewcall	RECORD
				  customer_num	LIKE customer.customer_num,
				  company	LIKE customer.company,
				  call_time	CHAR(5),
				  am_pm1	CHAR(2),
				  yr_mon1	DATE,
				  user_id	LIKE cust_calls.user_id,
				  call_code	LIKE cust_calls.call_code,
				  call_flag	CHAR(1),
				  res_time	CHAR(5),
				  am_pm2	CHAR(2),
				  yr_mon2	DATE,
				  res_flag	CHAR(1)
				END RECORD,
		gr_workcall	RECORD
				  customer_num	LIKE customer.customer_num,
				  company	LIKE customer.company,
				  call_time	CHAR(5),
				  am_pm1	CHAR(2),
				  yr_mon1	DATE,
				  user_id	LIKE cust_calls.user_id,
				  call_code	LIKE cust_calls.call_code,
				  call_flag	CHAR(1),
				  res_time	CHAR(5),
				  am_pm2	CHAR(2),
				  yr_mon2	DATE,
				  res_flag	CHAR(1)
				END RECORD

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################

--* Set help message file to "hlpmsgs" and then set form-specific
--*   info.
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 5,
    MESSAGE LINE LAST

  DEFER INTERRUPT

  OPEN WINDOW w_main AT 2,3
   WITH 18 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER)

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer
  CALL cust_menu2()

  CLOSE FORM f_customer
  CLOSE WINDOW w_main
  CLEAR SCREEN

END MAIN

########################################
FUNCTION cust_menu2()
########################################
--* Purpose: Displays the CUSTOMER menu so the use can choose
--*            an action on the customer table. Differs from 
--*            cust_menu1() in Ex 9 by calling browse_custs2() 
--*            instead of browse_custs1() in the Query option
--*            to display selected rows.
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
        CALL insert_cust()
      END IF
      CLEAR FORM
      CALL clear_lines(2,16)
      CALL clear_lines(1,4)

    COMMAND "Query" "Look up customer(s) in the database." HELP 11
      CALL query_cust2() RETURNING st_custs
      IF st_custs IS NOT NULL THEN
	CALL browse_custs2(st_custs)
      END IF
      CALL clear_lines(1, 4)

    COMMAND KEY ("!")
      CALL bang()

    COMMAND KEY ("E","e","X","x") "Exit" "Exit the program." HELP 100
      EXIT MENU
  END MENU

END FUNCTION  -- cust_menu2 --

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
FUNCTION browse_custs2(selstmt)
########################################
--* Purpose: Prepares and executes the SELECT to find the specified
--*            customer rows then allows user to scroll through selected 
--*            Differs from browse_custs() in Ex 6 by calling
--*            next_action3() instead of next_action() to display menu.
--* Argument(s): selstmt - string containing SELECT statement to
--*			   execute
--* Return Value(s): NONE
---------------------------------------
  DEFINE	selstmt		CHAR(150),

		fnd_custs	SMALLINT,
		end_list	SMALLINT

--* Create an executable SQL statement from the "selstmt" string
  PREPARE st_selcust FROM selstmt

--* Associate a cursor with the PREPAREd SELECT stmt
  DECLARE c_cust CURSOR FOR st_selcust

  LET fnd_custs = FALSE
  LET end_list = FALSE
  INITIALIZE gr_workcust.* TO NULL

--* Open the c_cust cursor and put the selected values into the
--*   global gr_customer record.
------------------------
  FOREACH c_cust INTO gr_customer.*
    LET fnd_custs = TRUE
    DISPLAY BY NAME gr_customer.*

    IF NOT next_action3() THEN		

--* If next_action3() returns FALSE, then user has chosen "Exit".
--*  Make end_list FALSE because user has chosen "Exit" before the
--*  the last selected row was reached
------------------------
      LET end_list = FALSE
      EXIT FOREACH
    ELSE

--* If next_action3() returns TRUE, then user has chosen "Next".
--*   Make end_list TRUE to indicate that the user is moving
--*   towards the end of the list of rows
------------------------
      LET end_list = TRUE
    END IF
--* Save the current row in the work buffer before fetching the next
    LET gr_workcust.* = gr_customer.*
  END FOREACH

  CALL clear_lines(2, 16)

  IF NOT fnd_custs THEN 
    CALL msg("No customers match search criteria.") 
  END IF 

  IF end_list THEN 
    CALL msg("No more customer rows.") 
  END IF 

  CLEAR FORM

END FUNCTION  -- browse_custs2 --

########################################
FUNCTION next_action3()
########################################
--* Purpose: Displays a menu to allow user to choose action on
--*            customer row currently displaying. Differs
--*            from next_action2() in Ex 9 by having
--*            an option for customer calls "Calls"
--* Argument(s): NONE
--* Return Value(s): TRUE - If user chooses to view next row
--*		     FALSE - If user chooses to change current row
--*			     or exit menu
---------------------------------------
  DEFINE 	nxt_action 	SMALLINT

  LET nxt_action = TRUE

--* The CUSTOMER MODIFICATION menu provides options for the user
--*   to take on the currently displaying customer row.
--*   Help messages are accessed with CONTROL-W. 
------------------------
  MENU "CUSTOMER MODIFICATION"
    COMMAND "Next" "View next selected customer." HELP 20
      EXIT MENU

    COMMAND "Update" "Update current customer on screen." HELP 21
--* If the user updates the customer info on the form, update
--*   the row in the database with the new info
------------------------
      IF addupd_cust("U") THEN
        CALL update_cust()
      END IF
      CALL clear_lines(1,16)
      NEXT OPTION "Next" 
     
    COMMAND "Delete" "Delete current customer on screen." HELP 22
      CALL delete_cust()
      IF gr_workcust.customer_num IS NOT NULL THEN	

--* There was a previous customer in the list: restore it to the screen
	LET gr_customer.* = gr_workcust.*
	DISPLAY BY NAME gr_customer.*
      ELSE
	INITIALIZE gr_customer.* TO NULL
        LET nxt_action = FALSE
	EXIT MENU
      END IF
      NEXT OPTION "Next" 

    COMMAND "Calls" "View this customer's calls." HELP 23
--* Make sure a customer has been selected. If not, tell user
--*   to use "Query" first.
------------------------
      IF gr_customer.customer_num IS NULL THEN
	CALL msg("No customer is current. Please use 'Query'.")
      ELSE
--* If a customer is current, implement the Customer Calls option
	CALL open_calls()
      END IF

    COMMAND KEY ("E","e","X","x") "Exit" "Return to CUSTOMER Menu"
	HELP 24
      LET nxt_action = FALSE
      EXIT MENU
  END MENU

  RETURN nxt_action

END FUNCTION  -- next_action3 --

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
FUNCTION insert_cust()
########################################
--* Purpose: Adds a new row to the customer table. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Insert a new customer row with values stored in gr_customer global
--*  record.
------------------------
WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
  INSERT INTO CUSTOMER 
  VALUES (0, gr_customer.fname, gr_customer.lname, 
	  gr_customer.company, gr_customer.address1, 
	  gr_customer.address2, gr_customer.city, 
	  gr_customer.state, gr_customer.zipcode, 
	  gr_customer.phone)
WHENEVER ERROR STOP -- reset compiler flag to halt on runtime errors

--* If INSERT was not successful, notify user of error number
--*  (in "status").
------------------------
  IF (status < 0) THEN
    ERROR status USING "-<<<<<<<<<<<", ": Unable to complete customer insert."
  ELSE

--* If INSERT was successful, obtain new customer number from the
--*  SERIAL customer_num column. This value is stored in the 
--*  SQLCA built-in record.
------------------------
    LET gr_customer.customer_num = SQLCA.SQLERRD[2]
--* Display new customer number on form.
    DISPLAY BY NAME gr_customer.customer_num

--* Provide special window emphasizing the customer number
    LET ga_dsplymsg[1] = "Customer has been entered in the database."
    LET ga_dsplymsg[2] = "  Number: ", 
		      gr_customer.customer_num USING "<<<<<<<<<<<", 
		      "  Name: ", gr_customer.company
    CALL message_window(9, 15)
  END IF

END FUNCTION  -- insert_cust --

########################################
FUNCTION update_cust()
########################################
--* Purpose: Updates a single customer row with the contents of the
--*            gr_customer global record. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Set the compiler flag so that the program does not perform
--*   error checking after the UPDATE
------------------------
WHENEVER ERROR CONTINUE
  UPDATE customer SET customer.* = gr_customer.*
  WHERE customer_num = gr_customer.customer_num
WHENEVER ERROR STOP	-- reset compiler flag for error checking

--* If UPDATE was not successful, notify user of error number
--*  (in "status").
------------------------
  IF (status < 0) THEN
    ERROR status USING "-<<<<<<<<<<<",
	": Unable to complete customer update."
    RETURN
  END IF

  CALL msg("Customer has been updated.")

END FUNCTION  -- update_cust --

########################################
FUNCTION delete_cust()
########################################
--* Purpose: Deletes a single customer row identified by the 
--*            gr_customer global record. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Prompt the user for confirmation of the DELETE. If successful,
--*  a DELETE cannot be undone.
------------------------
  IF (prompt_window("Are you sure you want to delete this?", 10, 15)) THEN

--* Verify that no orders or calls exist for the customer.
    IF verify_delete() THEN

--* Delete the customer row indicated by the gr_customer global
--*  record.
------------------------
WHENEVER ERROR CONTINUE	-- set compiler flag to ignore runtime errors
      DELETE FROM customer 
      WHERE customer_num = gr_customer.customer_num
WHENEVER ERROR STOP -- reset compiler flag to halt on runtime errors

      IF (status < 0) THEN
	ERROR status USING "-<<<<<<<<<<<",
	  ": Unable to complete customer delete."
      ELSE
	CALL msg("Customer has been deleted.")
	CLEAR FORM
      END IF
    ELSE  
--* Customer has orders or calls and cannot be deleted
      LET ga_dsplymsg[1] = "Customer ", 
		gr_customer.customer_num USING "<<<<<<<<<<<",
		" has placed orders and cannot be"
      LET ga_dsplymsg[2] = "                  deleted."
      CALL message_window(7, 8)
    END IF
  END IF

END FUNCTION  -- delete_cust --

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


########################################
FUNCTION open_calls()
########################################
--* Purpose: Implements the Customer Calls of the CUSTOMER MAINTENANCE
--*            menu.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  OPEN WINDOW w_call AT 2,3
   WITH 18 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER)

  OPEN FORM f_custcall FROM "f_custcall"
  DISPLAY FORM f_custcall

  DISPLAY "CUSTOMER CALLS" AT 4, 29

  DISPLAY BY NAME gr_customer.customer_num, gr_customer.company

--* Display the CUSTOMER CALLS menu 
  CALL call_menu()

  CLOSE FORM f_custcall
  CLOSE WINDOW w_call

END FUNCTION  -- open_calls --

########################################
FUNCTION call_menu()
########################################
--* Purpose: Displays the CUSTOMER CALLS menu and implements
--*            this menu's options.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  DISPLAY 
  "--------------------------------------------Press CTRL-W for Help----------"
    AT 3, 1

--* The CUSTOMER CALLS menu provides options for the user
--*   to take on the currently displaying customer call (cust_calls) 
--*   row. Help messages are accessed with CONTROL-W. 
------------------------
  MENU "CUSTOMER CALLS"
    COMMAND "Receive" "Add a new customer call to the database."
	HELP 70
      CALL addupd_call("A")

    COMMAND "View" "Look at calls for this customer." HELP 71
      CALL browse_calls(gr_customer.customer_num)

    COMMAND KEY ("!")
      CALL bang()

    COMMAND KEY ("E","e","X","x") "Exit" 
	"Return to the CUSTOMER MODIFICATION menu." HELP 72
      EXIT MENU
  END MENU

END FUNCTION  -- call_menu --

########################################
FUNCTION addupd_call(au_flag)
########################################
--* Purpose: Accepts user input for customer call information.
--*            Can either accept info for a new call or
--*	       allow update of an existing call.
--* Argument(s): au_flag - "A" to indicate this is a new call
--*	                   "U" to indicate this is an existing call
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE	au_flag		CHAR(1),

		keep_going	SMALLINT

--* Display user instructions
  DISPLAY 
   " Press Accept to save save call. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY 
   " Press Cancel to exit w/out saving."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Test if argument is valid and initialize records
  IF au_flag = "A" THEN
    INITIALIZE gr_custcalls.* TO NULL
    INITIALIZE gr_viewcall.* TO NULL
    INITIALIZE gr_workcall.* TO NULL
    LET gr_viewcall.yr_mon1 = TODAY
  ELSE			--* au_flag = "U"
    LET gr_workcall.* = gr_viewcall.*
  END IF

  LET gr_viewcall.customer_num = gr_customer.customer_num

--* If user enters call information, prompt user for confirmation
  LET keep_going = TRUE
  IF input_call() THEN
    LET ga_dsplymsg[1] = "Customer call entry complete."
    IF prompt_window("Are you ready to save this customer call?", 
		14, 14)
    THEN
--* If this is a new call, insert it in the cust_calls table
      IF (au_flag = "A") THEN
	CALL insert_call()
	CLEAR call_time, am_pm1, yr_mon1, user_id, call_code,
	      call_flag, res_time, am_pm2, yr_mon2, res_flag

      ELSE			--* au_flag = "U"
--* If this is an existing call, update it in the cust_calls table
	CALL update_call() 
      END IF
    ELSE    --* user doesn't want to update
      LET keep_going = FALSE
    END IF
  ELSE    --* user pressed Cancel/Interrupt
    LET keep_going = FALSE
  END IF

--* Clear fields if they have not yet been cleared (user didn't 
--*   confirm or pressed Cancel key)
------------------------
  IF NOT keep_going THEN
    IF au_flag = "A" THEN
      CLEAR call_time, am_pm1, yr_mon1, user_id, call_code,
      	    call_flag, res_time, am_pm2, yr_mon2, res_flag

    ELSE		--*  au_flag = "U"
      LET gr_viewcall.* = gr_workcall.*
      DISPLAY BY NAME gr_viewcall.*
    END IF
    CALL msg("Customer call input terminated.")
  END IF

  CALL clear_lines(2,16)
END FUNCTION  -- addupd_call --

########################################
FUNCTION input_call()
########################################
  DEFINE	pr_calltime	RECORD
			  	  hrs		SMALLINT,
			  	  mins		SMALLINT
				END RECORD,
		pr_restime	RECORD
			  	  hrs		SMALLINT,
			  	  mins		SMALLINT
				END RECORD,

		edit_fld	LIKE cust_calls.call_descr,
		call_cnt	SMALLINT,
		fld_flag	CHAR(1),
		new_flag	CHAR(1)

--* Clear out the two time records
  INITIALIZE pr_calltime.* TO NULL
  INITIALIZE pr_restime.* TO NULL

  LET int_flag = FALSE
  INPUT BY NAME gr_viewcall.call_time THRU gr_viewcall.res_flag
  WITHOUT DEFAULTS

    BEFORE FIELD call_time
--* Initialize the empty time fields with the current time
      IF gr_viewcall.call_time IS NULL THEN
        CALL init_time() RETURNING gr_viewcall.call_time,
			           gr_viewcall.am_pm1
--* Only need to DISPLAY am_pm1 because call_time is automatically
--*   displayed after this BEFORE FIELD finishes
------------------------
	DISPLAY BY NAME gr_viewcall.am_pm1
      END IF

    AFTER FIELD call_time
--* If user clears field, initialize time fields with the current time
      IF gr_viewcall.call_time IS NULL THEN
        CALL init_time() RETURNING gr_viewcall.call_time,
			           gr_viewcall.am_pm1
        DISPLAY BY NAME gr_viewcall.call_time
      ELSE

--* Verify that hour value is between 0 and 23
        LET pr_calltime.hrs = gr_viewcall.call_time[1,2]
        IF (pr_calltime.hrs < 0) OR (pr_calltime.hrs > 23) THEN
	  ERROR "Hour must be between 0 and 23. Please try again."
	  LET gr_viewcall.call_time[1,2] = "00"
	  NEXT FIELD call_time
        END IF

--* Verify that minute value is between 0 and 59
        LET pr_calltime.mins = gr_viewcall.call_time[4,5]
        IF (pr_calltime.mins < 0) OR (pr_calltime.mins > 59) THEN
	  ERROR "Minutes must be between 0 and 59. Please try again."
	  LET gr_viewcall.call_time[4,5] = "00"
	  NEXT FIELD call_time
        END IF

--* Set am_pm1 to PM when time is in 24-hour notation and is past
--*   12:00 PM
------------------------
        IF pr_calltime.hrs > 12 THEN
	  LET gr_viewcall.am_pm1 = "PM"
	  DISPLAY BY NAME gr_viewcall.am_pm1
	  NEXT FIELD yr_mon1
        END IF
      END IF

    AFTER FIELD am_pm1
--* Verify that flag is valid: A or P. 
      IF (gr_viewcall.am_pm1 IS NULL)
	  OR (gr_viewcall.am_pm1[1] NOT MATCHES "[AP]")
      THEN
	ERROR "Time must be either AM or PM."
	LET gr_viewcall.am_pm1[1] = "A"
	NEXT FIELD am_pm1
      END IF

    BEFORE FIELD yr_mon1
--* Initialize empty field with today's date
      IF gr_viewcall.yr_mon1 IS NULL THEN
	LET gr_viewcall.yr_mon1 = TODAY
      END IF

    AFTER FIELD yr_mon1
--* If user clears field, initialize field with today's date
      IF gr_viewcall.yr_mon1 IS NULL THEN
	LET gr_viewcall.yr_mon1 = TODAY
	DISPLAY BY NAME gr_viewcall.yr_mon1
      END IF

--* Convert call time fields (time, am_pm flag, and date) to a 
--*   DATETIME
------------------------
      CALL get_datetime(pr_calltime.*, gr_viewcall.am_pm1,
			gr_viewcall.yr_mon1)
        RETURNING gr_custcalls.call_dtime

      IF gr_workcall.customer_num IS NULL THEN

--* If this is an insert (not an update), verify whether a row already
--*   exists with this key
------------------------
	SELECT COUNT(*)					
	INTO call_cnt
	FROM cust_calls
	WHERE customer_num = gr_custcalls.customer_num
 	  AND call_dtime = gr_custcalls.call_dtime

	IF (call_cnt > 0) THEN
	  ERROR "This customer already has a call entered for: ", 
	    gr_custcalls.call_dtime
          CALL init_time() RETURNING gr_viewcall.call_time,
			             gr_viewcall.am_pm1
	  NEXT FIELD call_time
	END IF
      END IF

    BEFORE FIELD user_id
--* Initialize empty field with user's UNIX user name
      IF gr_viewcall.user_id IS NULL THEN
  	SELECT USER 
  	INTO gr_viewcall.user_id
  	FROM informix.systables
  	WHERE tabname = "systables"
      END IF

    AFTER FIELD user_id
--* Prevent user from leaving empty user_id field
      IF gr_viewcall.user_id IS NULL THEN
	ERROR "You must enter the name of the person logging the call."
	NEXT FIELD user_id
      END IF

    BEFORE FIELD call_code
--* Notify user of valid codes for this field
      MESSAGE "Valid call codes: B, D, I, L, O"

    AFTER FIELD call_code
--* Prevent user from leaving empty call_code field
      IF gr_viewcall.call_code IS NULL THEN
	ERROR "You must enter a call code. Please try again."
	NEXT FIELD call_code
      END IF

--* Clear message line of call code message
      MESSAGE ""

    BEFORE FIELD call_flag
--* Notify user of special feature to edit description
      MESSAGE "Press F2 (CTRL-E) to edit call description."

      IF gr_workcall.customer_num IS NULL THEN 	--* doing an insert

--* If this is an insert (not an update), automatically display the
--*   Edit form (f_edit) to accept a call description. Once the
--*   edit is complete, display the appropriate call_flag value.
------------------------
	LET gr_viewcall.call_flag = edit_descr("C")
	DISPLAY BY NAME gr_viewcall.call_flag
      END IF

    AFTER FIELD call_flag
--* If no call description has been added, the call_flag should be "N" 
      IF gr_custcalls.call_descr IS NULL 
	  AND (gr_viewcall.call_flag = "Y")
      THEN
	ERROR "No call description exists: changing flag to 'N'."
	LET gr_viewcall.call_flag = "N"
	DISPLAY BY NAME gr_viewcall.call_flag
      END IF

--* If a call description has been added, the call_flag should be "Y" 
      IF gr_custcalls.call_descr IS NOT NULL
	  AND (gr_viewcall.call_flag = "N")
      THEN
	ERROR "A call description exists: changing flag to 'Y'."
	LET gr_viewcall.call_flag = "Y"
	DISPLAY BY NAME gr_viewcall.call_flag
      END IF

      MESSAGE ""

--* Ask user whether to continue on to call resolution fields
      LET ga_dsplymsg[1] = "Call receiving information complete."
      IF prompt_window("Enter call resolution now?", 14, 14) THEN
        NEXT FIELD res_time
      ELSE
	EXIT INPUT
      END IF

    BEFORE FIELD res_time
--* Initialize the empty time fields with the current time
      IF gr_viewcall.res_time IS NULL THEN
        CALL init_time() RETURNING gr_viewcall.res_time,
                                   gr_viewcall.am_pm2

--* Only need to DISPLAY am_pm2 because res_time is automatically
--*   displayed after this BEFORE FIELD finishes
------------------------
	DISPLAY BY NAME gr_viewcall.am_pm2
      END IF

    AFTER FIELD res_time
--* If user clears field, initialize time fields with the current time
      IF gr_viewcall.res_time IS NULL THEN
        CALL init_time() RETURNING gr_viewcall.res_time,
                                   gr_viewcall.am_pm2
      ELSE

--* Verify that hour value is between 0 and 23
        LET pr_restime.hrs = gr_viewcall.res_time[1,2]
        IF (pr_restime.hrs < 0) OR (pr_restime.hrs > 23) THEN
	  ERROR "Hour must be between 0 and 23. Please try again."
	  LET gr_viewcall.res_time[1,2] = "00"
	  NEXT FIELD res_time
        END IF

--* Verify that minute value is between 0 and 59
        LET pr_restime.mins = gr_viewcall.res_time[4,5]
        IF (pr_restime.mins < 0) OR (pr_restime.mins > 59) THEN
	  ERROR "Minutes must be between 0 and 59. Please try again."
	  LET gr_viewcall.res_time[4,5] = "00"
	  NEXT FIELD res_time
        END IF

--* Set am_pm2 to PM when time is in 24-hour notation and is past
--*   12:00 PM
------------------------
        IF pr_restime.hrs > 12 THEN
	  LET gr_viewcall.am_pm2 = "PM"
	  DISPLAY BY NAME gr_viewcall.am_pm2
	  NEXT FIELD yr_mon2
        END IF
      END IF

    AFTER FIELD am_pm2
--* Verify that flag is valid: A or P. 
      IF (gr_viewcall.am_pm2 IS NULL)
	  OR (gr_viewcall.am_pm2[1] NOT MATCHES "[AP]")
      THEN
	ERROR "Time must be either AM or PM."
	LET gr_viewcall.am_pm2[1] = "A"
	NEXT FIELD am_pm2
      END IF

    BEFORE FIELD yr_mon2
--* Initialize empty field with today's date
      IF gr_viewcall.yr_mon2 IS NULL THEN
	LET gr_viewcall.yr_mon2 = TODAY
      END IF

    AFTER FIELD yr_mon2
--* If user clears field, initialize field with today's date
      IF gr_viewcall.yr_mon2 IS NULL THEN
	LET gr_viewcall.yr_mon2 = TODAY
	DISPLAY BY NAME gr_viewcall.yr_mon2
      END IF

--* Verify that resolution date is AFTER call date
      IF gr_viewcall.yr_mon2 < gr_viewcall.yr_mon1 THEN
	ERROR "Resolution date should not be before call date."
	LET gr_viewcall.yr_mon2 = TODAY
	NEXT FIELD yr_mon2
      END IF

    BEFORE FIELD res_flag
--* Notify user of special feature to edit description
      MESSAGE "Press F2 (CTRL-E) to edit resolution description."

      IF gr_workcall.customer_num IS NULL THEN 	--* doing an insert
	LET gr_viewcall.res_flag = edit_descr("R")
	DISPLAY BY NAME gr_viewcall.res_flag
      END IF

    AFTER FIELD res_flag
--* If no call description has been added, the call_flag should be "N" 
      IF gr_custcalls.res_descr IS NULL 
	  AND (gr_viewcall.res_flag = "Y")
      THEN
	ERROR "No resolution description exists: changing flag to 'N'."
	LET gr_viewcall.res_flag = "N"
	DISPLAY BY NAME gr_viewcall.res_flag
      END IF

--* If a call description has been added, the call_flag should be "Y" 
      IF gr_custcalls.res_descr IS NOT NULL
	  AND (gr_viewcall.res_flag = "N")
      THEN
	ERROR "A resolution description exists: changing flag to 'Y'."
	LET gr_viewcall.res_flag = "Y"
	DISPLAY BY NAME gr_viewcall.res_flag
      END IF

      MESSAGE ""

  ON KEY (F2, CONTROL-E)
--* If cursor is in either flag field, implement Edit form (f_edit)
      IF INFIELD(call_flag) OR INFIELD(res_flag) THEN

--* Set fld_flag to indicate which field the edit is for
	IF INFIELD(call_flag) THEN
	  LET fld_flag = "C"
	ELSE		--* user pressed F2 (CTRL-E) from res_flag
	  LET fld_flag = "R"
	END IF

--* Display f_edit form and accept user input. Function returns
--*   value of flag field.
	LET new_flag = edit_descr(fld_flag)

--* Assign new value of flag field to correct flag field
	IF fld_flag = "C" THEN
	  LET gr_viewcall.call_flag = new_flag
	  DISPLAY BY NAME gr_viewcall.call_flag

	ELSE		--* fld_flag = "R", editing Call Resolution

	  LET gr_viewcall.res_flag = new_flag
	  DISPLAY BY NAME gr_viewcall.res_flag
	END IF
      END IF

    ON KEY (CONTROL-W)
--* Implement field-level help for fields of the f_custcalls form.
      IF INFIELD(call_time) OR INFIELD(res_time) THEN
        CALL SHOWHELP(80)
      END IF
      IF INFIELD(am_pm1) OR INFIELD(am_pm2) THEN
        CALL SHOWHELP(81)
      END IF
      IF INFIELD(yr_mon1) OR INFIELD (yr_mon2) THEN
        CALL SHOWHELP(82)
      END IF
      IF INFIELD(user_id) THEN
        CALL SHOWHELP(83)
      END IF
      IF INFIELD(call_code) THEN
        CALL SHOWHELP(84)
      END IF
      IF INFIELD(call_flag) OR INFIELD (res_flag) THEN
        CALL SHOWHELP(85)
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    RETURN (FALSE)
  END IF

--* Complete initialization of gr_custcalls record
  LET gr_custcalls.customer_num = gr_viewcall.customer_num
  LET gr_custcalls.user_id = gr_viewcall.user_id
  LET gr_custcalls.call_code = gr_viewcall.call_code
  
--* Convert resolution time fields (time, am_pm flag, and date) to 
--*   a DATETIME
------------------------
  CALL get_datetime(pr_restime.*, gr_viewcall.am_pm2,
			gr_viewcall.yr_mon2)
    RETURNING gr_custcalls.res_dtime

  RETURN (TRUE)

END FUNCTION  -- input_call --

########################################
FUNCTION browse_calls(cust_num)
########################################
--* Purpose: Prepares and executes the SELECT to find the specified
--*            cust_calls rows then allows user to scroll through selected 
--*            Similar to browse_custs2() function above.
--* Argument(s): cust_num - customer number of customer whose calls
--*			    are being displayed
--* Return Value(s): NONE
---------------------------------------
  DEFINE	cust_num	LIKE customer.customer_num,

		fnd_calls	SMALLINT,
		end_list	SMALLINT

  LET fnd_calls = FALSE
  LET end_list = FALSE

--* Associate a cursor with the SELECT stmt to find customer calls
  DECLARE c_calls CURSOR FOR
    SELECT *
    FROM cust_calls
    WHERE customer_num = cust_num
    ORDER BY call_dtime

--* Open the c_calls cursor and put the selected values into the
--*   global gr_custcalls record.
------------------------
  FOREACH c_calls INTO gr_custcalls.*
    LET fnd_calls = TRUE

--* Initialize gr_viewcall record with values to display
    LET gr_viewcall.customer_num = gr_customer.customer_num
    LET gr_viewcall.company = gr_customer.company
    LET gr_viewcall.user_id = gr_custcalls.user_id
    LET gr_viewcall.call_code = gr_custcalls.call_code

--* Convert DATETIME value of call_dtime to the appropriate values
--*   for the form's call time fields
------------------------
    CALL get_timeflds(gr_custcalls.call_dtime)
      RETURNING gr_viewcall.call_time, gr_viewcall.am_pm1,
		gr_viewcall.yr_mon1

--* Set value of call_flag based on whether current call currently
--*   has a call description 
------------------------
    IF gr_custcalls.call_descr IS NULL THEN
      LET gr_viewcall.call_flag = "N"
    ELSE
      LET gr_viewcall.call_flag = "Y"
    END IF

--* If no resolution time has been entered, initialize resolution 
--*   time fields to null
------------------------
    IF gr_custcalls.res_dtime IS NULL THEN
       LET gr_viewcall.res_time = NULL
       LET gr_viewcall.am_pm2 = "AM"
       LET gr_viewcall.yr_mon2 = TODAY
    ELSE

--* If current call has a resolution time, convert DATETIME value of
--*   res_dtime to the appropriate values form the form's resolution
--*   time fields.
------------------------
      CALL get_timeflds(gr_custcalls.res_dtime)
        RETURNING gr_viewcall.res_time, gr_viewcall.am_pm2, 
		  gr_viewcall.yr_mon2
    END IF

--* Set value of res_flag based on whether current call currently
--*   has a resolution description 
------------------------
    IF gr_custcalls.res_descr IS NULL THEN
      LET gr_viewcall.res_flag = "N"
    ELSE
      LET gr_viewcall.res_flag = "Y"
    END IF

--* Display the form information for the current call
    DISPLAY BY NAME gr_viewcall.*
		    
    IF NOT nxtact_call() THEN		

--* If nxtact_call() returns FALSE, then user has chosen "Exit".
--*  Make end_list FALSE because user has chosen "Exit" before the
--*  the last selected row was reached
------------------------
      LET end_list = FALSE
      EXIT FOREACH
    ELSE

--* If nxtact_call() returns TRUE, then user has chosen "Next".
--*   Make end_list TRUE to indicate that the user is moving
--*   towards the end of the list of rows
------------------------
      LET end_list = TRUE
    END IF
  END FOREACH

  IF NOT fnd_calls THEN 
    CALL msg("No calls exist for this customer.") 
  END IF 

  IF end_list THEN 
    CALL msg("No more customer calls.") 
  END IF 

  CLEAR call_time, am_pm1, yr_mon1, user_id, call_code,
	call_flag, res_time, am_pm2, yr_mon2, res_flag

END FUNCTION  -- browse_calls --

########################################
FUNCTION nxtact_call()
########################################
--* Purpose: Displays a menu to allow user to choose action on
--*            cust_calls row currently displaying. Similar
--*            to the next_action3() function above.
--* Argument(s): NONE
--* Return Value(s): TRUE - If user chooses to view next row
--*		     FALSE - If user chooses to change current row
--*			     or exit menu
---------------------------------------
  DEFINE 	nxt_action 	SMALLINT

  LET nxt_action = TRUE

--* The CUSTOMER CALL MODIFICATION menu provides options for the 
--*   user to take on the currently displaying cust_calls row.
--*   Help messages are accessed with CONTROL-W. 
------------------------
  MENU "CUSTOMER CALL MODIFICATION"
    COMMAND "Next" "View next selected customer call." HELP 90
      EXIT MENU

    COMMAND "Update" "Update current customer call on screen."
	HELP 91
      CALL addupd_call("U")
      NEXT OPTION "Next" 
     
    COMMAND KEY ("!")
      CALL bang()

    COMMAND KEY ("E","e","X","x") "Exit" "Return to CUSTOMER CALLS Menu"
	HELP 92
      LET nxt_action = FALSE
      EXIT MENU
  END MENU

  RETURN nxt_action

END FUNCTION  -- nxtact_call --

########################################
FUNCTION get_timeflds(the_dtime)
########################################
--* Purpose: Converts a DATETIME value to the three time
--*            fields: 
--*	          time_fld - character representation of time (xx:xx)
--*	          am_pm    - flag to indicate AM or PM
--*	          yr_mon   - date 
--*            Inversion operation performed by get_datetime()
--* Argument(s): the_dtime - the DATETIME value to convert
--* Return Value(s): three time fields (see description in Purpose)
---------------------------------------
  DEFINE	the_dtime	DATETIME YEAR TO MINUTE,

		am_pm		CHAR(2),
		yr_mon		DATE,
		time_fld	CHAR(5),
		num_hrs		SMALLINT

--* If the DATETIME is NULL, return three NULL time values
  IF the_dtime IS NULL THEN
    LET time_fld = NULL
    LET am_pm = NULL
    LET yr_mon = NULL
  ELSE  -- DATETIME is not NULL

--* Use 4GL data conversion to extract DATE portion of DATETIME
--*   value.
------------------------
    LET yr_mon = the_dtime

--* Use EXTEND() function to extract time portion of DATETIME
--*   value. Need to index into the time value because it is
--*   a character representation
------------------------
    LET time_fld = "00:00"
    LET time_fld[1,2] = EXTEND(the_dtime, HOUR TO HOUR)
    LET time_fld[4,5] = EXTEND(the_dtime, MINUTE TO MINUTE)

--* Use 4GL data conversion to get an integer representation of
--*   the number of hours in the current time. The integer
--*   value makes the following comparison easier.
------------------------
    LET num_hrs = time_fld[1,2]

--* Convert the 24-hour representation of the time (as stored
--*   in a DATETIME value) into a 12-hour notation and the
--*   am_pm flag.
------------------------
    IF num_hrs >= 12 THEN
      LET am_pm = "PM"
      LET num_hrs = num_hrs - 12
--* If the number of hours has two digits, put both digits into the
--*   character time field. If this number has only one digit, put a
--*   "0" into the left position and the digit into the right one.
      IF num_hrs > 9 THEN
	LET time_fld[1,2] = num_hrs
      ELSE
        LET time_fld[1] = "0"
	LET time_fld[2] = num_hrs
      END IF
    ELSE   -- num_hrs < 12
      LET am_pm = "AM"
      IF num_hrs = 0 THEN
--* Convert 24-hour time of "00:00" to "12:00 AM".
	LET time_fld[1,2] = "12"
      END IF
    END IF
  END IF

  RETURN time_fld, am_pm, yr_mon

END FUNCTION  -- get_timeflds --

########################################
FUNCTION get_datetime(pr_time, am_pm, yr_mon)
########################################
--* Purpose: Converts three time fields into a DATETIME value. Three
--*            time fields are: 
--*	          time_fld - character representation of time (xx:xx)
--*	          am_pm    - flag to indicate AM or PM
--*	          yr_mon   - date 
--*            Inversion operation performed by get_timeflds()
--* Argument(s): three time fields (see description in Purpose)
--* Return Value(s): the DATETIME value for the three time fields
---------------------------------------
  DEFINE	pr_time		RECORD
		  	  	  hrs		SMALLINT,
		  	  	  mins		SMALLINT
				END RECORD,
		am_pm		CHAR(2),
		yr_mon		DATE,

		the_dtime	DATETIME YEAR TO MINUTE


--* If the DATE is NULL, return a NULL DATETIME
  IF yr_mon IS NULL THEN
    LET the_dtime = NULL
  ELSE

--* Use 4GL data conversion to convert DATE to DATETIME
    LET the_dtime = yr_mon	

--* Convert 12:00 AM to "00:00"
    IF am_pm[1] = "A" THEN
      IF pr_time.hrs = 12 THEN
	LET pr_time.hrs = 0
      END IF
    ELSE			--* am_pm = "P"
--* Convert 1:00 PM thru 11:59 PM to 24-hour notation
      IF pr_time.hrs < 12 THEN
	LET pr_time.hrs = pr_time.hrs + 12  --* convert PM to 24-hour time
      END IF
    END IF

--* Store the time value in the DATETIME value (it already contains
--*   the date value). Note use of UNITS function to make sure
--*   hours and minutes are correctly added into DATETIME
------------------------
    LET the_dtime = the_dtime + pr_time.hrs UNITS HOUR   
	+ pr_time.mins UNITS MINUTE    --* add in time  (hours and minutes) 
				       --*  to DATETIME value
  END IF

  RETURN (the_dtime)

END FUNCTION  -- get_datetime --

########################################
FUNCTION init_time()
########################################
  DEFINE	new_time	CHAR(5),
		am_pm		CHAR(2),
		hrs		SMALLINT
 
--* Get current system time in hours to minutes form
  LET new_time = CURRENT HOUR TO MINUTE

--* If 24-hour notation, convert to 12-hour and AM/PM flag
  IF new_time > "12:59" THEN 
    LET hrs = new_time[1,2]
    LET hrs = hrs - 12
    IF hrs > 9 THEN		-- need to put two digits in
      LET new_time[1,2] = hrs
    ELSE			-- need to put only 1 digit in
      LET new_time[1] = 0
      LET new_time[2] = hrs
    END IF
    LET am_pm = "PM"
  ELSE
    LET am_pm = "AM"
  END IF

  RETURN new_time, am_pm

END FUNCTION  -- init_time --

########################################
FUNCTION edit_descr(edit_flg)
########################################
--* Purpose: Accepts user input for description. Can either
--*            accept info for a call description or a
--*	       call resolution description.  
--* Argument(s): edit_flag - "C" to indicate this is a call 
--*                              description
--*	                     "R" to indicate this is a call
--*                              resolution description
--* Return Value(s): value of description flag 
--*                    "Y" - if user has entered a description
--*                    "N" - if user has not entered a descr
---------------------------------------
  DEFINE	edit_flg	CHAR(1),

		edit_str	LIKE cust_calls.call_descr,
		edit_ret	SMALLINT,
		has_value	CHAR(1)

--* Open new window and display the f_edit form
  OPEN WINDOW w_edit AT 3, 11
    WITH 12 ROWS, 60 COLUMNS
    ATTRIBUTE (BORDER, FORM LINE 4, COMMENT LINE 2)

  OPEN FORM f_edit FROM "f_edit"
  DISPLAY FORM f_edit

  DISPLAY " Press Accept to save, Cancel to exit w/out saving."
    AT 1, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Display appropriate form title and initialize value to
--*   edit from appropriate column (call_descr or res_descr)
------------------------
  IF edit_flg = "C" THEN
    DISPLAY "CALL DESCRIPTION"
      AT 3, 24
    LET edit_str = gr_custcalls.call_descr
  ELSE				--* edit_flg = "R"
    DISPLAY "CALL RESOLUTION"
      AT 3, 24
    LET edit_str = gr_custcalls.res_descr
  END IF

--* Accept user input for description
  LET int_flag = FALSE
  INPUT BY NAME edit_str
  WITHOUT DEFAULTS

--* If edit_str is null, then description has no value.
  LET has_value = "Y"
  IF edit_str IS NULL THEN
    LET has_value = "N"
  END IF

  IF int_flag THEN
    LET int_flag = FALSE
  ELSE

--* If user has saved value, store it in appropriate column
--*   (call_descr or res_descr)
------------------------
    IF edit_flg = "C" THEN
      LET gr_custcalls.call_descr = edit_str
    ELSE
      LET gr_custcalls.res_descr = edit_str
    END IF
  END IF

  CLOSE FORM f_edit
  CLOSE WINDOW w_edit

  RETURN has_value

END FUNCTION  -- edit_descr --

########################################
FUNCTION insert_call()
########################################
--* Purpose: Adds a new row to the cust_calls table. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Insert a new cust_calls row with values stored in gr_custcalls 
--*  global record.
------------------------

WHENEVER ERROR CONTINUE
  INSERT INTO cust_calls 
  VALUES (gr_custcalls.*)
WHENEVER ERROR STOP

--* If INSERT was not successful, notify user of error number
--*  (in "status").
------------------------
  IF (status < 0) THEN
    ERROR status USING "-<<<<<<<<<<<", ": Unable to complete customer call ",
	"insert."
  ELSE
    CALL msg("Customer call has been entered in the database.")
  END IF

END FUNCTION  -- insert_call --

########################################
FUNCTION update_call()
########################################
--* Purpose: Updates a single cust_calls row with the contents of the
--*            gr_custcalls global record. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

WHENEVER ERROR CONTINUE
  UPDATE cust_calls SET cust_calls.* = gr_custcalls.*
  WHERE customer_num = gr_custcalls.customer_num
    AND call_dtime = gr_custcalls.call_dtime
WHENEVER ERROR STOP

--* If UPDATE was not successful, notify user of error number
--*  (in "status").
------------------------
  IF (status < 0) THEN
    ERROR status USING "-<<<<<<<<<<<",
	": Unable to complete customer call update."
    RETURN
  END IF

  CALL msg("Customer call has been updated.")

END FUNCTION  -- update_call --

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


