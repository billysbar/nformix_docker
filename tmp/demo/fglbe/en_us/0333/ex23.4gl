
#######################################################################
# APPLICATION: Example 23 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex23.4gl                            FORM: f_customer.per,     # 
#                                                 f_custkey.per,      # 
#                                                 f_custsel.per       # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program allows the user to see how checks for locking #
#          can be implemented in 4GL. It is intended to be run at     #
#          two terminals as follows:                                  #
#             1. Run ex23 on Terminal 1 and choose the "Lock Table"   #
#                option. This option locks the customer table.        #
#             2. Run ex23 on Terminal 2 and choose the "Lock Table"   #
#                option. With an SE engine, this option fails to lock #
#                the customer table because Terminal 1 has already    #
#                locked it. With an OnLine engine, this option is     #
#                able to lock the table in shared mode but future     #
#                updates will fail (see Step 5).                      #
#             3. On Terminal 2, choose the "Try Update" option and    #
#                specify the number of ties to retry a failed fetch.  #
#             4. On Terminal 2, enter the customer number or company  #
#                name of the customer to update then press Accept.    #
#                The customer info displays on the screen (because    #
#                Terminal 1 has only locked the table in SHARED MODE).#
#             5. On Terminal 2, enter new values for the customer     #
#                on the screen and then press Accept. Because the     #
#                table is locked by another process, the program      #
#                cannot update the customer row. It performs the      #
#                specified number of retrys to acquire the lock,      #
#                waiting for the lock to be released. Because the     #
#                lock from Terminal 1 is not released within the time #
#                taken by these retries, the update fails.            #
#             6. On Terminal 2, choose the "Try Update" option a      #
#                second time and enter the number of retries and the  #
#                desired customer number or name. Modify the data in  #
#                one of the fields but do NOT press Accept yet.       #
#             7. On Terminal 2, press Accept and then immediately     #
#                return to Terminal 1.                                #
#             8. On Terminal 1, choose the "Release Lock" option and  #
#                immediately look at the screen of Terminal 2. You    #
#                will see the Retry messages in Terminal 2 stop once  #
#                the lock is released at Terminal 1. The update is    #
#                able to complete.                                    #
#                                                                     # 
# FUNCTIONS:                                                          #
#   lock_menu() - displays the LOCK DEMO menu to allow user to choose #
#     whether to: lock the customer table, try to update a customer   #
#     row, or release the lock on the customer table.                 #
#   bang() - see description in ex3.4gl                               #
#   lock_cust() - tries to optain a lock on the customer table        #
#     (SHARE MODE).                                                   #
#   try_update() - finds a specified customer and then tries to update#
#     this customer row.                                              #
#   get_repeat() - accepts user input for the number of repeats to    #
#     perform in getting the lock before giving up.                   #
#   open_ckey() - see description in ex21.4gl file.                   #
#   close_ckey() - see description in ex21.4gl file.                  #
#   find_cust() - see description in ex21.4gl file.                   #
#   cust_popup2() - see description in ex12.4gl file.                 #
#   change_cust() - see description in ex6.4gl file.                  #
#   row_locked() - checks the value of SQLCA.SQLERRD[2] to see of the #
#     status value is negative due to a locking conflict. ISAM errors #
#     of: -107, -113, -134, -143, -144, and -154 are treated as       #
#     indications of a locking conflict.                              #
#   update_cust2(number_of_trys) - checks for a locked row before     #
#     updating a customer row. If locked row found, function performs #
#     "number_of_trys" retries to acquire lock before giving up and   #
#     returning an error.                                             #
#   test_success() -- tests the "status" value: returns 1 (if the     #
#     update was successful, 0 (if the update failed with a           #
#     non-locking error, and -1 (if the update failed with a locking  #
#     error).                                                         #
#   clear_lines(numlines,mrow) - see description in ex6.4gl file.     #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  02/11/91    dam             Created the ex23.4gl file              #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE	gr_customer RECORD LIKE customer.*,
		gr_workcust RECORD LIKE customer.*
END GLOBALS

########################################
MAIN
########################################

