
#######################################################################
# APPLICATION: Example 30 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex30.4gl                            FORM: f_name.per          # 
#                                                                     # 
# PURPOSE: This program demonstrates how to produce a listing         #
#          of a database schema. It obtains the schema information by #
#          accessing the system catalog tables:                       #
#             syscolumns 	systables                             #
#                                                                     # 
# FUNCTIONS:                                                          #
#   get_dbname() - accepts user input of the name of a database using #
#      the f_name form. It is this database whose schema is to be     #
#      printed.                                                       #
#   schema(dbname) - gathers the schema information from the system   #
#      tables and sends it to the report for formatting.              #
#   convert_type(coltype_num, col_length) - converts the integer      #
#      column type and length information stored in syscolumns        #
#      (coltype and collength) into a string representation of the    #
#      column's data type.                                            #
#   cnvrt_dt(clngth) - converts the integer column length of a        #
#      DATETIME field ("clngth") into the qualifiers of the data type #
#      (YEAR, MONTH, ...).                                            #
#   cnvrt_varch(clngth) - converts the integer column length of a     #
#      VARCHAR field ("clngth") into the maximum and minimun column   #
#      lengths.                                                       #
#   cnvrt_intvl(clngth) - converts the integer column length of an    #
#      INTERVAL field ("clngth") into the qualifiers of the data type #
#      (YEAR, MONTH, ...).                                            #
#   qual_fld(ftype,fvalue) - converts a hex digit "fvalue" into the   #
#      corresponding field qualifier (YEAR, MONTH, ...).              #
#   intvl_lngth(hex_lngth,large_lngth,small_lngth) - converts the     #
#      field qualifier range values ("large_lngth" and "small_lngth") #
#      into the corresponding field qualifiers (YEAR, MONTH, ...).    #
#   to_hex(dec_number, power) - converts a decimal number,            #
#      "dec_number" into a string representation of a hex number. The #
#      "power" indicates the largest possible value of the hex number.#
#   hex_digit(dec_num) - converts a decimal digit, "dec_num", into a  #
#      hex char (0-9, A-F).                                           #
#   dec_digit(hex_char) - converts a hex char (0-9, A-F) "hex_char",  #
#      into a decimal digit (0-15).                                   #
#   schema_rpt() - report to create the schema listing.               #
#   report_output(menu_title) - see description in ex15.4gl file.     #
#   init_msgs() - see description in ex2.4gl file.                    #
#   open_db(dbname) - see description in ex24.4gl file.               #
#   prompt_window(question, x,y) - see description in ex6.4gl file.   #
#   msg(str) - see description in ex3.4gl file.                       #
#   clear_lines(numlines,mrow) - see description in ex6.4gl file.     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/06/91    dam             Created example 30 file                #
#  04/13/91    dec             Converted embedded subs to includes,   #
#                              neatened some comments, indents.       #
#  04/13/91    dec             delay to read msg when open_db fails   #
#  04/13/91    dec             change "invoice" to "report" in msg    #
#  04/15/91    dec	       tweak logic of to_hex function         #
#  04/15/91    dec             add "informix." to all systable names  #
#                              so as to work with mode-ansi dbs.      #
#  04/15/91    dec             append not_null also to varchar, text, #
#                              and byte displays, and move out of case#
#  04/16/91    dec             tweak logic of to_hex some more.       #
#######################################################################

GLOBALS
# used by open_db.sub, begin_wk.sub, commit_wk.sub, rollback_wk.sub
  DEFINE gr_database RECORD
--* These fields are set to TRUE or FALSE by the open_db() function
--*    based on the values in SQLAWARN following a database statement.
		       db_known   SMALLINT, -- following fields are usable
		       has_log    SMALLINT, -- based on SQLAWARN[2]
		       is_ansi    SMALLINT, -- based on SQLAWARN[3]
		       is_online  SMALLINT, -- based on SQLAWARN[4]
		       can_wait   SMALLINT  -- supports "set lock mode to wait"
    		     END RECORD


# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)
END GLOBALS

#######################################
MAIN
#######################################
  DEFINE	dbname	CHAR(50),
		msg_txt	CHAR(110),
		answer	CHAR(1)

--* Set of form lines to work with f_name form
  OPTIONS
	FORM LINE 2,
	COMMENT LINE 3,
	MESSAGE LINE 6,
	ERROR LINE LAST - 1
    
--* Open window and display f_name form. This form prompts the user
--*   form the name of the database whose schema is to be printed out.
------------------------
  OPEN WINDOW w_schema AT 2,3
    WITH 9 ROWS, 76 COLUMNS
    ATTRIBUTE (BORDER, COMMENT LINE 3)
    
  CALL get_dbname() RETURNING dbname
  IF dbname IS NOT NULL THEN

--* If user entered a database name, try opening it. If open succeeds,
--*   can print schema.
------------------------
    CALL clear_lines(5, 4)
    IF open_db(dbname) THEN
      CALL schema(dbname)
    ELSE -- unable to open specified db,
      SLEEP 3 -- give user time to read open_db()'s error msg
    END IF
  END IF
    
  CLOSE WINDOW w_schema
  CLEAR SCREEN

END MAIN
  
