
#######################################################################
# APPLICATION: Example 28 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex28.4gl                        FORM: none                    #
#                                       ASSOCIATED FILES: ex28pa.unl  #
#                                                         ex28pt.unl  # 
#                                                                     # 
# PURPOSE: This program demonstrates the use of recursive algorithms  #
#          in 4gl, in particular ways of working around the fact that #
#          cursors are global objects and cannot be localized.        #
#                                                                     # 
#          Since there is no naturally recursive data in the demo     # 
#          database, the MAIN program creates two tables that support # 
#          a model bill-of-materials application.                     # 
#                                                                     # 
# STATEMENTS:                                                         # 
#          CREATE TEMP TABLE      DROP TABLE          INSERT          # 
#          SELECT...GROUP BY      START REPORT TO     LOAD            # 
#                                                                     # 
# FUNCTIONS:                                                          #
#    explode_all() - drives the parts-explosion demonstration by      #
#       setting up report, then calling explode() once for each       #
#       top-level part in tree.                                       #
#    explode(p,n,l) - recursive function that prints an indented      #
#       listing of all parts contained within part p.                 # 
#    kaboom(p,n,l) - report function used by explode() to format a    #
#       print line.                                                   #
#    inventory_all() - drives the parts-inventory demonstration by    #
#       setting up report, then calling inventory() once for each     #
#       top-level part in tree.                                       # 
#    inventory(p,n,l) - recursive function that makes an inventory of #
#       all unitary parts used to assemble part p.                    # 
#    inven_rep(p,n,l) - report function used by inventory() to format #
#       print lines.                                                  #
#    pushkids(p) - finds all children of part p, lists them and their #
#       use counts in the array ma_kidstack, and returns the count of #
#       them.                                                         # 
#    pop_a_kid() - return the part number and use count of the        #
#       last-stacked part.                                            #
#    set_up_tables() - locates, or creates, the two tables needed by  #
#       the example. The user supplies a database name and a path to  #
#       the load files.                                               #
#    tear_down_tables() - optionally removes model tables after       #
#       demonstration is over.                                        # 
#                                                                     # 
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/16/91    dec             Created Example 28                     #
#                                                                     # 
#######################################################################

--* Module variables
DEFINE 	ma_kidstack 	 ARRAY[200] OF INTEGER,	-- two items per pushed kid
	m_nextkid  	 SMALLINT,	-- MUST BE INITIALIZED TO ZERO
	m_theDb, m_fpath CHARACTER(80)

########################################
MAIN
########################################

--* Set up the PARTS and PARTREE tables which hold the part info
	CALL set_up_tables()	-- exits program unless tables are ok

--* Initialize number of child parts 
	LET m_nextkid = 0

--* Declare c_parent cursor used in both report drivers to find all
--*   parent parts. 
------------------------
	DECLARE c_parent CURSOR FOR
	  SELECT DISTINCT mainq.parent 
	  FROM PARTREE mainq
	  WHERE 0 = (SELECT COUNT(*) 
			FROM PARTREE subq
			WHERE subq.child=mainq.parent)

	CALL explode_all()	-- parts explosion for all parents
	CALL inventory_all()	-- parts inventory for all parents
	CALL tear_down_tables()	-- offers to remove tables & does

END MAIN

########################################
FUNCTION explode_all()
########################################
--* Purpose: This is the driver for the parts-explosion report. For 
--*            each top-level part it calls the recursive explode() 
--*            function to display the parts explosion for that part.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE dada INTEGER

  DISPLAY ""
  DISPLAY ""
  DISPLAY "DEMONSTRATING PARTS EXPLOSION"
  DISPLAY ""

--* Ask for name of output file for the report
  DISPLAY "Specify a filename to receive the parts explosion report"
  DISPLAY "  file or just press RETURN for report to the screen."
  DISPLAY ""
  PROMPT  "File: " FOR m_fpath
  DISPLAY ""
  DISPLAY "Generating the file ", m_fpath CLIPPED, ". Please wait..."
  DISPLAY ""

--* If user pressed RETURN, send report output to screen. Otherwise
--*   send it to the specified file
------------------------
  IF LENGTH(m_fpath) = 0 THEN
	START REPORT kaboom
  ELSE
	START REPORT kaboom TO m_fpath
  END IF

--* Send each parent part to the recursive function
  FOREACH c_parent INTO dada
	CALL explode(dada,1,0) -- used once at level 0
  END FOREACH

  FINISH REPORT kaboom

END FUNCTION  -- explode_all --