--* Set help message file to "hlpmsgs" and set up form lines
  OPTIONS
    HELP FILE "hlpmsgs",
    COMMENT LINE LAST-3,
    MESSAGE LINE LAST,
    FORM LINE 5

  DEFER INTERRUPT

--* Open a window for the lock menu 
  OPEN WINDOW w_locktst AT 2,3
    WITH 18 ROWS, 76 COLUMNS
    ATTRIBUTE (BORDER)

--* Display and implement the LOCK MENU
  CALL lock_menu()

  CLOSE WINDOW w_locktst
  CLEAR SCREEN

END MAIN

########################################
FUNCTION lock_menu()
########################################
--* Purpose: Displays the LOCK DEMO menu so the use can test
--*            locking retry.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	curr_tx		SMALLINT,
		another_user	CHAR(1)

  LET another_user = "U"

--* Begin a transaction and set curr_tx to TRUE to indicate
--*   that a transaction is current
------------------------
  BEGIN WORK
  LET curr_tx = TRUE

  DISPLAY 
  "--------------------------------------------Press CTRL-W for Help----------"
    AT 3, 1

--* The LOCK DEMO menu provides options for the user
--*   to test the locking retry. 
--*   Help messages are accessed with CONTROL-W. 
------------------------
  MENU "LOCK DEMO"
      COMMAND "Lock Table" "Lock the customer table." HELP 140

--* If a transaction is not current, start one.
	IF NOT curr_tx THEN
	  BEGIN WORK
	  LET curr_tx = TRUE
	END IF

--* Lock the customer table in SHARED mode
	CALL lock_cust() RETURNING another_user

	NEXT OPTION "Try Update"

      COMMAND "Try Update" "Find and try updating a customer row."
	    HELP 141

--* If a transaction is not current, start one.
	IF NOT curr_tx THEN
	  BEGIN WORK
	  LET curr_tx = TRUE
	END IF

--* Let the user try to update a row in the customer table. If the
--*   update is successful, commit the current transaction. If the 
--*   update fails, roll back the transaction. The success of the 
--*   update depends on whether the customer table is locked by 
--*   another process.
------------------------
	IF try_update() THEN
	  COMMIT WORK
	  CALL msg("Customer has been updated.")
	ELSE
	  ROLLBACK WORK
	  CALL msg("Customer has not been updated.")
	END IF

