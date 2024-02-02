
#######################################################################
# APPLICATION: Example 27 - 4GL Examples Manual                       #
#                                                                     #
# FILE: ex27.4gl                            FORM: f_customer.per,     #
#                                                 f_answer.per        #
#                                                                     #
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of a scroll cursor to    #
#          browse and modify a selection of rows.  The browsing is    #
#          the same as example 19 or 20.  Insert, Update and Delete   #
#          menu choices are also enabled provided that the user has   #
#          has been granted the privileges to do those actions, as    #
#          shown in the system catalog table, systabauth.             #
#                                                                     #
# FUNCTIONS:                                                          #
#   query_cust3a() - constructs a query on the customer table, as     #
#      discussed in example 20.                                       #
#   query_cust3b() - constructs an added query; see ex. 20.           #
#   scroller_3(start_cond) - a further upgrade to scroller_1() of     #
#      example 19 and scroller_2() of ex. 20. It uses ROWIDs to       #
#      track rows, allows updates and deletes, and handles            #
#      asynchronous changes in the database by other users running    #
#      concurrently.                                                  #
#   disp_row(rid) - display the specified row but first check that it #
#                   still exists and matches the query constraints    #
#   del_row(rid) -  delete the specified row, first checking that it  #
#                   still exists and matches the query constraints    #
#   upd_row(rid) -  update the specified row, first checking that it  #
#                   still exists and matches the query constraints    #
#   answer() - see description in ex20.4gl file.                      #
#   clear_lines(numlines, x) - see description in ex6.4gl file.       #
#   like() - see description in ex24.4gl file                         #
#   open_db() - see description in ex22.4gl file.                     #
#   begin_wk() - see description in ex22.4gl file.                    #
#   commit_wk() - see description in ex22.4gl file.                   #
#   rollback_wk() - see description in ex22.4gl file.                 #
#   get_user() -  return the value of the USER string.                #
#   get_tab_auth() - return this user's privileges with respect to a  #
#                    specified table.                                 #
#   sel_merged_auth() - selects all privileges and returns the        #
#      superset of privileges. Since the key to systabauth is         #
#      grantor+grantee+tabid, a given grantee may have multiple       #
#      grants for a given table.                                      #
#   merge_auth() - returns the superset of two tabauth strings,       #
#      retaining any letter in preference to a hyphen, and uppercase  #
#      letters in preference to lower.                                #
#                                                                     # 
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/31/91    dec             create based on ex19                   #
#######################################################################

DATABASE stores2

GLOBALS
# used by open_db.sub, begin_wk.sub, commit_wk.sub, rollback_wk.sub
  DEFINE gr_database RECORD
--* These fields are set to TRUE or FALSE by the open_db() function
--*    based on the values in SQLAWARN following a database statement.
		       db_known   SMALLINT, -- following fields are usable
		       has_log    SMALLINT, -- based on SQLAWARN[2]
		       is_ansi    SMALLINT, -- based on SQLAWARN[3]
		       is_online  SMALLINT, -- based on SQLAWARN[4]
		       can_wait   SMALLINT  -- supports "set lock mode to wait"
    		     END RECORD


END GLOBALS

# Module variables shared by scroller_3() and disp_row()
DEFINE    m_querycond CHAR(500),             -- current query condition text
          mr_currcust  RECORD LIKE customer.* -- current row contents

########################################
MAIN
########################################
  DEFINE  cond 		CHAR(150),          -- conditional clause from CONSTRUCT
	  more 		SMALLINT,           -- continue flag
	  dbname 	CHAR(10)

  DEFER INTERRUPT

  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 5,
    COMMENT LINE 5,
    MESSAGE LINE 19

  OPEN WINDOW w_db AT 2, 3
    WITH 4 ROWS, 65 COLUMNS
    ATTRIBUTE (BORDER, PROMPT LINE 3)

--* Accept name of database 
  DISPLAY "Enter name of standard demo database, or press RETURN to"
   AT 2,2
  LET int_flag = FALSE
  PROMPT "   use 'stores2' database: " FOR dbname
  IF int_flag THEN
    LET int_flag = FALSE
    CLOSE WINDOW w_db
    EXIT PROGRAM
  END IF

  CLOSE WINDOW w_db
--* If user just pressed RETURN, use default database: stores2
  IF LENGTH(dbname)=0 THEN 
    LET dbname = "stores2" 
  END IF
  IF open_db(dbname)=FALSE THEN   -- open db, find out about logging
    DISPLAY "Unable to open that database, sorry." AT 20,1
    EXIT PROGRAM
  END IF

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer

  LET more = TRUE
  WHILE more

--* Accept user search criteria on f_customer
    CALL query_cust3a() RETURNING cond
    IF cond IS NOT NULL THEN
        LET more = scroller_3(cond)     -- Query = TRUE, Exit = FALSE
    ELSE  -- query was cancelled
        LET more = FALSE
    END IF

  END WHILE

  CLOSE FORM f_customer
  CLEAR SCREEN
END MAIN

