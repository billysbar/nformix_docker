-- The query1 program allows users to query the database
-- for customers.  The get_customer function supports query
-- by example and guides the user through the query process.

DATABASE stores

GLOBALS

   DEFINE p_customer RECORD LIKE customer.*,
          p_state    ARRAY[50] OF RECORD LIKE state.*,
          state_cnt  SMALLINT

END GLOBALS

MAIN

   OPTIONS HELP FILE "helpdemo", -- specifies help file location
           INPUT WRAP            -- requires explicit accept

   CALL get_states()             -- populates p_state array

   OPEN WINDOW custwind AT 5, 10
      WITH FORM "custform"      
      ATTRIBUTE (border, MESSAGE LINE 1)

   CALL get_customer()       -- allows query by example and
                             -- displays retrieved rows
   MESSAGE "End program."

   SLEEP 2

   CLOSE WINDOW custwind

END MAIN

-- The get_customer function provides the query by example and
-- displays retrieved rows.  It checks for a SELECT * query and
-- asks the user whether this is wanted.  If the user types n,
-- the program reenters the CONSTRUCT.

-- Help is available on a field-by-field basis, and a list of
-- states is available when in the state field.

FUNCTION get_customer()
                      
   DEFINE s1, query_1  CHAR(300),
          answer       CHAR(1),
          exist        SMALLINT

   CONSTRUCT BY NAME query_1 ON customer.*

      BEFORE CONSTRUCT
         MESSAGE "Enter search criteria; press ESC to begin search."
         DISPLAY "Press F1 or CTRL-W for field help." AT 2,1

      ON KEY (F1, CONTROL-W)
         CALL customer_help()        -- display field level help

      BEFORE FIELD state
         MESSAGE "Press F2 or CTRL-B to display a list of states."

      ON KEY (F2, CONTROL-B) 
         IF infield(state) THEN     
            CALL statehelp()         -- display list of states
         END IF

      AFTER FIELD state
         MESSAGE "Enter search criteria; press ESC to begin search."

      AFTER CONSTRUCT           -- check for blank search criteria
         IF NOT field_touched(customer.*) THEN
            PROMPT "Do you really want to see ",
                  "all customer rows? (y/n) "
               FOR CHAR answer
            IF answer MATCHES "[Nn]" THEN
               MESSAGE "Enter search criteria; ",
                  "press ESC to begin search."
               CONTINUE CONSTRUCT      -- reenter query by example
            END IF                  
         END IF                    
         
   END CONSTRUCT

   LET s1 = "SELECT * FROM customer WHERE ",
      query_1 CLIPPED                   
   PREPARE s_1 FROM s1
   DECLARE q_curs CURSOR FOR s_1
   DISPLAY "" AT 2,1                     -- clear line 2 of text
   LET exist = 0

   FOREACH q_curs INTO p_customer.*
      LET exist = 1
      DISPLAY p_customer.* TO customer.*
      PROMPT "Do you want to see the next customer (y/n) ?  "
         FOR CHAR answer
      IF answer MATCHES "[Nn]" THEN      
         EXIT FOREACH
      END IF
   END FOREACH

   IF exist = 0 THEN
      MESSAGE "No rows found."
   ELSE
      IF answer NOT MATCHES "[Nn]" THEN
         MESSAGE "No more rows satisfy the search criteria."
      END IF
   END IF

   SLEEP 2

END FUNCTION


FUNCTION customer_help()  -- returns field level help

   CASE
      WHEN infield(customer_num) CALL showhelp(1001)
      WHEN infield(fname) CALL showhelp(1002)
      WHEN infield(lname) CALL showhelp(1003)
      WHEN infield(company) CALL showhelp(1004)
      WHEN infield(address1) CALL showhelp(1005)
      WHEN infield(address2) CALL showhelp(1006)
      WHEN infield(city) CALL showhelp(1007)
      WHEN infield(state) CALL showhelp(1008)
      WHEN infield(zipcode) CALL showhelp(1009)
      WHEN infield(phone) CALL showhelp(1010)
   END CASE

END FUNCTION

FUNCTION get_states()  -- populate p_state array

   DECLARE c_state CURSOR FOR 
      SELECT * FROM state 
      ORDER BY sname
   LET state_cnt = 1
   FOREACH c_state INTO p_state[state_cnt].*
       LET state_cnt = state_cnt + 1
       IF state_cnt > 50 THEN
           EXIT FOREACH
       END IF
   END FOREACH
   LET state_cnt = state_cnt - 1

END FUNCTION

FUNCTION statehelp()  -- display p_state array
                          
   DEFINE idx SMALLINT

   MESSAGE "Use arrow keys to move cursor; ",
      "press ESC to select state."
   OPEN WINDOW w_state AT 8,37
      WITH FORM "state_list"
      ATTRIBUTE (BORDER, FORM LINE 2)

   CALL set_count(state_cnt)
   DISPLAY ARRAY p_state TO s_state.*
   LET idx = arr_curr()

   CLOSE WINDOW w_state
   LET p_customer.state = p_state[idx].code
   DISPLAY BY NAME p_customer.state
   RETURN

END FUNCTION
