--   menu1.4gl program

DATABASE stores


--   The GLOBALS statement defines two program records,
--   a MONEY variable, and three SMALLINT variables used
--   throughout the program.

GLOBALS

   DEFINE 
      p_customer          RECORD LIKE customer.*,
      p_orders            RECORD LIKE orders.*,
      t_price             MONEY,
      cur, exist, priv    SMALLINT

END GLOBALS


--   The MAIN statement defines two local variables,
--   specifies the location of the Prompt, Form, and
--   Menu lines, and prompts the user to determine the
--   value of the priv global variable.  It opens two
--   windows and displays forms in each window.  It sets
--   the global variables cur to 1 and exist to 0, calls
--   the tot_price function, and calls the show_menu
--   function.  Finally, it closes the forms and windows.

MAIN

   DEFINE ordform     CHAR(18),
          answer      CHAR(1)

   OPTIONS PROMPT LINE LAST,
           FORM LINE FIRST,
           MENU LINE LAST-2

   LET priv = 0

   PROMPT "Are you a privileged user (y/n)? "
      FOR CHAR answer
   
   IF answer MATCHES "[yY]" THEN
      LET priv = 1
   END IF

   OPEN WINDOW ow2 AT 10,15
      WITH 12 ROWS,63 COLUMNS
      ATTRIBUTE(BORDER)

   IF priv  THEN      -- specify form file
      LET ordform = "p_ordcur"
   ELSE
      LET ordform = "ordcur"
   END IF

   OPEN FORM ordcur FROM ordform
   DISPLAY FORM ordcur

   OPEN WINDOW cw1 AT 5,5
      WITH 12 ROWS,63 COLUMNS
      ATTRIBUTE(BORDER)

   OPEN FORM custcur FROM "custcur"
   DISPLAY FORM custcur

   LET cur = 1        -- current window is customer
   LET exist = 0      -- no record yet retrieved

   CALL tot_price()   -- select total_price info
		      -- into temp table
   CALL show_menu()   -- main menu used in program

   CLOSE FORM custcur
   CLOSE FORM ordcur
   CLOSE WINDOW cw1
   CLOSE WINDOW ow2

END MAIN


--   The tot_price function retrieves aggregate information
--   about the cost of all items in each order and places
--   this information in the price temporary table.  Subsequent
--   queries for order information will use this temp table.

FUNCTION tot_price()

   SELECT order_num, SUM(total_price) t_price
      FROM items
      GROUP BY order_num INTO TEMP price

END FUNCTION


--   The show_menu function displays the menu_name menu.
--   This is the "main" menu for the program and appears
--   at the top of the current window.

FUNCTION show_menu()

  DEFINE win_flag   SMALLINT,
         menu_name  CHAR(20)

  LET win_flag = 1          -- tracks current window
  LET menu_name = "SEARCH"  -- specifies default menu name

  WHILE win_flag = 1

      LET win_flag = 0

      MENU menu_name

         BEFORE MENU      -- set menu name and option list
            HIDE OPTION ALL
            IF priv THEN
               LET menu_name = "PRIVILEGED SEARCH"
               SHOW OPTION ALL
            ELSE
               SHOW OPTION "Query", "Detail", "Switch", "Exit"
            END IF

         COMMAND "Query" "Search for rows."
            IF cur = 1 THEN      -- in customer window
               CALL get_cust()
            ELSE 
               CALL get_ord()
            END IF

         -- Add command available to privileged users only
         COMMAND "Add" "Add a new row."
            IF cur = 1 THEN      -- in customer window
               CALL add_cust()
            ELSE 
               CALL add_ord()
            END IF

         -- Update command available to privileged users only
         COMMAND "Update" "Update the current row."
            IF cur = 1   -- in customer window
            THEN 
               IF exist = 0 THEN
                  CALL mess ("First select a customer.")
               ELSE
                  CALL upd_cust() 
               END IF
            ELSE        -- cur=0 and in order window
               IF exist = 0 THEN
                  CALL mess ("First select an order.")
               ELSE
                  CALL upd_ord() 
               END IF
            END IF
            NEXT OPTION "Query"

         -- Delete command available to privileged users only
         COMMAND "Delete" "Delete the current row."
            IF cur = 1   -- in customer window
            THEN 
               IF exist = 0 THEN
                  CALL mess ("First select a customer.")
               ELSE
                  CALL del_cust() 
               END IF
            ELSE        -- cur=0 and in order window
               IF exist = 0 THEN
                  CALL mess ("First select an order.")
               ELSE
                  CALL del_ord() 
               END IF
            END IF
            NEXT OPTION "Query"

         COMMAND "Detail" "Get details."
            IF cur = 1   -- in customer window
            THEN 
               IF exist = 0 THEN
                  CALL mess ("First select a customer.")
               ELSE
                  CALL det_ord() 
               END IF
            ELSE        -- cur=0 and in order window
               IF exist = 0 THEN
                  CALL mess ("First select an order.")
               ELSE
                  CALL det_cust() 
               END IF
            END IF
            NEXT OPTION "Query"

         COMMAND "Switch" "Change the window." 

            LET win_flag = 1
            EXIT MENU

         COMMAND "Exit" "Leave the program."
            EXIT MENU

      END MENU

      IF win_flag = 1 THEN
         CALL change_wind()   
      END IF

   END WHILE