########################################
FUNCTION scroller_3(start_cond)
########################################
--* Purpose: Opens the cursor and puts up a menu with the following 
--*            choices:
--*       	Query: construct a different query
--*       	Revise: bound the query by ANDing more conditions to it
--*       	First, Last, Prior and Next: scrolling actions.
--*       	Update, Delete: modify actions if user is privileged
--*       	Exit: exit the program
--*            Can either accept info for a new customer or
--*	       allow update of existing info.
--*          Only ROWIDs are selected by the scrolling cursor. Each 
--*          time a row is displayed it is fetched anew from its ROWID.  
--*          Thus rows that are updated (by this user or any other) 
--*          so as to no longer meet the criteria are discovered, and 
--*          the cursor is closed and reopened to keep the list of
--*          selected records current.
--*
--*          This function assumes the form f_customer has been displayed.
--*          It closely follows the design of the scroller_2() function
--*          in Ex 20.
--* Argument(s): start_cond - string containing WHERE clause for user's
--*                           search criteria conditions
--* Return Value(s): TRUE - if user selects Query (to begin a new
--*			        query) from menu
--*                  FALSE - if user selects Exit from menu
---------------------------------------
  DEFINE start_cond 	CHAR(150),    -- initial query condition

         cust_priv LIKE informix.systabauth.tabauth, -- privilege in table
         scroll_sel 	CHAR(500),   -- SELECT statement for scroll cursor
         curr_rid,      	     -- row id of row now being displayed,
         next_rid,       	     -- ..of row to display when Next is chosen,
         prior_rid      INTEGER,     -- ..of row to display when Prior is chosen
	                  	     -- (ROWIDs are integers)
         fetch_dir,      	     -- flag showing direction of travel in list
         using_next,     	     -- flag values: going fwd using fetch next,
         using_prior,    	     -- ...going bwd using fetch prior, or
         at_end,         	     -- ...at either end of the list
         retval,         	     -- value to RETURN from function
         misc    	SMALLINT,
         scroll_pos     SMALLINT     -- position, direction in selection set
                  		     -- no one can manually scroll > 32K 
				     -- ...records

--* Initialize direction constants
  LET using_next = +1
  LET using_prior = -1
  LET at_end = 0

  LET m_querycond = start_cond   -- initialize query condition
  LET cust_priv = get_tab_auth("customer") -- the user's privileges

  LET scroll_pos = 1    -- initial position is First
  LET retval = 99       -- neither TRUE nor FALSE

--* This loop supports scrolling by:
--*	1. preparing and executing the scroll cursor
--*	2. displaying a menu of possible options
--*     3. closing the cursor
--* When a menu option finds that the cursor is showing stale data,
--*   the set must be resynchronized to acquire fresh data. To do 
--*   this, the option exits the MENU statement and the loop closes 
--*   the cursor, reopens it, repositions the cursor to its previous 
--*   position (as close as possible), and redisplays the menu.
------------------------
  WHILE retval <> TRUE AND retval <> FALSE -- ie while not Query or Exit

--* Prepare and execute SELECT to retrieve specified customer rows
    LET scroll_sel = "SELECT ROWID FROM customer WHERE ",m_querycond CLIPPED
    PREPARE scroll_prep FROM scroll_sel
    DECLARE c_custrid SCROLL CURSOR FOR scroll_prep
    OPEN c_custrid

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

--* Fetch first row's ROWID into curr_rid
        FETCH FIRST c_custrid INTO curr_rid -- test for empty set
        IF SQLCA.SQLCODE = NOTFOUND THEN
            ERROR "There are no rows that satisfy this query."

--* No matching rows so show only Query and Exit as menu options
            HIDE OPTION ALL
            SHOW OPTION "Query"
            SHOW OPTION "Exit"
            NEXT OPTION "Query"
        ELSE -- set contains at least one row
            MESSAGE "Setting cursor position, be patient"

--* Deny user access to menu options for which s/he doesn't
--*   have permission
------------------------
            IF cust_priv[2] = "-" THEN 
	 	HIDE OPTION "Update" 
	    END IF
            IF cust_priv[5] = "-" THEN 
		HIDE OPTION "Delete" 
	    END IF

--* If scroll_pos <> 1, then cursor has been reopened and need to
--*   resynchronize by moving cursor position to its position in the
--*   previous cursor. This tries to display the row the user was
--*   viewing before the cursor was closed.
------------------------
            IF scroll_pos > 1 THEN 

--* In previous cursor, user had only moved forward and backward
--*   incrementally and did not use "Last" option. The scroll_pos is
--*   the cursor position in the previous set. Can fetch prior, 
--*   current, and next rows with using "ABSOLUTE scroll_pos"
------------------------
                LET misc = scroll_pos - 1 -- get prior row
                FETCH ABSOLUTE misc c_custrid INTO prior_rid
                IF SQLCA.SQLCODE = 0 THEN
--* If fetch of prior row successful, get current row
                    FETCH NEXT c_custrid INTO curr_rid
                END IF

                IF SQLCA.SQLCODE = 0 THEN -- got current row, set up "Next"
--* If fetches of current and prior rows successful, get next row
                    LET fetch_dir = using_next
                    FETCH NEXT c_custrid INTO next_rid

--* Display "Next" option if a next row exists, otherwise hide this
--*   option.
------------------------
                    IF SQLCA.SQLCODE = 0 THEN
                        NEXT OPTION "Next"
                    ELSE
                        HIDE OPTION "Next"
                        NEXT OPTION "First"
                    END IF
                ELSE -- current row unavailable, go for "Last"
