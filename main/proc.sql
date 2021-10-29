/**
* SQL  or  PL/pgSQL routines of implementation
**/
--basic
/**
* Adding department, remove department
*/
CREATE OR REPLACE PROCEDURE add_department
(
  IN did   INTEGER
, IN dname VARCHAR(50)
)
AS
$$
INSERT INTO departments VALUES
       (did
            , dname
       )
       $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE remove_department
(
IN target_did INTEGER
)
AS
$$
DELETE
FROM
       departments
WHERE
       did = target_did $$ LANGUAGE sql
;

/**
* End
*/
/**
* Routines to add room, change capacity
*/
CREATE OR REPLACE PROCEDURE add_room
(
room_name  VARCHAR(50)
,floor_num INTEGER
, room_num INTEGER
, did      INTEGER
)
AS
$$
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
(
floor      INTEGER
, room_num INTEGER
, capacity INTEGER
,          date DATE
)
AS
$$
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
* End
*/
/**
* Routines for adding employee
*/
CREATE OR REPLACE PROCEDURE add_employee
(
IN ename     VARCHAR(50)
, hp_contact VARCHAR(50)
, kind       VARCHAR(7)
, did        INTEGER
)
AS
$$
INSERT INTO employees
       ( ename
            , hp_contact
            , kind
            , did
       )
       VALUES
       ( ename
            , hp_contact
            , kind
            , did
       )
       $$ LANGUAGE SQL
;

-- extracting initials for email generation
DROP
FUNCTION
IF EXISTS get_name_initials( VARCHAR(50));
CREATE OR REPLACE FUNCTION get_name_initials
(
VARCHAR(50)
) RETURNS VARCHAR(10)
AS
$$
DECLARE
initials VARCHAR(50) := '';
letter   VARCHAR     := '';
BEGIN
FOREACH letter IN ARRAY string_to_array($1, ' ')
LOOP
initials := initials
|| SUBSTR(letter, 1, 1);
END LOOP;
RETURN initials;
END;
$$ LANGUAGE plpgsql;
-- create email and assign for employee
CREATE OR REPLACE FUNCTION assign_email()
RETURNS TRIGGER
AS
$$
DECLARE
Eabbrv   VARCHAR(10) := '';
EmailEnd VARCHAR(11) := '@gsnail.com';
BEGIN
Eabbrv    := get_name_initials(NEW.ename);
NEW.email := CONCAT(Eabbrv, NEW.eid, EmailEnd);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER assign_email_add BEFORE
INSERT
ON
       employees FOR EACH ROW EXECUTE FUNCTION assign_email()
;

CREATE OR REPLACE PROCEDURE remove_employee
(
IN eid          INTEGER
, resigned_date DATE
)
AS
$$
UPDATE
       employees
SET    resigned_date = $2
WHERE
       eid = $1
;

$$ Language SQL;
/**
* End
*/
/**
* Routines for declaring health
*/
CREATE OR REPLACE PROCEDURE declare_health
(
IN eid_in INTEGER
, date_in DATE
, temp_in DECIMAL
)
AS
$$
BEGIN
INSERT INTO Health_Declaration
       ( eid
            , date
            , temp
       )
       VALUES
       ( $1
            , $2
            , $3
       )
ON
       CONFLICT
       (eid
            , date
       )
       DO
UPDATE
SET    temp = $3
WHERE
       Health_Declaration.eid      = $1
       AND Health_Declaration.date = $2
;

END;
$$ Language plpgsql;
--trigger to assign fever
CREATE OR REPLACE FUNCTION assign_fever()
RETURNS TRIGGER AS $$
BEGIN
IF (NEW.temp >= 37.5) THEN
NEW.fever := TRUE;
ELSE
NEW.fever := FALSE;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER assign_fever_trig BEFORE
INSERT
       OR
UPDATE
ON
       Health_Declaration FOR EACH ROW EXECUTE PROCEDURE assign_fever()
;

