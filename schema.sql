/**
* SQL commands to create application's database scheme
**/
--table declaration
DROP TABLE IF EXISTS Health_Declaration CASCADE
;

DROP TABLE IF EXISTS Employees CASCADE
;

DROP TABLE IF EXISTS Departments CASCADE
;

DROP TABLE IF EXISTS Sessions CASCADE
;

DROP TABLE IF EXISTS Meeting_Rooms CASCADE
;

--isa
DROP VIEW IF EXISTS Junior;
DROP VIEW IF EXISTS Senior;
DROP VIEW IF EXISTS Manager;
--relations
DROP TABLE IF EXISTS Updates CASCADE
;

DROP TABLE IF EXISTS Declare_Temp CASCADE
; -- DATE, EID
--schema for TABLE
CREATE TABLE Departments
             (
                          did   INTEGER PRIMARY KEY
                        , dname VARCHAR(50)
             )
;

CREATE TABLE Employees
             (
                          eid   INTEGER PRIMARY KEY
                        , ename VARCHAR(50)                        , email VARCHAR(50) UNIQUE
                        , --trigger to check for @
                          home_contact INTEGER
                        , --design decision
                          hp_contact     INTEGER
                        , office_contact INTEGER                        , resigned_date  DATE
                        , did            INTEGER REFERENCES Departments(did)
                        , kind           VARCHAR(7)
                        , -- junior, senior or manager ISA
                          CONSTRAINT Chk_kind CHECK (kind IN ('Junior'
                                                            ,'Senior'
                                                            , 'Manager'))
             )
;

CREATE TABLE Health_Declaration             (                          eid   INT REFERENCES Employees (eid)                ,       date DATE             , temp  DECIMAL
                        , fever BOOLEAN
                        , -- trigger IF/ WHEN ADD
                          PRIMARY KEY (date, eid)
             )
;

CREATE TABLE Updates
             ( --update capacity
                          floor   INTEGER
                        , room    INTEGER
                        ,         date DATE
                        , new_cap INTEGER
                        , PRIMARY KEY (date, floor, room)
             )
;
CREATE TABLE Meeting_Rooms
             (                                date DATE
                        , rname VARCHAR(50)                       , room  INTEGER
                        , floor INTEGER                        , did   INTEGER REFERENCES Departments(did) NOT NULL
                        , --must include one
                          PRIMARY KEY (floor, room)
                        , FOREIGN KEY (date, floor, room) REFERENCES Updates (date, floor, room) ON
UPDATE
       CASCADE -- derived
             )
; CREATE TABLE Sessions
             (
                          Joins_eid INT REFERENCES Employees(eid)                      , --some employee who joins the meeting
                          Manager_eid INT REFERENCES Employees(eid)
                        , --check here
                          Booker_eid INT REFERENCES Employees(eid)                        , --the booker  (trigger)
                          room INTEGER NOT NULL                       , --must include room
                          floor INTEGER NOT NULL                        , -- must  include room
                          FOREIGN KEY (room, floor) REFERENCES Meeting_Rooms (room, floor)
                        ,       time TIME                    ,       date DATE
                        , rname VARCHAR(50)                     , PRIMARY KEY(Joins_eid, time, date, Booker_eid, room, floor)
             )
;

--views
CREATE VIEW Junior AS  (
                   SELECT              eid
                   FROM                         Employees
                   WHERE                          kind = 'Junior'
            )
;

CREATE VIEW Senior AS            (
                   SELECT                          eid
                   FROM                          Employees
                   WHERE                          kind = 'Senior'
            )
;

CREATE VIEW Manager AS            (                   SELECT
                          eid
                   FROM                          Employees                   WHERE
                          kind = 'Manager'
            )
;