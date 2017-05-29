#!/bin/bash
# Juan Manuel Torres - https://github.com/Tedezed
set -e

echo "v0.0.3"
git config --global http.sslverify false

echo "* Copiando etc odoo"
FILE="/etc/odoo/odoo.conf"
if [ ! -f $FILE ]; then
    cp /conf-odoo/* /etc/odoo

    # # Admin random pass Odoo
    # choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
    # MASTER_PASS="$({ 
    #   choose '0123456789'
    #   choose 'abcdefghijklmnopqrstuvwxyz'
    #   choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    #   for i in $( seq 1 $(( 18 + RANDOM % 6 )) )
    #      do
    #         choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    #      done
    #  } | sort -R | awk '{printf "%s",$1}')"
    echo "admin_passwd = $MASTER_PASS" >> /etc/odoo/odoo.conf
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}

#echo "* Copiando addons"
#FILE="/mnt/extra-addons/db-hosts.sh"
#if [ ! -f $FILE ]; then
#    echo "No se copiara nada"
#    #cp -R -n /odoo-files/* /mnt/extra-addons
#fi

#DOM PS
echo "$KMINION $PS_DOMAIN" >> /etc/hosts

echo "* Asignando permisos"
chown -R odoo:odoo /mnt/extra-addons
chown -R odoo:odoo /var/lib/odoo

echo "* check_config odoo"
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

echo "Iniciando odoo 10"
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1