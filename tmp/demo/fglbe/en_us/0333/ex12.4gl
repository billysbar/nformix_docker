
#######################################################################
# APPLICATION: Example 12 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex12.4gl                            FORM: f_ship.per,         # 
#                                                 f_custsel.per,      # 
#                                                 f_ordersel.per      # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program illustrates how to handle an unknown number   #
#          entries in a fixed-sized program array.                    #
#                                                                     # 
# FUNCTIONS:                                                          #
#   find_order() - finds order to update based on user input of       #
#      customer number and order number.                              #
#   cust_popup2() - displays a popup window for customers using a     #
#      fixed-size array and allowing unlimited number of customers.   #
#   order_popup(cust_num) - displays a popup window for order info    #
#      for the current customer using a fixed-size array and allowing #
#      unlimited number of customers.                                 #
#   calc_order(ord_num) - calculates the total cost of the order.     #
#   tax_rates(state_code) - see description in ex4.4gl file.          #
#   input_ship() - accepts user input for shipping info.              #
#   upd_order(ord_num) - updates shipping info in "order" row.        #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   msg(str) - see description in ex5.4gl file.                       #
#   clear_lines(numlines,mrow) - see description in ex6.4gl file.     #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/24/91    dam             Split file into subroutines            #
#  01/22/91    dam             Created example 12                     #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_ordship RECORD 
		  customer_num  LIKE customer.customer_num,
		  company  	LIKE customer.company,
		  order_num	INTEGER,
		  order_date	LIKE orders.order_date
            	END RECORD,

		gr_charges RECORD
		  tax_rate	DECIMAL(5,3),
		  ship_charge	LIKE orders.ship_charge,
		  sales_tax	MONEY(9),
		  order_total	MONEY(11)
	    	END RECORD,

		gr_ship RECORD
		  ship_date	LIKE orders.ship_date,
		  ship_instruct	LIKE orders.ship_instruct,
		  ship_weight	LIKE orders.ship_weight,
		  ship_charge	LIKE orders.ship_charge
		END RECORD

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################
  DEFINE	upd_stat	INTEGER

--* Define help message file for program and set Comment and Message
--*   lines to work with f_ship form.
------------------------
  OPTIONS
    HELP FILE "hlpmsgs",
    COMMENT LINE 1,
    MESSAGE LINE LAST

  DEFER INTERRUPT

  OPEN WINDOW w_main AT 2,3
   WITH 19 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER)

  OPEN FORM f_ship FROM "f_ship"
  DISPLAY FORM f_ship

--* If user enters an order, accept shipping information 
  IF find_order() THEN

    DISPLAY 
      " Press Accept to save shipping info. Press CTRL-W for Help."
      AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)
    DISPLAY 
      " Press Cancel to exit w/out saving."
      AT 18, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Calculate order amount (must be calculated because it is not
--*   stored directly in orders table)
------------------------
    CALL calc_order(gr_ordship.order_num)

--* Display any existing shipping information on f_ship form
    SELECT ship_date, ship_instruct, ship_weight, ship_charge
    INTO gr_ship.*
    FROM  orders
    WHERE order_num = gr_ordship.order_num

--* If user enters shipping info, update the orders row
    IF input_ship() THEN
      LET upd_stat = upd_order(gr_ordship.order_num)
      IF (upd_stat < 0) THEN
	ERROR upd_stat USING "-<<<<<<<<<<<", 
	  ": Unable to update the order."
      ELSE
	CALL msg("Order updated with shipping information.")
      END IF
    END IF
  END IF

  CLOSE FORM f_ship
  CLOSE WINDOW w_main
  CLEAR SCREEN
END MAIN

########################################
FUNCTION find_order()
########################################
--* Purpose: Allows user to choose an order by by entering first the
--*            customer number and then the order number.
--* Argument(s): NONE
--* Return Value(s): TRUE - If user chooses a valid order
--*                  FALSE - If user ends INPUT with Interrupt key
---------------------------------------
  DEFINE	cust_num	LIKE customer.customer_num,
		last_key	SMALLINT

