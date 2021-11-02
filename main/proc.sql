/**
* TRIGGERS
*/
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
CREATE OR REPLACE TRIGGER assign_fever_trig BEFORE
INSERT
    OR
UPDATE
ON
    health_declaration FOR EACH ROW EXECUTE PROCEDURE assign_fever()
;

-- triggers that activate when an employee has a fever
--procedure to remove employee from all future meeting room bookings IF FEVER
CREATE OR REPLACE FUNCTION remove_future_meetings_on_fever()
RETURNS TRIGGER AS $$
BEGIN
IF NEW.fever = 'true' THEN
DELETE
FROM
    Sessions s
WHERE
    (
        s.participant_eid = NEW.eid
        OR s.booker_eid   = NEW.eid
    )
    AND s.datetime >= NEW.date::TIMESTAMP
;

END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER check_fever AFTER
INSERT
    OR
UPDATE
ON
    health_declaration FOR EACH ROW EXECUTE PROCEDURE remove_future_meetings_on_fever()
;

--Trigger to stop 2 managers from updating capacity of room in the same day
CREATE OR REPLACE FUNCTION updates_check() RETURNS TRIGGER AS $$
begin
if exists
(
    select
        1
    from
        updates
    where
        floor              = new.floor
        and room           = new.room
        and date           = new.date
        and approving_eid != new.approving_eid
)
then
raise notice 'capacity of room already updated today';
return null;
else
return new;
end if;
end;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE TRIGGER updates_check_trigger
BEFORE
INSERT
ON
    updates FOR EACH ROW EXECUTE FUNCTION updates_check()
;

/**
* BASIC ROUTINES
*/
CREATE OR REPLACE PROCEDURE add_department
(
  IN did   INTEGER
, IN dname varchar(50)
)
AS
$$
INSERT INTO departments VALUES
    (did
      , dname
    )
    $$ LANGUAGE SQL
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
    did = target_did $$ LANGUAGE SQL
;

CREATE OR REPLACE PROCEDURE add_room
(
room_name  varchar(50)
,floor_num INTEGER
, room_num INTEGER
, did      INTEGER
)
AS
$$
INSERT INTO Meeting_Rooms
    (rname
      , floor
      , room
      , did
    )
    values
    (room_name
      , floor_num
      , room_num
      , did
    )
    $$ LANGUAGE SQL
;

-- Assume when room added no entry exists in [Updates]
CREATE OR REPLACE PROCEDURE change_capacity (manager_eid INTEGER, floornum INTEGER , roomnum INTEGER , capacity INTEGER , effective_date DATE) AS $$
BEGIN
IF EXISTS
(
    select
        1
    from
        Manager
    where
        eid = manager_eid
)
THEN
INSERT INTO updates VALUES
    (effective_date
      , manager_eid
      , capacity
      , floornum
      , roomnum
    )
ON
    CONFLICT
    (date
      , floor
      , room
      , approving_eid
    )
    DO
UPDATE
SET new_cap = capacity
;

ELSE
RAISE EXCEPTION 'You are not a manager';
END IF;
END
$$ LANGUAGE plpgsql;
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

CREATE OR REPLACE PROCEDURE remove_employee
(
IN eid          INTEGER
, resigned_date DATE
)
AS
$$
UPDATE
    employees
SET resigned_date = $2
WHERE
    eid = $1
;

$$ LANGUAGE SQL;
/**
* CORE ROUTINES
*/
CREATE OR REPLACE PROCEDURE book_room (floor integer, room integer, date date, start_hr integer, end_hr integer, booker_eid integer) AS $$
DECLARE
hasFever        boolean;
bookingTime     time;
n               integer := end_hr - start_hr;
j               integer := end_hr - start_hr;
bookingDatetime timestamp;
isBooked        boolean := false;
BEGIN
IF NOT EXISTS
(
    select
        1
    from
        Manager
    where
        eid = booker_eid
    UNION
    select
        1
    from
        Senior
    where
        eid = booker_eid
)
THEN
RAISE EXCEPTION 'eid % is not a senior or manager', booker_eid;
END IF;
--If employee is trying to book but didn't declare temperature today, reject his booking
select
    fever
into
    hasFever
from
    Health_Declaration
where
    eid      = booker_eid
    and date = CURRENT_DATE
;

