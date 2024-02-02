
#######################################################################
# APPLICATION: Example 20 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex20.4gl                            FORM: f_customer.per,     # 
#                                                 f_answer.per        # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of a scroll cursor to    #
#          let the user browse through a selection of rows.  The      #
#          browse is still read-only.  The user is allowed to refine  #
#          the query by adding more conditions.  This is basically a  #
#          refinement of the design of example 19.                    # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   scroller_2(cond) - an upgrade to scroller_1() discussed in        #
#      example 19: it has a Revise option.                            #
#   query_cust3a() - a refinement of the query_cust2() code           #
#      described in example 6: a subroutine to execute CONSTRUCT and  #
#      return only the relational expression, not a SELECT.           #
#   query_cust3b() - differs from 3a only in the text of the messages #
#      displayed in different cases.                                  #
#   clear_lines(numlines,mrow) - see description in ex6.4gl file.     #
#   answer(msg,ans1,ans2,ans3) - yet another user-alert subroutine,   #
#      presents a question with up to three possible answers, returns #
#      the answer that the user picks.                                #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/28/91    dec             create based on ex6                    #
#######################################################################

DATABASE stores2
                
########################################
MAIN
########################################
  DEFINE	cond CHAR(250),		-- conditional clause from CONSTRUCT
		more SMALLINT		-- continue flag

  DEFER INTERRUPT

--* Set help message file to "hlpmsgs" and set form lines to work
--*   with f_customer form
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 5,
    MESSAGE LINE 19

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer

--* Continue accepting query-by-example until program is cancelled
  LET more = TRUE
  WHILE more

--* Accept user's search criteria and return string with SELECT
    CALL query_cust3a() RETURNING cond
--* If user entered search criteria, prepare the SELECT and run it
    IF cond IS NOT NULL THEN
--* Provide a menu to scroll through selected data
	LET more = scroller_2(cond)	-- Query = TRUE, Exit = FALSE
    ELSE  -- query was cancelled
        LET more = FALSE
    END IF

  END WHILE

  CLOSE FORM f_customer
  CLEAR SCREEN
END MAIN

########################################
FUNCTION scroller_2(cond)
########################################
--* Purpose: Puts up a menu with the following choices: 
--*	        Query: construct a different query
--*	        Revise: bound the query with more AND conditions
--*	        Show-cond: display current query conditions
--*	        First, Last, Prior and Next: scrolling actions.
--*	        Exit: exit the program
--*          Read-ahead logic is used so the Prior/Next options 
--*          can be hidden when the cursor is at the end of its 
--*          range (as in ex19). This function assumes:
--*  		o  the form f_customer has been displayed
--*		o  the scroll cursor "cust_row" has been opened
--* Argument(s): cond - string containing WHERE clause for user's
--*                     search criteria conditions
--* Return Value(s): TRUE - if user selects Query (to begin a new
--*			    query) from menu
--*                  FALSE - if user selects Exit from menu
---------------------------------------
  DEFINE cond		CHAR(250),	-- initial query condition
	 recond,			-- query as extended/constrained
	 selstmt	CHAR(500),      -- full SELECT statement
	 curr_cust,		-- curr_cust: the row now being displayed
	 next_cust,		-- the row to display when Next is chosen
	 prior_cust		-- the row to display when Prior is chosen
			RECORD LIKE customer.*,
    	 retval,		-- value to RETURN from function
    	 fetch_dir,		-- flag showing direction of travel in list
	 using_next,		-- flag values: going fwd using fetch next,
	 using_prior,		    -- ...going bwd using fetch prior, or
	 at_end		SMALLINT    -- ...at either end of the list
			

--* Initialize direction constants
  LET using_next = +1
  LET using_prior = -1
  LET at_end = 0
  LET recond = cond	-- initialize query condition

  LET retval = 99	-- neither TRUE nor FALSE

  WHILE retval <> TRUE AND retval <> FALSE -- i.e. while not Query or Exit

    LET selstmt = "SELECT * FROM customer WHERE ",
	recond CLIPPED, " ORDER BY customer_num"
    PREPARE prep_stmt FROM selstmt
    DECLARE cust_row SCROLL CURSOR FOR prep_stmt
    OPEN cust_row

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
		LET fetch_dir = using_next

