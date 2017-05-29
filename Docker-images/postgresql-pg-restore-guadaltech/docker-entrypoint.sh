#!/bin/bash
# Juan Manuel Torres - https://github.com/Tedezed
set -e

if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi

insetar_logo ()
{
	LOGO_BASE64=$@

	psql -U odoo -d odoo -a -c "UPDATE res_company SET logo_web='""$LOGO_BASE64""'::bytea, write_uid=1, write_date=(now() at time zone 'UTC') WHERE id IN (1);"
}

cambio_nombre_compania ()
{
	CONF_NOMBRE=$1

	psql -U odoo -d odoo -a -c "UPDATE res_company SET name='"$CONF_NOMBRE"',write_uid=1,write_date=(now() at time zone 'UTC') WHERE id IN (1)"
	psql -U odoo -d odoo -a -c "UPDATE res_partner SET name='"$CONF_NOMBRE"', display_name='"$CONF_NOMBRE"', commercial_company_name='"$CONF_NOMBRE"' , write_uid=1,write_date=(now() at time zone 'UTC') WHERE id IN (1)"
}

# Falta activar wizard
crear_usuario_odoo_psql ()
{
	nombre=$1
	usuario=$2
	pass=$3

	id_res_partner=$(psql -t -U odoo -d odoo -a -c "SELECT nextval('res_partner_id_seq') from generate_series(1,1)" | grep -v "SELECT nextval('res_partner_id_seq') from generate_series(1,1)" | sed -e 's/^\s*//' -e '/^$/d')
	id_res_user=$(psql -t -U odoo -d odoo -a -c "SELECT nextval('res_users_id_seq') from generate_series(1,1)" | grep -v "SELECT nextval('res_users_id_seq') from generate_series(1,1)" | sed -e 's/^\s*//' -e '/^$/d')
	id_pass_change=$(psql -t -U odoo -d odoo -a -c "SELECT nextval('change_password_user_id_seq') from generate_series(1,1)" | grep -v "SELECT nextval('change_password_user_id_seq') from generate_series(1,1)" | sed -e 's/^\s*//' -e '/^$/d')
	id_pass_wizard=$(psql -t -U odoo -d odoo -a -c "SELECT nextval('change_password_wizard_id_seq') from generate_series(1,1)" | grep -v "SELECT nextval('change_password_wizard_id_seq') from generate_series(1,1)" | sed -e 's/^\s*//' -e '/^$/d')
	echo "$nombre $pass $email - partner_id $id_res_partner user_id $id_res_user" 
	psql -U odoo -d odoo -a -c "INSERT INTO res_partner (id, sale_warn, notify_email, color, tz, opt_out, invoice_warn, company_id, employee, type, email, is_company, picking_warn, customer, supplier, active, lang, name, partner_share, facturae, create_uid, write_uid, create_date, write_date, display_name, purchase_warn) VALUES("$id_res_partner", 'no-message', 'always', 0, NULL, false, 'no-message', 1, false, 'contact', NULL, false, 'no-message', true, false, true, 'es_ES', '"$nombre"', false, false, 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'), '"$nombre"', 'no-message');"
	psql -U odoo -d odoo -a -c "INSERT INTO res_users (id, partner_id, alias_id, active, company_id, action_id, share, password, signature, login, create_uid, write_uid, create_date, write_date) VALUES("$id_res_user", "$id_res_partner", NULL, true, 1, NULL, false, '"$pass"', '<p><br></p>', '"$usuario"', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'));"
	psql -U odoo -d odoo -c "INSERT INTO change_password_wizard (id, create_uid, write_uid, create_date, write_date) VALUES("$id_pass_wizard", 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'));"
	psql -U odoo -d odoo -a -c "INSERT INTO change_password_user (id, user_login, user_id, new_passwd, wizard_id, create_uid, write_uid, create_date, write_date) VALUES("$id_pass_change", '"$usuario"', "$id_res_user", '"$pass"', 1, 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'));"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[21]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[49]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[4]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[1]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[26]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
	psql -U odoo -d odoo -a -c "INSERT INTO res_groups_users_rel (uid, gid) (SELECT a, b FROM unnest(ARRAY["$id_res_user"]) AS a, unnest(ARRAY[39]) AS b) EXCEPT (SELECT uid, gid FROM res_groups_users_rel WHERE uid IN ("$id_res_user"))"
}