########################################
FUNCTION explode(pn,pu,ln)
########################################
--* Purpose: Recursively walks the tree of parts. It obtains the
--*            current part and then calls itself to obtain each 
--*            child part. The formatting is done in the report 
--*            function, kaboom().
--* Argument(s): pn - part number of the part to expand
--*	         pu - number of times this part is used at this level
--*	         ln - level in the tree that this part is on
--* Return Value(s): NONE
---------------------------------------
  DEFINE	pn 	INTEGER,	-- this part number
		pu 	INTEGER,	-- number of times used at this level
		ln 	INTEGER,	-- level in the tree

		nkids 	SMALLINT,	-- number of children pn has
		kn 	INTEGER,	-- part number of one kid
		ku 	INTEGER,	-- its usage count
		pdesc 	CHAR(40)  -- description of pn

--* Get name of the part from the PARTS table
	SELECT descr INTO pdesc 
	FROM PARTS
	WHERE partnum = pn

--* Send information for this part to the report
	OUTPUT TO REPORT kaboom(pn,pdesc,pu,ln)

--* Push all child parts for this parent part onto the stack.
--*   Function returns the number of child parts pushed. For
--*   each of the child parts, get the part number (kn) and the
--*   usage count (ku) and call explode() recursively.
------------------------
	CALL pushkids(pn) RETURNING nkids -- get, save pn's children
	WHILE nkids > 0
		CALL pop_a_kid() RETURNING kn, ku
		LET nkids = nkids - 1
		CALL explode(kn,ku,ln+1) -- here's the recursion!
	END WHILE

END FUNCTION  -- explode --
	
########################################
REPORT kaboom(part,desc,use,level)
########################################
--* Purpose: Report function to create the parts explosion
--*            report. This report lists each parent part and 
--*            the parts which make up this part. If any
--*            child part is, in turn, made up of parts, the
--*            report lists these parts as well, until it 
--*            reaches a noncomposite (bottom-level) part.
--* Argument(s): part - part number of part
--*              desc - description of part
--*              use - number of times this part is used
--*              level - the level number in the part tree
--*                      the report is currently on
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	part 	INTEGER,
		desc 	CHAR(40),
		use 	INTEGER,
		level 	INTEGER,
		j 	SMALLINT

  FORMAT
    PAGE HEADER
	PRINT COLUMN 20, "PARTS EXPLOSION REPORT - PAGE",
			PAGENO USING "###"
	PRINT COLUMN 30, TODAY
	SKIP 3 LINES

    ON EVERY ROW
	IF level = 0 THEN 
	  PRINT 
 	END IF -- blank line
	FOR j = 1 TO level
		PRINT 4 SPACES;
	END FOR
	PRINT	part USING "&&&&&&", " (",use USING "---",") ",
			desc CLIPPED
END REPORT  -- kaboom --

########################################
FUNCTION inventory_all()
########################################
--* Purpose: This is the driver for the parts-inventory report. For 
--*            each top-level part it calls the recursive inventory() 
--*            function to display the inventory of parts used 
--*            in that part.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE papa INTEGER

  DISPLAY "DEMONSTRATING PARTS USAGE INVENTORY"
  DISPLAY ""

--* Ask for name of output file for the report
  DISPLAY "Specify a filename to receive the inventory report"
  DISPLAY "  file or just press RETURN for report to the screen."
  DISPLAY ""
  PROMPT  "File: " FOR m_fpath
  DISPLAY "Generating the file ", m_fpath CLIPPED, ". Please wait..."
  DISPLAY ""

--* If user pressed RETURN, send report output to screen. Otherwise
--*   send it to the specified file
------------------------
  IF LENGTH(m_fpath) = 0 THEN
	START REPORT inven_rep
  ELSE
	START REPORT inven_rep TO m_fpath
  END IF

--* Send each parent part to the recursive function
  FOREACH c_parent INTO papa
	CALL inventory(papa,0) -- this assembly used 0 times
  END FOREACH

  FINISH REPORT inven_rep
END FUNCTION  -- inventory_all --