--* If prior or current row is no longer at the previous absolute 
--*   location in the set, the set has become smaller because rows
--*   have been deleted from the end. Set scroll position to 
--*   "Last" by setting it to zero.
------------------------
                    LET scroll_pos = 0
                END IF
            END IF -- scroll_pos > 1

--* In previous cursor, user had moved to the end of the set with 
--*   "Last" and then moved backward in the set. We don't know how 
--*   many rows are in the set. The scroll_pos is negative because 
--*   it is initialized to 0 at the last row. To return to the 
--*   previous cursor position, FETCH LAST to end of set, then fetch 
--*   "backward" with FETCH RELATIVE scroll_pos where scroll_pos is 
--*   a negative number to get prior, current, and next rows. 
------------------------
            IF scroll_pos < 0 THEN 
                FETCH LAST c_custrid INTO curr_rid -- establish position

                LET misc = scroll_pos + 1 -- get "next" row
                FETCH RELATIVE misc c_custrid INTO next_rid
                IF SQLCA.SQLCODE = 0 THEN -- ok, try for current
--* If fetch of next row successful, get current row
                    FETCH PRIOR c_custrid INTO curr_rid
                END IF
                IF SQLCA.SQLCODE = 0 THEN -- got current, set up "Prior"
--* If fetches of current and next rows successful, get prior row
                    LET fetch_dir = using_prior
                    FETCH PRIOR c_custrid INTO prior_rid

--* Display "Prior" option if a prior row exists, otherwise hide this
--*   option.
------------------------
                    IF SQLCA.SQLCODE = 0 THEN
                        NEXT OPTION "Prior"
                    ELSE
                        HIDE OPTION "Prior"
                        NEXT OPTION "Last"
                    END IF
                ELSE -- current row unavailable, go for "First"

--* If next or current row is no longer at the previous relative
--*   location in the set, the set has become smaller because rows
--*   have been deleted from the front. Set scroll position to 
--*   "First" by setting it to one.
------------------------
                    LET scroll_pos = 1
                END IF
            END IF -- scroll_pos < 0

--* In previous cursor, user had moved to the end of the set with 
--*   "Last" so we don't know how many rows are in the set.
--*   To return to the previous cursor position, FETCH LAST to get
--*   current row and FETCH PRIOR to get prior row. No next row
--*   exists.
------------------------
            IF scroll_pos = 0 THEN -- do just as for "Last" choice
                FETCH LAST c_custrid INTO curr_rid
                HIDE OPTION "Next"      -- can't go onward from here
                LET fetch_dir = using_prior
                FETCH PRIOR c_custrid INTO prior_rid

--* Display "Prior" option if a prior row exists, otherwise hide this
--*   option.
------------------------
                IF SQLCA.SQLCODE = 0 THEN       -- at least 2 rows in set
                    NEXT OPTION "Prior"
                ELSE                    -- only 1 row in set
                    HIDE OPTION "Prior"
                    NEXT OPTION "Query"
                END IF
            END IF -- scroll_pos = 0 = last

--* In previous cursor, user had moved to the first row of the set.
--*   To return to the previous cursor position, FETCH FIRST to get
--*   current row and FETCH NEXT to get next row. No prior row
--*   exists.
------------------------
            IF scroll_pos = 1 THEN -- do just as for "First" choice
                FETCH FIRST c_custrid INTO curr_rid
                HIDE OPTION "Prior"             -- can't back up from #1
                LET fetch_dir = using_next
                FETCH NEXT c_custrid INTO next_rid

--* Display "Prior" option if a prior row exists, otherwise hide this
--*   option.
------------------------
                IF SQLCA.SQLCODE = 0 THEN       -- at least 2 rows
                    NEXT OPTION "Next"
                ELSE                    -- only 1 row in set
                    HIDE OPTION "Next"
                    NEXT OPTION "Query"
                END IF
            END IF -- scroll_pos = 1 = First
            MESSAGE "" -- clear "please wait" message
            IF disp_row(curr_rid) = FALSE THEN 
		EXIT MENU 
	    END IF
        END IF

---------------
--Query option
---------------
      COMMAND KEY(ESC,Q) "Query" "Query for a different set of customers."
	    HELP 130
--* Exit this menu and the controlling WHILE loop (retval = TRUE)
        LET retval = TRUE
        EXIT MENU

---------------
--Revise option
---------------
      COMMAND "Revise" "Restrict the current query by adding conditions."
	    HELP 131
--* Allow user to enter qualifying search criteria
        CALL query_cust3b() RETURNING start_cond

--* If search criteria entered, build new WHERE clause with
--*   conditions for initial search AND new qualifying conditions
------------------------
        IF start_cond IS NOT NULL THEN -- some condition entered
            LET m_querycond = m_querycond CLIPPED, " AND ", start_cond CLIPPED
            EXIT MENU   -- close and re-open the cursor
        ELSE

--* CONSTRUCT clears form. If the current row (identified by ROWID 
--*   in curr_rid) has not been deleted by another user, or been 
--*   updated so that it no longer fits the current query 
--*   constraints, refresh the display. Otherwise, exit the menu 
--*   and force cursor to reopen.
------------------------
            IF disp_row(curr_rid) = FALSE THEN 
		EXIT MENU 
	    END IF
        END IF

