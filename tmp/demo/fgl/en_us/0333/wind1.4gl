
DATABASE stores

#	The GLOBALS statement defines two program records
#	and a program array used throughout the program.

GLOBALS

	DEFINE 

	p_customer	 RECORD 
			 customer_num LIKE customer.customer_num,
			 fname LIKE customer.fname,
			 lname LIKE customer.lname,
			 address1 LIKE customer.address1,
			 address2 LIKE customer.address2,
			 city LIKE customer.city,
			 state LIKE customer.state,
			 zipcode LIKE customer.zipcode,
			 phone LIKE customer.phone

			 END RECORD,

	p_orders	 RECORD 

			 order_num LIKE orders.order_num,
			 order_date LIKE orders.order_date,
			 ship_date LIKE orders.ship_date

			 END RECORD,

	p_items		 ARRAY[10] OF RECORD
	
			 item_num LIKE items.item_num,
			 stock_num LIKE items.stock_num,
			 manu_code LIKE items.manu_code,
			 description LIKE stock.description,
			 quantity LIKE items.quantity,
			 unit_price LIKE stock.unit_price,
			 total_price LIKE items.total_price

			 END RECORD

END GLOBALS


#	The MAIN statement opens the order form and displays
#	the form on the screen.  It calls the enter_order function
#	that allows the user to enter information about a 
#	customer order into the database.

MAIN

	OPEN FORM orderform FROM "order"

	DISPLAY FORM orderform

	CALL enter_order()

	CALL mess("End program.")

	CLEAR SCREEN

END MAIN

#	The enter_order function allows the user to enter an
#	order for a customer on the order form, inserts the
#	order into the stores database, and displays the
#	order number for the new order.

FUNCTION enter_order()

	DEFINE pa_curr,sc_curr, stock	 SMALLINT,
		m_code CHAR(3)

	CALL get_cust()

	CALL mess("Enter an order date and a ship date.")

	INPUT p_orders.order_date, p_orders.ship_date
		FROM order_date, ship_date

	CALL mess("Enter up to ten items.")

	INPUT ARRAY p_items FROM s_items.*

		BEFORE FIELD stock_num
		MESSAGE "Enter a stock number or press CTRL-B for help."

		BEFORE FIELD manu_code
	        MESSAGE "Enter the manufacturing code or ",
			"press CTRL-B for help."

		BEFORE FIELD quantity
		MESSAGE "Enter a quantity."

		ON KEY (CONTROL-B)
			IF infield(stock_num) OR infield(manu_code) THEN
				CALL stock_help()
				NEXT FIELD quantity
			END IF

		AFTER FIELD stock_num, manu_code
			MESSAGE ""

			LET pa_curr = arr_curr()

			IF 	p_items[pa_curr].stock_num IS NOT NULL
				AND p_items[pa_curr].manu_code IS NOT NULL 
			THEN
				CALL get_item()

				IF p_items[pa_curr].quantity IS NOT NULL THEN

					CALL get_total()

				END IF

			END IF

		AFTER FIELD quantity
			MESSAGE ""

			LET pa_curr = arr_curr()

			IF p_items[pa_curr].stock_num IS NOT NULL
				AND p_items[pa_curr].manu_code IS NOT NULL 
				AND p_items[pa_curr].quantity IS NOT NULL
			THEN
				CALL get_total()

			END IF


		BEFORE INSERT

			CALL get_item_num()

		AFTER INSERT

			CALL renum_items()

		AFTER DELETE 	

			CALL renum_items()

	END INPUT 

	INSERT INTO orders (order_num, order_date, customer_num, ship_date)
		VALUES (0,
			p_orders.order_date, 
			p_customer.customer_num,
			p_orders.ship_date)

	LET p_orders.order_num = SQLCA.SQLERRD[2]

	DISPLAY p_orders.order_num TO order_num

	CALL insert_items()

	CALL mess("Order added.")

END FUNCTION