--* Perform the fetch-ahead to get the next row into the next_cust
--*   record. If there is another row, make "Next" the next option. 
--*   If no other rows exist, hide the "Next" option.
------------------------
		FETCH NEXT cust_row INTO next_cust.*
		IF SQLCA.SQLCODE = 0 THEN	-- at least 2 rows
		    NEXT OPTION "Next"
		ELSE				-- only 1 row in set
		    HIDE OPTION "Next"
		    NEXT OPTION "Query"
		END IF
	    END IF

---------------
--Query option
---------------
	COMMAND KEY(ESC,Q) "Query"		
		"Query for a different set of customers." HELP 130
	    LET retval = TRUE
	    EXIT MENU

---------------
--Revise option
---------------
	COMMAND "Revise" "Apply more conditions to current query."
		HELP 131
--* Allow user to enter qualifying search criteria
	    CALL query_cust3b() RETURNING cond

--* If search criteria entered, build new WHERE clause with
--*   conditions for initial search AND new qualifying conditions
------------------------
	    IF cond IS NOT NULL THEN -- some condition entered
		LET recond = recond CLIPPED, " AND ", cond CLIPPED
		EXIT MENU 	-- close and re-open the cursor
	    ELSE 	-- CONSTRUCT clears form, refresh the display
		DISPLAY BY NAME curr_cust.*
	    END IF

---------------
--Show-cond option
---------------
	COMMAND "Show-cond" "Display the current query conditions."
		HELP 132
	    CALL answer(recond CLIPPED,"","","")

---------------
--First option
---------------
	COMMAND "First" "Display first customer in selected set."
		HELP 133

--* There is at least one row, but we do not know which row is 
--*   currently on the screen. So fetch the first row into the 
--*   curr_cust record and display it.
------------------------
	    FETCH FIRST cust_row INTO curr_cust.* -- this cannot return 100
	    DISPLAY BY NAME curr_cust.* -- give user something to look at
	    HIDE OPTION "Prior"		-- can't back up from #1

--* Set fetch-ahead directory to "forward"
	    LET fetch_dir = using_next

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
	COMMAND "Next" "Display next customer in selected set."
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

	      WHEN using_next
--* If fetch_dir is using_next, the user is continuing to move
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

	      WHEN using_prior
--* If fetch_dir is using_prior, the user was moving backward through 
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
	    ELSE
		LET fetch_dir = using_next
	    END IF
	
---------------
--Prior option
---------------
	COMMAND "Prior"	"Display previous customer in selected set."
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

	      WHEN using_prior
--* If fetch_dir is using_prior, the user is continuing to move
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

	      WHEN using_next
--* If fetch_dir is using_next, the user was moving forward through 
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
	    ELSE
		LET fetch_dir = using_prior
	    END IF

---------------
--Last option
---------------
	COMMAND "Last" "Display final customer in selected set."
		HELP 136

--* There is at least one row, but we do not know which row is 
--*   currently on the screen. So fetch the last row into the 
--*   curr_cust record and display it.
------------------------
	    FETCH LAST cust_row INTO curr_cust.* -- this cannot return 100
	    DISPLAY BY NAME curr_cust.* -- give user something to look at
	    HIDE OPTION "Next"		-- can't go onward from here

--* Set fetch-ahead directory to "backward"
	    LET fetch_dir = using_prior

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
    CLOSE cust_row
  END WHILE { retval neither FALSE nor TRUE, re-open cursor }

  RETURN retval

END FUNCTION  -- scroller_2 --

######################################################################
# >> These functions assume the form f_customer has been displayed.
######################################################################