--* Set curr_tx to FALSE because the transaction is ended (with
--*   COMMIT WORK or ROLLBACK WORK
------------------------
	LET curr_tx = FALSE
	CLEAR WINDOW w_locktst

      COMMAND "Release Lock" "Release lock on customer table."
	    HELP 142

--* If another_user is still "U" (unknown), the user needs to
--*   run the LOCK option so the program can tell if the customer
--*   table is locked by another user.
------------------------
	IF another_user = "U" THEN
	  CALL msg("Status of table lock is unknown. Run 'Lock' option.")
	  NEXT OPTION "Lock Table"
	ELSE
	  IF another_user = "Y" THEN
	    CALL msg("Cannot release another user's lock.")
	  ELSE
	    IF curr_tx THEN
--* To release the lock, commit the transaction.
	      COMMIT WORK
	      LET curr_tx = FALSE
	      CALL msg("Lock on customer table has been released.")
	    END IF
	  END IF
	END IF
	
      COMMAND KEY ("!")
	CALL bang()

      COMMAND KEY ("E", "e", "X", "x") "Exit" "Exit program." 
	    HELP 100

--* If a transaction is current, end it.
	IF curr_tx THEN
	  COMMIT WORK
	END IF
	EXIT MENU
  END MENU

END FUNCTION  -- lock_menu --

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


########################################
FUNCTION lock_cust()
########################################
--* Purpose: Attempts to lock the customer table in SHARED mode.
--*            The success of this attempt is partly dependent of the
--*            database engine used. If the engine is OnLine, the 
--*            SHARED lock request will be successful even if another 
--*            user has locked the table in SHARED mode because 
--*            IBM Informix-OnLine allows multiple shared locks. If, 
--*            however, the database engine is IBM Informix-SE, a SHARED 
--*            lock request fails if another user has locked the 
--*            table (in SHARED or EXCLUSIVE mode).
--* Argument(s): NONE
--* Return Value(s): "N" if the lock is successful
--*                  "Y" if the lock request is not successful
--*                     (table is locked by another process)
---------------------------------------
    DEFINE another_user 	CHAR(1)

    LET another_user = "N"

--* This WHENEVER statement catches the error which occurs if the
--*  program is working with an SE engine and the customer table is 
--*  already locked by another process.
------------------------
WHENEVER ERROR CONTINUE		
    LOCK TABLE customer IN SHARE MODE
WHENEVER ERROR STOP

    IF (status < 0) THEN
--* If table locked by another process, status is -289
      IF status = -289 THEN
	CALL msg("Table is currently locked by another user.")
	LET another_user = "Y"
      ELSE
	ERROR status USING "-<<<<<<<<<<<", 
	  ": Unable to lock customer table."
      END IF
    ELSE
      CALL msg("Customer table is now locked.")
    END IF

    RETURN another_user

END FUNCTION  -- lock_cust --

########################################
FUNCTION try_update()
########################################
--* Purpose: Allows the user to attempt an update on a row of
--*            the customer table.
--* Argument(s): NONE
--* Return Value(s): TRUE - update was successful
--*                  FALSE - update was not successful or
--*			     user cancelled the request
---------------------------------------
  DEFINE	success		SMALLINT,
		number_of_trys	SMALLINT

--* Prompt user for the number of lock retries to perform if
--*   the specified customer row is already locked.
------------------------
  LET number_of_trys = get_repeat()
  IF number_of_trys = 0 THEN
    RETURN FALSE
  END IF

--* Open the f_custkey form in a separate window
  CALL open_ckey()

--* Allow user to select a customer by entering either the
--*   customer number or company name.
------------------------
  LET success = FALSE
  IF find_cust() THEN
--* Close the f_custkey form and open the f_customer form
    CALL close_ckey()

    OPEN FORM f_customer FROM "f_customer"
    DISPLAY FORM f_customer

--* Get specified customer row and store in global record gr_customer
    SELECT *
    INTO gr_customer.*
    FROM customer
    WHERE customer_num = gr_customer.customer_num

--* Store a copy of original values in work buffer
    LET gr_workcust.* = gr_customer.*
    DISPLAY BY NAME gr_customer.*

--* Allow user to modify current values of customer row
    IF change_cust() THEN

--* If values are modified, try to update the customer row.
--*   If the row is already locked, try again for number_of_trys
--*   times.
------------------------
      CALL update_cust2(number_of_trys) RETURNING success
      IF success THEN
        CLEAR FORM
      ELSE
--* If update was not successful, restore original values to screen
        LET gr_customer.* = gr_workcust.*
        DISPLAY BY NAME gr_customer.*
      END IF
    END IF

    CLOSE FORM f_customer
  ELSE
    CALL close_ckey()
  END IF

  RETURN success

END FUNCTION  -- try_update --

########################################
FUNCTION get_repeat()
########################################
--* Purpose: Allows user to input the number of times to
--*            repeat a lock attempt. 
--* Argument(s): NONE
--* Return Value(s): number of retries
---------------------------------------
  DEFINE	invalid_resp	SMALLINT,
		trys		CHAR(2),
		numtrys		SMALLINT

--* Open a new window and prompt for input
  OPEN WINDOW w_repeat AT 6,7
    WITH 3 ROWS, 65 COLUMNS
    ATTRIBUTE (BORDER, PROMPT LINE 3)

  DISPLAY 
  " Enter number of retries and press Accept. Press CTRL-W for Help."
    AT 1, 1 ATTRIBUTE (REVERSE, YELLOW)
  LET invalid_resp = TRUE
  WHILE invalid_resp
    LET int_flag = FALSE
    PROMPT "How many times should I try getting a locked row? "
      FOR trys HELP 143


--* By allowing the input to be character, the program does not 
--*   explode if user enters a letter in the input field (even 
--*   though a letter is not a valid response). To check for 
--*   invalid letters in the input, the program uses data conversion
--*   in the LET statement to convert character answer to an integer.  
--*   The WHENEVER ANY ERROR CONTINUE statement prevents runtime 
--*   error if conversion fails.
--* NOTE: the ANY option of WHENEVER is a new 4.1 feature.
------------------------
WHENEVER ANY ERROR CONTINUE 
    LET numtrys = trys		
WHENEVER ANY ERROR STOP		

    IF (status < 0) THEN	--* encountered conversion error
      ERROR "Please enter a positive integer number"
      CONTINUE WHILE
    END IF

    IF int_flag THEN
--* If user cancels PROMPT, return 0 for number of retries
      LET int_flag = FALSE
      LET numtrys = 0
      EXIT WHILE
    END IF

--* Make sure number of tries is not negative
    IF (numtrys <= 0) THEN	--* integer < 0
      ERROR "Please enter a positive integer number"
      CONTINUE WHILE
    END IF

    LET invalid_resp = FALSE

  END WHILE

  CLOSE WINDOW w_repeat
  RETURN numtrys

END FUNCTION  -- get_repeat --
    
########################################
FUNCTION open_ckey()
########################################
--* Purpose: Opens window and displays f_custkey in this
--*            window.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  OPEN WINDOW w_custkey AT 6,3
   WITH 5 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER, COMMENT LINE 2, FORM LINE FIRST)

  OPEN FORM f_custkey FROM "f_custkey"
  DISPLAY FORM f_custkey

