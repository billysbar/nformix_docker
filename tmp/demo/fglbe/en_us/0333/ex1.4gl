
#######################################################################
# APPLICATION: Example 1 - 4GL Examples Manual                        # 
#                                                                     # 
# FILE: ex1.4gl                             FORM: f_logo.per          # 
#                                                                     # 
# PURPOSE: This program demonstrates the implementation of an         #
#          application logo: a screen which displays the name of      #
#          the application being started.                             #
#                                                                     # 
# STATEMENTS:                                                         # 
#          MAIN		          FUNCTION            OPEN FORM       #
#          DEFINE	          CALL  	      DISPLAY FORM    #
#          DISPLAY                SLEEP                               #
#                                                                     # 
# FUNCTIONS:                                                          #
#    dsply_logo(sleep_secs) - displays an application logo contained  #
#       in the f_logo form file. The logo displays for "sleep_secs"   #
#       number of seconds.                                            #
#                                                                     #
# MODIFICATION HISTORY:                                               #
#  date        programmer      change                                 #
#  --------    ----------      -------------------------------------- #
#  02/14/91    dam             Updated header                         #
#  12/27/90    dam             Created file ex1.4gl                   #
#######################################################################

########################################
MAIN
########################################

  CALL dsply_logo(3)
END MAIN

#######################################
FUNCTION dsply_logo(sleep_secs)
#######################################
--* Purpose: Displays an application logo on the screen for a 
--*            specified number of seconds.
--* Form: f_logo.per
--* Argument(s): sleep_secs - number of seconds to display logo
--* Return Value(s): NONE
---------------------------------------
  DEFINE sleep_secs	SMALLINT,

  	 thedate 	DATE

--* Open the f_logo form (allocate resources) and display the form
--*  on the screen
------------------------
  OPEN FORM app_logo FROM "f_logo"
  DISPLAY FORM app_logo

  DISPLAY " IBM INFORMIX-4GL By Example Application" AT 2,15
    ATTRIBUTE (REVERSE, GREEN)

--* Initialize the application date then display it in the appdate
--*   field on the f_logo form.
------------------------
  LET thedate = TODAY
  DISPLAY thedate TO formonly.appdate

--* Pause execution for "sleep_secs" seconds so that the f_logo form 
--*   remains on the screen.
------------------------
  SLEEP sleep_secs
  CLOSE FORM app_logo
  
END FUNCTION  -- dsply_logo --

