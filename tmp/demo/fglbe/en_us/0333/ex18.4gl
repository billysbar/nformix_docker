
#######################################################################
# APPLICATION: Example 18 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex18.4gl                            FORM: f_catalog.per,      # 
#                                                 f_catadv.per,       # 
#                                                 f_catdescr.per      # 
#                                                                     # 
# PURPOSE: This program puts up a scrolling display of the "catalog"  #
#          table. This table contains a VARCHAR, TEXT and BYTE column.#
#          These data types are unique to the Informix OnLine         #
#          NOTE 1: The schema only contains the "catalog" table if    #
#                  you are using the OnLine database. If you are using#
#                  an SE database, this program will exit without     #
#                  accessing the "catalog" table.                     #
#                                                                     # 
#          This program can display and update the VARCHAR and TEXT   #
#          columns.                                                   #
#                                                                     # 
#          NOTE 2: Before the program can handle images (BYTE column  #
#                  "cat_pic" in "catalog"), it must be customized     #
#                  for the image formats in use on the current host   #
#                  system (a GUI).  For more information on handling  #
#                  BYTE images, see the BLOB demo released with       #
#                  version 4.1 of the 4GL software.                   #
#                                                                     # 
# STATEMENTS:                                                         # 
#          LOCATE           FREE                                      #
#                                                                     # 
# FUNCTIONS:                                                          #
#   is_online() - checks to see if the current database is an OnLine  #
#     or SE database. OnLine data types are not available with an SE  #
#     database.                                                       #
#   load_arrays() - loads the contents of the "catalog" table into    #
#     global arrays: ga_catrows, and ga_catrids. Instead of reading   #
#     the values of the catalog TEXT columns (cat_descr), this program#
#     marks a character field as "Y" or "N" indicating the presence of#
#     the TEXT value.                                                 #
#   open_wins() - opens all windows used in the program.              #
#   close_wins() - closes all windows used in the program.            #
#   dsply_cat(cat_cnt) - displays the contents of the catalog program #
#     array (ga_catrows) on the form f_catalog.                       #
#   show_advert(rownum) - displays the contents of the VARCHAR column #
#     (cat_advert) on the form f_catadv.                              #
#   show_descr(rownum) - displays the contents of the TEXT column     #
#     (cat_descr) on the form f_catdescr.                             #
#   upd_err() -  reports an error if one occurs during an UPDATE.     #
#   msg(str) - see description in ex5.4gl file.                       #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated header                         #
#  01/30/91    dam             Created example 18 file                #
#######################################################################

-- /////////////////////////////////////////////////////////////////////// --
--
--                       NOTE TO INFORMIX USERS
--
-- /////////////////////////////////////////////////////////////////////// --
--
-- This program assumes that the OnLine engine is up and running on
-- your system.

DATABASE stores2

GLOBALS
  DEFINE 	g_txflag 	CHAR(1),  -- TRUE if database uses transactions
		g_arraysz	SMALLINT, -- size of arrays used in ARRAY stmts
		g_txtblob  	TEXT,	  -- cat_descr value, located in memory

--* The ga_catrows array holds data to be displayed through form 
--*   f_catalog.per .  This record structure must match the screen-record 
--*   defined in the form.
------------------------
		ga_catrows ARRAY[200] OF RECORD
		  catalog_num	LIKE catalog.catalog_num,
		  stock_num 	LIKE stock.stock_num,
		  manu_name	LIKE manufact.manu_name,
		  has_pic	CHAR(1),
		  has_desc	CHAR(1),
		  description	CHAR(15)
		END RECORD,

--* In ga_catadv[ j ] is the VARCHAR, cat_advert, that matches row 
--*   ga_catrows[ j ]. It is held separately because it is not displayed 
--*   in the screen record.
------------------------
		ga_catadv ARRAY[200] OF LIKE catalog.cat_advert,
	