IF NOT FOUND THEN
RAISE EXCEPTION 'eid % no health declaration on %', booker_eid, CURRENT_DATE;
END IF;
--Employee declared temp but has fever today
IF (hasFever IS TRUE) THEN
RAISE EXCEPTION 'You have fever today, no booking allowed';
END IF;
--Check if room is booked
bookingTime     := make_time(start_hr,0,0);
bookingDatetime := date + bookingTime;
LOOP
exit when n = 0;
IF EXISTS
(
    select
        1
    from
        Sessions
    where
        floor        = floor
        and room     = room
        and datetime = bookingDatetime + make_interval(hours => (n-1))
)
THEN isBooked := true;
END IF;
n := n-1;
END LOOP;
IF (isBooked IS TRUE) THEN RAISE EXCEPTION 'time slot unavailable';
END IF;
--All checks passed, book the slots
LOOP
exit when j = 0;
INSERT INTO Sessions
    (approving_manager_eid
      , booker_eid
      , participant_eid
      , floor
      , room
      , datetime
    )
    VALUES
    (null
      , booker_eid
      , booker_eid
      , floor
      , room
      , bookingDatetime + make_interval(hours => (j-1))
    )
;

j := j-1;
END LOOP;
END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE PROCEDURE unbook_room (floor integer, room integer, date date, start_hr integer, end_hr integer, booker_eid integer) AS $$
DECLARE
booking_time     time := make_interval(start_hr,0,0);
booking_datetime timestamp;
bcheck           boolean := true;
n                int     := end_hr - start_hr;
j                int     := end_hr - start_hr;
BEGIN
booking_datetime := date + booking_time;
LOOP
EXIT WHEN n=0;
IF NOT EXISTS
(
    select
        1
    from
        Sessions
    where
        floor          = floor
        and room       = room
        and datetime   = booking_datetime + make_interval(hours => (n-1))
        and booker_eid = booker_eid
)
THEN bcheck := false;
END IF;
n := n-1;
END LOOP;
IF (bcheck IS FALSE) THEN RAISE EXCEPTION 'Some bookings do not exist for the date and time range';
END IF;
LOOP
EXIT WHEN j=0;
DELETE
FROM
    Sessions
WHERE
    floor          = floor
    and room       = room
    and datetime   = booking_datetime + make_interval(hours => (j-1))
    and booker_eid = booker_eid
;

j := j-1;
END LOOP;
END;
$$ LANGUAGE plpgsql;
/**
* HEALTH ROUTINES
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
SET temp = $3
WHERE
    Health_Declaration.eid      = $1
    AND Health_Declaration.date = $2
;

END;
$$ LANGUAGE plpgsql;
-- contact tracing
CREATE OR REPLACE FUNCTION contact_tracing(f_eid INTEGER)
RETURNS TABLE (eid                               INTEGER)
AS
$$
DECLARE curr_date TIMESTAMP := current_date::TIMESTAMP; --gets today's date at 00:00
BEGIN
RETURN QUERY
--get all meetings that fever guy joined, more specifically the time, booker_eid, room and floor
WITH get_meetings AS
    (
        SELECT
            s.booker_eid , s.time , s.room , s.floor
        FROM
            Sessions s
        WHERE
            s.participant_eid = $1
    )
--get participants list from PAST 3 meeting dates
-- simply consider range of 3 days --> current_timestamp - interval '3 days' to now.
SELECT DISTINCT
    s.participant_eid
FROM
    get_meetings gm , Sessions s
WHERE
    gm.time               >= curr_date - INTERVAL '3 days'
    AND s.booker_eid       = gm.booker_eid
    AND s.participant_eid <> $1 -- dont want fever fella
    AND gm.room            = s.room
    AND gm.floor           = s.floor
;

END;
$$ LANGUAGE plpgsql;
--procedure to REMOVE future meetings of close contacts with fever case
CREATE OR REPLACE PROCEDURE remove_future_meetings_on_fever_close_contact()
AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;
/**
* ADMIN ROUTINES
*/
CREATE OR REPLACE FUNCTION view_manager_report (start_date DATE, manager_eid INT)
RETURNS TABLE (floor_no                                    INT, room_no INT, session_time TIMESTAMP, eid INT) AS $$
BEGIN
IF NOT EXISTS
(
    SELECT
        1
    FROM
        Manager m
    WHERE
        manager_eid = m.eid
)
THEN RETURN QUERY
(
    SELECT
        floor, room, time, participant_eid
    FROM
        Sessions
    WHERE
        booker_eid ISNULL
)
;
ELSE RETURN QUERY
(
    SELECT
        s.floor, s.room, s.time, s.participant_eid
    FROM
        Sessions s, Meeting_rooms m, Employees e
    WHERE
        s.approving_manager_eid ISNULL
        AND s.time      > start_date
        AND manager_eid = e.eid
        AND s.floor     = m.floor
        AND s.room      = m.room
        AND e.did       = m.did
    ORDER BY
        s.time ASC
)
;
END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION non_compliance(sDate DATE, eDate DATE)
RETURNS TABLE (eid                              INTEGER, nDays BIGINT)
AS $$
BEGIN
RETURN QUERY
-- generate all possible dates
WITH gen_date AS
    (
        SELECT
            date::date
        FROM
            generate_series($1, $2, '1 day'::interval) date
    )
  ,
     -- generate all possible eid | dates combination
    eid_date AS
    (
        SELECT
            e.eid , gd.date
        FROM
            Employees e , gen_date gd
    )
  ,
     -- get all eid and dates not declared
    eid_not_declared_on AS
    (
        SELECT
            ed.eid , ed.date
        FROM
            eid_date ed
        EXCEPT
        SELECT
            hd.eid , hd.date
        FROM
            Health_Declaration hd
    )
