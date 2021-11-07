--deletes all rows from the following
TRUNCATE Departments, Meeting_Rooms,Employees,Health_Declaration CASCADE;

/**
 * Data addition
 */
-- add departments
INSERT INTO Departments VALUES (1, 'Sales');
INSERT INTO Departments VALUES (2, 'Training');
INSERT INTO Departments VALUES (3, 'Product Management');
INSERT INTO Departments VALUES (4, 'Marketing');
INSERT INTO Departments VALUES (5, 'Business Development');
INSERT INTO Departments VALUES (6, 'Services');
INSERT INTO Departments VALUES (7, 'Finance');
INSERT INTO Departments VALUES (8, 'Events Management');

-- add rooms
INSERT INTO Meeting_Rooms VALUES ('Buffalo', 1, 1, 5);
INSERT INTO Meeting_Rooms VALUES ('Eagle', 1, 2, 5);
INSERT INTO Meeting_Rooms VALUES ('Snake', 1, 3, 4);
INSERT INTO Meeting_Rooms VALUES ('White-eye', 2, 1, 8);
INSERT INTO Meeting_Rooms VALUES ('Tortoise', 2, 2, 3);
INSERT INTO Meeting_Rooms VALUES ('Deer', 2, 3, 8);
INSERT INTO Meeting_Rooms VALUES ('Blue Racer', 3, 1, 4);
INSERT INTO Meeting_Rooms VALUES ('Crane', 3, 2, 5);
INSERT INTO Meeting_Rooms VALUES ('Gray', 3, 3, 2);
INSERT INTO Meeting_Rooms VALUES ('Stork', 4, 1, 1);
INSERT INTO Meeting_Rooms VALUES ('Cormorant', 4, 2, 3);
INSERT INTO Meeting_Rooms VALUES ('Heron', 4, 3, 1);
INSERT INTO Meeting_Rooms VALUES ('Fisher', 5, 1, 2);
INSERT INTO Meeting_Rooms VALUES ('Jackrabbit', 5, 2, 5);
INSERT INTO Meeting_Rooms VALUES ('Raven', 5, 3, 8);

-- add employee
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Anna-diane Dentith', '+7 823 623 8994', 'Manager', 2, 'AD1@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Somerset Ruckledge', '+52 707 905 4955', 'Manager', 2, 'SR2@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Julissa Eades', '+386 514 939 1518', 'Manager', 8, 'JE3@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Reese Klesel', '+86 261 880 6053', 'Junior', 1, 'RK4@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Candid, emaile Allery', '+57 354 243 8810', 'Junior', 4, 'CA5@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Liva Giacopazzi', '+55 766 477 8836', 'Manager', 8, 'LG6@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Rebekkah Giscken', '+55 887 461 2873', 'Junior', 7, 'RG7@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Clarita Kochlin', '+234 624 288 5382', 'Junior', 6, 'CK8@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Phylys Raatz', '+353 636 356 2036', 'Junior', 1, 'PR9@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Marwin Stoppe', '+62 173 418 0160', 'Senior', 3, 'MS10@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Emmerich Fitzsymonds', '+63 229 610 9884', 'Senior', 8, 'EF11@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Merl Danigel', '+593 138 621 1165', 'Junior', 1, 'MD12@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Jarrid Fairbairn', '+93 344 686 0880', 'Senior', 7, 'JF13@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Athene Havick', '+386 530 723 0530', 'Manager', 5, 'AH14@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Amandie Tegler', '+55 228 837 6855', 'Senior', 1, 'AT15@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Axel Alexandrou', '+63 342 580 2521', 'Senior', 7, 'AA16@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Lottie Craig', '+86 100 767 4477', 'Junior', 1, 'LC17@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Barnard Garnsworthy', '+63 865 417 5689', 'Senior', 8, 'BG18@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Errick Bennough', '+381 266 549 2972', 'Senior', 3, 'EB19@gsnail.com');
INSERT INTO Employees(ename, hp_contact, kind, did, email) VALUES ('Aubert Trahmel', '+380 557 174 6238', 'Junior', 6, 'AT20@gsnail.com');

INSERT INTO updates VALUES
('2021-11-6',1,5,1,1),
('2021-11-6',1,5,1,2),
('2021-11-6',1,5,1,3),
('2021-11-6',1,8,2,1),
('2021-11-6',1,8,2,2),
('2021-11-6',1,8,2,3),
('2021-11-6',1,10,3,1),
('2021-11-6',1,10,3,2),
('2021-11-6',1,10,3,3);

INSERT INTO sessions(participant_eid, approving_manager_eid, booker_eid, floor, room, datetime, rname) VALUES
(1, 1, 10, 5, 1, '2021-11-7 04:00:00', 'Fisher'),
(2, 2, 11, 5, 1, '2021-11-7 05:00:00', 'Fisher'),
(3, 3, 10, 2, 3, '2021-11-7 06:00:00', 'Deer'),
(4, 1, 11, 5, 1, '2021-11-14 07:00:00', 'Fisher'),
(5, 2, 10, 5, 1, '2021-11-14 08:00:00', 'Fisher'),
(6, 3, 11, 2, 3, '2021-11-14 09:00:00', 'Deer'),
(7, 1, 10, 5, 1, '2021-11-21 10:00:00', 'Fisher'),
(8, 2, 11, 5, 1, '2021-11-21 11:00:00', 'Fisher'),
(9, 3, 10, 2, 3, '2021-11-21 12:00:00', 'Deer'),
(10, 2, 11, 5, 1, '2021-11-21 11:00:00', 'Fisher');