END FUNCTION


--   The set_curs function uses a CASE statement to
--   test the value of the argument passed to it by
--   other functions in the program.  It prepares a
--   SELECT statement, declares a scroll cursor for
--   the SELECT statement, and opens the cursor.

FUNCTION set_curs(flag)

   DEFINE flag SMALLINT, 
      query_1, query_str CHAR(300)

   CLEAR FORM

   CASE flag

      WHEN 1     -- function called by get_cust 

         CONSTRUCT query_1 ON customer.* FROM customer.*
         LET query_str = "SELECT * FROM customer WHERE ",
            query_1 CLIPPED


      WHEN 2     -- function called by get_ord

         CONSTRUCT query_1 ON orders.* FROM orders.*
         LET query_str =
           "SELECT orders.*, t_price ",
           "FROM orders, OUTER price WHERE ",
              "orders.order_num = price.order_num AND ",
               query_1 CLIPPED

      WHEN 3     -- function called by det_ord 

         LET query_str = 
           "SELECT orders.*, t_price ",
           "FROM orders, OUTER price WHERE ",
              "orders.order_num = price.order_num AND ",
              "orders.customer_num = ",
                    p_customer.customer_num USING "###"

   END CASE

   PREPARE s_1 FROM query_str
   DECLARE q_curs SCROLL CURSOR FOR s_1
   OPEN q_curs

END FUNCTION


--   The get_cust function allows the user to perform
--   a query by example on the cust_cur form displayed
--   in the cw1 window.

FUNCTION get_cust()

   CALL clear_menu()
   CALL mess("Enter search criteria for one or more customers.")
   CALL set_curs(1)      -- pass value to set_curs function
   CALL view_cust()      -- display rows retrieved in query

END FUNCTION


--   The view_cust function performs a fetch first and tests
--   whether a customer row is returned.  If the active set
--   is empty, the function ends.  If the active set contains
--   at least one row, the function displays the row along
--   with a menu that allows the user to browse through the
--   row(s) in the active set.

FUNCTION view_cust()

   FETCH FIRST q_curs INTO p_customer.*

   IF status = NOTFOUND THEN
      CALL mess("No customers found.")
      CLOSE q_curs
      LET exist = 0   --  set exist=0 as no row retrieved
      CLEAR FORM
      RETURN
   ELSE
      DISPLAY BY NAME p_customer.*
      LET exist = 1   --  set exist=1 as row retrieved
   END IF

   MENU "BROWSE"

      COMMAND "Next" "View the next customer in the list."
      FETCH NEXT q_curs INTO p_customer.*
         IF status = NOTFOUND THEN
               CALL mess("No more customers in this direction.")
            FETCH LAST q_curs INTO p_customer.*
         END IF
         DISPLAY BY NAME p_customer.*

      COMMAND "Previous" "View the previous customerin the list."
         FETCH PREVIOUS q_curs INTO p_customer.*
         IF status = NOTFOUND THEN
              CALL mess("No more customers in this direction.")
            FETCH FIRST q_curs INTO p_customer.*
         END IF
         DISPLAY BY NAME p_customer.*

      COMMAND "First" "View the first customer in the list."
         FETCH FIRST q_curs INTO p_customer.*
         DISPLAY BY NAME p_customer.*

      COMMAND "Last" "View the last customer in the list."
         FETCH LAST q_curs INTO p_customer.*
         DISPLAY BY NAME p_customer.*

      COMMAND "Select-and-exit" "Select the current customer."
         CALL clear_menu()
         EXIT MENU
   END MENU

   CLOSE q_curs