---------------
--First option - same as "First" option in Ex 20 except only the ROWID
--               is fetched instead of the row values. See Ex 20.
---------------
      COMMAND "First" "Display first customer in selected set."
	    HELP 133
        FETCH FIRST c_custrid INTO curr_rid -- this cannot return NOTFOUND

--* If the current row (identified by ROWID in curr_rid) has not 
--*   been deleted by another user, or been updated so that it no 
--*   longer fits the current query constraints, refresh the display.
--*   Otherwise, exit the menu and force cursor to reopen.
------------------------
        IF disp_row(curr_rid) = FALSE THEN 
	    EXIT MENU 
	END IF
        LET scroll_pos = 1      -- know an absolute position
        HIDE OPTION "Prior"             -- can't back up from #1
        LET fetch_dir = using_next
        FETCH NEXT c_custrid INTO next_rid
        IF SQLCA.SQLCODE = 0 THEN       -- at least 2 rows
            SHOW OPTION "Next"  -- it might be hidden
            NEXT OPTION "Next"
        ELSE                    -- only 1 row in set
            HIDE OPTION "Next"
            NEXT OPTION "Query"
        END IF

---------------
--Next option - same as "Next" option in Ex 20 except only the ROWID
--              is fetched instead of the row values. See Ex 20.
---------------
      COMMAND "Next" "Display next customer in selected set."
	    HELP 134
        LET prior_rid = curr_rid
        LET curr_rid = next_rid

--* If the current row (identified by ROWID in curr_rid) has not 
--*   been deleted by another user, or been updated so that it no 
--*   longer fits the current query constraints, refresh the display.
--*   Otherwise, exit the menu and force cursor to reopen.
------------------------
        IF disp_row(curr_rid) = FALSE THEN 
	    EXIT MENU 
	END IF
        LET scroll_pos = scroll_pos+1
        SHOW OPTION "Prior"
        CASE (fetch_dir)
          WHEN using_next
            FETCH NEXT c_custrid INTO next_rid
          WHEN at_end
            FETCH RELATIVE +2 c_custrid INTO next_rid
          WHEN using_prior
            FETCH RELATIVE +3 c_custrid INTO next_rid
        END CASE
        IF SQLCA.SQLCODE = NOTFOUND THEN
            LET fetch_dir = at_end
            HIDE OPTION "Next"
            NEXT OPTION "First"
        ELSE
            LET fetch_dir = using_next
        END IF

---------------
--Prior option
---------------
      COMMAND "Prior" "Display previous customer in selected set."
	    HELP 135
        LET next_rid = curr_rid
        LET curr_rid = prior_rid

--* If the current row (identified by ROWID in curr_rid) has not 
--*   been deleted by another user, or been updated so that it no 
--*   longer fits the current query constraints, refresh the display.
--*   Otherwise, exit the menu and force cursor to reopen.
------------------------
        IF disp_row(curr_rid) = FALSE THEN 
	    EXIT MENU 
	END IF
        LET scroll_pos = scroll_pos-1
        SHOW OPTION "Next"
        CASE (fetch_dir)
          WHEN using_prior
            FETCH PRIOR c_custrid INTO prior_rid
          WHEN at_end
            FETCH RELATIVE -2 c_custrid INTO prior_rid
          WHEN using_next
            FETCH RELATIVE -3 c_custrid INTO prior_rid
        END CASE
        IF SQLCA.SQLCODE = NOTFOUND THEN
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
        FETCH LAST c_custrid INTO curr_rid

--* If the current row (identified by ROWID in curr_rid) has not 
--*   been deleted by another user, or been updated so that it no 
--*   longer fits the current query constraints, refresh the display.
--*   Otherwise, exit the menu and force cursor to reopen.
------------------------
        IF disp_row(curr_rid) = FALSE THEN 
	    EXIT MENU 
	END IF
        LET scroll_pos = 0      -- position now relative to last row
        HIDE OPTION "Next"      -- can't go onward from here
        FETCH PRIOR c_custrid INTO prior_rid
        LET fetch_dir = using_prior
        IF SQLCA.SQLCODE = 0 THEN       -- at least 2 rows in set
            SHOW OPTION "Prior"         -- it might have been hidden
            NEXT OPTION "Prior"
        ELSE                    -- only 1 row in set
            HIDE OPTION "Prior"
            NEXT OPTION "Query"
        END IF

---------------
--Update option
---------------
      COMMAND "Update" "Modify contents of current row."
	    HELP 137

--* Attempt to modify the current row 
        CALL upd_row(curr_rid)
        EXIT MENU -- force cursor to reopen

---------------
--Delete option
---------------
      COMMAND "Delete" "Delete the current row."
	    HELP 138

--* Ask user to confirm delete request. Deletes CANNOT be undone.
	IF "Yes" = answer("Are you sure you want to delete this?", 
						"Yes","No","") 
	THEN
--* Attempt to delete the current row
          CALL del_row(curr_rid)
	  CLEAR FORM
        END IF
	CLOSE c_custrid
	NEXT OPTION "Query"

