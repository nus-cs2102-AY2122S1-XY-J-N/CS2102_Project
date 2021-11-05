/**
* SQL commands to create application's database scheme
**/

/**
 * Drop all procedures, functions and triggers
 */
DROP FUNCTION IF EXISTS updates_check() CASCADE;
DROP PROCEDURE IF EXISTS remove_employee(integer,date) CASCADE;
DROP PROCEDURE IF EXISTS remove_department(integer) CASCADE;
DROP PROCEDURE IF EXISTS add_employee(character varying,character varying,character varying,integer) CASCADE;
DROP PROCEDURE IF EXISTS approve_meeting(integer,integer,date,integer,integer,integer) CASCADE;
DROP PROCEDURE IF EXISTS leave_meeting(integer,integer,date,integer,integer,integer) CASCADE;
DROP PROCEDURE IF EXISTS join_meeting(integer,integer,date,integer,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS search_room(integer,date,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS view_booking_report(integer,date) CASCADE;
DROP PROCEDURE IF EXISTS add_sessions(integer,integer,integer,integer,integer,timestamp without time zone,character varying) CASCADE;
DROP PROCEDURE IF EXISTS add_random_sessions(integer) CASCADE;
DROP FUNCTION IF EXISTS view_future_meeting(date,integer) CASCADE;
DROP FUNCTION IF EXISTS get_name_initials(character varying) CASCADE;
DROP FUNCTION IF EXISTS assign_email() CASCADE;
DROP FUNCTION IF EXISTS remove_future_meetings_on_fever() CASCADE;
DROP FUNCTION IF EXISTS remove_future_meetings_on_retire() CASCADE;
DROP PROCEDURE IF EXISTS add_department(integer,character varying) CASCADE;
DROP PROCEDURE IF EXISTS add_room(character varying,integer,integer,integer) CASCADE;
DROP PROCEDURE IF EXISTS change_capacity(integer,integer,integer,integer,date) CASCADE;
DROP PROCEDURE IF EXISTS declare_health(integer,date,numeric) CASCADE;
DROP FUNCTION IF EXISTS view_manager_report(date,integer) CASCADE;
DROP FUNCTION IF EXISTS stop_delete_employee() CASCADE;
DROP FUNCTION IF EXISTS contact_tracing(integer) CASCADE;
DROP FUNCTION IF EXISTS non_compliance(date,date) CASCADE;
DROP PROCEDURE IF EXISTS unbook_room(integer,integer,date,integer,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS assign_fever() CASCADE;	
DROP PROCEDURE IF EXISTS book_room(integer,integer,date,integer,integer,integer) CASCADE;

DROP TRIGGER IF EXISTS assign_email_add ON employees;
DROP TRIGGER IF EXISTS assign_fever_trig ON health_declaration;
DROP TRIGGER IF EXISTS check_fever ON health_declaration;
DROP TRIGGER IF EXISTS retire_employee ON employees;
DROP TRIGGER IF EXISTS stop_delete_statement ON employees;
DROP TRIGGER IF EXISTS updates_check_trigger ON updates;

DROP TABLE IF EXISTS Health_Declaration
   , Employees
   , Departments
   , Sessions
   , Meeting_Rooms
   , Updates CASCADE
;

DROP VIEW IF EXISTS
Junior,
Senior,
Manager
;

--schema for TABLE
CREATE TABLE Departments
       (
              did   INTEGER PRIMARY KEY
            , dname VARCHAR(50)
       )
;

CREATE TABLE Employees
       (
              eid SERIAL PRIMARY KEY
            , ename        VARCHAR(50) NOT NULL
            , email        TEXT UNIQUE
            , home_contact VARCHAR(50)
            ,
               --design decision
              hp_contact     VARCHAR(50) NOT NULL
            , office_contact VARCHAR(50)
            , resigned_date  DATE
            , did            INTEGER REFERENCES Departments(did)
            , kind           VARCHAR(7)
            ,
               -- junior, senior or manager ISA
              CONSTRAINT Chk_kind CHECK ( kind IN ('Junior'
                                                 , 'Senior'
                                                 , 'Manager') )
       )
;

CREATE TABLE Health_Declaration
       (
              eid   INT REFERENCES Employees (eid)
            ,       date DATE
            , temp  DECIMAL
            , fever BOOLEAN
            ,
               -- trigger IF/ WHEN ADD
              PRIMARY KEY (date, eid)
       )
;

CREATE TABLE Meeting_Rooms
       (
              rname VARCHAR(50)
            , floor  INTEGER
            , room INTEGER
            , did   INTEGER REFERENCES Departments(did)
            , PRIMARY KEY (floor, room)
       )
;

CREATE TABLE Updates
       (
              date DATE
            , approving_eid INTEGER
            , new_cap INTEGER CHECK (new_cap > 0)
            , floor    INTEGER
            , room   INTEGER
            , PRIMARY KEY (approving_eid, date, floor, room)
            , FOREIGN KEY (floor, room) REFERENCES Meeting_Rooms (floor, room)
       )
;

CREATE TABLE Sessions
       (
              participant_eid INT REFERENCES Employees(eid)
            ,
               --some employee who joins the meeting
              approving_manager_eid INT REFERENCES Employees(eid)
            ,
               --check here
              booker_eid INT REFERENCES Employees(eid)
            ,
              floor INTEGER NOT NULL
            
              ,room INTEGER NOT NULL
             ,datetime TIMESTAMP
             
            , rname VARCHAR(50)
              -- must  include room
             , FOREIGN KEY (floor, room) REFERENCES Meeting_Rooms (floor, room)
            , PRIMARY KEY(participant_eid, datetime, booker_eid, floor, room )
			, CHECK (to_char(datetime, 'YYYY:DD:HH24:MI:SS') LIKE '%00:00') -- check that ends in an hour
       )
;

--views
CREATE VIEW Junior AS
       (
              SELECT
                     eid
              FROM
                     Employees
              WHERE
                     kind = 'Junior'
       )
;

CREATE VIEW Senior AS
       (
              SELECT
                     eid
              FROM
                     Employees
              WHERE
                     kind = 'Senior'
       )
;

CREATE VIEW Manager AS
       (
              SELECT
                     eid
              FROM
                     Employees
              WHERE
                     kind = 'Manager'
       )
;

CREATE OR REPLACE VIEW session_pax
 AS
 SELECT count(sessions.participant_eid) AS pax,
    sessions.approving_manager_eid,
    sessions.booker_eid,
    sessions.floor,
    sessions.room,
    sessions.datetime,
    sessions.rname
   FROM sessions
  GROUP BY sessions.approving_manager_eid, sessions.booker_eid, sessions.floor, sessions.room, sessions.datetime, sessions.rname;
  