--* Display form title and user instructions
  CALL clear_lines(1, 3) 
  DISPLAY "ORDER SEARCH" AT 2, 34
  CALL clear_lines(2, 17) 
  DISPLAY " Enter customer number and order number then press Accept."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Cancel to exit without searching. Press CTRL-W for Help."
    AT 18, 1 ATTRIBUTE (REVERSE, YELLOW)

  LET int_flag = FALSE
  INPUT BY NAME gr_ordship.customer_num, gr_ordship.order_num 
	HELP 110
    BEFORE FIELD customer_num
--* Notify user of special popup window available on this field.
      MESSAGE 
        "Enter a customer number or press F5 (CTRL-F) for a list."

    AFTER FIELD customer_num
--* Prevent user from leaving an empty customer_num field.
      IF gr_ordship.customer_num IS NULL THEN
	ERROR "You must enter a customer number. Please try again."
	NEXT FIELD customer_num
      END IF

--* Verify that user entered a valid customer number
      SELECT company
      INTO gr_ordship.company
      FROM customer
      WHERE customer_num = gr_ordship.customer_num

      IF (status = NOTFOUND) THEN
	  ERROR 
	"Unknown customer number. Use F5 (CTRL-F) to see valid customers."
	  LET gr_ordship.customer_num = NULL
	  NEXT FIELD customer_num
      END IF

--* If customer_num is valid, display customer's company name
      DISPLAY BY NAME gr_ordship.company
      MESSAGE ""

    BEFORE FIELD order_num
--* Notify user of special popup window available on this field.
      MESSAGE 
        "Enter an order number or press F5 (CTRL-F) for a list."

    AFTER FIELD order_num
--------------------
--* A null order_num field is invalid unless the user is moving back
--* to the customer_num field with the Left Arrow (like after an 
--* ON KEY from customer_num which obtained the wrong customer number).
--* NOTE: the FGL_LASTKEY() and FGL_KEYVAL() functions are new 4.1 features.
--------------------
      LET last_key = FGL_LASTKEY()
      IF (last_key <> FGL_KEYVAL("left") )
	  AND (last_key <> FGL_KEYVAL("up") ) 
      THEN
	IF gr_ordship.order_num IS NULL THEN
	  ERROR "You must enter an order number. Please try again."
	  NEXT FIELD order_num
	END IF

--* Verify that an order exists for the specified order number.
	SELECT order_date, customer_num
 	INTO gr_ordship.order_date, cust_num
	FROM orders
	WHERE order_num = gr_ordship.order_num

	IF (status = NOTFOUND) THEN
	  ERROR
	"Unknown order number. Use F5 (CTRL-F) to see valid orders."
	  LET gr_ordship.order_num = NULL
	  NEXT FIELD order_num
	END IF

--* If the specified order number is not for the specified customer,
--*   notify the user.
	IF (cust_num <> gr_ordship.customer_num) THEN
	  ERROR "Order ", gr_ordship.order_num USING "<<<<<<<<<<<",
		" is not for customer ", 
		gr_ordship.customer_num USING "<<<<<<<<<<<"
	  LET gr_ordship.order_num = NULL
	  DISPLAY BY NAME gr_ordship.order_num
	  NEXT FIELD customer_num
	END IF

	DISPLAY BY NAME gr_ordship.order_date
      ELSE
	LET gr_ordship.order_num = NULL
	DISPLAY BY NAME gr_ordship.order_num
      END IF

      MESSAGE ""

    ON KEY (F5, CONTROL-F)
      IF INFIELD(customer_num) THEN
--* If cursor is in customer_num field, implement customer popup
	CALL cust_popup2()
	  RETURNING gr_ordship.customer_num, gr_ordship.company

