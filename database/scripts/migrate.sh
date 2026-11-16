#!/bin/bash

# Function to parse common parameters
parse_params() {
    local params=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url)
                URL="$2"
                shift 2
                ;;
            --db)
                DATABASE="$2"
                shift 2
                ;;
            --user)
                USER="$2"
                shift 2
                ;;
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --ref-url)
                REF_URL="$2"
                shift 2
                ;;
            --ref-db)
                REF_DATABASE="$2"
                shift 2
                ;;
            --ref-user)
                REF_USER="$2"
                shift 2
                ;;
            --ref-password)
                REF_PASSWORD="$2"
                shift 2
                ;;
            --schemas)
                SCHEMAS="$2"
                shift 2
                ;;
            --script)
                SCRIPT="$2"
                shift 2
                ;;
            --with-data)
                MIGRATE_WITH_DATA="${2,,}"
                shift 2
                ;;
            --with-rollback)
                GENERATE_ROLLBACK="${2,,}"
                shift 2
                ;;
            --tag)
                MIGRATION_TAG="$2"
                shift 2
                ;;
            --table-diff)
                case $2 in
                    inline|separate|off|none)
                        INCLUDE_TABLES="${2,,}"
                        shift 2
                        ;;
                    *)
                        echo -e "${RED}[ ERROR ]:${NC} Unsupported value for '$1': $2"
                        echo "Type $0 help for usage information"
                        exit 1
                        ;;
                    esac
                ;;
            --help|help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}[ ERROR ]:${NC} Unknown option: '$1'"
                echo "Type $0 help for usage information"
                exit 1
                ;;
        esac
    done
}

postpoc_migration() {
    # $1 - migration file with path
    # $2 - rollback file with path

    if [[ -f $1 ]]; then

        tag=`basename ${1}`
        # get first line of changeset for saving
        changeset=`grep -m 1 -Ri "\-\- changeset" $1`
        changeset_id=`echo $changeset | cut -d ":" -f2 | cut -d ' ' -f1`
        changelog_insert="   <include file=\"migrations/${tag}\"/>\n\
    <changeSet id=\"${changeset_id}\" author=\"liquibase\"> <tagDatabase tag=\"${tag}\" keepTagOnRollback=\"true\"/> </changeSet>"

        # remove all chengesets line from file
        sed -i '/^-- changeset.*/d' $1

        # add chengeset line abd liquibase tag comments
        sed -i "/\-\- liquibase formatted sql/a -- tag: ${tag}" $1
        sed -i "/\-\- liquibase formatted sql/a ${changeset}" $1

        if [[ -f $2 ]]; then

            # transform rollback file for insertion into migrations script
            sed -i '/^\-\- liquibase formatted.*/d' $2
            sed -i '/^-- changeset.*/d' $2
            # transform multiline sql commands into single line
            sed -i -e ':a;$!N;s/\n\(.\)/ \1/;ta;P;D' $2
            sed -i '/^$/!s/^/\-\-rollback /' $2

            # add rollback lines into main script
            cat "${2}" >> "${1}"
        fi

        # add info about new migration into root changelog file
        sed -i "/new changelogs will be inserted above/i\ ${changelog_insert}" ${BASE_PATH}/migrations/changelog.xml
    fi
}