END FUNCTION  -- open_ckey --

########################################
FUNCTION close_ckey()
########################################
--* Purpose: Closes window displaying f_custkey and closes this form
--*            as well.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  CLOSE FORM f_custkey
  CLOSE WINDOW w_custkey

END FUNCTION  -- close_ckey --

########################################
FUNCTION find_cust()
########################################
--* Purpose: Accepts user input for customer key information.
--*            User can identify a customer by entering either
--*	       the customer number or the company name. A popup
--*	       window is available for both these fields.
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE	cust_cnt	SMALLINT

  CALL clear_lines(2, 3)
  DISPLAY " Enter customer number or company name."
    AT 3, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Accept to continue or Cancel to exit."
    AT 4, 1 ATTRIBUTE (REVERSE, YELLOW)

  LET int_flag = FALSE
  INPUT BY NAME gr_customer.customer_num, gr_customer.company

    BEFORE FIELD customer_num
--* Notify user of special popup window for this field
      MESSAGE "Enter a customer number or press F5 (CTRL-F) for a list."

    AFTER FIELD customer_num
      IF gr_customer.customer_num IS NOT NULL THEN
--* Verify that customer number is valid
	SELECT company
	INTO gr_customer.company
	FROM customer
	WHERE customer_num = gr_customer.customer_num

	IF (status = NOTFOUND) THEN
	  ERROR 
"Unknown Customer number. Use F5 (CTRL-F) to see valid customers."
	  LET gr_customer.customer_num = NULL
	  NEXT FIELD customer_num
	END IF

        DISPLAY BY NAME gr_customer.company

	MESSAGE ""

--* If customer number is valid, have identified the customer
--*   and do not need to continue on to the company field.
------------------------
	EXIT INPUT
      END IF

    BEFORE FIELD company
--* Notify user of special popup window for this field
      MESSAGE "Enter a company name or press F5 (CTRL-F) for a list."

    AFTER FIELD company
--* Prevent user from leaving an empty company field. Return cursor
--*   to customer_num so user can choose how to identify the
--*   customer.
------------------------
      IF gr_customer.company IS NULL THEN
	ERROR "You must enter either a customer number or company name."
	NEXT FIELD customer_num
      END IF

--* Verify that company name is valid
      SELECT COUNT(*)
      INTO cust_cnt
      FROM customer
      WHERE company = gr_customer.company

--* If company name is not unique, suggest user identify the customer
--*   by choosing it from the popup window.
------------------------
      IF (cust_cnt > 1) THEN
	  ERROR "Company name is not unique. Press F5 (CTRL-F) for a list."
	  NEXT FIELD company
      END IF

      IF (cust_cnt = 0) THEN
	  ERROR "Unknown company name. Press F5 (CTRL-F) for a list."
	  NEXT FIELD company
      END IF

--* If execution reaches this point, cust_cnt = 1.
      SELECT customer_num
      INTO gr_customer.customer_num
      FROM customer
      WHERE company = gr_customer.company

      DISPLAY BY NAME gr_customer.customer_num
      MESSAGE ""

    ON KEY (F5, CONTROL-F)
