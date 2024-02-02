
#######################################################################
# APPLICATION: Example 15 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex15.4gl                            FORM: f_orders.per,       # 
#                                                 f_custsel.per,      # 
#                                                 f_stocksel.per,     # 
#                                                 f_ship.per          # 
#                                                                     # 
#                                           HELP FILE: hlpmsgs.src    # 
#                                                                     # 
# PURPOSE: This program illustrates how to create a more complex      #
#          report, using the AFTER GROUP sections. It also implements #
#          a report destination menu.                                 #
#                                                                     # 
# STATEMENTS:                                                         # 
#             START REPORT TO                                         #
#             AFTER GROUP          BEFORE GROUP                       #
#                                                                     # 
# FUNCTIONS:                                                          # 
#   add_order2() - same as add_order() in ex11.4gl except it also     #
#      calls the invoice() routine to print out an invoice (a report).#
#   input_cust() - see description in ex11.4gl file.                  #
#   cust_popup() - see description in ex11.4gl file.                  #
#   input_order() - see description in ex11.4gl file.                 #
#   input_items() - see description in ex11.4gl file.                 #
#   renum_items() - see description in ex11.4gl file.                 #
#   stock_popup(stock_item) - see description in ex11.4gl file.       #
#   dsply_taxes() - displays retail tax rate and sales tax amount     #
#      based on state in customer's address. Also calculates order's  #
#      total by adding in sales tax amount.                           #
#   order_amount() - see description in ex11.4gl file.                #
#   tax_rates(state_code) - see description in ex4.4gl file.          #
#   ship_order() - see description in ex11.4gl file.                  #
#   input_ship() - see description in ex11.4gl file.                  #
#   order_tx() - see description in ex11.4gl file.                    #
#   insert_order() - see description in ex11.4gl file.                #
#   insert_items() - see description in ex11.4gl file.                #
#   clear_lines(numlines,mrows) - see description in ex6.4gl file.    #
#   msg(str) - see description in ex5.4gl file.                       #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   prompt_window(question,x,y) - see description in ex4.4gl file.    #
#   invoice() - gathers invoice data for report.                      #
#   report_output(menu_title,x,y) - displays the Report Destination   #
#       menu with title "menu_title" at coordinates "x" and "y".      #
#   invoice_rpt() - report to create the invoice.                     #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/24/91    dam             Split file into subroutines            #
#  01/13/91    dam             Create the file                        #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer RECORD LIKE customer.*,

        	gr_orders RECORD 
                  order_num 	LIKE orders.order_num,
                  order_date 	LIKE orders.order_date,
                  po_num 	LIKE orders.po_num,
		  order_amount 	MONEY(8,2),
		  order_total 	MONEY(10,2)
            	END RECORD,

        	ga_items ARRAY[10] OF RECORD
                  item_num 	LIKE items.item_num,
                  stock_num 	LIKE items.stock_num,
                  manu_code 	LIKE items.manu_code,
                  description 	LIKE stock.description,
                  quantity 	LIKE items.quantity,
                  unit_price 	LIKE stock.unit_price,
                  total_price 	LIKE items.total_price
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
  OPTIONS
    HELP FILE "hlpmsgs",
    FORM LINE 2,
    COMMENT LINE 1,
    MESSAGE LINE LAST

  DEFER INTERRUPT

  OPEN WINDOW w_main AT 2,3
   WITH 18 ROWS, 76 COLUMNS
   ATTRIBUTE (BORDER)

  OPEN FORM f_orders FROM "f_orders"
  DISPLAY FORM f_orders
  CALL add_order2()
  CLEAR SCREEN

END MAIN

########################################
FUNCTION add_order2()
########################################
--* Purpose: Controls data entry for a new order. Breaks this data
--*            entry into six phases:
--*              (1) accept entry of customer who placed the order
--*              (2) accept entry of order date and PO number
--*              (3) accept entry of items being ordered
--*              (4) accept entry of shipping information (optional)
--*              (5) save all order information in database
--*              (6) print out an invoice
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  INITIALIZE gr_orders.* TO NULL

  DISPLAY "ORDER ADD" AT 2, 34
  CALL clear_lines(2, 16) 
  DISPLAY " Press Cancel to exit without saving."
    AT 17, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Phase 1 - accept customer data
  IF input_cust() THEN

--* Phase 2 - accept order date and PO number (if Phase 1 is OK)
    IF input_order() THEN

--* Phase 3 - accept items being ordered (if Phase 2 is OK)
      IF input_items() THEN
--* Calculate sales tax for order
	CALL dsply_taxes()
	IF prompt_window("Do you want to ship this order now?", 8, 12) THEN

--* Phase 4 - if user wants to enter shipping info, accept it
	  CALL ship_order()
	ELSE
	  LET gr_ship.ship_date = NULL
	END IF

	CALL clear_lines(2, 16)

	LET ga_dsplymsg[1] = "Order entry complete."
	IF prompt_window("Are you ready to save this order?", 8, 12) THEN

--* Phase 5 - if user confirms order, save it in database
	  IF order_tx() THEN
  	    CALL clear_lines(2, 16)

	    LET ga_dsplymsg[1] = "Order Number: ", 
			gr_orders.order_num USING "<<<<<<<<<<<"
	    LET ga_dsplymsg[2] = " has been placed for Customer: ",
			gr_customer.customer_num USING "<<<<<<<<<<<"
	    LET ga_dsplymsg[3] = "Order Date: ", gr_orders.order_date
	    CALL message_window(9, 13) 

	    CLEAR FORM

--* Phase 6 - create an invoice for the order
	    CALL invoice()
	  END IF
	ELSE
	  CLEAR FORM
	  CALL msg("Order has been terminated.")
	END IF
      END IF
    END IF
  END IF

END FUNCTION  -- add_order2 --