#	The get_cust function retrieves customer information from the
#	stores database and displays it on the screen form.

FUNCTION get_cust()

	WHILE TRUE

		PROMPT "Enter a customer number or press CTRL-B for help:  "
			FOR p_customer.customer_num
			ON KEY (CONTROL-B)
				LET p_customer.customer_num = show_cust()
		END PROMPT

		SELECT fname, lname, address1, address2,
			city, state, zipcode, phone
			INTO p_customer.fname THRU p_customer.phone
			FROM customer 
			WHERE customer_num = p_customer.customer_num

		IF status = 0 THEN

			EXIT WHILE
		ELSE
			CALL mess("No customer with that customer number.")

		END IF

	END WHILE

	DISPLAY p_customer.* TO customer.*

END FUNCTION

#	The show_cust function opens a window, allows the user to
#	select a customer, and returns the customer number to the
#	get_cust function.

FUNCTION show_cust()

	DEFINE p_cust ARRAY[25] OF RECORD
		fname LIKE customer.fname,
		lname LIKE customer.lname,
		company LIKE customer.company
		END RECORD,
		p_custnum ARRAY[25] OF integer,
		counter SMALLINT

	OPEN WINDOW cwindo AT 10,15
		WITH FORM "cust"
		ATTRIBUTE(BORDER, MESSAGE LINE FIRST)

	DECLARE cust_list CURSOR FOR
		SELECT fname, lname, company, customer_num FROM customer

	LET counter = 1

	FOREACH cust_list INTO p_cust[counter].*, p_custnum[counter]
		LET counter = counter + 1
		IF counter > 25 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	CALL set_count(counter -1)

	MESSAGE "Highlight a customer name and press ESC"

	DISPLAY ARRAY p_cust TO s_cust.*

	LET counter = arr_curr()

	CLOSE WINDOW cwindo

	RETURN p_custnum[counter]
	
END FUNCTION

#	The stock_help function is called when the cursor is in the
#	stock_num or manu_code field and the user presses CONTROL-B.

FUNCTION stock_help()
	DEFINE pa_curr, sc_curr SMALLINT
	LET sc_curr = scr_line()
	LET pa_curr = arr_curr()
	CALL get_stock() RETURNING 
		p_items[pa_curr].stock_num,
		p_items[pa_curr].manu_code,
		p_items[pa_curr].description,
		p_items[pa_curr].unit_price
	DISPLAY p_items[pa_curr].stock_num, 
		p_items[pa_curr].manu_code, 
		p_items[pa_curr].description,  
		p_items[pa_curr].unit_price 
	TO s_items[sc_curr].stock_num, 
		s_items[sc_curr].manu_code,
		s_items[sc_curr].description, 
		s_items[sc_curr].unit_price

END FUNCTION

#	The get_stock function opens a window, allows the user to
#	query the database for information about stock items, and
#	returns information about a selected item to the stock_help function.

FUNCTION get_stock()

	DEFINE p_stock ARRAY[25] OF RECORD
		manu_name LIKE manufact.manu_name,
		description LIKE stock.description,
		unit LIKE stock.unit,
		unit_price LIKE stock.unit_price
		END RECORD,

		p_sn_mc ARRAY[25] OF RECORD
		stock_num LIKE stock.stock_num,
		manu_code LIKE stock.manu_code
		END RECORD,

		counter SMALLINT,
		query_1, sel_stmt CHAR(500)

	OPEN WINDOW w AT 10,8
		WITH FORM "stock1"
		ATTRIBUTE(BORDER, MESSAGE LINE FIRST)


	WHILE TRUE

		MESSAGE "Enter search criteria for one or more items."

		CONSTRUCT query_1 ON 
		manu_name, description, unit, unit_price
		FROM s_stock[1].*

		LET sel_stmt = 
		"SELECT manu_name, description, unit, unit_price, ",
		"stock_num, stock.manu_code ",
		"FROM stock, manufact ",
		"WHERE stock.manu_code = manufact.manu_code AND ",
		query_1 CLIPPED

		PREPARE s1 FROM sel_stmt

		DECLARE stock_list CURSOR FOR s1

		LET counter = 1

		FOREACH stock_list INTO  p_stock[counter].*, p_sn_mc[counter].*
			LET counter = counter + 1
			IF counter > 25 THEN
				EXIT FOREACH
			END IF
		END FOREACH

		IF counter = 1 THEN

			MESSAGE "No items satisfy the search criteria."
			SLEEP 3
		ELSE
			EXIT WHILE

		END IF

	END WHILE

	CALL set_count(counter -1)

	MESSAGE "Highlight a stock item and press ESC"

	DISPLAY ARRAY p_stock TO s_stock.*

	LET counter = arr_curr()

	CLOSE WINDOW w

	RETURN p_sn_mc[counter].stock_num, 
		p_sn_mc[counter].manu_code,
		p_stock[counter].description, 
		p_stock[counter].unit_price

