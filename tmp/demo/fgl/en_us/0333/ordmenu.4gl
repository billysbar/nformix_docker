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

			 END RECORD,

	chosen	 SMALLINT

END GLOBALS


MAIN

	OPEN FORM orderform FROM "order"

	DISPLAY FORM orderform

	LET chosen = 0

	CALL show_menu()

	CALL mess("End program.")

	CLEAR SCREEN

END MAIN

FUNCTION show_menu()

	DEFINE	answer	 CHAR(1)

	MENU "ORDER"

		COMMAND "Add" "Add a new order."

			LET answer = "y"

			WHILE answer = "y"

				CALL enter_order()

				PROMPT "Do you want to ",
					"enter another order (y/n) : "
					FOR answer

			END WHILE

			LET chosen = 1

		COMMAND "Query" "Search for an order."

			CALL get_order()

		COMMAND "Modify" "Change an order."

			IF chosen = 1 THEN

				CALL change_order()

			ELSE

				CALL mess("No order has been chosen.")

			END IF

		COMMAND "Delete" "Delete an order."

			IF chosen = 1 THEN

				CALL clear_menu()

				PROMPT "Are you sure you want ",
					"to delete this order (y/n) : "
					FOR answer

				IF answer = "y" THEN

					CALL delete_order()

					LET chosen = 0

				END IF

			ELSE

				CALL mess("No order has been chosen.")

			END IF

		COMMAND "Exit" "Exit the ORDER Menu."

			EXIT MENU

	END MENU

END FUNCTION

FUNCTION enter_order()

	DEFINE pa_curr	 SMALLINT

	CALL clear_menu()

	CLEAR FORM

	CALL get_cust()

	CALL mess("Enter an order date and a ship date.")

	INPUT p_orders.order_date, p_orders.ship_date
		FROM order_date, ship_date

	CALL mess("Enter up to ten items.")


	INPUT ARRAY p_items FROM s_items.*

		BEFORE FIELD stock_num
			MESSAGE "Enter a stock number."

		BEFORE FIELD manu_code
			MESSAGE "Enter the code for a manufacturer."

		BEFORE FIELD quantity
			MESSAGE "Enter a quantity."

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


FUNCTION get_order()

	DEFINE
		counter,exist	SMALLINT,
		answer	CHAR(1)

	CALL clear_menu()

	CLEAR FORM

	CALL get_cust()

	DECLARE q_curs CURSOR FOR
		SELECT order_num, order_date, ship_date
			FROM orders
			WHERE customer_num = p_customer.customer_num	

	LET exist = 0

	LET chosen = 0

	FOREACH q_curs INTO p_orders.*

		LET exist = 1

		CLEAR orders.*

		FOR counter = 1 TO 4

			CLEAR s_items[counter].*

		END FOR

		DISPLAY p_orders.* TO orders.*

		DECLARE my_curs CURSOR FOR
			SELECT item_num, items.stock_num, 
				items.manu_code, description, 
				quantity, unit_price, total_price
			FROM items, stock
			WHERE order_num = p_orders.order_num
				AND items.stock_num = stock.stock_num 
				AND items.manu_code = stock.manu_code
			ORDER BY item_num

		LET counter = 1

		FOREACH my_curs INTO p_items[counter].*

			LET counter = counter + 1

			IF counter > 10 THEN

				CALL mess("Ten or more items.")

				EXIT FOREACH
			
			END IF

		END FOREACH
		
		CALL set_count(counter - 1)

		MESSAGE "Press ESC when you finish viewing the items on order."

		DISPLAY ARRAY p_items TO s_items.*

		MESSAGE ""

		PROMPT "Enter 'y' to select this order ", 
			"or RETURN to view next order: "
			FOR answer

		IF answer = "y" THEN

			LET chosen = 1

			EXIT FOREACH

		END IF

	END FOREACH

	IF exist = 0 THEN

		CALL mess("No orders found for this customer.")

	ELSE

		IF chosen = 0 THEN

			CALL mess("There are no more orders for this customer.")

			CLEAR FORM

		END IF

	END IF

END FUNCTION


FUNCTION change_order()

	DEFINE  pa_curr	SMALLINT,
		answer	CHAR(1)

	CALL clear_menu()

	PROMPT "Do you want to change the order or ship date (y/n) : "
		FOR answer

	IF answer = "y" THEN

		INPUT p_orders.order_date, p_orders.ship_date
			WITHOUT DEFAULTS
			FROM order_date, ship_date

	END IF


	PROMPT "Do you want to change any items (y/n) : "
		FOR answer

	IF answer = "y" THEN


		INPUT ARRAY p_items WITHOUT DEFAULTS FROM s_items.* 

			BEFORE FIELD stock_num
				MESSAGE "Enter a stock number."

			BEFORE FIELD manu_code
				MESSAGE "Enter the code for a manufacturer."

			BEFORE FIELD quantity
				MESSAGE "Enter a quantity."

			AFTER FIELD stock_num, manu_code
				MESSAGE ""

				LET pa_curr = arr_curr()

				IF p_items[pa_curr].stock_num IS NOT NULL
				AND p_items[pa_curr].manu_code IS NOT NULL 
				
				THEN
					CALL get_item()
	
					IF p_items[pa_curr].quantity IS NOT NULL
					THEN
	
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

	END IF

	UPDATE orders
		SET order_date = p_orders.order_date,
			ship_date = p_orders.ship_date
		WHERE order_num = p_orders.order_num

	DELETE FROM items
		WHERE order_num = p_orders.order_num


	CALL insert_items()

	CALL mess("Order changed.")

END FUNCTION

FUNCTION delete_order()

	DEFINE counter SMALLINT

	DELETE FROM orders
		WHERE order_num = p_orders.order_num

	DELETE FROM items
		WHERE order_num = p_orders.order_num

	CLEAR orders.*

	FOR counter = 1 to 4

		CLEAR s_items[counter].*

	END FOR

	CALL mess("Order deleted.")

END FUNCTION

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

FUNCTION get_total()

	DEFINE pa_curr, sc_curr SMALLINT

	LET pa_curr = arr_curr()

	LET sc_curr = scr_line()

	LET p_items[pa_curr].total_price =
		p_items[pa_curr].quantity * p_items[pa_curr].unit_price

	DISPLAY p_items[pa_curr].total_price
		TO s_items[sc_curr].total_price

END FUNCTION


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

FUNCTION get_cust()

	WHILE TRUE

		PROMPT "Enter a customer number:  "
			FOR p_customer.customer_num

		SELECT fname, lname, address1, address2, 
				city, state, zipcode, phone
			INTO p_customer.fname THRU p_customer.phone
			FROM customer 
			WHERE customer_num = p_customer.customer_num

		IF status = 0 THEN

			EXIT WHILE

		END IF

	END WHILE

	DISPLAY p_customer.* TO customer.*

END FUNCTION

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

FUNCTION mess(str)

	DEFINE str CHAR(50)

	DISPLAY str CLIPPED AT 23,1

	SLEEP 3

	DISPLAY "" AT 23, 1

END FUNCTION

FUNCTION clear_menu()

	DISPLAY "" AT 1,1
	DISPLAY "" AT 2,1

END FUNCTION

