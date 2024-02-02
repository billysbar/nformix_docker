
#######################################################################
# APPLICATION: Example 4 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex4.4gl                             FORM: f_custkey.per,      # 
#                                                 f_custsum.per       # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of a key      #
#          search: searching a table by key and displaying the        #
#          contents of the matching row.                              #
#                                                                     # 
# STATEMENTS:                                                         #
#          DATABASE		  ERROR               SELECT          #
#          INPUT keyfld	          CLEAR SCREEN        DISPLAY BY NAME #
#          RETURN (value)         WHENEVER ERROR      IF (status < 0) #
#          EXIT PROGRAM                                               #
#                                                                     # 
# FUNCTIONS:                                                          #
#   get_custnum() -  accepts the customer number (key of the customer #
#          the customer table).                                       #
#   get_summary() - calculates customer summary info: number of unpaid#
#          orders, amount due, number of open customer calls.         #
#   dsply_summary() - displays customer summary info on screen.       #
#   tax_rates(state_code) - finds the sales tax rate for "state_code".#
#   init_msgs() - see description in ex2.4gl file.                    #
#   prompt_window(question,x,y) - displays the contents of a global   #
#          global array called "ga_dsplymsg" in a window and then dis-#
#          plays a PROMPT with the string "question". Window size is  #
#          determined by the number of lines in the "ga_dsplymsg"     #
#          array. Window position is determined by the "x" (column)   #
#          and "y" (row) arguments.                                   #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Created new version of ex4.4gl         #
#  12/26/90    dam             Added header to file                   #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE	gr_custsum RECORD 
		  customer_num 	LIKE customer.customer_num,
		  company 	LIKE customer.company,
		  unpaid_ords 	SMALLINT,
		  amount_due	MONEY(11),
		  open_calls 	SMALLINT
		END RECORD

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################

  OPTIONS
    INPUT ATTRIBUTE (REVERSE, BLUE),
    PROMPT LINE 13,
    MESSAGE LINE LAST

  CALL cust_summary()

END MAIN

########################################
FUNCTION cust_summary()
########################################
--* Purpose: Controls execution of request for customer number and
--*            display of customer summary information. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	search_again	SMALLINT

--* WHILE loop continues until user answers "No" to continue
--*   prompt (dsply_summary() returns FALSE)
------------------------
  LET search_again = TRUE
  WHILE search_again
    CALL get_custnum() RETURNING gr_custsum.customer_num

    CALL dsply_summary() RETURNING search_again
  END WHILE

  CLEAR SCREEN

END FUNCTION  -- cust_summary --

########################################
FUNCTION get_custnum()
########################################
--* Purpose: Accepts input of customer number 
--* Form: f_custkey.per
--* Argument(s): NONE
--* Return Value(s): cust_num - customer number of customer 
--*                             selected (customer_num)
---------------------------------------
  DEFINE	cust_num	INTEGER,
		cust_cnt	SMALLINT

--* Open and display f_custkey form
  OPEN FORM f_custkey FROM "f_custkey"
  DISPLAY FORM f_custkey

--* Display a title for the form
  DISPLAY "                "
    AT 2, 30
  DISPLAY "CUSTOMER KEY LOOKUP"
    AT 2, 20
  DISPLAY " Enter customer number and press Accept."
    AT 4, 1 ATTRIBUTE (REVERSE, YELLOW)

  INPUT cust_num FROM customer_num
    AFTER FIELD customer_num

--* If no customer number entered, notify user and return cursor to
--*   customer_num field
------------------------
      IF cust_num IS NULL THEN
	ERROR "You must enter a customer number. Please try again."
	NEXT FIELD customer_num
      END IF

--* If customer number entered, verify that it is a valid
--*   customer in the database
------------------------
      SELECT COUNT(*)
      INTO cust_cnt
      FROM customer
      WHERE customer_num = cust_num

      IF (cust_cnt = 0) THEN
	ERROR "Unknown customer number. Please try again."
	LET cust_num = NULL
	NEXT FIELD customer_num
      END IF

  END INPUT

--* Deallocate form resources by closing form
  CLOSE FORM f_custkey

--* Return customer number of specified customer
  RETURN (cust_num)

END FUNCTION  -- get_custnum --