#######################################
FUNCTION get_dbname()
#######################################
--* Purpose: Accepts user input for the name of a database. 
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE	dbname	CHAR(50)
    
  OPEN FORM f_name FROM "f_name"
  DISPLAY FORM f_name
    
  DISPLAY "DATABASE SCHEMA LISTING"
    AT 2, 20
  DISPLAY " Press Accept to print schema or Cancel to exit w/out printing."
    AT 8, 1  ATTRIBUTE (REVERSE, YELLOW)
    
  LET int_flag = FALSE
  INPUT dbname FROM a_char
    BEFORE FIELD a_char
      MESSAGE " Enter the name of the database."

    AFTER FIELD a_char
      IF dbname IS NULL THEN
	ERROR "You must enter a database name."
	NEXT FIELD a_char
      END IF
  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    LET dbname = NULL -- input ended with ^C, take the hint
  END IF
    
  CLOSE FORM f_name
  RETURN (dbname)

END FUNCTION  -- get_dbname --

#######################################
FUNCTION schema(dbname)
#######################################
--* Purpose: This is the driver for the schema listing report. It
--*            prompts the user for where to send the report output:
--*            screen, file, or printer. Then for each user-defined 
--*            table in the database, it converts the encoded 
--*            data type of each column and sends the result to
--*            be formatted by the schema_rpt() report function.
--*            This encoded information is stored in the systables 
--*            and syscolumns system catalogs .
--* Argument(s): dbname - the name of the database whose schema is to
--*                       be printed
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	dbname		CHAR(50),
		pr_schema  RECORD 
		    dbname	CHAR(50),
		    is_online	SMALLINT,
		    tabname	CHAR(18),
		    nindexes 	SMALLINT,
		    colname 	CHAR(18),
		    colno 	SMALLINT,
		    coltype 	SMALLINT,
		    collength 	SMALLINT
	        END RECORD,

		coltypename	CHAR(50),
		print_option	CHAR(1),
		file_name	CHAR(20)

--* Determine where to send report output (schema listing
  LET print_option = report_output("SCHEMA LISTING", 5, 10)

  CASE (print_option)
    WHEN "F" -- build filename "DBxxx.lst" where "xxx" is the name
	     -- of the database whose schema is being listed
    	LET file_name = "DB"
	IF LENGTH(dbname) > 10 THEN -- limit length of name
	    LET file_name = file_name CLIPPED, dbname[1,10]
	ELSE
	    LET file_name = file_name CLIPPED, dbname CLIPPED
	END IF
	LET file_name = file_name CLIPPED, ".lst"
    
	START REPORT schema_rpt TO file_name
	MESSAGE " Writing schema report to ", file_name CLIPPED,
		" -- please wait."
	SLEEP 2
    
    WHEN "P"
	START REPORT schema_rpt TO PRINTER
	MESSAGE "Sending schema report to printer -- please wait."
	SLEEP 2
    
    WHEN "S"
	START REPORT schema_rpt 
	MESSAGE "Preparing report for screen -- please wait."
    
  END CASE
    
--* Fill pr_schema record with data needed by report header
  LET pr_schema.dbname = dbname
  LET pr_schema.is_online = gr_database.is_online

--* The c_schema cursor will contain the system catalog information
--*   for each user-defined table and column 
------------------------
  DECLARE c_schema CURSOR FOR
    SELECT tabname, nindexes, colname, colno, coltype, collength
    FROM informix.systables st, informix.syscolumns sc
    WHERE st.tabtype = "T"	-- tables, not views
      AND st.tabid > 99 	-- user tables, not system tables
      AND st.tabid = sc.tabid -- join condition
    ORDER BY st.tabname, sc.colno
    
  FOREACH c_schema INTO pr_schema.tabname THRU pr_schema.collength
    
--* Convert the encoded data type and length for each column to 
--*   a string containing the data type and send this column's info to
--*   the report
------------------------
    CALL convert_type(pr_schema.coltype, pr_schema.collength)
      RETURNING coltypename
    OUTPUT TO REPORT schema_rpt (pr_schema.*, coltypename, print_option)

  END FOREACH
    
  FINISH REPORT schema_rpt

END FUNCTION  -- schema --

#######################################
FUNCTION convert_type(coltype_num, col_length)
#######################################
--* Purpose: Converts the column's data type and length as stored in 
--*            the coltype and collength columns of syscolumns to a 
--*            string version of the column's data type. 
--* Argument(s): coltype_num - column's coded data type (as stored in
--*                            syscolumns.coltype)
--*              col_length - column's coded length (as stored in
--*                            syscolumns.collength)
--* Return Value(s): character string contains the column's
--*                  data type (as used to define the column)
---------------------------------------
  DEFINE 	coltype_num	SMALLINT,
		col_length	SMALLINT,

		msize		SMALLINT,
		nsize		SMALLINT,
		coltype_name	CHAR(50),
        	dt_length	CHAR(35),
        	intv_length	CHAR(35),
		not_null	CHAR(9),
		max_length	SMALLINT,
		min_length	SMALLINT

--* If the column type is > 256, the columns has been specified as NOT
--*   NULL. With 256 masked out, coltype_num still represents the column's
--*   data type.
------------------------
  LET not_null = NULL
  IF coltype_num >= 256 THEN
	LET coltype_num = coltype_num - 256
	LET not_null = " NOT NULL"
  END IF
    
--* Determine the column's data type based on the coltype column. Some
--*   types require additional conversion because the collength value 
--*   specifies the length of the column.
------------------------
  CASE coltype_num
    WHEN 0	-- CHAR(x)
	LET coltype_name = "CHAR(",
			   col_length USING "<<<<<<<<<<<", ")"
    WHEN 1	-- SMALLINT
	LET coltype_name = "SMALLINT"
    WHEN 2	-- INTEGER
	LET coltype_name = "INTEGER"
    WHEN 3	-- FLOAT
	LET coltype_name = "FLOAT"
    WHEN 4	-- SMALLFLOAT
	LET coltype_name = "SMALLFLOAT"
    WHEN 5	-- DECIMAL(m,n)