--* In ga_catrids[ j ] is the ROWID of the data in ga_catrows[ j ].  It 
--*    is used for fast selection of the TEXT or VARCHAR value for a 
--*    specified row.
------------------------
		ga_catrids ARRAY[200] OF INTEGER

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################
  DEFINE	cat_cnt  	SMALLINT	-- count of rows actually read

  DEFER INTERRUPT 	-- ...do not stop cold on error or ^C	

--* Set up form and text lines to work with f_catalog form
  OPTIONS 
    MESSAGE LINE LAST,
    PROMPT LINE LAST,
    COMMENT LINE FIRST,
    FORM LINE FIRST+1

--* Verify that current database is an OnLine database
  IF NOT is_online() THEN
    EXIT PROGRAM
  END IF

--* Initialize size of global arrays (ga_catrows, ga_catadv, ga_catrids)
--*   so that future changes in the size of these arrays will only
--*   require changing the actual array definitions and the value
--*   assigned to this global variable.
------------------------
  LET g_arraysz = 200

--* Open all forms that used
  OPEN FORM f_catalog FROM "f_catalog"
  OPEN FORM f_catadv FROM "f_catadv"
  OPEN FORM f_catdescr FROM "f_catdescr"

--* Locate the TEXT blob variable in a file
  LOCATE g_txtblob IN FILE    

--* Load up the contents of the catalog table into arrays.
  CALL load_arrays() RETURNING cat_cnt

--* Open all windows used in the program
  CALL open_wins()
--* Display contents of ga_catrows to the f_catalog form
  CALL dsply_cat(cat_cnt)
--* Close all windows used in the program
  CALL close_wins()
  CLEAR SCREEN
END MAIN

########################################
FUNCTION is_online()
########################################
--* Purpose: Determines if the stores2 database uses the
--*          IBM Informix-OnLine engine and if it uses 
--*             transactions by executing the DATABASE 
--*             statement and reading the SQLCA array.
--* Argument(s): NONE
--* Return Value(s): TRUE - if stores2 uses OnLine engine
--*                  FALSE - if stores2 does not use OnLine engine
---------------------------------------

WHENEVER ERROR CONTINUE

--* The following should not be necessary, and returns an error -349
--*   if no database is open.  But when using Informix-Link or -Star
--*   and there IS an open database, and it happens to be remote, an
--*   attempt to open a database produces -917 Must close current database.
------------------------
  CLOSE DATABASE
WHENEVER ERROR STOP
  IF sqlca.sqlcode <> 0 AND sqlca.sqlcode <> -349 THEN
    ERROR "Error ",sqlca.sqlcode," closing current database."
    RETURN (FALSE)
  END IF -- either 0 or -349 is OK here

--* Open the database a 2nd time to read the SQLCA array.
--*   SQLCA.SQLAWARN[2] is "W" if the database uses transactions
--*   SQLCA.SQLAWARN[4] is "W" if the database is an OnLine
------------------------
  DATABASE stores2

--* If SQLCA.SQLAWARN[2] is "W", the database uses transactions
  LET g_txflag = FALSE
  IF SQLCA.SQLAWARN[2] = "W" THEN	 -- get use of transaction
    LET g_txflag = TRUE
  END IF

--* If SQLCA.SQLAWARN[4] is "W", the database engine is OnLine
  IF SQLCA.SQLAWARN[4] <> "W" THEN
      LET ga_dsplymsg[1] = "This database is not an INFORMIX OnLine"
      LET ga_dsplymsg[2] = "  database. You cannot run this example because"
      LET ga_dsplymsg[3] = "  it accesses a table containing data types"
      LET ga_dsplymsg[4] = "  specific to OnLine (VARCHAR, TEXT, BYTE)."
      CALL message_window(4,4)
      CLEAR SCREEN
      RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- is_online --

########################################
FUNCTION load_arrays()
########################################
--* Purpose: Loads the global arrays with the catalog info.
--*            Global arrays are:
--*	          ga_catrows - catalog info to be displayed
--*	          ga_catadv - VARCHAR info of selected catalog rows
--*	          ga_catrids - ROWIDs of selected catalog rows
--* Argument(s): NONE
--* Return Value(s): number of items in the each of the global arrays
---------------------------------------
  DEFINE	idx	SMALLINT