---------------
--Exit option
---------------
      COMMAND KEY(INTERRUPT,"E") "Exit" "Exit program."
	    HELP 100
        LET retval = FALSE
        EXIT MENU
    END MENU

    CLOSE c_custrid
  END WHILE         -- retval neither FALSE nor TRUE
  RETURN retval

END FUNCTION  -- scroller_3 --

########################################
FUNCTION disp_row(rid)
########################################
--* Purpose: Gets and displays the contents of the row identified
--*            by ROWID.  In addition to the test ROWID=N, the other 
--*            query conditions (from the user) are also applied. 
--*            Thus if the row has been deleted by another user, or 
--*            it has been updated so that it no longer fits the 
--*            current query constraints, the row will be not found.  
--* Argument(s): rid - ROWID of row to get and display
--* Return Value(s): TRUE - if row identified by rid is found
--*                  FALSE - if row identified by rid is not found
---------------------------------------
  DEFINE rid 		INTEGER,

	 err, ret 	SMALLINT,
	 get_sel 	CHAR(500)

--* Attempt to fetch the row identified by the ROWID
  LET get_sel = "SELECT * FROM customer",
		" WHERE ROWID = ", rid,
		" AND ", m_querycond CLIPPED
  PREPARE prep_get FROM get_sel
  DECLARE c_getrow CURSOR FOR prep_get
  OPEN c_getrow

WHENEVER ERROR CONTINUE
  FETCH c_getrow INTO mr_currcust.*
  LET err = SQLCA.SQLCODE
WHENEVER ERROR STOP

  CLOSE c_getrow
  FREE c_getrow  -- release cursor resources
  LET ret = TRUE -- assume it will work

--* Check the success of the FETCH statement
  CASE err
    WHEN 0   -- FETCH was successful
    	DISPLAY BY NAME mr_currcust.*
    WHEN NOTFOUND -- row deleted or changed beyond recognition
	ERROR "Selected row no longer exists -- resynchronizing"
	SLEEP 2
	LET ret = FALSE
    OTHERWISE -- some other error
        ERROR "SQL error ",err," fetching row."
	SLEEP 2  -- leave screen unchanged, return TRUE, avoiding a loop
  END CASE
  RETURN ret

END FUNCTION  -- disp_row --

########################################
FUNCTION del_row(rid)
########################################
--* Purpose: Deletes the row whose ROWID is N. In addition to the 
--*            test ROWID=N, the other query conditions are
--*            applied. Thus if another user has deleted row N, or 
--*            updated it so that it no longer fits the current 
--*            query, the row will be not found. 
--* Argument(s): rid - ROWID of row to delete
--* Return Value(s): NONE
---------------------------------------
  DEFINE rid 		INTEGER,

         ret 		SMALLINT,
         del_stm 	CHAR(500)

--* Build a DELETE statment which includes user's search criteria 
--*   as the second condition 
------------------------
  LET del_stm = "DELETE FROM customer",
                " WHERE ROWID = ", rid,
                " AND ", m_querycond CLIPPED
  PREPARE prep_del FROM del_stm

--* If database uses transactions (and is not ANSI-compliant)
  CALL begin_wk()

WHENEVER ERROR CONTINUE
  EXECUTE prep_del
  LET ret = SQLCA.SQLERRD[3] -- count of rows deleted
WHENEVER ERROR STOP

--* Make sure that only 1 row was deleted. Count of deleted
--*   rows is in SQLERRD[3] of SQLCA.
------------------------
  IF ret = 1 THEN
    CALL commit_wk()    -- if database uses transactions, commit work
  ELSE          -- no row deleted
    ERROR "SQL problem, delete not done -- resynchronizing"
    CALL rollback_wk()  -- end failed transaction
    SLEEP 3
  END IF
  FREE prep_del

END FUNCTION  -- del_row --

########################################
FUNCTION upd_row(rid)
########################################
--* Purpose: Updates the row whose ROWID is N, in this order:
--*             1. accept user input
--*             2. ask for confirmation of update
--*             3. begin work, then fetch and lock the row in question
--*                a. if it exists and has not changed, update it and 
--*                   commit
--*                b. if it has gone or been changed, alert user and 
--*                   roll back
--*          A change in any field indicates an update by some other 
--*          user which would be invalidated by this user's actions, 
--*          so the select statement, instead of using the 
--*          m_querycond conditions, actually tests for equality in 
--*          every column between the database and the last-displayed 
--*          row values in mr_currcust.
--* Argument(s): rid - ROWID of row to delete
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
    DEFINE 	rid 		INTEGER,

        	reject, touched SMALLINT,
        	rejmsg 		CHAR(80),
        	pr_updcust      RECORD LIKE customer.*,
        	pr_testcust 	RECORD LIKE customer.*,
		cust_cnt	SMALLINT

--* Create a local copy of the current customer values
    LET pr_updcust.* = mr_currcust.*

    CALL clear_lines(2, 16)
    DISPLAY " Enter new data and press Accept to update."
      AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)
    DISPLAY " Press Cancel to exit without changing database."
      AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

    LET int_flag = FALSE
    INPUT BY NAME pr_updcust.company, pr_updcust.address1, pr_updcust.address2, 
		  pr_updcust.city, pr_updcust.state, pr_updcust.zipcode,
		  pr_updcust.fname, pr_updcust.lname, pr_updcust.phone 
    WITHOUT DEFAULTS
