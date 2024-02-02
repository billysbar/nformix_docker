
DATABASE stores

MAIN

	DEFINE p_customer RECORD LIKE customer.*,
		answer CHAR(1),
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
