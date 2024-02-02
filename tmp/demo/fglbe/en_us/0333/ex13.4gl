
#######################################################################
# APPLICATION: Example 13 - 4GL Examples Manual                       # 
#                                                                     # 
# FILE: ex13.4gl                        FORM: f_name.per              #
#                                       ASSOCIATED FILES: ex13a.4gl   #
#                                                         ex13i.sh    #
#                                                         ex13r.sh    #
#                                                                     # 
# PURPOSE: This program is the front-end for Example 13. It provides  #
#          the user with a menu to indicate which system is being     #
#          used: r4gl or i4gl. This information is needed to determine#
#          how to execute the 4GL program that uses the C function.   #
#          The program then displays a menu allowing the user to      #
#          choose which file to read: an ASCII file or standard input #
#          (stdin). Reading from ASCII file causes the program to run #
#          the ex13a.4gl file with a single argument: the name of the #
#          file to read. Reading from stdin causes the program to run #
#          the ex13a.4gl file with no arguments.                      #
#                                                                     # 
# STATEMENTS:                                                         # 
#          RUN                                                        # 
#          NUM_ARGS() built-in function                               # 
#          ARG_VAL() built-in function                                # 
#                                                                     # 
# FUNCTIONS:                                                          #
#   get_fname() - allows the user to enter the name of the file to    #
#     read.                                                           #
#   clear_lines(numlines, mrow) - see description in ex6.4gl file.    #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/27/91    dam             added front-end to program             #
#  02/14/91    dam             updated file header                    #
#  12/27/90    dec             initial draft                          #
#######################################################################

########################################
MAIN
########################################
  DEFINE 	fname 		CHAR(50),
		cmd_line	CHAR(70),
		sys_type	CHAR(1)

      
  OPEN WINDOW w_cfuncs AT 3,3
    WITH 15 ROWS, 76 COLUMNS
    ATTRIBUTE (BORDER)

--* Menu prompts user for which 4GL system they are using: RDS or 4GL
--*   This info is needed to create the command to invoke the 
--*   4GL program which contains a C function.
------------------------
  MENU "Which system?"
    COMMAND "r4gl" "Run the example as p-code 4GL."
      LET sys_type = "R"
      EXIT MENU
    COMMAND "i4gl" "Run the example as compiled 4GL."
      LET sys_type = "I"
      EXIT MENU
  END MENU

--* Display summary of program on screen
  DISPLAY "Reading ASCII files with a C function"
    AT 4, 20
  DISPLAY "This program uses a C function called fglgets() for reading stream"
    AT 6, 2
  DISPLAY "   input. The function uses the fgets() function from the standard"
    AT 7, 2
  DISPLAY "   C library.  The fglgets() function can read input from either"
    AT 8, 2
  DISPLAY "   existing ASCII files or from stdin (standard input). This program"
    AT 9, 2
  DISPLAY "   just displays the data it reads back on the screen.  However, "
    AT 10, 2
  DISPLAY "   the program could be modified to use the data in other ways. "
    AT 11, 2
  DISPLAY "   Reading from ASCII files allows the program to access data stored"
    AT 12, 2
  DISPLAY "   in files. Reading from stdin allows the program to act as a UNIX"
    AT 13, 2
  DISPLAY "   filter."
    AT 14, 2

--* Menu prompts user for which type of file to read: ASCII or stdin
--*   The C function can be called with no arguments (to read from
--*   stdin) or with a file name as an argument.
------------------------
  MENU "Read File"
    COMMAND "ASCII" "Read in from an ASCII file."
      CALL clear_lines(11, 4)
--* Accept user input of file name
      CALL get_fname() RETURNING fname
      CLEAR WINDOW w_cfuncs
      IF fname IS NOT NULL THEN
--* If using RDS (r4gl), must call ex13a with a special "runner": fglgo13
	IF sys_type = "R" THEN
          LET cmd_line = "fglgo13 ex13a ", fname CLIPPED
	ELSE
--* If using 4GL (i4gl), must call ex13a directly as a .4ge file 
          LET cmd_line = "ex13a.4ge ", fname CLIPPED
	END IF
--* Invoke ex13a as a separate operating system process
        RUN cmd_line
      END IF

    COMMAND "Stdin" "Read in from Standard Input (screen)."
      CALL clear_lines(11, 4)
--* To read from standard input (stdin), the program uses a shell
--*   script. This script provides a few lines of explanation then
--*   calls ex13a.
------------------------
      IF sys_type = "R" THEN
--* If using RDS (r4gl), script calls ex13a with a special "runner": fglgo13
	LET cmd_line = "/bin/sh ex13r.sh"
      ELSE
--* If using 4GL (i4gl), script calls ex13a directly as a .4ge file 
	LET cmd_line = "/bin/sh ex13i.sh"
      END IF
      RUN cmd_line

    COMMAND KEY ("E", "e", "X", "x") "Exit" "Exit the program."
      EXIT MENU
  END MENU

  CLEAR SCREEN
END MAIN

#######################################
FUNCTION get_fname()
#######################################
--* Purpose: Accepts user input of a file name on the f_name form.
--* Argument(s): NONE
--* Return Value(s): name of file to read
--*                       OR
--*                  NULL if user ends INPUT with Cancel key
---------------------------------------
  DEFINE	fname	CHAR(50)

--* Set Message line to work with the f_name form
  OPTIONS 
    MESSAGE LINE 7

  OPEN FORM f_name FROM "f_name"
  DISPLAY FORM f_name

--* Display form title and instructions
  DISPLAY "READING FROM A FILE"
    AT 4, 20
  DISPLAY " Enter a file name and press Accept or press Cancel to exit."
    AT 8, 1  ATTRIBUTE (REVERSE, YELLOW)

--* Accept file name as input
  INPUT fname FROM a_char
    BEFORE FIELD a_char
      MESSAGE " Enter the name of the file to read."

    AFTER FIELD a_char
      IF fname IS NULL THEN
	ERROR "You must enter a file name."
	NEXT FIELD a_char
      END IF

  END INPUT

  IF int_flag THEN
    LET int_flag = FALSE
    LET fname = NULL
  END IF

  CLOSE FORM f_name
  RETURN (fname)

END FUNCTION  -- get_fname --

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


