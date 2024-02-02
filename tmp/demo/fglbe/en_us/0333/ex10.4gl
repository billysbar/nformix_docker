
#######################################################################
# APPLICATION: Example 10 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex10.4gl                            FORM: f_manuf.per         # 
#                                                                     # 
# PURPOSE: This program illustrates how to perform inserts, updates,  #
#          and deletes on items within a multi-row form. It uses the  #
#          array ga_mrowid to track the operations performed by the   #
#          user to items in the program array: ga_manuf. The ga_mrowid#
#          array stores the rowid and an operation flag for each item #
#          in the program array. This operation flag has two possible #
#          values: "U" - when an existing entry is updated, and "I"   #
#          when an entry is added. When an item is deleted, its rowid #
#          and manufacturer code are stored in a second global array: #
#          ga_drows. Once the user has completed all edits to the     #
#          manufacturers, the program then performs the required data-#
#          base operations by checking the operation flag (in         #
#          ga_mrowid)of each entry in the program array and the       #
#          ga_drows array for entries that have been deleted.         #
#                                                                     # 
# STATEMENTS:                                                         #
#             INPUT ARRAY                                             #
#                                                                     # 
# FUNCTIONS:                                                          #
#   dsply_manuf() - displays the f_manuf form and controls the array  #
#      editing.                                                       #
#   valid_null(array_idx, array_size) - checks to see if the current  #
#      key stroke is valid when the manu_code field is NULL (empty).  #
#   reshuffle(direction) - reshuffles the ga_mrowid array when an     #
#      item is added to (direction="I") or deleted from               #
#      (direction="D") the program array ga_manuf.                    #
#   verify_mdel(del_idx) - verifies that the manufacturer to be       #
#      deleted does not currently have items in the stock table.      #
#   choose_op() - checks the operation flag (op_flag) in the          #
#      ga_mrowid array for the updates and inserts to perform. Also   #
#      checks the ga_drows for the deletes to perform.                #
#   insert_manuf(array_idx) - adds a manufact row to database.        #
#   update_manuf(array_idx) - updates an existing manufact row.       #
#   delete_manuf(del_idx) - deletes an existing manufact row.         #
#   verify_rowid(mrowid,code_in_mem) - verifies that the rowid of the #
#      row to be updated or deleted has not been deleted by another   #
#      user.                                                          #
#   save_rowid(mrowid, mcode) - saves the "mrowid" rowid and the      #
#      "mcode" manufacturer code of the row to be deleted in the      #
#      ga_drows array (before this info is deleted when the ga_mrowid #
#      array is reshuffled).                                          #
#   msg(str) - see description in ex5.4gl file.                       #
#   init_msgs() - see description in ex2.4gl file.                    #
#   message_window(x,y) - see description in ex2.4gl file.            #
#   prompt_window(question,x,y) - see description in ex4.4gl file.    #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/14/91    dam             Created ex10.4gl file                  #
#######################################################################

DATABASE stores2

GLOBALS
  DEFINE	ga_manuf 	ARRAY[50] OF 
				  RECORD 
				    manu_code LIKE manufact.manu_code,
				    manu_name LIKE manufact.manu_name,
				    lead_time LIKE manufact.lead_time
				  END RECORD,

		ga_mrowid 	ARRAY[50] OF 
				  RECORD
				    mrowid	INTEGER,
				    op_flag	CHAR(1)
				  END RECORD,

		ga_drows	ARRAY[50] OF 
				  RECORD
				    mrowid	INTEGER,
				    manu_code	LIKE manufact.manu_code
				  END RECORD,
		g_idx		SMALLINT

# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)

END GLOBALS

########################################
MAIN
########################################

--* Set form line to start at 4th line of window. Set Message and
--*   Comment lines to work with f_manuf form. Redefine the Insert and
--*   Delete keys.
------------------------
  OPTIONS
      FORM LINE 4,
      MESSAGE LINE LAST,
      COMMENT LINE 2,
      INSERT KEY CONTROL-E,
      DELETE KEY CONTROL-T 
	      
  DEFER INTERRUPT

--* Display all manufact rows on f_manuf form. If user modifies this
--*   data, call choose_op() to determine what database operations
--*   need to be performed. 
------------------------
  IF dsply_manuf() THEN
    CALL choose_op()
    CALL msg("Manufacturer maintenance complete.")
  END IF

END MAIN

