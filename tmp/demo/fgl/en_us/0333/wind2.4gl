

DATABASE stores

#	The GLOBALS statement defines two program records and
#	a SMALLINT variable used throughout the program.

GLOBALS

	DEFINE 
	p_customer	 RECORD LIKE customer.*,
	p_orders	 RECORD LIKE orders.*,
	cur		 SMALLINT

END GLOBALS


#	The MAIN statement opens two windows and displays
#	forms in each window.  It sets the global variable cur
#	to 1 and calls the show_menu function.  Finally, it
#	closes the forms and windows.

MAIN


	OPEN WINDOW ow2 AT 10,15
		WITH 11 ROWS,63 COLUMNS
		ATTRIBUTE(BORDER)

	OPEN FORM ordcur FROM "ordcur"

	DISPLAY FORM ordcur

	OPEN WINDOW cw1 AT 5,5
		WITH 11 ROWS,63 COLUMNS
		ATTRIBUTE(BORDER)

	OPEN FORM custcur FROM "custcur"

	DISPLAY FORM custcur

	LET cur = 1

	CALL show_menu()

	CLOSE FORM custcur

	CLOSE FORM ordcur

	CLOSE WINDOW cw1

	CLOSE WINDOW ow2

END MAIN


#	The show_menu function displays the SEARCH Menu.
#	The SEARCH Menu is the "main" menu for the program
#	and appears at the top of the current window.

FUNCTION show_menu()

	DEFINE win_flag SMALLINT

	LET win_flag = 1

	WHILE win_flag = 1

		LET win_flag = 0

		MENU "SEARCH"

			COMMAND "Query" "Search for rows."
				IF cur = 1 THEN
					CALL get_cust()
				ELSE 
					CALL get_ord()
				END IF

			COMMAND "Detail" "Get details."
				IF cur = 1 THEN
					CALL det_ord() 
				ELSE 
					CALL det_cust() 
				END IF

			COMMAND "Switch" "Change the window." 

				LET win_flag = 1
				EXIT MENU

			COMMAND "Exit" "Leave the program."
				EXIT MENU

		END MENU

		IF win_flag = 1 THEN
			CALL change_wind()	
		END IF

	END WHILE

END FUNCTION


#	The set_curs function uses a CASE statement to test
#	the value of the argument passed to it by other functions
#	in the program.  It prepares a SELECT statement, declares
#	a scroll cursor for the SELECT statement, and opens the cursor.

FUNCTION set_curs(flag)

	DEFINE flag SMALLINT, 
		query_1, query_str CHAR(300)

	CASE flag

		WHEN 1     # function called by get_cust 

			CONSTRUCT query_1 ON customer.* FROM customer.*
			LET query_str = "SELECT * FROM customer WHERE ", 
				query_1 CLIPPED

		WHEN 2     # function called by get_ord

			CONSTRUCT query_1 ON orders.* FROM orders.*
			LET query_str = "SELECT * FROM orders WHERE ", 
				query_1 CLIPPED

		WHEN 3     # function called by det_ord 

			LET query_str = 
              		"SELECT * FROM orders WHERE orders.customer_num = ",
			p_customer.customer_num USING "###"
	END CASE

	PREPARE s_1 FROM query_str

	DECLARE q_curs SCROLL CURSOR FOR s_1

	OPEN q_curs

END FUNCTION


#	The get_cust function allows the user to perform a 
#	query by example on the cust_cur form displayed in the
#	cw1 window.

FUNCTION get_cust()

	CALL clear_menu()

	CALL mess("Enter search criteria for one or more customers.")

	CALL set_curs(1)

	CALL view_cust()

END FUNCTION


#	The view_cust function performs a fetch first and tests
#	whether a customer row is returned.  If the active set is
#	empty, the function ends.  If the active set contains at
#	least one row, the function displays the row along with a 
#	menu that allows the user to browse through the
#	row(s) in the active set.

FUNCTION view_cust()

	FETCH FIRST q_curs INTO p_customer.*

	IF status = NOTFOUND THEN
		CALL mess("No customers found.")
		CLOSE q_curs
		RETURN
	ELSE
		DISPLAY BY NAME p_customer.*
	END IF

	MENU "BROWSE"

		COMMAND "Next" "View the next customer in the list."
		FETCH NEXT q_curs INTO p_customer.*
			IF status = NOTFOUND THEN
			      CALL mess("No more customers in this direction.")
				FETCH LAST q_curs INTO p_customer.*
			END IF
			DISPLAY BY NAME p_customer.*

		COMMAND "Previous" "View the previous customer in the list."
			FETCH PREVIOUS q_curs INTO p_customer.*
			IF status = NOTFOUND THEN
			     CALL mess("No more customers in this direction.")
				FETCH FIRST q_curs INTO p_customer.*
			END IF
			DISPLAY BY NAME p_customer.*

		COMMAND "First" "View the first customer in the list."
			FETCH FIRST q_curs INTO p_customer.*
			DISPLAY BY NAME p_customer.*

		COMMAND "Last" "View the last customer in the list."
			FETCH LAST q_curs INTO p_customer.*
			DISPLAY BY NAME p_customer.*

		COMMAND "Select-and-exit" "Select the current customer."
			CALL clear_menu()
			EXIT MENU
	END MENU

	CLOSE q_curs