--* Note specifically not taking new customer_num, the primary key

--* This is an abbreviated form of field validations for the customer
--*   row. For more complete validations, see the addupd_cust() 
--*   function in Ex 9.
------------------------
      AFTER FIELD state
--* Prevent user from leaving empty state field.
        IF pr_updcust.state IS NULL THEN
	  ERROR "You must enter a state code. Please try again."
	  NEXT FIELD state
        END IF

--* Verify that state code entered is valid: does it exist in state
--*   table?
------------------------
        SELECT COUNT(*)
        INTO cust_cnt
        FROM state
        WHERE code = pr_updcust.state

        IF (cust_cnt = 0) THEN
	  ERROR 
      "Unknown state code. Please try again."
	  LET pr_updcust.state = NULL
	  NEXT FIELD state
        END IF

      AFTER INPUT
--* Set touched to TRUE if any field value has been updated.
--* NOTE: the FIELD_TOUCHED() function is a new 4.1 feature.
------------------------
	LET touched = FIELD_TOUCHED(fname,lname,company, 
					address1,address2,
					city,state,
					zipcode,phone)
    END INPUT

    IF int_flag THEN
      LET rejmsg = "Update cancelled at your request - resynchronizing."
      LET reject = TRUE
    ELSE
      IF NOT touched THEN
	  LET rejmsg =
		"No data entered so database unchanged - resynchronizing."
	  LET reject = TRUE
      ELSE
--* Ask user to confirm the database update
	  IF "No" = answer("OK to go ahead and update the database?",
						"Yes","No","") 
	  THEN
	      LET rejmsg = "Database not changed - resynchronizing."
	      LET reject = TRUE
	  END IF
      END IF
    END IF

--* If row is to be updated, then start a transaction and open an
--*   update cursor to lock and access the row.
------------------------
    IF NOT reject THEN
	CALL begin_wk()

WHENEVER ERROR CONTINUE
	DECLARE c_updrow CURSOR FOR
	    SELECT * INTO pr_testcust.* FROM customer
	    WHERE ROWID = rid
	FOR UPDATE

	OPEN c_updrow
	FETCH c_updrow
WHENEVER ERROR STOP

--* If the OPEN and FETCH were successful, and the row just fetched
--*   matches the row that was displayed (before the update), then
--*   update the row
------------------------
	IF SQLCA.SQLCODE = 0
	  AND pr_testcust.customer_num = mr_currcust.customer_num
	  AND like(pr_testcust.fname,mr_currcust.fname)
	  AND like(pr_testcust.lname,mr_currcust.lname)
	  AND like(pr_testcust.company,mr_currcust.company)
	  AND like(pr_testcust.address1,mr_currcust.address1)
	  AND like(pr_testcust.address2,mr_currcust.address2)
	  AND like(pr_testcust.city,mr_currcust.city)
	  AND like(pr_testcust.state,mr_currcust.state)
	  AND like(pr_testcust.zipcode,mr_currcust.zipcode)
	  AND like(pr_testcust.phone,mr_currcust.phone)
	THEN
	    UPDATE customer SET	fname = pr_updcust.fname,
				lname  = pr_updcust.lname,
				company  = pr_updcust.company,
				address1  = pr_updcust.address1,
				address2  = pr_updcust.address2,
				city  = pr_updcust.city,
				state  = pr_updcust.state,
				zipcode  = pr_updcust.zipcode,
				phone  = pr_updcust.phone
	      WHERE CURRENT OF c_updrow
	    CALL commit_wk()
	    MESSAGE "Database updated - resynchronizing."
	ELSE
	    LET rejmsg="SQL problem updating row - not done - resynchronizing"
	    LET reject = TRUE
	    CALL rollback_wk()
	END IF
    END IF
    CALL clear_lines(2, 16)
    IF reject THEN 
	ERROR rejmsg 
    END IF
END FUNCTION  -- upd_row --

########################################
FUNCTION like(a,b)
########################################
--* Purpose: Compares two strings for equality. Two NULL
--*            strings are considered equal.
--* Argument(s): a - one string to compare
--*              b - second string to compare
--* Return Value(s): TRUE - if two strings are equal
--*                  FALSE - if two strings are not equal
---------------------------------------
  DEFINE a,b 	CHAR(255)

    IF (a IS NULL) AND (b IS NULL) THEN
	RETURN TRUE
    ELSE
	IF a = b THEN
	    RETURN TRUE
	ELSE
	    RETURN FALSE
	END IF
    END IF
END FUNCTION  -- like --

########################################
FUNCTION open_db(dbname)
########################################
--* Purpose: Dynamically executes a DATABASE statement and saves
--*            the resulting flags from SQLAWARN in the global 
--*            record gr_database.
--* Argument(s): dbname - a character string containing the name 
--*                       of the database to open. It may include 
--*                       a sitename:  "dbname@sitename" or 
--*                       "//sitename/dbname". It may also include 
--*                       the keyword exclusive: "dbname EXCLUSIVE". 
--*                       It is to support this last feature that 
--*                       we prepare and execute the statement.
--* Return Value(s): TRUE - if database was successfully opened
--*                  FALSE - if unable to open specified database
---------------------------------------
    DEFINE	dbname CHAR(50),
		-- size of above allows for sitename (8), dbname (10),
		-- the word " EXCLUSIVE" and punctuation.

		dbstmt CHAR(60), -- "DATABASE " plus the above
		sqlr   SMALLINT

    LET gr_database.db_known = FALSE -- initialize with safe values
    LET gr_database.has_log = FALSE
    LET gr_database.is_ansi = FALSE
    LET gr_database.is_online = FALSE
    LET gr_database.can_wait = FALSE