--* The collength value specifies the precision of the DECIMAL column
	LET msize = col_length / 256
	LET nsize = col_length mod 256
	LET coltype_name = "DECIMAL(", msize USING "<<<<<",
			   ",", nsize USING "<<<<<", ")"
    WHEN 6  -- in the SERIAL field: no account has been made of serials
	    --   with starting values
	LET coltype_name = "SERIAL"
    WHEN 7	-- DATE
	LET coltype_name = "DATE"
    WHEN 8	-- MONEY(m,n)
--* The collength value specifies the precision of the MONEY column 
	LET msize = col_length / 256
	LET nsize = col_length mod 256
	LET coltype_name = "MONEY(", msize USING "<<<<<"
	IF nsize <> 2 THEN -- scale not default 2, show it
	    LET coltype_name = coltype_name CLIPPED,
				",", nsize USING "<<<<<"
	END IF
	LET coltype_name = coltype_name CLIPPED, ")"
    WHEN 9 -- should not occur
	LET coltype_name = "PLAN 9"
    WHEN 10 	-- DATETIME first TO last (handle in subroutine)
--* The collength value specifies the qualifiers of the DATETIME
--*   column. 
------------------------
	CALL cnvrt_dt(col_length) RETURNING dt_length
	LET coltype_name = "DATETIME ", dt_length CLIPPED
    WHEN 11	-- BYTE (OnLine only)
	LET coltype_name = "BYTE"
    WHEN 12	-- TEXT (OnLine only)
	LET coltype_name = "TEXT"
    WHEN 13 	-- VARCHAR(max,min) (handle in subroutine)
--* The collength value specifies the minimum and maximum lengths of
--*   the VARCHAR column.
------------------------
	CALL cnvrt_varch(col_length) RETURNING max_length, min_length
	LET coltype_name = "VARCHAR(", max_length CLIPPED
	IF min_length > 0 THEN -- min not default of zero, show it
	    LET coltype_name = coltype_name CLIPPED, ",", min_length CLIPPED
	END IF
	LET coltype_name = coltype_name CLIPPED, ")"
    WHEN 14 	-- INTERVAL first TO last (handle in subroutine)
--* The collength value specifies the qualifiers of the INTERVAL
--*   column. 
------------------------
	CALL cnvrt_intvl(col_length) RETURNING intv_length
	LET coltype_name = "INTERVAL ", intv_length CLIPPED
    OTHERWISE 	-- ???
	LET coltype_name = "UNDEFINED: ", coltype_num
    END CASE

--* Concatenate any NOT NULL string to column's data type
    LET coltype_name = coltype_name CLIPPED, not_null
    
    RETURN (coltype_name)
END FUNCTION  -- convert_type --

#######################################
FUNCTION cnvrt_varch(clngth)
#######################################
--* Purpose: Converts the internal database representation of a
--*            VARCHAR column's length to the minimum and maximum 
--*            values for the column.
--* Argument(s): clngth - the syscolumns.collength value for the
--*                        VARCHAR column
--* Return Value(s): VARCHAR column's maximum and minimum length
---------------------------------------
  DEFINE 	clngth		SMALLINT,

       		hex_length	CHAR(4),
		min_length	SMALLINT,
		max_length	SMALLINT


--* Convert collength to hexadecimal. Since database uses masking of bits to
--*   quickly determine column size,  need to convert decimal number to one
--*   that more readily yields "bit" values.
------------------------
  LET hex_length = to_hex(clngth, 4)
    
--* Minimum length is 2 left-most "bits" so get decimal equivalent
  LET min_length = dec_digit(hex_length[1]) * 16 
		     + dec_digit(hex_length[2])
   
--* Minimum length is 2 right-most "bits" so get decimal equivalent
  LET max_length = dec_digit(hex_length[3]) * 16 
		     + dec_digit(hex_length[4])
    
  RETURN max_length, min_length 

END FUNCTION  -- cnvrt_varch --

#######################################
FUNCTION cnvrt_dt(clngth)
#######################################
--* Purpose: Converts the internal database representation of a
--*            DATETIME column's length to the field qualifiers
--*            for the column.
--* Argument(s): clngth - the syscolumns.collength value for the
--*                        DATETIME column
--* Return Value(s): DATETIME column's qualifiers in the form:
--*                      "large TO small"
---------------------------------------
  DEFINE 	clngth		SMALLINT,

       		large_fld	CHAR(11),
       		small_fld	CHAR(11),
       		dt_size		CHAR(35),
       		hex_length	CHAR(3),
		null_size	SMALLINT


--* Convert collength to hexadecimal. Since database uses masking of bits to
--*   quickly determine column size,  need to convert decimal number to one
--*   that more readily yields "bit" values.
------------------------
  LET hex_length = to_hex(clngth, 3)
    
--* "large" qualifier is coded in 2nd to left-most "bit" so get name
--*   of qualifier and its default size (default size not needed for
--*   DATETIME fields - is used in INTERVAL)
------------------------
  CALL qual_fld("l", hex_length[2])
    RETURNING large_fld, null_size
    
