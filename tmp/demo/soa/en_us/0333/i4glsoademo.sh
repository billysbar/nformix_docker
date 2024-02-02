: '
: **************************************************************************
: *  Licensed Materials - Property of IBM                                  *
: *                                                                        *
: *  "Restricted Materials of IBM"                                         *
: *                                                                        *
: *  IBM Informix 4GL                                                      *
: *  Copyright IBM Corporation 2001, 2009. All rights reserved.            *
: *                                                                        *
: **************************************************************************
: *************************************************************************
:
:  Title:	i4glsoademo.sh
:  Description:	Demonstration Database Installation Script for the
:               I4GL C-code.
:
: *************************************************************************
: '

# Initialization.
IDIR=${INFORMIXDIR}
LD_LIBRARY_PATH=${IDIR}/lib:${IDIR}/lib/esql:${IDIR}/lib/tools:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
DEFAULT_HOSTS=$INFORMIXDIR/etc/sqlhosts
HOSTS="$INFORMIXSQLHOSTS"
DBPATH=.
export DBPATH
DBDATE=mdy4/
export DBDATE
DBMONEY=\$.
export DBMONEY
COPY=cp
CHMOD=chmod
CC=gcc
log=no
dbspaceopt=0
db=
dbspace=
err=no 
i=
count=0
create="create database"
wlog=""
in=""
 
# Set the CLIENT_LOC & DB_LOC before database is created.
INFENV=${IDIR}/bin/infenv
DEFLOCALE=en_US.8859-1
CONVLOC=${IDIR}/bin/convloc
 
if [ "x${LOCALE}" = "x" ]; then            # LOCALE is not set -- unlikely!
    LOCALE=`$INFENV DBLANG`                # try get from DBLANG instead
    if [ "x${LOCALE}" = "x" ]; then
        LOCALE=`$INFENV CLIENT_LOCALE`     # try to default to CLIENT_LOCALE
        if [ "x${LOCALE}" = "x" ]; then
            LOCALE=`$INFENV DB_LOCALE`     # finally default to DB_LOCALE
        fi
    fi
fi

DEMOPATH=`$CONVLOC $LOCALE`

# Read the command line args & create the database.
# There are only 4 possible arguments : -log, dbname, -dbspace and dbspacename
if (test $# -gt 4)
then
        infxmsg 33410 $0
        exit 1
fi

#find out if logging or a specific dbspace or database name  is requested
for i in $*
do
    count=`expr $count + 1`
    case $i in
        -log)       if (test $log = no)
                    then
                        log=yes
                    else
                        err=wha
                    fi;;
        -dbspace)   if (test $dbspaceopt -eq 0)
                    then
                        dbspaceopt=`expr $count + 1`
                    else
                        err=wha
                    fi;;
        [a-zA-Z]*)  if (test x$dbspace = x -a $dbspaceopt -eq $count)
                    then
                        dbspace=$i
                    elif (test x$db = x)
                    then
                        db=$i
                    else
                        err=wha
                    fi;;
        -*)         err=wha
                    infxmsg 33408 $i
                    ;;
        *)          err=wha
                    infxmsg 33409
                    ;;
    esac
done   
 
if (test $err = wha)
then
        infxmsg 33410 $0
        exit 1
fi
 
# error if -dbspace w/o dbspacename
if (test x$dbspace = x -a $dbspaceopt -ne 0)
then
        infxmsg 33410 $0
        exit 1
fi

# supply default dbname if not supplied at command line.
if (test x$db = x)
then
    db=i4glsoa;
fi

if (test X$HOSTS = "X")
then
    HOSTS=$DEFAULT_HOSTS
fi

if (test X$INFORMIXSERVER = "X")
then
    infxmsg -33401
    exit 1
fi

echo "
 
IBM Informix 4GL-SOA Sample 4GL Function as Web Service Demonstration
 
"

TYPE=`awk '{ if ($1 == host) print substr($2,1,2); }' host=$INFORMIXSERVER $HOSTS`

if (test $TYPE = "se")
then
    TURBO=""
    if test -d $db.dbs
    then
	DROPIT=1
     fi
else
    TURBO=1
    DROPIT=1
fi

#export  PATH=$IDIR/demo/soa/${DEMOPATH}:$PATH


$COPY $IDIR/demo/soa/${DEMOPATH}/mki4glsoa.4gl .

$IDIR/bin/c4gl -static -nokeep -o mki4glsoa mki4glsoa.4gl

if (test $DROPIT)
then
#dropping existing database
    echo "The existing '$db' database is being dropped."
    ./mki4glsoa -d $db
    if test $? -ne 0
    then
        echo "Unable to drop existing $db database."
        exit 1
    fi
fi

#creating database
echo "The '$db' database is being created."

if (test "$TURBO" -eq 1 -a $log = yes)
then
	wlog="with log"
elif (test $TYPE = "se" -a $log = yes)
then
	logpath=`pwd`
	wlog="with log in '$logpath/$db.log'"
fi

if (test "$TURBO" -eq 1 -a $dbspaceopt -ne 0)
then
	in="in"	
fi

