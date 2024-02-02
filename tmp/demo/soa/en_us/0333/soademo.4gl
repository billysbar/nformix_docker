-- ************************************************************************** 
-- *  Licensed Materials - Property of IBM                                  * 
-- *                                                                        * 
-- *  "Restricted Materials of IBM"                                         * 
-- *                                                                        * 
-- *  IBM Informix 4GL                                                      * 
-- *  Copyright IBM Corporation 2009. All rights reserved.                  * 
-- *                                                                        * 
-- ************************************************************************** 

FUNCTION zipcode_details(pin)
       DEFINE state_rec RECORD 
                pin CHAR(10),
                city CHAR(100),
                state CHAR(100)
              END RECORD,

              pin CHAR(10),
              sel_stmt CHAR(512);

       LET sel_stmt= "SELECT * FROM statedetails WHERE pin = ?";

       PREPARE st_id FROM sel_stmt;
       DECLARE cur_id CURSOR FOR st_id;

       OPEN cur_id USING pin;
       FETCH cur_id INTO state_rec.*;
       CLOSE cur_id;
       FREE cur_id;
       FREE st_id;
       RETURN state_rec.city, state_rec.state

END FUNCTION