########################################
FUNCTION input_cust()
########################################
--* Purpose: Accept user input to identify a customer by
--*            customer number. Function provides a popup window 
--*            of valid customer numbers.
--* Argument(s): NONE
--* Return Value(s): TRUE - user has chosen a valid customer
--*                  FALSE - user has ended INPUT with Cancel key
---------------------------------------

  DISPLAY 
   " Enter the customer number and press RETURN. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)

  LET int_flag = FALSE
  INPUT BY NAME gr_customer.customer_num HELP 60
    BEFORE FIELD customer_num
--* Notify user of special popup window for this field
      MESSAGE "Enter a customer number or press F5 (CTRL-F) for a list."

    AFTER FIELD customer_num
--* Prevent user from leaving an empty customer_num field
      IF gr_customer.customer_num IS NULL THEN
	ERROR "You must enter a customer number. Please try again."
	NEXT FIELD customer_num
      END IF

--* Validate the customer_number entered. If valid, display the
--*  company name for the customer.
------------------------
      SELECT company, state
      INTO gr_customer.company, gr_customer.state
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
      EXIT INPUT

    ON KEY (CONTROL-F, F5)
      IF INFIELD(customer_num) THEN
--* If cursor is in the customer_num field, implement a popup window
--*   returning both a customer_num and company value.
------------------------
	CALL cust_popup()
	  RETURNING gr_customer.customer_num, gr_customer.company

--* If customer_num is NULL, user has not chosen a value from the
--*   popup window.
------------------------
 	IF gr_customer.customer_num IS NULL THEN
	  NEXT FIELD customer_num
	ELSE

--* If customer has been chosen, find the state for the customer.
--*   The state is needed for sales tax calculations.
------------------------
	  SELECT state
	  INTO gr_customer.state
	  FROM customer
	  WHERE customer_num = gr_customer.customer_num

	  DISPLAY BY NAME gr_customer.customer_num, gr_customer.company
	END IF
      END IF
	
  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    CLEAR FORM
    CALL msg("Order input terminated.")
    RETURN (FALSE)
  END IF

  RETURN (TRUE)
END FUNCTION  -- input_cust --

########################################
FUNCTION cust_popup()
########################################
--* Purpose: Implements the customer popup on the f_custsel form. 
--* Argument(s): NONE
--* Return Value(s): customer_num - number of chosen customer row
--*                                     OR
--*                              NULL if no customer rows exist or
--*                                   user pressed Interrupt key
--*                  company - company name of chosen customer row
---------------------------------------
  DEFINE	pa_cust ARRAY[200] OF RECORD
	       	  customer_num 	LIKE customer.customer_num,
	       	  company 	LIKE customer.company
		END RECORD,

		idx 		INTEGER,
		cust_cnt	INTEGER,
		array_sz 	SMALLINT,
		over_size	SMALLINT

  LET array_sz = 200		--* match size of pa_cust array

--* Open new window for popup and display f_custsel form
  OPEN WINDOW w_custpop AT 7, 5
    WITH 12 ROWS, 44 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_custsel FROM "f_custsel"
  DISPLAY FORM f_custsel

--* Display user instructions for popup
  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select a company."
    AT 2,2

--* c_custpop cursor will contain all customer rows, ordered by 
--*   customer number
------------------------
  DECLARE c_custpop CURSOR FOR
    SELECT customer_num, company 
    FROM customer
    ORDER BY customer_num

  LET over_size = FALSE

--* Read each customer row into the pa_cust array
  LET cust_cnt = 1
  FOREACH c_custpop INTO pa_cust[cust_cnt].*

--* Increment array index to get ready for next row
    LET cust_cnt = cust_cnt + 1

--* If new array index is bigger than size of pa_cust, set over_size
--*   to TRUE and stop reading customer rows
------------------------
    IF cust_cnt > array_sz THEN
      LET over_size = TRUE
      EXIT FOREACH
    END IF
  END FOREACH

--* If array index is still one, FOREACH loop never executed: have
--*  no customers rows in table.
------------------------
  IF cust_cnt = 1 THEN
    CALL msg("No customers exist in the database.")
    LET idx = 1
--* Return a NULL code to indicate no customer rows exist
    LET pa_cust[idx].customer_num = NULL
  ELSE  
--* If over_size is TRUE, notify user that not all rows can display
    IF over_size THEN
      MESSAGE "Customer array full: can only display ", 
	array_sz USING "<<<<<<"
    END IF

--* Initialize size of program array so ARR_COUNT() can track it
    CALL SET_COUNT(cust_cnt - 1)

--* Set int_flag to FALSE to make sure it correctly indicates Interrupt
    LET int_flag = FALSE

--* Display contents of pa_cust program array in sa_cust screen
--*   array (the screen array is defined within the f_custsel form)
------------------------
    DISPLAY ARRAY pa_cust TO sa_cust.* 

--* Once the DISPLAY ARRAY ends, obtains last position of cursor
--*   within the array. This position is the selected customer.
------------------------
    LET idx = ARR_CURR()

    IF int_flag THEN
      LET int_flag = FALSE
      CLEAR FORM
      CALL msg("No customer selected.")
      LET pa_cust[idx].customer_num = NULL
    END IF
  END IF

  CLOSE WINDOW w_custpop

--* Use idx as index into program array to get selected customer
--*   values
------------------------
  RETURN pa_cust[idx].customer_num, pa_cust[idx].company

END FUNCTION  -- cust_popup --

########################################
FUNCTION input_order()
########################################
--* Purpose: Accepts user input for order information on the 
--*            f_orders form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*		     FALSE - if user ends INPUT with Cancel key
---------------------------------------

  CALL clear_lines(1, 16)
  DISPLAY 
   " Enter the order information and press RETURN. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)

  LET int_flag = FALSE
  INPUT BY NAME gr_orders.order_date, gr_orders.po_num HELP 61
    BEFORE FIELD order_date
--* Initialize an empty field with today's date
      IF gr_orders.order_date IS NULL THEN
	LET gr_orders.order_date = TODAY
      END IF

    AFTER FIELD order_date
--* If user clears field, set it to today's date
      IF gr_orders.order_date IS NULL THEN
	LET gr_orders.order_date = TODAY
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    CLEAR FORM
    CALL msg("Order input terminated.")
    RETURN (FALSE)
  END IF

  RETURN (TRUE)
