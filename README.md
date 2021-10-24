# CS2102_Project
Welcome to our CS2102: Database Systems project!

## Quick start (Windows)
1. Clone this project into a new folder.
1. Ensure that you have the following [prerequisites](#prerequisites)
1. In cloned folder, go to <kbd> main </kbd>, execute <kbd> import.sh </kbd> to import the database and test cases
1. Run database by <kbd> run.sh </kbd>


## Prerequisites 
### Setting up postgres with no password authentication
1. Installed [psql](https://www.postgresql.org/download/) (14 is OK)
1. Setup user postgres with no password authentication
   1. > Open psql instance
  
   1. > `SHOW hba_file;`,
  
   1. > GOTO <kbd>hba_file</kbd>,
  
   1. > change ALL `Method` attributes to `trust`,
  
   1. > restart PSQL server by <kbd> Services </kbd> (Windows) -> `postgresql...` -> Right click and restart server
