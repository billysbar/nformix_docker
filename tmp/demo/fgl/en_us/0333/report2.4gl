
DATABASE stores

MAIN

	DEFINE p_customer RECORD LIKE customer.*

	DECLARE q_curs CURSOR FOR 
		SELECT fname, lname, company
			FROM customer

	START REPORT cust_list

	FOREACH q_curs INTO p_customer.fname,
				p_customer.lname,
				p_customer.company

		OUTPUT TO REPORT cust_list (p_customer.fname,
					p_customer.lname,
					p_customer.company)

	END FOREACH

	FINISH REPORT cust_list

END MAIN

REPORT cust_list (fname, lname, company)

	DEFINE fname, lname	CHAR(15),
		company	CHAR(20)

	FORMAT

		PAGE HEADER

			PRINT COLUMN 25, "CUSTOMER LIST"
			SKIP 1 LINE
			PRINT COLUMN 24, "August 26, 1986"
			SKIP 2 LINES
			PRINT "Last Name",
				COLUMN 26, "First Name",
				COLUMN 50, "Company"
			SKIP 1 LINE

		ON EVERY ROW
			PRINT lname,
				COLUMN 26, fname,
				COLUMN 50, company


		PAGE TRAILER
			PRINT "Confidential Information",
				COLUMN 55, PAGENO USING "Page ##"

END REPORT
