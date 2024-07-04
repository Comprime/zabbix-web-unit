#!/bin/ash
# shellcheck shell=dash

set -o pipefail

set +e

# Script trace mode

DEBUG_MODE=$(echo "${DEBUG_MODE}" | awk '{print tolower($0)}')
if [ "${DEBUG_MODE}" = "true" ]; then
    set -o xtrace
fi

WAITLOOPS=5
SLEEPSEC=1

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var fileVar def varValue fileVarValue
	var="$1"
	fileVar="${var}_FILE"
	def="${2:-}"
	varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
	fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
	if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	if [ -n "${varValue}" ]; then
		export "$var"="${varValue}"
	elif [ -n "${fileVarValue}" ]; then
		export "$var"="$(cat "${fileVarValue}")"
	elif [ -n "${def}" ]; then
		export "$var"="$def"
	fi
	unset "$fileVar"
}

# Check prerequisites for MySQL database
check_variables() {
    if [ -z "${DB_SERVER_SOCKET}" ]; then
        : "${DB_SERVER_HOST:="mysql-server"}"
    else
        DB_SERVER_HOST="localhost"
    fi
    : "${DB_SERVER_PORT:="3306"}"

    file_env MYSQL_USER
    file_env MYSQL_PASSWORD

    DB_SERVER_ZBX_USER=${MYSQL_USER:-"zabbix"}
    DB_SERVER_ZBX_PASS=${MYSQL_PASSWORD:-"zabbix"}

    DB_SERVER_DBNAME=${MYSQL_DATABASE:-"zabbix"}
}

db_tls_params() {
    local result=""

    ZBX_DB_ENCRYPTION=$(echo "${ZBX_DB_ENCRYPTION}" | awk '{print tolower($0)}')
    if [ "${ZBX_DB_ENCRYPTION}" = "true" ]; then
        result="--ssl"

        if [ -n "${ZBX_DB_CA_FILE}" ]; then
            result="${result} --ssl-ca=${ZBX_DB_CA_FILE}"
        fi

        if [ -n "${ZBX_DB_KEY_FILE}" ]; then
            result="${result} --ssl-key=${ZBX_DB_KEY_FILE}"
        fi

        if [ -n "${ZBX_DB_CERT_FILE}" ]; then
            result="${result} --ssl-cert=${ZBX_DB_CERT_FILE}"
        fi
    fi

    echo "$result"
}

check_db_connect() {
    echo "********************"
    echo "* DB_SERVER_HOST: ${DB_SERVER_HOST}"
    echo "* DB_SERVER_PORT: ${DB_SERVER_PORT}"
    if [ -n "${DB_SERVER_SOCKET}" ]; then
        echo "* DB_SERVER_SOCKET: ${DB_SERVER_SOCKET}"
    fi
    echo "* DB_SERVER_DBNAME: ${DB_SERVER_DBNAME}"
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "* DB_SERVER_ZBX_USER: ${DB_SERVER_ZBX_USER}"
        echo "* DB_SERVER_ZBX_PASS: ${DB_SERVER_ZBX_PASS}"
    fi
    echo "********************"

    local WAIT_TIMEOUT
    WAIT_TIMEOUT=5

    while true; do
        local CONN_ERR EC
        CONN_ERR="$(php /usr/local/share/docker-entrypoint/dbcheck.php)"
        EC=$?
        [ "${EC}" -eq "0" ] && break
        echo "**** ${DB_SERVER_TYPE} DB server is not available. Waiting $WAIT_TIMEOUT seconds..."
        if [ "${DEBUG_MODE}" = "true" ]; then
            echo "${CONN_ERR}"
        fi
        sleep $WAIT_TIMEOUT
    done
}

