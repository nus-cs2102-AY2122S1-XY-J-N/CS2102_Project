/**
* SQL  or  PL/pgSQL routines of implementation
**/

--basic
CREATE OR REPLACE PROCEDURE add_department
(IN did INTEGER, IN dname VARCHAR(50))
AS $$
INSERT INTO departments VALUES
       (did
            , dname
       )
       $$ LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE remove_department
(IN target_did INTEGER)
AS $$
DELETE
FROM
       departments
WHERE
       did = target_did $$ LANGUAGE sql
;

/**
 * Routines for adding employee
 */
CREATE OR REPLACE PROCEDURE add_employee
(IN ename VARCHAR(50), hp_contact INTEGER, kind VARCHAR(7), did INTEGER)
AS $$
INSERT INTO employees(ename, hp_contact, kind, did) VALUES
(ename, hp_contact, kind, did)
$$ LANGUAGE sql;

-- extracting initials for email generation
DROP FUNCTION IF EXISTS get_name_initials(VARCHAR(50));
CREATE OR REPLACE FUNCTION get_name_initials(VARCHAR(50))
RETURNS VARCHAR(10) AS $$
DECLARE
initials VARCHAR(50) := '';
letter   VARCHAR := '';
BEGIN
FOREACH letter IN ARRAY string_to_array($1, ' ')
LOOP
initials := initials || substr(letter, 1, 1);
END LOOP;
RETURN initials;
END;
$$ LANGUAGE plpgsql;

-- create email and assign for employee
CREATE OR REPLACE FUNCTION assign_email()
	RETURNS trigger AS $$
	DECLARE 
		Eprefix VARCHAR(1) := '';
		Eabbrv VARCHAR(10) := '';
		EmailEnd VARCHAR(11) := '@gsnail.com';
	BEGIN
		CASE
			WHEN NEW.kind = 'Junior' THEN Eprefix := 'J';
			WHEN NEW.kind = 'Senior' THEN Eprefix := 'S';
			WHEN NEW.kind = 'Manager' THEN Eprefix := 'M';
		END case;
		Eabbrv = get_name_initials(NEW.ename);
		NEW.email := CONCAT(Eprefix, Eabbrv, NEW.eid, EmailEnd);
	RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
CREATE OR REPLACE TRIGGER assign_email_add
BEFORE INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION assign_email();
/**
 * End of adding employee routines
 */