--deletes all rows from the following
TRUNCATE Departments, Meeting_Rooms,Employees,Health_Declaration CASCADE;

/**
 * Tests to run (copy and paste)
 */
 
 
 -- add department
 
 -- add employee
 
 -- remove department
 
 -- add room
 
 -- change capacity
 
 -- declare health
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
 -- see non compliance
 
 -- booking a room
 
 -- joining a meeting
 
 -- approving a meeting
 
 -- joining a meeting after it's approved
 
 -- leaving an approved meeting
 
 -- unbook a room
 
 -- viewing booking report
 
 -- contact tracing
 
 /**
  * End of tests
  */
 
 