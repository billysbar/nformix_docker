
DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS

MAIN

	DEFINE answer CHAR(1),
		found_flag SMALLINT

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form

	MESSAGE "Selecting all rows from the customer table . . ."

	SLEEP 3

	MESSAGE ""

	DECLARE q_curs CURSOR FOR
		SELECT * FROM customer

	LET found_flag = FALSE

	FOREACH q_curs INTO p_customer.*

		LET found_flag = TRUE

		DISPLAY BY NAME p_customer.* 

		PROMPT "Do you want to add or ",
			"change any information (y/n) ?  "
			FOR answer

		IF answer = "y" THEN 

			CALL change_row()

		END IF 	

		PROMPT "Do you want to see the ",
			"next customer row (y/n) ? " 
			FOR answer

		IF answer = "n" THEN

			EXIT FOREACH

		END IF

	END FOREACH

	IF found_flag = FALSE THEN

		MESSAGE "No rows found.  End program."

	ELSE
		IF answer = "y" THEN

			MESSAGE "No more rows.  End program."

		ELSE
			MESSAGE "End program."

		END IF

	END IF

	SLEEP 3

	CLEAR SCREEN

END MAIN

FUNCTION change_row()

	INPUT BY NAME p_customer.fname THRU p_customer.phone 
		WITHOUT DEFAULTS 

	UPDATE customer 
		SET customer.* = p_customer.*
		WHERE customer_num = p_customer.customer_num

	MESSAGE "Row updated."

	SLEEP 3

	MESSAGE ""

END FUNCTION 