# Function to show help
show_help() {
    echo ""
    echo "Migration Tool Help"
    echo "==================="
    echo "Usage: $0 <command> [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  make-migration     Generates a new SQL migration script in migrations folder"
    echo "  update             Performs database migration according to .sql script or all scripts in migrations folder"
    echo "  rollback           Performs rollback database to tag (tags == migrations sql script names)"
    echo "  fake-update        Mark database as migrated to tag(Doesn't change db schema, just insert meta info in liquibase migration history)"
    echo "  help               Show this help message"
    echo ""
    echo "make-migration Options:"
    echo "  --url URL                Database connection URL (default: ${URL})"
    echo "  --db DATABASE            Database name (default: ${DATABASE})"
    echo "  --user DBUSER            Database user (default: ${USER})"
    echo "  --password PASSWORD      Database password (default: ${PASSWORD})"
    echo "  --ref-url REF_URL        Reference database connection URL (default: ${REF_URL})"
    echo "  --ref-db REF_DATABASE    Reference database name (default: ${REF_DATABASE})"
    echo "  --ref-user REF_USER      Reference database user (default: ${REF_USER})"
    echo "  --ref-password PASSWORD  Reference database password (default: ${REF_PASSWORD})"
    echo "  --schemas SCHEMAS        List of schemas separated by commas for diff calculation (default: ${SCHEMAS})"
    echo "  --script SCRIPT          Script name that will be created, if not set, will be generated automaticaly"
    echo "  --with-data WITH_DATA    Flag(possible values: true/false), if used migration will be generated with data migrations (added INSERT command). (default: false)"
    echo "  --with-rollback WITH_RB  Flag(possible values: true/false), if used migration will be generated with rollback commands. (default: ${GENERATE_ROLLBACK})"
    echo "  --table-diff TBL_DIFF    Used migration script will generate sql command for tables schema change.(default: ${INCLUDE_TABLES})"
    echo "                               possible values:"
    echo "                                   inline   - Generate one sql migration file with command for table changing"
    echo "                                   separate - Generates a main migration script without commands related to table migration and another separate file with these commands"
    echo "                                   none/off - Generate one sql migration file WiTHOUT command for table schema changing"
    echo ""
    echo "update Options:"
    echo "  --url URL                Database connection URL (default: ${URL})"
    echo "  --db DATABASE            Database name (default: ${DATABASE})"
    echo "  --user USER              Database user (default: ${USER})"
    echo "  --password PASSWORD      Database password (default: ${PASSWORD})"
    echo "  --script SCRIPT          Specific name for migration script to run, supported xml/sql(default: ${BASE_PATH}/migrations/changelog.xml)"
    echo "  --tag MIGRATION_TAG      Migration tag, if set migration will be done only till tag (optional)"
    echo ""
    echo "rollback Options:"
    echo "  --url URL                Database connection URL (default: ${URL})"
    echo "  --db DATABASE            Database name (default: ${DATABASE})"
    echo "  --user USER              Database user (default: ${USER})"
    echo "  --password PASSWORD      Database password (default: ${PASSWORD})"
    echo "  --tag MIGRATION_TAG       File name of last migration you want to stay (required)"
    echo "  --script SCRIPT          Path to root changelog with migrations (default: ${BASE_PATH}/migrations/changelog.xml)"
    echo ""
    echo "fake-update Options:"
    echo "  --url URL                Database connection URL (default: ${URL})"
    echo "  --db DATABASE            Database name (default: ${DATABASE})"
    echo "  --user USER              Database user (default: ${USER})"
    echo "  --password PASSWORD      Database password (default: ${PASSWORD})"
    echo "  --tag MIGRATION_TAG      File name of migration that satisfying current database schemas (required)"
    echo "  --script SCRIPT          Path to root changelog with migrations (default: ${BASE_PATH}/migrations/changelog.xml)"
    echo ""
    echo "Examples:"
    echo "  $0 make-migration --url \"localhost:5432\" --db=\"mydb\" --user \"myuser\" --password \"mypassword\" --schema \"public,api\" --script \"create_users_table.sql\" --with-data \"true\""
    echo "  $0 make-migration --script baseline_rollback.sql --ref-url alea-vi-pipeline-db-1:5432 --url 192.168.00.1:5433 --db test --with-rollback true"
    echo "  $0 update --url \"localhost:5432\" --db=\"mydb\" --user \"myuser\" --password \"mypassword\" --script \"/path/to/migration.sql\""
    echo "  $0 rollback --url \"localhost:5432\" --db=\"mydb\" --user \"myuser\" --password \"mypassword\" --tag 'custom_migration.sql'"
    echo "  $0 fake-update --tag \"baseline.sql\" --url \"my.prod-database.com:5432\""
    echo ""
}

