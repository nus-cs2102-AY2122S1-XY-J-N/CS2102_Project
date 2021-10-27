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
                        , ename        VARCHAR(50)
                        , email        TEXT UNIQUE
                        , home_contact VARCHAR(50)
                        ,
                           --design decision
                          hp_contact     VARCHAR(50)
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
                        , room  INTEGER
                        , floor INTEGER
                        , did   INTEGER REFERENCES Departments(did)
                        , PRIMARY KEY (floor, room)
             )
;

CREATE TABLE Updates
             (
                                        date DATE
                        , approving_eid INTEGER DEFAULT NULL
                        , --trigger needed to check if eid is a manager
                          new_cap INTEGER CHECK (new_cap > 0)
                        , room    INTEGER
                        , floor   INTEGER
                        , PRIMARY KEY (date, approving_eid, room, floor)
                        , FOREIGN KEY (room, floor) REFERENCES Meeting_Rooms (room, floor)
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
                           --the booker  (trigger)
                          room INTEGER NOT NULL
                        ,
                           --must include room
                          floor INTEGER NOT NULL
                        ,
                           -- must  include room
                          FOREIGN KEY (room, floor) REFERENCES Meeting_Rooms (room, floor)
                        ,       time TIME
                        ,       date DATE
                        , rname VARCHAR(50)
                        , PRIMARY KEY( participant_eid, time, date, booker_eid, room, floor )
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

/**
* Triggers to prevent direct access
*/
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