END FUNCTION


#	The get_item function selects the description and unit price
#	for an item from the database, enters this information into
#	the program array, and displays the information on the 
#	screen form.

FUNCTION get_item()

	DEFINE pa_curr, sc_curr SMALLINT

	LET pa_curr = arr_curr()
	LET sc_curr = scr_line()

	SELECT description, unit_price
		INTO	p_items[pa_curr].description,
			p_items[pa_curr].unit_price
		FROM	stock
		WHERE	stock.stock_num = p_items[pa_curr].stock_num
			AND stock.manu_code = p_items[pa_curr].manu_code

	DISPLAY p_items[pa_curr].description, 
			p_items[pa_curr].unit_price
		TO s_items[sc_curr].description,
			s_items[sc_curr].unit_price

END FUNCTION

#	The get_total function computes the total price for an item
#	and displays this value on the form.

FUNCTION get_total()

	DEFINE pa_curr, sc_curr SMALLINT

	LET pa_curr = arr_curr()

	LET sc_curr = scr_line()

	LET p_items[pa_curr].total_price =
		p_items[pa_curr].quantity * p_items[pa_curr].unit_price

	DISPLAY p_items[pa_curr].total_price
		TO s_items[sc_curr].total_price

END FUNCTION


#	The get_item_num function displays the item number of the
#	current program array row before the user begins entering
#	information.

FUNCTION get_item_num()

	DEFINE pa_curr, sc_curr SMALLINT

	LET pa_curr = arr_curr()

	LET sc_curr = scr_line()

	LET p_items[pa_curr].item_num = pa_curr

	DISPLAY pa_curr TO s_items[sc_curr].item_num

END FUNCTION


FUNCTION renum_items()

	DEFINE pa_curr,
		pa_total,
		sc_curr,
		sc_total,
		k	SMALLINT

	LET pa_curr = arr_curr()

	LET pa_total = arr_count()

	LET sc_curr = scr_line()

	LET sc_total = 4

	FOR k = pa_curr TO pa_total

		LET p_items[k].item_num = k

		IF sc_curr <= sc_total THEN

			DISPLAY k TO s_items[sc_curr].item_num

			LET sc_curr = sc_curr + 1

		END IF

	END FOR

END FUNCTION


#	The insert_items function inserts the items in the program array
#	into the database.

FUNCTION insert_items()

	DEFINE counter SMALLINT

	FOR counter = 1 TO arr_count()

		INSERT INTO items 
			VALUES (p_items[counter].item_num,
				p_orders.order_num,
				p_items[counter].stock_num,
				p_items[counter].manu_code,
				p_items[counter].quantity,
				p_items[counter].total_price)

	END FOR

END FUNCTION

#	The mess function displays a message on line 23 of the screen.
#	Other functions in the program pass character strings 
#	to the mess function.

FUNCTION mess(str)

	DEFINE str CHAR(50)

	DISPLAY str CLIPPED AT 23,1

	SLEEP 3

	DISPLAY "" AT 23, 1

END FUNCTION