END FUNCTION  -- input_order --

########################################
FUNCTION input_items()
########################################
--* Purpose: Accepts user input for stock items on the bottom half
--*            of the f_orders form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*		     FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE 	curr_pa		INTEGER,
		curr_sa		INTEGER,
	 	stock_cnt	INTEGER,
	 	stock_item	LIKE stock.stock_num,
	 	popup		SMALLINT,
		keyval		INTEGER,
		valid_key	SMALLINT

  CALL clear_lines(1, 16)
  DISPLAY 
   " Enter the item information and press Accept. Press CTRL-W for Help."
    AT 16, 1 ATTRIBUTE (REVERSE, YELLOW)

  LET int_flag = FALSE
  INPUT ARRAY ga_items FROM sa_items.* HELP 62

    BEFORE ROW -- executed before cursor stops on a new line
      LET curr_pa = ARR_CURR()
      LET curr_sa = SCR_LINE()

--* Executed after user presses Insert key and before 4GL inserts new
--*   line into array
------------------------
    BEFORE INSERT
      CALL renum_items()

    BEFORE FIELD stock_num
--* Notify user of special popup window for stock_num field
      MESSAGE 
   "Enter a stock number or press F5 (CTRL-F) for a list."

--* Initialize popup flag to FALSE to indicate that user has not
--*   displayed the popup window
------------------------
      LET popup = FALSE

    AFTER FIELD stock_num
--* If stock_num field is empty, need to determine whether it can
--*   remain so.
------------------------
      IF ga_items[curr_pa].stock_num IS NULL THEN

--* NOTE: the FGL_LASTKEY() and FGL_KEYVAL() functions are new 4.1 features.
        LET keyval = FGL_LASTKEY()

--* If user pressed Accept, need to determine whether user has
--*   entered any items for the order. If no items entered,
--*   treat Accept like Cancel. If items entered, exit the
--*   item entry and save the items.
-----------------
        IF keyval = FGL_KEYVAL("accept") THEN
 	    IF curr_pa = 1 THEN 	--* empty items array
	      LET int_flag = TRUE	--* code simulates a Cancel
	      EXIT INPUT
	    END IF
        ELSE 		--* FGL_LASTKEY() <> FGL_KEYVAL("accept")

--* If user has not pressed Accept, check if key is trying to move
--*   back up into the array (left arrow, up arrow, previous page).
--*   If user pressed one of these keys, a null stock number is
--*   OK. If user pressed any other key, null stock number is
--*   invalid.
-----------------
	  LET valid_key = (keyval = FGL_KEYVAL("up"))
	      OR (keyval = FGL_KEYVAL("prevpage"))
	  IF NOT valid_key THEN
            ERROR "You must enter a stock number. Please try again."
	    NEXT FIELD stock_num
	  END IF
	END IF

      ELSE		--* stock number is not null, continue

--* If user has not filled stock_num using the popup window, must
--*   verify that stock_num entered is valid.
------------------------
	  IF NOT popup THEN
	    LET stock_cnt = 0

	    SELECT COUNT(*)
	    INTO stock_cnt
	    FROM stock
	    WHERE stock_num = ga_items[curr_pa].stock_num

	    IF (stock_cnt = 0) THEN
	      ERROR 
   "Unknown stock number. Use F5 (CTRL-F) to see valid stock numbers."
	      LET ga_items[curr_pa].stock_num = NULL
	      NEXT FIELD stock_num
	    END IF
	  END IF
      END IF

      MESSAGE ""

    BEFORE FIELD manu_code
--* Notify user of special popup window for manu_code field
      MESSAGE 
   "Enter the manufacturer code or press F5 (CTRL-F) for a list."

    AFTER FIELD manu_code
--* Prevent user from leaving empty manu_code field.
      IF ga_items[curr_pa].manu_code IS NULL THEN
	ERROR 
    "You must enter a manufacturer code. Use F5 (CTRL-F) to see valid codes."
	LET ga_items[curr_pa].manu_code = NULL
	NEXT FIELD manu_code

      ELSE

--* If user has not filled manu_code using the popup window, must 
--*   verify that manu_code entered is valid.
------------------------
	IF NOT popup THEN
          SELECT description, unit_price
	  INTO ga_items[curr_pa].description, ga_items[curr_pa].unit_price
	  FROM stock
	  WHERE stock_num = ga_items[curr_pa].stock_num
	    AND manu_code = ga_items[curr_pa].manu_code
 
	  IF (status = NOTFOUND) THEN
	    ERROR 
"Unknown manuf code for this stock number. Use F5 (CTRL-F) to see valid codes."
	    LET ga_items[curr_pa].manu_code = NULL
	    NEXT FIELD manu_code
	  END IF

--* Display associated information for specified item
	  DISPLAY ga_items[curr_pa].description, ga_items[curr_pa].unit_price 
	    TO sa_items[curr_sa].description, sa_items[curr_sa].unit_price
          MESSAGE ""
	  NEXT FIELD quantity
	END IF
      END IF

      MESSAGE ""

    BEFORE FIELD quantity
--* Initialize empty field to 1
      IF ga_items[curr_pa].quantity IS NULL THEN
	LET ga_items[curr_pa].quantity = 1
      END IF

    AFTER FIELD quantity
--* If quantity field is empty or contains a negative number, notify
--*   user.
------------------------
      IF ga_items[curr_pa].quantity IS NULL
          OR ga_items[curr_pa].quantity < 0 
      THEN
        ERROR "Quantity must be greater than 0. Please try again."
	NEXT FIELD quantity
      END IF

--* Calculate total price (quantity * unit price) for the item
      LET ga_items[curr_pa].total_price = ga_items[curr_pa].quantity 
		* ga_items[curr_pa].unit_price
      DISPLAY ga_items[curr_pa].total_price TO sa_items[curr_sa].total_price

--* Calculate total order amount (sum of total prices)
      CALL order_amount() RETURNING gr_orders.order_amount
      DISPLAY BY NAME gr_orders.order_amount
	  