########################################
FUNCTION query_cust3a() -- used for initial query
########################################
--* Purpose: Performs a CONSTRUCT so the user can enter initial     
--*            search criteria. This function assumes the form 
--*            f_customer has been displayed.
--* Argument(s): NONE
--* Return Value(s): q_cust - the string containing the WHERE
--*			        clause with the search criteria
--*				(if the user entered search criteria)
--*			       NULL (if the user terminates with Interrupt)
---------------------------------------
  DEFINE	q_cust		CHAR(120),
		msgtxt		CHAR(150)

  CALL clear_lines(1,4)
  DISPLAY "CUSTOMER QUERY-BY-EXAMPLE 2" 
    AT 4, 24
  CALL clear_lines(2, 16)
  DISPLAY 
  " Enter search criteria and press Accept. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Cancel to exit w/out searching."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Set int_flag and allow user to enter initial search criteria in all 
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

--* If no fields have been touched, user did not enter search criteria
--*   and by default WHERE clause will check for all rows.
--* NOTE: the FIELD_TOUCHED() function is a new 4.1 feature.
------------------------
 	IF (NOT FIELD_TOUCHED(customer.*)) THEN
	  LET msgtxt = "You did not enter any search criteria. ",
			"Do you really want to select all rows?"
	  IF "No-revise" = answer(msgtxt,"Yes-all","No-revise","")
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
    LET int_flag = FALSE
    CALL clear_lines(2,16)
    CALL msg("Customer query terminated.")

--* If the user ended the CONSTRUCT by pressing the Interrupt key,
--*   return a NULL string for the WHERE clause.
------------------------
    LET q_cust = NULL
  END IF
  CALL clear_lines(1,4)
  CALL clear_lines(2,16)

  RETURN (q_cust)

END FUNCTION  {query_cust3a}

######################################################################
FUNCTION query_cust3b()
######################################################################
--* Purpose: Performs a CONSTRUCT so the user can enter additional     
--*            search criteria. This function assumes the form 
--*            f_customer has been displayed.
--* Argument(s): NONE
--* Return Value(s): q_cust - the string containing the WHERE
--*			        clause with the search criteria
--*				(if the user entered search criteria)
--*			       NULL (if the user terminates with Interrupt)
---------------------------------------
  DEFINE	q_cust		CHAR(120),
		msgtxt		CHAR(150)

  CALL clear_lines(1,4)
  DISPLAY "CUSTOMER QUERY-BY-EXAMPLE: Additional Conditions" AT 4, 14
  CALL clear_lines(2, 16)
  DISPLAY 
  " Enter additional criteria and press Accept. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Cancel to exit w/out changing query."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Set int_flag and allow user to enter additional search criteria in