########################################
FUNCTION dsply_manuf()
########################################
--* Purpose: Displays contents of the manufact table on the f_manuf
--*            form. 
--* Argument(s): NONE
--* Return Value(s): TRUE - user has confirmed edits to manufact rows
--*                  FALSE - user has pressed Cancel key or has not
--*                          confirmed edits
---------------------------------------
  DEFINE	idx		SMALLINT,
		curr_pa		SMALLINT,
		curr_sa		SMALLINT,
		total_pa	SMALLINT,
		manuf_cnt	SMALLINT,

		pr_nullman	RECORD
			  	  manu_code 	LIKE manufact.manu_code,
			  	  manu_name 	LIKE manufact.manu_name,
			  	  lead_time 	LIKE manufact.lead_time
				END RECORD,

		pr_workman	RECORD
			  	  manu_code 	LIKE manufact.manu_code,
			  	  manu_name 	LIKE manufact.manu_name,
			  	  lead_time 	LIKE manufact.lead_time
				END RECORD

  INITIALIZE pr_nullman.* TO NULL

  OPEN WINDOW w_manufs AT 4,5
    WITH 13 ROWS, 67 COLUMNS
    ATTRIBUTE (BORDER)

  OPEN FORM f_manuf FROM "f_manuf"
  DISPLAY FORM f_manuf

  DISPLAY " Press Accept to save manufacturers, Cancel to exit w/out saving."
    AT 1, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY " Press CTRL-E to insert a line, CTRL-T to delete a line."
    AT 13, 1 ATTRIBUTE (REVERSE, YELLOW)
  DISPLAY "MANUFACTURER MAINTENANCE"
    AT 3, 15

--* c_manufs cursor will contain all manufact rows, ordered by code.
--*  Also contains the internal ROWID for each row.
------------------------
  DECLARE c_manufs CURSOR FOR
    SELECT ROWID, manu_code, manu_name, lead_time FROM manufact
    ORDER BY manu_code

  LET idx = 1

--* Read manufact ROWIDs into the ga_mrowid global array and the
--*   column data into the ga_manuf global array
------------------------
  FOREACH c_manufs INTO ga_mrowid[idx].mrowid, ga_manuf[idx].*
    LET idx = idx + 1
  END FOREACH

--* If not manufact rows exist, initialize ga_manuf to NULL
  IF idx = 1 THEN
    LET ga_manuf[1].* = pr_nullman.*
  END IF

--* Initialize size of program array so ARR_COUNT() can track it
  CALL SET_COUNT(idx - 1)

--* Display contents of ga_manuf program array in sa_manuf screen
--*   array (the screen array is defined within the f_manuf form)
------------------------
  INPUT ARRAY ga_manuf WITHOUT DEFAULTS FROM sa_manuf.*
    BEFORE ROW -- executed before cursor stops on a new line
      LET curr_pa = ARR_CURR()  -- current index in program array
      LET curr_sa = SCR_LINE()  -- current index in screen array
      LET total_pa = ARR_COUNT() -- total number in program array
      LET pr_workman.* = ga_manuf[curr_pa].*

--* Executed after user presses Insert key and before 4GL inserts new
--*   line into arrays
------------------------
    BEFORE INSERT 
      LET pr_workman.* = pr_nullman.*	-- clear out work buffer

--* Executed after user presses Delete key and before 4GL deletes 
--*   current line in arrays
------------------------
    BEFORE DELETE
--* 1. save the rowid of the row to delete
      CALL save_rowid(ga_mrowid[curr_pa].mrowid,
		ga_manuf[curr_pa].manu_code)

--* 2. remove the deleted row from the rowid array
      CALL reshuffle("D")

--* 3. clear out the contents of the work buffer
      LET pr_workman.* = ga_manuf[curr_pa].*

    BEFORE FIELD manu_code
--* Save original value of manu_code in work buffer
      LET pr_workman.manu_code = ga_manuf[curr_pa].manu_code

    AFTER FIELD manu_code
--* If user didn't enter a manu_code, need to determine whether
--*  an empty field is valid. If not, notify user and prevent
--*  cursor from leaving field.
------------------------
      IF (ga_manuf[curr_pa].manu_code IS NULL) THEN
	IF NOT valid_null(curr_pa, total_pa) THEN
	  ERROR "You must enter a manufacturer code. Please try again."
	  LET ga_manuf[curr_pa].manu_code = pr_workman.manu_code
	  NEXT FIELD manu_code
        END IF
      END IF