--* Associate a cursor with the SELECT stmt to find the catalog info
--*   for the global arrays
------------------------
  DECLARE c_cat CURSOR FOR
    SELECT catalog.catalog_num, catalog.stock_num,
	   manufact.manu_name, stock.description,
	   catalog.cat_advert, catalog.ROWID
    FROM catalog,manufact,stock
    WHERE catalog.stock_num = stock.stock_num
      AND catalog.manu_code = manufact.manu_code
      AND stock.manu_code = manufact.manu_code
    ORDER BY 1

--* Open a special window to notify user of cause of delay in
--*   execution
------------------------
  OPEN WINDOW w_msg AT 5,5
    WITH 4 ROWS, 60 COLUMNS
    ATTRIBUTE (BORDER)

  DISPLAY "ACCESSING OnLine DATA TYPES"
    AT 1, 20
  DISPLAY "Loading catalog data into arrays, please wait..."
    AT 3, 2

  LET idx = 1 { invariant: idx-1 rows have been loaded }
  FOREACH c_cat INTO ga_catrows[idx].catalog_num,
		   ga_catrows[idx].stock_num,
		   ga_catrows[idx].manu_name,
		   ga_catrows[idx].description,
		   ga_catadv[idx],
		   ga_catrids[idx]

--* The FOREACH loads the non-blob values into the arrays, but we do
--*   not want to load the blob values now, we have nowhere to put 
--*   them and it would take too long.  However we do need to know 
--*   if they exist (are not null) in each row. In order to find out, 
--*   we set an array column to "N" and then SELECT a literal "Y" 
--*   over it only where there is non-null blob data.  Use of ROWID 
--*   makes these SELECTs go very quickly.
------------------------
	LET ga_catrows[idx].has_desc = "N"
	SELECT "Y" 
	INTO ga_catrows[idx].has_desc
	FROM catalog
	WHERE rowid = ga_catrids[idx]
	  AND cat_descr IS NOT NULL

	LET ga_catrows[idx].has_pic = "N"
	SELECT "Y" 
	INTO ga_catrows[idx].has_pic
	FROM catalog
	WHERE ROWID = ga_catrids[idx]
	  AND cat_picture IS NOT NULL

	LET idx = idx + 1
	IF idx > g_arraysz THEN -- make sure we don't run overfill arrays
		EXIT FOREACH
	END IF
  END FOREACH

  LET idx = idx - 1 	-- actual number of rows loaded

  CLOSE WINDOW w_msg

  RETURN (idx)

END FUNCTION  -- load_arrays --

########################################
FUNCTION open_wins()
########################################
--* Purpose: Opens all the 4GL windows used by the program, main 
--*             window last so it will be "on top".
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  OPEN WINDOW w_advert AT 6, 6 
    WITH 11 ROWS, 68 COLUMNS 
    ATTRIBUTE(BORDER, COMMENT LINE LAST)

  OPEN WINDOW w_descr AT 4, 4 
    WITH 13 ROWS, 72 COLUMNS 
    ATTRIBUTE(BORDER, COMMENT LINE LAST)

  OPEN WINDOW w_cat AT 2, 2 
    WITH 20 ROWS, 77 COLUMNS

END FUNCTION  -- open_wins --

########################################
FUNCTION close_wins()
########################################
--* Purpose: Closes all the 4GL windows used in the program
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  CLOSE WINDOW w_advert
  CLOSE WINDOW w_descr
  CLOSE WINDOW w_cat

END FUNCTION  -- close_wins --

########################################
FUNCTION dsply_cat(cat_cnt)
########################################
--* Purpose: Displays the contents of the global array ga_catrows
--*            array on the f_catalog form
--* Argument(s): cat_cnt - the number of selected catalog rows
--* Return Value(s): NONE
---------------------------------------
  DEFINE	cat_cnt		SMALLINT

