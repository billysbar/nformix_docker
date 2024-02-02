-- ************************************************************************** 
-- *  Licensed Materials - Property of IBM                                  * 
-- *                                                                        * 
-- *  "Restricted Materials of IBM"                                         * 
-- *                                                                        * 
-- *  IBM Informix 4GL                                                      * 
-- *  Copyright IBM Corporation 2008. All rights reserved.                  * 
-- *                                                                        * 
-- ************************************************************************** 
-- **************************************************************************
-- 
--   Title      : mki4glsoa.4gl
--   Description: 4gl program to create i4glsoa database & table
-- 
-- **************************************************************************
-- 
--   Prototype:    mki4glsoa { -c | -d } [dbname] [string]
--       where:    -c => create demo database
--                 -d => drop demo database
--                 [dbname] => demo database name (default = "i4glsoa")
--                 [string] => An optional quoted string which may have the
--                             with log option or name of dbspace in which 
--                             demo database is to be built.
-- 
--          eg: create database db in rootdbs with log
--                              The string can appear only with '-c' option.
-- 
-- **************************************************************************

MAIN

    DEFINE argval1 CHAR(2),  dbname CHAR(40), dbstr CHAR(560)
    DEFINE len INT

    IF  num_args() > 1 THEN
        LET dbname = arg_val(2)
    ELSE
        LET dbname = "i4glsoa"
    END IF

    LET argval1 = downshift(arg_val(1))

    IF  argval1 = "-d" THEN

        WHENEVER ERROR CONTINUE
        DROP DATABASE dbname
        IF sqlca.sqlcode = -329     {database not there to drop}
        OR sqlca.sqlcode = 0 THEN     {dropped successfully}
           EXIT PROGRAM(0)
        ELSE
           EXIT PROGRAM(1)
        END IF
        WHENEVER ERROR STOP
    ELSE
        IF  argval1 = "-c" 
        THEN
            IF num_args() == 3
            THEN
                LET len = LENGTH(arg_val(3))
                IF len > 560 { 560 = 512 + "create database" + "with log" + ...}
                THEN
                    DISPLAY "The total length of arguments to the demo script should not exceed 512 bytes"
                    EXIT PROGRAM(1)
                END IF

                LET dbstr = arg_val(3)

                PREPARE pid from dbstr
                IF sqlca.sqlcode <> 0
                THEN
                    EXIT PROGRAM(1)
                END IF

                EXECUTE pid
                IF sqlca.sqlcode <> 0
                THEN
                    EXIT PROGRAM(1)
                END IF

                FREE pid
            ELSE
                CREATE DATABASE dbname     { If string option is not used }
            END IF

        
            CREATE TABLE statedetails
            (
                pin char(10),
                city char(100),
                state char(100)
            );

            GRANT RESOURCE TO PUBLIC

        ELSE
            EXIT PROGRAM(1)
        END IF
    END IF

    EXIT PROGRAM(0)
END MAIN
