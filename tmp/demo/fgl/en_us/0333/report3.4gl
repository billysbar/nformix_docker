DATABASE stores

MAIN

	DEFINE p_customer RECORD LIKE customer.*

	DECLARE q_curs CURSOR FOR 
		SELECT lname, company, city, state
			FROM customer
			ORDER BY city

	START REPORT cust_list

	FOREACH q_curs INTO p_customer.lname,
				p_customer.company,
				p_customer.city,
				p_customer.state

		OUTPUT TO REPORT cust_list (p_customer.lname,
					p_customer.company,
					p_customer.city,
					p_customer.state)

	END FOREACH

	FINISH REPORT cust_list

END MAIN

REPORT cust_list (lname, company, city, state)

	DEFINE lname	CHAR(15),
		company	CHAR(20),
		city	CHAR(15),
		state	CHAR(2)

	FORMAT

		ON EVERY ROW
			PRINT lname,
				COLUMN 18, company,
				COLUMN 40, city,
				COLUMN 60, state

		AFTER GROUP OF city
			SKIP 2 LINES


END REPORT
