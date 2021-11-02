:: Windows script to log into psql, and connect to RoomsManagerDatabase
@ECHO off
set dbname=RoomsManagerDatabase
psql -U postgres -d %dbname%