--* If doing an Insert, need to verify code is unique
      IF (pr_workman.manu_code IS NULL)
	  AND (ga_manuf[curr_pa].manu_code IS NOT NULL)
      THEN
	SELECT COUNT(*)
	INTO manuf_cnt
	FROM manufact
	WHERE manu_code = ga_manuf[curr_pa].manu_code

	IF manuf_cnt > 0 THEN
	  ERROR 
  "This manufacturer code already exists. Please choose another code."
	  LET ga_manuf[curr_pa].manu_code = NULL
	  NEXT FIELD manu_code
	ELSE				--* no manufs exist with new code

--* If not on the last line of program array, clear a line for the
--*  new manufacturer in the ga_mrowid array.
------------------------
	  IF curr_pa <> total_pa THEN
	    CALL reshuffle("I")
	  END IF

	  LET ga_mrowid[curr_pa].op_flag = "I"	--* mark the line as new
	END IF

--* If doing an Update, notify user that field cannot be modified
      ELSE
	IF (ga_manuf[curr_pa].manu_code <> pr_workman.manu_code) THEN
	  LET ga_dsplymsg[1] = "You cannot modify the manufacturer code."
	  LET ga_dsplymsg[2] = "    "
	  LET ga_dsplymsg[3] = "To modify this value, delete the incorrect"
	  LET ga_dsplymsg[4] = "  entry and enter a new one with the correct"
	  LET ga_dsplymsg[5] = "  manufacturer code."
	  CALL message_window(7,7)

 	  LET ga_manuf[curr_pa].manu_code = pr_workman.manu_code
	  NEXT FIELD manu_code
        END IF
      END IF

    BEFORE FIELD manu_name
--* Save original value of manu_name in work buffer
      LET pr_workman.manu_name = ga_manuf[curr_pa].manu_name

    AFTER FIELD manu_name
--* Prevent user from leaving empty manu_name field
      IF ga_manuf[curr_pa].manu_name IS NULL THEN
	ERROR "You must enter a manufacturer name. Please try again."
	NEXT FIELD manu_name
      END IF

--* If user has modified manu_name and line is not already marked, mark 
--*   line as "updated"
------------------------
      IF (ga_manuf[curr_pa].manu_name <> pr_workman.manu_name) THEN
	IF ga_mrowid[curr_pa].op_flag IS NULL THEN
	  LET ga_mrowid[curr_pa].op_flag = "U"
	END IF
      END IF

    BEFORE FIELD lead_time
--* Initialize empty lead_time field to 0 days
      IF ga_manuf[curr_pa].lead_time IS NULL THEN
	LET ga_manuf[curr_pa].lead_time = 0 UNITS DAY
      END IF

--* Save original value of lead_time in work buffer
      LET pr_workman.lead_time = ga_manuf[curr_pa].lead_time
--* Notify user of special input format required for INTERVAL field
      MESSAGE "Enter the lead_time in the form ' ###' (e.g. ' 001')."

    AFTER FIELD lead_time
--* If lead_time is empty, assign a value of 0 days 
      IF ga_manuf[curr_pa].lead_time IS NULL THEN
	LET ga_manuf[curr_pa].lead_time = 0 UNITS DAY
        DISPLAY ga_manuf[curr_pa].lead_time TO sa_manuf[curr_sa].lead_time
      END IF

--* If user has modified lead_time, mark line as "updated"
      IF (ga_manuf[curr_pa].lead_time <> pr_workman.lead_time) THEN
	IF ga_mrowid[curr_pa].op_flag IS NULL THEN
	  LET ga_mrowid[curr_pa].op_flag = "U"
	END IF
      END IF

--* Clear out message line and replace user instructions (Message line
--*  is line 13)
------------------------
      MESSAGE ""
      DISPLAY " Press CTRL-E to insert a line, CTRL-T to delete a line."
        AT 13, 1 ATTRIBUTE (REVERSE, YELLOW)

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    CALL msg("Manufacturer maintenance terminated.")
    RETURN (FALSE)
  END IF

--* Ask user to confirm changes made
  IF prompt_window("Are you sure you want to save these changes?", 8,11)
  THEN
    RETURN (TRUE)
  ELSE
    RETURN (FALSE)
  END IF

END FUNCTION  -- dsply_manuf --

########################################
FUNCTION valid_null(array_idx, array_size)
########################################
--* Purpose: Checks the last key pressed to determine if the current 
--*            field can contain be empty.
--* Argument(s): array_idx - current position of cursor in prog array
--*              array_size - current size of prog array
--* Return Value(s): TRUE - field can be NULL
--*                  FALSE - field cannot be NULL
---------------------------------------
  DEFINE	array_idx	SMALLINT,
		array_size	SMALLINT,

		next_fld	SMALLINT,
		last_key	INTEGER

