
#######################################################################
# APPLICATION: Example 5 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex5.4gl                             FORM: f_customer.per      # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of a query-   #
#          by-form on the customer table.                             #
#                                                                     # 
# STATEMENTS:                                                         # 
#          CONSTRUCT		    DECLARE CURSOR FOR stmt           #
#          PREPARE  		    OPEN                              #
#          LET (with concatenation) FETCH                             #
#                                   CLOSE                             #
#                                                                     # 
# FUNCTIONS:                                                          #
#   query_cust1() -  displays the f_customer form for a query-by-form #
#      on the customer table and generates a WHERE clause from the    #
#      entered search criteria. Program prompts user to see next row. #
#   answer_yes(question) - prompts the user for a YES (Y or y) or NO  #
#      (N or n) response to the "question".  Returns TRUE (YES) or    #
#      FALSE (NO).                                                    #
#   msg(str) - displays the "str" in the current Message line, waits  #
#      for 3 seconds, then clear the Message line.                    #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  12/26/90    dam             Added header to file                   #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer RECORD LIKE customer.*
END GLOBALS

########################################
MAIN
########################################

--* Redefine Prompt and Message lines to work with f_customer form
  OPTIONS 
    PROMPT LINE 14,
    MESSAGE LINE 15

--* Defer interpretation of Interrupt/Cancel key as program termination
  DEFER INTERRUPT

  OPEN FORM f_customer FROM "f_customer"
  DISPLAY FORM f_customer
  DISPLAY "CUSTOMER QUERY-BY-EXAMPLE" AT 2, 25

--* Allow user to enter search criteria on the f_customer form
  CALL query_cust1()

  CLOSE FORM f_customer
  CLEAR SCREEN
END MAIN

########################################
FUNCTION query_cust1()
########################################
--* Purpose: Implements the customer query-by-example on the f_customer
--*            form. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	q_cust		CHAR(200),
		selstmt		CHAR(250),
		answer		CHAR(1),
		found_some	SMALLINT,
		invalid_resp	SMALLINT

--* WHILE TRUE is an infinite loop. The EXIT WHILE statements exit it.
  WHILE TRUE

--* Notify user of available keys
    DISPLAY 
   " Press Accept to search for customer data, Cancel to exit w/out searching."
      AT 15, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Initialize int_flag to FALSE so it is correctly set before the
--*   CONSTRUCT begins
    LET int_flag = FALSE

--* Allow user to enter search criteria on all f_customer fields.
--*   This CONSTRUCT stores resulting WHERE clause string in q_cust
------------------------
    CONSTRUCT BY NAME q_cust ON customer.customer_num,
  			      customer.company,
  			      customer.address1,
  			      customer.address2,
  			      customer.city,
  			      customer.state,
  			      customer.zipcode,
  			      customer.fname,
  			      customer.lname,
  			      customer.phone
  
--* If user has pressed Interrupt/Cancel, reset int_flag and exit 
    IF int_flag THEN
      LET int_flag = FALSE
      EXIT WHILE
    END IF

--* User hasn't pressed Cancel, clear out screen instructions
    DISPLAY 
   "                                                                          "
      AT 15, 1

--* Check to see if user has entered search criteria. If not,
--*   interpret query as ALL customer rows.
------------------------
    IF q_cust = " 1=1" THEN
      IF NOT answer_yes("Do you really want to see all customers? (n/y):")
      THEN
	CONTINUE WHILE
      END IF
    END IF
      
--* Create and prepare the SELECT statement using CONSTRUCT's WHERE
--*   clause string
------------------------
    LET selstmt = "SELECT * FROM customer WHERE ", q_cust CLIPPED
    PREPARE st_selcust FROM selstmt
    DECLARE c_cust CURSOR FOR st_selcust
  
--* Execute the SELECT statement and open the cursor to access the rows
    OPEN c_cust

--* Fetch first row. If fetch is successful, first row values stored
--*   in global gr_customer record.
------------------------
    LET found_some = 0
    FETCH c_cust INTO gr_customer.*

--* If fetch is successful, set found_some to 1. Otherwise found_some
--*   remains set to 0 to indicate no rows found.
------------------------
    IF (status = 0) THEN
      LET found_some = 1
    END IF

    WHILE (found_some = 1)
--* Display first customer
      DISPLAY BY NAME gr_customer.*

--* Fetch next customer (fetch ahead)
      FETCH NEXT c_cust INTO gr_customer.*

--* If fetch is not successful, set found_some to -1 to indicate no
--*   more rows.
------------------------
      IF (status = NOTFOUND) THEN
	LET found_some = -1
	EXIT WHILE
      END IF

--* Ask user if going to view next row
      IF NOT answer_yes("Display next customer? (n/y):") THEN
	LET found_some = -2
      END IF
    END WHILE

--* Notify user of various "error" conditions
    CASE found_some
      WHEN -1
	CALL msg("End of selected customers.")
      WHEN 0
	CALL msg("No customers match search criteria.")
      WHEN -2
	CALL msg("Display terminated at your request.")
    END CASE
    
    CLOSE c_cust

  END WHILE

--* Clear user instructions
  DISPLAY 
    "                                                                         "
    AT 15,1 
--* Clear form fields
  CLEAR FORM

END FUNCTION  -- query_cust1 --

########################################
FUNCTION answer_yes(question)
########################################
--* Purpose: Prompts a user with a question and expects a YES or
--*            NO response.
--* Argument(s): question - text of question
--* Return Value(s): TRUE  if response is "Y" or "y"
--*                  FALSE if response if "N" or "n"
---------------------------------------
  DEFINE 	question	CHAR(50),

		invalid_resp	SMALLINT,
		answer		CHAR(1),
		ans_yes		SMALLINT

--* Repeat prompt attempt until user answers either YES or NO
  LET invalid_resp = TRUE
  WHILE invalid_resp

--* Display user question in Prompt line and accept response in
--*   variable "answer"
------------------------
    PROMPT question CLIPPED FOR answer
    IF answer MATCHES "[NnYy]" THEN
      LET invalid_resp = FALSE
      LET ans_yes = TRUE
      IF answer MATCHES "[Nn]" THEN
	LET ans_yes = FALSE
      END IF
    END IF
  END WHILE

  RETURN ans_yes

END FUNCTION  -- answer_yes --

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

