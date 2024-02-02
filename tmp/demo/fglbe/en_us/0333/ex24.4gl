
#######################################################################
# APPLICATION: Example 24 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex24.4gl                         FORM: none                   #
#                                        ASSOCIATED FILES: ex24.unl   #
#                                                                     # 
# PURPOSE: This program demonstrates the design of a batch-oriented,  #
#          as opposed to interactive, program; and the use of an      #
#          update journal table to defer updates to off-peak hours;   #
#          and the use of a cursor WITH HOLD, that is, a cursor that  #
#          remains open across transaction boundaries.                #
#                                                                     # 
#          In order to preserve the original state of the example     #
#          database, the MAIN program saves the ORDERS table contents #
#          over the run of the program.  It creates an example of an  # 
#          update journal on the fly from an unload file.             # 
#                                                                     # 
# STATEMENTS:                                                         # 
#          RENAME TABLE     CREATE TEMP TABLE   DROP TABLE            # 
#          LOAD             DECLARE...WITH HOLD                       # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   update_driver(rep) - the "main" logic of the simulated batch      #
#      application: reads rows from the update journal, validates     #
#      them, and applies them.                                        #
#   like(a,b) -  compares two values either of which might be null,   #
#               returning TRUE if they are equal or equally null      #
#   upd_rep(f,v1,v2,x) - report function for the update process,      #
#      documents each update as it is applied (or not applied).       # 
#   save_orders() - saves the orders table if it has not already been #
#      saved.                                                         #
#   build_journal() - creates and populates a simulated update-journal#
#      table from the file ex24.unl, distributed with the program.    #
#      This function also contains the schema of the upd_journal      #
#      table.                                                         #
#   restore_orders() - restores the orders table to its state before  #
#      Example 24 ran. Uses qsave_orders to restore the table.        #
#   save_journal() - saves the contents of the update journal table   #
#      (upd_journal) in the file ex24.out before dropping this table. #
#   open_db(dbname) - see description in ex24.4gl file.               #
#   check_db_priv(wanted) - checks that the user has a specified level#
#      of database privilege.                                         #
#   begin_wk() - see description in ex24.4gl file.                    #
#   commit_wk() - see description in ex24.4gl file.                   #
#   rollback_wk() - see description in ex24.4gl file.                 #
#                                                                     # 
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  04/17/91    dam             Moved BEGIN WORK and enhanced report   #
#                                 output.                             #
#  02/14/91    dam             Updated file header                    #
#  02/09/91    dec             Created Example 24                     #
#######################################################################

DATABASE stores2

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

END GLOBALS

DEFINE	jrn RECORD
		journal_id   INTEGER,
		upd_status   CHAR(1),
		order_num    INTEGER,
		entered_by   CHAR(8),
		enter_date   DATETIME YEAR TO SECOND
	    END RECORD,
	ver, 			    -- table values BEFORE update
	set, 			    -- new updated table values
	cur RECORD LIKE orders.*    -- table values currently in db

########################################
MAIN
########################################
  DEFINE	reppath 	CHAR(80),
		dbname 		CHAR(10),
		valid_db	SMALLINT

    DEFER INTERRUPT

    LET valid_db = FALSE

--* Accept the name of the database to use
    DISPLAY "Enter the name of the example database, or simply press"
    LET int_flag = FALSE
    PROMPT  "RETURN to use 'stores2': " FOR dbname

    IF int_flag THEN
      LET int_flag = FALSE
    ELSE
--* If user pressed RETURN, use stores2 as database name
      IF LENGTH(dbname) = 0 THEN 
        LET dbname = "stores2" 
      END IF
--* Attempt to open specified database
      IF open_db(dbname) THEN
        IF NOT check_db_priv("R") THEN
          DISPLAY "Sorry, you must have at least Resource privilege"
	  DISPLAY "in that database for this example to work."
	  DISPLAY "Run the program again with a different database."
        ELSE
	  LET valid_db = TRUE
        END IF
      END IF
    END IF