--* Executed after user presses Insert key and after 4GL inserts new
--*   line into array
------------------------
    AFTER INSERT
--* After a new item is added, recalculate total order amount
      CALL order_amount() RETURNING gr_orders.order_amount

      DISPLAY BY NAME gr_orders.order_amount

--* Executed after user presses Delete key and after 4GL removes 
--*   current line from array
------------------------
    AFTER DELETE
--* After an item is deleted, renumber the items....
      CALL renum_items()

--* ... and recalculate the total order amount
      CALL order_amount() RETURNING gr_orders.order_amount

      DISPLAY BY NAME gr_orders.order_amount

    AFTER INPUT
--* After user ends the INPUT, clear out instructions and Message line
      CALL clear_lines(1, 16)
      MESSAGE ""

    ON KEY (CONTROL-F, F5)
--* If user is in either the stock_num or the manu_code field,
--*   implement the stock popup window
------------------------
      IF INFIELD(stock_num) OR INFIELD(manu_code) THEN

--* Value of stock_item determines contents of popup window. If
--*   stock_item is NULL, popup shows all stock items in inventory.
--*   If stock_item is not null, it contains the stock number
--*   of the current line and the popup window shows only those
--*   stock items with this stock number (different manufacturers)
------------------------
	IF INFIELD(stock_num) THEN
	  LET stock_item = NULL
	ELSE
	  LET stock_item = ga_items[curr_pa].stock_num
	END IF

--* Open stock popup window and return the stock number, manufacturer
--*   code, stock item description, and unit price.
------------------------
   	CALL stock_popup(stock_item) 
	  RETURNING ga_items[curr_pa].stock_num, ga_items[curr_pa].manu_code, 
           	  ga_items[curr_pa].description, ga_items[curr_pa].unit_price 

	IF ga_items[curr_pa].stock_num IS NULL THEN

--* if stock_num is NULL, stock_popup() called from stock_num
--*    field and user didn't select a stock item. Return cursor to 
--*    stock_num field. The manu_code is also null in this case.
-------------------------
	  NEXT FIELD stock_num
	ELSE		
	  IF ga_items[curr_pa].manu_code IS NULL THEN

--* Only manu_code is NULL so stock_popup() called from manu_code
--*    field and user didn't select a stock item. Return cursor 
--*    to manu_code field.
-------------------------
	    NEXT FIELD manu_code
	  END IF
	END IF

        DISPLAY ga_items[curr_pa].stock_num TO sa_items[curr_sa].stock_num
        DISPLAY ga_items[curr_pa].manu_code TO sa_items[curr_sa].manu_code
        DISPLAY ga_items[curr_pa].description TO 
		    sa_items[curr_sa].description
        DISPLAY ga_items[curr_pa].unit_price TO 
		    sa_items[curr_sa].unit_price
        NEXT FIELD quantity
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL clear_lines(2, 16)
    CLEAR FORM
    CALL msg("Order input terminated.")
    RETURN (FALSE)
  END IF

  RETURN (TRUE)
END FUNCTION  -- input_items --

########################################
FUNCTION renum_items()
########################################
--* Purpose: Renumbers order items on the f_orders form when an
--*            item is added or deleted. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	pcurr	INTEGER,
		ptotal  INTEGER,
		scurr	INTEGER,
		stotal	INTEGER, 
		k 	INTEGER

--* Obtain current array values
  LET pcurr = ARR_CURR()
  LET ptotal = ARR_COUNT()
  LET scurr = SCR_LINE()

--* Size of screen array is four (see f_orders form)
  LET stotal = 4

--* From current line of program array to end of program array,
--*   renumber the lines.
------------------------
  FOR k = pcurr TO ptotal
    LET ga_items[k].item_num = k
    IF scurr <= stotal THEN
      DISPLAY k TO sa_items[scurr].item_num
      LET scurr = scurr + 1
    END IF
  END FOR

END FUNCTION  -- renum_items --

########################################
FUNCTION stock_popup(stock_item)
########################################
--* Purpose: Implements the stock popup on the f_stocksel form. 
--* Argument(s): stock_item - NULL if popup is to show all stock rows
--*                           stock number is popup is to show only
--*                             those stock rows for a certain stock
--*                             number.
--* Return Value(s): stock_num - number of chosen stock row
--*                                     OR
--*                              NULL if no stock rows exist or
--*                                   user pressed Interrupt key
--*                  manu_code - manufacturer code of chosen stock row
--*                  description - description of chosen stock row
--*                  unit_price - unit price of chosen stock row
---------------------------------------
  DEFINE 	stock_item	INTEGER,

		pa_stock ARRAY[200] OF RECORD
	          stock_num 	LIKE stock.stock_num,
	          description 	LIKE stock.description,
	          manu_code 	LIKE stock.manu_code,
	          manu_name 	LIKE manufact.manu_name,
	          unit 		LIKE stock.unit,
	          unit_price 	LIKE stock.unit_price
	    	END RECORD,

		idx 		INTEGER,
		stock_cnt	INTEGER,
		st_stock	CHAR(300),
		array_sz	SMALLINT,
		over_size	SMALLINT

  LET array_sz = 200		--* match size of pa_stock array

--* Open new window for popup and display f_stocksel form
  OPEN WINDOW w_stockpop AT 7, 4
    WITH 12 ROWS, 73 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_stocksel FROM "f_stocksel"
  DISPLAY FORM f_stocksel

--* Display user instructions for popup
  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select a stock item."
    AT 2,2

--* Build SELECT statement for popup window based on value of
--*   stock_item (all stock rows or only those for a specified
--*   stock number).
------------------------
  LET st_stock = 
    "SELECT stock_num, description, stock.manu_code, manufact.manu_name, ",
    "unit, unit_price FROM stock, manufact"

  IF stock_item IS NOT NULL THEN
    LET st_stock = st_stock CLIPPED, " WHERE stock_num = ", stock_item,
	" AND stock.manu_code = manufact.manu_code",
	" ORDER BY 1, 3"
  ELSE
    LET st_stock = st_stock CLIPPED, 
	" WHERE stock.manu_code = manufact.manu_code",
	" ORDER BY 1, 3"
  END IF