END FUNCTION


--   The get_ord function allows the user to perform a 
--   query by example on the ord_cur form displayed
--   in the ow2 window.

FUNCTION get_ord()

   CALL clear_menu()
   CALL mess("Enter search criteria for one or more orders.")
   CALL set_curs(2)     -- pass value to set_curs function 
   CALL view_ord()      -- display rows retrieved in query

END FUNCTION


--   The view_ord function performs a fetch first and tests
--   whether an order row is returned.  If the active set
--   is empty, the function ends.  If the active set contains
--   at least one row, the function displays the row along
--   with a menu that allows the user to browse through
--   the row(s) in the active set.  The value of the priv
--   global variable determines whether the t_price
--   variable is displayed in the form.

FUNCTION view_ord()

   FETCH FIRST q_curs INTO p_orders.*, t_price

   IF status = NOTFOUND THEN
      CALL mess("No orders found.")
      CLOSE q_curs
      LET exist = 0     --  set exist=0 as no row retrieved
      CLEAR FORM
      RETURN
   ELSE
      IF priv THEN      -- form includes a total price field
         DISPLAY BY NAME p_orders.*, t_price
      ELSE
         DISPLAY BY NAME p_orders.*
      END IF
      LET exist = 1     --  set exist=1 as row retrieved
   END IF

   MENU "BROWSE"

      COMMAND "Next" "View the next order in the list."
         FETCH NEXT q_curs INTO p_orders.*, t_price
         IF status = NOTFOUND THEN
            CALL mess("No more orders in this direction.")
            FETCH LAST q_curs INTO p_orders.*
         END IF

         IF priv THEN      -- form includes a total price field
            DISPLAY BY NAME p_orders.*, t_price
         ELSE
            DISPLAY BY NAME p_orders.*
         END IF

      COMMAND "Previous" "View the previous order in the list."
         FETCH PREVIOUS q_curs INTO p_orders.*, t_price
         IF status = NOTFOUND THEN
            CALL mess("No more orders in this direction.")
            FETCH FIRST q_curs INTO p_orders.*
         END IF

         IF priv THEN
            DISPLAY BY NAME p_orders.*, t_price
         ELSE
            DISPLAY p_orders.*
         END IF

      COMMAND "First" "View the first order in the list."
         FETCH FIRST q_curs INTO p_orders.*, t_price

         IF priv THEN
            DISPLAY BY NAME p_orders.*, t_price
         ELSE
            DISPLAY p_orders.*
         END IF

      COMMAND "Last" "View the last order in the list."
         FETCH LAST q_curs INTO p_orders.*, t_price

         IF priv THEN
            DISPLAY BY NAME p_orders.*, t_price
         ELSE
            DISPLAY p_orders.*
         END IF

      COMMAND "Select-and-exit" "Select the current order."
         CALL clear_menu()
         EXIT MENU

   END MENU

   CLOSE q_curs

END FUNCTION


-- The add_cust function allows privileged users to add
-- a row to the customer table.

FUNCTION add_cust()

   CLEAR FORM
   CALL clear_menu()
   CALL mess("Enter customer information.")
   INPUT BY NAME p_customer.fname THRU p_customer.phone 
   LET p_customer.customer_num =  0
   INSERT INTO customer VALUES (p_customer.*)
   LET p_customer.customer_num = SQLCA.SQLERRD[2]
   DISPLAY p_customer.customer_num TO customer_num
   CALL mess("Row added.")

END FUNCTION


--   The add_ord function allows privileged users to add
--   a row to the orders table.  Items must be added
--   at a later point, using a different form.

FUNCTION add_ord()

   CLEAR FORM
   CALL clear_menu()
   CALL mess("Enter order information.")
   INPUT BY NAME p_orders.order_date THRU p_orders.paid_date
   LET p_orders.order_num =  0
   INSERT INTO orders VALUES (p_orders.*)
   LET p_orders.order_num = SQLCA.SQLERRD[2]
   DISPLAY p_orders.order_num TO order_num
   CALL mess("Row added.")

END FUNCTION


--   The upd_cust function allows privileged users to
--   update a customer row.

FUNCTION upd_cust()

   CALL clear_menu()
   CALL mess("Update current customer information.")
   INPUT BY NAME p_customer.fname THRU p_customer.phone 
      WITHOUT DEFAULTS 
   UPDATE customer 
      SET customer.* = p_customer.*
      WHERE customer_num = p_customer.customer_num
   CALL mess("Row updated.")