--* "small" qualifier is coded in 3rd to left-most "bit" so get name
--*   of qualifier and its default size (default size not needed for
--*   DATETIME fields - is used in INTERVAL)
------------------------
  CALL qual_fld("s", hex_length[3])
    RETURNING small_fld, null_size
    
--* Build qualifier string
  LET dt_size = large_fld CLIPPED, " TO ", small_fld CLIPPED
  RETURN (dt_size CLIPPED) 

END FUNCTION  -- cnvrt_dt --

#######################################
FUNCTION cnvrt_intvl(clngth)
#######################################
--* Purpose: Converts the internal database representation of a
--*            INTERVAL column's length to the field qualifiers
--*            for the column.
--* Argument(s): clngth - the syscolumns.collength value for the
--*                        INTERVAL column
--* Return Value(s): INTERVAL column's qualifiers in the form:
--*                      "large TO small"
---------------------------------------
  DEFINE 	clngth		SMALLINT,

       		large_fld	CHAR(11),
       		large_size	SMALLINT,
       		small_fld	CHAR(11),
       		small_size	SMALLINT,
       		intv_size	CHAR(35),
       		hex_length	CHAR(3),
		fld_lngth	SMALLINT,
		i		SMALLINT

--* Convert collength to hexadecimal. Since database uses masking of bits to
--*   quickly determine column size,  need to convert decimal number to one
--*   that more readily yields "bit" values.
------------------------
  LET hex_length = to_hex(clngth,3)
    
--* "large" qualifier is coded in 2nd to left-most "bit" so get name
--*   of qualifier and its default size (default size needed to see if
--*   column uses additional precision on qualifier)
------------------------
  CALL qual_fld("l", hex_length[2])
    RETURNING large_fld, large_size
    
--* "small" qualifier is coded in 3rd to left-most "bit" so get name
--*   of qualifier and its default size (default size needed to see if
--*   column uses additional precision on qualifier)
------------------------
  CALL qual_fld("s", hex_length[3])
    RETURNING small_fld, small_size
    
--* Determine if this INTERVAL has additional precision. If so, add
--*   precision value to the "large" qualifier (not valid to specify
--*   precision on "small" qualifier.
------------------------
  LET fld_lngth = intvl_lngth(hex_length, large_size, small_size)
    
  IF fld_lngth > 0 THEN
    LET i = LENGTH(large_fld) + 1
    LET large_fld[i, i + 2] = "(", fld_lngth USING "<", ")"
  END IF
    
--* Build qualifier string
  LET intv_size = large_fld CLIPPED, " TO ", small_fld CLIPPED
  RETURN (intv_size) 

END FUNCTION  -- cnvrt_intvl --

#######################################
FUNCTION qual_fld(ftype, fvalue)
#######################################
--* Purpose: Converts a single "bit" to its qualifier value.
--*            This function used for DATETIME and INTERVAL
--*            columns.
--* Argument(s): ftype - the "bit" value to convert to a 
--*                        qualifier
--*              fvalue - "l" if this is a "large" qualifier
--*                       "s" if this is a "small" qualifier
--* Return Value(s): name of the qualifier presented by the
--*                  "bit" in ftype
---------------------------------------
  DEFINE	ftype, fvalue	CHAR(1),

		fld_name	CHAR(11),
		fld_size	SMALLINT

--* Hexadecimal value (ftype) represents the qualifier name. Based on
--*   qualifier, get default "size" and store in fld_size. Default size is
--*   needed to determine precision for INTERVALs (not used for
--*   DATETIME)
------------------------
  CASE 
    WHEN (fvalue = "0")		  -- YEAR qualifier
      LET fld_name = "YEAR"
      LET fld_size = 4

    WHEN (fvalue = "2")		  -- MONTH qualifier
      LET fld_name = "MONTH"
      LET fld_size = 2

    WHEN (fvalue = "4")		  -- DAY qualifier
      LET fld_name = "DAY"
      LET fld_size = 2

    WHEN (fvalue = "6")		  -- HOUR qualifier
      LET fld_name = "HOUR"
      LET fld_size = 2

    WHEN (fvalue = "8")		  -- MINUTE qualifier
      LET fld_name = "MINUTE"
      LET fld_size = 2

    WHEN (fvalue MATCHES "[Aa]")  -- SECOND qualifier
      LET fld_name = "SECOND"
      LET fld_size = 2

    WHEN (fvalue MATCHES "[Bb]")  -- FRACTION(1) qualifier
      LET fld_name = "FRACTION(1)"
      LET fld_size = 1

    WHEN (fvalue MATCHES "[Cc]")  -- FRACTION(2) qualifier
      LET fld_size = 2		  --  (default for 1st qualifier)

--* If this is a "large" qualifier, default precision is 2 so just
--*   use default notation in qualifier. However, if this is a "small"
--*   qualifier, default precision is 3 so need to specify precision 
--*   (no default notation)
------------------------
      IF ftype = "l" THEN
        LET fld_name = "FRACTION"
      ELSE
        LET fld_name = "FRACTION(2)"
      END IF

    WHEN (fvalue MATCHES "[Dd]")  -- FRACTION(3) qualifier
      LET fld_name = "FRACTION"   --  (default for 2nd qualifier)
      LET fld_size = 3

    WHEN (fvalue MATCHES "[Ee]")  -- FRACTION(4) qualifier
      LET fld_name = "FRACTION(4)"
      LET fld_size = 4

    WHEN (fvalue MATCHES "[Ff]")  -- FRACTION(5) qualifier
      LET fld_name = "FRACTION(5)"
      LET fld_size = 5

    OTHERWISE
      LET fld_name = "uh oh: ", fvalue
      LET fld_size = 0
  END CASE

  RETURN fld_name, fld_size

END FUNCTION  -- qual_fld --

#######################################
FUNCTION intvl_lngth(hex_lngth, large_lngth, small_lngth)
#######################################
--* Purpose: Compares the internal database representation of the
--*            INTERVAL column's size with the "default" sizes of the 
--*            column's "large" and "small" qualifiers. If the 
--*            internal size is different from the default size, a 
--*            qualifier has non-default precision specified.
--* Argument(s): hex_lngth - hexadecimal representation of the
--*                          INTERVAL column's size (internal 
--*                          representation)
--*              large_lngth - default size of INTERVAL column's
--*                            "large" qualifier
--*              small_lngth - default size of INTERVAL column's
--*                            "small" qualifier
--* Return Value(s): precision on INTERVAL column's "large" qualifier
--*                      (non-default precision not valid on "small" 
--*                      qualifier)
--*                                OR
--*                  0 if "large" qualifier uses default precision
---------------------------------------
  DEFINE 	hex_lngth	CHAR(3),
		large_lngth	SMALLINT,
		small_lngth	SMALLINT,

		dec_lngth	SMALLINT,
		default_lngth	SMALLINT,
		num_flds	SMALLINT,
		ret_lngth	SMALLINT
  
