-- get all triggers
select event_object_schema as table_schema,
       event_object_table as table_name,
       trigger_schema,
       trigger_name,
       string_agg(event_manipulation, ',') as event,
       action_timing as activation,
       action_condition as condition,
       action_statement as definition
from information_schema.triggers
group by 1,2,3,4,6,7,8
order by table_schema,
         table_name;
-- get procedures
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

-- get all procedures
-- drop all procedures, useful for importing a fresh database
-- reference: https://dba.stackexchange.com/questions/122742/how-to-drop-all-of-my-functions-in-postgresql
CREATE OR REPLACE PROCEDURE drop_all_procedures() AS
$$
BEGIN
DO
$do$
DECLARE
   _sql text;
BEGIN
   SELECT INTO _sql
          string_agg(format('DROP %s %s;'
                          , CASE prokind
                              WHEN 'f' THEN 'FUNCTION'
                              WHEN 'a' THEN 'AGGREGATE'
                              WHEN 'p' THEN 'PROCEDURE'
                              WHEN 'w' THEN 'FUNCTION'  -- window function (rarely applicable)
                              -- ELSE NULL              -- not possible in pg 11
                            END
                          , oid::regprocedure)
                   , E'\n')
   FROM   pg_proc
   WHERE  pronamespace = 'public'::regnamespace  -- schema name here!
   -- AND    prokind = ANY ('{f,a,p,w}')         -- optionally filter kinds
   ;

   IF _sql IS NOT NULL THEN
      RAISE NOTICE '%', _sql;  -- debug / check first
      -- EXECUTE _sql;         -- uncomment payload once you are sure
   ELSE 
      RAISE NOTICE 'No fuctions found in schema %', quote_ident(_schema);
   END IF;
END
$do$;
END;
$$ LANGUAGE plpgsql;
-- get all functions