------------------
--* If customer_num is NULL, user didn't select from popup list (pressed
--*   Cancel from the popup form). In this case, company contains 
--*   the DATE value from the line the cursor was one when the user
--*   pressed Cancel.
--* If customer_num AND company are Null, then no companies exist in
--*   the database. Setting company to NULL is the popup
--*   routine's way of indicating that execution should return to the
--*   customer_num field.
------------------
	IF gr_ordship.customer_num IS NULL THEN
	  IF gr_ordship.company IS NULL THEN
	    LET ga_dsplymsg[1]  = "No customers exist in the database!"
	    CALL message_window(11, 12)
          END IF

	  NEXT FIELD customer_num
	END IF

	DISPLAY BY NAME gr_ordship.customer_num, gr_ordship.company
	MESSAGE ""
	NEXT FIELD order_num
      END IF

      IF INFIELD(order_num) THEN
--* If cursor is in order_num field, implement order popup
	CALL order_popup(gr_ordship.customer_num)
	  RETURNING gr_ordship.order_num, gr_ordship.order_date

------------------
--* If order_num is NULL, user didn't select from popup list (pressed
--*   Cancel from the popup form). In this case, order_date contains 
--*   the DATE value from the line the cursor was one when the user
--*   pressed Cancel.
--* If order_num AND order_date are Null, then no orders exist for the
--*   current customer. Setting order_date to NULL is the popup
--*   routine's way of indicating that execution should return to the
--*   customer_num field so the user can select a new customer.
------------------
	IF gr_ordship.order_num IS NULL THEN
	  IF gr_ordship.order_date IS NULL THEN
	    LET ga_dsplymsg[1]  = "No orders exists for customer ", 
		gr_ordship.customer_num USING "<<<<<<<<<<<", "."
	    CALL message_window(11, 12)
	    LET gr_ordship.customer_num = NULL
	    LET gr_ordship.company = NULL
	    DISPLAY BY NAME gr_ordship.company
	    NEXT FIELD customer_num
	  ELSE
	    NEXT FIELD order_num
	  END IF
	END IF

	DISPLAY BY NAME gr_ordship.order_num, gr_ordship.order_date
        MESSAGE ""
	EXIT INPUT
      END IF

    AFTER INPUT
--* If user is ending INPUT with the Accept key, but customer_num or
--*   order_num is NULL, cannot exit.
------------------------
      IF NOT int_flag THEN
        IF (gr_ordship.customer_num IS NULL) 
	    OR (gr_ordship.order_num IS NULL) THEN
	  ERROR 
          "Enter the customer and order numbers or press Cancel to exit."
	  NEXT FIELD customer_num
        END IF
      END IF
  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2, 17)
    CALL msg("Order search terminated.")
    RETURN (FALSE)
  END IF

  CALL clear_lines(2, 17)
  RETURN (TRUE)

END FUNCTION  -- find_order --

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
FUNCTION order_popup(cust_num)
########################################
--* Purpose: Implements the order popup on the f_ordersel form. 
--*            Uses algorithm that enables popup to display rows
--*            in groups which means that the size of the program
--*            array is no longer a restriction on the number of
--*            rows than can be displayed.
--* Argument(s): cust_num - the customer number of the customer whose
--*                         orders are to be displayed.
--* Return Value(s): order_num - number of chosen orders row
--*                                     OR
--*                              NULL if no orders rows exist or
--*                                   cannot open cursor or user 
--*                                   pressed Interrupt key
--*                  order_date - order date of chosen orders row
---------------------------------------
  DEFINE 	cust_num	LIKE customer.customer_num,

		pa_order 	ARRAY[10] OF RECORD
	        	order_num 	LIKE orders.order_num,
	        	order_date 	LIKE orders.order_date,
	        	po_num 		LIKE orders.po_num,
	        	ship_date 	LIKE orders.ship_date,
	        	paid_date 	LIKE orders.paid_date
	    	END RECORD,

		idx 		SMALLINT,
		i 		SMALLINT,
		order_cnt	SMALLINT,
		fetch_orders	SMALLINT,
		array_size	SMALLINT,
		total_orders	INTEGER,
		number_to_see	INTEGER,
		curr_pa		SMALLINT

  LET array_size = 10   	-- match size of pa_order array
  LET fetch_orders = FALSE