/**
* END
*/
/**
* Routine to add sessions
*/
CREATE OR REPLACE FUNCTION generate_random_sessions_table(n INTEGER)
RETURNS TABLE(participant_id                                INTEGER,
man_id                                                      INTEGER,
booker_id                                                   INTEGER,
room_name                                                   VARCHAR(50),
room_no                                                     INTEGER,
floor_no                                                    INTEGER,
time_of_booking                                             TIMESTAMP)
AS
$$
BEGIN
RETURN QUERY
WITH rand_id AS
     (
            SELECT
                   eid participant_id
            FROM
                   employees
            ORDER BY
                   random()
            LIMIT  n
     )
   , rand_man_id AS
     (
            SELECT
                   eid man_id
            FROM
                   manager
            ORDER BY
                   random()
            LIMIT  n
     )
   , rand_book_id AS
     (
            select
                   eid booker_id
            FROM
                   junior
            ORDER BY
                   random()
            LIMIT  n
     )
   , rand_room AS
     (
            select
                   rname room_name
                 , room  room_no
                 , floor floor_no
            from
                   meeting_rooms
            ORDER BY
                   random()
            LIMIT  n
     )
   , get_timestamp AS
     (
            SELECT DISTINCT
                   generate_series( (current_date)::timestamp, (current_date + interval '1 MONTH')::timestamp, interval '1 hour' ) timestamps
            LIMIT  n
     )
SELECT DISTINCT
       *
FROM
       rand_id
     , rand_man_id
     , rand_book_id
     , rand_room
     , get_timestamp
LIMIT  n
;

END;
$$ LANGUAGE plpgsql;
/**
* End generate sessions FUNCTION
*/
/**
* Start of insert into sessions  PROCEDURE
*/
-- adding normal sessions
CREATE OR REPLACE PROCEDURE add_sessions(participant_eid INTEGER, approving_manager_eid INTEGER, booker_eid INTEGER, room INTEGER, floor INTEGER, time_in TIMESTAMP, rname VARCHAR(50))
AS
$$
BEGIN
INSERT INTO Sessions
       (participant_eid
            , approving_manager_eid
            , booker_eid
            , room
            , floor
            , time
            , rname
       )
       VALUES
       ($1
            , $2
            , $3
            , $4
            , $5
            , $6
            , $7
       )
;

END;
$$ LANGUAGE plpgsql;
-- adding random sessions
CREATE OR REPLACE PROCEDURE add_random_sessions(how_many_to_insert INTEGER)
AS
$$
BEGIN
INSERT INTO Sessions
       (participant_eid
            , approving_manager_eid
            , booker_eid
            , room
            , floor
            , time
            , rname
       )
SELECT
       participant_id
     , man_id
     , booker_id
     , room_no
     , floor_no
     , time_of_booking
     , room_name
FROM
       generate_random_sessions_table(how_many_to_insert)
ON
       CONFLICT(participant_eid, time, booker_eid, room, floor) -- primary key
       DO NOTHING                                               -- strictly  for dummy data
;

END;
$$ LANGUAGE plpgsql;
/**
* End of INSERT sessions PROCEDURE
*/

/**
 * Start of non-compliance PROCEDURE
 */
CREATE OR REPLACE FUNCTION non_compliance(sDate DATE, eDate DATE)
RETURNS TABLE (eid INTEGER, nDays BIGINT)
AS $$
BEGIN
RETURN QUERY
-- generate all possible dates
WITH gen_date AS (
SELECT date::date FROM generate_series($1, $2, '1 day'::interval) date
),

-- generate all possible eid | dates combination
eid_date AS (SELECT e.eid, gd.date FROM Employees e, gen_date gd),

-- get all eid and dates not declared
eid_not_declared_on AS (
SELECT ed.eid, ed.date FROM eid_date ed
EXCEPT
SELECT hd.eid, hd.date FROM Health_Declaration hd)

SELECT endo.eid , COUNT(endo.date) nDays FROM eid_not_declared_on endo GROUP BY endo.eid ORDER BY endo.eid;
END;
$$ LANGUAGE plpgsql;
 /*
  * End of non-compliance PROCEDURE
  */
