

DATABASE stores

MAIN

	DEFINE p_customer RECORD LIKE customer.*

	DECLARE q_curs CURSOR FOR 
		SELECT * FROM customer

	START REPORT cust_list

	FOREACH q_curs INTO p_customer.*

		OUTPUT TO REPORT cust_list (p_customer.*)

	END FOREACH

	FINISH REPORT cust_list

END MAIN

REPORT cust_list (r_customer)

	DEFINE r_customer RECORD LIKE customer.*

	FORMAT EVERY ROW

END REPORT
