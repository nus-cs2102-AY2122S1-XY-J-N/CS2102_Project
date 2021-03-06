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
CREATE TRIGGER assign_fever_trig BEFORE
INSERT
       OR
UPDATE
ON
       health_declaration FOR EACH ROW EXECUTE PROCEDURE assign_fever()
;

-- triggers that activate when an employee has a fever
--procedure to remove employee and their close contacts from all future meeting room bookings IF FEVER
CREATE OR REPLACE FUNCTION remove_future_meetings_on_fever()
RETURNS TRIGGER AS $$
DECLARE curr_date DATE := CURRENT_DATE;
BEGIN
IF NEW.fever = 'true' THEN
-- get close contacts (3 days or less)
WITH get_close_contacts AS
     (
            SELECT
                   eid --returns close contacts
            FROM
                   contact_tracing(NEW.eid)
     )
-- 1st check for close contacts 7 days
DELETE
FROM
       Sessions s
WHERE
       (
              s.participant_eid IN
              (
                     select
                            eid
                     FROM
                            get_close_contacts
              ) -- close contact of fever case
       )
       AND s.datetime >= NEW.date::TIMESTAMP
       AND s.datetime <= NEW.date::TIMESTAMP + INTERVAL '7 DAYS'
;

-- remove fever fella from ALL future meetings
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

-- add fever fella to employees blacklist
INSERT INTO Blacklist_Employees VALUES
       (NEW.eid
            , curr_date
            , curr_date + INTEGER '14' -- 2 weeks work from home, assume best case 14 days as per https://www.webmd.com/lung/covid-recovery-overview#2
       )
ON
       CONFLICT
       (eid
            , sDate
            , eDate
       )
       DO NOTHING
;

WITH get_close_contacts AS
     (
            SELECT
                   eid --returns close contacts
            FROM
                   contact_tracing(NEW.eid)
     )
-- add close contacts to employees blacklist
INSERT INTO Blacklist_Employees
       (eid
            , sDate
            , eDate
       )
SELECT
       gcc.eid
     , curr_date
     , curr_date + INTEGER '7'
FROM
       get_close_contacts gcc
ON
       CONFLICT (eid, sDate, eDate) DO NOTHING
;

END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER check_fever AFTER
INSERT
       OR
UPDATE
ON
       health_declaration FOR EACH ROW EXECUTE PROCEDURE remove_future_meetings_on_fever()
;

--trigger to notify database admin of addition of close contacts OR fever employee to blacklist
CREATE OR REPLACE FUNCTION notify_admin_on_blacklist_addition() RETURNS TRIGGER AS
$$
BEGIN
RAISE NOTICE 'Employee % has been added to the blacklist from % to %', NEW.eid, NEW.sDate, NEW.eDate;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER blacklist_notify_trigger
AFTER
INSERT
ON
       blacklist_employees FOR EACH ROW EXECUTE FUNCTION notify_admin_on_blacklist_addition()
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
CREATE TRIGGER updates_check_trigger
BEFORE
INSERT
ON
       updates FOR EACH ROW EXECUTE FUNCTION updates_check()
;

-- trigger to remove retired employee  from  future  meetings
CREATE OR REPLACE FUNCTION remove_future_meetings_on_retire()
RETURNS TRIGGER AS
$$
BEGIN
IF (NEW.resigned_date IS NOT NULL) THEN
DELETE
FROM
       Sessions
WHERE
       participant_eid = NEW.eid
       AND datetime   >= CURRENT_DATE::TIMESTAMP
;

RAISE NOTICE 'Removed % from all future meetings!', NEW.eid;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER retire_employee
AFTER
INSERT
       OR
UPDATE
ON
       employees FOR EACH ROW EXECUTE FUNCTION remove_future_meetings_on_retire()
;

/**
* BASIC ROUTINES
*/
CREATE OR REPLACE PROCEDURE add_department (IN did INTEGER, IN dname VARCHAR(50))
AS $$
INSERT INTO departments VALUES
       (did
            , dname
       )
       $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE remove_department (IN target_did INTEGER)
AS $$
DELETE
FROM
       departments
WHERE
       did = target_did $$ LANGUAGE sql
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
CREATE OR REPLACE PROCEDURE public.change_capacity(
IN manager_eid    integer,
IN floornum       integer,
IN roomnum        integer,
IN capacity       integer,
IN effective_date date)
LANGUAGE 'plpgsql'
AS $BODY$
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
SET    new_cap = capacity
;

