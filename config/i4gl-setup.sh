#!/bin/bash

cd $INFORMIXDIR
cp -R ~/tmp/* .
sudo INFORMIXDIR=$INFORMIXDIR ./install4gl
cp /opt/ibm/informix/lib/tools/lib4gsh.so /opt/ibm/informix/lib

cd /tmp
c4gl hello.4gl -o hello.4ge
./hello.4ge