########################################
FUNCTION inventory(pn,un)
########################################
--* Purpose: Recursively walks the tree of parts. It accumulates a
--*            list of the unit (unitary, non-composite) parts used 
--*            in a given part. The list is kept in a temporary 
--*            table; when a top-level part has been completely 
--*            listed, the table is read out and reported. The 
--*            formatting is done in the report function, 
--*            inven_rep().
--* Argument(s): pn - part number of the part to do the inventory on
--*	         un - quantity needed (0 means top level)
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	pn INTEGER,	-- major assembly to inventory
		un INTEGER,	-- quantity needed (0 means top level)

		nkids SMALLINT,	-- number of progeny of pn
		mulfac SMALLINT,-- quantity of part pn needed   
		kn INTEGER,	-- one child
		ku INTEGER,	-- number of parts kn in one part pn
		desc CHAR(40)	-- one descriptor

  LET mulfac = un		-- usually true except for kludge:
  IF un = 0 THEN -- this is top-level call, initialize temp table
	CREATE TEMP TABLE invenTemp (partnum INTEGER, used INTEGER ) 
	  WITH NO LOG
	LET mulfac = 1
  END IF

--* Push all child parts for this parent part onto the stack.
--*   Function returns the number of child parts pushed. 
------------------------
  CALL pushkids(pn) RETURNING nkids

--* If level is 0, this is a noncomposite (bottom-level) part so add it
--*   to the temporary table.
------------------------
  IF nkids = 0 THEN 	
	INSERT INTO invenTemp VALUES(pn,mulfac)
  ELSE			-- part pn is an assembly, inventory it

--*   For each of the child parts, get the part number (kn) and 
--*   the usage count (ku) from the stack and call inventory() recursively.
------------------------
	WHILE nkids > 0
		CALL pop_a_kid() RETURNING kn, ku
		LET nkids = nkids - 1
		CALL inventory(kn,ku*mulfac) -- recurse!
	END WHILE
  END IF
	
  IF un = 0 THEN -- top level call, now do the report
	SELECT descr INTO desc 
	FROM PARTS 
	WHERE partnum = pn

--* Have report print out a header to introduce the part
	OUTPUT TO REPORT inven_rep(pn,0,desc)

--* The c_unitpart cursor will contains all parts which make up the
--*   part "pn". The SELECT uses the SUM() aggregate function to 
--*   total up the number of parts used for this part
------------------------
	DECLARE c_unitpart CURSOR FOR
		SELECT t.partnum, SUM(t.used), p.descr
		INTO kn,ku,desc
		FROM invenTemp t, PARTS p
		WHERE t.partnum = p.partnum
		GROUP BY t.partnum, p.descr
		ORDER BY t.partnum

	FOREACH c_unitpart
--* Send number of part "kn" used in this part, "ku".
		OUTPUT TO REPORT inven_rep(kn,ku,desc)
	END FOREACH
--* Drop temp table so it is "cleared out" for next part
	DROP TABLE invenTemp
  END IF
END FUNCTION  -- inventory --

########################################
REPORT inven_rep(part,use,desc)
########################################
--* Purpose: Report function to create the parts inventory
--*            report. This report lists each parent part and 
--*            the parts which make up this part. For each
--*            child part, the report lists the number of this
--*            part used in the parent part.
--* Argument(s): part - part number of part
--*              use - number of times this part is used
--*              desc - description of part
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	part, use INTEGER,
		desc CHAR(40)

  FORMAT
    PAGE HEADER
	PRINT COLUMN 26, "INVENTORY REPORT - PAGE ",
			PAGENO USING "###"
	PRINT COLUMN 36, TODAY
	SKIP 3 LINES

    ON EVERY ROW
	IF use > 0 THEN
		PRINT use USING "####", " of ",desc,
			" (", part USING "&&&&&&",")"
	ELSE -- control break time

--* If use is zero, have a parent part so print out a header for
--*   this part.
------------------------
		PRINT
		PRINT "Unit parts used in ",desc,
			" (",part USING "&&&&&&",")"
		PRINT
	END IF
END REPORT  -- inven_rep --

---------------------------------------
--* Because a cursor is a global object, it is not possible to put a
--* recursive function call within a FOREACH loop: the cursor must be
--* opened, used and closed before the recursion happens. In both the
--* explode() and inventory() functions we need to make a recursive
--* call for each child of a part, but we need a cursor to find the
--* child part numbers.  The following two subroutines are
--* one solution to this problem.
--*
--* The drawback of this solution is the fixed size of the stack, which
--* must be able to hold all siblings along one path from root to branch.
--* Another is that the stack pointer "m_nextkid" must be initialized.
---------------------------------------

########################################
FUNCTION pushkids(pn)
########################################
--* Purpose: Finds all child parts of parent pn, and "pushes" their
--*            partnums and use counts on the stack implemented by the
--*            ma_kidstack array. 
--* Argument(s): pn - part number of part to find children of
--* Return Value(s): the number of child parts pushed onto the stack.
---------------------------------------
  DEFINE 	pn	INTEGER, 

		kn, ku 	INTEGER,
		oldtop 	SMALLINT