# Initialize default values
URL="${URL:=localhost:5432}"
DATABASE="${DATABASE:=postgres}"
USER="${DBUSER:=postgres}"
PASSWORD="${PASSWORD:=postgres}"
REF_URL="${REF_URL:=localhost:5432}"
REF_DATABASE="${REF_DATABASE:=postgres}"
REF_USER="${REF_USER:=postgres}"
REF_PASSWORD="${REF_PASSWORD:=postgres}"
SCHEMAS="${SCHEMAS:=public,mart,ml,core,stage,raw,etl,tiger_data,tiger,topology,api_internal,api,geofencing,geonames,notify,event_feed}"
DIFF_TYPES="${DIFF_TYPES:=catalogs,checkconstraints,databasepackage,databasepackagebody,foreignkeys,functions,indexes,primarykeys,sequences,storedprocedures,triggers,uniqueconstraints,views}"
GENERATE_ROLLBACK="${WITH_RB:=true}"
INCLUDE_TABLES="${TBL_DIFF:=inline}"

DOCKER_IMAGE="liquibase/liquibase:4.33"

BASE_PATH=`git rev-parse --show-toplevel 2>/dev/null`
if [[ `echo $?` -ne 0 ]]; then
    if [[ "$PWD" == *"scripts"* && "$PWD" == *"alea-vi-pipeline"* ]]; then
        BASE_PATH=`dirname $PWD`;
    else
        BASE_PATH="$PWD";
    fi
fi

LOCAL_RUN=0
which liquibase > /dev/null
if [[ `echo $?` -eq 0 ]]; then LOCAL_RUN=1; fi

# colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Main script logic
if [[ $# -lt 1 ]]; then
    echo -e "${RED}[ ERROR ]:${NC} No command specified"
    echo "Type $0 help for usage information"
    exit 1
fi

# Hande command and parameters
COMMAND="$1"
shift
parse_params "$@"

case "$COMMAND" in
    make-migration)
        echo -e "${BLUE}[ INFO ]:${NC} Generating new SQL migration script in migrations folder..."
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

        if [[ -z "$SCRIPT" ]]; then
            SCRIPT="${TIMESTAMP}_migration.sql"
        else
            SCRIPT="${TIMESTAMP}_${SCRIPT}"
        fi

        if [[ "$MIGRATE_WITH_DATA" = "true" ]]; then
            DIFF_TYPES="${DIFF_TYPES},data"
        fi

        if [[ "${INCLUDE_TABLES}" = "inline" ]]; then
            DIFF_TYPES="${DIFF_TYPES},tables,columns"
            echo -e "${BLUE}[ INFO ]:${NC} Table schema migration commands will be included"
        fi

        URL="jdbc:postgresql://${URL}"
        REF_URL="jdbc:postgresql://${REF_URL}"
        command="liquibase diff-changelog --changelog-file=migrations/${SCRIPT} \
--url="${URL}/${DATABASE}" --username=$USER --password=$PASSWORD \
--reference-url="${REF_URL}/${REF_DATABASE}" --reference-username=$REF_USER --reference-password=$REF_PASSWORD \
--include-schema=true --include-catalog=true --schemas='${SCHEMAS}' --diff-types='$DIFF_TYPES'"

        if [[ ${LOCAL_RUN} -eq 1 ]]; then
            eval $command
        else
            docker run --rm --network host -v ${BASE_PATH}/migrations:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
        fi

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}[ ERROR ]:${NC} Generation failed see errors above"
            exit 1
        fi

        echo -e "${BLUE}[ INFO ]:${NC} Migration script created: $SCRIPT"

        if [[ "$GENERATE_ROLLBACK" = "true" ]]; then
            echo -e "${BLUE}[ INFO ]:${NC} Generating rollback commands..."

            command="liquibase diff-changelog --changelog-file=migrations/rollback_${SCRIPT} \
--url="${REF_URL}/${REF_DATABASE}" --username=$REF_USER --password=$REF_PASSWORD \
--reference-url="${URL}/${DATABASE}" --reference-username=$USER --reference-password=$PASSWORD \
--include-schema=true --include-catalog=true --schemas='${SCHEMAS}' --diff-types='$DIFF_TYPES'"

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${BASE_PATH}/migrations:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            postpoc_migration "${BASE_PATH}/migrations/${SCRIPT}" "${BASE_PATH}/migrations/rollback_${SCRIPT}"
            rm -rf "${BASE_PATH}/migrations/rollback_${SCRIPT}"
        else
            postpoc_migration "${BASE_PATH}/migrations/${SCRIPT}"
        fi
        echo -e "${YELLOW}[ WARNING ]:${NC} It's AUTO-generated sql file, please, check it before runninig migration at production database."
        echo -e "${BLUE}[ INFO ]:${NC} Migration ${SCRIPT} successfully generated"

        if grep -Ri " TABLE " "${BASE_PATH}/migrations/${SCRIPT}" > /dev/null; then
            echo -e "${YELLOW}[ WARNING ]:${NC} Table changing commands has been detected, please read carefully ${SCRIPT}."
        fi

        if [[ "${INCLUDE_TABLES}" = "separate" ]]; then
            SEP_SCRIPT=${SCRIPT/.sql/_separate.sql}

            echo -e "${BLUE}[ INFO ]:${NC} Generating separate migrations file with commands for tables"

            command="liquibase diff-changelog --changelog-file=migrations/${SEP_SCRIPT} \
--url="${REF_URL}/${REF_DATABASE}" --username=$REF_USER --password=$REF_PASSWORD \
--reference-url="${URL}/${DATABASE}" --reference-username=$USER --reference-password=$PASSWORD \
--include-schema=true --include-catalog=true --schemas='${SCHEMAS}' --diff-types='$DIFF_TYPES,tables,columns'"

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${BASE_PATH}/migrations:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            postpoc_migration "${BASE_PATH}/migrations/${SEP_SCRIPT}"

            echo -e "${BLUE}[ INFO ]:${NC} Separated file ${SEP_SCRIPT} has been created"
            if grep -Ri " TABLE " "${BASE_PATH}/migrations/${SEP_SCRIPT}" > /dev/null; then
                echo -e "${YELLOW}[ WARNING ]:${NC} Table changing commands has been detected, please compare ${SCRIPT} and ${SEP_SCRIPT}."
            fi
        fi
        ;;

    update)
        echo -e "${BLUE}[ INFO ]:${NC} Performing database migration..."
        echo -e "${BLUE}[ INFO ]:${NC} Connection URL: $URL"
        echo -e "${BLUE}[ INFO ]:${NC} Database name: $DATABASE"
        echo -e "${BLUE}[ INFO ]:${NC} Database User: $USER"
        URL="jdbc:postgresql://${URL}"
        dbparams="--url="${URL}/${DATABASE}" --username=$USER --password=$PASSWORD"
        SCRIPT="${SCRIPT:="${BASE_PATH}/migrations/changelog.xml"}"

        if [[ ! -f "${SCRIPT}" ]]; then
            echo -e "${RED}[ ERROR ]:${NC} File not found - '${SCRIPT}'";
            exit 1
        fi

        folder=`dirname ${SCRIPT}`
        file=`basename ${SCRIPT}`

        if [[ "$SCRIPT" == *".sql"* ]]; then
            echo -e "${BLUE}[ INFO ]:${NC} Running specific script: $SCRIPT"
            command="liquibase update --changelog-file=migrations/${file} ${dbparams} && liquibase tag --tag=${file} ${dbparams}"

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${folder}:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            if [[ $? -ne 0 ]]; then
                echo -e "${RED}[ ERROR ]:${NC} Migration failed see errors above"
                exit 1
            fi
        elif [[ "$SCRIPT" == *".xml"* ]]; then
            if [[ -n "${MIGRATION_TAG}" ]]; then
                echo -e "${BLUE}[ INFO ]:${NC} Running migration from file ${SCRIPT} to tag ${MIGRATION_TAG}..."
                command="liquibase update-to-tag --tag=${MIGRATION_TAG} --changelog-file=migrations/${file} ${dbparams}"
            else
                echo -e "${BLUE}[ INFO ]:${NC} Running all migration from file ${SCRIPT}..."
                command="liquibase update --changelog-file=migrations/${file} ${dbparams}"
            fi

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${folder}:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            if [[ $? -ne 0 ]]; then
                echo -e "${RED}[ ERROR ]:${NC} Migration failed see errors above"
                exit 1
            fi
        else
            echo -e "${RED}[ ERROR ]:${NC} Unsupported file extention: ${SCRIPT}"
        fi

        echo -e "${BLUE}[ INFO ]:${NC} Migration completed successfully!"
        ;;

    rollback)
        SCRIPT="${SCRIPT:="${BASE_PATH}/migrations/changelog.xml"}"
        if [[ -z ${MIGRATION_TAG} ]]; then
            echo -e "${RED}[ ERROR ]:${NC} MIGRATION TAG is required! Specify the tag of the migration ('--tag' option) for rolling back."
            exit 1
        fi
        if [[ -f "$SCRIPT" ]]; then
            folder=`dirname ${SCRIPT}`
            file=`basename ${SCRIPT}`
            URL="jdbc:postgresql://${URL}"
            echo -e "${YELLOW}[ WARNING ]:${NC} Rolling back changes to ${MIGRATION_TAG} state"

            dbparams="--url="${URL}/${DATABASE}" --username=$USER --password=$PASSWORD"
            command="liquibase rollback --tag=${MIGRATION_TAG} --changelog-file=migrations/${file} ${dbparams}"

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${folder}:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            if [[ $? -ne 0 ]]; then
                echo -e "${RED}[ ERROR ]:${NC} Rollback failed see errors above"
                exit 1
            fi
        else
            echo -e "${RED}[ ERROR ]:${NC} Migration script is not provided, --script option is required"
            exit 1
        fi
        echo -e "${BLUE}[ INFO ]:${NC} Database successfully rolled back to ${MIGRATION_TAG} state"
        ;;

    fake-update)
        echo -e "${BLUE}[ INFO ]:${NC} Performing a fake update operation..."
        SCRIPT="${SCRIPT:="${BASE_PATH}/migrations/changelog.xml"}"
        if [[ -z ${MIGRATION_TAG} ]]; then
            echo -e "${RED}[ ERROR ]:${NC} MIGRATION TAG is required! Specify the tag of the migration ('--tag' option) for sync."
            exit 1
        fi

        if [[ -f "$SCRIPT" ]]; then
            folder=`dirname ${SCRIPT}`
            file=`basename ${SCRIPT}`
            echo -e "${YELLOW}[ WARNING ]:${NC} Setting database ${DATABASE} as satisfying ${MIGRATION_TAG} tag"

            URL="jdbc:postgresql://${URL}"
            dbparams="--url="${URL}/${DATABASE}" --username=$USER --password=$PASSWORD"
            command="liquibase changelog-sync-to-tag --tag=${MIGRATION_TAG} --changelog-file=migrations/${file} ${dbparams}"

            if [[ ${LOCAL_RUN} -eq 1 ]]; then
                eval $command
            else
                docker run --rm --network host -v ${folder}:/liquibase/migrations:rw --user liquibase ${DOCKER_IMAGE} bash -c "${command}"
            fi

            if [[ $? -ne 0 ]]; then
                echo -e "${RED}[ ERROR ]:${NC} Rollback failed see errors above"
                exit 1
            fi
        fi

        echo -e "${BLUE}[ INFO ]:${NC} Database is marked as migrated to ${MIGRATION_TAG}"
        ;;

    help|--help)
        show_help
        exit 0
        ;;

    *)
        echo -e "${RED}[ ERROR ]:${NC} Unknown command '$COMMAND'"
        show_help
        exit 1
        ;;
esac
