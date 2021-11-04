#!/bin/bash
 
###################################################
# Bash script to generate project database	  #
###################################################

#Create project database
psql -U postgres -c "DROP DATABASE IF EXISTS "RoomsManagerDatabase";"

#Set the value of variable
database="RoomsManagerDatabase"
 
#Create database
createdb -U postgres RoomsManagerDatabase

# Import .sql files into database
psql -d $database -U postgres -f schema.sql -f data.sql -f proc.sql

echo ##########################
echo ###displaying tables...###
echo ######################### #

#Check tables created
psql -d $database -U postgres -c "\d+"
 
#Print done
echo finished setting up, exiting.
echo 	use ' run.sh ' to run the database!
$SHELL

