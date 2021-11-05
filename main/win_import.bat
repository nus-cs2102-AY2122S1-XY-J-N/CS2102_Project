@ECHO OFF
set dbname=RoomsManagerDatabase
echo deleting database...
:: Drops datebase if found
psql -U postgres -c "DROP DATABASE IF EXISTS "%dbname%";"
:: Create new database
createdb -U postgres %dbname%
:: Import files
psql -d "%dbname%" -q -U postgres -f schema.sql -f data.sql -f proc.sql
:: Echo done
echo Finished import. Signing in!

:: Log into postgres, under database
psql -U postgres -d %dbname%