--* Convert left-most "bit" to decimal. This is the interval field
--*   size
------------------------
  LET dec_lngth = dec_digit(hex_lngth[1])

--* Number of fields in INTERVAL is difference between 2nd and 3rd
--*   "bits"
------------------------
  LET num_flds = dec_digit(hex_lngth[3]) - dec_digit(hex_lngth[2])

--* Based on number of fields in INTERVAL, compare how big field
--*   would be if it used all default sizes (no precision) with
--*   how big it actually is (dec_lngth)
------------------------
  CASE num_flds
    WHEN 0	-- intvl has only 1 field: i.e. YEAR TO YEAR
	IF dec_lngth = large_lngth THEN  -- uses default
	  LET ret_lngth = 0
	ELSE
	  LET ret_lngth = dec_lngth  -- return actual precision
	END IF

    WHEN 1	-- intvl is FRACTION(2) to FRACTION(3) : this is
                --   default for both qualifiers
	LET ret_lngth = 0 

    WHEN -1	-- intvl is FRACTION(2) to FRACTION(1) : this is
                --   default for "large" qualifier
	LET ret_lngth = 0 

    OTHERWISE   -- intvl has 2,3,4, or 5 fields: i.e. HOUR TO MINUTE,
                --    HOUR TO SECOND

--* Calculate default size 
        LET default_lngth = (large_lngth + small_lngth) + (num_flds - 2)
	IF default_lngth = dec_lngth THEN	-- uses default
	  LET ret_lngth = 0
	ELSE	-- return actual precision
          LET ret_lngth = large_lngth + ( dec_lngth - default_lngth )
	END IF
  END CASE
    
  RETURN ret_lngth

END FUNCTION  -- intvl_lngth --

#######################################
FUNCTION to_hex(dec_number, power)
#######################################
--* Purpose: Converts a decimal number to its hexadecimal 
--*            equivalent (1-F). Largest possible hex number
--*            this function can return is FFFF.
--* Argument(s): dec_number - the decimal value to convert to a 
--*                        hexadecimal
--*              power - power of 16 to determine largest
--*                      possible hexadecimal number
--* Return Value(s): 4-character string containing the
--*                  hexadecimal equivalent of dec_number.
---------------------------------------
  DEFINE	dec_number	INTEGER,
		power		SMALLINT,

		the_num		INTEGER,
		i,j		SMALLINT,
		hex_power	INTEGER,
		hex_number	CHAR(4)

  LET the_num = dec_number
  IF the_num < 0 THEN -- greater than 0x7fff, force to unsigned status
    LET the_num = 65536 + the_num
  END IF

--* Create the power of 16 to use in the decimal-hex conversion.
--*   The power of 16 represents a hex digit: 1, 16, 256, ...
------------------------
  LET hex_power = 16 ** power
  LET hex_number = "0000"
    
--* For each power of 16 between 0 and "power" (16**0 to 16**power):
  FOR i = 1 TO power

--*    Decimal number is zero, so just exit
    IF the_num = 0 THEN
      EXIT FOR
    END IF
--*    Get digit for left-most position in hex number (16**power-1).
    LET hex_power = hex_power / 16

--*    If this power of 16 is less than the decimal number then
--*    a value exists at this hex digit. To get the value,
--*    divide the decimal by this power of 16, converting the
--*    result (1-15) to its hex digit (1-F). The remainder
--*    of the division is the portion of the decimal number that still
--*    needs to be converted.
------------------------
    IF the_num >= hex_power THEN
      LET hex_number[i] = hex_digit(the_num / hex_power)
      LET the_num = the_num MOD hex_power
    END IF
  END FOR
    
--* Return the "power" number of digits of the hex number
  RETURN (hex_number[1,power])

END FUNCTION  -- to_hex --

#######################################
FUNCTION hex_digit(dec_num)
#######################################
--* Purpose: Converts a decimal number (0-15) to its hexadecimal digit
--*            (0-F). The inverse operation is performed by the
--*            dec_digit() function.
--* Argument(s): dec_num - the decimal number to convert
--* Return Value(s): the hex digit that represents dec_num
---------------------------------------
  DEFINE 	dec_num		SMALLINT,

		hex_char	CHAR(1)

