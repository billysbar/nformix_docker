
#######################################################################
# APPLICATION: Example 7 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex7.4gl                             FORM: f_stock.per         # 
#                                                                     # 
# PURPOSE: This module contains routines to add a new "stock" row  to #
#          the database.                                              #
#                                                                     # 
# STATEMENTS:                                                         #
#          INSERT       IF (status < 0)                               #
#                                                                     # 
# FUNCTIONS:                                                          #
#   input_stock() - accepts user input for stock info.                #
#   unique_stock() - determines if stock number and manufacturer code #
#      are unique.                                                    #
#   insert_stock() - adds new "stock" row to database.                #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/22/91    dam             Split out functions                    #
#  12/17/90    dam             Added header to file                   #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_stock	RECORD 
		   stock_num 	LIKE stock.stock_num,
		   description 	LIKE stock.description,
		   manu_code 	LIKE manufact.manu_code,
		   manu_name 	LIKE manufact.manu_name,
		   unit 	LIKE stock.unit,
		   unit_price 	LIKE stock.unit_price
		END RECORD
END GLOBALS

########################################
MAIN
########################################

  OPTIONS
    COMMENT LINE 7,
    MESSAGE LINE LAST

  DEFER INTERRUPT

  OPEN WINDOW w_stock AT 5, 3
   WITH FORM "f_stock"
   ATTRIBUTE (BORDER)

  DISPLAY "ADD STOCK ITEM" AT 2, 25

--* If user enters a stock number, INSERT row into stock table
  IF input_stock() THEN
    CALL insert_stock()
    CLEAR FORM
  END IF

  CLOSE WINDOW w_stock
  CLEAR SCREEN

END MAIN

########################################
FUNCTION input_stock()
########################################
--* Purpose: Accepts user input for stock information on the 
--*            f_stock form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*		     FALSE - if user ends INPUT with Cancel key
---------------------------------------

  DISPLAY 
   " Press Accept to save stock data, Cancel to exit w/out saving."
    AT 1, 1 ATTRIBUTE (REVERSE, YELLOW)

  INPUT BY NAME gr_stock.stock_num, gr_stock.description,
		gr_stock.manu_code, gr_stock.unit,
		gr_stock.unit_price

    AFTER FIELD stock_num
--* Prevent user from leaving stock_num field empty
      IF gr_stock.stock_num IS NULL THEN
	ERROR "You must enter a stock number. Please try again."
	NEXT FIELD stock_num
      END IF

    AFTER FIELD manu_code
--* Prevent user from leaving manu_code field empty
      IF gr_stock.manu_code IS NULL THEN
	ERROR "You must enter a manufacturer code. Please try again."
	NEXT FIELD manu_code
      END IF

--* If manu_name is NULL, need to find manufacturer's name from database.
      IF gr_stock.manu_name IS NULL THEN
	SELECT manu_name 
	INTO gr_stock.manu_name
	FROM manufact
	WHERE manu_code = gr_stock.manu_code

--* If no manu_name for specified code, have an invalid code
	IF (status = NOTFOUND) THEN
	  ERROR "Unknown manufacturer's code. Please try again."
	  LET gr_stock.manu_code = NULL
	  NEXT FIELD manu_code
	END IF
	DISPLAY BY NAME gr_stock.manu_name

--* Verify that combination of stock_num and manu_code is
--*   unique in stock table. 
------------------------
        IF unique_stock() THEN
	  DISPLAY BY NAME gr_stock.manu_code, gr_stock.manu_name
	  NEXT FIELD unit
        ELSE
--* If stock_num/manu_code combination not unique, return user to
--*   stock_num field to try again.
------------------------
	  DISPLAY BY NAME gr_stock.description, gr_stock.manu_code,
	    gr_stock.manu_name
	  NEXT FIELD stock_num
        END IF
      END IF

    BEFORE FIELD unit
--* Display text in Message line to indicate special field feature
      MESSAGE "Enter a unit or press RETURN for 'EACH'"

    AFTER FIELD unit
--* If user doesn't enter a unit, default is "EACH"
      IF gr_stock.unit IS NULL THEN
	LET gr_stock.unit = "EACH"
	DISPLAY BY NAME gr_stock.unit
      END IF
--* Clear special unit message from Message line.
      MESSAGE ""

    BEFORE FIELD unit_price
--* Display "0.00" in an empty unit_price field
      IF gr_stock.unit_price IS NULL THEN
	LET gr_stock.unit_price = 0.00
      END IF

    AFTER FIELD unit_price
--* Prevent user from leaving unit_price field empty
      IF gr_stock.unit_price IS NULL THEN
	ERROR "You must enter a unit price. Please try again."
	NEXT FIELD unit_price
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL msg("Stock input terminated.")
    RETURN (FALSE)
  END IF
RETURN (TRUE)

END FUNCTION  -- input_stock --

########################################
FUNCTION unique_stock()
########################################
--* Purpose: Checks stock table for row with specified stock_num
--*            and manu_code. These two columns must be unique
--*            within the stock table.
--* Argument(s): NONE
--* Return Value(s): TRUE - new stock_num and manu_code (in gr_stock)
--*			    define a unique stock item.
--*		     FALSE - new stock_num and manu_code are not
--*			     unique and cannot define a new stock item
---------------------------------------
  DEFINE	stk_cnt	SMALLINT

--* Count number of stock rows with new stock_num and manu_code
--*   values
------------------------
  SELECT COUNT(*)
  INTO stk_cnt
  FROM stock
  WHERE stock_num = gr_stock.stock_num
    AND manu_code = gr_stock.manu_code

--* If new stock_num/manu_code is not unique, notify user
  IF (stk_cnt > 0) THEN
    ERROR "A stock item with stock number ", gr_stock.stock_num, 
	    " and manufacturer code ", gr_stock.manu_code, " exists."
    LET gr_stock.stock_num = NULL
    LET gr_stock.description = NULL
    LET gr_stock.manu_code = NULL
    LET gr_stock.manu_name = NULL
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- unique_stock --

########################################
FUNCTION insert_stock()
########################################
--* Purpose: Adds a new row to the stock table. 
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* Insert a new stock row with values stored in gr_stock global
--*  record.
------------------------
WHENEVER ERROR CONTINUE	-- set compiler flag to ignore runtime errors
    INSERT INTO stock (stock_num, description, manu_code, unit, 
			unit_price)
      VALUES (gr_stock.stock_num, gr_stock.description, gr_stock.manu_code, 
	      gr_stock.unit, gr_stock.unit_price)
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

--* If INSERT was not successful, notify user of error number
--*  (in "status").
------------------------
    IF status < 0 THEN
      ERROR status USING "-<<<<<<<<<<<", 
	": Unable to save stock item in database." 
    ELSE
      CALL msg("Stock item added to database.")
    END IF

END FUNCTION  -- insert_stock --

########################################
FUNCTION msg(str)
########################################
--* Purpose: Displays a "str" string of 78 characters in the Message
--*            line for 3 seconds then clears the Message line.
--* Argument(s): str - text to display
--* Return Value(s): NONE
---------------------------------------
  DEFINE	str	CHAR(78)

  MESSAGE str 
  SLEEP 3
  MESSAGE ""

END FUNCTION  -- msg --