crear_cuenta_bancaria ()
{
	NUM_CUENTA=$@

	id_partner_bank=$(psql -t -U odoo -d odoo -a -c "SELECT nextval('res_partner_bank_id_seq') from generate_series(1,1)" | grep -v "SELECT nextval('res_partner_bank_id_seq') from generate_series(1,1)" | sed -e 's/^\s*//' -e '/^$/d')
	psql -U odoo -d odoo -a -c "INSERT INTO res_partner_bank (id, currency_id, partner_id, company_id, bank_id, acc_number, create_uid, write_uid, create_date, write_date) VALUES("$id_partner_bank", NULL, 1, 1, NULL, '""${NUM_CUENTA}""', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'))"
	psql -U odoo -d odoo -a -c "UPDATE account_journal SET bank_account_id=(SELECT id FROM res_partner_bank WHERE acc_number = '""${NUM_CUENTA}""'), write_uid=1, write_date=(now() at time zone 'UTC') WHERE id IN (SELECT id FROM account_journal WHERE type = 'bank' LIMIT 1)"
}

echo "* Ver pre-a-0.0.2.0"
FILE="/var/lib/postgresql/data/PG_VERSION"
if [ -f $FILE ]; then
	echo "[CORRECTO] File $FILE existe"
	FILE2="/var/lib/postgresql/data/postmaster.pid"
	if [ -f $FILE2 ]; then
		echo "[REPARANDO...] File $FILE2 existe por un apagado inadecuado..."
		rm -rf /var/lib/postgresql/data/postmaster.pid
		exec gosu postgres pg_ctl -D "$PGDATA" -m immediate -w start &
		sleep 5

		echo "* Esperando que inicie PostgreSQL"
		key3=true
		while [  "$key3" = true ]; do
			FILE3="/var/lib/postgresql/data/postmaster.pid"
			if [ -f $FILE3 ]; then
				echo "[CORRECTO] File $FILE3 existe"
				exec gosu postgres pg_ctl -D "$PGDATA" -m immediate -w stop
				sleep 5
				key=false
			else
				echo "[ESPERANDO] El fichero $FILE3 no existe"
				echo "Esperando 5s a que el servicio inicie..."
				sleep 5
			fi
		done
	fi
	#echo "Borrando postmaster.pid inicial"
	#rm -rf /var/lib/postgresql/data/postmaster.pid
