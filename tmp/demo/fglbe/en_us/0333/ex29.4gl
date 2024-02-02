
#######################################################################
# APPLICATION: Example 29 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex29.4gl                            FORM: none                # 
#                                                                     # 
# PURPOSE: This program formats rows of the customer table into a     #
#          three-column mailing label stock.  Several features of     #
#          reports are demonstrated include the statements            #
#                                                                     # 
# STATEMENTS:                                                         # 
#          INITIALIZE		ON EVERY ROW	PAGE TRAILER          #
#          FIRST PAGE HEADER   	ON LAST ROW                           #
#                                                                     # 
# FUNCTIONS:                                                          #
#    three_up() is the report function.                               #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  01/23/91    dec             created example                        #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE 	gr_customer 	RECORD LIKE customer.*
END GLOBALS

########################################
MAIN
########################################
  DEFINE	repfile CHAR(80) -- report pathname

--* Accept name of file to contain mailing labels
  DISPLAY "Enter a filename to receive the labels, or for"
  DISPLAY "output to the screen (stdout) just press RETURN."
  DISPLAY ""
  PROMPT "Filename: " FOR repfile
  DISPLAY ""

--* If user pressed RETURN, send report output to screen. Otherwise
--*   send it to named file.
------------------------
  IF LENGTH(repfile)=0 THEN -- null response
    START REPORT three_up
    DISPLAY "Preparing labels for screen display..."
  ELSE -- filename
    START REPORT three_up TO repfile
    DISPLAY "Writing labels to file ", repfile CLIPPED,"..."
  END IF

--* The c_cust cursor will contain all customers, ordered by zipcode
--*   and, within zipcode, by company name.
------------------------
  DECLARE c_cust CURSOR FOR
    SELECT * INTO gr_customer.*
    FROM customer
    ORDER BY zipcode,company

--* Send each customer to three_up() report for mailing label
--*   formatting
------------------------
  FOREACH c_cust
    OUTPUT TO REPORT three_up()
  END FOREACH

  FINISH REPORT three_up

  CLEAR SCREEN
END MAIN

########################################
REPORT three_up() -- the report function
########################################
--* Purpose: Report function to create mailing labels for each
--*            customer in the customer table. It formats each record 
--*            into lines comprising three labels.  When it has filled a
--*            the lines of three, it prints them. It also saves the 
--*            lowest and the highest zipcodes on each page, and
--*            prints them at page bottom.
--*
--*          Three-up label stock in the US is typically 2.6 inches 
--*          across each label. In this example we assume that, at 
--*          ten characters per inch, a line is compose of a 3-character 
--*          margin followed by a 25-character label line, repeated 
--*          three times.  These numbers need to be adjusted for the 
--*          label stock used by the program.
--*
--* Argument(s): NONE  (uses global record gr_customer)
--* Return Value(s): NONE
---------------------------------------
  DEFINE current_column,		-- current column, from 0 to 3
	 column_width,			-- width of any label column
	 gutter_width 	SMALLINT,	-- gap between columns
	 margins 	ARRAY[3] OF SMALLINT, -- starting margin of each column
	 pageno 	SMALLINT,	-- current page number
	 lo_zip, 			-- lowest zipcode on current page
	 hi_zip LIKE customer.zipcode,  -- highest ditto
	 lines ARRAY[6] of CHARACTER(127), -- one row of labels
	 j, k 		SMALLINT,       -- misc indexes
	 city_fld 	SMALLINT,       -- size of city field
	 line_num 	SMALLINT        -- current line in lines array

  OUTPUT
    PAGE LENGTH 66
    LEFT MARGIN 0		-- these must be tuned to match the 
    TOP MARGIN 4		-- label stock used by program
    BOTTOM MARGIN 4

  FORMAT
    FIRST PAGE HEADER	-- initialize some variables
	LET pageno = 0
	LET current_column = 0
	LET lo_zip = NULL
	LET hi_zip = "00000"

--* Set up the margins for each of the three mailing-label columns
	LET column_width = 25
	LET gutter_width = 3
	LET margins[1] = gutter_width
	LET margins[2] = margins[1]+column_width+gutter_width
	LET margins[3] = margins[2]+column_width+gutter_width

--* Clear out label print lines
	FOR j = 1 TO 6
	    LET lines[j] = " "
	END FOR

    ON EVERY ROW
	IF (lo_zip IS NULL) THEN -- starting new page
	    LET lo_zip = gr_customer.zipcode 
	END IF
--* Keep track of highest zip code encountered so far
	IF (hi_zip < gr_customer.zipcode) THEN
	    LET hi_zip = gr_customer.zipcode
	END IF

--* Establish which column to print in and obtain appropriate margins
	LET current_column = current_column + 1
	LET j = margins[current_column]
	LET k = j + column_width - 1
--* j, k are now substring arguments for the text of this label
--*   within a page-wide line.
------------------------

--* If they are defined in the current record, print out the company
--*   name and first address line
------------------------
	IF gr_customer.company IS NOT NULL THEN
	  LET lines[2][j,k] = gr_customer.company
	END IF
	IF gr_customer.address1 IS NOT NULL THEN
	  LET lines[3][j,k] = gr_customer.address1
	END IF

--* If current record has a 2nd address line, print it. Adjust where 
--*   to print "city, state" based on whether this record has a 2nd 
--*   address line.
------------------------
	IF gr_customer.address2 IS NULL THEN
	  LET line_num = 4	-- move city, state up one line
	ELSE
	  LET lines[4][j,k] = gr_customer.address2
	  LET line_num = 5	
	END IF

--* The following formatting of "city, state zipcode" is specific to 
--*   US domestic address forms. Formatting also deals with the
--*   possibility that any of these fields could be empty (null).
------------------------
	IF gr_customer.city IS NULL THEN
          LET city_fld = j + 15   -- move to 1st position past city
	  LET k = city_fld + 1    -- make room for 2 chars (", ")
	  LET lines[line_num][city_fld,k] = ", "
          LET city_fld = 17       -- 15 for city, 2 for ", "
	ELSE
          LET city_fld = LENGTH(gr_customer.city) + 2
	  LET k = j + city_fld  -- make room for city name and ", "
	  LET lines[line_num][j,k] = gr_customer.city CLIPPED, ", "
	END IF

	IF gr_customer.state IS NULL THEN  
	  LET j = j + city_fld + 3   -- increment past state field
	ELSE
	  LET j = j + city_fld + 1   -- move to 1st position past ", "
	  LET k = j + 2		     -- make room for 2 chars (state)
				     --... plus 1 char (blank)
	  LET lines[line_num][j,k] = gr_customer.state, " "
	  LET j = k + 1		     -- increment past state field
	END IF
	IF gr_customer.zipcode IS NOT NULL THEN  
	  LET k = j + 4 	     -- make room for 5 chars (zip)
	  LET lines[line_num][j,k] = gr_customer.zipcode
	END IF

	IF current_column = 3 THEN	-- time to print lines and clear
	    FOR j = 1 to 6
		PRINT lines[j]
		LET lines[j] = " "
	    END FOR
	    LET current_column = 0	-- ready for next set
	END IF

    ON LAST ROW
	IF current_column > 0 THEN	-- print short last line
	    FOR j = 1 TO 6
		PRINT lines[j]
	    END FOR
	END IF

    PAGE TRAILER
	LET pageno = pageno + 1
	PRINT
	PRINT
	PRINT
	PRINT "page",pageno USING "-----",
		    COLUMN 50,
		    "Customers in zipcode ",lo_zip," to ",hi_zip
	LET lo_zip = NULL
	LET hi_zip = "00000"

END REPORT  -- three_up --
