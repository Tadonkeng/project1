# Mission DevOps PostgreSQL Check Job
The PostgreSQL check job can be used to validate the following:
 1. An application's RDS database has been provisioned
 2. The necessary credentials environment variables have been made available in the application's namespace
 3. Privileges for the read-write, read-only, and admin RDS user accounts have been set correctly

## How Can I Use PostgreSQL Check Job?
The PostgreSQL check job can be deployed by copying the postgres check pod configuration tree into an application's
manifest repository.  There is no per-application configuration required for the job to run properly.  Make sure to
reference the debug-pods/postgres directory in the application's main kustomization.yaml file.

### Directory Tree Within the Application Manifests Repo
    .
    ├── README.md
    │
    ├── base
    │   ├── api
    │   │   ├── deployment.yaml
    │   │   ├── kustomization.yaml
    │   │   ├── service.yaml
    │   └── kustomization.yaml
    │
    ├── debug-pods
    │   └── postgres
    │       ├── README.md
    │       ├── job.yaml
    │       ├── kustomization.yaml
    │       ├── scripts
    │       │   └── postgresql-check.sh
    │       └── tests
    │           ├── create-table.sql
    │           ├── delete.sql
    │           ├── drop-table.sql
    │           ├── grant-ro.sql
    │           ├── grant-rw.sql
    │           ├── grant-usage-rw.sql
    │           ├── insert.sql
    │           ├── select.sql
    │           └── update.sql
    │
    └── il2
        ├── base
        │   └── kustomization.yaml
        └── overlays
            ├── prod
            │   └── kustomization.yaml
            └── staging
                └── kustomization.yaml


## How Does the PostgreSQL Check Job Work?
There is a set of SQL template scripts and a main bash script used to populate each template and execute the queries.
The postgresql-check.sh bash script is used as the docker entrypoint.  It generates .pgpass file with entries for the
admin, read-write, and read-only users.  Then the run_sql_file function defined in the script is used to run the
different sql scripts in the tests folder.

## How Can I Add New SQL Queries?
Adding new SQL queries requires the following:
 1. Add a new file containing the SQL query to the repository's tests folder
 2. Update the kustomization.yaml file's configMapGenerator section
 3. Add a reference to the new file to the volumes.configMap.items section in job.yaml
 4. Update the scripts/postgresql-check.sh to include a call to the new SQL file