--* If cursor is in either the customer_num or the company fields,
--*   implement a customer popup window.
------------------------
      IF INFIELD(customer_num) OR INFIELD(company) THEN

        CALL cust_popup2()
          RETURNING gr_customer.customer_num, gr_customer.company

--* If customer_num is NULL, user did not choose a customer from popup
        IF gr_customer.customer_num IS NULL THEN
	  LET gr_customer.company = NULL
        ELSE
--* Display selected customer on screen and exit
	  DISPLAY BY NAME gr_customer.customer_num, gr_customer.company
	  EXIT INPUT
        END IF
      END IF
	
    AFTER INPUT
--* If user presses Accept without entering a customer number,
--*   prevent the Accept from ending the INPUT
------------------------
      IF (gr_customer.customer_num IS NULL) AND (NOT int_flag) THEN
	ERROR 
  "Cannot continue yet. Enter the customer or press Cancel to exit."
	NEXT FIELD customer_num
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(1, 4)
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- find_cust --

########################################
FUNCTION cust_popup2()
########################################
--* Purpose: Implements the customer popup on the f_custsel form. 
--*            Uses algorithm that enables popup to display rows
--*            in groups which means that the size of the program
--*            array is no longer a restriction on the number of
--*            rows than can be displayed.
--* Argument(s): NONE
--* Return Value(s): customer_num - number of chosen customer row
--*                                     OR
--*                              NULL if no customers rows exist or
--*                                   unable to open cursor or user 
--*                                   pressed Interrupt key
--*                  company - company name of chosen customer row
---------------------------------------
  DEFINE 	pa_cust ARRAY[10] OF RECORD
	           customer_num 	LIKE customer.customer_num,
	           company 		LIKE customer.company
	    	END RECORD,

		idx 		SMALLINT,
		i 		SMALLINT,
		cust_cnt	SMALLINT,
		fetch_custs	SMALLINT,
		array_size	SMALLINT,
		total_custs	INTEGER,
		number_to_see	INTEGER,
		curr_pa		SMALLINT

  LET array_size = 10   	-- match size of pa_order array
  LET fetch_custs = FALSE

--* Verify that customers exist
  SELECT COUNT(*)
  INTO total_custs
  FROM customer

  IF total_custs = 0 THEN
    LET pa_cust[1].customer_num = NULL
    LET pa_cust[1].company = NULL
    RETURN pa_cust[1].customer_num, pa_cust[1].company
  END IF

--* Open new window for popup and display f_custsel form
  OPEN WINDOW w_custpop AT 8, 13
    WITH 12 ROWS, 50 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_custsel FROM "f_custsel"
  DISPLAY FORM f_custsel

  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select a customer."
    AT 2,2

--* Number of rows remaining to display is the total number of customers
  LET number_to_see = total_custs
  LET idx = 0

--* c_custpop cursor will contain all customer rows, ordered by number
  DECLARE c_custpop CURSOR FOR
    SELECT customer_num, company
    FROM customer
    ORDER BY customer_num

WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
  OPEN c_custpop
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

  IF (status = 0) THEN
    LET fetch_custs = TRUE
  ELSE
--* If unable to open cursor, return NULL values
    CALL msg("Unable to open cursor.")
    LET idx = 1
    LET pa_cust[idx].customer_num = NULL
    LET pa_cust[idx].company = NULL
  END IF

  WHILE fetch_custs		-- still have customers to see
    WHILE (idx < array_size)    -- still have room in program array
      LET idx = idx + 1
--* Fetch next customer row into program array
      FETCH c_custpop INTO pa_cust[idx].*
      IF (status = NOTFOUND) THEN		--* no more orders to see
	LET fetch_custs = FALSE
	LET idx = idx - 1
	EXIT WHILE
      END IF
    END WHILE

--* If there are still more to see (after array is full), notify
--*   user of special key sequence to see more orders.
------------------------
    IF (number_to_see > array_size) THEN
      MESSAGE "On last row, press F5 (CTRL-B) for more customers."
    END IF

--* No more rows to see
    IF (idx = 0) THEN
      CALL msg("No customers exist in the database.")
      LET idx = 1
      LET pa_cust[idx].customer_num = NULL
    ELSE

