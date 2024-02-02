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
#  Title:	4glusr.msg
#  Sccsid:	@(#)4glusr.msg /main/development/2 04/23/96 17:50:02 
#  Description
# 		4gl run-time messages which may be modified by the user
#
#**************************************************************************

.-1301
 This value is not among the valid possibilities 
.-1302
 The two entries were not the same -- please try again 
.-1303
 You cannot use this editing feature because a picture exists 
.-1304
 Error in field 
.-1305
 This field requires an entered value 
.-1306
 Please type again for verification 
.-1307
 Cannot insert another row - the input array is full 
.-1308
 Cannot delete row - it has no data 
.-1309
 There are no more rows in the direction you are going 
.-1312
FORMS statement error number %d.
.-1313
SQL statement error number %d.
.-1314
Program stopped at "%s", line number %d.
.-1315
4GL run-time error number %d.
.-1316
ISAM error number %d.
.-1317
A numeric conversion error has occurred due to incompatibility 
between a calling program and its function parameters or 
between a variable and its assigned expression.
.-1318
A parameter count mismatch has occurred between the calling 
function and the called function.
.-1319
The 4GL program has run out of runtime data space memory.
.-1320
A function has not returned the correct number of values 
expected by the calling function.
.-1321
A validation error has occurred as a result of the VALIDATE command.
.-1322
A report output file cannot be opened.
.-1323
A report output pipe cannot be opened.
.-1324
A report output file cannot be written to.
.-1325
A report PRINT FILE source file cannot be opened for reading.
.-1326
An array variable has been referenced outside of its specified 
dimensions.
.-1327
An insert statement could not be prepared for inserting rows
into a temporary table used for a report.
.-1328
A temporary table needed for a report could not be created in
the selected database.  The user must have permission to 
create tables in the selected database, and there must be no 
existing table named "t_<reportname>" already in the database.
.-1329
A database index could not be created for a temporary database
table needed for a report.  There must be no existing index 
named "i_<reportname>" already in the database.
.-1330
A row could not be inserted into a temporary report table.
.-1331
A row could not be fetched from a temporary report table.
.-1332
A character variable has referenced subscripts that are out 
of range. 
.-1333
Strings of length > 512 cannot be returned from function calls.
.-1334
The 4GL program cannot allocate any more space for temporary 
string storage.
.-1335
A report is accepting output or being finished before it 
has been started.
.-1336
The pcode compiled from module "%s" is pcode version %d, which is
incompatible with and cannot be executed by this 4GL-RDS pcode 
runner.  Recompile all .4gl modules in this program with a current
version of the pcode compiler (fglpc).
.-1337
The variable "%s" has been redefined with a different 
type or length.
.-1338
The function "%s" has not been defined in any module in 
the program.
.-1339
 Global variable "%s" cannot be found in the descriptor table.
.-1340
 The error log has not been started.
.-1343
 No help file specified 
.-1344
 INFORMIX-4GL Run Time Facility
.-1345
 Undefined opcode.  Please recompile with a compatible version of fglpc.
.-1346
 Number is too large for a DECIMAL data type
.-1347
 Number is too small for a DECIMAL data type
.-1348
 An attempt was made to divide by zero.
.-1349
 Character to numeric conversion error.
.-1350
 It is not possible to convert between the specified types.
.-1351
The function (or report) "%s" has already been defined.  Function
and report cannot both have the same name.
.-1352
'%s' may not be used as both a function (or report) name and a variable name.
.-1353
 Use '!' to edit TEXT and BYTE fields.
.-1355
 Cannot build temporary file.
.-1356
 Write error on temporary file "%s"
.-1357
 Read error on temporary file "%s"
.-1358
 Write error on blob file "%s"
.-1359
 Read error on blob file "%s"
.-1360
 No "PROGRAM=" clause for this field.
.-1361
 Illegal blob file name.  Null names are not permitted.
.-1371
The field "%s" does not exist in the current form.
.-1372
The number entered is too large to fit in the decimal or money variable.
.-1373
The field "%s" is not in the list of fields in the CONSTRUCT/INPUT
statement.
#
# SQL Warning message errors for warnings 1 -> 5
#
.-1374
SQL character truncation or transaction warning.
.-1375
SQL NULL value in aggregate or mode ANSI database warning.
.-1376
SQL Informix-OnLine or program variable mismatch warning.
.-1377
SQL float-to-decimal conversion warning.
.-1378
SQL non-ANSI extension warning.
.-1379
Report functions may not be called directly.  Please use the
OUTPUT TO REPORT statement.
# Needed string filled version of sql.msg error -852
.-1380
Write failed. %s rows unloaded (check ulimit or disk space). See error -852.
.-1382
SIGXFSZ received by the process. Exceeded file size limit.
.-1383
SIGXCPU received by the process. Exceeded CPU time limit.
.1310
Program error at "%s", line number %d.
.1311
Date: %s    Time: %s
.1341
You have reached the end of this help text. Press RETURN to continue.
.1342
HELP
Screen
Displays the next page of Help text.
Resume
Ends this Help session.
.1354
<byte value>
.1362
Loading
.1363
Unloading
.1364
startlog function
.1365
errorlog function
.1366
length function
.1367
upshift function
.1368
downshift function
.1369
num_args function
.1370
arg_val function
.1371
fgl_lastkey function
.1372
fgl_getenv function
.1373
fgl_keyval function
.1374
fgl_startlog function
.1375
fgl_errorlog function
.1376
cursor_name function
.1377
err_print function
.1378
err_get function
.1379
err_quit function
.1380
showhelp function
.1381
fgl_putfldbuf function
.1382
fgl_getfldbuf function
.1383
fgl_currfield function
.1384
fgl_nextfield function
.-1385
You can only use this function within an INPUT, INPUT ARRAY,
or CONSTRUCT statement.
.-1386
This feature is not available in this release.
.-1387
fgl_getkey function
.-1390
Reserved for Informix-NewEra.
.-1391
Reserved for Informix-NewEra.
.-1392
Reserved for Informix-NewEra.
.-1393
Reserved for Informix-NewEra.
.-1394
Reserved for Informix-NewEra.
.-1395
Reserved for Informix-NewEra.
.-1396
Reserved for Informix-NewEra.
.-1397
Reserved for Informix-NewEra.
.-1398
Reserved for Informix-NewEra.
.-1399
Reserved for Informix-NewEra.
