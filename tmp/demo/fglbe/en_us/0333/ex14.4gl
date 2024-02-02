
#######################################################################
# APPLICATION: Example 14 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex14.4gl                            FORM: none                # 
#                                                                     # 
# PURPOSE: This program illustrates how to send data to a simple      #
#          report. It also contains the report function for formatting#
#          the data.                                                  #
#                                                                     # 
# STATEMENTS:                                                         # 
#          FOREACH INTO           FINISH REPORT       ON EVERY ROW    # 
#          START REPORT           REPORT              PAGE HEADER     # 
#          OUTPUT TO REPORT                                           # 
#                                                                     # 
# FUNCTIONS:                                                          #
#    manuf_listing() - gathers and sends the manufacturer data to the #
#      report.                                                        #
#    init_msgs() - see description in ex2.4gl file.                   #
#    prompt_window(question,x,y) - see description in ex4.4gl file.   #
#    manuf_rpt() - report function to format data.                    #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated file header                    #
#  01/22/91    dam             Created Example 14                     #
#######################################################################

DATABASE stores2

GLOBALS
# This array is used by init_msgs(), message_window(), and 
#  prompt_window() to allow the user to display text in a 
#  message or prompt window. 
  DEFINE	ga_dsplymsg ARRAY[5] OF CHAR(48)
END GLOBALS

########################################
MAIN
########################################

  LET ga_dsplymsg[1] = "           Manufacturer Listing Report"
  IF prompt_window("Do you want to display this report?", 5, 10)
  THEN
    CALL manuf_listing()     -- report driver function
  END IF
END MAIN

########################################
FUNCTION manuf_listing()
########################################
--* Purpose: Starts report and then sends manufact rows to report,
--*            one at a time.
--* Argument(s): NONE
--* Return Value(s): NONE
---------------------------------------
  DEFINE	pa_manuf  RECORD
			  	manu_code 	LIKE manufact.manu_code,
			  	manu_name 	LIKE manufact.manu_name,
			  	lead_time 	LIKE manufact.lead_time
			  END RECORD

--* Cursor c_manuf will contain all manufact rows, ordered by code
  DECLARE c_manuf CURSOR FOR
    SELECT manu_code, manu_name, lead_time
    FROM manufact
    ORDER BY manu_code

--* Start up manuf_rpt report and send output to screen
  START REPORT manuf_rpt

--* Send each manufact row to report manuf_rpt
  FOREACH c_manuf INTO pa_manuf.*
    OUTPUT TO REPORT manuf_rpt(pa_manuf.*)
  END FOREACH

--* Finish report manuf_rpt
  FINISH REPORT manuf_rpt

END FUNCTION  -- manuf_listing --

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
REPORT manuf_rpt(pa_manuf)
########################################
--* Purpose: Report function to create a manufacturer listing.
--* Argument(s): pa_manuf - record containing single manufact row
--* Return Value(s): NONE
---------------------------------------
  DEFINE	pa_manuf  RECORD
			  	manu_code 	LIKE manufact.manu_code,
			  	manu_name 	LIKE manufact.manu_name,
			  	lead_time 	LIKE manufact.lead_time
			  END RECORD

--* Establish report margins and page defaults
  OUTPUT
    LEFT MARGIN 0
    RIGHT MARGIN 0
    TOP MARGIN 1
    BOTTOM MARGIN 1
    PAGE LENGTH 23

  FORMAT
    PAGE HEADER
--* Provide a report header with name of report, date, and screen
--*   number (like page number)
------------------------
      SKIP 3 LINES
      PRINT COLUMN 30, "MANUFACTURER LISTING"
      PRINT COLUMN 31, TODAY USING "ddd. mmm dd, yyyy"
      PRINT COLUMN 31, "Screen Number: ", PAGENO USING "##&"
      SKIP 5 LINES

--* Provide headers for data columns
      PRINT COLUMN 2, "Manufacturer",
	    COLUMN 17, "Manufacturer",
	    COLUMN 34, "Lead Time"
      PRINT COLUMN 6, "Code",
	    COLUMN 21, "Name",
	    COLUMN 36, "(in days)"
      PRINT "----------------------------------------";
      PRINT "----------------------------------------"
      SKIP 1 LINE

    ON EVERY ROW
--* Print manufacturer info for a single row
      PRINT COLUMN 6, pa_manuf.manu_code,
	    COLUMN 16, pa_manuf.manu_name,
	    COLUMN 36, pa_manuf.lead_time

    PAGE TRAILER
--* At end of each screen, tell user how to continue on.
      SKIP 1 LINE
      PAUSE "Press RETURN to display next screen."

END REPORT  -- manuf_rpt --
