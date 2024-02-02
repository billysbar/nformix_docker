{######################################################################
# APPLICATION: blobdemo                                               # 
#                                                                     # 
# FILE: blobdemo.4gl                            FORM: main_bd.per,    # 
#                                                 pict_bd.per,        # 
#                                                 text_bd.per,        #
#                                                  varc_bd.per        # 
#                                                                     # 
# PURPOSE: This 4GL program illustrates use of byte, text and varchar #
#          datatypes under the OnLine engine. A GUI running either    #
#          Motif 1.1 or OpenWindows is required to display byte       #
#	   images (blobs). A GUI IS NOT NEEDED TO EXAMINE THE USE     #
#	   OF VARCHARS and TEXT BLOBS.                                #
#                                                                     # 
# FUNCTIONS:                                                          #
#   main()       - contains most of the set-up routines               #
#   show_varc()  - displays and update catalog.cat_advert varchar     #
#   show_text()  - displays and updates catalog.description text blob #
#   show_pict()  - displays and updates catalog.cat_picture byte blob #
#   set_up_cat() - reloads the catalog table at the user's discretion #
#   upd_err()    - reports an error if one occurs during an update    #
#   dispwait()   - displays a message and waits for acknowledgement   #
#   get_user()   - gets userID                                        #
#   kill_show()  - invokes a tmp file created by blobshow.sh that     #
#                  removes a displayed X image from the screen        #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date           author       change                                 #
#  --------    ----------      -------------------------------------- #
#  August '90      dc          create blobdemo under SunView          #
#  April '90       tk          convert demo and images to run under X #
#  May '90         dc          added catalog tbl reloading routine    #
####################################################################### 
--
//////////////////////////////////////////////////////////////////////// }
--
--			blobdemo.4gl release version 4.1
--
-- /////////////////////////////////////////////////////////////////////// --
--
--                       GENERAL INSTALLATION NOTES
--
-- /////////////////////////////////////////////////////////////////////// --
--
-- This program accesses the catalog table in the "stores2" OnLine database, which
-- contains a VARCHAR column, a TEXT column, and a BYTE column. Through this
-- program, all three can be displayed and updated.
--
-- ASSUMPTIONS: this program requires and assumes that:
--
--	1. You are using an Informix OnLine engine that supports TEXT
--         and BYTE datatypes.
--
--	2. You are using a HP workstation running Motif 1.1 (X11r4) or
--	   a Sun workstation running OpenWindows.
--
--	3. You have created a "stores2" demonstration database.
--
--	4. If you want to display blob images, you must have access to the
--	   X utility "xwud". This utility is typically located in the /bin
--	   directory of the GUI. For example, for OpenWindows, xwud can be
--	   found in "openwin/bin".
--	   
--	5. Your terminal window can display a 35 row by 80 column 4gl window.
--
--	6. A /tmp directory is available.
--
-- In addition, the ASCII editor to be used when editing TEXT fields
-- should be specified in the DBEDIT environment variable before you start
-- the program. The default is "vi".
--
-- A script to create the stores2 demonstration database can be invoked
-- by typing:
--
--		sqldemo name_of_database
--
-- If no name is specified, the name of the database will be "stores2"
--
-- Note: When the sqldemo script is called upon to create a database under OnLine, any
-- existing database of the same name is AUTOMATICALLY DROPPED (deleted) if you
-- own of the database. If you are not, for example, the owner of stores2, you will
-- need to create a database of a different name and change the DATABASE name in
-- this file and in the four .per filesif you want to create a new version of the
-- stores2 database.
--
-- When a demo database is created, the BYTE column of the
-- catalog table (cat_picture) contains nulls. blobdemo.4gl reloads catalog
-- to contain 10 blob images in "xwd" format. Hence this program is dependent
-- on its host being X11R4 or a derivative such as Motif 1.1 or OpenWindows if
-- you want to display and manipulate blob images.
--
-- This program has been tested on a color HP running Motif 1.1 and on a
-- monochrome SPARC 1+ running Sun OS 4.1.1 with a OpenWindows GUI.
-- using version 4.1 of Informix OnLine.  The theory is that it
-- should work in any other X11r4- or Motif 1.1-based system.
--
-- //////////////////////////////////////////////////////////////////////// --

-- Change the following DATABASE statement to reflect the name of the
-- demo database as installed on your system.  The DATABASE statement
-- also appears one other time!  The database statement is first used
-- nonprocedurally, to supply compile-time meanings for the LIKE clause.

DATABASE stores2

-- ////////////////////////////////////////////////////////////////////////
-- /////	Global variables
-- ////////////////////////////////////////////////////////////////////////

GLOBALS

define j,k integer		-- scratch integers for loop control
define transact char(1)		-- has W if database uses transactions
define answer char(80)		-- receives answer to misc. prompts
define process_var int		-- is image being shown or not

-- The following strings will contain operating system commands which
-- are executed with the RUN command in order to display and erase images.

define 	showpic	char(128)	-- command to display an image from a file

-- The following strings contain pathnames to temporary files.
-- The filenames are generated in function make_tmp_name().

define	picfname,		-- fname for cat_picture values
	savfname character(80)	-- fname for saved background bits

-- These variables represent one picture and one TEXT value. Only one
-- of each is fetched from the database at any time.

define	picblob byte,		-- image, located in picfname file
	txtblob text		-- cat_descr value, located in memory

-- The following structures are used to hold row data from the catalog table.
-- We allow for up to 200 rows (the catalog table in the enhanced stores
-- database currently has 75).

define	cat_cnt smallint	-- count of rows actually read

-- The cat_rows array holds data to be displayed through form main_bd.per .
-- This record structure must match the screen-record defined in the form.

define	cat_rows array[200] of record
		catalog_num	integer,
		stock_num 	smallint,
		manu_name	char(15),
		has_pic		char(1),
		has_desc	char(1),
		description	char(15)
	end record

-- In cat_adv[ j ] is the VARCHAR, cat_advert, that matches row cat_rows[ j ].
-- It is held separately because it is not displayed in the screen record.

define	cat_adv array[200] OF LIKE catalog.cat_advert
	
-- In cat_rids[ j ] is the ROWID of the data in cat_rows[ j ].  It is used
-- for fast selection of the TEXT or BYTE value for a specified row.

define	cat_rids array[200] of integer

	
END GLOBALS

-- ////////////////////////////////////////////////////////////////////////
-- /////	Main program
-- ////////////////////////////////////////////////////////////////////////
	
MAIN

	-- ////////////////////////////////////////////////////////////////
	-- ///// Initialize the program and its variables...
	-- ////////////////////////////////////////////////////////////////

-- Change the following to reflect the name of the enhanced stores database
-- as installed on your system.  It appeared one other time above!  Here it
-- is being executed solely to set the sqlawarn[2] flag which tells us
-- whether the database uses transactions.

DATABASE stores2
let transact = sqlca.sqlawarn[2] -- note use of transactions
let process_var = 0 		 -- no picture being shown

				-- ...do not stop cold on error or ^C	
defer interrupt

	 			-- ...specify usage of screen & windows
options MESSAGE LINE FIRST
options PROMPT LINE FIRST
options COMMENT LINE FIRST
options FORM LINE FIRST+1


				-- ...open forms that we use
open form main_bd from "main_bd"
open form pict_bd from "pict_bd"
open form text_bd from "text_bd"
open form varc_bd from "varc_bd"

whenever error continue

				-- ...set up names of scratch files
let picfname = make_tmp_fname("pic")
let savfname = make_tmp_fname("pic")

				-- ...locate the blob variables
locate picblob in file picfname
locate txtblob in memory

				--  ...clear out RUN-commands
let showpic = NULL

	-- ////////////////////////////////////////////////////////////////
	-- ///// Make sure we have pictures in the catalog table (if the
	-- ///// user wants pictures).
	-- ////////////////////////////////////////////////////////////////

call set_up_cat()

	-- ////////////////////////////////////////////////////////////////
	-- ///// Load up the contents of the catalog table into arrays.
	-- ////////////////////////////////////////////////////////////////

declare cat cursor for
	select unique catalog.catalog_num,
		catalog.stock_num,
		manufact.manu_name,
		stock.description,
		catalog.cat_advert,
		catalog.ROWID
	from catalog,manufact,stock
		where catalog.stock_num = stock.stock_num
		and catalog.manu_code = manufact.manu_code
		and stock.manu_code = manufact.manu_code
	order by 1

display "Loading catalog rows, hang on..." at 2,1

let cat_cnt = 1 { invariant: cat_cnt-1 rows have been loaded }
foreach cat into cat_rows[cat_cnt].catalog_num,
		 cat_rows[cat_cnt].stock_num,
		 cat_rows[cat_cnt].manu_name,
		 cat_rows[cat_cnt].description,
		 cat_adv[cat_cnt],
		 cat_rids[cat_cnt]

	-- The foreach loads the non-blob values into the arrays, but we do
	-- not want to load the blob values now, we have nowhere to put them
	-- and it would take too long.  However we do need to know if they
	-- exist (are not null) in each row.  In order to find out, we set
	-- an array column to "N" and then SELECT a literal "Y" over it only
	-- where there is non-null blob data.  Use of ROWID makes these
	-- SELECTs go very quickly.

	let cat_rows[cat_cnt].has_pic = "N"
	select "Y" into cat_rows[cat_cnt].has_pic
		from catalog
		where rowid = cat_rids[cat_cnt]
		and cat_picture is not null

	let cat_rows[cat_cnt].has_desc = "N"
	select "Y" into cat_rows[cat_cnt].has_desc
		from catalog
		where rowid = cat_rids[cat_cnt]
		and cat_descr is not null

	let cat_cnt = cat_cnt + 1
	if cat_cnt > 200 then -- make sure we don't run overfill arrays
		exit foreach
	end if
end foreach

let cat_cnt = cat_cnt - 1 	-- actual number of rows loaded
if cat_cnt = 0 then 		-- some error opening cursor or on first fetch
	error "Sorry, unable to read from the catalog table."
	sleep 3
	exit program
end if

	-- ////////////////////////////////////////////////////////////////
	-- ///// INITIALIZE GRAPHICS-DEPENDENT ITEMS...
	-- ////////////////////////////////////////////////////////////////

 -- <-- curly brace here disables the X/Motif/openwin code!

-- The following code is for HP Motif 1.1 and OpenWindows and should work for other
-- X-windows / Motif 1.1 systems xwd formats. blobshow.sh is a small shell program
-- that manages the calling of a system-level window display utility,
-- in this case xwud. See comments in blobshow.sh for additional details.
--
-- For xwud change the parameters passed to the -geometry option to adjust the size
-- of the image and its location.

let showpic = "blobshow.sh xwud '-geometry =550x425+550+400 -in' ", picfname clipped

-- later, when we "run showpic" the entire command string will be executed and
-- the blob image will appear in its own window. (And you didn't believe in magic!)

 -- <-- curly brace here closes out the disabled X/Motif/Openwin code!
 
{ -- <-- curly brace here disables other graphic-dependent code
 
 -- if you want to do a version for SunTools or some other GUI, here a
 -- good place to put the graphic-dependent code
 
} -- <-- curly brace here closes out disabled X/Motif/openwin code

	-- ////////////////////////////////////////////////////////////////
	-- ///// Open all the 4GL windows we will use, main window last
	-- ////////////////////////////////////////////////////////////////

open window varc_win at 15, 5 with 11 rows, 68 columns attribute(border)
open window text_win at 4, 4 with 24 rows, 72 columns attribute(border)
	
open window pict_win at 21, 5 with 6 rows, 72 columns
		attribute(border,COMMENT LINE FIRST)

open window main_win at 1, 1 with 33 rows, 79 columns

	-- ////////////////////////////////////////////////////////////////
	-- ///// Use DISPLAY ARRAY to display the contents of the arrays
	-- ///// and let the user scroll around. 
	-- ////////////////////////////////////////////////////////////////

display form main_bd

	-- tell 4GL the number of rows so display-array won't run off end
call set_count(cat_cnt)

display array cat_rows to scroller.*

	on key (control-E)
      		call kill_show()
		exit display

	-- the following functions make other windows current. 
	
	on key (control-V)
		call show_varc(arr_curr())

	on key (control-T)
		call show_text(arr_curr())

	on key (control-P)
		call show_pict(arr_curr())

end display

free picblob	-- free temp file
call kill_show()

end main

-- ////////////////////////////////////////////////////////////////////////
-- //// The show_varc() function uses the varc_win to display and update
-- //// the varchar value, catalog.cat_advert.
-- ////////////////////////////////////////////////////////////////////////

function show_varc(rownum)
	define rownum integer
	define flag smallint
	define adv LIKE catalog.cat_advert
	define xu, xn char(2)

	current window is varc_win
	options comment line last
	display form varc_bd
	display cat_rows[rownum].catalog_num,
		cat_rows[rownum].description,
		cat_rows[rownum].manu_name
	to	catalog_num, description, manu_name
	let adv = cat_adv[rownum]
	let xn = "__"
	let xu = "__"
	let flag = 0
	input adv,xn,xu without defaults from cat_advert, xn, xu
		before field cat_advert
			let flag = 0
		before field xn
			let flag = 1
		before field xu
			let flag = 2
		after field xu
			next field cat_advert
		on key(ESC,control-E)
			exit input
		on key(control-B)
			open window dialog at 2,2 with 5 rows, 40 columns
				attribute(border)
		      display "control-A switches insert/overtype mode" at 2,1
		      display "control-X deletes one character" at 3,1
		      display "control-D deletes to end of line" at 4,1
		      display "arrow keys move cursor" at 5,1
			call dispwait("return key goes to next field")
			close window dialog
			current window is varc_win
	end input
	if flag = 2 then -- user wants to update field
		if transact = "W" then
			begin work
		end if
		update catalog set cat_advert = adv
			where rowid = cat_rids[rownum]
		if status = 0 then
			if transact = "W" then
				commit work
			end if
			let cat_adv[rownum] = adv
			message "Your varchar has been updated!" 
				ATTRIBUTE (REVERSE)
			sleep 2
                        message ""      -- clear message
		else
			call upd_err()
		end if
	end if
	current window is main_win
end function

-- ////////////////////////////////////////////////////////////////////////
-- //// The show_text() function uses the text_win to display and update
-- //// the text value, catalog.cat_descr.  Note that if the text column
-- //// is null in this row, a null will be selected and displayed, and
-- //// if the user puts in data and updates, it will be null no more.
-- ////////////////////////////////////////////////////////////////////////

function show_text(rownum)
	define rownum integer
	define flag smallint
	define xu, xn char(2)

	current window is text_win
	options comment line last
	display form text_bd
	display cat_rows[rownum].catalog_num,
		cat_rows[rownum].description,
		cat_rows[rownum].manu_name
	to	catalog_num, description, manu_name
	select cat_descr into txtblob from catalog
		where rowid = cat_rids[rownum]
	let xn = "__"
	let xu = "__"
	let flag = 0
	input txtblob,xn,xu without defaults from cat_descr, xn, xu
		before field cat_descr
			let flag = 0
		before field xn
			let flag = 1
		before field xu
			let flag = 2
		after field xu
			next field cat_descr
		on key(ESC,control-E)
			exit input
	end input
	if flag = 2 then -- user wants to update field
		if transact = "W" then
			begin work
		end if
		update catalog set cat_descr = txtblob
			where rowid = cat_rids[rownum]
		if status = 0 then
			if transact = "W" then
				commit work
			end if
			message "Your text blob has been updated!"
				ATTRIBUTE (REVERSE)
			sleep 2
                        message ""    -- clear message
		else
			call upd_err()
		end if
	end if
	current window is main_win

end function

-- ////////////////////////////////////////////////////////////////////////
-- //// The show_pict() function uses the pict_win to display and update
-- //// the picture value (i.e., the byte field), catalog.cat_picture.    
-- ////////////////////////////////////////////////////////////////////////

function show_pict(rownum)
	define rownum integer
	define flag smallint
	define xu, xn char(2)

	if process_var = 1 then -- a previous picture is still visible
		call kill_show()
		let process_var = 0
	end if
	current window is pict_win
	display form pict_bd
	display cat_rows[rownum].catalog_num,
		cat_rows[rownum].description,
		cat_rows[rownum].manu_name
	to	catalog_num, description, manu_name

	if cat_rows[rownum].has_pic = "N" then
		open window dialog at 15,15 with 4 rows, 60 columns
			attribute(border,prompt line last-1)
		display "This catalog entry has no picture." at 2,2
		prompt  " Do you want to supply one? (y/n) " for answer
		if not answer[1,1] matches "[Yy]" then
			close window dialog
			current window is main_win
			return
		end if
		display "Enter the full pathname of an image file." at 2,2
		prompt " " for answer
		close window dialog
--> the essence of blobload is on the next three lines
		locate picblob in file answer
		update catalog set cat_picture = picblob
			where rowid = cat_rids[rownum]
			
		if status = 0 then
			let cat_rows[rownum].has_pic = "Y"
		else
			call upd_err()
			current window is main_win
			return
		end if
	end if 		-- if we get here, there is a picture in this row
	let process_var = 1
	message "Locating blob image, one moment please!"
		ATTRIBUTE (BLINK, BOLD, UNDERLINE, REVERSE)
	locate picblob in file picfname
	select cat_picture into picblob from catalog
		where rowid = cat_rids[rownum]
 	run showpic 		-- this is what it's all about
	message ""		-- clear message
				-- here's the place to swap image files
	let xn = "__"
	let xu = "__"
	let flag = 0
	input xn,xu without defaults from xn, xu
		before field xn
			let flag = 1
		before field xu
			let flag = 2
		after field xu
			next field xn
		on key(ESC,control-E)
			exit input
	end input
	if flag = 2 then -- user wants to update picture?
		open window dialog at 15,15 with 4 rows, 60 columns
			attribute(border,prompt line last-1)
		prompt " Do you want to use a different picture? (y/n) "
								for answer
		if not answer[1,1] matches "[Yy]" then
			close window dialog
			current window is main_win
			return
		end if
		call kill_show()
		display "Enter the pathname of an image file." at 2,2
		prompt " " for answer
		close window dialog
		
		-- note the following does not set a nonzero status code
		-- even if the pathname is garbage!  so the LOCATE does
		-- not supply a way of validating the pathname.
		locate picblob in file answer
		if transact = "W" then
			begin work
		end if
		update catalog set cat_picture = picblob
				where rowid = cat_rids[rownum]
		if status = 0 then
			if transact = "W" then
				commit work
			end if
			message "Your blob image has been updated!"
					ATTRIBUTE (REVERSE)
			sleep 2
			message ""
		else
			call upd_err()
		end if
	end if -- update
	current window is main_win
end function

-- ////////////////////////////////////////////////////////////////////////
-- /////	Miscellaneous functions
-- ////////////////////////////////////////////////////////////////////////
function set_up_cat()
			-- this function reloads the catalog table if necessary
define idir char(128)	-- holds current INFORMIXDIR environment value

	let j = 0
	select count(*) into j
		from catalog
		where cat_picture is not null
	if sqlca.sqlcode <> 0 then
		error "Error ",sqlca.sqlcode," accessing the catalog table."
		sleep 3
		exit program
	end if
	if j > 0 then 	-- there are already pictures in the table
		return
	end if
	options prompt line 9
	open window dialog at 5,10 with 10 rows, 64 columns
			attribute(border)
	display "The catalog table has only nulls in the cat_picture column."
				at 2,2
	display "The program works without pictures for the text and varchar"
				at 3,2
	display "columns, and can be used to install images in cat_picture."
				at 4,2
	display "But we can reload catalog so that 10 rows contain xwd images."
				at 6,2
	display "Do you want to replace all rows in the catalog table?"
				at 7,2
	prompt "   (Y/N) " for answer
	if not answer[1,1] matches "[yY]" then
		close window dialog
		return
	end if
	clear window dialog
-- the following assignment has to produce a valid pathname. why?
-- because we are executing a 4gl program and have already successfully
-- opened a database! 
	let idir = fgl_getenv("INFORMIXDIR")
	if idir is NULL then
	    let idir = "/usr/informix"
	end if
	let idir = idir clipped, "/demo/fgl/catalog_b.unl"

   display "Please specify the pathname of file catalog_b.unl, which was"
				at 2,2
   display "distributed in the /demo/fgl subdirectory of the Informix"
				at 3,2
   display "distribution directory."
				at 4,2
   display " " at 5,2 
	display "Just press return to use the current INFORMIXDIR, as follows:"
				at 6,2
	display "   ",idir	at 7,2
	display "Otherwise enter a path to the file."
				at 8,2
	prompt "path: " for answer
	if length(answer) = 0 then
		let answer = idir
	end if
	clear window dialog
	display "Clearing all rows from the catalog table..."
				at 2,2
	delete from catalog -- deleting all rows
	if sqlca.sqlcode <> 0 then
		display "Sorry, error ",sqlca.sqlcode, "deleting rows."
				at 3,2
		exit program
	else
		display "Catalog table cleared."
				at 4,2
	end if
	display "loading catalog table rows from:"
				at 6,2
	display "   ",answer	at 7,2
	load from answer insert into catalog
	if sqlca.sqlcode <> 0 then
		if sqlca.sqlcode -805 then -- could not find file
	display "Sorry, the LOAD command was unable to open the above file."
				at 8,2
		else
	display "Error ",sqlca.sqlcode," loading table."
		end if
		error "Error loading table - rerun program."
		sleep 5
		exit program
	end if
	close window dialog
end function
		
function upd_err()
	-- this function reports an error if one occurs during update
	define scode, icode integer
	let scode = sqlca.sqlcode
	let icode = sqlca.sqlerrd[2] -- isam error code
	if transact = "W" then
		rollback work
	end if
	open window dialog at 4,20 with 4 rows, 50 columns
				attribute(border)
	display "Update failed, sql code ",scode,", isam code ",icode
		at 3, 2
	display "Database not changed." at 4, 2
	prompt "Press return to continue" for answer
	close window dialog
end function

function dispwait(txt)
	-- displays message and waits for user acknowledgment
	define txt char(40)
	prompt txt clipped for answer
end function

function get_user()
	-- gets userID
	-- Use sa dummy select on systables to return the
	-- current userid string.
	define u character(18)
	select user into u from systables where tabid=100
	return u clipped
end function

-- return a pathname to what we hope is a unique filename in /tmp.
-- the form of the name is /tmp/userid.ssfff.suffix, where ssfff
-- is the time of creation, and suffix is passed as a parameter.

function make_tmp_fname(suffix)
	-- creates a temporary file name for BLOB image file
	define  suffix character(8),
		f character(64),
		t character(8)
	let t = extend(current,second to fraction)
	let f = "/tmp/",get_user(),".",t[1,2],t[4,6],".",suffix
	return f clipped
end function

-- close the window currently displaying a blob image

function kill_show()
	-- runs a temporary file created automatically by blobshow.sh that
	-- removes a displayed image from the screen
	if process_var !=0 then
		run "/tmp/kill.sh"
	end if
end function