--* if cursor is on the last line 
--*   if the user presses up arrow or Accept then
--*     up arrow: null manu_code is OK, move up
--*     Accept: null manu_code is OK, save and exit
--*   else the user presses RETURN
--*     null manu_code is not OK, force return to field

--* if cursor is NOT on last line
--*   if the user presses up arrow, down arrow, Accept then
--*     null manu_code is NOT OK because it leaves a gap in the array
--*	suggest deleting the line 
--*	force return to field
--*   if the user presses RETURN then
--*     null manu_code is NOT OK because it allows entry of a null code
--*	force return to field
------------------------

--* NOTE: the FGL_LASTKEY() and FGL_KEYVAL() functions are new 4.1 features.
  LET last_key = FGL_LASTKEY()
  LET next_fld = (last_key = FGL_KEYVAL("right")) 
		   OR (last_key = FGL_KEYVAL("return")) 
		   OR (last_key = FGL_KEYVAL("tab"))

  IF (array_idx >= array_size) THEN   -- cursor is on last, empty line
    IF next_fld THEN		      --  AND user moves to next field
      RETURN (FALSE)
    END IF
  ELSE	  -- cursor is on an empty line within the array

--* User presses key that does NOT move to next field
    IF NOT next_fld THEN		
      LET ga_dsplymsg[1] = "You cannot leave an empty line in the middle "
      LET ga_dsplymsg[2] = " of the array. To continue, either: "
      LET ga_dsplymsg[3] = "    - enter a manufacturer in the line"
      LET ga_dsplymsg[4] = "    - delete the empty line "
      CALL message_window(7, 12)
    END IF
    RETURN (FALSE)
  END IF
    
  RETURN (TRUE)

END FUNCTION  -- valid_null --

########################################
FUNCTION reshuffle(direction)
########################################
--* Purpose: reshuffles or reorders the ga_mrowid to add or remove
--*            a line. Required because ga_mrowid must remain in
--*            sync with ga_manuf (ga_mrowid[idx].* contains info
--*            for same row as ga_manuf[idx].*). 4GL automatically 
--*            adds and removes lines from ga_manuf because it is 
--*            the program array.
--* Argument(s): direction - "I" (Insert) add a new line 
--*                          "D" (Delete) remove a line
--* Return Value(s): NONE
---------------------------------------
  DEFINE	direction		CHAR(1),

		pcurr, ptotal, i 	SMALLINT,
		clear_it		SMALLINT

--* Get current index and size for program array
  LET pcurr = ARR_CURR()
  LET ptotal = ARR_COUNT()

  IF direction = "I" THEN   	--* reshuffle to create an open
				--*   position in the array
    FOR i = ptotal TO pcurr STEP -1
      LET ga_mrowid[i + 1].* = ga_mrowid[i].*
    END FOR

--* Line to clear out is the current cursor line
    LET clear_it = pcurr
  END IF

  IF direction = "D" THEN	--* reshuffle to get rid of the
				--*   open position in the array
    IF pcurr < ptotal THEN
      FOR i = pcurr TO ptotal 
        LET ga_mrowid[i].* = ga_mrowid[i + 1].*
      END FOR
    END IF

--* Line to clear out is the last line of the array
    LET clear_it = ptotal
    
  END IF

--* Clear out appropriate line of array
  LET ga_mrowid[clear_it].mrowid = 0
  LET ga_mrowid[clear_it].op_flag = NULL

END FUNCTION  -- reshuffle --

########################################
FUNCTION verify_mdel(array_idx)
########################################
--* Purpose: Verifies that a manufact row can be deleted by
--*            determining whether stock items exist for the
--*            manufacturer.
--* Argument(s): array_idx - current position of cursor in prog array
--* Return Value(s): TRUE - no stock items exist
--*                  FALSE - stock rows exist; don't DELETE
---------------------------------------
  DEFINE	array_idx	SMALLINT,

		stock_cnt	SMALLINT

--* Count number of stock rows for current manufacturer
  SELECT COUNT(*)
  INTO stock_cnt
  FROM stock
  WHERE manu_code = ( SELECT manu_code 
		      FROM manufact
		      WHERE ROWID = ga_drows[array_idx].mrowid )

  IF stock_cnt > 0 THEN
    LET ga_dsplymsg[1] = "Inventory currently has stock items made"
    LET ga_dsplymsg[2] = "  by manufacturer ", ga_drows[array_idx].manu_code
    LET ga_dsplymsg[3] = "Cannot delete manufacturer while stock items"
    LET ga_dsplymsg[4] = "  exist."
    CALL message_window(6,9)

    RETURN (FALSE)
  END IF

  RETURN (TRUE)
