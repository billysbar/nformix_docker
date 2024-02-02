
#######################################################################
# APPLICATION: Example 21 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex21.4gl                            FORM: f_date.per          # 
#                                                 f_custkey.per       # 
#                                                 f_custsel.per       # 
#                                                 f_payord.per        # 
#                                                                     # 
# PURPOSE: This program uses a single function to perform both the    #
#          add and update processes on the "customer" table.          #
#                                                                     # 
# STATEMENTS:                                                         # 
#             INSERT (on SERIAL field)                                #
#             OPEN WINDOW WITH rows + OPEN FORM                       #
#                                                                     # 
# FUNCTION:                                                           # 
#   input_date() - accepts user input for the date to mark the orders #
#      as paid.                                                       #
#   open_ckey() - opens the f_custkey form.                           #
#   close_ckey() - closes the f_custkey form.                         #
#   find_cust() - accepts user input of a customer number or company  #
#      name and then finds a customer based on either of these values.#
#   cust_popup2() - see description in ex12.4gl file.                 #
#   find_unpaid() - determines the number of unpaid orders for the    #
#      specified customer.                                            #
#   pay_orders(total_unpaid) - finds, displays and updates the unpaid #
#      orders for the current customer with the specified paid date.  #
#      This function uses an Update cursor.                           #
#   calc_order(ord_num) - see description in ex12.4gl file.           #
#   tax_rates(state_code) - see description in ex4.4gl file.          #
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
#  01/31/91    dam             Created example 21 file                #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer 	RECORD LIKE customer.*,
		gr_payord	RECORD
				  paid_date	LIKE orders.paid_date,
				  customer_num	LIKE orders.customer_num,
				  company	LIKE customer.company,
				  order_num	LIKE orders.order_num,
				  order_date	LIKE orders.order_date,
				  po_num	LIKE orders.po_num,
				  ship_date	LIKE orders.ship_date
				END RECORD,
		gr_charges	RECORD
		  		  tax_rate	DECIMAL(5,3),
		  		  ship_charge	LIKE orders.ship_charge,
		  		  sales_tax	MONEY(9),
		  		  order_total	MONEY(11)
				END RECORD

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################
  DEFINE	keep_going	SMALLINT,
		num_unpaid	SMALLINT

--* Set form lines to work with the f_date, f_custkey, and f_payord
--*   forms
------------------------
  OPTIONS
    FORM LINE FIRST,
    MESSAGE LINE LAST

  DEFER INTERRUPT

  IF input_date() THEN
--* If user entered a paid date, open f_custkey 
    LET keep_going = TRUE
    CALL open_ckey()
    WHILE keep_going
      IF find_cust() THEN
--* If user entered a customer key, find number of unpaid orders
	LET gr_payord.customer_num = gr_customer.customer_num
	LET gr_payord.company = gr_customer.company
        LET num_unpaid = find_unpaid()
--* If customer has unpaid orders, allow update of these orders
        IF (num_unpaid > 0) THEN
	  CALL pay_orders(num_unpaid) 
        END IF
      ELSE
        LET keep_going = FALSE
      END IF
    END WHILE
  END IF

--* Close f_custkey form and its window
  CALL close_ckey()
  CLEAR SCREEN
END MAIN

########################################
FUNCTION input_date()
########################################
--* Purpose: Accepts user input for a date on the f_date form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------

--* Open "top" window for f_date form
  OPEN WINDOW w_paydate AT 2,3
   WITH 6 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER, COMMENT LINE 2)

  OPEN FORM f_date FROM "f_date"
  DISPLAY FORM f_date

  DISPLAY "ORDER PAY DATE" AT 1,24
  CALL clear_lines(1, 6)
  DISPLAY " Enter order paid date and press Accept. Press Cancel to exit."
    AT 6, 1 ATTRIBUTE (REVERSE, YELLOW)

  INPUT gr_payord.paid_date FROM a_date

    BEFORE FIELD a_date
--* Initialize empty field with today's date
      IF gr_payord.paid_date IS NULL THEN
	LET gr_payord.paid_date = TODAY
      END IF

    AFTER FIELD a_date
--* Prevent user from leaving an empty a_date field
      IF gr_payord.paid_date IS NULL THEN
	ERROR "You must enter a Paid Date for the orders."
	NEXT FIELD paid_date
      END IF

  END INPUT

  CALL clear_lines(1, 6)
  IF int_flag THEN
    LET int_flag = FALSE
    CLOSE FORM f_date
    CLOSE WINDOW w_paydate
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- input_date --

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
FUNCTION find_unpaid()
########################################
--* Purpose: Determines the number of unpaid orders for the
--*            customer currently in the gr_customer global
--*	       record. An unpaid order has a NULL value in
--*            the order_date column.
--* Argument(s): NONE
--* Return Value(s): number of unpaid orders for current cust
--*                            OR
--*                  0 if no orders or user does not want to continue
---------------------------------------
  DEFINE	unpaid_cnt	SMALLINT

--* Count number of unpaid orders
  SELECT COUNT(*)
  INTO unpaid_cnt
  FROM orders
  WHERE customer_num = gr_payord.customer_num
    AND paid_date IS NULL


--* If none exist, notify user and exit
  IF (unpaid_cnt = 0) THEN
    LET ga_dsplymsg[1] = "Customer: ", 
	gr_payord.customer_num USING "<<<<<<<<<<<",
	" (", gr_payord.company CLIPPED, ")"
    LET ga_dsplymsg[2] = "  has no unpaid orders."
    CALL message_window(8,14)
    RETURN (0)
  END IF