--* Make sure the catalog window, w_cat, is the current window
--*   (i.e. it is "on top" of all others). 
------------------------
  CURRENT WINDOW IS w_cat

--* Display f_catalog in the catalog window. This form has already
--*   been opened in the MAIN function.
------------------------
  DISPLAY FORM f_catalog

--* Tell 4GL the number of rows so display-array won't run off end
  CALL SET_COUNT(cat_cnt)
  LET int_flag = FALSE

--* Use DISPLAY ARRAY to display the contents of the arrays and
--*    and let the user scroll around. 
------------------------
  DISPLAY ARRAY ga_catrows TO sa_cat.*
    ON KEY (CONTROL-E)
	EXIT DISPLAY

--* The following functions make other windows current. Each
--*    must make the main window current when it exits.

    ON KEY (CONTROL-V,F4)
--* These sequences display the advertising copy (VARCHAR value) for
--*   the current catalog row.
------------------------
	CALL show_advert(ARR_CURR())

    ON KEY (CONTROL-T,F5)
--* These sequences display the copy (TEXT value) for the current
--*   catalog row.
------------------------
	CALL show_descr(ARR_CURR())

  END DISPLAY

--* Free the temporary file used to hold the TEXT value
  FREE g_txtblob

END FUNCTION  -- dsply_cat --

########################################
FUNCTION show_advert(rownum)
########################################
--* Purpose: Uses the w_advert window to display and update the
--*            VARCHAR value, catalog.cat_advert, for the current
--*            catalog row. The current row is the one that the
--*	       the cursor was on when the user initiated this 
--*	       function.
--* Argument(s): rownum - the index in the program array (ga_catrows)
--*	                    of the current catalog row. This value
--*	                    is sent into the function by the
--*                         ARR_CURR() function
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	rownum 		INTEGER,

		upd_advert 	SMALLINT,
		advert 		LIKE catalog.cat_advert,
		exit_fld	CHAR(2),
		upd_fld 	CHAR(2)

--* Make sure the advertising window, w_advert, is the current window
--*   (i.e. it is "on top" of all others). 
------------------------
  CURRENT WINDOW IS w_advert

--* Display f_catadv in the advertising window. This form has already
--*   been opened in the MAIN function.
------------------------
  DISPLAY FORM f_catadv

--* Display information describing the catalog item whose advertising
--*   copy is to be displayed.
------------------------
  DISPLAY ga_catrows[rownum].catalog_num, ga_catrows[rownum].description,
	  ga_catrows[rownum].manu_name
    TO	  catalog_num, description, manu_name

--* Initialize the input fields:
--*    advert - the current VARCHAR value for the current catalog row
--*    exit_fld and upd_fld - an underscore character
------------------------
  LET advert = ga_catadv[rownum]
  LET exit_fld = "__"
  LET upd_fld = "__"

--* Initialize upd_advert to FALSE to indicate that the user has not 
--*   chosen to save the current advertising copy
------------------------
  LET upd_advert = FALSE

  LET int_flag = FALSE
  INPUT advert, exit_fld, upd_fld WITHOUT DEFAULTS FROM cat_advert, xn, xu
    BEFORE FIELD cat_advert
--* If cursor "wraps" around to this field from the xu field, need to
--*   reset upd_advert to FALSE to indicate that the user has not
--*   chosen to save the current advertising copy
------------------------
	LET upd_advert = FALSE

    BEFORE FIELD xn
--* If cursor moves back to this field from the xu field, need to
--*   reset upd_advert to FALSE to indicate that the user has not chosen
--*   to save the current advertising copy
------------------------
	LET upd_advert = FALSE

    BEFORE FIELD xu
--* Set upd_advert to TRUE to indicate that user has entered the 
--*   "Update Copy" field.
------------------------
	LET upd_advert = TRUE

    AFTER FIELD xu
