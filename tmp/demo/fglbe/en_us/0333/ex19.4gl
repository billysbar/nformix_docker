
#######################################################################
# APPLICATION: Example 19 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex19.4gl                            FORM: f_customer.per      # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of a scroll cursor to    #
#          let the user browse through a selection of rows.  In this  #
#          example the browse is read-only.  Update/delete with a     #
#          scroll cursor are added in later versions.                 #
#                                                                     # 
# STATEMENTS:                                                         # 
#          BEFORE MENU     HIDE OPTION   SHOW OPTION    NEXT OPTION   # 
#          FETCH FIRST     FETCH LAST    FETCH RELATIVE               # 
#          CASE                                                       # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   scroller_1() - runs the browsing menu, fetching rows on request   #
#   query_cust2() - see discussion in ex6.4gl file.                   #
#   clear_lines(numlines,mrow) - see description in ex6.4gl file.     #
#   init_msgs() - see description in ex2.4gl file.                    #
#   prompt_window(question,x,y) - see description in ex4.4gl file.    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/25/91    dec             create based on ex6                    #
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
  DEFINE	stmt 	CHAR(150),	-- select statement from CONSTRUCT
		more 	SMALLINT	-- continue flag

  DEFER INTERRUPT

--* Set help message file to "hlpmsgs" and set form lines to work
--*   with f_customer form
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 3,
    MESSAGE LINE 19

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer

--* Continue accepting query-by-example until program is cancelled
  LET more = TRUE
  WHILE more

--* Accept user's search criteria and return string with SELECT
    CALL query_cust2() RETURNING stmt
--* If user entered search criteria, prepare the SELECT and run it
    IF stmt IS NOT NULL THEN
	PREPARE prep_stmt FROM stmt
	DECLARE cust_row SCROLL CURSOR FOR prep_stmt
	OPEN cust_row
--* Provide a menu to scroll through selected data
	LET more = scroller_1()	-- Query returns TRUE, Exit returns FALSE
        CLOSE cust_row
    ELSE  -- query was cancelled
        LET more = FALSE
    END IF

  END WHILE

  CLOSE FORM f_customer
  CLEAR SCREEN
END MAIN

########################################
FUNCTION scroller_1()
########################################
--* Purpose: Puts up a menu with scrolling choices: First, Last, 
--*            Prior and Next. Read-ahead logic is used so the 
--*            Prior/Next options can be hidden when the cursor is 
--*            at the end of its range. This function assumes
--*  		o  the form f_customer has been displayed
--*		o  the scroll cursor "cust_row" has been opened
--* Argument(s): NONE
--* Return Value(s): TRUE - if user selects Query (to begin a new
--*			    query) from menu
--*                  FALSE - if user selects Exit from menu
---------------------------------------
  DEFINE 	curr_cust,   -- the row now being displayed
		next_cust,   --	the row to display when Next is chosen
		prior_cust   -- the row to display when Prior is chosen
			RECORD LIKE customer.*,
    		retval,		           -- value to RETURN from function
    		fetch_dir,	           -- flag showing direction of travel 
					   --   in list
		toward_last,	           -- flag values: going Next-wise,
		toward_first	SMALLINT,  -- ...going Prior-wise, or at 
					   -- ...(either) end of the
		at_end		SMALLINT   -- ...of the list

--* Initialize direction constants
    LET toward_last = +1
    LET toward_first = -1
    LET at_end = 0

    DISPLAY 
  "--------------------------------------------Press CTRL-W for Help----------"
      AT 3, 1

--* The View Customers menu provides options for the user
--*   to scroll through the retrieved customer rows.
--*   The menu options which display depend on which ones
--*   can be executed at a point in time. Help messages are 
--*   accessed with CONTROL-W. 
--* NOTE: the BEFORE MENU clause and the SHOW OPTION and HIDE OPTION
--*   statements are new 4.1 features.
------------------------
    MENU "View Customers"

        BEFORE MENU -- Set up as for First, but with chance of zero rows
	    SHOW OPTION ALL 
	    FETCH FIRST cust_row INTO curr_cust.*
	    IF SQLCA.SQLCODE = NOTFOUND THEN
		ERROR "There are no rows that satisfy this query."

--* No matching rows so show only Query and Exit as menu options
		HIDE OPTION ALL
		SHOW OPTION "Query"
		SHOW OPTION "Exit"
		NEXT OPTION "Query"
	    ELSE -- found at least one row
		DISPLAY BY NAME curr_cust.*

--* Hide the "Prior" option because the first row in the set
--*   is displaying (there is no prior).
------------------------
		HIDE OPTION "Prior"

--* Initialize direction of movement through set to "forward"
		LET fetch_dir = toward_last

--* Perform the fetch-ahead to get the next row into the next_cust
--*   record. If there is another row, make "Next" the next option. 
--*   If no other rows exist, hide the "Next" option.
------------------------
		FETCH NEXT cust_row INTO next_cust.*
		IF SQLCA.SQLCODE = 0 THEN	-- at least 2 rows
		    NEXT OPTION "Next"
		ELSE				-- only 1 row in set