# create database
./mki4glsoa -c ${db} "$create $db $in $dbspace $wlog"
if test $? -ne 0
then
    echo "Unable to create $db database."
    exit 1
else
	echo "
The '${db}' database has been created.
"	
	echo "
The tables have been created.
"	
fi

rm -f ./mki4glsoa

echo "
The datafile was generated and the data is being loaded into the tables.
"

cat > statedetails.unl <<!
560071|Bangalore|KA|
97006|Beaverton|OR|
89101|Las Vegas|NV|
66219|Lenexa|KS|
!

cat > soa_load.4gl <<end_4gl
DATABASE $db
MAIN
    LOAD FROM "statedetails.unl" DELIMITER "|" INSERT INTO statedetails;
END MAIN
end_4gl

    
$IDIR/bin/c4gl -o soa_load soa_load.4gl
./soa_load

echo "

The IBM Informix 4GL-SOA demonstration programs are being copied.
"

$COPY $IDIR/demo/soa/${DEMOPATH}/soademo.4gl .
#$COPY $IDIR/demo/soa/${DEMOPATH}/client.c .
$COPY $IDIR/demo/soa/${DEMOPATH}/clsoademo.4gl .
$COPY $IDIR/demo/soa/${DEMOPATH}/clientmake makefile

$CHMOD 755 statedetails.unl
$CHMOD 755 mki4glsoa.4gl
$CHMOD 755 soa_load.4gl
$CHMOD 755 soademo.4gl
#$CHMOD 755 client.c
$CHMOD 755 clsoademo.4gl
$CHMOD 755 makefile

#$CC -o client -DMULTIPLE_OUTPUT -I${AXIS2C_HOME}/include/axis2-1.5.0 -L${AXIS2C_HOME}/lib -laxis2_engine client.c


echo "
The configuration file for the web service deployment is being generated.
"

CONFIGFILE=`pwd`/soademo.4cf

ARG_INFORMIXDIR=$IDIR
ARG_DATABASE="i4glsoa"
ARG_CLIENT_LOCALE="$LOCALE"
ARG_DB_LOCALE="$LOCALE"
ARG_INFORMIXSERVER="$INFORMIXSERVER"
ARG_HOSTNAME=`uname -n`
ARG_PORTNO=9876
ARG_WSHOME="$AXIS2C_HOME"
ARG_TMPDIR="/tmp/zipcodedemo"
ARG_SERVICENAME="ws_zipcode"
ARG_FUNCTIONNAME="zipcode_details"
ARG_DIRNAME=`pwd`
ARG_WSDLFILE="zipcode_details.wsdl"
ARG_WSDLNS="http://www.ibm.com/zipcode_details"


# create the TMPDIR
rm -rf  $ARG_TMPDIR
mkdir   $ARG_TMPDIR

echo "[SERVICE]"                                                          > $CONFIGFILE
echo "   TYPE               = publisher"                                 >> $CONFIGFILE
echo "   INFORMIXDIR        = $ARG_INFORMIXDIR"                          >> $CONFIGFILE
echo "   DATABASE           = $ARG_DATABASE"                             >> $CONFIGFILE
echo "   CLIENT_LOCALE      = $ARG_CLIENT_LOCALE"                        >> $CONFIGFILE
echo "   DB_LOCALE          = $ARG_DB_LOCALE"                            >> $CONFIGFILE
echo "   INFORMIXSERVER     = $ARG_INFORMIXSERVER"                       >> $CONFIGFILE
echo "   HOSTNAME           = $ARG_HOSTNAME"                             >> $CONFIGFILE
echo "   PORTNO             = $ARG_PORTNO"                               >> $CONFIGFILE
echo "   I4GLVERSION        = 7.50.xC3"                                  >> $CONFIGFILE
echo "   WSHOME             = $ARG_WSHOME"                               >> $CONFIGFILE
echo "   WSVERSION          = AXIS1.5"                                   >> $CONFIGFILE
echo "   TMPDIR             = $ARG_TMPDIR"                               >> $CONFIGFILE
echo "   SERVICENAME        = $ARG_SERVICENAME"                          >> $CONFIGFILE
echo "   [FUNCTION]"                                                     >> $CONFIGFILE
echo "       NAME           = $ARG_FUNCTIONNAME"                         >> $CONFIGFILE
echo "       [INPUT]"                                                    >> $CONFIGFILE
echo "           [VARIABLE]NAME = pin TYPE = CHAR(10)[END-VARIABLE]"    >> $CONFIGFILE
echo "       [END-INPUT]"                                                >> $CONFIGFILE
echo "       [OUTPUT]"                                                   >> $CONFIGFILE
echo "           [VARIABLE]NAME = city TYPE = CHAR(100)[END-VARIABLE]"  >> $CONFIGFILE
echo "           [VARIABLE]NAME = state TYPE = CHAR(100)[END-VARIABLE]" >> $CONFIGFILE
echo "       [END-OUTPUT]"                                               >> $CONFIGFILE
echo "   [END-FUNCTION]"                                                 >> $CONFIGFILE
echo "   [DIRECTORY]"                                                    >> $CONFIGFILE
echo "       NAME           = $ARG_DIRNAME"                              >> $CONFIGFILE
echo "       FILE           = soademo.4gl,"                              >> $CONFIGFILE
echo "   [END-DIRECTORY]"                                                >> $CONFIGFILE
echo "[END-SERVICE]"                                                     >> $CONFIGFILE
echo ""                                                                  >> $CONFIGFILE