ELSE
RAISE EXCEPTION 'You are not a manager';
END IF;
DELETE
FROM
       sessions
WHERE
       floor    = floornum
       AND room = roomnum
       AND datetime IN
       (
              SELECT
                     datetime
              FROM
                     session_pax
              WHERE
                     floor        =floornum
                     AND room     =roomnum
                     AND datetime > effective_date::timestamp
                     AND pax      > capacity
       )
;

END
$BODY$;
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
SET    resigned_date = $2
WHERE
       eid = $1
;

$$ LANGUAGE SQL;
/**
* CORE ROUTINES
*/
CREATE OR REPLACE PROCEDURE approve_meeting (floor_no INTEGER, room_no INTEGER, date DATE, start_hour INTEGER, end_hour INTEGER, approver_eid INTEGER)
AS $$
DECLARE
start_datetime TIMESTAMP := (CAST(date AS TEXT) || ' ' || start_hour || ':00:00')::TIMESTAMP;
end_datetime   TIMESTAMP := (CAST(date AS TEXT) || ' ' || end_hour || ':00:00')::TIMESTAMP;
BEGIN
IF EXISTS
(
       SELECT
              1
       FROM
              Manager       m
            , Employees     e
            , Sessions      s
            , Meeting_rooms r
       WHERE
              m.eid = approver_eid --is a manager
              --check whether manager's did same as room's did
              AND e.eid                 = approver_eid
              AND e.did                 = r.did
              AND e.resigned_date IS NULL -- check not resigned
              AND s.floor               = r.floor
              AND s.room                = r.room
              AND s.datetime           >= start_datetime
              AND s.datetime            < end_datetime
)
THEN
UPDATE
       Sessions
SET    approving_manager_eid = approver_eid
WHERE
       floor         = floor_no
       AND room      = room_no
       AND datetime >= start_datetime
       AND datetime  < end_datetime
;

ELSE
RAISE EXCEPTION 'Employee is not a manager/ Manager is not in same department as meeting room/ Employee is resigned / Approver has fever / Meeting Not Found!';
END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE PROCEDURE leave_meeting (floor_no INTEGER, room_no INTEGER, date DATE, start_hour INTEGER, end_hour INTEGER, leaver_eid INTEGER)
AS $$
DECLARE
start_datetime TIMESTAMP := (CAST(date AS TEXT) || ' ' || start_hour || ':00:00')::TIMESTAMP;
end_datetime   TIMESTAMP := (CAST(date AS TEXT) || ' ' || end_hour || ':00:00')::TIMESTAMP;
BEGIN
IF EXISTS
(
       SELECT
              1
       FROM
              Sessions
       WHERE
              approving_manager_eid ISNULL --meeting not approved yet
              --check whether eid is participating in the specified meeting
              AND participant_eid = leaver_eid
              AND floor           = floor_no
              AND room            = room_no
              AND datetime       >= start_datetime
              AND datetime        < end_datetime
)
THEN
DELETE
FROM
       Sessions
WHERE
       participant_eid = leaver_eid
       AND floor       = floor_no
       AND room        = room_no
       AND datetime   >= start_datetime
       AND datetime    < end_datetime
;

END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE PROCEDURE join_meeting (floor_no INTEGER, room_no INTEGER, date DATE, start_hour INTEGER, end_hour INTEGER, joiner_eid INTEGER)
AS $$
DECLARE
start_datetime     TIMESTAMP   := (CAST(date AS TEXT) || ' ' || start_hour || ':00:00')::TIMESTAMP;
end_datetime       TIMESTAMP   := (CAST(date AS TEXT) || ' ' || end_hour || ':00:00')::TIMESTAMP;
booker_eid_var     INTEGER     := 0;
rname_var          VARCHAR(50) := '';
increment_datetime TIMESTAMP   := start_datetime;
BEGIN
-- if employee is on blacklist
IF EXISTS
(
       SELECT
              1
       FROM
              blacklist_employees be
       WHERE
              be.eid  = $6
              AND $3 >= be.sDate
              AND $3 <= be.eDate
)
THEN RAISE EXCEPTION 'You cannot join any meeting due to contact tracing measures!';
END IF;
IF EXISTS
(
       SELECT
              1
       FROM
              Sessions  s
            , Employees e
              --check whether meeting is joinable
       WHERE
              s.approving_manager_eid ISNULL
              AND s.datetime >= start_datetime
              AND s.datetime  < end_datetime
              --check whether eid has resigned
              AND e.eid = joiner_eid
              AND e.resigned_date ISNULL
)
-- check fever
AND
(
    EXISTS
    (
           SELECT
                  1
           FROM
                  Health_Declaration hd
           WHERE
                  (
                         hd.eid       = $6
                         AND hd.date  = current_date
                         AND hd.fever = false
                  )
    )
    OR
    (
        NOT EXISTS
        (
               SELECT
                      1
               FROM
                      Health_Declaration hd
               WHERE
                      (
                             hd.eid      = $6
                             AND hd.date = current_date
                      )
        )
    )
)
THEN
--loop for joining multiple meetings
LOOP
EXIT WHEN increment_datetime = end_datetime;
booker_eid_var :=
(
       SELECT
              booker_eid
       FROM
              Sessions
       WHERE
              floor         = floor_no
              AND room      = room_no
              AND datetime >= start_datetime
              AND datetime  < end_datetime
       LIMIT  1
)
;
rname_var :=
(
       SELECT
              rname
       FROM
              Sessions
       WHERE
              floor         = floor_no
              AND room      = room_no
              AND datetime >= start_datetime
              AND datetime  < end_datetime
       LIMIT  1
)
;
INSERT INTO Sessions VALUES
       (joiner_eid
            , NULL
            , booker_eid_var
            , floor_no
            , room_no
            , increment_datetime
            , rname_var
       )