prepare_zbx_web_config() {
    echo "** Preparing Zabbix frontend environment"

    export EXPOSE_WEB_SERVER_INFO=${EXPOSE_WEB_SERVER_INFO:-"1"}
    if truthy "${PHP_OPCACHE_PRELOAD}"; then
        export PHP_OPCACHE_PRELOAD="/usr/local/share/docker-entrypoint/preload.php"
        export PHP_OPCACHE_PRELOAD_USER="unit"
    fi

    export PHP_FPM_PM=${PHP_FPM_PM:-"dynamic"}
    export PHP_FPM_PM_MAX_CHILDREN=${PHP_FPM_PM_MAX_CHILDREN:-"50"}
    export PHP_FPM_PM_START_SERVERS=${PHP_FPM_PM_START_SERVERS:-"5"}
    export PHP_FPM_PM_MIN_SPARE_SERVERS=${PHP_FPM_PM_MIN_SPARE_SERVERS:-"5"}
    export PHP_FPM_PM_MAX_SPARE_SERVERS=${PHP_FPM_PM_MAX_SPARE_SERVERS:-"35"}
    export PHP_FPM_PM_MAX_REQUESTS=${PHP_FPM_PM_MAX_REQUESTS:-"0"}

    ZBX_DENY_GUI_ACCESS=$(echo "${ZBX_DENY_GUI_ACCESS-false}" | awk '{print tolower($0)}')
    export ZBX_DENY_GUI_ACCESS=${ZBX_DENY_GUI_ACCESS}
    export ZBX_GUI_ACCESS_IP_RANGE=${ZBX_GUI_ACCESS_IP_RANGE:-"['127.0.0.1']"}
    export ZBX_GUI_WARNING_MSG=${ZBX_GUI_WARNING_MSG:-"Zabbix is under maintenance."}

    export ZBX_MAXEXECUTIONTIME=${ZBX_MAXEXECUTIONTIME:-"600"}
    export ZBX_MEMORYLIMIT=${ZBX_MEMORYLIMIT:-"128M"}
    export ZBX_POSTMAXSIZE=${ZBX_POSTMAXSIZE:-"16M"}
    export ZBX_UPLOADMAXFILESIZE=${ZBX_UPLOADMAXFILESIZE:-"2M"}
    export ZBX_MAXINPUTTIME=${ZBX_MAXINPUTTIME:-"300"}
    export PHP_TZ=${PHP_TZ:-"UTC"}

    export DB_SERVER_TYPE="MYSQL"
    export DB_SERVER_HOST="p:${DB_SERVER_HOST}"
    export DB_SERVER_PORT=${DB_SERVER_PORT}
    export DB_SERVER_DBNAME=${DB_SERVER_DBNAME}
    export DB_SERVER_SCHEMA=${DB_SERVER_SCHEMA}
    export DB_SERVER_USER=${DB_SERVER_ZBX_USER}
    export DB_SERVER_PASS=${DB_SERVER_ZBX_PASS}
    export ZBX_SERVER_HOST=${ZBX_SERVER_HOST}
    export ZBX_SERVER_PORT=${ZBX_SERVER_PORT}
    export ZBX_SERVER_NAME=${ZBX_SERVER_NAME}

    ZBX_DB_ENCRYPTION=$(echo "${ZBX_DB_ENCRYPTION-false}" | awk '{print tolower($0)}')
    export ZBX_DB_ENCRYPTION=${ZBX_DB_ENCRYPTION}
    export ZBX_DB_KEY_FILE=${ZBX_DB_KEY_FILE}
    export ZBX_DB_CERT_FILE=${ZBX_DB_CERT_FILE}
    export ZBX_DB_CA_FILE=${ZBX_DB_CA_FILE}
    ZBX_DB_VERIFY_HOST=$(echo "${ZBX_DB_VERIFY_HOST-false}" | awk '{print tolower($0)}')
    export ZBX_DB_VERIFY_HOST=${ZBX_DB_VERIFY_HOST}

    export ZBX_VAULT=${ZBX_VAULT}
    export ZBX_VAULTURL=${ZBX_VAULTURL}
    export ZBX_VAULTDBPATH=${ZBX_VAULTDBPATH}
    export VAULT_TOKEN=${VAULT_TOKEN}
    export ZBX_VAULTCERTFILE=${ZBX_VAULTCERTFILE}
    export ZBX_VAULTKEYFILE=${ZBX_VAULTKEYFILE}

    DB_DOUBLE_IEEE754=$(echo "${DB_DOUBLE_IEEE754-true}" | awk '{print tolower($0)}')
    export DB_DOUBLE_IEEE754=${DB_DOUBLE_IEEE754}

    export ZBX_HISTORYSTORAGEURL=${ZBX_HISTORYSTORAGEURL}
    export ZBX_HISTORYSTORAGETYPES=${ZBX_HISTORYSTORAGETYPES:-"[]"}

    export ZBX_SSO_SETTINGS=${ZBX_SSO_SETTINGS:-""}
    export ZBX_SSO_SP_KEY=${ZBX_SSO_SP_KEY}
    export ZBX_SSO_SP_CERT=${ZBX_SSO_SP_CERT}
    export ZBX_SSO_IDP_CERT=${ZBX_SSO_IDP_CERT}

    export ZBX_SESSION_NAME=${ZBX_SESSION_NAME:-"zbx_session"}
}