--* Continue only if have opened specified database and have 
--*   correct permissions on this database.
------------------------
    IF valid_db THEN
      CALL save_orders()	-- save contents of orders table
      IF build_journal() THEN	-- create the upd_journal

        DISPLAY ""
        DISPLAY "Enter a pathname to receive the update report output."
        DISPLAY "For output to the screen, just press RETURN."
	LET int_flag = FALSE
        PROMPT "Report pathname or null: " FOR reppath

        IF int_flag THEN
	  LET int_flag = FALSE
	ELSE
--* Call the report driver to perform the updates indicated
--*   the batch update records (in upd_journal table).
          CALL update_driver(reppath)	-- run the real example
          CALL restore_orders() 	-- fix updated orders table
	END IF
	
--* Save upd_journal rows in the ex24.out file so user can look at
--*   them when program ends. The upd_journal table is removed at
--*   the end of the program.
	CALL save_journal()
	
      END IF
      DROP TABLE qsave_orders
    END IF

END MAIN

########################################
FUNCTION update_driver(rep)
########################################
--* Purpose: Processes the order updates stored in the batch update
--*            table, upd_journal. Each upd_journal row contains
--*	       updates for a particular orders row. As it performs
--*            these updates, the function sends messages to a
--*            report indicating how the updates went. 
--* Argument(s): rep - the pathname of the file in which to save report
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	rep 		CHAR(80),

		oops, num 	SMALLINT

--* If no report name specified, send report output to screen
    IF LENGTH(rep) = 0 THEN
	START REPORT upd_rep
    ELSE
--* If report name specified, send report output to this file
	START REPORT upd_rep TO rep
    END IF

--* The jrnlupd cursor will contain the batch update rows
--*   from upd_journal. This cursor is a WITH HOLD update cursor.
--*   The WITH HOLD ensures that individual orders and upd_journal
--*   rows can be updated and the transaction ended (committed or 
--*   rolled back) without having this cursor closed. If this 
--*   cursor was not declared as WITH HOLD, ending a transaction 
--*   would cause it to close.
------------------------
    DECLARE jrnlupd CURSOR WITH HOLD FOR
      SELECT * INTO jrn.*,
		  ver.ship_instruct THRU ver.paid_date,
		  set.ship_instruct THRU set.paid_date
      FROM upd_journal
      WHERE upd_status = "N"
    FOR UPDATE

--* The ordupd cursor will contain the orders row to be updated
--*   with the information in a upd_journal batch update row.
--*   This is an update cursor so that the orders row will be
--*   locked and therefore not updated by any other process.
--*   This cursor is closed when the transaction is ended (committed
--*   or updated).
------------------------
    DECLARE ordupd CURSOR FOR
      SELECT * INTO cur.* FROM orders
      WHERE order_num = jrn.order_num
    FOR UPDATE

--* If the database uses transactions (and is not ANSI-compliant),
--*   perform a BEGIN WORK.
------------------------
    CALL begin_wk()

--* Open and fetch a batch update row into the jrn, ver, and set records
    FOREACH jrnlupd
--* Open and fetch the associated orders row into the cur record
	OPEN ordupd
	FETCH ordupd

	LET oops = SQLCA.SQLCODE
	IF oops = 0 THEN
	    LET num = 0
	ELSE
	    OUTPUT TO REPORT upd_rep(" "," "," ","order_num not found")
	END IF

