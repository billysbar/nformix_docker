DATABASE stores

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


MAIN

	OPEN FORM orderform FROM "order"

	DISPLAY FORM orderform

	CALL get_order()

	MESSAGE "End program."

	SLEEP 3

	CLEAR SCREEN

END MAIN



FUNCTION get_order()

	DEFINE
		query_1, s1	CHAR(800),
		exist SMALLINT,
		answer	CHAR(1)

	MESSAGE "Enter search criteria for one or more orders."

	SLEEP 3

	MESSAGE ""

	CONSTRUCT query_1 ON customer.customer_num, fname, lname,
		address1, address2, city, state, zipcode, phone,
		orders.order_num, order_date, ship_date,
		items.stock_num, items.manu_code, quantity, total_price
		FROM customer.*, orders.*, stock_num, 
		manu_code, quantity, total_price

	LET s1 = "SELECT UNIQUE customer.customer_num, fname, lname, ",
		"address1, address2, city, state, zipcode, phone, ",
		"orders.order_num, order_date, ship_date ",
		"FROM customer, orders, items ",
		"WHERE customer.customer_num = orders.customer_num AND ",
		"orders.order_num = items.order_num AND ",
		query_1 CLIPPED, 
		" ORDER BY customer.customer_num, orders.order_num"

	PREPARE s_1 FROM s1

	DECLARE q_curs CURSOR FOR s_1

	LET exist = 0

	FOREACH q_curs INTO p_customer.*, p_orders.*

		LET exist = 1

		CLEAR FORM

		DISPLAY BY NAME p_customer.*

		DISPLAY BY NAME p_orders.*

		PROMPT "Do you want to view the items for this order (y/n) : "
			FOR answer

		IF answer = "y" THEN

			CALL get_items()

		END IF

		PROMPT "Do you want to see the next order (y/n) : "
			FOR answer

		IF answer = "n" THEN

			EXIT FOREACH

		END IF

	END FOREACH

	IF exist = 0 THEN

		MESSAGE "No rows satisfy the search criteria."
	ELSE

		IF answer = "y" THEN

			MESSAGE "No more rows satisfy the search criteria."

		END IF

	END IF

	SLEEP 3

END FUNCTION

FUNCTION get_items()

	DEFINE counter SMALLINT

	DECLARE my_curs CURSOR FOR
		SELECT item_num, items.stock_num, items.manu_code,
		description, quantity, unit_price, total_price
		FROM items, stock
		WHERE order_num = p_orders.order_num
		AND items.stock_num = stock.stock_num
		AND items.manu_code = stock.manu_code
		ORDER BY item_num

	LET counter = 1

	FOREACH my_curs INTO p_items[counter].*

		LET counter = counter + 1

	END FOREACH
		
	CALL set_count(counter - 1)

	MESSAGE "Press ESC when you finish viewing the items."

	DISPLAY ARRAY p_items TO s_items.*

	MESSAGE ""

END FUNCTION