--* Verify that orders for the specified customer exist
  SELECT COUNT(*)
  INTO total_orders
  FROM orders
  WHERE customer_num = cust_num

  IF total_orders = 0 THEN
    LET pa_order[1].order_num = NULL
    LET pa_order[1].order_date = NULL
    RETURN pa_order[1].order_num, pa_order[1].order_date
  END IF

--* Open new window for popup and display f_ordersel form
  OPEN WINDOW w_orderpop AT 9, 5
    WITH 12 ROWS, 71 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_ordersel FROM "f_ordersel"
  DISPLAY FORM f_ordersel

  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select an order."
    AT 2,2

--* Number of rows remaining to display is the total number of orders
  LET number_to_see = total_orders
  LET idx = 0

--* c_orderpop cursor will contain all orders rows for the specified
--*   customer, ordered by order number
------------------------
  DECLARE c_orderpop CURSOR FOR
    SELECT order_num, order_date, po_num, ship_date, paid_date 
    FROM orders
    WHERE customer_num = cust_num
    ORDER BY order_num

WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
  OPEN c_orderpop
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

  IF (status = 0) THEN
    LET fetch_orders = TRUE
  ELSE
--* If unable to open cursor, return NULL values
    CALL msg("Unable to open cursor.")
    LET idx = 1
    LET pa_order[idx].order_num = NULL
    LET pa_order[idx].order_date = NULL
  END IF

  WHILE fetch_orders			-- still have orders to see
    WHILE (idx < array_size) 	-- still have room in program array
      LET idx = idx + 1
--* Fetch next orders row into program array
      FETCH c_orderpop INTO pa_order[idx].*
      IF (status = NOTFOUND) THEN		-- no more orders to see
	LET fetch_orders = FALSE
	LET idx = idx - 1
	EXIT WHILE
      END IF
    END WHILE

--* If there are still more to see (after array is full), notify
--*   user of special key sequence to see more orders.
------------------------
    IF (number_to_see > array_size) THEN
      MESSAGE "On last row, press F5 (CTRL-B) for more orders."
    END IF

--* No more rows to see
    IF (idx = 0) THEN
      CALL msg("No orders exist in the database.")
      LET idx = 1
      LET pa_order[idx].order_num = NULL
    ELSE

--* Initialize size of program array so ARR_COUNT() can track it
      CALL SET_COUNT(idx)

--* Display contents of pa_order program array in sa_order screen
--*   array (the screen array is defined within the f_ordersel form)
------------------------
      LET int_flag = FALSE
      DISPLAY ARRAY pa_order TO sa_order.* 
	ON KEY (F5, CONTROL-B)
--* These keys implement the "scroll" to the next set of rows. 
	  LET curr_pa = ARR_CURR()

--* If current cursor position (in program array) is the last line
--*   of program array, then decrement number_to_see by number
--*   viewed.
------------------------
	  IF (curr_pa = idx) THEN
	    LET number_to_see = number_to_see - idx

--* If there are still more to see, reset index and return to get
--*   next set of rows
------------------------
	    IF (number_to_see > 0) THEN
	      LET idx = 0
	      EXIT DISPLAY
	    ELSE
	      CALL msg("No more orders to see.")
	    END IF
	  ELSE
--* If current cursor position is not the last line, notify user
--*   that can only move to next set of rows from last line
------------------------
	    CALL msg("Not on last order row.")
      	    MESSAGE "On last row, press F5 (CTRL-B) for more orders."
	  END IF
      END DISPLAY

--* If user pressed either Accept or Cancel (not F5 or CONTROL-B), 
--*   exit WHILE loop that fetches more rows
------------------------
      IF idx <> 0 THEN
	LET idx = ARR_CURR()
	LET fetch_orders = FALSE
      END IF

      IF int_flag THEN
	LET int_flag = FALSE
	CALL msg("No order number selected.")
	LET pa_order[idx].order_num = NULL
      END IF

    END IF
  END WHILE
	
  CLOSE FORM f_ordersel
  CLOSE WINDOW w_orderpop
  RETURN pa_order[idx].order_num, pa_order[idx].order_date