--* If the FETCH was successful and the batch update changed the
--*   value of the ship_instruct column (value BEFORE the journal 
--*   update (in ver) differs from value after this update (in set)
--* AND....
------------------------
	IF oops = 0 AND NOT like(ver.ship_instruct,set.ship_instruct) THEN

--* ... the value currently in the orders row (in cur) still 
--*   matches the value BEFORE the journal update (in ver), then
--*   this column needs to be updated. 
------------------------
	    IF like(ver.ship_instruct,cur.ship_instruct) THEN

--* Put the new ship_instruct value into the cur record and
--*   send a message to the report.
------------------------
		LET cur.ship_instruct = set.ship_instruct
		LET num = num+1
		OUTPUT TO REPORT upd_rep("ship_instruct",
					ver.ship_instruct,
					set.ship_instruct,
					" ")
	    ELSE
--* The orders row has been modified since the update journal
--*   saved its values. Don't do the update to the orders row.
------------------------
		LET oops = 1
		OUTPUT TO REPORT upd_rep("ship_instruct",
					ver.ship_instruct,
					cur.ship_instruct,
					"no match: orig & current")
	    END IF
	END IF

--* If the orders row has not been modified since the update
--*   journal saved its values and the batch update changed the
--*   value of the backlog column (value BEFORE the journal 
--*   update (in ver) differs from value after this update (in set)
--* AND....
------------------------
	IF oops = 0 AND NOT like(ver.backlog,set.backlog) THEN

--* ... the value currently in the orders row (in cur) still 
--*   matches the value BEFORE the journal update (in ver), then
--*   this column needs to be updated. 
------------------------
	    IF like(ver.backlog,cur.backlog) THEN

--* Make sure that the new backup is valid and, if so, then
--*   put the new ship_instruct value into the cur record and
--*   send a message to the report.
------------------------
		IF set.backlog MATCHES "[yn]" THEN
		    LET cur.backlog = set.backlog
		    LET num = num+1
		    OUTPUT TO REPORT upd_rep("backlog",
					    ver.backlog,
					    set.backlog,
					    " ")
		ELSE

--* The new backup value in the update journal is not valid.
		    LET oops = 1
		    OUTPUT TO REPORT upd_rep("backlog"," ",
					    set.backlog,
					    "improper value for field")
		END IF
	    ELSE

--* The orders row has been modified since the update journal
--*   saved its values. Don't do the update to the orders row.
------------------------
		LET oops = 1
		OUTPUT TO REPORT upd_rep("backlog",
					ver.backlog,
					cur.backlog,
					"no match: orig & current")
	    END IF
	END IF

--* The same procedure followed for the backup column is repeated
--*   for the po_num column. See the comments for the backup column.
------------------------
	IF oops = 0 AND NOT like(ver.po_num,set.po_num) THEN
	    IF like(ver.po_num,cur.po_num) THEN
		LET cur.po_num = set.po_num
		LET num = num+1
		OUTPUT TO REPORT upd_rep("po_num",
					ver.po_num,
					set.po_num,
					" ")
	    ELSE
		LET oops = 1
		OUTPUT TO REPORT upd_rep("po_num",
					ver.po_num,
					cur.po_num,
					"no match: orig & current")
	    END IF
	END IF

--* The same procedure followed for the backup column is repeated
--*   for the ship_date column. See the comments for the backup column.
------------------------
	IF oops = 0 AND NOT like(ver.ship_date,set.ship_date) THEN
	    IF like(ver.ship_date,cur.ship_date) THEN
		LET cur.ship_date = set.ship_date
		LET num = num+1
		OUTPUT TO REPORT upd_rep("ship_date",
					ver.ship_date,
					set.ship_date,
					" ")
	    ELSE
		LET oops = 1
		OUTPUT TO REPORT upd_rep("ship_date",
					ver.ship_date,
					cur.ship_date,
					"no match: orig & current")
	    END IF
	END IF

--* The same procedure followed for the backup column is repeated
--*   for the ship_weight column. See the comments for the backup column.
------------------------
	IF oops = 0 AND NOT like(ver.ship_weight,set.ship_weight) THEN
	    IF like(ver.ship_weight,cur.ship_weight) THEN
		LET cur.ship_weight = set.ship_weight
		LET num = num+1
		OUTPUT TO REPORT upd_rep("ship_weight",
					ver.ship_weight,
					set.ship_weight,
					" ")
	    ELSE
		LET oops = 1
		OUTPUT TO REPORT upd_rep("ship_weight",
					ver.ship_weight,
					cur.ship_weight,
					"no match: orig & current")
	    END IF
	END IF
	IF oops = 0 AND NOT like(ver.ship_charge,set.ship_charge) THEN
	    IF like(ver.ship_charge,cur.ship_charge) THEN
		LET cur.ship_charge = set.ship_charge
		LET num = num+1
		OUTPUT TO REPORT upd_rep("ship_charge",
					ver.ship_charge,
					set.ship_charge,
					" ")
	    ELSE
		LET oops = 1
		OUTPUT TO REPORT upd_rep("ship_charge",
					ver.ship_charge,
					cur.ship_charge,
					"no match: orig & current")
	    END IF
	END IF

--* The same procedure followed for the backup column is repeated
--*   for the paid_date column. See the comments for the backup column.
------------------------
	IF oops = 0 AND NOT like(ver.paid_date,set.paid_date) THEN
	    IF like(ver.paid_date,cur.paid_date) THEN
		LET cur.paid_date = set.paid_date
		LET num = num+1
		OUTPUT TO REPORT upd_rep("paid_date",
					ver.paid_date,
					set.paid_date,
					" ")
	    ELSE
		LET oops = 1
		OUTPUT TO REPORT upd_rep("paid_date",
					ver.paid_date,
					cur.paid_date,
					"no match: orig & current")
	    END IF
	END IF

--* If the orders row has not been modified since the update journal
--*   saved its values, can update the row. The cur record contains
--*   the new values. 
------------------------
	IF oops = 0 THEN
	    IF num > 0 THEN
WHENEVER ERROR CONTINUE
		UPDATE orders SET (ship_instruct,backlog,
		    po_num,ship_date,ship_weight,ship_charge,paid_date)
		    = (cur.ship_instruct THRU cur.paid_date)
		    WHERE CURRENT OF ordupd
WHENEVER ERROR STOP
		IF status < 0 THEN
		  OUTPUT TO REPORT upd_rep("orders table not updated",
			" "," ",status)
		  LET oops = 1
		ELSE

--* Also need to update the upd_journal row to indicate that
--*   its updates have been performed on the orders table.
------------------------
WHENEVER ERROR CONTINUE
		  UPDATE upd_journal SET upd_status = "D"
		    WHERE CURRENT OF jrnlupd
WHENEVER ERROR STOP
		  IF status < 0 THEN
		    OUTPUT TO REPORT upd_rep("upd_journal not updated",
			" "," ",status)
		    LET oops = 1
		  ELSE
		    OUTPUT TO REPORT upd_rep(" ",
			" "," ","orders table updated ")
  		  END IF
		END IF 
	    ELSE
		OUTPUT TO REPORT upd_rep(" "," "," ","no changed fields ")
		LET oops = 1
	    END IF
	END IF

--* Need to end the current transaction. If the orders and 
--*   upd_journal row was successfully updated, commit the current 
--*   transactions. If not, roll back this transaction. The inner
--*   cursor (ordupd) is closed but the outer cursor (jrnlupd) remains
--*   open because it is declared as a WITH HOLD cursor.
------------------------
	IF oops = 0 THEN
	    CALL commit_wk()
	ELSE
	    CALL rollback_wk()
	END IF

--* Begin transaction for next fetched row. Since the cursors
--*   are both update cursors, they need to lock the fetched
--*   row and a lock can only be obtained within a transaction.
------------------------
	CALL begin_wk()		

    END FOREACH

--* End the transaction begun at the end of the FOREACH loop (if
--*   rows found) or before the FOREACH loop (if no rows found).
------------------------
    IF oops = 0 THEN
        CALL commit_wk()
    ELSE
        CALL rollback_wk()
    END IF

    FINISH REPORT upd_rep

END FUNCTION  -- update_driver --

########################################
REPORT upd_rep(f,v1,v2,x)
########################################
--* Purpose: Report function to create the journal of batch
--*            updates.
--* Argument(s): f - column being updated
--*			OR
--*                  status message to print
--*              v1 - value of column BEFORE update
--*			OR
--*                   NULL (if status message)
--*              v2 - value of column AFTER update
--*			OR
--*                   NULL (if status message)
--*              x - optional comment
--*			OR
--*                  status value (if status message)
--* Return Value(s): NONE
---------------------------------------
  DEFINE f,v1,v2,x 	CHAR(25), 

	 prev_upd 	INTEGER

    OUTPUT
      LEFT MARGIN 0

    FORMAT
      FIRST PAGE HEADER
	PRINT 20 SPACES, "UPDATE JOURNAL REPORT"
	PRINT 20 SPACES, "Run on: ", TODAY
	LET prev_upd = 0

      ON EVERY ROW
--* If the id of the current upd_journal row has changed,
--*   print out new header for new row
------------------------
	IF jrn.journal_id <> prev_upd THEN
	    LET prev_upd = jrn.journal_id
	    PRINT
	    PRINT 2 SPACES, "UPDATE ", 
		jrn.journal_id USING "####",
		" against Order ",
		jrn.order_num USING "#####"
	    PRINT 4 SPACES, "Entered by ",
		jrn.entered_by,
		" on ", jrn.enter_date
	END IF

	PRINT 6 SPACES, f;

--* If value for v1 provided, print out original column value
        IF v1[1] = " " THEN
	    PRINT " ";
	ELSE
	    PRINT 1 SPACE, "BEFORE: ";
	    IF v1 IS NULL THEN
	      PRINT "(null)"
	    ELSE
	      PRINT v1
	    END IF
	END IF

        PRINT 32 SPACES;
--* If value for v2 provided, print out new column value
        IF v2[1] = " " THEN
	    PRINT " "
	ELSE
	    PRINT "AFTER: "; 
	    IF v2 IS NULL THEN
	      PRINT "(null)"
	    ELSE
	      PRINT v2
	    END IF
	END IF

        PRINT 6 SPACES;
--* If value for x provided, print out additional message 
        IF x[1] = " " THEN
	    PRINT " "
	ELSE
	    PRINT "STATUS: ", x CLIPPED
	END IF
	SKIP 1 LINE

END REPORT  -- upd_rep --
		
########################################
FUNCTION save_orders()
########################################
--* Purpose: Preserves the contents of the original orders table 
--*            from the example database by selecting into another 
--*            table.  The table cannot be a temp because if the 
--*            program crashed after making some updates, the temp
--*            would be lost.  The user would have to rebuild the 
--*            whole database to restore orders.  When qsave_orders 
--*            is permanent, rerunning the program might produce 
--*            some error diagnostics in the update report, but at 
--*            the end, the orders table would be restored.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE j SMALLINT

--* If the qsave_orders table does not currently exist,
--*   create it and load it with the contents of the
--*   orders table. 
------------------------
  SELECT COUNT(*) 
  INTO j 
  FROM informix.systables
  WHERE tabname = "qsave_orders"

  IF j = 0 THEN	-- the table has not yet been saved
	CREATE TABLE qsave_orders (order_num INTEGER, order_date DATE,
	                           customer_num INTEGER, ship_instruct CHAR(40),
                                   backlog CHAR(1), po_num CHAR(10), 
                                   ship_date DATE, ship_weight DECIMAL(8,2),
      	                           ship_charge MONEY(6), paid_date DATE)
	INSERT INTO qsave_orders SELECT * FROM orders
	DISPLAY "Contents of orders table saved in temp table: qsave_orders."
  ELSE
	DISPLAY "Copy of orders table ('qsave_orders') exists."
  END IF

END FUNCTION  -- save_orders --

########################################
FUNCTION restore_orders()
########################################
--* Purpose: Restores the contents of the original orders table 
--*            from the save table, qsave_orders.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

    DELETE FROM orders 
    WHERE order_num IN
	(SELECT DISTINCT order_num FROM upd_journal)

    INSERT INTO orders
	SELECT * FROM qsave_orders 
        WHERE order_num IN
	    (SELECT DISTINCT order_num FROM upd_journal)

END FUNCTION -- restore_orders --

########################################
FUNCTION build_journal()
########################################
--* Purpose: Builds the update journal table and loads it with the
--*            the set of example update requests saved in a LOAD 
--*            file named ex24.unl.  This program updates the orders
--*            table from this table of update requests.  
--* Argument(s): NONE
--* Return Value(s): TRUE - if user ends PROMPT with Accept or RETURN
--*                         key
--*                  FALSE - if user ends PROMPT with Cancel key
---------------------------------------
  DEFINE 	fpath, afile 	CHAR(80),
    		j 		SMALLINT

--* If the upd_journal table does not currently exist,
--*   create it and load it with the contents of the
--*   ex24.unl file. 
------------------------
    SELECT COUNT(*) 
    INTO j 
    FROM informix.systables
    WHERE tabname = "upd_journal"

    IF j <> 0 THEN	-- one exists, may be updated, drop it
	DROP TABLE upd_journal
    END IF
    CREATE TABLE upd_journal (
	-- these columns describe the update operation
	journal_id SERIAL,	-- unique id of update item
	upd_status CHAR(1),	-- N=new, X=error, A=applied
	order_num  INTEGER,	-- foreign key to orders
	entered_by CHAR(8),	-- user who entered update
	enter_date DATETIME YEAR TO SECOND, -- ...and when
	-- these columns show the contents of the row prior to update
	-- they are grouped so they can be read into a record LIKE orders
	org_si     CHAR(40),	-- org_si = original_ship_instruct
	org_bl     CHAR(1),	-- backlog
	org_po     CHAR(10),	-- po_num
	org_sd     DATE,	-- ship_date
	org_sw     DECIMAL(8,2), -- ship_weight
	org_sc     MONEY(6),	-- ship_charge
	org_pd     DATE,	-- paid_date
	-- these columns are the desired contents post-update
	upd_si     CHAR(40),	-- upd_si = update_ship_instruct
	upd_bl     CHAR(1),	-- backlog
	upd_po     CHAR(10),	-- po_num
	upd_sd     DATE,	-- ship_date
	upd_sw     DECIMAL(8,2), -- ship_weight
	upd_sc     MONEY(6),	-- ship_charge
	upd_pd     DATE		-- paid_date
	)

    DISPLAY "Simulated update journal table upd_journal created."
    DISPLAY ""
    DISPLAY "To load the simulated update journal we need a file pathname"
    DISPLAY "for the file ex24.unl ."
    DISPLAY "It came in the same directory as the source file of this program."
    DISPLAY ""
    DISPLAY "Enter a pathname, including the final slash (or backslash)."
    DISPLAY "For the current working directory just press RETURN."
    DISPLAY ""

--* Prompt user for directory where load file exists
    LET int_flag = FALSE
    PROMPT  "Path to ex24.unl file: " FOR fpath
    IF int_flag THEN
      RETURN (FALSE)
    END IF

--* Build name of load file
    LET afile = fpath CLIPPED, "ex24.unl"
    DISPLAY "Loading from ",afile CLIPPED
--* Load upd_journal table from this file
    LOAD FROM afile INSERT INTO upd_journal
    DISPLAY "Update journal table loaded."
    DISPLAY ""

    RETURN (TRUE)

END FUNCTION  -- build_journal --

########################################
FUNCTION save_journal()
########################################
--* Purpose: Saves contents of upd_journal table in the
--*            file "ex24.out" so that user can look at the state of
--*            this table after the program exits. Once contents
--*            saved, the function drops the upd_journal table so that
--*            the database returns to its original structure.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

  UNLOAD TO "ex24.out" SELECT * FROM upd_journal
  IF status < 0 THEN
    DISPLAY "Unable to store contents of journal table in ex24.out file."
  ELSE
    DISPLAY "New contents of journal table stored in ex24.out file."
    DROP TABLE upd_journal
    IF status < 0 THEN
        DISPLAY "Unable to drop journal table."
    END IF
  END IF

  DISPLAY "Dropped journal table: upd_journal."

END FUNCTION  -- save_journal --

########################################
FUNCTION like(a,b)
########################################
--* Purpose: Compares two strings for equality. Two NULL
--*            strings are considered equal.
--* Argument(s): a - one string to compare
--*              b - second string to compare
--* Return Value(s): TRUE - if two strings are equal
--*                  FALSE - if two strings are not equal
---------------------------------------
  DEFINE a,b 	CHAR(255)

    IF (a IS NULL) AND (b IS NULL) THEN
	RETURN TRUE
    ELSE
	IF a = b THEN
	    RETURN TRUE
	ELSE
	    RETURN FALSE
	END IF
    END IF
END FUNCTION  -- like --

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

###########################################
FUNCTION check_db_priv(wanted)
###########################################
  DEFINE	wanted 		CHAR(1),

  		actual  	CHAR(1),
    		retcode 	SMALLINT

    LET retcode = FALSE	-- assume failure
WHENEVER ERROR CONTINUE -- no need to crash program on error here
    LET actual = "?"	-- ..just make sure we have usable data

    DECLARE dbgrant CURSOR FOR
	SELECT usertype INTO actual 
	FROM informix.sysusers
	WHERE username = USER
	  OR username = "public" -- alway lowercase

    FOREACH dbgrant
	CASE wanted
	  WHEN "C"
	    IF actual <> "?" THEN
		LET retcode = TRUE	-- any privilege includes "C"
	    END IF
	  WHEN "R"
	    IF actual <> "C" AND actual <> "?" THEN
		LET retcode = TRUE	-- "D" or "R" is ok for "R"
	    END IF
	  WHEN "D"
	    IF actual = "D" THEN
		LET retcode = TRUE	-- the only real "D" is "D"
	    END IF
	END CASE

        IF retcode THEN 
	  EXIT FOREACH 
	END IF
    END FOREACH

    FREE dbgrant
    RETURN retcode
WHENEVER ERROR STOP

END FUNCTION  -- check_db_priv --

########################################
FUNCTION begin_wk()
########################################
--* Purpose: Executes the BEGIN WORK statement to start a transaction
--*            but only if the current database supports transactions 
--*            and is not ANSI-compliant. (An ANSI-compliant database 
--*            uses transactions but does not use BEGIN WORK.)
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database is NOT 
--*   ANSI-compliant and it uses transactions, then do a BEGIN
--*   WORK.
------------------------
    IF gr_database.db_known
      AND NOT gr_database.is_ansi
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	BEGIN WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on BEGIN WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- begin_wk --

########################################
FUNCTION commit_wk()
########################################
--* Purpose: Executes the COMMIT WORK statement to end a transaction
--*            but only if the current database supports transactions.
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database 
--*   uses transactions, then do a COMMIT WORK.
------------------------
    IF  gr_database.db_known
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	COMMIT WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on COMMIT WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- commit_wk --

########################################
FUNCTION rollback_wk()
########################################
--* Purpose: Executes the ROLLBACK WORK statement to end a transaction
--*            but only if the current database supports transactions. 
--*
--*          This function uses the global record gr_database, which 
--*          must have been initialized by calling open_db() before 
--*          calling this function.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------

--* If the database record is filled in and the database 
--*   uses transactions, then do a ROLLBACK WORK.
------------------------
    IF  gr_database.db_known
      AND gr_database.has_log 
    THEN

WHENEVER ERROR CONTINUE
	ROLLBACK WORK
	IF SQLCA.SQLCODE <> 0 THEN
	    ERROR "Error ", SQLCA.SQLCODE,
		" on ROLLBACK WORK (isam #", SQLCA.SQLERRD[2], ")"
	END IF
WHENEVER ERROR STOP

    END IF

END FUNCTION  -- rollback_wk --


