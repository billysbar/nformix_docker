#**************************************************************************
#
#			   INFORMIX SOFTWARE, INC.
#
#			      PROPRIETARY DATA
#
#	THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF 
#	INFORMIX SOFTWARE, INC.  THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
#	CONFIDENCE.  INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR 
#	DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT 
#	SIGNED BY AN OFFICER OF INFORMIX SOFTWARE, INC.
#
#	THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
#	SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE. 
#	UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
#
#
#  Title:	mkstore4.4gl
#  Sccsid:	@(#)mkstore4.4gl	10.1	1/16/94	22:51:21
#  Description:
#		4gl program to create stores database & tables.
#
#**************************************************************************
#
#    Prototype:    mkstore4 { -c | -d } [dbname] [string]
#        where:    -c => create demo database
#                  -d => drop demo database
#                  [dbname] => demo database name (default = "stores")
#                  [string] => An optional quoted string which may have the
#							   with log option or name of dbspace in which 
#                              demo database is to be built.
#								eg: create database db in rootdbs with log
#   						   The string can appear only with '-c' option.
#

MAIN

    DEFINE argval1 CHAR(2),  dbname CHAR(40), dbstr CHAR(560)
    DEFINE len INT

    IF  num_args() > 1 THEN
        LET dbname = arg_val(2)
    ELSE
        LET dbname = "stores"
    END IF

    LET argval1 = downshift(arg_val(1))

    IF  argval1 = "-d" THEN

        WHENEVER ERROR CONTINUE
        DROP DATABASE dbname
        IF sqlca.sqlcode = -329 	{database not there to drop}
        OR sqlca.sqlcode = 0 THEN 	{dropped successfully}
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

            CREATE TABLE customer 
                (
                customer_num	SERIAL(101),
                fname		CHAR(15),
                lname		CHAR(15),
                company		CHAR(20),
                address1	CHAR(20),
                address2	CHAR(20),
                city		CHAR(15),
                state		CHAR(2),
                zipcode		CHAR(5),
                phone		CHAR(18)
                )
        
            CREATE TABLE orders
                (
                order_num	SERIAL(1001),
                order_date	DATE,
                customer_num	INTEGER,
                ship_instruct	CHAR(40),
                backlog		CHAR(1),
                po_num		CHAR(10),
                ship_date	DATE,
                ship_weight	DECIMAL(8,2),
                ship_charge	MONEY(6),
                paid_date	DATE
                )
        
            CREATE TABLE items
                (
                item_num		SMALLINT,
                order_num		INTEGER,
                stock_num		SMALLINT,
                manu_code		CHAR(3),
                quantity		SMALLINT,
                total_price		MONEY(8)
                )
        
            CREATE TABLE stock
                (
                stock_num		SMALLINT,
                manu_code		CHAR(3),
                description		CHAR(15),
                unit_price		MONEY(6),
                unit			CHAR(4),
                unit_descr		CHAR(15)
                )
        
            CREATE TABLE manufact
                (
                manu_code		CHAR(3),
                manu_name		CHAR(15)
                )
        
            CREATE TABLE state
                   (
                code			CHAR(2),
                sname			CHAR(15)
                )
        
            CREATE TABLE syscolatt
                (
                tabname			CHAR(18),
                colname			CHAR(18),
                seqno			SERIAL,
                color			SMALLINT,
                inverse			CHAR(1),
                underline		CHAR(1),
                blink			CHAR(1),
                left			CHAR(1),
                def_format		CHAR(64),
                condition		CHAR(64)
                )
        
            CREATE UNIQUE INDEX c_num_ix ON customer (customer_num)
            CREATE INDEX zip_ix ON customer (zipcode)
        
            CREATE UNIQUE INDEX o_num_ix ON orders (order_num)
            CREATE INDEX o_c_num_ix ON orders (customer_num)
        
            CREATE INDEX i_o_num_ix ON items (order_num)
            CREATE INDEX st_man_ix ON items (stock_num, manu_code)
        
            CREATE UNIQUE INDEX stk_man_ix ON stock (stock_num, manu_code)
        
            CREATE UNIQUE INDEX man_cd_ix ON manufact (manu_code)
        
            CREATE UNIQUE INDEX st_x1 on state (code);

            CREATE INDEX sysacomp ON syscolatt (tabname, colname, seqno)
            CREATE INDEX sysatabname ON syscolatt (tabname)

            GRANT RESOURCE TO PUBLIC

        ELSE
            EXIT PROGRAM(1)
        END IF
    END IF

    EXIT PROGRAM(0)

END MAIN
