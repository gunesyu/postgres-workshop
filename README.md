## docker-compose
#### 1- reference the latest official docker image for postgres:
  ```yaml
  image: postgres:latest
  ```

#### 2- set the neccessary variables for creating and using user: (*better to use .env files*)
  ```yaml
    ports:
      - "${DB_PORT}:${DB_PORT}"
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
   ```

#### 3- specify a volume for data persistence:
  ```yaml
  volumes:
    - postgres:/var/lib/postgresql/data
   ```

#### 4- in volumes section, reference that:
  ```yaml
    volumes:
        postgres:
  ```

#### 5- up the container: ( *better to use shell scripts* )
  ```bash
  docker compose up -d
  ```

## connect manually
#### 1- using db via **dbeaver** etc.

#### 2- using **container terminal**
  ```bash
  psql
  ```
>error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "root" does not exist

you need to specify which database you're trying to connect:
  ```bash
  psql -U admin -d pg_workshop
  ```

if you don't want to specify a database, you can use default postgres database which is present in every postgresql installation:
  ```bash
  psql -U username postgres
  ```

#### 3- run psql commands on its cli:
  ```bash
  \?
  ```

#### 4- check privileges of current role:
  ```bash
  \du
  ```
  OR
  ```sql
  SELECT * FROM pg_roles WHERE pg_roles.rolname = CURRENT_ROLE;
  ```

#### 5- check users:
  ```sql
  select * from pg_user;
  ```
  ```sql
  SELECT CURRENT_USER;
  ```

#### 6- create user with the same name as container user: (***root***)
  ```sql
  CREATE USER root SUPERUSER CREATEROLE
  ```

#### 7- create user interactive mode: ***it will also give the LOGIN privilege***
  ```bash
  createuser --interactive <rolename>
  ```

#### 8- create user with password:
  ```sql
  CREATE ROLE "user1" WITH LOGIN PASSWORD 'secretpassword';
  ```
  ``ex. with password expiration:``
  ```sql
  CREATE ROLE "user1" WITH LOGIN PASSWORD 'secretpassword' VALID UNTIL '2050-01-01'
  ```
  ``ex. connection limit:``
  ```sql
  CREATE ROLE "user1" WITH LOGIN PASSWORD 'secretpassword' CONNECTION LIMIT 1000
  ```

#### 9- update user: (***its password***, ***its name***, ***superuser***)
  ```sql
  ALTER ROLE <role> WITH PASSWORD '<password>';
  ```
  ```sql
  ALTER ROLE <role> RENAME TO <newrole>;
  ```
  ```sql
  ALTER ROLE batman SUPERUSER;
  ```
  ```sql
  ALTER ROLE batman NOSUPERUSER;
  ```

#### 10- delete user:
  ```sql
  REASSIGN OWNED BY "user1" TO "myuser";
  DROP OWNED BY "user1";
  DROP ROLE "user1";
  ```

#### 11- Access the objects in the schema that users do not own
  ```sql
  GRANT USAGE ON SCHEMA <schema_name> TO <role_name>;
  ```

#### 12- create a new schema that will be owned by a role
  ```sql
  CREATE SCHEMA IF NOT EXISTS <schema_name> AUTHORIZATION <role_name>;
  ```

#### 13- update schema owner
  ```sql
  ALTER SCHEMA <schema_name> OWNER TO { new_owner | CURRENT_USER | SESSION_USER};
  ```

#### 14- delete schema
  ```sql
  DROP SCHEMA <schema_name> CASCADE;
  ```

#### 15- Grant & Revoke all privileges on all tables in a schema to a role
  ```sql
  GRANT ALL ON ALL TABLES IN SCHEMA "public" TO joe;
  ```
  ```sql
  REVOKE ALL ON film FROM jim;
  ```

#### 16- Group roles
  ```sql
  CREATE ROLE sales;
  CREATE ROLE alice WITH LOGIN PASSWORD 'SecurePass1';
  GRANT sales TO alice;
  GRANT SELECT ON rental TO sales;
  ```
  ```sql
  REVOKE sales FROM alice;
  ```

#### 17- Row level security
  ```sql
  ALTER TABLE table_name FORCE ROW LEVEL SECURITY;
  CREATE POLICY name ON table_name USING (condition);
  ```
  ``exp: managers to departments``
  ```sql
  CREATE ROLE managers;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO managers;
  CREATE ROLE alice WITH LOGIN PASSWORD 'SecurePass1' IN ROLE managers;
  CREATE ROLE bob WITH LOGIN PASSWORD 'SecurePass2' IN ROLE managers;
  ALTER TABLE departments FORCE ROW LEVEL SECURITY;
  CREATE POLICY department_managers ON departments TO managers USING (manager = current_user);

  $ psql -U alice -d hr
  SELECT * FROM departments;
   id | name  | manager
  ----+-------+---------
    1 | Sales | alice

  $ psql -U bob -d hr
  SELECT * FROM departments;
   id |   name    | manager
  ----+-----------+---------
    2 | Marketing | bob
  ```

### connect via app
```
postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?schema=public
```
- ``exp: fallback server``
  >postgresql://username:password@198.51.100.22:3333,198.51.100.33:5555

- ``exp: db name and parameters``
  >postgresql://username:password@198.51.100.22:3333/sales?connect_timeout=10


### create dump - backup
``exp:``
```bash
pg_dump --username=sales_app_user --password --schema-only SALES > sales_database_schema.sql
```

``exp: all of the database schemas except first and second``
```bash
pg_dumpall --schema-only --exclude-database=FIRST --exclude-database=SECOND > almost_all_schemas.sql
```

``exp: multiple databases with a single pattern``
```bash
pg_dumpall --schema-only --exclude-database='SALES_*'  > all_schemas_except_sales.sql
```
``exp: with timestamp`` ***you can create a cron job to run the script periodically***:
```bash
pg_dump -U "$PGUSER" -d "$PGDATABASE" > "$BACKUP_DIR/$PGDATABASE"_"$datestamp"_"$timestamp".sql
```

### restore
  ```bash
  pg_restore [connection-option] [option] [filename]
  ```

``exp: drop and restore``
  ```bash
  $ psql -U postgres
   > drop database dvdrental;
   > create database dvdrental;
   > exit
  $ pg_restore -U postgres -d dvdrental D:/backup/dvdrental.tar
  $ psql -U postgres -d dvdrental
   > \dt
   > exit
  ```

### restart
  ```bash
  sudo systemctl restart postgresql
  # sudo service postgresql restart
  /etc/init.d/postgresql status
  ```

### check uptime
  ```sql
  SELECT current_timestamp - pg_postmaster_start_time() uptime;
  ```

### triggers
lots of BEFORE/AFTER operations like event listeners
  ```sql
  CREATE OR MODIFY TRIGGER trigger_name <WHEN> <EVENT> ON table_name <TRIGGER_TYPE> EXECUTE stored_procedure_name;
  -- WHEN
    -- BEFORE – invoke before the event occurs
    -- AFTER – invoke after the event occurs
  -- EVENT
    -- INSERT – invoke for INSERT
    -- UPDATE – invoke for UPDATE
    -- DELETE – invoke for DELETE
  -- TRIGGER_TYPE
    -- FOR EACH ROW
    -- FOR EACH STATEMENT
  ```
  ``exp:``
  ```sql
  CREATE TRIGGER before_insert_person BEFORE INSERT ON person FOR EACH ROW EXECUTE stored_procedure;
  ```

##
```html

TODO

- vacuum?
- replica?
- sharding?
- scaling?
- load balancing?

```