--* Create "wrap around" from the "Update Copy" field to the
--*   advertising copy
------------------------
	NEXT FIELD cat_advert

    ON KEY(CONTROL-E, ESC)
--* Define special sequences for user to exit the form
	EXIT INPUT
			
  END INPUT

--* If user wants to update field:
--*   1. do a BEGIN WORK if the database uses transactions 
------------------------
  IF upd_advert THEN 
    IF g_txflag THEN
	BEGIN WORK
    END IF

--*   2. update the cat_advert column (VARCHAR) of the current 
--*      catalog row with the new advertising copy
------------------------
WHENEVER ERROR CONTINUE
    UPDATE catalog SET cat_advert = advert
      WHERE rowid = ga_catrids[rownum]
WHENEVER ERROR STOP

--*   3. Check status of the UPDATE
    IF (status < 0) THEN
--*      3A. If UPDATE not successful, notify user
	CALL upd_err()
    ELSE

--*      3B. If UPDATE was successful, commit the transaction (if the
--*	     database uses transactions) ....
------------------------
	IF g_txflag THEN
		COMMIT WORK
	END IF
--*      ....and save new advertising copy in the ga_catadv global array
	LET ga_catadv[rownum] = advert
    END IF
  END IF

--* Return catalog window (w_cat) to the top of the screen
  CURRENT WINDOW IS w_cat

END FUNCTION  -- show_advert --

########################################
FUNCTION show_descr(rownum)
########################################
--* Purpose: Uses the w_descr window to display and update the TEXT
--*            value, catalog.cat_descr, for the current catalog row.
--*            The current row is the one that the cursor was on when
--*	       the user initiated this function. Note that if the 
--*            TEXT column is null in this row, a null will be 
--*            selected and displayed, and if the user puts in data 
--*            and updates, it will be null no more.
--* Argument(s): rownum - the index in the program array (ga_catrows)
--*	                    of the current catalog row. This value
--*	                    is sent into the function by the
--*                         ARR_CURR() function
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	rownum 		INTEGER,
		upd_descr	SMALLINT,
		exit_fld 	CHAR(2),
		upd_fld  	CHAR(2)

--* Make sure the description window, w_descr, is the current window
--*   (i.e. it is "on top" of all others). 
------------------------
  CURRENT WINDOW IS w_descr

--* Display f_catdescr in the advertising window. This form has already
--*   been opened in the MAIN function.
------------------------
  DISPLAY FORM f_catdescr

--* Display information describing the catalog item whose description
--*   is to be displayed.
------------------------
  DISPLAY ga_catrows[rownum].catalog_num, ga_catrows[rownum].description,
	  ga_catrows[rownum].manu_name
    TO	  catalog_num, description, manu_name

--* Select the TEXT value from the catalog table using the row's
--*   ROWID. Note that this function is not verifying that the
--*   ROWID still identifies the same catalog row. See Example 11
--*   for ROWID verification.
------------------------
  SELECT cat_descr 
  INTO g_txtblob 
  FROM catalog
  WHERE ROWID = ga_catrids[rownum]

  LET exit_fld = "__"
  LET upd_fld = "__"

--* Initialize upd_descr to FALSE to indicate that the user has not 
--*   chosen to save the current copy description 
------------------------
  LET upd_descr = FALSE

  LET int_flag = FALSE
  INPUT g_txtblob, exit_fld, upd_fld WITHOUT DEFAULTS FROM cat_descr, xn, xu
    BEFORE FIELD xn
--* If cursor "wraps" around to this field from the xu field, 
--*   need to reset upd_descr to FALSE to indicate that the user 
--*   has not chosen to save the current copy description
------------------------
	LET upd_descr = FALSE

    BEFORE FIELD xu
--* If cursor moves back to this field from the xu field, need to
--*   reset upd_descr to FALSE to indicate that the user has not chosen
--*   to save the current copy description
------------------------
	LET upd_descr = TRUE

    AFTER FIELD xu