else
	echo "[ESPERANDO] El fichero $FILE no existe"
	echo "Copiando Backup inicial"
	cp -R /backup/postgresql/data /var/lib/postgresql
	chown postgres:postgres -R /var/lib/postgresql

	sleep 3
	echo "* Arrancando primer arranque PostgreSQL con GOSU"
	exec gosu postgres pg_ctl -D "$PGDATA" -m immediate -w start &
	sleep 5

	echo "* Esperando que inicie PostgreSQL"
	key=true
	while [  "$key" = true ]; do
		FILE="/var/lib/postgresql/data/postmaster.pid"
		if [ -f $FILE ]; then
			echo "[CORRECTO] File $FILE existe"
			key=false
		else
			echo "[ESPERANDO] El fichero $FILE no existe"
			echo "Esperando 3s a que el servicio inicie..."
			sleep 5
		fi
	done

	echo '* Cambiando contraseña para usuario root'
	sleep 5
	psql -U odoo -d odoo -a -c "ALTER USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"

	echo '* Iniciando personalización Updates para Odoo'
	psql -U odoo -d odoo -a -c "UPDATE res_company set phone='$CONF_TELF', email='$CONF_MAIL' where id=1;"
	psql -U odoo -d odoo -a -c "UPDATE res_users set login='$ODOO_USER', password='$ODOO_PASS' where id=1;"
	psql -U odoo -d odoo -a -c "UPDATE res_partner set name='$CONF_NOMBRE',street='$CONF_CALLE',city='$CONF_CIUDAD',zip='$CONF_COD_ZIP', website='$CONF_WEB', phone='$CONF_TELF', mobile='$CONF_TELF_MOVIL', email='$CONF_MAIL', vat='$CONF_DNI' where id=1;"
	psql -U odoo -d odoo -a -c "UPDATE res_users set login='$USER_MOBILE', password='$USER_MOBILE_PASS' where id=6;"
	psql -U odoo -d odoo -a -c "UPDATE res_partner set email='$ODOO_USER' where name='Administrator';"
	psql -U odoo -d odoo -a -c "UPDATE res_partner set email='$ODOO_USER' where name='mobile';"

	if [ $ODOO_TYPE = 'odoo-prestashop' ]; then
		echo "  * POSTGRES-ODOO con PrestaShop";
		psql -U odoo -d odoo -a -c "INSERT INTO "prestashop_configure" ("id", "unlink_ps", "server_db", "user_db", "pass_db", "last_price", "port_db", "pob_default_lang", "pob_default_category", "pref_db", "name_db", "active", "socket_db", "api_key", "create_uid", "write_uid", "create_date", "write_date") VALUES(nextval('prestashop_configure_id_seq'), false, '$MYSQL_SERVER', 'root', '$MYSQL_PASSWD', NULL, 3306, 71, 1, 'ps', 'prestashop', true, '/var/lib/mysql/mysql.sock', '$PS_WEBSERVICE_KEY', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'));"
		psql -U odoo -d odoo -a -c "INSERT INTO "ir_property" ("id", "value_text", "name", "type", "company_id", "fields_id", "res_id", "create_uid", "write_uid", "create_date", "write_date") VALUES(nextval('ir_property_id_seq'), '1', 'property_shopps_id', 'char', 1, 5142, 'prestashop.configure,1', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'))"
		psql -U odoo -d odoo -a -c "INSERT INTO "ir_property" ("id", "value_text", "name", "type", "company_id", "fields_id", "res_id", "create_uid", "write_uid", "create_date", "write_date") VALUES(nextval('ir_property_id_seq'), 'http://$PS_DOMAIN/api', 'property_api_url', 'char', 1, 5137, 'prestashop.configure,1', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'))"
		psql -U odoo -d odoo -a -c "INSERT INTO "ir_property" ("id", "name", "type", "company_id", "fields_id", "value_reference", "res_id", "create_uid", "write_uid", "create_date", "write_date") VALUES(nextval('ir_property_id_seq'), 'property_pob_default_stock_location', 'many2one', 1, 5141, 'stock.location,15', 'prestashop.configure,1', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'))"
		psql -U odoo -d odoo -a -c "INSERT INTO "ir_property" ("id", "value_text", "name", "type", "company_id", "fields_id", "res_id", "create_uid", "write_uid", "create_date", "write_date") VALUES(nextval('ir_property_id_seq'), '0', 'property_shopps_id', 'char', 1, 5142, 'prestashop.configure,1', 1, 1, (now() at time zone 'UTC'), (now() at time zone 'UTC'))"
		psql -U odoo -d odoo -a -c "TRUNCATE ir_attachment CASCADE;"
	else
		echo "  * POSTGRES-ODOO sin PrestaShop";
		psql -U odoo -d odoo -a -c "TRUNCATE ir_attachment CASCADE;"
	fi
	cambio_nombre_compania $CONF_NOMBRE
	crear_cuenta_bancaria $NUM_CUENTA
	insetar_logo $LOGO_BASE64
	psql -U odoo -d odoo -a -c "COMMIT;"

	sleep 3
	echo "* Reiniciando PostgreSQL"
	exec gosu postgres pg_ctl -D "$PGDATA" -w stop -m immediate &
	sleep 5

	echo "* Esperando que pare PostgreSQL"
	key=true
	while [  "$key" = true ]; do
		FILE="/var/lib/postgresql/data/postmaster.pid"
		if [ -f $FILE ]; then
			echo "[ESPERANDO] El fichero $FILE existe"
			echo "Esperando 3s a que el servicio pare..."
			sleep 5
		else
			echo "[CORRECTO] File $FILE no existe"
			key=false
			sleep 3
		fi
	done
fi

echo "Iniciando PostgreSQL [FINAL]"
exec gosu postgres "$@"
exec "$@"