########################################
FUNCTION get_summary()
########################################
--* Purpose: Gathers summary data for specified customer and
--*            puts it in the gr_custsum global record.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	cust_state	LIKE state.code,
		item_total	MONEY(12),
		ship_total	MONEY(7),
		sales_tax	MONEY(9),
		tax_rate	DECIMAL(5,3)

--* Get customer's company name and state (for later tax evaluation)
  SELECT company, state
  INTO gr_custsum.company, cust_state
  FROM customer
  WHERE customer_num = gr_custsum.customer_num

--* Calculate number of unpaid orders for customer
  SELECT COUNT(*)
  INTO gr_custsum.unpaid_ords
  FROM orders
  WHERE customer_num = gr_custsum.customer_num
    AND paid_date IS NULL

--* If customer has unpaid orders, calculate total amount due
  IF (gr_custsum.unpaid_ords > 0) THEN
    SELECT SUM(total_price)
    INTO item_total
    FROM items, orders
    WHERE orders.order_num = items.order_num
      AND customer_num = gr_custsum.customer_num
      AND paid_date IS NULL

    SELECT SUM(ship_charge)
    INTO ship_total
    FROM orders
    WHERE customer_num = gr_custsum.customer_num
      AND paid_date IS NULL

    LET tax_rate = 0.00
    CALL tax_rates(cust_state) RETURNING tax_rate
  
    LET sales_tax = item_total * (tax_rate / 100)
    LET gr_custsum.amount_due = item_total + sales_tax + ship_total

--* If customer has no unpaid orders, total amount due = $0.00
  ELSE
    LET gr_custsum.amount_due = 0.00
  END IF

--* Calculate number of open calls for this customer
  SELECT COUNT(*)
  INTO gr_custsum.open_calls
  FROM cust_calls
  WHERE customer_num = gr_custsum.customer_num
    AND res_dtime IS NULL

END FUNCTION  -- get_summary --

########################################
FUNCTION dsply_summary()
########################################
--* Purpose: Displays summary information from gr_custsum global
--*            record on form.      
--* Form: f_custsum.per
--* Argument(s): NONE
--* Return Value(s): TRUE - user wants to enter another cust num
--*                  FALSE - user wants to exit program
---------------------------------------
  DEFINE get_more	SMALLINT

--* Open and display f_custsum form
  OPEN FORM f_custsum FROM "f_custsum"
  DISPLAY FORM f_custsum

  DISPLAY "                   "
    AT 2, 20

--* Call get_summary() to gather summary information
  CALL get_summary()

--* Display customer summary info on form
  DISPLAY BY NAME gr_custsum.*

--* Use ga_dsplymsg global array and prompt_window() function to
--*   see if user wants to enter another customer number.
------------------------
  LET ga_dsplymsg[1] = "Customer summary for customer ",
	gr_custsum.customer_num USING "<<<<<<<<<<<"
  LET ga_dsplymsg[2] = " (", gr_custsum.company CLIPPED, ") complete."
 
  LET get_more = TRUE
  IF NOT prompt_window("Do you want to see another summary?",14,12)
  THEN
    LET get_more = FALSE
  END IF

--* Return user's answer: TRUE = yes, FALSE = no
  RETURN get_more
  CLOSE FORM f_custsum

END FUNCTION  -- dsply_summary --

########################################
FUNCTION tax_rates(state_code)
########################################
--* Purpose: Determines a retail tax rate based on a two-letter 
--*   "state_code". The task of obtaining the tax rate would be much 
--*   more efficiently performed by adding a column called "tax_rate" 
--*   to the "state" table and obtaining the rate directly from the 
--*   database. However, this schema does not have this column 
--*   available. Not all tax rates are filled in due to a lack of 
--*   information about state tax rates.
--* Argument(s): state_code - code for state whose tax rate is to be
--*            		      determined.
--* Return Value(s): tax rate for state_code
---------------------------------------
  DEFINE	state_code	LIKE state.code,

		tax_rate	DECIMAL(4,2)