WHENEVER ERROR CONTINUE
--* The CLOSE DATABASE statement returns an error -349 if no database
--*     But when using Informix-Link or -Star and there IS an open 
--*     database, and it happens to be remote, an attempt to open 
--*     a database produces -917 Must close current database.
------------------------
    CLOSE DATABASE
    IF SQLCA.SQLCODE <> 0 AND SQLCA.SQLCODE <> -349 THEN
	ERROR "Error ",SQLCA.SQLCODE," closing current database."
	RETURN FALSE
    END IF -- either 0 or -349 is OK here

--* Create DATABASE statement to execute (in case user added
--*   EXCLUSIVE keyword as part of argument).
------------------------
    LET dbstmt = "DATABASE ",dbname
    PREPARE prepdbst FROM dbstmt
    IF SQLCA.SQLCODE <> 0 THEN -- big syntax trouble in "dbname"
	ERROR "Not an acceptable database name: ",dbname
	RETURN FALSE
    END IF
    EXECUTE prepdbst
    LET sqlr = SQLCA.SQLCODE
WHENEVER ERROR STOP

    IF sqlr = 0 THEN	-- we have opened the database

--* Since the statement succeeded, "prepdbst" was freed by
--*    the engine automatically
------------------------

--* Set the values of the gr_database global record based on
--*   the results in SQLCA after the DATABASE statement executed
------------------------
	LET gr_database.db_known = TRUE
	IF SQLCA.SQLAWARN[2] = "W" THEN
		LET gr_database.has_log = TRUE
	END IF
	IF SQLCA.SQLAWARN[3] = "W" THEN
	    LET gr_database.is_ansi = TRUE
	END IF
	IF SQLCA.SQLAWARN[4] = "W" THEN
	    LET gr_database.is_online = TRUE
	ELSE -- not online, check lock support
	    SET LOCK MODE TO WAIT
	    IF SQLCA.SQLCODE = 0 THEN -- didn't get -527 or -513
	    	LET gr_database.can_wait = TRUE
	    END IF
	    SET LOCK MODE TO NOT WAIT -- restore default, ignore return code
	END IF
    ELSE 

--* The database did not open; display a message. Although there 
--*   is probably nothing the program can do with no database open, 
--*   we will not use an EXIT PROGRAM here, because there is also 
--*   no harm it can do with no database open!
------------------------
	FREE prepdbst -- since not freed automatically when stmt fails

--* Check for possible causes of failure and notify user
	CASE 
	  WHEN (sqlr = -329 OR sqlr = -827)
	   ERROR dbname CLIPPED,
			": Database not found or no system permission." 
	  WHEN (sqlr = -349)
	   ERROR dbname CLIPPED,
			" not opened, you do not have Connect privilege."
	  WHEN (sqlr = -354)
	    ERROR dbname CLIPPED,
			": Incorrect database name format."
	  WHEN (sqlr = -377)
	    ERROR "open_db() called with a transaction still incomplete."
	  WHEN (sqlr = -512)
	    ERROR "Unable to open in exclusive mode, db probably in use."
	OTHERWISE
	    ERROR dbname CLIPPED,
			": error ",sqlr," on DATABASE statement."
	END CASE
    END IF
    RETURN gr_database.db_known

END FUNCTION  -- open_db --

########################################
FUNCTION begin_wk()
########################################
--* Purpose: Executes the BEGIN WORK statement to start a transaction
--*            but only if the current database supports transactions 
--*            and is not ANSI-compliant. (An ANSI-compliant database 
--*            uses transactions but does not use BEGIN WORK.)
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database is NOT 
--*   ANSI-compliant and it uses transactions, then do a BEGIN
--*   WORK.
------------------------
    IF gr_database.db_known
      AND NOT gr_database.is_ansi
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	BEGIN WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on BEGIN WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- begin_wk --

########################################
FUNCTION commit_wk()
########################################
--* Purpose: Executes the COMMIT WORK statement to end a transaction
--*            but only if the current database supports transactions.
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database 
--*   uses transactions, then do a COMMIT WORK.
------------------------
    IF  gr_database.db_known
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	COMMIT WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on COMMIT WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- commit_wk --

