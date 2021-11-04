--deletes all rows from the following
TRUNCATE Departments, Meeting_Rooms,Employees,Health_Declaration CASCADE;

/**
 * Tests to run (copy and paste)
 */
 
 -- add department
 SELECT * FROM Departments;
 
CALL add_department(9, 'Department Test 1');
CALL add_department(10, 'Department Test 2');
CALL add_department(11, 'Department Test 3');

 -- remove department
CALL remove_department(11);


 -- add employee
SELECT * FROM employees;
CALL add_employee('Nigel', '+65 8888 8888', 'Manager', 9);
CALL add_employee('Xi Yuan', '+65 8888 6666', 'Senior', 9);
CALL add_employee('Jerrell', '+65 8888 7777', 'Senior', 9); 
CALL add_employee('Junior Test' , '+65 9999 4444', 'Junior', 9);
CALL add_employee('Junior not from our department', '+65 999', 'Junior', 8);

 -- add room
SELECT * FROM Meeting_Rooms;
CALL add_room('ALR', 10, 10, 9);
CALL add_room('ALR 1', 10, 11, 9);
CALL add_room('ALR 2', 10, 12, 9);

 -- change capacity --> needed for search rooms
SELECT * FROM Updates;
SELECT * FROM Employees;
	-- junior change capacity
	CALL change_capacity(30, 10, 10, 5, current_date); -- throws you are not a manager
	-- senior change capacity
	CALL change_capacity(27, 10, 10, 5, current_date); -- throws you are not a manager
	-- manager change capacity
	CALL change_capacity(26, 10, 10, 5, current_date); --  success ALR
	CALL change_capacity(26, 10, 11, 5, current_date); --  success ALR1
	CALL change_capacity(26, 12, 10, 5, current_date); --  success ALR2


 -- declare health
 -- should see fever dependent on temperature declaration.
SELECT * FROM Health_Declaration;
CALL declare_health (1, current_date, 36.6);
CALL declare_health (2, current_date, 36.5);
CALL declare_health (3, current_date, 36.6);
CALL declare_health (4, current_date, 38.0); --fever
CALL declare_health (5, current_date, 36.5);
CALL declare_health (6, current_date, 36.9);
CALL declare_health (7, current_date, 36.4);
CALL declare_health (8, current_date, 36.2);
CALL declare_health (9, current_date, 36.9);
CALL declare_health (10, current_date, 36.9);
CALL declare_health (11, current_date, 37.9);	--fever
CALL declare_health (12, current_date, 36.6);
CALL declare_health (13, current_date, 36.3);
CALL declare_health (14, current_date, 37.4);
CALL declare_health (15, current_date, 37.4);
CALL declare_health (16, current_date, 36.2);
CALL declare_health (17, current_date, 37.9); --fever
CALL declare_health (18, current_date, 36.0);
CALL declare_health (19, current_date, 37.6); --fever
CALL declare_health (20, current_date, 36.2);
-- employees 21 to 25 (our additions have NOT declared for today) have 2 etc.

 -- see non compliance
SELECT * FROM non_compliance(current_date, current_date + 1); -- sorts in decreasing days declared, can see our custom additions have 1 day not recorded more.
 
 -- booking a room
 -- reference: ALR = FLOOR 10, ROOM 10, DEPARTMENT 9
	-- junior : eid 29
	-- senior : eid 27
	-- manager : eid 26
	
	-- Junior tries to book a room
		CALL book_room(10,10, current_date, 12, 13, 29); -- throws eid.. is not a manager
	-- Senior books a room
		CALL book_room(10,10, current_date, 12, 14, 27); -- throws no health declaration
		CALL declare_health(27, current_date, 36.5);
		-- success book
	-- Manager books a room with fever
		CALL declare_health(26, current_date, 37.5);
		CALL book_room(10, 10, current_date, 15, 18, 26);
		-- update health declaration
		CALL declare_health(26, current_date, 37.4);
		-- it works now!
	SELECT * FROM Sessions; -- notice 3 hour slot for manager (3-4, 4-5, 5-6), 2 hour slot for senior
	
 -- joining a meeting
  -- reference: manager's booking 3-6
   -- employee joining w/o fever, declared health for today
	CALL join_meeting(10, 10, current_date, 15, 16, 1);
	-- employee trying to join without declaring health for today
	SELECT * FROM NON_COMPLIANCE(current_date, current_date);
	-- for instance, employee eid 25
	CALL join_meeting(10, 10, current_date, 15, 16, 25);
   -- employee joining with fever reference : employee 4 -- cannot join
    CALL join_meeting(10, 10, current_date, 15,16,4);
 -- approving a meeting
	SELECT * FROM Sessions; -- should only see current meeting
	SELECT * FROM Manager M, Employees E where M.eid = E.eid AND E.did = 9; -- only Nigel can approve as same did, eid = 26
	CALL approve_meeting(10, 10, current_date, 15, 18, 26); -- check sessions to see approved
 -- joining a meeting after it's approved
	CALL join_meeting(10, 10, current_date, 15, 16, 3); --meeting approved already!
 
 -- leaving an approved meeting
	SELECT * FROM SESSIONS;
	CALL leave_meeting(10, 10, current_date, 15, 16, 1); -- 1 leaves the meeting --> failed as approved

-- leaving an unapproved meeting
	SELECT * FROM SESSIONS;
	CALL join_meeting(10, 10, current_date, 12, 13, 5); --declared health , no fever
	CALL join_meeting(10, 10, current_date, 12, 13, 6); --declared health , no fever
	
	CALL leave_meeting(10, 10, current_date, 12, 13, 5); -- 5 leaves the meeting
 -- unbook a room
	SELECT * FROM SESSIONS;
 
 -- if meeting is not approved	 and wrong booker eid
	CALL unbook_room(10, 10, current_date, 12, 13, 1);
	
-- if meeting is not approved, and correct booker eid
	CALL unbook_room(10, 10, current_date, 12, 13, 27); -- time slot for 13 - 14 still there, expected.
 -- if meeting is approved
	CALL unbook_room(10, 10, current_date, 15, 17, 26);  -- only left with one entry from 17 - 18, expected
 -- viewing booking report
		-- not a manager
			SELECT * FROM Junior; -- e.g. 5
			SELECT * FROM view_booking_report(5, current_date); -- empty table as expected
		-- manager
			SELECT * FROM Manager; -- e.g. 26
			SELECT * FROM view_booking_report(26, current_date);
 -- contact tracing
 
 /**
  * End of tests
  */
 
 