#!/bin/bash
# Juan Manuel Torres - https://github.com/Tedezed

# Inicio personalización #
echo '* Iniciando personalización para Odoo...'
pg_restore -i -h localhost -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -v "/odoo-prostgres/DB/$DB_RESTORE"

psql -U odoo -d odoo -a -c "
	-- Actualizar ficha de compañía
	UPDATE res_partner set name='$CONF_NOMBRE',street='$CONF_CALLE',city='$CONF_CIUDAD',zip='$CONF_COD_ZIP', website='$CONF_WEB', phone='$CONF_TELF', mobile='$CONF_TELF_MOVIL', email='$CONF_MAIL', vat='$CONF_DNI' where id=1;
	UPDATE res_company set phone='000000', email='TUEMAIL@EMAIL.COM' where id=1;

	-- Actualizar ficha de cliente
	UPDATE res_partner set name='$CONF_NOMBRE',street='$CONF_CALLE',city='$CONF_CIUDAD', zip='$CONF_COD_ZIP', website='$CONF_WEB', phone='$CONF_TELF', mobile='$CONF_TELF_MOVIL', email='$CONF_MAIL', vat='$CONF_DNI' where id=7;

	-- Actualizar datos de login
	UPDATE res_users set login='$ODOO_USER', password='$ODOO_PASS' where id=6;"
# Fin personalización #