--* If the decimal number is 10 - 15, then it must be converted
--*   to its hex equivalent. Decimal numbers 0-9 do not need
--*   to be converted.
------------------------
  CASE dec_num
    WHEN 10
      LET hex_char = "A"
    WHEN 11
      LET hex_char = "B"
    WHEN 12
      LET hex_char = "C"
    WHEN 13
      LET hex_char = "D"
    WHEN 14
      LET hex_char = "E"
    WHEN 15
      LET hex_char = "F"
    OTHERWISE
      LET hex_char = dec_num
  END CASE

  RETURN hex_char

END FUNCTION  -- hex_digit --

#######################################
FUNCTION dec_digit(hex_char)
#######################################
--* Purpose: Converts a hexadecimal digit (0-F) to its decimal 
--*            number (0-15). The inverse operation is performed 
--*            by the hex_digit() function.
--* Argument(s): hex_char - the hex digit to convert
--* Return Value(s): the decimal number that represents hex_char
---------------------------------------
  DEFINE	hex_char	CHAR(1),

		dec_num		SMALLINT
	
--* If the hex number is A - F, then it must be converted
--*   to its decimal equivalent (10 - 15). Hex digits 0-9 do 
--*   not need to be converted.
------------------------
  IF hex_char MATCHES "[ABCDEF]" THEN
    CASE hex_char
      WHEN "A"
	LET dec_num = 10
      WHEN "B"
	LET dec_num = 11
      WHEN "C"
	LET dec_num = 12
      WHEN "D"
	LET dec_num = 13
      WHEN "E"
	LET dec_num = 14
      WHEN "F"
	LET dec_num = 15
    END CASE
  ELSE
    LET dec_num = hex_char
  END IF

  RETURN dec_num

END FUNCTION  -- dec_digit --

#######################################
REPORT schema_rpt(r, coltypname, print_dest)
#######################################
--* Purpose: Report function to create a schema listing.
--* Argument(s): r - record containing table and column info
--*              coltypname - string containing the column's
--*                           data type
--*              print_dest - "S" send output to screen
--*                             (need to PAUSE after a screenful)
--*                           "F" send output to file
--*                             (no PAUSE needed after a screenful)
--*                           "P" send output to print
--*                             (no PAUSE needed after a screenful)
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	r  RECORD 
		    dbname	CHAR(50),
		    is_online	SMALLINT,
		    tabname	CHAR(18),
		    nindexes 	SMALLINT,
		    colname 	CHAR(18),
		    colno 	SMALLINT,
		    coltype 	SMALLINT,
		    collength 	SMALLINT
	        END RECORD,
		coltypname	CHAR(50),
		print_dest	CHAR(1)

  OUTPUT 
    LEFT MARGIN 0
    RIGHT MARGIN 80

  FORMAT
    FIRST PAGE HEADER

--* Print a report header with the name of the database and
--*   the type of the database engine.
------------------------
	PRINT COLUMN 40, "DATABASE SCHEMA LISTING FOR ",
		r.dbname CLIPPED
	PRINT COLUMN 40, "IBM INFORMIX-";
	IF r.is_online THEN
	  PRINT COLUMN 53, "OnLine Database"
	ELSE
	  PRINT COLUMN 53, "SE Database"
	END IF
	PRINT COLUMN 50, today
	SKIP 3 LINES
	      
    PAGE HEADER
--* At the top of each page, list the page number
	PRINT COLUMN 60, "PAGE ", PAGENO USING "#&"
	SKIP 2 LINES

    BEFORE GROUP OF r.tabname
--* Before each new table, print table info:
--*       o  table name
--*       o  number of indexes
--*       o  column headers
------------------------
	NEED 6 LINES
	PRINT "TABLE: ", r.tabname CLIPPED,
	      COLUMN 30, "NUMBER OF INDEXES: ", r.nindexes USING "&<<<<"
	PRINT "----------------------------------------";
	PRINT "----------------------------------------"
	PRINT COLUMN 4, "Column", COLUMN 27, "Type"
	PRINT "----------------------------------------";
	PRINT "----------------------------------------"

    AFTER GROUP OF r.tabname
--* After each table has been printed, skip lines
	SKIP 2 LINES

    ON EVERY ROW 
--* Print column info
	PRINT COLUMN 4, r.colname, COLUMN 27, coltypname CLIPPED
	IF (print_dest = "S") AND (LINENO > 22) THEN
--* If output is the screen, break report output into screens
	  PAUSE "Press RETURN to see next screen"
	  SKIP TO TOP OF PAGE
  	END IF      
      
END REPORT  -- schema_rpt --

########################################
FUNCTION report_output(menu_title, x,y)
########################################
--* Purpose: Displays a menu giving user the possible destinations
--*            for a report.
--*            form. 
--* Argument(s): menu_title - title to display for menu 
--*              x - x coordinate (row) for menu's window
--*              y - y coordinate (column) for menu's window
--* Return Value(s): "S" - send output to screen
--*                  "F" - send output to file
--*                  "P" - send output to printer
---------------------------------------
  DEFINE	menu_title	CHAR(15),
		x		SMALLINT,
		y		SMALLINT,

		rpt_out		CHAR(1)

  OPEN WINDOW w_rpt AT x, y
    WITH 2 ROWS, 41 COLUMNS
    ATTRIBUTE (BORDER)

