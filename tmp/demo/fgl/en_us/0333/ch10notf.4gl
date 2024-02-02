DATABASE stores

MAIN
	DEFINE p_customer RECORD LIKE customer.*
	
	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form

	WHILE TRUE

		PROMPT "Enter a customer number:  "
		FOR p_customer.customer_num

		SELECT * INTO p_customer.* FROM customer
			WHERE customer_num = p_customer.customer_num

		IF status = 0 THEN

			EXIT WHILE

		END IF

	END WHILE

	DISPLAY BY NAME p_customer.*

	SLEEP 3

	CLEAR SCREEN

END MAIN




