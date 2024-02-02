
#######################################################################
# APPLICATION: Example 22 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex22.4gl                             FORM: none               # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of the SQLAWARN fields   #
#          when opening a database.                                   #
#                                                                     # 
# STATEMENTS:                                                         # 
#          EXECUTE IMMEDIATE                                          # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   open_db(dbname) - dynamically opens a database and saves the      #
#      the SQLAWARN fields for later use. Also determines engine lock # 
#      features.                                                      # 
#   begin_wk() - if the current db uses transactions and is not       #
#      ANSI-compliant, executes the BEGIN WORK statement.             # 
#   commit_wk() - if the current db uses transactions, executes the   # 
#      COMMIT WORK statement.                                         # 
#   rollback_wk() - if the current db uses transactions, executes the #
#      ROLLBACK WORK statement.                                       #
#                                                                     # 
#                                                                     # 
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/10/91    dec             Created Example 22                     #
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

END GLOBALS

########################################
MAIN
########################################
  DEFINE 	db 	CHAR(50), 
		ret 	INTEGER

  DISPLAY "Example 22, testing open_db function." AT 1,1
  OPTIONS 
    PROMPT LINE 3

--* Prompt user for db name
  PROMPT "Enter name of database to try: " FOR db

--* Open database. This function fills the global record
--*   gr_database with info about the database
------------------------
  IF open_db(db) THEN
    DISPLAY "Database is open."
    IF gr_database.is_online THEN
	DISPLAY "The engine is IBM Informix-OnLine."
	DISPLAY "It supports SET LOCK MODE TO WAIT [n]"
    ELSE
	DISPLAY "The engine is IBM Informix-SE."
	IF gr_database.can_wait THEN
	    DISPLAY "It supports SET LOCK MODE TO WAIT."
	ELSE
	    DISPLAY "It does not support SET LOCK MODE."
	END IF
    END IF
    IF gr_database.is_ansi THEN
	DISPLAY "The database is ANSI-compliant, that is,"
	IF gr_database.is_online THEN
	    DISPLAY " it was created with LOG MODE ANSI."
	ELSE
	    DISPLAY " START DATABASE...MODE ANSI was used on it."
	END IF
	DISPLAY "A transaction is always in effect; COMMIT WORK ends."
    ELSE
	DISPLAY "The database uses Informix extensions to ANSI SQL."
	IF gr_database.has_log THEN
	    DISPLAY "It has a transaction log; BEGIN/COMMIT WORK used."
	ELSE
	    DISPLAY "The database does not have a transaction log."
	END IF
    END IF
  ELSE -- error opening db?
    DISPLAY "Database did not open correctly." AT 4,1
    SLEEP 10 -- leave error message visible before program end
  END IF
END MAIN

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