--* This menu provides a list of possible report destinations. To
--* allow customization of the menu, the name of the menu is passed 
--* in as an argument.
--* NOTE: having a variable as the menu title is a new 4.1 feature.
------------------------
  MENU menu_title
    COMMAND "File" "Save report output in a file.          "
      LET rpt_out = "F"
      EXIT MENU

    COMMAND "Printer" "Send report output to the printer.     "
      LET rpt_out = "P"
      EXIT MENU

    COMMAND "Screen" "Send report output to the screen.      "
--* Warn user that sending output to the screen means that the output
--*   cannot be saved.
------------------------
      LET ga_dsplymsg[1] = "Output is not saved after it is sent to "
      LET ga_dsplymsg[2] = "            the screen." 
      LET x = x - 1
      LET y = y + 2
      IF prompt_window("Are you sure you want to use the screen?", x, y)
      THEN
        LET rpt_out = "S"
	EXIT MENU
      ELSE
	NEXT OPTION "File"
      END IF
  END MENU

  CLOSE WINDOW w_rpt
  RETURN rpt_out

END FUNCTION  -- report_output --

########################################
FUNCTION init_msgs()
########################################
--* Purpose: Clears out the global message array ga_dsplymsg.
--*    It is called in the message_window() and prompt_window() 
--*    functions after each of these functions display the contents 
--*    of the ga_dsplymsg array.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	i	SMALLINT

  FOR i = 1 TO 5
    LET ga_dsplymsg[i] = NULL
  END FOR

END FUNCTION  -- init_msgs --

#######################################
FUNCTION prompt_window(question, x,y)
#######################################
--* Purpose: Displays a window containing user-defined text
--*            and a user-defined prompt which can be answered
--*            Yes or No.
--* Argument(s): question - text of prompt for user
--*              x - x coordinate (column) of window's position
--*              y - y coordinate (row) of window's position
--* Return Value(s): NONE
---------------------------------------
  DEFINE question	CHAR(48),
	 x,y		SMALLINT,

	 numrows	SMALLINT,
  	 rownum,i	SMALLINT,
	 answer		CHAR(1),
	 yes_ans	SMALLINT,
	 invalid_resp	SMALLINT,
	 ques_lngth	SMALLINT,
	 unopen		SMALLINT,
	 array_sz	SMALLINT,
	 local_stat	SMALLINT

--* The array_sz variable contains the size of the global message
--*   array, ga_dsplymsg. If the size of this array needs to be
--*   changed in the future, the developer only needs to change
--*   the value of array_sz to update the prompt_window() function 
------------------------
  LET array_sz = 5
  LET numrows = 4		-- numrows value:
				--        1 (for the window header)
				--        1 (for the window border)
				--        1 (for the empty line before
				--            the first line of message)
				--        1 (for the empty line after
				--            the last line of message)

--* Count the number of non-null (non-blank) lines currently
--*   stored in ga_dsplymsg
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      LET numrows = numrows + 1
    END IF
  END FOR

--* Repeat attempt to open window until it is successful
  LET unopen = TRUE
  WHILE unopen

--* Set compiler flag so that runtime error checking is turned off
WHENEVER ERROR CONTINUE

--* Open the prompt window at the coordinates passed in as function
--*   arguments. 
------------------------
    OPEN WINDOW w_prompt AT x, y
      WITH numrows ROWS, 52 COLUMNS
      ATTRIBUTE (BORDER, PROMPT LINE LAST)

--* Set compiler flag so that runtime error checking is turned back on
WHENEVER ERROR STOP

--* If OPEN WINDOW was not successful, find out why.
    LET local_stat = status
    IF (local_stat < 0) THEN

--* If status is -1138 or -1144, window coordinates don't fit
--*   on current screen. Change window coordinates to 3,3
------------------------
      IF (local_stat = -1138) OR (local_stat = -1144) THEN
	MESSAGE "prompt_window() error: changing coordinates to 3,3."
	SLEEP 2
	LET x = 3
	LET y = 3
      ELSE

--* If status is any other error, cannot recover
	MESSAGE "prompt_window() error: ", local_stat USING "-<<<<<<<<<<<"
	SLEEP 2
	EXIT PROGRAM
      END IF
    ELSE
      LET unopen = FALSE
    END IF
  END WHILE

  DISPLAY " APPLICATION PROMPT" AT 1, 17
   ATTRIBUTE (REVERSE, BLUE)

--* Display non-null lines of ga_dsplymsg in the message window.
  LET rownum = 3		-- start text display at third line
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      DISPLAY ga_dsplymsg[i] CLIPPED AT rownum, 2
      LET rownum = rownum + 1
    END IF
  END FOR

--* Create prompt message using "question" argument and appending
--*   the string "(n/y)" to the end (if there is room).
------------------------
  LET yes_ans = FALSE
  LET ques_lngth = LENGTH(question)
  IF ques_lngth <= 41 THEN 	-- room enough to add "(n/y): " string
    LET question [ques_lngth + 2, ques_lngth + 7] = "(n/y):" 
  END IF

--* Repeat prompt until user answers either "Y", "y", "N", or "n".
--*   Set yes_ans to TRUE is user answers YES and to FALSE for NO.
------------------------
  LET invalid_resp = TRUE
  WHILE invalid_resp
    PROMPT question CLIPPED, " " FOR answer
    IF answer MATCHES "[nNyY]" THEN
      LET invalid_resp = FALSE
      IF answer MATCHES "[yY]" THEN
	LET yes_ans = TRUE
      END IF
    END IF
  END WHILE

