DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS

MAIN

	DEFINE answer CHAR(1)

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form 

	DEFER INTERRUPT

	LET answer = "y"

	WHILE answer = "y"

		CALL enter_cust()

		PROMPT "Do you want to enter another row (y/n) ? "
			FOR answer

	END WHILE

	MESSAGE "End Program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION enter_cust()

	CLEAR FORM

	DISPLAY "Press ESC to add.  Press DEL to discard." AT 2,1

	LET int_flag = 0

	INPUT p_customer.fname THRU p_customer.phone
		FROM sc_cust.*

	DISPLAY "" AT 2,1

	IF int_flag <> 0 THEN

		MESSAGE "Row discarded."

		SLEEP 3

		MESSAGE ""

		CLEAR FORM

		RETURN

	END IF

	LET p_customer.customer_num = 0

	INSERT INTO customer VALUES (p_customer.*)

	LET p_customer.customer_num = SQLCA.SQLERRD[2]

	DISPLAY p_customer.customer_num TO customer_num

	MESSAGE "Row added."

	SLEEP 3

	MESSAGE ""

END FUNCTION
