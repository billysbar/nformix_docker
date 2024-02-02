DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS

MAIN

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form

	CALL get_customer()

	MESSAGE "End program."

	SLEEP 3

	CLEAR SCREEN

END MAIN

FUNCTION get_customer()

	DEFINE s1, query_1 CHAR(300),
		exist	SMALLINT,
		answer CHAR(1)

	MESSAGE "Enter search criteria for one or more customers."

	SLEEP 3

	MESSAGE ""

	CONSTRUCT BY NAME query_1 ON customer.*

	LET s1 = "SELECT * FROM customer WHERE ", query_1 CLIPPED

	PREPARE s_1 FROM s1

	DECLARE q_curs CURSOR FOR s_1

	LET exist = 0

	FOREACH q_curs INTO p_customer.*

		LET exist = 1

		DISPLAY p_customer.* TO customer.*

		PROMPT "Do you want to see the next customer (y/n) ?  "
			FOR answer

		IF answer = "n" THEN

			EXIT FOREACH

		END IF

	END FOREACH

	IF exist = 0 THEN

		MESSAGE "No rows found."
	ELSE

		IF answer = "y" THEN

			MESSAGE "No more rows satisfy the search criteria."

		END IF

	END IF

	SLEEP 3

END FUNCTION