--* Only one matching row so show only "Query", "First", "Last" and
--*   "Exit" as options
------------------------
		    HIDE OPTION "Next"
		    NEXT OPTION "Query"
		END IF
	    END IF

---------------
--Query option
---------------
	COMMAND KEY(ESC,Q) "Query"		
		"Query for a different set of customers" HELP 130
	    LET retval = TRUE
	    EXIT MENU

---------------
--First option
---------------
	COMMAND "First"	"Display first customer in selected set"
		HELP 133

--* There is at least one row, but we do not know which row is 
--*   currently on the screen. So fetch the first row into the 
--*   curr_cust record and display it.
------------------------
	    FETCH FIRST cust_row INTO curr_cust.* -- this cannot return 100
	    DISPLAY BY NAME curr_cust.* -- give user something to look at
	    HIDE OPTION "Prior"		-- can't back up from #1

--* Set fetch-ahead directory to "forward"
	    LET fetch_dir = toward_last

--* Perform the "fetch-ahead" into the next_cust record. If no next
--*   row exists, hide the "Next" option.
------------------------
	    FETCH NEXT cust_row INTO next_cust.*
	    IF SQLCA.SQLCODE = 0 THEN	-- at least 2 rows
		SHOW OPTION "Next"	-- it might be hidden
		NEXT OPTION "Next"
	    ELSE			-- only 1 row in set
		HIDE OPTION "Next"
		NEXT OPTION "Query"
	    END IF

---------------
--Next option
---------------
	COMMAND "Next"	"Display next customer in selected set"
		HELP 134

--* Because of fetch-ahead, don't need to fetch to get next row.
--*   Just move data in records so that current row is now in prior_cust
--*   and next row is now in curr_cust. 
------------------------
	    LET prior_cust.* = curr_cust.*
	    SHOW OPTION "Prior"
	    LET curr_cust.* = next_cust.*
	    DISPLAY BY NAME curr_cust.*

--* The whole point of the fetch-ahead is to fetch rows before they 
--*   are actually requested by the user. This feature means that the 
--*   current cursor position in the active set is usually not
--*   at the displayed row. After the "Next" uses up the fetch-ahead
--*   row, want to perform fetch-ahead but must first determine which 
--*   row was last fetched (where the current cursor position is). 
------------------------
	    CASE (fetch_dir)

	      WHEN toward_last
--* If fetch_dir is toward_last, the user is continuing to move
--*   forward through the set (toward the last row). The current
--*   cursor position is one AFTER the displayed row. Fetch-ahead 
--*   can just FETCH NEXT into next_cust
------------------------
		FETCH NEXT cust_row INTO next_cust.*

	      WHEN at_end   
--* If fetch_dir is at_end, the user was moving backward through the
--*   set and had reached the first row before choosing to see the 
--*   next row. The current cursor position is on the first row and 
--*   is pointing to the same row as is being displayed. When the 
--*   user views the the first row in the set, the fetch-ahead cannot 
--*   continue because there are no more rows to fetch in that direction.
--*   When the user changes direction by choosing the next row, a 
--*   FETCH is not required because the row is already in next_cust. 
--*   However, without a FETCH, the current cursor position remains 
--*   unchanged (at the first row). The fetch-ahead cannot just do a 
--*   FETCH NEXT (or FETCH RELATIVE +1) because this would retrieve 
--*   the displayed row. So the fetch-ahead must do a 
--*   FETCH RELATIVE +2 to move out ahead again, skipping over the 
--*   displayed row.
------------------------
    		FETCH RELATIVE +2 cust_row INTO next_cust.*
		LET fetch_dir = toward_last

	      WHEN toward_first
--* If fetch_dir is toward_first, the user was moving backward through 
--*   the set (toward the first row) before choosing to see the next 
--*   row. When the user changes direction by choosing the next row,
--*   a FETCH is not required because the row was already in 
--*   next_cust. The row in curr_cust becomes the new prior_cust.
--*   However, without a FETCH, the current cursor position remains 
--*   unchanged (at the old prior row). The fetch-ahead cannot just do a 
--*   FETCH NEXT (or FETCH RELATIVE +1) because this would retrieve 
--*   the old current row (the new prior row). A FETCH RELATIVE +2 
--*   would just retrieve the old next row (the new displayed row). 
--*   So the fetch-ahead must do a FETCH RELATIVE +3 to move out 
--*   ahead again, skipping forward over both the new rows: prior and 
--*   displayed.
------------------------
    		FETCH RELATIVE +3 cust_row INTO next_cust.*
		LET fetch_dir = toward_last

	    END CASE

	    IF SQLCA.SQLCODE = NOTFOUND THEN

--* Fetch-ahead failed, so the current row is the last one (at the end
--*   of the set). Change the fetch_dir to indicate that the end of the
--*   set has been reached. Hide the "Next" option so the user cannot 
--*   continue to move forward.
------------------------
		LET fetch_dir = at_end
		HIDE OPTION "Next"
		NEXT OPTION "First"
	    END IF
	