--*   all f_customer fields.  This CONSTRUCT stores resulting WHERE 
--*   clause string in q_cust and specifies help message 30 (from the
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

--* If no fields have been touched, user did not enter search criteria
--*   and by default WHERE clause will check for all rows.
--* NOTE: the FIELD_TOUCHED() function is a new 4.1 feature.
------------------------
 	IF (NOT FIELD_TOUCHED(customer.*)) THEN
	  LET msgtxt = "You did not enter any search criteria. ",
			"Did you mean to add no new conditions?"
	  IF "No-revise" = answer(msgtxt,"Yes-all","No-revise","")
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
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    CALL msg("No new conditions added.")
    LET q_cust = " 1=1" -- same as Accept w/o touching fields
  END IF

--* If the user ended the CONSTRUCT by pressing the Interrupt key,
--*   return a NULL string for the WHERE clause.
------------------------
  IF q_cust = " 1=1" THEN
    LET q_cust = NULL
  END IF

  CALL clear_lines(1,4)
  CALL clear_lines(2, 16)

  RETURN (q_cust)

END FUNCTION  -- query_cust3b --

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
FUNCTION answer(msg,ans1,ans2,ans3)
########################################
--* Purpose: This function is modeled on the Answer command of 
--*            Hypercard: It opens an "alert box" with a question, 
--*            and prompts for one, two or three possible answers.  
--*            These possible responses are displayed as:
--*
--*                "Choose <ans1>[[, <ans2>] or <ans3>]: (XYZ) " 
--*
--*            where (XYZ) shows the initial letters of the choices.
--*            The user is prompted until one of these letters has 
--*            been typed.  Then the matching answer is returned as 
--*            the function value.  For example:
--*
--*  	       LET flag = answer("Should I or should I not?","Yes","No")
--*
--*            prompts the user with:
--*                           "Choose Yes or No: (YN)" 
--*            and the function will return either "Yes" or "No".
--*
--*          By setting the ans1 argument to NULL, this function can 
--*            also be called to provide a default prompt:
--*
--*              "Press RETURN to continue."  
--*
--*          For example:
--*    		   CALL answer("\n\tLook out behind you!","","","")
--*
--* Argument(s): msg - a message with up to 200 characters.  It 
--*                    is displayed in four rows of 50 characters.  
--*                    It may contain tab (\t) and newline (\n) 
--*                    characters for formatting.  However the 
--*                    display is a WORDWRAP field so no special 
--*                    formatting is really required.
--*              ans1 - NULL: to display the default prompt 
--*                         "Press RETURN to continue."  
--*				    OR
--*                     non-empty string: first possible choice for
--*                       answer 
--*              ans2 - NULL: if ans1 is NULL
--*                              OR
--*                     second possible choice for answer
--*              ans3 - NULL: if ans1 is NULL
--*                              OR
--*                     third possible choice for answer
--* Return Value(s): nothing - if ans1 is NULL and default prompt
--*                               is used
--*                  the answer chosen by the user (ans1, ans2, or
--*                     ans3)
---------------------------------------
  DEFINE msg 			CHAR(255),  -- input text for display
	 ans1,ans2,ans3 	CHAR(10),   -- possible user responses or nulls
	 inp 			CHAR(1),    -- user's one-character reply
	 j 			SMALLINT,   -- misc index
	 codes 			CHAR(5),    -- match string [abc]
	 choose 		CHAR(50)    -- prompt string

--* Open a special window for the f_answer form
    OPEN WINDOW ans_win AT 10,10 
      WITH FORM "f_answer"
      ATTRIBUTE(BORDER,PROMPT LINE LAST,FORM LINE FIRST)
    DISPLAY msg TO msgtext
    
--* Make a class of the valid responses
    LET codes = "[",UPSHIFT(ans1[1]),
		    UPSHIFT(ans2[1]),
		    UPSHIFT(ans3[1]), "]"
    
    IF LENGTH(ans1) = 0 THEN -- all-blank or null
	PROMPT "Press RETURN to continue: " FOR inp
    ELSE

--* Build prompt with possible responses
	LET choose = "Choose ",ans1 CLIPPED
	IF (LENGTH(ans2) * LENGTH(ans3)) <> 0 THEN -- both given
	    LET choose = choose CLIPPED, ", ", ans2 CLIPPED, 
		" or ", ans3 CLIPPED
	ELSE -- not both ans2 and ans3, possibly neither
	    IF LENGTH(ans2) <> 0 THEN
		LET choose = choose CLIPPED, " or ", ans2 CLIPPED
	    END IF
	END IF

--* Prompt user with the prompt text and continue until a valid
--*   response is entered
------------------------
	LET inp = "\n" -- one thing a user cannot enter at a prompt
	WHILE NOT UPSHIFT(inp) MATCHES codes
	    PROMPT choose CLIPPED, " ",codes,": " FOR inp
	END WHILE
    END IF
    CLOSE WINDOW ans_win

--* If prompt contained possible responses, check for the 
--*   responses that was entered and return it.
------------------------
    IF LENGTH(ans1) <> 0 THEN
	CASE
	    WHEN UPSHIFT(inp) = UPSHIFT(ans1[1]) 
		LET choose = ans1
	    WHEN UPSHIFT(inp) = UPSHIFT(ans2[1]) 
		LET choose = ans2
	    WHEN UPSHIFT(inp) = UPSHIFT(ans3[1]) 
		LET choose = ans3
	END CASE
	RETURN choose
    END IF
END FUNCTION  -- answer --

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

