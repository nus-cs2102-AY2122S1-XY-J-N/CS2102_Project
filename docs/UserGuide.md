# Rooms Manager Database procedures
This document aims to provide the database manager with the syntax of procedures for displaying or modifying data.
Note the syntax to using a procedure: [`CALL name ( [ argument ] [, ...] )`](https://www.postgresql.org/docs/11/sql-call.html).
## Before you begin, some syntax-matters
1. Anything string-related has to be enclosed with `''` for psql.
2. PostgreSQL uses the `yyyy-mm-dd` format e.g., `2000-12-31`.
## List of procedures
xx
### Adding a department
`CALL add_department(did INTEGER, IN dname VARCHAR(50));`

### Removing a department
`CALL remove_department (target_did INTEGER);`

### Adding an employee
`CALL add_employee(ename VARCHAR(50), hp_contact INTEGER, kind VARCHAR(7), did INTEGER);`

This generates a unique eid for the employee which follows an  increasing sequence starting from 1, and also a unique email which concatenates their initials to their eid, followed by the company's email. 

For instance, assume that the phone number and did are valid. 

Then  `CALL add_employee('Abraham Benedict Cumberbatch Donkey', 12345678, 'Senior', 69);` would result in an email `ABCD2@gsnail.com`, if the employee has eid 2.

### Removing an employee
`CALL remove_employee(IN eid INTEGER, resigned_date DATE);`

This call simply tags a date in the resigned_date attribute of the employee with given eid.
