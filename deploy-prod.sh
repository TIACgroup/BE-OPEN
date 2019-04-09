#!/bin/bash
# DSpace deploy script

#DSpace source
DSPACE_SOURCE='path-to-dspace-source'
#Dspace install
DSPACE_INSTALL='path-to-dspace-install'
#Tomcat
TOMCAT='path-to-tomcat'

#Build projekta
cd $DSPACE_SOURCE
mvn clean package

#Zaustavljanje tomcat servisa
systemctl stop tomcat

#Ant build
cd dspace/target/dspace-installer/
ant update clean_backups

#Brisanje web aplikacije iz tomcat-a
echo 'Brisanje web aplikacije iz tomcat-a ...'
cd $TOMCAT/webapps/
rm -rf oai/ rdf/ rest/ ROOT/ solr/ sword/ swordv2/

#Kopiranje web aplikacije iz dspace instalacionog foldera u tomcat
echo 'Kopiranje web aplikacije u tomcat ...'
cd $DSPACE_INSTALL/webapps
cp -R jspui/ oai/ rdf/ rest/ solr/ sword/ swordv2/ $TOMCAT/webapps

#Preimenovanje jspui u ROOT
cd $TOMCAT/webapps
mv jspui/ ROOT

#Startovanje tomcat-a
echo 'Startovanje tomcat-a ...'
systemctl start tomcat