END FUNCTION  -- verify_mdel --

########################################
FUNCTION choose_op()
########################################
--* Purpose: Calls the function to perform the appropriate database
--*            operation on each line of the program array. The 
--*            operation is determined by the line's op_flag (in the
--*            ga_mrowid global array.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	idx	SMALLINT

--* Check ga_mrowid global array for lines which have been added
--*   ("I") or updated ("U").
------------------------
  FOR idx = 1 TO ARR_COUNT()
    CASE ga_mrowid[idx].op_flag
      WHEN "I"
	CALL insert_manuf(idx)
      WHEN "U"
	CALL update_manuf(idx)
    END CASE
  END FOR

--* Perform delete operation for each line in ga_drows (indexed by
--*   g_idx global variable).
------------------------
  FOR idx = 1 TO g_idx
    CALL delete_manuf(idx)
  END FOR

END FUNCTION  -- choose_op --

########################################
FUNCTION insert_manuf(array_idx)
########################################
--* Purpose: Adds a new row to the manufact table. 
--* Argument(s): array_idx - current position of cursor in prog array
--* Return Value(s): NONE
---------------------------------------
  DEFINE	array_idx	SMALLINT

--* Insert a new manufact row with values stored in a line of the 
--*  ga_manuf global array.
------------------------
WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
  INSERT INTO manufact  (manu_code, manu_name, lead_time)
  VALUES (ga_manuf[array_idx].manu_code,
	  ga_manuf[array_idx].manu_name,
	  ga_manuf[array_idx].lead_time)
WHENEVER ERROR STOP -- reset compiler flag to halt on runtime errors

  IF (status < 0) THEN

--* If INSERT was not successful, notify user of error number
--*  (in "status").
------------------------
    ERROR status USING "-<<<<<<<<<<<", 
	": Unable to complete manufact insert of ", 
	ga_manuf[array_idx].manu_code
  ELSE
    LET ga_dsplymsg[1] = "Manufacturer ", ga_manuf[array_idx].manu_code, 
	" has been inserted."
    CALL message_window(6,6)
  END IF

END FUNCTION  -- insert_manuf --

########################################
FUNCTION update_manuf(array_idx)
########################################
--* Purpose: Updates a single manufact row with the contents of a
--*            line in the ga_manuf global array. 
--* Argument(s): array_idx - current position of cursor in prog array
--* Return Value(s): NONE
---------------------------------------

  DEFINE	array_idx	SMALLINT,

		mrowid		INTEGER,
		mcode		LIKE manufact.manu_code

--* Verify that the row identified by the ROWID has not been
--*   deleted or updated since the program first acquired it
------------------------
  LET mrowid = ga_mrowid[array_idx].mrowid
  LET mcode = ga_manuf[array_idx].manu_code
  IF verify_rowid(mrowid, mcode) THEN

--* Update a manufact row with values stored in a line of the 
--*  ga_manuf global array.
------------------------
WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
    UPDATE manufact SET (manu_code, manu_name, lead_time) =
      (ga_manuf[array_idx].manu_code, ga_manuf[array_idx].manu_name,
       ga_manuf[array_idx].lead_time)
    WHERE ROWID = mrowid
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

    IF (status < 0) THEN

--* If UPDATE was not successful, notify user of error number
--*  (in "status").
------------------------
      ERROR status USING "-<<<<<<<<<<<", 
	": Unable to complete manufact update of ", mcode
    END IF

    LET ga_dsplymsg[1] = "Manufacturer ", mcode, " has been updated."
    CALL message_window(6,6)
  END IF

END FUNCTION  -- update_manuf --

########################################
FUNCTION delete_manuf(del_idx)
########################################
--* Purpose: Deletes the manufact row whose ROWID is stored in 
--*            the ga_drows global array
--* Argument(s): del_idx - current position in ga_drows array
--* Return Value(s): NONE
---------------------------------------
  DEFINE	del_idx		SMALLINT,

		msg_text	CHAR(40),
		mrowid		INTEGER

--* Verify that the manufact row has not associated stock
--*   items in database.
------------------------
  IF verify_mdel(del_idx) THEN

