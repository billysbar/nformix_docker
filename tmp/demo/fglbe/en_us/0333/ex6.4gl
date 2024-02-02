
#######################################################################
# APPLICATION: Example 6 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex6.4gl                             FORM: f_customer.per      # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of a query-   #
#          by-form on the customer table that allows the user to      #
#          update or delete a row once it is displayed.               #
#                                                                     # 
# STATEMENTS:                                                         # 
#          UPDATE    	                  CONSTRUCT (more complex)    #
#          DELETE    	            	  INPUT WITHOUT DEFAULTS      #
#          MENU - NEXT OPTION             FOREACH                     #
#          OPTIONS - FORM LINE, COMMENT LINE                          #
#                                                                     # 
# FUNCTIONS:                                                          #
#   query_cust2() -  displays the f_customer form for a query-by-form #
#      on the "customer" table and generates a WHERE clause from the  #
#      entered search criteria.                                       #
#   browse_custs(selstmt) - displays results of query on screen, one  #
#      at a time.                                                     #
#   next_action() - displays menu that allows user to choose the      #
#      action to take: see the next row, update the current row, or   #
#      delete the current row.                                        #
#   change_cust() -  allows user to modify values of current customer.#
#   update_cust() - performs database UPDATE of customer.             #
#   delete_cust() - performs database DELETE of customer.             #
#   verify_delete() - checks to see of the customer to be deleted has #
#      any orders in the database. If so, it returns FALSE.           #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   prompt_window(question,x,y) - see description in ex4.4gl file.    #
#   msg(str) - see description in ex5.4gl file.                       #
#   clear_lines(numlines, mrow) - clears "numlines" number of lines   #
#      starting with line "mrow".                                     #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/22/91    dec             Split out functions                    #
#  01/08/91    dam	       Enhanced query_cust2() function        #
#  12/26/90    dam             Added header to file                   #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer 	RECORD LIKE customer.*,
		gr_workcust	RECORD LIKE customer.*

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################
  DEFINE	st_cust		CHAR(150)

--* Set the help file to hlpmsgs, and start the form on the 5th line
--*   of the window. Also set the Comment and Message lines to work with the
--*   f_customer form.
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 5,
    MESSAGE LINE 19

  DEFER INTERRUPT

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer

--* Allow user to enter search criteria on the f_customer form. This
--*  version of the query-by-example returns a string containing the 
--*  SELECT statement to find the specified rows.
------------------------
  CALL query_cust2() RETURNING st_cust
  IF st_cust IS NOT NULL THEN

--* If the user entered search criteria, search for the specified rows
--*   and provide a menu to browse thru the matching rows
------------------------
    CALL browse_custs(st_cust)
  END IF

  CLOSE FORM f_customer
  CLEAR SCREEN
END MAIN

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
FUNCTION browse_custs(selstmt)
########################################
--* Purpose: Prepares and executes the SELECT to find the specified
--*            customer rows then allows user to scroll through selected rows.
--* Argument(s): selstmt - string containing SELECT statement to
--*			   execute
--* Return Value(s): NONE
---------------------------------------
  DEFINE	selstmt		CHAR(150),

		fnd_custs	SMALLINT, -- do matching custs exist?
		end_list	SMALLINT  -- is this the last cust?

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
    LET fnd_custs = TRUE	   -- have found matching rows
    DISPLAY BY NAME gr_customer.*  -- display row on form

    IF NOT next_action() THEN		

--* If next_action() returns FALSE, then user has chosen "Exit".
--*  Make end_list FALSE because user has chosen "Exit" before the
--*  the last selected row was reached
------------------------
      LET end_list = FALSE
      EXIT FOREACH
    ELSE

--* If next_action() returns TRUE, then user has chosen "Next".
--*   Make end_list TRUE to indicate that the user is moving
--*   towards the end of the list of rows
------------------------
      LET end_list = TRUE
    END IF
--* Save the current row in the work buffer before fetching the next
    LET gr_workcust.* = gr_customer.*
  END FOREACH

  CALL clear_lines(2,16)

  IF NOT fnd_custs THEN   -- No matching customer rows
    CALL msg("No customers match search criteria.") 
  END IF 

  IF end_list THEN 	  -- Have reached last row
    CALL msg("No more customer rows.") 
  END IF 

  CLEAR FORM

END FUNCTION  -- browse_custs --

########################################
FUNCTION next_action()
########################################
--* Purpose: Displays a menu to allow user to choose action on
--*            customer row currently displaying. 
--* Argument(s): NONE
--* Return Value(s): TRUE - If user chooses to view next row
--*		     FALSE - If user chooses to change current row
--*			     or exit menu
---------------------------------------
  DEFINE nxt_action 	SMALLINT

  CALL clear_lines(1,16)

  LET nxt_action = TRUE

--* Display help instructions under the menu
  DISPLAY 
    "---------------------------------------Press CTRL-W for Help----------"
    AT 3, 1

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
      IF change_cust() THEN
	CALL update_cust()
	CALL clear_lines(1,16)
      END IF
      NEXT OPTION "Next" 
     
    COMMAND "Delete" "Delete current customer on screen." HELP 22
      CALL delete_cust()
      IF gr_workcust.customer_num IS NOT NULL THEN	

--* There was a previous customer in the list: restore it to the screen
	LET gr_customer.* = gr_workcust.*
	DISPLAY BY NAME gr_customer.*
      ELSE
--* No previous customer exists: clear the gr_customer record
	INITIALIZE gr_customer.* TO NULL
	LET nxt_action = FALSE
	EXIT MENU
      END IF
      NEXT OPTION "Next" 

    COMMAND "Exit" "Exit the program." HELP 100
      LET nxt_action = FALSE
      EXIT MENU
  END MENU

  RETURN nxt_action

END FUNCTION  -- next_action --

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