echo "

The 4GL function '$ARG_FUNCTIONNAME' is being deployed as a web service. 

"

perl $IDIR/bin/w4glc -keep -silent -generate -compile -deploy -force $CONFIGFILE

status=$?

if (test $status -ne 0)
then
        echo "ERROR: Deploying the web service '$ARG_SERVICENAME'. Check /tmp/w4glerr.log"
else
        echo "The '$ARG_SERVICENAME' web service has been deployed."
#fi


echo "
The configuration file for the web service consumption is being generated.
"
CONFIGFILE_CL=`pwd`/clientsoademo.4cf

ARG_I4GL_FUNCTION="cons_ws_zipcode"
ARG_TARGET_FILE="cons_ws_zipcode.c"
ARG_TARGET_OBJECT_FILE="cons_ws_zipcode.o"

$COPY $AXIS2C_HOME/services/$ARG_SERVICENAME/$ARG_WSDLFILE $ARG_TMPDIR

echo "[SERVICE]"                                                              > $CONFIGFILE_CL
echo "   TYPE               = subscriber"                                    >> $CONFIGFILE_CL
echo "   I4GLVERSION        = 7.50.xC3"                                      >> $CONFIGFILE_CL
echo "   TARGET_DIR         = $ARG_TMPDIR"                                   >> $CONFIGFILE_CL
echo "   I4GL_FUNCTION      = $ARG_I4GL_FUNCTION"                            >> $CONFIGFILE_CL
echo "   TARGET_FILE        = $ARG_TARGET_FILE"                              >> $CONFIGFILE_CL
echo "   [WSDL_INFO]        "                                                >> $CONFIGFILE_CL
echo "       WSDL_PATH      = $ARG_TMPDIR"                                   >> $CONFIGFILE_CL
echo "       WSDL_FILE      = $ARG_WSDLFILE"                                 >> $CONFIGFILE_CL
echo "       WSDL_NAME_SPACE= $ARG_WSDLNS"                                   >> $CONFIGFILE_CL
echo "       [FUNCTION]"                                                     >> $CONFIGFILE_CL
echo "           SERVICENAME        = $ARG_SERVICENAME"                      >> $CONFIGFILE_CL
echo "           NAME           = $ARG_FUNCTIONNAME"                         >> $CONFIGFILE_CL
echo "           [INPUT]"                                                    >> $CONFIGFILE_CL
echo "               [VARIABLE]NAME = pin TYPE = CHAR(10)[END-VARIABLE]"    >> $CONFIGFILE_CL
echo "           [END-INPUT]"                                                >> $CONFIGFILE_CL
echo "           [OUTPUT]"                                                   >> $CONFIGFILE_CL
echo "               [VARIABLE]NAME = city TYPE = CHAR(100)[END-VARIABLE]"  >> $CONFIGFILE_CL
echo "               [VARIABLE]NAME = state TYPE = CHAR(100)[END-VARIABLE]" >> $CONFIGFILE_CL
echo "           [END-OUTPUT]"                                               >> $CONFIGFILE_CL
echo "        [END-FUNCTION]"                                                >> $CONFIGFILE_CL
echo "    [END-WSDL_INFO]"                                                   >> $CONFIGFILE_CL
echo "[END-SERVICE]"                                                         >> $CONFIGFILE_CL
echo ""                                                                      >> $CONFIGFILE_CL


        echo "

The  AXIS2C application server is being started.
"
        loc_pwd=`pwd`

        cd $AXIS2C_HOME/bin
        ./axis2_http_server -p 9876 -l 5  &
        
        sleep 3
        

echo "

The web service '$ARG_SERVICENAME' is being consumed by the 4GL function $ARG_I4GL_FUNCTION

"
perl $IDIR/bin/w4glc -silent -generate -compile $CONFIGFILE_CL 

status=$?

if (test $status -ne 0)
then
        echo "ERROR: Consuming the web service '$ARG_SERVICENAME'. Check /tmp/w4glerr.log"
else
        echo "The '$ARG_SERVICENAME' web service has been consumed."
fi

        cd $loc_pwd
        $COPY $ARG_TMPDIR/$ARG_TARGET_OBJECT_FILE .
        $COPY $ARG_TMPDIR/$ARG_TARGET_FILE .
        make
        ./zipcode_client
        

        var1=`ps -elf | grep "./axis2_http_server -p 9876" | head -n 1|tr -s ' '|cut -d " " -f4`
        
        echo "
        
The AXIS2C application server is terminating.
" 
        
        kill $var1

fi

echo "

The files created for the web service '$ARG_SERVICENAME' are located in the '$ARG_TMPDIR' directory.


End of the IBM Informix 4GL-SOA Demonstration Installation Script.
"