--* The c_kid cursor will contain the child parts for
--*   part "pn"
------------------------
  DECLARE c_kid CURSOR FOR
	SELECT child, used INTO kn, ku 
	FROM PARTREE
	WHERE parent = pn
	ORDER BY child DESC 

--* Save the current "top" of the stack
  LET oldtop = m_nextkid

--* Put each child part on the "stack" by first incrementing the
--*   top-of-stack pointer, m_nextkid, then storing first the child
--*   part number and then it's usage count at this position of the
--*   ma_kidstack array.
------------------------
  FOREACH c_kid
	LET m_nextkid = m_nextkid + 1
	LET ma_kidstack[m_nextkid] = kn
	LET m_nextkid = m_nextkid + 1
	LET ma_kidstack[m_nextkid] = ku
  END FOREACH

--* Return the number of kids "pushed" onto the stack
  RETURN (m_nextkid - oldtop)/2
END FUNCTION  -- pushkids --

########################################
FUNCTION pop_a_kid()
########################################
--* Purpose: "Pops" the information for one child part from the
--*             top of the stack implemented by the ma_kidstack
--*             array. 
--* Argument(s): NONE
--* Return Value(s): the information for a child part:
--*                        part number
--*                        usage count
---------------------------------------
--* pop_a_kid() returns one pushed part number and count.
--*            Can either accept info for a new customer or
--*	       allow update of existing info.
  DEFINE kn, 			-- kid number from stack 
	 ku 	INTEGER		-- kid usage from stack

--* Use current top-of-stack pointer to "pop" child part
--*   info: first the usage count and then the part number
--*   Note that the items come off the stack in the reverse of the
--*   order they were pushed on (in pushkids()) because a stack is a
--*   last-in-first-out structure.
------------------------
  LET ku = ma_kidstack[m_nextkid]
  LET m_nextkid = m_nextkid - 1
  LET kn = ma_kidstack[m_nextkid]
  LET m_nextkid = m_nextkid - 1
	
  RETURN kn, ku

END FUNCTION  -- pop_a_kid --
	
########################################
FUNCTION set_up_tables()
########################################
--* Purpose: Locates or creates a database to hold the PARTS 
--*            and PARTREE tables. Create and populate the tables 
--*            if necessary.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	j, k 	SMALLINT, 
		afile 	CHAR(80)

WHENEVER ERROR CONTINUE	-- don't crash if things don't exist

  DISPLAY "DEMONSTRATING A RECURSIVE FUNCTION"
  DISPLAY ""
  DISPLAY "This program uses two tables named PARTS and PARTREE."
  DISPLAY ""

--* Accept name of database containing the PARTS and PARTREE tables
  DISPLAY "Please enter the name of a database where these tables"
  DISPLAY "  now exist. If they do not exist now, just press RETURN."
  DISPLAY ""
  PROMPT  "Database name: " FOR m_theDb
  DISPLAY ""

--* If user just pressed RETURN, will try to create tables in 
--*   existing db.
------------------------
  IF LENGTH(m_theDb CLIPPED) = 0 THEN

--* Accept name of db to check for tables
    DISPLAY "Please enter the name of a database where we can create"
    DISPLAY "  those two tables. Press RETURN to use the stores2"
    DISPLAY "  database."
    DISPLAY ""
    PROMPT  "Database name: " FOR m_theDb
    DISPLAY ""
--* If user just pressed RETURN, will check db "stores2"
    IF LENGTH(m_theDb) = 0 THEN
	 LET m_theDb = "stores2" 
    END IF

    DATABASE m_theDb

--* If unable to open db, will try to create one 
    IF SQLCA.SQLCODE = -329 THEN
	DISPLAY "Database ", m_theDb CLIPPED,
		" does not exist (or if it does, you"
	DISPLAY "  do not have Connect privilege in it).  We will try to"
	DISPLAY "  create the database."
	DISPLAY ""
	LET SQLCA.SQLCODE = 0 -- does create db not set this?
	CREATE DATABASE m_theDb
	IF SQLCA.SQLCODE = 0 THEN
		DISPLAY "Database has been created."
		DISPLAY ""
	END IF
    END IF
  ELSE
--* User entered name of db where PARTS and PARTREE tables exist. Try
--*   opening it
------------------------
    DATABASE m_theDb
  END IF
  IF SQLCA.SQLCODE <> 0 THEN
    DISPLAY "Sorry, error ",SQLCA.SQLCODE,
	    " opening or creating the database ",m_theDb CLIPPED
    EXIT PROGRAM
  END IF

