
#######################################################################
# APPLICATION: Example 8 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex8.4gl                             FORM: f_stock.per,        # 
#                                                 f_manufsel.per      # 
#                                                                     # 
# PURPOSE: This module contains routines to add a new "stock" row  to #
#          the database. It also has a popup window to look up        #
#          manufacturer codes.                                        #
#                                                                     # 
# STATEMENTS:                                                         #
#          DISPLAY ARRAY                       INPUT - ON KEY         #
#          DECLARE CURSOR FOR SELECT                                  #
#                                                                     # 
# FUNCTIONS:                                                          #
#   input_stock2() - based on input_stock() in ex7.4gl file with a    #
#      popup window on the manufacturer code added.                   #
#   unique_stock() - see description in ex7.4gl file.                 #
#   insert_stock() - see description in ex7.4gl file.                 #
#   manuf_popup() -  displays popup window (f_manufsel) to allow      #
#      to select a valid manufacturer code.                           #
#   msg(str) - see description in ex5.4gl file.                       #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  01/23/91    dam             Split into separate files              #
#  01/04/91    dam             Created file                           #
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
  IF input_stock2() THEN
    CALL insert_stock()
    CLEAR FORM
  END IF

  CLOSE WINDOW w_stock
  CLEAR SCREEN

END MAIN

########################################
FUNCTION input_stock2()
########################################
--* Purpose: Accepts user input for stock information on the 
--*            f_stock form. Implements popup window on
--*            manu_code field.
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

    BEFORE FIELD manu_code
--* Notify user of special feature of manu_code field.
      MESSAGE  "Enter a manufacturer code or press F5 (CTRL-F) for a list."

    AFTER FIELD manu_code
--* Prevent user from leaving manu_code field empty
      IF gr_stock.manu_code IS NULL THEN
	ERROR "You must enter a manufacturer code. Please try again."
	NEXT FIELD manu_code
      END IF

      SELECT manu_name 
      INTO gr_stock.manu_name
      FROM manufact
      WHERE manu_code = gr_stock.manu_code

--* If no manu_name for specified code, have an invalid code
      IF (status = NOTFOUND) THEN
	ERROR 
  "Unknown manufacturer's code. Use F5 (CTRL-F) to see valid codes."
	LET gr_stock.manu_code = NULL
	NEXT FIELD manu_code
      END IF
      DISPLAY BY NAME gr_stock.manu_name
      MESSAGE ""

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

    ON KEY (F5, CONTROL-F)
--* If cursor is currently in manu_code field, implement popup window
      IF INFIELD(manu_code) THEN
--* Manufact popup returns code and name selected
	CALL manuf_popup() RETURNING gr_stock.manu_code, gr_stock.manu_name
--* If manu_code is NULL, user exited popup window with Cancel key
	IF gr_stock.manu_code IS NULL THEN
	  NEXT FIELD manu_code
	ELSE
--* manu_code is not null so display it on form
	  DISPLAY BY NAME gr_stock.manu_code
	END IF
--* Clear special manu_code field message
        MESSAGE ""

--* Verify that combination of stock_num and manu_code is
--*   unique in stock table. 
------------------------
	IF unique_stock() THEN
	  DISPLAY BY NAME gr_stock.manu_name
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

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL msg("Stock input terminated.")
    RETURN (FALSE)
  END IF
RETURN (TRUE)

END FUNCTION  -- input_stock2 --

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
FUNCTION manuf_popup()
########################################
--* Purpose: Implements the manufacturer popup on the f_manufsel
--*            form. 
--* Argument(s): NONE
--* Return Value(s): manu_code - code of manufact row chosen
--*                                     OR
--*                              NULL if no manufact rows exist or
--*                                   user presses Interrupt key
--*                  manu_name - name of manufact row chosen
---------------------------------------
  DEFINE 	pa_manuf ARRAY[200] OF RECORD 
		   	manu_code LIKE manufact.manu_code,
		   	manu_name LIKE manufact.manu_name
		END RECORD,

  		idx 		SMALLINT,
		manuf_cnt	SMALLINT,
		array_sz	SMALLINT,
		over_size	SMALLINT

  LET array_sz = 200		--* match size of pa_manuf array

--* Open new window for popup and display f_manufsel form
  OPEN WINDOW w_manufpop AT 7, 13
    WITH 12 ROWS, 44 COLUMNS
    ATTRIBUTE(BORDER, FORM LINE 4)

  OPEN FORM f_manufsel FROM "f_manufsel"
  DISPLAY FORM f_manufsel

--* Display user instructions for popup
  DISPLAY "Move cursor using F3, F4, and arrow keys."
    AT 1,2
  DISPLAY "Press Accept to select a manufacturer."
    AT 2,2

--* c_manufpop cursor will contain all manufact rows, ordered by code
  DECLARE c_manufpop CURSOR FOR
    SELECT manu_code, manu_name 
    FROM manufact
    ORDER BY manu_code

  LET over_size = FALSE

--* Read each manufact row into the pa_manuf array
  LET manuf_cnt = 1
  FOREACH c_manufpop INTO pa_manuf[manuf_cnt].*

--* Increment array index to get ready for next row
    LET manuf_cnt = manuf_cnt + 1

--* If new array index is bigger than size of pa_manuf, set over_size
--*   to TRUE and stop reading manufact rows
------------------------
    IF manuf_cnt > array_sz THEN
      LET over_size = TRUE
      EXIT FOREACH
    END IF
  END FOREACH

--* If array index is still one, FOREACH loop never executed: have
--*  no manufact rows in table.
------------------------
  IF (manuf_cnt = 1) THEN
    CALL msg("No manufacturers exist in the database.")
    LET idx = 1
--* Return a NULL manu_code to indicate no manufact rows exist
    LET pa_manuf[idx].manu_code = NULL
  ELSE
--* If over_size is TRUE, notify user that not all rows can display
    IF over_size THEN
      MESSAGE "Manuf array full: can only display ", 
	array_sz USING "<<<<<<"
    END IF

--* Initialize size of program array so ARR_COUNT() can track it
    CALL SET_COUNT(manuf_cnt-1)
--* Set int_flag to FALSE to make sure it correctly indicates Interrupt
    LET int_flag = FALSE

--* Display contents of pa_manuf program array in sa_manuf screen
--*   array (the screen array is defined within the f_manufsel form)
------------------------
    DISPLAY ARRAY pa_manuf TO sa_manuf.* 

--* Once the DISPLAY ARRAY ends, obtains last position of cursor
--*   within the array. This position is the selected manufacturer.
------------------------
    LET idx = ARR_CURR()

    IF int_flag THEN
--* If user ended DISPLAY ARRAY with Interrupt, return NULL manu_code
      LET int_flag = FALSE
      CALL msg("No manufacturer code selected.")
      LET pa_manuf[idx].manu_code = NULL
    END IF
  END IF

  CLOSE WINDOW w_manufpop
--* Use idx as index into program array to get selected code and name
  RETURN pa_manuf[idx].manu_code, pa_manuf[idx].manu_name

END FUNCTION  -- manuf_popup --

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

