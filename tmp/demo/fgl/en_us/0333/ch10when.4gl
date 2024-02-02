DATABASE stores

GLOBALS

	DEFINE p_customer RECORD LIKE customer.*

END GLOBALS


MAIN
	DEFINE answer CHAR(1)

	CALL startlog("error_log")

 	WHENEVER ERROR CALL exit_now 

	OPEN FORM cust_form FROM "customer"

	DISPLAY FORM cust_form 

	LET answer = "y"

	WHILE answer = "y"

		CALL enter_cust()

		PROMPT "Do you want to enter another row (y/n) ? "
			FOR answer

	END WHILE

	MESSAGE "End Program."

	SLEEP 3

	CLEAR SCREEN

END MAIN


FUNCTION enter_cust()

END FUNCTION


FUNCTION exit_now()

	CLEAR SCREEN

	DISPLAY "There is a serious problem. ", 
		"Call your applications designer for help."

	EXIT PROGRAM

END FUNCTION