truthy()
{
    ! [ "$1" = "0" ] && ! [ "$1" = "false" ]
}

unit_cmd()
{
    local ret retBody retStatus
    if [ -z "$3" ]; then
        ret=$(curl -s -w '%{http_code}' -X "$1" --unix-socket /var/run/control.unit.sock "http://localhost/$2")
    else
        ret=$(curl -s -w '%{http_code}' -X "$1" --data-binary "$3" --unix-socket /var/run/control.unit.sock "http://localhost/$2")
    fi
    retBody=$(echo "${ret}" | jq -c | head -c -4)
    retStatus=$(echo "${ret}" | tail -c 4)
    if [ "${retStatus}" -ne "200" ]; then
        echo "$0: Error: HTTP response status code is '${retStatus}'"
        echo "${RET_BOD}Y"
        return 1
    else
        echo "$0: OK: HTTP response status code is '${retStatus}'"
        if [ "${DEBUG_MODE}" = "true" ]; then
            echo "  ${retBody}"
        fi
    fi
    return 0
}

unit_app_cfg_part()
{
    echo "$@" | jq -s 'reduce .[] as $i ({}; . * $i)'
}

unit_app_cfg()
{
    local cfgFilter
    cfgFilter="."
    if [ "${PHP_FPM_PM}" = "dynamic" ]; then
        cfgFilter="${cfgFilter} | .applications.zabbix.processes = {max: (\"${PHP_FPM_PM_MAX_CHILDREN-1}\" | tonumber), spare: (\"${PHP_FPM_PM_START_SERVERS-1}\" | tonumber), idle_timeout: 32}"
        if [ "${PHP_FPM_PM_MAX_REQUESTS}" -gt "0" ]; then
            cfgFilter="${cfgFilter} | .applications.zabbix.limits.requests = (\"${PHP_FPM_PM_MAX_REQUESTS}\" | tonumber)"
        fi
    fi
    if [ "${EXPOSE_WEB_SERVER_INFO}" != "true" ]; then
        cfgFilter="${cfgFilter} | .settings.http.server_version = false"
    fi
    cfgFilter="$(jq -cM "${cfgFilter}" /usr/local/share/docker-entrypoint/zabbix.unit.json)"
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo " * Unit CFG: ${cfgFilter}"
    fi
    unit_cmd PUT config "${cfgFilter}"
}

prepare_unit() {
    if find "/var/lib/unit/" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        echo "$0: /var/lib/unit/ is not empty, skipping initial configuration..."
    else
        echo "$0: Launching Unit daemon to perform initial configuration..."
        $1 --control unix:/var/run/control.unit.sock

        for _ in $(seq $WAITLOOPS); do
            if [ ! -S /var/run/control.unit.sock ]; then
                echo "$0: Waiting for control socket to be created..."
                sleep $SLEEPSEC
            else
                break
            fi
        done
        # even when the control socket exists, it does not mean unit has finished initialisation
        # this curl call will get a reply once unit is fully launched
        unit_cmd GET
    
        unit_app_cfg
        unit_cmd GET

        echo "$0: Stopping Unit daemon after initial configuration..."
        kill -TERM "$(cat /var/run/unit.pid)"

        for _ in $(seq $WAITLOOPS); do
            if [ -S /var/run/control.unit.sock ]; then
                echo "$0: Waiting for control socket to be removed..."
                sleep $SLEEPSEC
            else
                break
            fi
        done
        if [ -S /var/run/control.unit.sock ]; then
            kill -KILL "$(cat /var/run/unit.pid)"
            rm -f /var/run/control.unit.sock
        fi

        echo
        echo "$0: Unit initial configuration complete; ready for start up..."
        echo
    fi
}

if [ "$1" = "unitd" ] || [ "$1" = "unitd-debug" ]; then
    check_variables
    prepare_zbx_web_config
    check_db_connect
    prepare_unit "$1"
fi

exec "$@"