--* Set upd_descr to TRUE to indicate that user has entered the 
--*   "Update Description" field.
------------------------
	NEXT FIELD cat_descr

    ON KEY(ESC,CONTROL-E)
--* Define special sequences for user to exit the form
	EXIT INPUT
  END INPUT

--* If user wants to update field:
--*   1. do a BEGIN WORK if the database uses transactions 
------------------------
  IF upd_descr THEN -- user wants to update field
	IF g_txflag THEN
		BEGIN WORK
	END IF

--*   2. update the cat_descr column (TEXT) of the current 
--*      catalog row with the new copy description
------------------------
WHENEVER ERROR CONTINUE
	UPDATE catalog SET cat_descr = g_txtblob
	  WHERE ROWID = ga_catrids[rownum]
WHENEVER ERROR STOP

--*   3. Check status of the UPDATE
    IF (status < 0) THEN
--*      3A. If UPDATE not successful, notify user
	CALL upd_err()
    ELSE
	IF g_txflag THEN
--*      3B. If UPDATE was successful, commit the transaction (if the
--*	     database uses transactions) ....
------------------------
		COMMIT WORK
	END IF
    END IF
  END IF

--* Return catalog window (w_cat) to the top of the screen
  CURRENT WINDOW IS w_cat

END FUNCTION  -- show_descr --

########################################
FUNCTION upd_err()
########################################
--* Purpose: Reports an error if one occurs during update
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends INPUT with Accept key
--*                  FALSE - if user ends INPUT with Cancel key
---------------------------------------
  DEFINE 	scode	INTEGER, 
		icode 	INTEGER

--* Save the current state code in a variable
  LET scode = SQLCA.SQLCODE
--* Save the current ISAM error in a variable
  LET icode = SQLCA.SQLERRD[2] -- isam error code

--* If the database uses transactions, roll back the current
--*   transaction
------------------------
  IF g_txflag THEN
    ROLLBACK WORK
  END IF

--* Notify user of cause of failure
  LET ga_dsplymsg[1] = "Update failed, sql code=",scode,", isam code=",icode
  LET ga_dsplymsg[2] = "Database not changed."
  CALL message_window(2,2)

END FUNCTION  -- upd_err --

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
FUNCTION message_window(x,y)
#######################################
--* Purpose: Displays a window containing user-defined text.
--*            The global array ga_dsplymsg contains this text.
--* Argument(s): x - x coordinate (column) of window's position
--*              y - y coordinate (row) of window's position
--* Return Value(s): NONE
---------------------------------------
  DEFINE numrows	SMALLINT,
	 x,y		SMALLINT,

  	 rownum,i	SMALLINT,
	 answer		CHAR(1),
	 array_sz	SMALLINT  -- size of the ga_dsplymsg array


--* The array_sz variable contains the size of the global message
--*   array, ga_dsplymsg. If the size of this array needs to be
--*   changed in the future, the developer only needs to change
--*   the value of array_sz to update the message_window() function 
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
------------------------
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      LET numrows = numrows + 1
    END IF
  END FOR

--* Open the message window at the coordinates passed in as function
--*   arguments.
------------------------
  OPEN WINDOW w_msg AT x, y
    WITH numrows ROWS, 52 COLUMNS
    ATTRIBUTE (BORDER, PROMPT LINE LAST)

  DISPLAY " APPLICATION MESSAGE" AT 1, 17
   ATTRIBUTE (REVERSE, BLUE)

  LET rownum = 3		-- * start text display at third line

--* Display non-null lines of ga_dsplymsg in the message window.
  FOR i = 1 TO array_sz
    IF ga_dsplymsg[i] IS NOT NULL THEN
      DISPLAY ga_dsplymsg[i] CLIPPED AT rownum, 2
      LET rownum = rownum + 1
    END IF
  END FOR

  PROMPT " Press RETURN to continue." FOR answer
  CLOSE WINDOW w_msg

--* Clear out ga_dsplymsg array so it is ready for the next user call
  CALL init_msgs()

END FUNCTION  -- message_window --