--* Verify that the row identified by the ROWID has not been
--*   deleted or updated since the program first acquired it
------------------------
    LET mrowid = ga_drows[del_idx].mrowid
    IF verify_rowid(mrowid, ga_drows[del_idx].manu_code) THEN

--* Delete the manufact row whose ROWID is in ga_drows[del_idx]
WHENEVER ERROR CONTINUE -- set compiler flag to ignore runtime errors
      DELETE FROM manufact 
      WHERE rowid = mrowid
WHENEVER ERROR STOP  -- reset compiler flag to halt on runtime errors

      IF (status < 0) THEN

--* If DELETE was not successful, notify user of error number
--*  (in "status").
------------------------
        ERROR status USING "-<<<<<<<<<<<", 
	  ": Unable to complete manufact delete of ", 
	  ga_drows[del_idx].manu_code
      END IF

      LET ga_dsplymsg[1] = "Manufacturer ", ga_drows[del_idx].manu_code, 
	" has been deleted."
      CALL message_window(6,6)
    END IF
  END IF

END FUNCTION  -- delete_manuf --

########################################
FUNCTION verify_rowid(mrowid, code_in_mem)
########################################
--* Purpose: Verifies that the ROWID stored in ga_mrowid still
--*            identifies the same manufact row. Because the manufact
--*            row was not locked when the program obtained the ROWID,
--*            another user could have updated or deleted the row
--*            identified by the ROWID in ga_mrowid. If this row
--*            has been changed, this program should not attempt
--*            to update or delete it.
--* Argument(s): mrowid - ROWID of row to verify
--*              code_in_mem - manufacturer code of row when ROWID
--*                            was stored in ga_mrowid
--* Return Value(s): TRUE - row identified by ROWID has not changed
--*                  FALSE - row identified by ROWID has changed
---------------------------------------
  DEFINE	mrowid		INTEGER,
		code_in_mem	LIKE manufact.manu_code,

		code_on_disk	LIKE manufact.manu_code

--* Find the manufacturer code of the row currently identified by
--*   ROWID
------------------------
  SELECT manu_code
  INTO code_on_disk
  FROM manufact
  WHERE ROWID = mrowid


--* If no row exists with specified ROWID, row has been deleted. If
--*  the current manufacturer code does not match the manufacturer
--*  code when the program started, row has been updated.
------------------------
  IF (status = NOTFOUND) 
      OR (code_on_disk <> code_in_mem)
  THEN
    ERROR "Manufacturer ", code_in_mem,
	" has been deleted by another user."
    RETURN (FALSE)
  END IF

  RETURN (TRUE)

END FUNCTION  -- verify_rowid --

########################################
FUNCTION save_rowid(mrowid, mcode)
########################################
--* Purpose: Saves the row information into the ga_drows global
--*            array. The ROWID for each manufact row is stored in the
--*            ga_mrowid global array. When the user deletes a line on 
--*            the f_manuf form, 4GL automatically removes the line 
--*            from the program array (ga_manuf) and the program 
--*            removes the line from the corresponding ROWID array 
--*            (ga_mrowid). However, before the line is removed from 
--*            ga_mrowid, this function saves the ROWID in the 
--*            global array (ga_drows) so that:
--*              (a) the ga_manuf and ga_mrowid arrays can remain 
--*                  parallel
--*              (b) the row can be deleted once the user has finished 
--*                  editing the manufact rows
--*          This function also increments the global index (g_idx)
--*            for the ga_drows array.
--* Argument(s): mrowid - ROWID of row to save in ga_drows
--*              mcode - manufacturer code of row to save in ga_drows
--* Return Value(s): NONE
---------------------------------------
  DEFINE	mrowid		INTEGER,
		mcode		LIKE manufact.manu_code

--* Initialize g_idx if there are not yet entries in ga_drows
  IF g_idx IS NULL THEN
    LET g_idx = 0
  END IF

--* Increment g_idx to move to the next available line in ga_drows 
  LET g_idx = g_idx + 1

--* Store ROWID and manufacturer code in ga_drows 
  LET ga_drows[g_idx].mrowid = mrowid
  LET ga_drows[g_idx].manu_code = mcode

END FUNCTION  -- save_rowid --

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
  LET numrows = 4		-- * numrows value:
				-- *        1 (for the window header)
				-- *        1 (for the window border)
				-- *        1 (for the empty line before
				-- *            the first line of message)
				-- *        1 (for the empty line after
				-- *            the last line of message)

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
  LET rownum = 3		-- * start text display at third line
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
  IF ques_lngth <= 41 THEN 	-- * room enough to add "(n/y): " string
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