--* Once db is opened, check for existence of PARTS and PARTREE
--*   tables
------------------------
  LET j = 0	-- in case no table is there
  LET k = 0
  SELECT COUNT(*) 
  INTO j 
  FROM PARTS

  SELECT COUNT(*) 
  INTO k 
  FROM PARTREE

--* If both tables exist and have rows, have completed set-up so
--*   exit function.
------------------------
  IF 0 < (j*k) THEN -- both tables exist, have rows
    DISPLAY "The needed tables do exist in this database. Thank you."
    RETURN
  END IF

--* At least one table does not exist or is empty so need to create
--*   and load tables
------------------------
  DISPLAY "To load the tables we need the file pathname for two files:"
  DISPLAY "         ex28pa.unl  and  ex28pt.unl"
  DISPLAY "  They came in the same directory as this program file."
  DISPLAY ""

--* Accept pathname for load files: ex28pa.unl (PARTS) and ex28pt.unl (PARTREE)
  DISPLAY "  Enter a pathname, including the final slash or backslash."
  DISPLAY "  If it is the current working directory just press RETURN."
  DISPLAY ""
  PROMPT  "Path to those files: " FOR m_fpath

WHENEVER ERROR STOP

--* Create tables
  CREATE TABLE PARTS(partnum INTEGER, descr CHAR(40))
  DISPLAY "Table PARTS has been created."

  CREATE TABLE PARTREE(parent INTEGER, child INTEGER, used INTEGER)
  DISPLAY "Table PARTREE has been created."
  DISPLAY ""

--* Load tables from files
  LET afile = m_fpath CLIPPED, "ex28pa.unl"
  DISPLAY "Loading PARTS from ",afile CLIPPED
  LOAD FROM afile INSERT INTO PARTS
  DISPLAY "Table PARTS has been loaded."
  DISPLAY ""
  LET afile = m_fpath CLIPPED, "ex28pt.unl"
  DISPLAY "Loading PARTREE from ",afile CLIPPED
  LOAD FROM afile INSERT INTO PARTREE
  DISPLAY "Table PARTREE has been loaded."
  DISPLAY ""

END FUNCTION  -- set_up_tables --

########################################
FUNCTION tear_down_tables()
########################################
--* Purpose: Offers to remove the PARTS and PARTREE tables.
--*            If these tables are the only two remaining in the
--*            database, this function also offers to remove the 
--*            database.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE 	ans 	CHAR(1), 
		j 	SMALLINT

  DISPLAY "We can leave the PARTS and PARTREE tables for use again"
  DISPLAY "  (or for you to modify and experiment with), or we can"
  DISPLAY "  drop them from the database."
  DISPLAY ""
  PROMPT  "Do you want to drop the two tables? (y/n): " FOR ans
  IF ans MATCHES "[yY]" THEN
    DROP TABLE PARTS
    DROP TABLE PARTREE
    DISPLAY "Tables dropped."

--* See if the database is now empty of user-defined tables
    SELECT COUNT(*) INTO j 
    FROM informix.systables 
    WHERE tabid > 99

    IF j = 0 THEN -- no more tables left
	DISPLAY "Database ",m_theDb CLIPPED," is empty now."
	PROMPT  "Do you want to drop the database also? (y/n): " FOR ans
	IF ans MATCHES "[yY]" THEN
	    DISPLAY ""
	    DISPLAY "You have chosen to REMOVE the ", m_theDb CLIPPED,
		" database. This step cannot be undone."
	    PROMPT "Are you sure you want to drop this database? (y/n): "
	      FOR ans
	    IF ans MATCHES "[yY]" THEN
		CLOSE DATABASE

WHENEVER ERROR CONTINUE
		DROP DATABASE m_theDb
WHENEVER ERROR STOP
		IF (status < 0) THEN
		  DISPLAY "Sorry, error ", SQLCA.SQLCODE, 
		    " while trying to drop the database ", m_theDb CLIPPED
		  EXIT PROGRAM
		END IF

		DISPLAY ""
		DISPLAY "The ", m_theDb CLIPPED, " database has been dropped."
    	    ELSE
		DISPLAY "The ", m_theDb CLIPPED, " database has not been dropped."
    	    END IF
    	END IF
    END IF
  ELSE
    DISPLAY "Tables PARTS and PARTREE remain in database ",
		m_theDb CLIPPED, "."
  END IF
END FUNCTION  -- tear_down_tables --