--* Prepare SELECT statement and declare c_stockpop cursor to contain 
--*   appropriate stock rows, ordered by stock number and then
--*   manufacturer code
------------------------
  PREPARE slct_run FROM st_stock
  DECLARE c_stockpop CURSOR FOR slct_run

  LET over_size = FALSE

--* Read each stock row into the pa_stock array
  LET stock_cnt = 1
  FOREACH c_stockpop INTO pa_stock[stock_cnt].*

--* Increment array index to get ready for next row
    LET stock_cnt = stock_cnt + 1

--* If new array index is bigger than size of pa_stock, set over_size
--*   to TRUE and stop reading stock rows
------------------------
    IF stock_cnt > array_sz THEN
	LET over_size = TRUE
	EXIT FOREACH
    END IF
  END FOREACH

--* If array index is still one, FOREACH loop never executed: have
--*  no stock rows in table.
------------------------
  IF stock_cnt = 1 THEN
    CALL msg("No stock data in the database.")
    LET idx = 1
--* Return a NULL code to indicate no stock rows exist
    LET pa_stock[idx].stock_num = NULL
  ELSE  
--* If over_size is TRUE, notify user that not all rows can display
    IF over_size THEN
	MESSAGE "Stock array full: can only display ", 
	    array_sz USING "<<<<<<"
    END IF

--* Initialize size of program array so ARR_COUNT() can track it
    CALL SET_COUNT(stock_cnt - 1)

--* Set int_flag to FALSE to make sure it correctly indicates Interrupt
    LET int_flag = FALSE
    DISPLAY ARRAY pa_stock TO sa_stock.* 

    LET idx = ARR_CURR()

    IF int_flag THEN
      LET int_flag = FALSE
      CLEAR FORM
      CALL msg("No stock item selected.")

--* if popup called from stock_num field, need to clear both 
--*    manu_code and stock_num fields. if popup called from
--*    manu_code field, only need to clear manu_code so that
--*    stock_num entered remains.
----------------
      LET pa_stock[idx].manu_code = NULL
      IF stock_item IS NULL THEN	
        LET pa_stock[idx].stock_num = NULL
      END IF

    END IF
  END IF

  CLOSE WINDOW w_stockpop

--* Use idx as index into program array to get selected stock
--*   values
------------------------
  RETURN pa_stock[idx].stock_num, pa_stock[idx].manu_code,
	 pa_stock[idx].description, pa_stock[idx].unit_price

END FUNCTION  -- stock_popup --

########################################
FUNCTION dsply_taxes()
########################################
--* Purpose: Calculates the sales tax for an order. The
--*            sales tax rate is based on the state code of the
--*           customers address.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Get tax from based on customer's state code
  LET gr_charges.tax_rate = tax_rates(gr_customer.state)
  DISPLAY gr_customer.state TO code
  DISPLAY BY NAME gr_charges.tax_rate

--* Calculate sales tax (order amount * (tax rate / 100) )
  LET gr_charges.sales_tax = gr_orders.order_amount 
		* (gr_charges.tax_rate / 100)
  DISPLAY BY NAME gr_charges.sales_tax

--* Calculate order total (order amount + sales tax)
  LET gr_charges.order_total = gr_orders.order_amount + 
	gr_charges.sales_tax 
  DISPLAY BY NAME gr_charges.order_total

END FUNCTION  -- dsply_taxes --

########################################
FUNCTION order_amount()
########################################
--* Purpose: Calculates the total order amount by summing up the
--*            individual item totals. 
--* Argument(s): NONE
--* Return Value(s): the order amount
---------------------------------------
  DEFINE 	ord_amount 	MONEY(8),
		idx 		INTEGER

  LET ord_amount = 0.00
--* Loop through program array (ga_items), adding up all non-null
--*   total_price fields.
------------------------
  FOR idx = 1 TO ARR_COUNT()
    IF ga_items[idx].total_price IS NOT NULL THEN
      LET ord_amount = ord_amount + ga_items[idx].total_price
    END IF
  END FOR

  RETURN (ord_amount)

END FUNCTION  -- order_amount --

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
FUNCTION ship_order()
########################################
--* Purpose: Controls input of shipping information.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  CALL clear_lines(1, 1)

--* Open new window for f_ship form. Redefine Command line and
--*   Form line for this window to work with f_ship.
------------------------
  OPEN WINDOW w_ship AT 7, 6
    WITH FORM "f_ship"
    ATTRIBUTE (BORDER, COMMENT LINE 3, FORM LINE 4)

  DISPLAY " Press Accept to save shipping information."
    AT 1, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press Cancel to exit w/out saving. Press CTRL-W for Help."
    AT 2, 1 ATTRIBUTE (REVERSE, YELLOW)

--* Display form title
  DISPLAY "SHIPPING INFORMATION"
    AT 4, 20

--* Display known order information in top half of form
  DISPLAY BY NAME gr_orders.order_num, gr_orders.order_date,
		  gr_customer.customer_num, gr_customer.company

  INITIALIZE gr_ship.* TO NULL

--* Accept input of shipping info in lower half of form
  IF input_ship() THEN
    CALL msg("Shipping information entered.")
  END IF
  CLOSE WINDOW w_ship

END FUNCTION  -- ship_order --

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
FUNCTION order_tx()
########################################
--* Purpose: Controls the database transaction for adding a new
--*            order. A row must be added to the orders table and a
--*            row for each item must be added to the items table.
--* Argument(s): NONE
--* Return Value(s): TRUE - transaction was successful
--*                  FALSE - transaction was rolled back; order was
--*                          not saved
---------------------------------------
  DEFINE 	tx_stat			INTEGER,
		tx_table		CHAR(5)

--* Begin the transaction for the order
  BEGIN WORK

--* Insert the orders row for the new order
    LET tx_table = "order"
    LET tx_stat = insert_order()
