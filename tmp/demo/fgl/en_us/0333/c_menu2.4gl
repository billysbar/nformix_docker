DATABASE stores

GLOBALS

	DEFINE 
               p_customer RECORD LIKE customer.*,
	       chosen SMALLINT

END GLOBALS

MAIN

	OPEN FORM cust_form FROM "customer"
	
	DISPLAY FORM cust_form

	LET chosen = FALSE

	OPTIONS MESSAGE LINE 22,
		PROMPT LINE 21,
		HELP FILE "custhelp.ex",
		HELP KEY F1

	CALL show_menu()

	MESSAGE "End program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION show_menu()

	DEFINE answer  CHAR(1)

	MESSAGE "Type the first letter of the option ",
		"you want to select or F1 for Help."

	MENU "CUSTOMER"
  
		COMMAND "Add" "Add a new customer." HELP 1

		        LET answer = "y"

		        WHILE answer = "y"
	
				CALL enter_row()
       
				PROMPT "Do you want to ",
					"enter another row (y/n) ?  "
					FOR answer

			END WHILE
     
		COMMAND "Query" "Search for a customer." HELP 2

			CALL query_data()

			IF chosen THEN

				NEXT OPTION "Modify"

			END IF
	
		COMMAND "Modify" "Modify a customer." HELP 3

			IF chosen THEN

				CALL change_data()

			ELSE

				MESSAGE "No customer has been chosen. ",
					"Use the Query option to select ",
					"a customer."

				NEXT OPTION "Query"

	      		END IF


		COMMAND "Delete" "Delete a customer." HELP 4

			IF chosen THEN
    
				PROMPT "Are you sure you want to ",
					"delete this customer (y/n)?  "
					FOR answer

				IF answer = "y" THEN

					CALL delete_row()

					LET chosen = FALSE

				END IF

			ELSE

				MESSAGE "No customer has been chosen. ",
					"Use the Query option to select ",
					"a customer."

				NEXT OPTION "Query"

			END IF
	

		COMMAND "Exit" "Leave the CUSTOMER menu." HELP 5

			EXIT MENU

	END MENU

END FUNCTION


FUNCTION enter_row()

	MESSAGE ""

	CLEAR FORM

	INPUT p_customer.fname THRU p_customer.phone 
		FROM sc_cust.*

	LET p_customer.customer_num =  0

	INSERT INTO customer VALUES (p_customer.*)

	LET p_customer.customer_num = SQLCA.SQLERRD[2]

	DISPLAY p_customer.customer_num TO customer_num

	MESSAGE "Row added."

	SLEEP 3

	MESSAGE ""

END FUNCTION

    

FUNCTION query_data()

	DEFINE last_name CHAR(15)

	MESSAGE ""

	CLEAR FORM

	PROMPT "Enter a last name: " FOR last_name

	MESSAGE "Selecting rows for customer with last name ",
		last_name, ". . ."

	SLEEP 3

	MESSAGE ""

	DECLARE a_curs SCROLL CURSOR FOR
		SELECT * FROM customer WHERE lname MATCHES last_name

	LET chosen = FALSE

	OPEN a_curs

	FETCH FIRST a_curs INTO p_customer.*

	IF status = NOTFOUND THEN 
		MESSAGE "No customers found."
		SLEEP 3
		MESSAGE ""
	ELSE
		DISPLAY BY NAME p_customer.*
		CALL view_cust()
	END IF

	CLOSE a_curs

END FUNCTION


FUNCTION view_cust()

	MENU "BROWSE"

		COMMAND "Next" "View the next customer in the list."
			FETCH NEXT a_curs INTO p_customer.*
			IF status = NOTFOUND THEN
				MESSAGE "No more customers in this direction."
				SLEEP 3 
				MESSAGE ""
				FETCH LAST a_curs INTO p_customer.*
			END IF
			DISPLAY BY NAME p_customer.*

		COMMAND "Previous" "View the previous customer in the list."
			FETCH PREVIOUS a_curs INTO p_customer.*
			IF status = NOTFOUND THEN
				MESSAGE "No more customers in this direction."
				SLEEP 3
				MESSAGE ""
				FETCH FIRST a_curs INTO p_customer.*
			END IF
			DISPLAY BY NAME p_customer.*

		COMMAND "First" "View the first customer in the list."
			FETCH FIRST a_curs INTO p_customer.*
			DISPLAY BY NAME p_customer.*

		COMMAND "Last" "View the last customer in the list."
			FETCH LAST a_curs INTO p_customer.*
			DISPLAY BY NAME p_customer.*

		COMMAND "Choose" "Choose the current customer."
			LET chosen = TRUE
			MESSAGE "This customer has been chosen."
			SLEEP 3
			MESSAGE ""

		COMMAND "Exit" "Leave the menu."
			EXIT MENU

	END MENU

END FUNCTION


FUNCTION change_data()

	INPUT p_customer.fname THRU p_customer.phone 
		WITHOUT DEFAULTS FROM sc_cust.*

	UPDATE customer 
		SET customer.* = p_customer.*
		WHERE customer_num = p_customer.customer_num

	MESSAGE "Row updated."

	SLEEP 3

	MESSAGE ""

END FUNCTION 


FUNCTION delete_row()

	DELETE FROM customer WHERE customer_num = 
		p_customer.customer_num

	CLEAR FORM

	MESSAGE "Row deleted."

	SLEEP 3

	MESSAGE ""

END FUNCTION 


