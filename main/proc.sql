/**
* SQL  or  PL/pgSQL routines of implementation
**/
--basic
CREATE OR REPLACE PROCEDURE add_department
(IN did INTEGER, IN dname VARCHAR(50))
AS $$
INSERT INTO departments VALUES
       (did
            , dname
       )
       $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE remove_department
(IN target_did INTEGER)
AS $$
DELETE
FROM
       departments
WHERE
       did = target_did $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE add_employee
(IN ename VARCHAR(50), hp_contact INTEGER, kind VARCHAR(7), did INTEGER)
AS $$
INSERT INTO employees VALUES
()
$$ LANGUAGE sql;