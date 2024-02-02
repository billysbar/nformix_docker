DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS

MAIN

	DEFER INTERRUPT

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form

	CALL query_data()

	MESSAGE "End Program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION query_data()

	DEFINE last_name CHAR(15),
		answer CHAR(1),
		exist SMALLINT

	LET int_flag = 0

	PROMPT "Enter last name or DEL to quit : " FOR last_name

	IF int_flag <> 0 THEN

		MESSAGE "Query Aborted."

		SLEEP 3

		MESSAGE ""

		RETURN

	END IF

	MESSAGE "Selecting rows for customer with the last name ",
		last_name, ". . . "

	SLEEP 3

	MESSAGE ""

	DECLARE a_curs CURSOR FOR
		SELECT * FROM customer WHERE lname MATCHES last_name

	LET exist = 0

	FOREACH a_curs INTO p_customer.*

		LET exist = 1

		DISPLAY p_customer.* TO customer.*

		PROMPT "Do you want to see the next customer (y/n) :  "
			FOR answer

		IF answer = "n" THEN

			EXIT FOREACH

		END IF

	END FOREACH

	IF exist = 0 THEN

		MESSAGE "No customer rows found."

	ELSE

		IF answer = "y" THEN

			MESSAGE "There are no more customer rows."

		END IF

	END IF

	SLEEP 3

END FUNCTION
