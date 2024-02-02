MAIN
   define a int;
   let a = func_cons_ws_zipcode();

END MAIN

FUNCTION func_cons_ws_zipcode()
   DEFINE state_rec RECORD
                pin CHAR(10),
                city CHAR(100),
                state CHAR(100)
              END RECORD;


   call cons_ws_zipcode("97006") returning state_rec.city, state_rec.state
   DISPLAY "\n ------------------------- \n"
   DISPLAY "SUPPLIED ZIP CODE: 97006 \n"
   DISPLAY " ------------------------- \n"
   DISPLAY "RESPONSE FROM WEB SERVICE \n"
   DISPLAY " ------------------------- \n"
   DISPLAY " CITY:",state_rec.city
   DISPLAY "\n STATE:",state_rec.state
   DISPLAY "\n ======================== \n"

   call cons_ws_zipcode("89101") returning state_rec.city, state_rec.state
   DISPLAY "\n ------------------------- \n"
   DISPLAY "SUPPLIED ZIP CODE: 89101 \n"
   DISPLAY " ------------------------- \n"
   DISPLAY "RESPONSE FROM WEB SERVICE \n"
   DISPLAY " ------------------------- \n"
   DISPLAY " CITY:",state_rec.city
   DISPLAY "\n STATE:",state_rec.state
   DISPLAY "\n ======================== \n"

   call cons_ws_zipcode("66219") returning state_rec.city, state_rec.state
   DISPLAY "\n ------------------------- \n"
   DISPLAY "SUPPLIED ZIP CODE: 66219 \n"
   DISPLAY " ------------------------- \n"
   DISPLAY "RESPONSE FROM WEB SERVICE \n"
   DISPLAY " ------------------------- \n"
   DISPLAY " CITY:",state_rec.city
   DISPLAY "\n STATE:",state_rec.state
   DISPLAY "\n ======================== \n"

   return 1
END FUNCTION

