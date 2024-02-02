DATABASE stores

MAIN

	DEFINE p_customer RECORD LIKE customer.*

	DECLARE q_curs CURSOR FOR 
		SELECT lname, company, city, state
			FROM customer

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

	ORDER BY city

	FORMAT

		PAGE HEADER

			PRINT COLUMN 25, "CUSTOMER LIST"
			SKIP 1 LINE
			PRINT COLUMN 24, "August 26, 1986"
			SKIP 2 LINES
			PRINT "Last Name",
				COLUMN 18, "Company",
				COLUMN 40, "City",
				COLUMN 60, "State"
			SKIP 2 LINES

		ON EVERY ROW
			PRINT lname,
				COLUMN 18, company,
				COLUMN 40, city,
				COLUMN 60, state

		AFTER GROUP OF city
			SKIP 2 LINES

		PAGE TRAILER
			PRINT "Confidential Information",
				COLUMN 55, PAGENO USING "Page ##"

END REPORT