SELECT
    endo.eid , COUNT(endo.date) nDays
FROM
    eid_not_declared_on endo
GROUP BY
    endo.eid
ORDER BY
    COUNT(endo.date) DESC
;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_booking_report (eid int, start_date date)
RETURNS TABLE(floornum                              int, roomnum int, booking_datetime timestamp, is_approved boolean) AS $$
DECLARE
BEGIN
RETURN QUERY
SELECT
    floor , room , datetime , CASE
        WHEN approving_manager_eid IS NULL
            THEN false
            ELSE true
    END AS is_approved
FROM
    Sessions
WHERE
    booker_eid    = eid
    AND datetime >= start_date::timestamp
ORDER BY
    datetime ASC
;

END;
$$ LANGUAGE plpgsql;
/**
* UTILITY ROUTINES FOR DATA GENERATION
*/
-- extracting initials for email generation
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
initials := initials || SUBSTR(letter, 1, 1);
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

--Routine to add sessions
CREATE OR REPLACE FUNCTION generate_random_sessions_table(n INTEGER)
RETURNS TABLE(participant_id                                INTEGER,
man_id                                                      INTEGER,
booker_id                                                   INTEGER,
room_name                                                   VARCHAR(50),
floor_no                                                    INTEGER,
room_no                                                     INTEGER,
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
        LIMIT n
    )
  , rand_man_id AS
    (
        SELECT
            eid man_id
        FROM
            manager
        ORDER BY
            random()
        LIMIT n
    )
  , rand_book_id AS
    (
        SELECT
            js.eid booker_id
        FROM
           (SELECT eid FROM Junior UNION SELECT eid FROM Senior) js
        ORDER BY
            random()
        LIMIT n
    )
  , rand_room AS
    (
        SELECT
            rname , floor , room
        FROM
            meeting_rooms
        OFFSET random() *
            (
                SELECT
                    count(*)
                FROM
                    meeting_rooms
            )
        LIMIT n
    )
  , get_timestamp AS
    (
        SELECT DISTINCT
            generate_series( (current_date)::timestamp, (current_date + interval '1 MONTH')::timestamp, interval '1 hour' ) timestamps
        LIMIT n
    )
SELECT DISTINCT
    *
FROM
    rand_id , rand_man_id , rand_book_id , rand_room
  , get_timestamp
LIMIT n
;

END;
$$ LANGUAGE plpgsql;
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
      , datetime
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
      , datetime
      , rname
    )
SELECT
    participant_id , man_id          , booker_id , room_no
  , floor_no       , time_of_booking , room_name
FROM
    generate_random_sessions_table(how_many_to_insert)
ON
    CONFLICT(participant_eid, datetime, booker_eid, room, floor) -- primary key
    DO NOTHING                                                   -- strictly  for dummy data
;

END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION view_future_meeting(sDate DATE, eid INTEGER)
RETURNS TABLE(floor                                  INTEGER, room INTEGER, dateStart TIMESTAMP)
AS $$
DECLARE startTimestamp TIMESTAMP := $1::TIMESTAMP; -- casts date to timestamp
BEGIN
RETURN QUERY
SELECT
    s.floor , s.room , s.time
FROM
    Sessions s
WHERE
    s.time               >= startTimestamp
    AND s.participant_eid = $2
ORDER BY
    s.time ASC
;

END;
$$ LANGUAGE plpgsql;