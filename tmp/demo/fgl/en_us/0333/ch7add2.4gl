

DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS


MAIN

	DEFINE	answer CHAR(1)

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form
		
	PROMPT "Do you want to enter a customer row (y/n) ?  " 
		FOR answer

	WHILE answer = "y"

		CALL enter_cust()

		PROMPT "Do you want to enter another customer row (y/n) ?  " 
			FOR answer

	END WHILE

	MESSAGE "End program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION enter_cust()

	CLEAR FORM

	INPUT BY NAME p_customer.fname THRU p_customer.phone 

	LET p_customer.customer_num =  0

	INSERT INTO customer VALUES (p_customer.*)

	LET p_customer.customer_num = SQLCA.SQLERRD[2]

	DISPLAY p_customer.customer_num TO customer_num

	MESSAGE "Row added."

	SLEEP 3

	MESSAGE ""

END FUNCTION