########################################
FUNCTION rollback_wk()
########################################
--* Purpose: Executes the ROLLBACK WORK statement to end a transaction
--*            but only if the current database supports transactions. 
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database 
--*   uses transactions, then do a ROLLBACK WORK.
------------------------
    IF  gr_database.db_known
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	ROLLBACK WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on ROLLBACK WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- rollback_wk --

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
FUNCTION get_tab_auth(tabname)
########################################
--* Purpose: Takes a table name and returns the privileges that
--*            the current user holds for that table. The 
--*            privileges are returned as a 7-character string 
--*            as found in the system catalog systabauth:
--*
--*	auth[1] = s if the user has (full) select privilege
--*	auth[2] = u if the user has (full) update privilege
--*	auth[3] = * if the user has any column-level privileges
--*     auth[4] = i if the user can insert
--*     auth[5] = d if the user can delete
--*     auth[6] = x if the user can create indexes
--*     auth[7] = a if the user can alter the table
--*
--*          In any position a hyphen (-) means "no privilege of 
--*          this type." A capital letter means the user can grant 
--*          the same privilege to others. 
--* Argument(s): tabname - name of table for which to check privileges 
--* Return Value(s): privilege string for specified table and
--*                    combination of user and public
---------------------------------------
  DEFINE tabname  CHAR(32),	-- allow "owner.tabname"

	 theTable LIKE informix.systables.tabname,  -- tablename part of above
	 theOwner LIKE informix.systables.owner,    -- ownerid part, if any
	 theTabid LIKE informix.systables.tabid,    -- tabid from systables
	 auth     LIKE informix.systabauth.tabauth, -- final authorization 
						    --  string
	 j,k      SMALLINT

--* Check the table name for an owner name (required for 
--*   ANSI-compliant) database. If one exists, store it in theOwner
------------------------
    LET theOwner = NULL			-- assume owner not included
    FOR j = 1 to LENGTH(tabname) - 1
	IF tabname[j] = "." THEN 
	    EXIT FOR 
	END IF
    END FOR
    IF tabname[j] = "." THEN	-- is an "owner." part, extract
	LET theOwner = tabname[1,j-1]	-- save "owner" omitting "."
	LET k = LENGTH(tabname)		-- not allowed in subscript!
	LET tabname = tabname[j+1,k]	-- drop "owner." 
    END IF
    LET theTable = tabname CLIPPED

    LET auth = "-------"	-- assume no privileges at all
    LET theTabid = -1		-- sentinel value in case no such table

--* Check system catalog table systables for table permissions. If
--*   an owner name has been specified, use the SELECT that includes 
--*   this owner.
------------------------
    IF theOwner IS NULL THEN
	SELECT MIN(tabid) INTO theTabid 
	FROM informix.systables
	WHERE @tabname = theTable
    ELSE
	SELECT tabid INTO theTabid 
	FROM informix.systables
	WHERE @tabname = theTable 
	  AND owner = theOwner
    END IF

--* If the table is user-defined (it's table id is >= 100), find
--*   authorizations for this user and for public and then merge
--*   them: retain any letter in preference to a hyphen, and 
--*   uppercase letters in preference to lower.
------------------------
    IF theTabid >= 100 THEN    -- table exists & is user-defined
	LET auth = merge_auth(	sel_merged_auths(get_user(), theTabid),
				sel_merged_auths("public", theTabid) )
    END IF

    RETURN auth
END FUNCTION  -- get_tab_auth --

########################################
FUNCTION sel_merged_auths(userid,theTabid)
########################################
--* Purpose: Selects all grants for a given table and returns the 
--*            superset of privileges. The primary key of systabauth 
--*            is: grantor, grantee, tabid, so a given 
--*            grantee may have multiple grants for a given table.
--* Argument(s): userid - id of user whose privileges are to be
--*                       checked
--*	         theTabid - id of table whose privileges are to be
--*                       checked
--* Return Value(s): merged privilege string for specified table
--*                  for specified user
---------------------------------------
  DEFINE	userid           LIKE informix.sysusers.username,
		theTabid         LIKE informix.systables.tabid,
		allAuth, oneAuth LIKE informix.systabauth.tabauth

--* Initialize authorizations to "none"
    LET allAuth = "-------"
    DECLARE c_authval CURSOR FOR
	SELECT tabauth INTO oneAuth 
	FROM informix.systabauth
	WHERE grantee = userid
	  AND tabid = theTabid

--* Combine all authorizations for this user and table into
--*   a single authorization.
------------------------
    FOREACH c_authval
	LET allAuth = merge_auth(allAuth,oneAuth)
    END FOREACH

    CLOSE c_authval
    RETURN allAuth
END FUNCTION  -- sel_merged_auths --

########################################
FUNCTION merge_auth(oldauth,newauth)
########################################
--* Purpose: Combines two tabauth strings, retaining any letter 
--*            in preference to a hyphen, and uppercase letters 
--*            in preference to lower.
--* Argument(s): oldauth - string of authorizations so far
--*	         newauth - new auth string to merge into oldauth
--* Return Value(s): merged privilege string of newauth
--*                  into oldauth
---------------------------------------
    DEFINE 	oldauth, newauth LIKE informix.systabauth.tabauth,

    		k SMALLINT

--* Go through current authorizations, character by character
    FOR k = 1 to LENGTH(oldauth)

--* If there is no privilege yet in old auth or this privilege
--*   is "less than" the new auth, move new auth in.
------------------------
	IF (oldauth[k] = "-")	-- no privilege in this position
	  OR (UPSHIFT(oldauth[k]) = newauth[k]) -- new is "with grant option"
	THEN 
	    LET oldauth[k] = newauth[k]
	END IF
    END FOR
    RETURN oldauth
END FUNCTION  -- merge_auth --

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

