#!/bin/bash
 
###################################################
# Bash script to generate project database	  #
###################################################

#Create project database
createdb -U postgres RoomsManagerDatabase

#Set the value of variable
database="RoomsManagerDatabase"
 
#Check database creation: 

psql -d $database -c "SELECT 'Success';"

# Import .sql files into database

psql -d $database -U postgres -f data.sql -f proc.sql -f schema.sql

echo ##########################
echo ###displaying tables...###
echo ######################### #

#Check tables created
psql -d $database -U postgres -c "\d+"
 
#Print done
echo finished setting up, exiting