--* If orders insert was successful, insert the items row(s)
    IF (tx_stat = 0) THEN		
      LET tx_table = "items"
      LET tx_stat = insert_items()
    END IF

--* If either insert failed, end the transaction by rolling it back
--*   (removing inserts on both tables: orders and items). The 
--*   tx_table variable notifies the user of which insert failed.
------------------------
    IF (tx_stat < 0) THEN
      ROLLBACK WORK
      ERROR tx_stat USING "-<<<<<<<<<<<",
	": Unable to save order: ", tx_table, " insert failed."
      RETURN (FALSE)
    END IF

--* If both database inserts have succeeded, end the transaction by
--*   committing it (saving data to database).
  COMMIT WORK

  RETURN (TRUE)

END FUNCTION  -- order_tx --

########################################
FUNCTION insert_order()
########################################
--* Purpose: Adds a new row to the orders table.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	ins_stat	INTEGER

  LET ins_stat = 0

--* Insert a new orders row with values stored in gr_orders global
--*  record.
------------------------
WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
    INSERT INTO orders (order_num, order_date, customer_num, po_num, 
	ship_date, ship_instruct, ship_weight, ship_charge)
      VALUES (0, gr_orders.order_date, gr_customer.customer_num, 
	      gr_orders.po_num, gr_ship.ship_date, gr_ship.ship_instruct, 
	      gr_ship.ship_weight, gr_ship.ship_charge)
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

    IF status < 0 THEN

--* If INSERT was not successful, save status number.
      LET ins_stat = status
    ELSE

--* If INSERT was successful, obtain new order number from the
--*  SERIAL order_num column. This value is stored in the 
--*  SQLCA built-in record.
------------------------
      LET gr_orders.order_num = SQLCA.SQLERRD[2]
      DISPLAY BY NAME gr_orders.order_num 
        ATTRIBUTE (REVERSE, BLUE)
    END IF

    RETURN (ins_stat)

END FUNCTION  -- insert_order --

########################################
FUNCTION insert_items()
########################################
--* Purpose: Adds new rows to the items table.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE idx 		INTEGER,
	 ins_stat	INTEGER

  LET ins_stat = 0

--* From current line of program array to end of program array,
--*   add a new items row for each non-null stock item in the
--*   order.
------------------------
  FOR idx = 1 TO ARR_COUNT()
    IF ga_items[idx].stock_num IS NOT NULL THEN

WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
      INSERT INTO items 
      VALUES (ga_items[idx].item_num, gr_orders.order_num, 
	      ga_items[idx].stock_num, ga_items[idx].manu_code,
              ga_items[idx].quantity, ga_items[idx].total_price)
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

      IF status < 0 THEN
--* If INSERT was not successful, save status number.
	LET ins_stat = status
        EXIT FOR
      END IF
    END IF
  END FOR

--* Return status of INSERT
  RETURN (ins_stat)

END FUNCTION  -- insert_items --

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
FUNCTION invoice()
########################################
--* Purpose: Starts report and then sends order/item info to report,
--*            one at a time.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE pr_invoice  RECORD
          	  	order_num	LIKE orders.order_num,
            	  	order_date	LIKE orders.order_date,
            	  	ship_instruct	LIKE orders.ship_instruct,
           	  	po_num		LIKE orders.po_num,
            	  	ship_date	LIKE orders.ship_date,
            	  	ship_weight	LIKE orders.ship_weight,
            	  	ship_charge	LIKE orders.ship_charge,
            	  	item_num	LIKE items.item_num,
            	  	stock_num	LIKE items.stock_num,
            	  	description	LIKE stock.description,
            	  	manu_code	LIKE items.manu_code,
            	  	manu_name	LIKE manufact.manu_name,
            	  	quantity	LIKE items.quantity,
            	  	total_price	LIKE items.total_price,
            	  	unit		LIKE stock.unit,
            	  	unit_price	LIKE stock.unit_price
        	    END RECORD,

    		file_name 	CHAR(20),
		inv_msg		CHAR(40),
		print_option	CHAR(1),
		scr_flag	SMALLINT

--* Ask user where to send report output: screen, file, or printer
  LET print_option = report_output("ORDER INVOICE", 13, 10)

--* Start report and send output to destination selected by user
  CASE (print_option)
    WHEN "F"
      LET file_name = "inv", gr_orders.order_num USING "<<<<&",".out" 
      START REPORT invoice_rpt TO file_name
      MESSAGE "Writing invoice to ", file_name CLIPPED," -- please wait."
    WHEN "P"
      START REPORT invoice_rpt TO PRINTER
      MESSAGE "Sending invoice to printer -- please wait."
    WHEN "S"
      START REPORT invoice_rpt 
      MESSAGE "Preparing invoice for screen -- please wait."
  END CASE

--* Get data for order's customer
  SELECT * 
  INTO gr_customer.*
  FROM customer
  WHERE customer_num = gr_customer.customer_num

--* Assign ship charge to gr_charges record so that it can be
--*   accessed within the report
------------------------
  LET gr_charges.ship_charge = gr_ship.ship_charge

--* Set flag to indicate whether output goes to screen
  IF print_option = "S" THEN
    LET scr_flag = TRUE
  ELSE
    LET scr_flag = FALSE
  END IF

--* Cursor c_invoice will contain order and item information.
  DECLARE c_invoice CURSOR FOR 
    SELECT o.order_num, o.order_date, o.ship_instruct, o.po_num, 
	   o.ship_date, o.ship_weight, o.ship_charge, i.item_num, 
	   i.stock_num, s.description, i.manu_code, m.manu_name, 
	   i.quantity, i.total_price, s.unit, s.unit_price
    FROM orders o, items i, stock s, manufact m
    WHERE ( (o.order_num = gr_orders.order_num) AND
	    (i.order_num = o.order_num) AND
            (i.stock_num = s.stock_num AND i.manu_code = s.manu_code) AND
            (i.manu_code = m.manu_code) )
    ORDER BY 8

