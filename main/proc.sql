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

CREATE OR REPLACE PROCEDURE add_room
(floor_num INTEGER, room_num INTEGER, room_name VARCHAR(50), did INTEGER)
AS $$
INSERT INTO Meeting_Rooms
       (rname
            , room
            , floor
            , did
       )
       values
       (room_name
            , room_num
            , floor_num
            , did
       )
       $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE change_capacity
(floor INTEGER, room_num INTEGER, capacity INTEGER, date DATE)
AS $$id
insert into Updates values
       (date
            , NULL
            , capacity
            , room_num
            , floor
       )
       $$ LANGUAGE sql
;

/**
* Routines for adding employee
*/
CREATE OR REPLACE PROCEDURE add_employee
(IN ename VARCHAR(50), hp_contact VARCHAR(50), kind VARCHAR(7), did INTEGER)
AS $$
INSERT INTO employees
       (ename
            , hp_contact
            , kind
            , did
       )
       VALUES
       (ename
            , hp_contact
            , kind
            , did
       )
       $$ LANGUAGE sql
;

-- extracting initials for email generation
DROP FUNCTION IF EXISTS get_name_initials(   VARCHAR(50));
CREATE OR REPLACE FUNCTION get_name_initials(VARCHAR(50))
RETURNS VARCHAR(10) AS $$
DECLARE
initials VARCHAR(50) := '';
letter   VARCHAR     := '';
BEGIN
FOREACH letter IN ARRAY string_to_array($1, ' ')
LOOP
initials := initials || substr(letter, 1, 1);
END LOOP;
RETURN initials;
END;
$$ LANGUAGE plpgsql;
-- create email and assign for employee
CREATE OR REPLACE FUNCTION assign_email()
RETURNS trigger AS $$
DECLARE
Eabbrv   VARCHAR(10) := '';
EmailEnd VARCHAR(11) := '@gsnail.com';
BEGIN
Eabbrv    := get_name_initials(NEW.ename);
NEW.email := CONCAT(Eabbrv, NEW.eid, EmailEnd);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER assign_email_add
BEFORE
INSERT
ON
       employees FOR EACH ROW EXECUTE FUNCTION assign_email()
;

/**
* End of adding employee routines
*/
/**
* Routines for removing employees
*/
CREATE OR REPLACE PROCEDURE remove_employee
(IN eid INTEGER, resigned_date DATE)
AS $$
UPDATE
       employees
SET    resigned_date = $2
WHERE
       eid = $1
;

$$ Language sql;
/**
* End of removing employees
*/