---------------
--Prior option
---------------
	COMMAND "Prior"	"Display previous customer in selected set"
		HELP 135

--* Because of fetch-ahead, don't need to fetch to get prior row.
--*   Just move data in records so that current row is now in next_cust
--*   and prior row is now in curr_cust. 
------------------------
	    LET next_cust.* = curr_cust.*
	    SHOW OPTION "Next"
	    LET curr_cust.* = prior_cust.*
	    DISPLAY BY NAME curr_cust.*

--* The whole point of the fetch-ahead is to fetch rows before they 
--*   are actually requested by the user. This feature means that the 
--*   current cursor position in the active set is usually not
--*   at the displayed row. After the "Prior" uses up the fetch-ahead
--*   row, want to perform fetch-ahead but must first determine which 
--*   row was last fetched (where the current cursor position is). 
------------------------
	    CASE (fetch_dir)

	      WHEN toward_first
--* If fetch_dir is toward_first, the user is continuing to move
--*   backward through the set (toward the first row). The current
--*   position is one BEFORE the displayed row. Fetch-ahead can just 
--*   FETCH NEXT into prior_cust
------------------------
		FETCH PRIOR cust_row INTO prior_cust.*

	      WHEN at_end
--* If fetch_dir is at_end, the user was moving forward through the
--*   set and had reached the last row before choosing to see the 
--*   prior row. The current cursor position is on the last row and 
--*   is pointing to the same row as is being displayed. When the 
--*   user views the last row in the set, the fetch-ahead cannot continue 
--*   because there are no more rows to fetch in that direction.
--*   When the user changes direction by choosing the prior row, a 
--*   FETCH is not required because the row is already in prior_cust. 
--*   However, without a FETCH, the current cursor position remains 
--*   unchanged (at the last row). The fetch-ahead cannot just do a 
--*   FETCH PRIOR (or FETCH RELATIVE -1) because this would retrieve 
--*   the displayed row. So the fetch-ahead must do a 
--*   FETCH RELATIVE -2 to move out ahead again, skipping over the 
--*   displayed row.
------------------------
		FETCH RELATIVE -2 cust_row INTO prior_cust.*
		LET fetch_dir = toward_first

	      WHEN toward_last
--* If fetch_dir is toward_last, the user was moving forward through 
--*   the set (toward the last row) before choosing to see the prior 
--*   row. When the user changes direction by choosing the prior row,
--*   a FETCH is not required because the row was already in 
--*   prior_cust. The row in curr_cust becomes the new next_cust.
--*   However, without a FETCH, the current cursor position remains 
--*   unchanged (at the old next row). The fetch-ahead cannot just do a 
--*   FETCH PRIOR (or FETCH RELATIVE -1) because this would retrieve 
--*   the old current row (the new next row). A FETCH RELATIVE -2 
--*   would just retrieve the old prior row (the new displayed row). 
--*   So the fetch-ahead must do a FETCH RELATIVE -3 to move out 
--*   ahead again, skipping backward over both the new rows: next and 
--*   displayed.
------------------------
		FETCH RELATIVE -3 cust_row INTO prior_cust.*
		LET fetch_dir = toward_first

	    END CASE

	    IF SQLCA.SQLCODE = NOTFOUND THEN

--* Fetch-ahead failed, so the current row is the first one (at the end
--*   of the set). Change the fetch_dir to indicate that the end of the
--*   set has been reached. Hide the "Prior" option so the user cannot 
--*   continue to move backward.
------------------------
		LET fetch_dir = at_end
		HIDE OPTION "Prior"
		NEXT OPTION "Last"
	    END IF

---------------
--Last option
---------------
	COMMAND "Last"	"Display final customer in selected set"
		HELP 136

--* There is at least one row, but we do not know which row is 
--*   currently on the screen. So fetch the last row into the 
--*   curr_cust record and display it.
------------------------
	    FETCH LAST cust_row INTO curr_cust.* -- this cannot return 100
	    DISPLAY BY NAME curr_cust.* -- give user something to look at
	    HIDE OPTION "Next"		-- can't go onward from here

--* Set fetch-ahead directory to "backward"
	    LET fetch_dir = toward_first

--* Perform the "fetch-ahead" into the prior_cust record. If no prior
--*   row exists, hide the "Prior" option.
------------------------
	    FETCH PRIOR cust_row INTO prior_cust.*
	    IF SQLCA.SQLCODE = 0 THEN	-- at least 2 rows
		SHOW OPTION "Prior" 	-- it might be hidden
		NEXT OPTION "Prior"
	    ELSE			-- only 1 row in set
		HIDE OPTION "Prior"
		NEXT OPTION "Query"
	    END IF

---------------
--Exit option
---------------
	COMMAND KEY(INTERRUPT,"E", "X") "Exit" "Exit program." HELP 100
	    LET retval = FALSE
	    EXIT MENU
    END MENU
    RETURN retval

END FUNCTION  -- scroller_1 --

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


