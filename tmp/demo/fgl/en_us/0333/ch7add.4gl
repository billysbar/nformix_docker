

DATABASE stores

GLOBALS

	DEFINE	p_customer RECORD LIKE customer.*

END GLOBALS


MAIN

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form

	MESSAGE "Enter customer information."

	CALL enter_cust()

	MESSAGE "End program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION enter_cust()

	INPUT BY NAME p_customer.fname THRU p_customer.phone 

	LET p_customer.customer_num =  0

	INSERT INTO customer VALUES (p_customer.*)

	LET p_customer.customer_num = SQLCA.SQLERRD[2]

	DISPLAY p_customer.customer_num TO customer_num

	MESSAGE "Row added."

	SLEEP 3

	MESSAGE ""

END FUNCTION