--* Send a single order/item line to the report. Order info is duplicated 
--*   in pr_invoice record each time because report needs to be able to 
--*   have identical info each time it is called. What differs in each 
--*   call is the item information.
------------------------
  FOREACH c_invoice INTO pr_invoice.* 
    OUTPUT TO REPORT 
      invoice_rpt (gr_customer.*, pr_invoice.*, gr_charges.*, scr_flag)
  END FOREACH

  FINISH REPORT invoice_rpt

--* When report completes, remind user where it was sent.
  CASE (print_option)
    WHEN "F"
      LET inv_msg = "Invoice written to file ", file_name CLIPPED
    WHEN "P"
      LET inv_msg = "Invoice sent to the printer." 
    WHEN "S"
      LET inv_msg = "Invoice sent to the screen." 
  END CASE
  CALL msg(inv_msg)

END FUNCTION  -- invoice --

########################################
FUNCTION report_output(menu_title, x,y)
########################################
--* Purpose: Displays a menu giving user the possible destinations
--*            for a report.
--*            form. 
--* Argument(s): menu_title - title to display for menu 
--*              x - x coordinate (row) for menu's window
--*              y - y coordinate (column) for menu's window
--* Return Value(s): "S" - send output to screen
--*                  "F" - send output to file
--*                  "P" - send output to printer
---------------------------------------
  DEFINE	menu_title	CHAR(15),
		x		SMALLINT,
		y		SMALLINT,

		rpt_out		CHAR(1)

  OPEN WINDOW w_rpt AT x, y
    WITH 2 ROWS, 41 COLUMNS
    ATTRIBUTE (BORDER)

--* This menu provides a list of possible report destinations. To
--* allow customization of the menu, the name of the menu is passed 
--* in as an argument.
--* NOTE: having a variable as the menu title is a new 4.1 feature.
------------------------
  MENU menu_title
    COMMAND "File" "Save report output in a file.          "
      LET rpt_out = "F"
      EXIT MENU

    COMMAND "Printer" "Send report output to the printer.     "
      LET rpt_out = "P"
      EXIT MENU

    COMMAND "Screen" "Send report output to the screen.      "
--* Warn user that sending output to the screen means that the output
--*   cannot be saved.
------------------------
      LET ga_dsplymsg[1] = "Output is not saved after it is sent to "
      LET ga_dsplymsg[2] = "            the screen." 
      LET x = x - 1
      LET y = y + 2
      IF prompt_window("Are you sure you want to use the screen?", x, y)
      THEN
        LET rpt_out = "S"
	EXIT MENU
      ELSE
	NEXT OPTION "File"
      END IF
  END MENU

  CLOSE WINDOW w_rpt
  RETURN rpt_out

END FUNCTION  -- report_output --


##############################################################
REPORT invoice_rpt (pr_cust, pr_invoice, pr_charges, scr_flag)
##############################################################
--* Purpose: Report function to create an invoice for an order.
--* Argument(s): pr_cust - record containing customer info
--*              pr_invoice - record containing order and items info
--*              pr_charges - record containing order amount
--*              scr_flag - TRUE if output goes to screen
--*                           and needs to be "paged"
--*                         FALSE  if output goes elsewhere
--* Return Value(s): NONE
---------------------------------------
  DEFINE pr_cust        RECORD LIKE customer.*,
         pr_invoice	RECORD
            		  order_num	LIKE orders.order_num,
            		  order_date	LIKE orders.order_date,
            		  ship_instruct	LIKE orders.ship_instruct,
            		  po_num	LIKE orders.po_num,
            		  ship_date	LIKE orders.ship_date,
            		  ship_weight	LIKE orders.ship_weight,
            	  	  ship_charge	LIKE orders.ship_charge,
            		  item_num	LIKE items.item_num,
            		  stock_num	LIKE items.stock_num,
            		  description	LIKE stock.description,
            		  manu_code	LIKE items.manu_code,
            		  manu_name	LIKE manufact.manu_name,
            		  quantity	LIKE items.quantity,
            		  total_price	LIKE items.total_price,
            		  unit		LIKE stock.unit,
            		  unit_price	LIKE stock.unit_price
            		  END RECORD,
	 pr_charges 	RECORD
		  	  tax_rate	DECIMAL(5,3),
		  	  ship_charge	LIKE orders.ship_charge,
		  	  sales_tax	MONEY(9),
		  	  order_total	MONEY(11)
	    		END RECORD,

	 scr_flag	SMALLINT,
         name_str 	CHAR(37),
         sub_total 	MONEY(10,2)

--* Establish report margins and page defaults
  OUTPUT
    LEFT MARGIN 0
    RIGHT MARGIN 0
    TOP MARGIN 1
    BOTTOM MARGIN 1
    PAGE LENGTH 48

  FORMAT
--* Executed each time a new value of order_num appears in the record
    BEFORE GROUP OF pr_invoice.order_num
      LET sub_total = 0.00
      SKIP TO TOP OF PAGE

--* Provide an invoice header with name and address of the company
--*   preparing the invoice, and the date.
------------------------
      SKIP 1 LINE
      PRINT 10 SPACES,
        "   W E S T   C O A S T   W H O L E S A L E R S ,   I N C ."
      PRINT 30 SPACES, " 1400 Hanbonon Drive"
      PRINT 30 SPACES, "Menlo Park, CA  94025"
      PRINT 32 SPACES, TODAY USING "ddd. mmm dd, yyyy"
      SKIP 4 LINES

--* Identify the invoice 
      PRINT COLUMN 2, "Invoice Number: ", 
	  pr_invoice.order_num USING "&&&&&&&&&&&",
        COLUMN 46, "Bill To: Customer Number ", pr_cust.customer_num 
	  USING "<<<<<<<<<<&"
      PRINT COLUMN 2, "Invoice Date:", 
	COLUMN 18, pr_invoice.order_date USING "ddd. mmm dd, yyyy",
	COLUMN 55, pr_cust.company

      PRINT COLUMN 2, "PO Number:", 
	COLUMN 18, pr_invoice.po_num,
	COLUMN 55, pr_cust.address1