--* Initialize size of program array so ARR_COUNT() can track it
      CALL SET_COUNT(idx)

--* Display contents of pa_cust program array in sa_cust screen
--*   array (the screen array is defined within the f_custsel form)
------------------------
      LET int_flag = FALSE
      DISPLAY ARRAY pa_cust TO sa_cust.* 
	ON KEY (F5, CONTROL-B)
--* These keys implement the "scroll" to the next set of rows. 
	  LET curr_pa = ARR_CURR()

--* If current cursor position (in program array) is the last line
--*   of program array, then decrement number_to_see by number
--*   viewed.
------------------------
	  IF (curr_pa = idx) THEN
	    LET number_to_see = number_to_see - idx
	    IF (number_to_see > 0) THEN

--* If there are still more to see, reset index and return to get
--*   next set of rows
------------------------
	      LET idx = 0
	      EXIT DISPLAY
	    ELSE
	      CALL msg("No more customers to see.")
	    END IF
	  ELSE
--* If current cursor position is not the last line, notify user
--*   that can only move to next set of rows from last line
------------------------
	    CALL msg("Not on last customer row.")
      	    MESSAGE 
	      "On last row, press F5 (CTRL-B) for more customers."
	  END IF
      END DISPLAY

--* If user pressed either Accept or Cancel (not F5 or CONTROL-B), 
--*   exit WHILE loop that fetches more rows
------------------------
      IF (idx <> 0) THEN
        LET idx = ARR_CURR()
	LET fetch_custs = FALSE
      END IF

      IF int_flag THEN		--* user pressed Cancel
	LET int_flag = FALSE
	CALL msg("No customer number selected.")
	LET pa_cust[idx].customer_num = NULL
      END IF

    END IF
  END WHILE
	
  CLOSE FORM f_custsel
  CLOSE WINDOW w_custpop
  RETURN pa_cust[idx].customer_num, pa_cust[idx].company

END FUNCTION  -- cust_popup2 --

########################################
FUNCTION change_cust()
########################################
--* Purpose: Accepts user input for customer information on the 
--*            f_customer form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*		     FALSE - if user ends INPUT with Cancel key
---------------------------------------

  CALL clear_lines(2,16) 
  DISPLAY 
    " Press Accept to save new customer data. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY 
    " Press Cancel to exit w/out saving."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Allow customer to modify customer information. The WITHOUT
--*  DEFAULTS clause causes the form to be initialized with the contents 
--*  of the gr_customer record. The HELP clause specifies that all 
--*  fields on this form display help message 40 (from the "hlpmsgs" 
--*  file) if the user presses CONTROL-W
------------------------
  INPUT BY NAME gr_customer.company, gr_customer.address1, 
		gr_customer.address2, gr_customer.city,
		gr_customer.state, gr_customer.zipcode,
		gr_customer.fname, gr_customer.lname, gr_customer.phone 
  WITHOUT DEFAULTS HELP 40

    AFTER FIELD company
--* Prevent the user from leaving the company field empty.
      IF gr_customer.company IS NULL THEN
	ERROR "You must enter a company name. Please try again."
	NEXT FIELD company
      END IF
  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2,16)
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- change_cust --


########################################
FUNCTION update_cust2(number_of_trys)
########################################
--* Purpose: Updates a single customer row with the contents of the
--*            gr_customer global record. This version of the 
--*            customer row update function uses an update cursor 
--*            to first lock the specified row. If the fetch fails 
--*            because the row is locked by another process, the
--*            function will retry the fetch several times to see
--*            if the lock has been released.
--* Argument(s): number_of_trys - the number of times to repeat
--*                               the FETCH if the row is locked
--*                               by another process.
--* Return Value(s): TRUE - 
---------------------------------------
  DEFINE	number_of_trys	SMALLINT,

		try_again	SMALLINT,
		try		SMALLINT,
		cust_num	LIKE customer.customer_num,
		success		SMALLINT,
		msg_txt		CHAR(78)