END FUNCTION 


--   The upd_ord function allows privileged users to
--   update an order row.

FUNCTION upd_ord()

   CALL clear_menu()
   CALL mess("Update current order information.")
   INPUT BY NAME p_orders.order_date
      THRU p_orders.paid_date 
      WITHOUT DEFAULTS 
   UPDATE orders 
      SET orders.* = p_orders.*
      WHERE order_num = p_orders.order_num
   CALL mess("Row updated.")

END FUNCTION 


--   The del_cust function is available to privileged
--   users only.  It will delete a customer row, but
--   first checks whether the customer has any orders;
--   if so, it will not delete the row.

FUNCTION del_cust()

   DEFINE num_orders SMALLINT,
          answer     CHAR(1)

   SELECT COUNT(*) INTO num_orders
      FROM orders
      WHERE customer_num = p_customer.customer_num

      IF num_orders THEN
         CALL mess("This customer has orders and cannot be removed.")
         RETURN
      END IF

   CALL clear_menu()

   PROMPT "Do you really want to delete this record (y/n)? "
      FOR CHAR answer

   IF answer MATCHES "[yY]" THEN
      DELETE FROM customer 
         WHERE customer_num = p_customer.customer_num
   END IF

   CLEAR FORM
   CALL mess("Record deleted.")

END FUNCTION 


--   The del_ord function is available to privileged
--   users only.  It will delete an order row, but
--   first checks whether the order has any items;
--   if so, it will not delete the row.

FUNCTION del_ord()

   DEFINE num_items SMALLINT,
          answer    CHAR(1)

   SELECT COUNT(*) INTO num_items
      FROM items
      WHERE order_num = p_orders.order_num

      IF num_items THEN
         CALL mess("This order has items and cannot be removed.")
         RETURN
      END IF

   CALL clear_menu()

   PROMPT "Do you really want to delete this record (y/n)? "
      FOR CHAR answer

   IF answer MATCHES "[yY]" THEN
      DELETE FROM orders 
         WHERE order_num = p_orders.order_num
   END IF

   CLEAR FORM
   CALL mess("Record deleted.")

END FUNCTION 


--   The det_cust function is called when the user selects
--   the Detail option on the SEARCH Menu and ow2 is 
--   the current window.  The det_cust function provides
--   information about the customer who placed the order
--   currently displayed in the ow2 window.

FUNCTION det_cust()

   DEFINE answer CHAR(1)
   CURRENT WINDOW IS cw1
   SELECT * INTO p_customer.* FROM customer WHERE customer_num =
         p_orders.customer_num
   DISPLAY BY NAME p_customer.*
   PROMPT "Press RETURN to return to the other window. " 
      FOR answer

END FUNCTION


--   The det_ord function is called when the user selects
--   the Detail option on the SEARCH Menu and cw1 is
--   the current window.  The det_ord function provides
--   information about the orders placed by the customer
--   currently displayed in the cw1 window.

FUNCTION det_ord()

   DEFINE answer CHAR(1)
   CURRENT WINDOW IS ow2
   CALL set_curs(3)
   CALL view_ord()
   PROMPT "Press RETURN to return to the other window. " 
         FOR answer
   LET exist = 1       -- if no rows retrieved in detail window,
                       -- view_ord function will reset exist to 0.

END FUNCTION

--   The change_wind function is called when the user
--   selects the Switch option on the SEARCH Menu.  Menu
--   lines in the current window. of text.  The function
--   changes the current window and, if the value of
--   exist is 0 (no current row), clears the form.

FUNCTION change_wind()

   CALL clear_menu()

   IF cur = 1 THEN      -- current window is customer
      CURRENT WINDOW IS ow2
      LET cur = 2   -- new current window is orders
   ELSE 
      CURRENT WINDOW IS cw1
      LET cur = 1   -- current window is customer
   END IF

   IF exist = 0 THEN
      CLEAR FORM
   END IF

END FUNCTION


--   The clear_menu function clears the two
--   Menu lines in the current window.

FUNCTION clear_menu()

   DISPLAY "" AT 10, 1 
   DISPLAY "" AT 11, 1 

END FUNCTION


--   The mess function is passed a character string as an
--   argument and displays the characters on the last line
--   of the current window.

FUNCTION mess(str)

   DEFINE str CHAR(50)
   DISPLAY str CLIPPED AT 12,1
   SLEEP 3
   DISPLAY "" AT 12,1

END FUNCTION   
