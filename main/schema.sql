/**
* SQL commands to create application's database scheme
**/
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
  