--* The c_custlck cursor will contain the customer row currently
--*   identifies by the gr_customer global record. Because this is 
--*   an update cursor, the row will be locked if it is fetched.
------------------------
  DECLARE c_custlck CURSOR FOR
    SELECT customer_num 
    FROM customer
    WHERE customer_num = gr_customer.customer_num
  FOR UPDATE

  LET success = FALSE
  LET try_again = TRUE
  LET try = 0
  WHILE try_again

--* The function uses OPEN instead of FOREACH so it can repeat
--*   the FETCH of a single row.
------------------------
    OPEN c_custlck 

    LET try_again = FALSE

WHENEVER ERROR CONTINUE
    FETCH c_custlck INTO cust_num
WHENEVER ERROR STOP

--* Check the success of the FETCH. 
    CALL test_success(status) RETURNING success

    CASE success 
      WHEN 1  --* FETCH was successful

--* Can update the row because it is locked.
WHENEVER ERROR CONTINUE
        UPDATE customer SET customer.* = gr_customer.*
        WHERE CURRENT OF c_custlck
WHENEVER ERROR STOP

--* If UPDATE fails, notify user
        IF (status < 0) THEN
	  ERROR status USING "-<<<<<<<<<<<",
	    ": Unable to update current customer."
        ELSE
	  LET success = TRUE
        END IF

      WHEN 0  --* FETCH encountered non-locking error
        ERROR status USING "-<<<<<<<<<<",
	  ": Unable to open customer cursor for update."
        SLEEP 3
	LET success = FALSE

      WHEN -1  --* FETCH encountered locked row
--* Increment number of tries already attempted and if there are
--*   still tries to do, notify the user and try again
------------------------
	LET try = try + 1
	IF (try <= number_of_trys) THEN
	  LET msg_txt = "Customer row is locked. Retry #", try USING "<<<"
	  CALL msg(msg_txt CLIPPED)
	  CLOSE c_custlck
          LET try_again = TRUE
	ELSE
	  LET success = FALSE
	END IF
    END CASE

  END WHILE

  CLOSE c_custlck

  RETURN success

END FUNCTION  -- update_cust2 --

########################################
FUNCTION test_success(db_status)
########################################
--* Purpose: Determines if the status of a FETCH indicates:
--*            o  the row has been fetched (status = 0)
--*            o  the row is locked by another process 
--*            o  the FETCH failed, but not due to a locking conflict
--* Argument(s): db_status - the status of the FETCH
--* Return Value(s): 1 - the row has been fetched (status = 0)
--*                  0 - the FETCH failed, but not due to a locking 
--*                          conflict
--*                 -1 - the FETCH failed because the row is locked 
--*                          by another process 
---------------------------------------
DEFINE	db_status	SMALLINT,

	success		SMALLINT

  IF (db_status < 0) THEN	-- FETCH failed
    IF row_locked() THEN	-- encountered a locked row
      LET success = -1
    ELSE			-- encountered non-locking error
      LET success = 0
    END IF
  ELSE   			-- didn't encounter error
    LET success = 1
  END IF

  RETURN success

END FUNCTION  -- test_success --

########################################
FUNCTION row_locked()
########################################
--* Purpose: Checks for various ISAM error codes which can
--*            indicate a failure because the row is already
--*            locked by another process.
--* Argument(s): NONE
--* Return Value(s): TRUE - if row is locked by another process
--*                  FALSE - ISAM value indicates failure, but
--*                            not due to a locked row
---------------------------------------
  DEFINE	locked	SMALLINT

--* Check value of ISAM code in SQLCA record. If, in the future,
--*   you find other ISAM values that indicate a locked row, these
--*   values only need to be added to this CASE statement rather 
--*   than added at each place which checks for a locked row.
------------------------
  CASE SQLCA.SQLERRD[2] 
    WHEN -107		-- record is locked
      LET locked = TRUE
    WHEN -113		-- file is locked
      LET locked = TRUE
    WHEN -134		-- no more locks
      LET locked = TRUE
    WHEN -143		-- deadlock detected
      LET locked = TRUE
    WHEN -144		-- key value locked
      LET locked = TRUE
    WHEN -154		-- deadlock timeout expired
      LET locked = TRUE
    OTHERWISE
      LET locked = FALSE
  END CASE

  RETURN locked

END FUNCTION  -- row_locked --
    
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