END FUNCTION


#	The get_ord function allows the user to perform a 
#	query by example on the ord_cur form displayed
#	in the ow2 window.

FUNCTION get_ord()

	CALL clear_menu()

	CALL mess("Enter search criteria for one or more orders.")

	CALL set_curs(2)

	CALL view_ord()

END FUNCTION


#	The view_ord function performs a fetch first and tests
#	whether an order row is returned.  If the active set
#	is empty, the function ends.  If the active set contains
#	at least one row, the function displays the row along
#	with a menu that allows the user to browse through
#	the row(s) in the active set.

FUNCTION view_ord()

	FETCH FIRST q_curs INTO p_orders.*

	IF status = NOTFOUND THEN
		CALL mess("No orders found.")
		CLOSE q_curs
		RETURN
	ELSE
		DISPLAY BY NAME p_orders.*
	END IF

	MENU "BROWSE"

		COMMAND "Next" "View the next order in the list."
			FETCH NEXT q_curs INTO p_orders.*
			IF status = NOTFOUND THEN
				CALL mess("No more orders in this direction.")
				FETCH LAST q_curs INTO p_orders.*
			END IF
			DISPLAY BY NAME p_orders.*

		COMMAND "Previous" "View the previous order in the list."
			FETCH PREVIOUS q_curs INTO p_orders.*
			IF status = NOTFOUND THEN
				CALL mess("No more orders in this direction.")
				FETCH FIRST q_curs INTO p_orders.*
			END IF
			DISPLAY BY NAME p_orders.*

		COMMAND "First" "View the first order in the list."
			FETCH FIRST q_curs INTO p_orders.*
			DISPLAY BY NAME p_orders.*

		COMMAND "Last" "View the last order in the list."
			FETCH LAST q_curs INTO p_orders.*
			DISPLAY BY NAME p_orders.*

		COMMAND "Select-and-exit" "Select the current order."
			CALL clear_menu()
			EXIT MENU

	END MENU

	CLOSE q_curs

END FUNCTION


#	The det_cust function is called when the user selects
#	the Detail option on the SEARCH Menu and ow2 is 
#	the current window.  The det_cust function provides
#	information about the customer who placed the order
#	currently displayed in the ow2 window.

FUNCTION det_cust()

	DEFINE answer CHAR(1)
	
	CURRENT WINDOW IS cw1

	SELECT * INTO p_customer.* FROM customer WHERE customer_num =
		p_orders.customer_num

	DISPLAY BY NAME p_customer.*

	PROMPT "Press RETURN to return to the other window: " 
		FOR answer

END FUNCTION


#	The det_ord function is called when the user selects
#	the Detail option on the SEARCH Menu and cw1 is
#	the current window.  The det_ord function provides
#	information about the orders placed by the customer
#	currently displayed in the cw1 window.

FUNCTION det_ord()

	DEFINE answer CHAR(1)

	CURRENT WINDOW IS ow2

	CALL set_curs(3)

	CALL view_ord()

	PROMPT "Press RETURN to return to the other window: " 
		FOR answer

END FUNCTION

#	The change_wind function is called when the user
#	selects the Switch option on the SEARCH Menu.
#	The function changes the current window.

FUNCTION change_wind()

 	CALL clear_menu()

	IF cur = 1 THEN
		CURRENT WINDOW IS ow2
		LET cur = 2
	ELSE 
		CURRENT WINDOW IS cw1
		LET cur = 1
	END IF

END FUNCTION

#	The clear_menu function clears the top two
#	lines in the current window of text.

FUNCTION clear_menu()

	DISPLAY "" AT 1, 1 
	DISPLAY "" AT 2, 1 

END FUNCTION

#	The mess function is passed a character string as an argument
#	and displays the characters on the 11th (last) line of the
#	current window.

FUNCTION mess(str)

	DEFINE str CHAR(50)

	DISPLAY str CLIPPED AT 11,1

	SLEEP 3

	DISPLAY "" AT 11,1

END FUNCTION	