--* Clear out ga_dsplymsg array so it is ready for the next user call
  CALL init_msgs()
  CLOSE WINDOW w_prompt

--* Return user's response: TRUE = Yes, FALSE = No
  RETURN (yes_ans)

END FUNCTION  -- prompt_window --

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

########################################
FUNCTION clear_lines(numlines, mrow)
########################################
--* Purpose: Clears out a specified number of lines, starting
--*            at "mrow". 
--* Argument(s): numlines - number of lines to clear
--*              mrow - first row to clear
--* Return Value(s): NONE
---------------------------------------
  DEFINE	numlines	SMALLINT,
		mrow		SMALLINT,

		i		SMALLINT

  FOR i = 1 TO numlines
--* Use mrow to indicate the x coordinate (row) to clear
    DISPLAY 
      "                                                                      "
      AT mrow,1
--* Increment x coordinate by one for next row
    LET mrow = mrow + 1
  END FOR

END FUNCTION  -- clear_lines --

########################################
FUNCTION open_db(dbname)
########################################
--* Purpose: Dynamically executes a DATABASE statement and saves
--*            the resulting flags from SQLAWARN in the global 
--*            record gr_database.
--* Argument(s): dbname - a character string containing the name 
--*                       of the database to open. It may include 
--*                       a sitename:  "dbname@sitename" or 
--*                       "//sitename/dbname". It may also include 
--*                       the keyword exclusive: "dbname EXCLUSIVE". 
--*                       It is to support this last feature that 
--*                       we prepare and execute the statement.
--* Return Value(s): TRUE - if database was successfully opened
--*                  FALSE - if unable to open specified database
---------------------------------------
    DEFINE	dbname CHAR(50),
		-- size of above allows for sitename (8), dbname (10),
		-- the word " EXCLUSIVE" and punctuation.

		dbstmt CHAR(60), -- "DATABASE " plus the above
		sqlr   SMALLINT

    LET gr_database.db_known = FALSE -- initialize with safe values
    LET gr_database.has_log = FALSE
    LET gr_database.is_ansi = FALSE
    LET gr_database.is_online = FALSE
    LET gr_database.can_wait = FALSE

WHENEVER ERROR CONTINUE
--* The CLOSE DATABASE statement returns an error -349 if no database
--*     But when using Informix-Link or -Star and there IS an open 
--*     database, and it happens to be remote, an attempt to open 
--*     a database produces -917 Must close current database.
------------------------
    CLOSE DATABASE
    IF SQLCA.SQLCODE <> 0 AND SQLCA.SQLCODE <> -349 THEN
	ERROR "Error ",SQLCA.SQLCODE," closing current database."
	RETURN FALSE
    END IF -- either 0 or -349 is OK here

--* Create DATABASE statement to execute (in case user added
--*   EXCLUSIVE keyword as part of argument).
------------------------
    LET dbstmt = "DATABASE ",dbname
    PREPARE prepdbst FROM dbstmt
    IF SQLCA.SQLCODE <> 0 THEN -- big syntax trouble in "dbname"
	ERROR "Not an acceptable database name: ",dbname
	RETURN FALSE
    END IF
    EXECUTE prepdbst
    LET sqlr = SQLCA.SQLCODE
WHENEVER ERROR STOP

    IF sqlr = 0 THEN	-- we have opened the database

--* Since the statement succeeded, "prepdbst" was freed by
--*    the engine automatically
------------------------

--* Set the values of the gr_database global record based on
--*   the results in SQLCA after the DATABASE statement executed
------------------------
	LET gr_database.db_known = TRUE
	IF SQLCA.SQLAWARN[2] = "W" THEN
		LET gr_database.has_log = TRUE
	END IF
	IF SQLCA.SQLAWARN[3] = "W" THEN
	    LET gr_database.is_ansi = TRUE
	END IF
	IF SQLCA.SQLAWARN[4] = "W" THEN
	    LET gr_database.is_online = TRUE
	ELSE -- not online, check lock support
	    SET LOCK MODE TO WAIT
	    IF SQLCA.SQLCODE = 0 THEN -- didn't get -527 or -513
	    	LET gr_database.can_wait = TRUE
	    END IF
	    SET LOCK MODE TO NOT WAIT -- restore default, ignore return code
	END IF
    ELSE 

--* The database did not open; display a message. Although there 
--*   is probably nothing the program can do with no database open, 
--*   we will not use an EXIT PROGRAM here, because there is also 
--*   no harm it can do with no database open!
------------------------
	FREE prepdbst -- since not freed automatically when stmt fails

--* Check for possible causes of failure and notify user
	CASE 
	  WHEN (sqlr = -329 OR sqlr = -827)
	   ERROR dbname CLIPPED,
			": Database not found or no system permission." 
	  WHEN (sqlr = -349)
	   ERROR dbname CLIPPED,
			" not opened, you do not have Connect privilege."
	  WHEN (sqlr = -354)
	    ERROR dbname CLIPPED,
			": Incorrect database name format."
	  WHEN (sqlr = -377)
	    ERROR "open_db() called with a transaction still incomplete."
	  WHEN (sqlr = -512)
	    ERROR "Unable to open in exclusive mode, db probably in use."
	OTHERWISE
	    ERROR dbname CLIPPED,
			": error ",sqlr," on DATABASE statement."
	END CASE
    END IF
    RETURN gr_database.db_known

END FUNCTION  -- open_db --