;

increment_datetime := increment_datetime + INTERVAL '1 HOUR';
END LOOP;
ELSE
RAISE EXCEPTION 'Meeting approved already/Invalid employee entered/ Employee has fever!';
END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE PROCEDURE public.book_room(
IN floornum integer,
IN roomnum  integer,
IN bdate    date,
IN start_hr integer,
IN end_hr   integer,
IN beid     integer)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
hasFever        boolean;
bookingTime     time;
n               integer := end_hr - start_hr;
j               integer := end_hr - start_hr;
bookingDatetime timestamp;
isBooked        boolean := false;
resignDate      date;
BEGIN
select
       resigned_date
into
       resignDate
from
       employees
where
       eid = beid
;

IF (resignDate IS NOT NULL) THEN
RAISE EXCEPTION 'eid % is resigned',beid;
ELSIF NOT EXISTS
(
       select
              1
       from
              Manager
       where
              eid = beid
       UNION
       select
              1
       from
              Senior
       where
              eid = beid
)
THEN
RAISE EXCEPTION 'eid % is not a senior or manager', beid;
END IF;
--If employee has fever today, reject booking. If employee didn't declare temp today, accept booking
select
       fever
into
       hasFever
from
       Health_Declaration
where
       eid      = beid
       and date = CURRENT_DATE
;

IF NOT FOUND THEN
hasFever:= false;
END IF;
--Employee declared temp but has fever today
IF (hasFever IS TRUE) THEN
RAISE EXCEPTION 'You have fever today, no booking allowed';
END IF;
-- else if employee is on blacklist
IF EXISTS
(
       SELECT
              1
       FROM
              blacklist_employees be
       WHERE
              be.eid     = beid
              AND bdate >= be.sDate
              AND bdate <= be.eDate
)
THEN RAISE EXCEPTION 'You cannot join any meeting due to contact tracing measures!';
END IF;
--Check if room is booked
bookingTime     := make_time(start_hr,0,0);
bookingDatetime := bdate + bookingTime;
LOOP
exit when n = 0;
IF EXISTS
(
       select
              1
       from
              Sessions
       where
              floor        = floornum
              and room     = roomnum
              and datetime = bookingDatetime + make_interval(hours => (n-1))
)
THEN isBooked := true;
END IF;
n := n-1;
END LOOP;
IF (isBooked IS TRUE) THEN RAISE EXCEPTION 'Time slot unavailable';
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
            , rname
       )
       VALUES
       (null
            , beid
            , beid
            , floornum
            , roomnum
            , bookingDatetime + make_interval(hours => (j-1))
            , (
                     select
                            rname
                     from
                            meeting_rooms
                     where
                            floor    = floornum
                            and room = roomnum
              )
       )
;