--* This huge set of CASE statements sets the tax_rate according to
--*  the two-letter "state_code"
------------------------
  CASE state_code[1]
    WHEN "A"	-- if state code begins with "A"
      CASE state_code
	WHEN "AK"
	  LET tax_rate = 0.0
	WHEN "AL"
	  LET tax_rate = 0.0
	WHEN "AR"
	  LET tax_rate = 0.0
	WHEN "AZ"
	  LET tax_rate = 5.5
      END CASE
    WHEN "C"    -- if state code begins with "C"
      CASE state_code
	WHEN "CA"
	  LET tax_rate = 6.5
	WHEN "CO"
	  LET tax_rate = 3.7
	WHEN "CT"
	  LET tax_rate = 8.0
      END CASE
    WHEN "D"    -- if state code begins with "D"
      LET tax_rate = 0.0	-- * tax rate for "DE"
    WHEN "F"    -- if state code begins with "F"
      LET tax_rate = 7.0	-- * tax rate for "FL"
    WHEN "G"    -- if state code begins with "G"
      LET tax_rate = 4.0	-- * tax rate for "GA"
    WHEN "H"    -- if state code begins with "H"
      LET tax_rate = 0.0	-- * tax rate for "HI"
    WHEN "I"    -- if state code begins with "I"
      CASE state_code
	WHEN "IA"
	  LET tax_rate = 0.0
	WHEN "ID"
	  LET tax_rate = 0.0
	WHEN "IL"
	  LET tax_rate = 0.0
	WHEN "IN"
	  LET tax_rate = 0.0
      END CASE
    WHEN "K"    -- if state code begins with "K"
      IF state_code = "KS" THEN
        LET tax_rate = 5.85
      ELSE
	LET tax_rate = 0.0	-- * tax rate for "KY"
      END IF
    WHEN "L"    -- if state code begins with "L"
      LET tax_rate = 0.0	-- * tax rate for "LA"
    WHEN "M"    -- if state code begins with "M"
      CASE state_code
	WHEN "MA"
	  LET tax_rate = 5.0
	WHEN "MD"
	  LET tax_rate = 5.0
	WHEN "ME"
	  LET tax_rate = 5.0
	WHEN "MI"
	  LET tax_rate = 4.0
	WHEN "MN"
	  LET tax_rate = 6.5
	WHEN "MO"
	  LET tax_rate = 5.725
	WHEN "MS"
	  LET tax_rate = 0.0
	WHEN "MT"
	  LET tax_rate = 0.0
      END CASE
    WHEN "N"    -- if state code begins with "N"
      CASE state_code
	WHEN "NC"
	  LET tax_rate = 0.0
	WHEN "ND"
	  LET tax_rate = 0.0
	WHEN "NE"
	  LET tax_rate = 0.0
	WHEN "NH"
	  LET tax_rate = 0.0
	WHEN "NJ"
	  LET tax_rate = 7.0
	WHEN "NM"
	  LET tax_rate = 0.0
	WHEN "NV"
	  LET tax_rate = 0.0
	WHEN "NY"
	  LET tax_rate = 8.25
      END CASE
    WHEN "O"    -- if state code begins with "O"
      CASE state_code
	WHEN "OH"
	  LET tax_rate = 6.0
	WHEN "OK"
	  LET tax_rate = 0.0
	WHEN "OR"
	  LET tax_rate = 0.0
      END CASE
    WHEN "P"    -- if state code begins with "P"
      LET tax_rate = 6.0	-- * tax rate for "PA"
    WHEN "R"    -- if state code begins with "R"
      LET tax_rate = 0.0	-- * tax rate for "RI"
    WHEN "S"    -- if state code begins with "S"
      IF state_code = "SC" THEN
	LET tax_rate = 0.0
      ELSE
	LET tax_rate = 0.0	-- * tax rate for "SD"
      END IF
    WHEN "T"    -- if state code begins with "T"
      IF state_code = "TN" THEN
	LET tax_rate = 0.0
      ELSE
	LET tax_rate = 8.25	-- * tax rate for "TX"
      END IF
    WHEN "U"    -- if state code begins with "U"
      LET tax_rate = 0.0	-- * tax rate for "UT"
    WHEN "V"    -- if state code begins with "V"
      IF state_code = "VA" THEN
	LET tax_rate = 4.5
      ELSE
	LET tax_rate = 0.0	-- * tax rate for "VT"
      END IF
    WHEN "W"    -- if state code begins with "W"
      CASE state_code
	WHEN "WA"
	  LET tax_rate = 8.2
	WHEN "WI"
	  LET tax_rate = 8.57
	WHEN "WV"
	  LET tax_rate = 0.0
	WHEN "WY"
	  LET tax_rate = 0.0
      END CASE
    OTHERWISE    -- unknown state code
      LET tax_rate = 0.0
  END CASE

  RETURN (tax_rate)

END FUNCTION  -- tax_rates --

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