--* Notify user of number of unpaid orders and ask for confirmation
--*   to continue with payment.
------------------------
  LET ga_dsplymsg[1] = "This customer has ", unpaid_cnt USING "<<<<<<", 
	" unpaid order(s)."
  IF prompt_window("Are you ready to begin paying these orders? ", 8,14)
  THEN
    RETURN (unpaid_cnt)
  ELSE
    RETURN (0)
  END IF

END FUNCTION  -- find_unpaid --
	
########################################
FUNCTION pay_orders(total_unpaid)
########################################
--* Purpose: Accepts user input for customer information.
--*            Can either accept info for a new customer or
--*	       allow update of existing info.
--* Argument(s): au_flag - "A" to indicate this is a new customer
--*	                   "U" to indicate this is an existing cust
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE	total_unpaid	SMALLINT,

		upd_cnt		SMALLINT,
		msg_txt		CHAR(10),
		success		SMALLINT

--* Open the bottom window to display the f_payord form
  OPEN WINDOW w_payord AT 8, 3
    WITH 6 ROWS, 76 COLUMNS
    ATTRIBUTE (BORDER)

  OPEN FORM f_payord FROM "f_payord"
  DISPLAY FORM f_payord

  DISPLAY BY NAME total_unpaid

  LET success = TRUE

--* The c_payord cursor will contain the unpaid orders for the current
--*   customer. This is an update cursor so each row will be locked
--*   when it is fetched.
------------------------
  DECLARE c_payord CURSOR FOR
    SELECT order_num, order_date, po_num, ship_date
    FROM orders
    WHERE customer_num = gr_payord.customer_num
      AND paid_date IS NULL
  FOR UPDATE OF paid_date

--* Begin a transaction for the update of unpaid orders.
  BEGIN WORK

  LET upd_cnt = 0
  FOREACH c_payord INTO gr_payord.order_num,
			gr_payord.order_date,
			gr_payord.po_num,
			gr_payord.ship_date
    
--* Calculate the total amount of this order
    CALL calc_order(gr_payord.order_num)

--* Display current order
    CLEAR order_num, order_date, po_num, ship_date, order_total
    DISPLAY BY NAME gr_payord.order_num
      ATTRIBUTE (REVERSE, YELLOW)
    DISPLAY BY NAME gr_payord.order_date, gr_payord.po_num, 
		    gr_payord.ship_date, gr_charges.order_total

--* Ask for confirmation of update
    IF prompt_window("Update this order's paid date?", 13, 14) THEN
      LET upd_cnt = upd_cnt + 1

--* Update current orders row.
WHENEVER ERROR CONTINUE
      UPDATE orders SET paid_date = gr_payord.paid_date 
      WHERE CURRENT OF c_payord
WHENEVER ERROR STOP

--* If UPDATE is not successful, notify user and do not continue
--*   with the order update process
------------------------
      IF (status < 0) THEN
	ERROR status USING "-<<<<<<<<<<<", 
  ": Unable to update order with paid date. No changes saved."
	LET success = FALSE
	LET upd_cnt = 0
	EXIT FOREACH
      END IF
    END IF
  END FOREACH

  CLOSE c_payord

--* If the UPDATE was successful, commit the transaction so that
--*   the confirmed updates are saved
------------------------
  IF success THEN
    COMMIT WORK
  ELSE
--* If the UPDATE is not successful, roll back the transaction
    ROLLBACK WORK
  END IF

  CLOSE FORM f_payord
  CLOSE WINDOW w_payord

--* Notify user of number of orders updated
  IF upd_cnt = 0 THEN
    LET msg_txt = "0"
  ELSE
    LET msg_txt = upd_cnt USING "<<<<<<"
  END IF
  LET ga_dsplymsg[1] = "Paid date updated for ", msg_txt CLIPPED,
	" order(s)."
  CALL message_window(10,12)

END FUNCTION  -- pay_orders --

########################################
FUNCTION calc_order(ord_num)
########################################
--* Purpose: Calculates the total for an order. Is needed because
--*            this total is not directly stored in the orders table. 
--*            It is a combination of:
--*              (1) sum of the total_price columns of the order's
--*			items rows. 
--*              (2) sales tax created by getting the sales tax rate
--*			(based on the customer's state) and multiplying
--*                     it by the order total (item 1 above)
--*              (3) ship_charge column of the orders row
--* Argument(s): ord_num - order number of the order to calculate
--* Return Value(s): amount of this order
---------------------------------------
  DEFINE	ord_num		LIKE orders.order_num,
		state_code	LIKE customer.state

--* Obtain the shipping charge and the customer state for the 
--*   specified order
------------------------
  SELECT ship_charge, state
  INTO gr_charges.ship_charge, state_code
  FROM orders, customer
  WHERE order_num = ord_num
    AND orders.customer_num = customer.customer_num

--* Initialize a null ship_charge to 0.00 to prevent the sum from
--*   being set to null (if one operand is null, result is null)
------------------------
  IF gr_charges.ship_charge IS NULL THEN
    LET gr_charges.ship_charge = 0.00
  END IF

--* Calculate sum of total_price columns in order's items rows
  SELECT SUM(total_price)
  INTO gr_charges.order_total
  FROM items
  WHERE order_num = ord_num

--* Initialize a null order_total to 0.00
  IF gr_charges.order_total IS NULL THEN
    LET gr_charges.order_total = 0.00
  END IF

--* Get tax rate for the customer's state
  CALL tax_rates(state_code) RETURNING gr_charges.tax_rate

--* Calculate sales tax
  LET gr_charges.sales_tax = gr_charges.order_total *
	(gr_charges.tax_rate / 100)

--* Calculate order total
--* NOTE: addition of shipping charge into order total is done later,
--*	    in input_ship()
------------------------
  LET gr_charges.order_total = gr_charges.order_total +
	gr_charges.sales_tax 		

END FUNCTION  -- calc_order --

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

  