j := j-1;
END LOOP;
END;
$BODY$;
CREATE OR REPLACE PROCEDURE unbook_room(
IN floor_in integer,
IN room_in  integer,
IN date_in  date,
IN start_hr integer,
IN end_hr   integer,
IN beid     integer)
AS $$
DECLARE
booking_time     time := make_time(start_hr,0,0);
booking_datetime timestamp;
bcheck           boolean := true;
n                int     := end_hr - start_hr;
j                int     := end_hr - start_hr;
BEGIN
booking_datetime := date_in + booking_time;
LOOP
EXIT WHEN n=0;
IF NOT EXISTS
(
       select
              1
       from
              Sessions
       where
              floor          = floor_in
              and room       = room_in
              and datetime   = booking_datetime + make_interval(hours => (n-1))
              and booker_eid = beid
)
THEN bcheck := false;
END IF;
n := n-1;
END LOOP;
IF (bcheck IS FALSE) THEN RAISE EXCEPTION 'Not all bookings for the time range under your name is found';
END IF;
LOOP
EXIT WHEN j=0;
DELETE
FROM
       Sessions
WHERE
       floor          = floor_in
       and room       = room_in
       and datetime   = booking_datetime + make_interval(hours => (j-1))
       and booker_eid = beid
;

j := j-1;
END LOOP;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION search_room (min_cap int, meeting_date date, start_hr int, end_hr int) RETURNS TABLE (floornum int, roomnum int, did_t int, roomcap int) AS $$
declare
start_datetime timestamp := meeting_date + make_time(start_hr,0,0);
end_datetime   timestamp := meeting_date + make_time(end_hr,0,0);
begin
RETURN QUERY
WITH rooms_CTE AS
     (
            select *
            from
                   updates
                   join
                          meeting_rooms
            USING  (floor
                 , room)
            where
                   new_cap >= min_cap
                   --rooms that are already booked for the input date and duration
     )
   , conflicting_sessions_CTE AS
     (
            select
                   floor
                 , room
            from
                   sessions
            where
                   participant_eid = booker_eid
                   and datetime   >= start_datetime
                   and datetime    < end_datetime
                   --rooms that meet min capacity, which takes capacity from the entry with latest date in updates
     )
   , cleaned_rooms_CTE AS
     (
            select
                   r1.floor
                 , r1.room
                 , r1.new_cap
                 , r1.did
            from
                   rooms_CTE r1
                   join
                          (
                                 select
                                        floor
                                      , room
                                      , max(date) as maxdate
                                 from
                                        rooms_CTE
                                 group by
                                        (floor
                                      , room)
                          )
                          r2
                          on
                                 r1.floor   =r2.floor
                                 and r1.room=r2.room
                                 and r1.date=r2.maxdate
            order by
                   (r1.floor
                 , r1.room)
     )
select *
from
       (
              select
                     floor
                   , room
                   , did
                   , new_cap
              from
                     cleaned_rooms_CTE
              except
              select
                     cr.floor
                   , cr.room
                   , cr.did
                   , cr.new_cap
              from
                     cleaned_rooms_CTE cr
                     join
                            conflicting_sessions_CTE s
                            on
                                   cr.floor   =s.floor
                                   and cr.room=s.room
       )
       ans
order by
       (ans.new_cap) asc
;

end;
$$ LANGUAGE PLPGSQL;
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
SET    temp = $3
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
                   s.booker_eid
                 , s.datetime
                 , s.room
                 , s.floor
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
       get_meetings gm
     , Sessions     s
WHERE
       gm.datetime           >= curr_date - INTERVAL '3 days'
       AND s.booker_eid       = gm.booker_eid
       AND s.participant_eid <> $1 -- dont want fever fella
       AND gm.room            = s.room
       AND gm.floor           = s.floor
;

END;
$$ LANGUAGE plpgsql;
/**
* ADMIN ROUTINES
*/
CREATE OR REPLACE FUNCTION view_manager_report (start_date DATE, manager_eid INTEGER)
RETURNS TABLE (floor_no                                    INTEGER, room_no INTEGER, date DATE, start_hour TIMESTAMP, eid INTEGER) AS $$
BEGIN
IF NOT EXISTS
(
       SELECT
              1
       FROM
              Manager m
       WHERE
              m.eid = manager_eid
)
THEN RETURN QUERY
(
       SELECT
              floor
            , room
            , datetime::DATE
            , datetime::TIMESTAMP
            , participant_eid
       FROM
              Sessions
       WHERE
              booker_eid ISNULL
)
;
ELSE RETURN QUERY
(
       SELECT
              s.floor
            , s.room
            , s.datetime::DATE
            , s.datetime::TIMESTAMP
            , s.participant_eid
       FROM
              Sessions      s
            , Meeting_rooms r
            , Employees     e
       WHERE
              s.approving_manager_eid ISNULL
              AND datetime::DATE >= start_date
              AND e.eid           = manager_eid --link manager to employees
              AND s.floor         = r.floor     --link sessions to meeting_rooms
              AND s.room          = r.room      --link sessions to meeting_rooms
              AND e.did           = r.did       --manager's did same as room's did
       ORDER BY
              datetime::DATE
            , datetime::TIMESTAMP ASC
)
;
END IF;
END
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION non_compliance(sDate DATE, eDate DATE)
RETURNS TABLE (eid                              INTEGER, nDays BIGINT)
AS $$
BEGIN
IF sDate > eDate THEN RAISE EXCEPTION 'The start date % is after the end date %', sDate, eDate;
END IF;
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
                   e.eid
                 , gd.date
            FROM
                   Employees e
                 , gen_date  gd
     )
   ,
      -- get all eid and dates not declared
     eid_not_declared_on AS
     (
            SELECT
                   ed.eid
                 , ed.date
            FROM
                   eid_date ed
            EXCEPT
            SELECT
                   hd.eid
                 , hd.date
            FROM
                   Health_Declaration hd
     )
