--deletes all rows from the following
TRUNCATE Departments, Meeting_Rooms,Employees,Health_Declaration CASCADE;

CALL add_department (1, 'Sales');
CALL add_department (2, 'Training');
CALL add_department (3, 'Product Management');
CALL add_department (4, 'Marketing');
CALL add_department (5, 'Business Development');
CALL add_department (6, 'Services');
CALL add_department (7, 'Sales');
CALL add_department (8, 'Product Management');

CALL add_room ('Buffalo', 1, 1, 5);
CALL add_room ('Eagle', 1, 2, 5);
CALL add_room ('Snake', 1, 3, 4);
CALL add_room ('White-eye', 2, 1, 8);
CALL add_room ('Tortoise', 2, 2, 3);
CALL add_room ('Deer', 2, 3, 8);
CALL add_room ('Blue Racer', 3, 1, 4);
CALL add_room ('Crane', 3, 2, 5);
CALL add_room ('Gray', 3, 3, 2);
CALL add_room ('Stork', 4, 1, 1);
CALL add_room ('Cormorant', 4, 2, 3);
CALL add_room ('Heron', 4, 3, 1);
CALL add_room ('Fisher', 5, 1, 2);
CALL add_room ('Jackrabbit', 5, 2, 5);
CALL add_room ('Raven', 5, 3, 8);

CALL add_employee ('Anna-diane Dentith', '+7 823 623 8994', 'Manager', 2);
CALL add_employee ('Somerset Ruckledge', '+52 707 905 4955', 'Manager', 2);
CALL add_employee ('Julissa Eades', '+386 514 939 1518', 'Manager', 8);
CALL add_employee ('Reese Klesel', '+86 261 880 6053', 'Junior', 1);
CALL add_employee ('Candide Allery', '+57 354 243 8810', 'Junior', 4);
CALL add_employee ('Liva Giacopazzi', '+55 766 477 8836', 'Manager', 8);
CALL add_employee ('Rebekkah Giscken', '+55 887 461 2873', 'Junior', 7);
CALL add_employee ('Clarita Kochlin', '+234 624 288 5382', 'Junior', 6);
CALL add_employee ('Phylys Raatz', '+353 636 356 2036', 'Junior', 1);
CALL add_employee ('Marwin Stoppe', '+62 173 418 0160', 'Senior', 3);
CALL add_employee ('Emmerich Fitzsymonds', '+63 229 610 9884', 'Senior', 8);
CALL add_employee ('Merl Danigel', '+593 138 621 1165', 'Junior', 1);
CALL add_employee ('Jarrid Fairbairn', '+93 344 686 0880', 'Senior', 7);
CALL add_employee ('Athene Havick', '+386 530 723 0530', 'Manager', 5);
CALL add_employee ('Amandie Tegler', '+55 228 837 6855', 'Senior', 1);
CALL add_employee ('Axel Alexandrou', '+63 342 580 2521', 'Senior', 7);
CALL add_employee ('Lottie Craig', '+86 100 767 4477', 'Junior', 1);
CALL add_employee ('Barnard Garnsworthy', '+63 865 417 5689', 'Senior', 8);
CALL add_employee ('Errick Bennough', '+381 266 549 2972', 'Senior', 3);
CALL add_employee ('Aubert Trahmel', '+380 557 174 6238', 'Junior', 6);