END FUNCTION  -- orders_popup --

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
FUNCTION input_ship()
########################################
--* Purpose: Accepts user input for shipping information on the bottom 
--*            half of the f_ship form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*		     FALSE - if user ends INPUT with Cancel key
---------------------------------------

  DISPLAY gr_charges.order_total TO order_amount

--* Initialize a null ship_charge to 0.00 so it won't make
--*   a calculation NULL
------------------------
  IF gr_charges.ship_charge IS NULL THEN
    LET gr_charges.ship_charge = 0.00
  END IF
  LET gr_ship.ship_charge = gr_charges.ship_charge

--* Calculate new order total (order total + ship charge)
  LET gr_charges.order_total = gr_charges.order_total 
		+ gr_charges.ship_charge
  DISPLAY BY NAME gr_charges.order_total

  LET int_flag = FALSE
  INPUT BY NAME gr_ship.ship_date, gr_ship.ship_instruct,
	gr_ship.ship_weight, gr_ship.ship_charge
  WITHOUT DEFAULTS HELP 63

    BEFORE FIELD ship_date
--* Initialize empty ship_date field to today's date
      IF gr_ship.ship_date IS NULL THEN
	LET gr_ship.ship_date = TODAY
      END IF

    AFTER FIELD ship_date
--* If user clears out ship_date, set it to today's date
      IF gr_ship.ship_date IS NULL THEN
	LET gr_ship.ship_date = TODAY
	DISPLAY BY NAME gr_ship.ship_date
      END IF

    BEFORE FIELD ship_weight 
--* Initialize an empty ship_weight field to 0.00
      IF gr_ship.ship_weight IS NULL THEN
	LET gr_ship.ship_weight = 0.00
      END IF

    AFTER FIELD ship_weight 
--* If user clears out ship_weight, set it to 0.00
      IF gr_ship.ship_weight IS NULL THEN
	LET gr_ship.ship_weight = 0.00
	DISPLAY BY NAME gr_ship.ship_weight
      END IF

--* Negative ship weight not valid
      IF gr_ship.ship_weight < 0.00 THEN
	ERROR 
  "Shipping Weight cannot be less than 0.00 lbs. Please try again."
	LET gr_ship.ship_weight = 0.00
	NEXT FIELD ship_weight
      END IF

    BEFORE FIELD ship_charge
--* If no shipping charge has been entered, calculate default charge
      IF gr_ship.ship_charge = 0.00 THEN
        LET gr_ship.ship_charge = 1.5 * gr_ship.ship_weight
      END IF

    AFTER FIELD ship_charge
--* If user clears out ship_charge, set it to $0.00
      IF gr_ship.ship_charge IS NULL THEN
	LET gr_ship.ship_charge = 0.00
	DISPLAY BY NAME gr_ship.ship_charge
      END IF

--* Negative ship charge not valid
      IF gr_ship.ship_charge < 0.00 THEN
	ERROR "Shipping Charge cannot be less than $0.00. Please try again."
	LET gr_ship.ship_charge = 0.00
	NEXT FIELD ship_charge
      END IF

--* Recalculate order total (order total + new ship charge)
      LET gr_charges.order_total = gr_charges.order_total + gr_ship.ship_charge
      DISPLAY BY NAME gr_charges.order_total

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL msg("Shipping input terminated.")
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- input_ship --


########################################
FUNCTION upd_order(ord_num)
########################################
--* Purpose: Updates an order with the shipping information in the
--*            gr_ship global array. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	ord_num		LIKE orders.order_num

WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
    UPDATE orders SET (ship_date, ship_instruct, ship_weight, ship_charge)
		   = (gr_ship.ship_date, gr_ship.ship_instruct,
		      gr_ship.ship_weight, gr_ship.ship_charge)
    WHERE order_num = ord_num
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

--* Return status of UPDATE to calling program
    RETURN (status)
END FUNCTION  -- upd_order --

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