SELECT
       endo.eid
     , COUNT(endo.date) nDays
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
SELECT DISTINCT
       s.floor
     , s.room
     , s.datetime
     , CASE
              WHEN s.approving_manager_eid IS NULL
                     THEN false
                     ELSE true
       END AS is_approved
FROM
       Sessions      s
     , Meeting_Rooms mr
     , Employees     e
WHERE
       e.eid           = $1
       AND e.did       = mr.did --same department
       AND s.datetime >= start_date::timestamp
ORDER BY
       datetime ASC
;

END;
$$ LANGUAGE plpgsql;
--update future meetings of close contacts
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
CREATE TRIGGER assign_email_add BEFORE
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
            SELECT
                   js.eid booker_id
            FROM
                   (
                          SELECT
                                 eid
                          FROM
                                 Junior
                          UNION
                          SELECT
                                 eid
                          FROM
                                 Senior
                   )
                   js
            ORDER BY
                   random()
            LIMIT  n
     )
   , rand_room AS
     (
            SELECT
                   rname
                 , floor
                 , room
            FROM
                   meeting_rooms
            OFFSET random() *
                   (
                          SELECT
                                 count(*)
                          FROM
                                 meeting_rooms
                   )
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
       CONFLICT(participant_eid, datetime, booker_eid, room, floor) -- primary key
       DO NOTHING
;

-- strictly  for dummy data;
END
;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION view_future_meeting(sDate DATE, eid INTEGER)
RETURNS TABLE(floor                                  INTEGER, room INTEGER, dateStart TIMESTAMP)
AS $$
DECLARE startTimestamp TIMESTAMP := $1::TIMESTAMP; -- casts date to timestamp
BEGIN
RETURN QUERY
SELECT
       s.floor
     , s.room
     , s.datetime
FROM
       Sessions s
WHERE
       s.datetime           >= startTimestamp
       AND s.participant_eid = $2
ORDER BY
       s.datetime ASC
;

END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION get_procedure()
RETURNS TABLE(procedure name) AS $$
BEGIN
RETURN QUERY
SELECT
       p.proname as procedure
FROM
       pg_proc p
       join
              pg_namespace n
              on
                     p.pronamespace = n.oid
WHERE
       n.nspname not in ('pg_catalog'
                       , 'information_schema')
       and p.prokind = 'p'
;

END;
$$ LANGUAGE plpgsql;
-- Prevent deleting of employees, use remove_employee instead.
CREATE OR REPLACE FUNCTION stop_delete_employee()
RETURNS trigger AS $$
BEGIN
RAISE EXCEPTION 'Unable to delete record directly. Please use remove_employee';
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER stop_delete_statement BEFORE
DELETE
ON
       Employees FOR EACH STATEMENT EXECUTE FUNCTION stop_delete_employee()
;

-- Additional check for consistency of database w.r.t contact tracing should database admin use insert instead of procedures
CREATE OR REPLACE FUNCTION check_sessions_blacklist() RETURNS TRIGGER AS $$
BEGIN
DELETE
FROM
       Sessions s
WHERE
       s.participant_eid IN
       (
              SELECT
                     be.eid
              FROM
                     blacklist_employees be
              WHERE
                     s.datetime     >= be.sDate::TIMESTAMP
                     AND s.datetime <= be.eDate::TIMESTAMP
       );
RETURN NULL
;

END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER check_sessions_blacklist_trigger AFTER
UPDATE
       OR
INSERT
ON
       Sessions FOR EACH ROW EXECUTE FUNCTION check_sessions_blacklist()
;