--* Determine whether need to print a second address line
      IF (pr_cust.address2 IS NOT NULL) THEN
	PRINT COLUMN 55, pr_cust.address2
      ELSE
	PRINT COLUMN 55, pr_cust.city CLIPPED, ", ",
	  pr_cust.state CLIPPED, "   ", pr_cust.zipcode CLIPPED
      END IF

--* If second address was printed, print the city, state data. If no
--*   second address line, this info was already printed on the previous
--*   line so just print blanks.
------------------------
      IF (pr_cust.address2 IS NOT NULL) THEN
	PRINT COLUMN 55, pr_cust.city CLIPPED, ", ",
	  pr_cust.state CLIPPED, "   ", pr_cust.zipcode CLIPPED
      ELSE
	PRINT COLUMN 55, "      "
      END IF

--* If a contact name is defined, create a string variable containing
--*   the ATTN: line. If none defined, just set this string to blanks.
------------------------
      IF (pr_cust.lname IS NOT NULL) THEN
  	LET name_str = "ATTN: ", pr_cust.fname CLIPPED, " ",
		pr_cust.lname CLIPPED
      ELSE
 	LET name_str = "     "
      END IF

--* Print shipping information
      PRINT COLUMN 2, "Ship Date:"; 
      IF (pr_invoice.ship_date IS NULL) THEN
	PRINT COLUMN 15, "Not Shipped";
      ELSE
	PRINT COLUMN 15, pr_invoice.ship_date USING "ddd. mmm dd, yyyy";
      END IF
--* If customer address had two lines, need to skip a line before printing
--*   ATTN line. If only one line of address, print ATTN line (line
--*   has already been skipped on previous line).
------------------------
      IF (pr_cust.address2 IS NOT NULL) THEN
	PRINT COLUMN 55, "     "
      ELSE
	PRINT COLUMN 49, name_str CLIPPED
      END IF

      PRINT COLUMN 2, "Ship Weight: ";
      IF (pr_invoice.ship_weight IS NULL) THEN
	PRINT "N/A";
      ELSE
	PRINT pr_invoice.ship_weight USING "<<<<<<<&.&&", " lbs.";
      END IF
--* If customer address had two lines, now can print ATTN line.
      IF (pr_cust.address2 IS NOT NULL) THEN
	PRINT COLUMN 49, name_str CLIPPED
      ELSE
	PRINT COLUMN 55, "     "
      END IF
      PRINT COLUMN 2, "Shipping Instructions:";
--* If no shipping instructions provided, just print "None".
      IF (pr_invoice.ship_instruct IS NULL) THEN
	PRINT COLUMN 25, "None"
      ELSE
	PRINT COLUMN 25, pr_invoice.ship_instruct
      END IF
      SKIP 1 LINE

      PRINT "----------------------------------------";
      PRINT "---------------------------------------"
      PRINT COLUMN 2, "Item",
	COLUMN 10, "Stock",
	COLUMN 18, "Manuf",
	COLUMN 56, "Unit"
      PRINT COLUMN 2, "Number",
	COLUMN 10, "Number",
	COLUMN 18, "Code",
	COLUMN 24, "Description",
	COLUMN 41, "Qty",
	COLUMN 49, "Unit",
	COLUMN 56, "Price",
	COLUMN 68, "Item Total"
      PRINT " ------  ------  ----- ---------------  ------  ----   --------";
      PRINT "    ----------"

--* Above PRINT lines print invoice headings for ordered items.
--*   Headings appear as shown in following commented lines:
{
 Item    Stock   Manuf                                 Unit
 Number  Number  Code  Description      Qty     Unit   Price       Item Total 
 ------  ------  ----- ---------------  ------  ----   --------    -----------
 XXXXXX  XXXXXX  XXX   XXXXXXXXXXXXXXX  XXXXXX  XXXX   $X,XXX.XX   $XXX,XXX.XX
}

--* Executed for every record sent to report
    ON EVERY ROW

--* Print order item data, lining data up with headings as shown by
--*   XX's in above comments.
------------------------
      PRINT COLUMN 2, pr_invoice.item_num USING "#####&",
	COLUMN 10, pr_invoice.stock_num USING "&&&&&&", 
	COLUMN 18, pr_invoice.manu_code,
	COLUMN 24, pr_invoice.description,
	COLUMN 41, pr_invoice.quantity USING "#####&",
	COLUMN 49, pr_invoice.unit,
	COLUMN 56, pr_invoice.unit_price USING "$,$$&.&&",
	COLUMN 68, pr_invoice.total_price USING "$$$,$$&.&&"

--* Calculate sub_total of invoice
      LET sub_total = sub_total + pr_invoice.total_price

--* Executed after value of order_num field changes.
    AFTER GROUP OF pr_invoice.order_num
      SKIP 1 LINE

      PRINT "----------------------------------------";
      PRINT "---------------------------------------"

      PRINT COLUMN 53, "Sub-total: ", 
	COLUMN 65, sub_total USING "$$,$$$,$$&.&&"

      PRINT COLUMN 43, "Sales Tax (", 
	  pr_charges.tax_rate USING "#&.&&&", "%): ",
	COLUMN 66, pr_charges.sales_tax USING "$,$$$,$$&.&&"

      IF (pr_invoice.ship_charge IS NULL) THEN
	LET pr_invoice.ship_charge = 0.00
      END IF
      PRINT COLUMN 47, "Shipping Charge: ",
	COLUMN 70, pr_invoice.ship_charge USING "$,$$&.&&"

      PRINT COLUMN 64, "--------------"
      PRINT COLUMN 57, "Total: ", 
	pr_charges.order_total USING "$$$,$$$,$$&.&&"

--* If user has chosen to send the invoice to the screen, this flat is
--*   TRUE. In this case, provide a pause after the invoice so data does not
--*   scroll off the screen. Notify user how to return to main program.
------------------------
      IF scr_flag THEN
	PAUSE "Press RETURN to continue."
      END IF

END REPORT  -- invoice_rpt --

