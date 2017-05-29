#!/bin/bash
# Juan Manuel Torres - https://github.com/Tedezed
set -e

echo "Ver optimizado: pre-a-0.0.2.0"
echo "= Iniciando cuerpo script ps"

if [ ! -f ./config/KEY  ]; then
	if [ $PS_THEME = "0" ]; then
		echo "  * Copiando PS inicial original";
		cp -R /tmp/html.org/* /var/www/html/
	fi
	if [ $PS_THEME = "1" ]; then
		echo "  * Copiando PS inicial con tema";
		cp -R /tmp/html.theme/* /var/www/html/
	fi

	echo "  * Generando fichero configuracion"
	cp /var/www/html/config/settings.inc.php /var/www/html/config/settings.inc.php.old
	sed "s&{{PASS_MYSQL}}&$DB_PASSWD&g" /var/www/html/config/settings.inc.php.old > /var/www/html/config/settings.inc.php
	rm -rf /var/www/html/config/settings.inc.php.old
	cp /var/www/html/config/settings.inc.php /var/www/html/config/settings.inc.php.old
	sed "s&{{NAME_MYSQL}}&$DB_SERVER&g" /var/www/html/config/settings.inc.php.old > /var/www/html/config/settings.inc.php

	echo "= Buscando server Mysql ="
	RET=1
	while [ $RET -ne 0 ]; do
	    mysql -h $DB_SERVER -P $DB_PORT -u $DB_USER -p$DB_PASSWD -e "status" > /dev/null 2>&1
	    RET=$?
	    if [ $RET -ne 0 ]; then
	        echo "  * Esperando que se inicie el servidor MySQL...";
	        sleep 3
	    else
	    	echo "  * Servicio MySQL [CORRECTO]";
	    fi
	done

	echo "  * Configurando usuario admin PS"
	mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "UPDATE \`ps_employee\` SET \`lastname\` = '$LASTNAME',\`firstname\` = '$FIRSTNAME',\`email\` = '$ADMIN_MAIL',\`passwd\` = MD5('TBG9pKKZDMFCAed1vnq5dc8Tz3U5AcbWjmrjDqNOUc5726IXV1POqaPf$ADMIN_PASSWD') WHERE \`id_employee\` = 1;" -b $DB_NAME

	echo "  * Configurando dominio"
	mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "UPDATE \`ps_shop_url\` SET \`id_shop_url\` = '1',\`active\` = '1',\`main\` = '1',\`domain\` = '$PS_DOMAIN',\`domain_ssl\` = '$PS_DOMAIN',\`id_shop\` = '1',\`physical_uri\` = '/',\`virtual_uri\` = '' WHERE \`id_shop_url\` = 1" -b $DB_NAME
	mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "UPDATE \`ps_configuration\` SET \`value\` = '$PS_DOMAIN',\`date_upd\` = '2017-03-24 10:33:33' WHERE \`name\` = 'PS_SHOP_DOMAIN' AND (id_shop_group IS NULL OR id_shop_group = 0) AND (id_shop IS NULL OR id_shop = 0) LIMIT 1" -b $DB_NAME

	if [ $PS_FOLDER_ADMIN != "admin" ]; then
		echo "  * Renaming admin folder as $PS_FOLDER_ADMIN ...";
	fi

	if [ $PS_HANDLE_DYNAMIC_DOMAIN = "0" ]; then
		rm /var/www/html/docker_updt_ps_domains.php
	else
		sed -ie "s/DirectoryIndex\ index.php\ index.html/DirectprestashopConsole.phar configuration:setoryIndex\ docker_updt_ps_domains.php\ index.php\ index.html/g" $APACHE_CONFDIR/conf-available/docker-php.conf
	fi

	if [ $PS_INSTALL_AUTO = "1" ]; then
		echo "  * Installing PrestaShop, this may take a while ...";

		if [ "$PS_DOMAIN" = "<to be defined>" ]; then
			export PS_DOMAIN=$(hostname -i)
		fi

		echo "  * Reseteando permisos;"
		chmod 770 -R /var/www/html

		if [ $PS_CONF_ODOO_AUTO = "1" ]; then
			# Inicio personalicación para odoo
			echo "  * Personalizando Prestashop para Odoo";

			echo "  * Instalado modulos OpenERP";
			mv /tmp/gst_pob_connector/prestaerp /var/www/html/modules/prestaerp
			mv /tmp/gst_pob_connector/prestaerpmultishop /var/www/html/modules/prestaerpmultishop
			mv /tmp/gst_pob_connector/prestaerpreturn /var/www/html/modules/prestaerpreturn

			## Instalación de modulos
			for modulox in prestaerp prestaerpmultishop prestaerpreturn
			do
				/var/www/html/prestashopConsole.phar module:install $modulox 
			done

			for modulox in prestaerp prestaerpmultishop prestaerpreturn
			do
				/var/www/html/prestashopConsole.phar module:enable $modulox
			done

			## Configuración modulo prestaerp
			/var/www/html/prestashopConsole.phar configuration:set Url $PRESTAERP_URL
			/var/www/html/prestashopConsole.phar configuration:set Port $PRESTAERP_PORT
			/var/www/html/prestashopConsole.phar configuration:set Username $PRESTAERP_USERNAME
			/var/www/html/prestashopConsole.phar configuration:set Password $PRESTAERP_PASS
			/var/www/html/prestashopConsole.phar configuration:set Database $PRESTAERP_DB
			/var/www/html/prestashopConsole.phar configuration:set auto_upd_status 1
			/var/www/html/prestashopConsole.phar configuration:set confirm_order 1
			/var/www/html/prestashopConsole.phar configuration:set auto_gen_inv 1
			/var/www/html/prestashopConsole.phar configuration:set drop_tables 0
			/var/www/html/prestashopConsole.phar configuration:set multi_lang 0
			/var/www/html/prestashopConsole.phar configuration:set multi_shop 0
			/var/www/html/prestashopConsole.phar configuration:set PS_REWRITING_SETTINGS 1
			/var/www/html/prestashopConsole.phar configuration:set PS_DASHBOARD_SIMULATION 0
			/var/www/html/prestashopConsole.phar configuration:set PS_WEBSERVICE 1
			/var/www/html/prestashopConsole.phar configuration:set multi_shop 1

			echo "  * Configuracion adicional de modulos OpenERP"
			mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "INSERT INTO \`ps_erp_shop_merge\` (\`erp_shop_id\`, \`prestashop_shop_id\`, \`created_by\`) VALUES (1, 1,'$FIRSTNAME $LASTNAME ($ADMIN_MAIL)')" -b $DB_NAME

			echo "  * Creando WebService";
			id_webservice_account=1
			id_shop=1
			mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "INSERT INTO \`ps_webservice_account\` (\`active\`, \`key\`, \`description\`) VALUES ('1','$PS_WEBSERVICE_KEY','');" -b $DB_NAME
			mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "INSERT INTO \`ps_webservice_account_shop\` (\`id_webservice_account\`, \`id_shop\`) VALUES ('1', '1');" -b $DB_NAME
			mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_webservice_permission\` (\`id_webservice_permission\` ,\`resource\` ,\`method\` ,\`id_webservice_account\`) VALUES (NULL , 'addresses', 'GET', 1), (NULL , 'addresses', 'PUT', 1), (NULL , 'addresses', 'POST', 1), (NULL , 'addresses', 'DELETE', 1), (NULL , 'addresses', 'HEAD', 1), (NULL , 'carriers', 'GET', 1), (NULL , 'carriers', 'PUT', 1), (NULL , 'carriers', 'POST', 1), (NULL , 'carriers', 'DELETE', 1), (NULL , 'carriers', 'HEAD', 1), (NULL , 'cart_rules', 'GET', 1), (NULL , 'cart_rules', 'PUT', 1), (NULL , 'cart_rules', 'POST', 1), (NULL , 'cart_rules', 'DELETE', 1), (NULL , 'cart_rules', 'HEAD', 1), (NULL , 'carts', 'GET', 1), (NULL , 'carts', 'PUT', 1), (NULL , 'carts', 'POST', 1), (NULL , 'carts', 'DELETE', 1), (NULL , 'carts', 'HEAD', 1), (NULL , 'categories', 'GET', 1), (NULL , 'categories', 'PUT', 1), (NULL , 'categories', 'POST', 1), (NULL , 'categories', 'DELETE', 1), (NULL , 'categories', 'HEAD', 1), (NULL , 'combinations', 'GET', 1), (NULL , 'combinations', 'PUT', 1), (NULL , 'combinations', 'POST', 1), (NULL , 'combinations', 'DELETE', 1), (NULL , 'combinations', 'HEAD', 1), (NULL , 'configurations', 'GET', 1), (NULL , 'configurations', 'PUT', 1), (NULL , 'configurations', 'POST', 1), (NULL , 'configurations', 'DELETE', 1), (NULL , 'configurations', 'HEAD', 1), (NULL , 'contacts', 'GET', 1), (NULL , 'contacts', 'PUT', 1), (NULL , 'contacts', 'POST', 1), (NULL , 'contacts', 'DELETE', 1), (NULL , 'contacts', 'HEAD', 1), (NULL , 'content_management_system', 'GET', 1), (NULL , 'content_management_system', 'PUT', 1), (NULL , 'content_management_system', 'POST', 1), (NULL , 'content_management_system', 'DELETE', 1), (NULL , 'content_management_system', 'HEAD', 1), (NULL , 'countries', 'GET', 1), (NULL , 'countries', 'PUT', 1), (NULL , 'countries', 'POST', 1), (NULL , 'countries', 'DELETE', 1), (NULL , 'countries', 'HEAD', 1), (NULL , 'currencies', 'GET', 1), (NULL , 'currencies', 'PUT', 1), (NULL , 'currencies', 'POST', 1), (NULL , 'currencies', 'DELETE', 1), (NULL , 'currencies', 'HEAD', 1), (NULL , 'customer_messages', 'GET', 1), (NULL , 'customer_messages', 'PUT', 1), (NULL , 'customer_messages', 'POST', 1), (NULL , 'customer_messages', 'DELETE', 1), (NULL , 'customer_messages', 'HEAD', 1), (NULL , 'customer_threads', 'GET', 1), (NULL , 'customer_threads', 'PUT', 1), (NULL , 'customer_threads', 'POST', 1), (NULL , 'customer_threads', 'DELETE', 1), (NULL , 'customer_threads', 'HEAD', 1), (NULL , 'customers', 'GET', 1), (NULL , 'customers', 'PUT', 1), (NULL , 'customers', 'POST', 1), (NULL , 'customers', 'DELETE', 1), (NULL , 'customers', 'HEAD', 1), (NULL , 'deliveries', 'GET', 1), (NULL , 'deliveries', 'PUT', 1), (NULL , 'deliveries', 'POST', 1), (NULL , 'deliveries', 'DELETE', 1), (NULL , 'deliveries', 'HEAD', 1), (NULL , 'employees', 'GET', 1), (NULL , 'employees', 'PUT', 1), (NULL , 'employees', 'POST', 1), (NULL , 'employees', 'DELETE', 1), (NULL , 'employees', 'HEAD', 1), (NULL , 'erp_address_merges', 'GET', 1), (NULL , 'erp_address_merges', 'PUT', 1), (NULL , 'erp_address_merges', 'POST', 1), (NULL , 'erp_address_merges', 'DELETE', 1), (NULL , 'erp_address_merges', 'HEAD', 1), (NULL , 'erp_attribute_values_merges', 'GET', 1), (NULL , 'erp_attribute_values_merges', 'PUT', 1), (NULL , 'erp_attribute_values_merges', 'POST', 1), (NULL , 'erp_attribute_values_merges', 'DELETE', 1), (NULL , 'erp_attribute_values_merges', 'HEAD', 1), (NULL , 'erp_attributes_merges', 'GET', 1), (NULL , 'erp_attributes_merges', 'PUT', 1), (NULL , 'erp_attributes_merges', 'POST', 1), (NULL , 'erp_attributes_merges', 'DELETE', 1), (NULL , 'erp_attributes_merges', 'HEAD', 1), (NULL , 'erp_category_merges', 'GET', 1), (NULL , 'erp_category_merges', 'PUT', 1), (NULL , 'erp_category_merges', 'POST', 1), (NULL , 'erp_category_merges', 'DELETE', 1), (NULL , 'erp_category_merges', 'HEAD', 1), (NULL , 'erp_customer_merges', 'GET', 1), (NULL , 'erp_customer_merges', 'PUT', 1), (NULL , 'erp_customer_merges', 'POST', 1), (NULL , 'erp_customer_merges', 'DELETE', 1), (NULL , 'erp_customer_merges', 'HEAD', 1), (NULL , 'erp_product_merges', 'GET', 1), (NULL , 'erp_product_merges', 'PUT', 1), (NULL , 'erp_product_merges', 'POST', 1), (NULL , 'erp_product_merges', 'DELETE', 1), (NULL , 'erp_product_merges', 'HEAD', 1), (NULL , 'erp_product_template_merges', 'GET', 1), (NULL , 'erp_product_template_merges', 'PUT', 1), (NULL , 'erp_product_template_merges', 'POST', 1), (NULL , 'erp_product_template_merges', 'DELETE', 1), (NULL , 'erp_product_template_merges', 'HEAD', 1), (NULL , 'groups', 'GET', 1), (NULL , 'groups', 'PUT', 1), (NULL , 'groups', 'POST', 1), (NULL , 'groups', 'DELETE', 1), (NULL , 'groups', 'HEAD', 1), (NULL , 'guests', 'GET', 1), (NULL , 'guests', 'PUT', 1), (NULL , 'guests', 'POST', 1), (NULL , 'guests', 'DELETE', 1), (NULL , 'guests', 'HEAD', 1), (NULL , 'image_types', 'GET', 1), (NULL , 'image_types', 'PUT', 1), (NULL , 'image_types', 'POST', 1), (NULL , 'image_types', 'DELETE', 1), (NULL , 'image_types', 'HEAD', 1), (NULL , 'images', 'GET', 1), (NULL , 'images', 'PUT', 1), (NULL , 'images', 'POST', 1), (NULL , 'images', 'DELETE', 1), (NULL , 'images', 'HEAD', 1), (NULL , 'languages', 'GET', 1), (NULL , 'languages', 'PUT', 1), (NULL , 'languages', 'POST', 1), (NULL , 'languages', 'DELETE', 1), (NULL , 'languages', 'HEAD', 1), (NULL , 'manufacturers', 'GET', 1), (NULL , 'manufacturers', 'PUT', 1), (NULL , 'manufacturers', 'POST', 1), (NULL , 'manufacturers', 'DELETE', 1), (NULL , 'manufacturers', 'HEAD', 1), (NULL , 'order_carriers', 'GET', 1), (NULL , 'order_carriers', 'PUT', 1), (NULL , 'order_carriers', 'POST', 1), (NULL , 'order_carriers', 'DELETE', 1), (NULL , 'order_carriers', 'HEAD', 1), (NULL , 'order_details', 'GET', 1), (NULL , 'order_details', 'PUT', 1), (NULL , 'order_details', 'POST', 1), (NULL , 'order_details', 'DELETE', 1), (NULL , 'order_details', 'HEAD', 1), (NULL , 'order_discounts', 'GET', 1), (NULL , 'order_discounts', 'PUT', 1), (NULL , 'order_discounts', 'POST', 1), (NULL , 'order_discounts', 'DELETE', 1), (NULL , 'order_discounts', 'HEAD', 1), (NULL , 'order_histories', 'GET', 1), (NULL , 'order_histories', 'PUT', 1), (NULL , 'order_histories', 'POST', 1), (NULL , 'order_histories', 'DELETE', 1), (NULL , 'order_histories', 'HEAD', 1), (NULL , 'order_invoices', 'GET', 1), (NULL , 'order_invoices', 'PUT', 1), (NULL , 'order_invoices', 'POST', 1), (NULL , 'order_invoices', 'DELETE', 1), (NULL , 'order_invoices', 'HEAD', 1), (NULL , 'order_merges', 'GET', 1), (NULL , 'order_merges', 'PUT', 1), (NULL , 'order_merges', 'POST', 1), (NULL , 'order_merges', 'DELETE', 1), (NULL , 'order_merges', 'HEAD', 1), (NULL , 'order_payments', 'GET', 1), (NULL , 'order_payments', 'PUT', 1), (NULL , 'order_payments', 'POST', 1), (NULL , 'order_payments', 'DELETE', 1), (NULL , 'order_payments', 'HEAD', 1), (NULL , 'order_slip', 'GET', 1), (NULL , 'order_slip', 'PUT', 1), (NULL , 'order_slip', 'POST', 1), (NULL , 'order_slip', 'DELETE', 1), (NULL , 'order_slip', 'HEAD', 1), (NULL , 'order_states', 'GET', 1), (NULL , 'order_states', 'PUT', 1), (NULL , 'order_states', 'POST', 1), (NULL , 'order_states', 'DELETE', 1), (NULL , 'order_states', 'HEAD', 1), (NULL , 'orders', 'GET', 1), (NULL , 'orders', 'PUT', 1), (NULL , 'orders', 'POST', 1), (NULL , 'orders', 'DELETE', 1), (NULL , 'orders', 'HEAD', 1), (NULL , 'price_ranges', 'GET', 1), (NULL , 'price_ranges', 'PUT', 1), (NULL , 'price_ranges', 'POST', 1), (NULL , 'price_ranges', 'DELETE', 1), (NULL , 'price_ranges', 'HEAD', 1), (NULL , 'product_feature_values', 'GET', 1), (NULL , 'product_feature_values', 'PUT', 1), (NULL , 'product_feature_values', 'POST', 1), (NULL , 'product_feature_values', 'DELETE', 1), (NULL , 'product_feature_values', 'HEAD', 1), (NULL , 'product_features', 'GET', 1), (NULL , 'product_features', 'PUT', 1), (NULL , 'product_features', 'POST', 1), (NULL , 'product_features', 'DELETE', 1), (NULL , 'product_features', 'HEAD', 1), (NULL , 'product_option_values', 'GET', 1), (NULL , 'product_option_values', 'PUT', 1), (NULL , 'product_option_values', 'POST', 1), (NULL , 'product_option_values', 'DELETE', 1), (NULL , 'product_option_values', 'HEAD', 1), (NULL , 'product_options', 'GET', 1), (NULL , 'product_options', 'PUT', 1), (NULL , 'product_options', 'POST', 1), (NULL , 'product_options', 'DELETE', 1), (NULL , 'product_options', 'HEAD', 1), (NULL , 'product_suppliers', 'GET', 1), (NULL , 'product_suppliers', 'HEAD', 1), (NULL , 'products', 'GET', 1), (NULL , 'products', 'PUT', 1), (NULL , 'products', 'POST', 1), (NULL , 'products', 'DELETE', 1), (NULL , 'products', 'HEAD', 1), (NULL , 'search', 'GET', 1), (NULL , 'search', 'HEAD', 1), (NULL , 'shop_groups', 'GET', 1), (NULL , 'shop_groups', 'PUT', 1), (NULL , 'shop_groups', 'POST', 1), (NULL , 'shop_groups', 'DELETE', 1), (NULL , 'shop_groups', 'HEAD', 1), (NULL , 'shop_urls', 'GET', 1), (NULL , 'shop_urls', 'PUT', 1), (NULL , 'shop_urls', 'POST', 1), (NULL , 'shop_urls', 'DELETE', 1), (NULL , 'shop_urls', 'HEAD', 1), (NULL , 'shops', 'GET', 1), (NULL , 'shops', 'PUT', 1), (NULL , 'shops', 'POST', 1), (NULL , 'shops', 'DELETE', 1), (NULL , 'shops', 'HEAD', 1), (NULL , 'specific_price_rules', 'GET', 1), (NULL , 'specific_price_rules', 'PUT', 1), (NULL , 'specific_price_rules', 'POST', 1), (NULL , 'specific_price_rules', 'DELETE', 1), (NULL , 'specific_price_rules', 'HEAD', 1), (NULL , 'specific_prices', 'GET', 1), (NULL , 'specific_prices', 'PUT', 1), (NULL , 'specific_prices', 'POST', 1), (NULL , 'specific_prices', 'DELETE', 1), (NULL , 'specific_prices', 'HEAD', 1), (NULL , 'states', 'GET', 1), (NULL , 'states', 'PUT', 1), (NULL , 'states', 'POST', 1), (NULL , 'states', 'DELETE', 1), (NULL , 'states', 'HEAD', 1), (NULL , 'stock_availables', 'GET', 1), (NULL , 'stock_availables', 'PUT', 1), (NULL , 'stock_availables', 'HEAD', 1), (NULL , 'stock_movement_reasons', 'GET', 1), (NULL , 'stock_movement_reasons', 'PUT', 1), (NULL , 'stock_movement_reasons', 'POST', 1), (NULL , 'stock_movement_reasons', 'DELETE', 1), (NULL , 'stock_movement_reasons', 'HEAD', 1), (NULL , 'stock_movements', 'GET', 1), (NULL , 'stock_movements', 'HEAD', 1), (NULL , 'stocks', 'GET', 1), (NULL , 'stocks', 'HEAD', 1), (NULL , 'stores', 'GET', 1), (NULL , 'stores', 'PUT', 1), (NULL , 'stores', 'POST', 1), (NULL , 'stores', 'DELETE', 1), (NULL , 'stores', 'HEAD', 1), (NULL , 'suppliers', 'GET', 1), (NULL , 'suppliers', 'PUT', 1), (NULL , 'suppliers', 'POST', 1), (NULL , 'suppliers', 'DELETE', 1), (NULL , 'suppliers', 'HEAD', 1), (NULL , 'supply_order_details', 'GET', 1), (NULL , 'supply_order_details', 'HEAD', 1), (NULL , 'supply_order_histories', 'GET', 1), (NULL , 'supply_order_histories', 'HEAD', 1), (NULL , 'supply_order_receipt_histories', 'GET', 1), (NULL , 'supply_order_receipt_histories', 'HEAD', 1), (NULL , 'supply_order_states', 'GET', 1), (NULL , 'supply_order_states', 'HEAD', 1), (NULL , 'supply_orders', 'GET', 1), (NULL , 'supply_orders', 'HEAD', 1), (NULL , 'tags', 'GET', 1), (NULL , 'tags', 'PUT', 1), (NULL , 'tags', 'POST', 1), (NULL , 'tags', 'DELETE', 1), (NULL , 'tags', 'HEAD', 1), (NULL , 'tax_rule_groups', 'GET', 1), (NULL , 'tax_rule_groups', 'PUT', 1), (NULL , 'tax_rule_groups', 'POST', 1), (NULL , 'tax_rule_groups', 'DELETE', 1), (NULL , 'tax_rule_groups', 'HEAD', 1), (NULL , 'tax_rules', 'GET', 1), (NULL , 'tax_rules', 'PUT', 1), (NULL , 'tax_rules', 'POST', 1), (NULL , 'tax_rules', 'DELETE', 1), (NULL , 'tax_rules', 'HEAD', 1), (NULL , 'taxes', 'GET', 1), (NULL , 'taxes', 'PUT', 1), (NULL , 'taxes', 'POST', 1), (NULL , 'taxes', 'DELETE', 1), (NULL , 'taxes', 'HEAD', 1), (NULL , 'translated_configurations', 'GET', 1), (NULL , 'translated_configurations', 'PUT', 1), (NULL , 'translated_configurations', 'POST', 1), (NULL , 'translated_configurations', 'DELETE', 1), (NULL , 'translated_configurations', 'HEAD', 1), (NULL , 'warehouse_product_locations', 'GET', 1), (NULL , 'warehouse_product_locations', 'HEAD', 1), (NULL , 'warehouses', 'GET', 1), (NULL , 'warehouses', 'PUT', 1), (NULL , 'warehouses', 'POST', 1), (NULL , 'warehouses', 'HEAD', 1), (NULL , 'weight_ranges', 'GET', 1), (NULL , 'weight_ranges', 'PUT', 1), (NULL , 'weight_ranges', 'POST', 1), (NULL , 'weight_ranges', 'DELETE', 1), (NULL , 'weight_ranges', 'HEAD', 1), (NULL , 'zones', 'GET', 1), (NULL , 'zones', 'PUT', 1), (NULL , 'zones', 'POST', 1), (NULL , 'zones', 'DELETE', 1), (NULL , 'zones', 'HEAD', 1)"
			
			if [ $MULTISHOP = "1" ]; then
				echo "  * Creando Multitienda"
				mysql -u $DB_USER --password=$DB_PASSWD -b $DB_NAME -h $DB_SERVER -P $DB_PORT -e "UPDATE \`ps_configuration\` SET \`value\` = '1' WHERE \`name\` = 'PS_MULTISHOP_FEATURE_ACTIVE';"
				/var/www/html/prestashopConsole.phar configuration:set PS_MULTISHOP_FEATURE_ACTIVE 1
				id_shop_group=60
				tema="default-bootstrap"
				declare -A DIC_SHOP=$DIC_SHOPS
				for multishop_name_group in ${LIST_GROUP_MULTISHOP[@]}
				do
					echo " = Creando Grupo $multishop_name_group"
					token_shop=$(mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "select http_referer from ps_pagenotfound;" | grep -o "token\=.*[a-zA-Z0-9]" -m1)
					http_referer1="http://$PS_DOMAIN/$PS_FOLDER_ADMIN/index.php?controller=AdminShopGroup&addshop_group&$token_shop"
					http_referer2="http://$PS_DOMAIN/$PS_FOLDER_ADMIN/index.php?controller=AdminShopGroup&id_shop_group=$id_shop_group&conf=3&$token_shop"
					mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_shop_group\` (\`id_shop_group\`, \`name\`, \`share_customer\`, \`share_order\`, \`share_stock\`, \`active\`, \`deleted\`) VALUES ('$id_shop_group','${multishop_name_group}', '0', '0', '0', '1', '0')"
					mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_pagenotfound\` (\`request_uri\`, \`http_referer\`, \`date_add\`, \`id_shop\`, \`id_shop_group\`)  VALUES ('/?controller=404', '$http_referer1', NOW(), 1, 1)"
					mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_pagenotfound\` (\`request_uri\`, \`http_referer\`, \`date_add\`, \`id_shop\`, \`id_shop_group\`)  VALUES ('/?controller=404', '$http_referer2', NOW(), 1, 1)"
					for tienda in ${DIC_SHOP[$multishop_name_group]}; do
						echo "  - Creando tienda $tienda"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_shop\` (\`active\`, \`deleted\`, \`name\`, \`id_theme\`, \`id_category\`, \`id_shop_group\`) VALUES ('1', '0', '$tienda', (SELECT id_theme FROM ps_theme WHERE name = '$tema' LIMIT 1), (SELECT id_category FROM ps_category WHERE is_root_category = 1 LIMIT 1), (SELECT id_shop_group FROM ps_shop_group WHERE name = '$multishop_name_group' LIMIT 1));"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_shop_url\` (\`active\`, \`main\`, \`domain\`, \`domain_ssl\`, \`id_shop\`, \`physical_uri\`) VALUES ('1', '1', '$PS_DOMAIN', '$PS_DOMAIN', (SELECT id_shop FROM ps_shop WHERE name='$tienda'), '/$tienda/');"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT INTO \`ps_category_shop\` (\`id_category\`, \`id_shop\`, \`position\`) VALUES (2, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 1) ON DUPLICATE KEY UPDATE \`position\` = 1;"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_carrier_shop\` (\`id_carrier\`, id_shop)
						(SELECT \`id_carrier\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_carrier_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_carrier_lang\` (\`id_carrier\`, \`id_lang\`, \`delay\`, id_shop)
						(SELECT \`id_carrier\`, \`id_lang\`, \`delay\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_carrier_lang
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_category_lang\` (\`id_category\`, \`id_lang\`, \`name\`, \`description\`, \`link_rewrite\`, \`meta_title\`, \`meta_keywords\`, \`meta_description\`, id_shop)
						(SELECT \`id_category\`, \`id_lang\`, \`name\`, \`description\`, \`link_rewrite\`, \`meta_title\`, \`meta_keywords\`, \`meta_description\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_category_lang
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_shop\` (\`id_cms\`, id_shop)
						(SELECT \`id_cms\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_cms_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_contact_shop\` (\`id_contact\`, id_shop)
						(SELECT \`id_contact\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_contact_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_country_shop\` (\`id_country\`, id_shop)
						(SELECT \`id_country\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_country_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_currency_shop\` (\`id_currency\`, \`conversion_rate\`, id_shop)
						(SELECT \`id_currency\`, \`conversion_rate\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_currency_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_employee_shop\` (\`id_employee\`, id_shop)
						(SELECT \`id_employee\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_employee_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_hook_module\` (\`id_module\`, \`id_hook\`, \`position\`, id_shop)
						(SELECT \`id_module\`, \`id_hook\`, \`position\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_hook_module
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_hook_module_exceptions\` (\`id_module\`, \`id_hook\`, \`file_name\`, id_shop)
						(SELECT \`id_module\`, \`id_hook\`, \`file_name\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_hook_module_exceptions
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_lang_shop\` (\`id_lang\`, id_shop)
						(SELECT \`id_lang\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_lang_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_meta_lang\` (\`id_meta\`, \`id_lang\`, \`title\`, \`description\`, \`keywords\`, \`url_rewrite\`, id_shop)
						(SELECT \`id_meta\`, \`id_lang\`, \`title\`, \`description\`, \`keywords\`, \`url_rewrite\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_meta_lang
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_module_shop\` (\`id_module\`, id_shop)
						(SELECT \`id_module\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_module_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_module_currency\` (\`id_module\`, \`id_currency\`, id_shop)
						(SELECT \`id_module\`, \`id_currency\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_module_currency
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_module_country\` (\`id_module\`, \`id_country\`, id_shop)
						(SELECT \`id_module\`, \`id_country\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_module_country
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_module_group\` (\`id_module\`, \`id_group\`, id_shop)
						(SELECT \`id_module\`, \`id_group\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_module_group
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_store_shop\` (\`id_store\`, id_shop)
						(SELECT \`id_store\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_store_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_webservice_account_shop\` (\`id_webservice_account\`, id_shop)
						(SELECT \`id_webservice_account\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_webservice_account_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_carrier_tax_rules_group_shop\` (\`id_carrier\`, \`id_tax_rules_group\`, id_shop)
						(SELECT \`id_carrier\`, \`id_tax_rules_group\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_carrier_tax_rules_group_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_group_shop\` (\`id_group\`, id_shop)
						(SELECT \`id_group\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_group_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_tax_rules_group_shop\` (\`id_tax_rules_group\`, id_shop)
						(SELECT \`id_tax_rules_group\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_tax_rules_group_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_zone_shop\` (\`id_zone\`, id_shop)
						(SELECT \`id_zone\`, (SELECT id_shop FROM ps_shop WHERE name='$tienda') FROM ps_zone_shop
						WHERE \`id_shop\` = 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO ps_cms_block (\`id_cms_block\`, \`id_cms_category\`, \`location\`, \`position\`, \`display_store\`) 
						VALUES (NULL, 1, 0, 0, 1);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO ps_cms_block_shop (\`id_cms_block\`, \`id_shop\`) VALUES ((SELECT id_shop FROM ps_shop WHERE name='$tienda'), (SELECT id_shop FROM ps_shop WHERE name='$tienda'));"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_lang\` (\`id_cms_block\`, \`id_lang\`, \`name\`) 
						VALUES ((SELECT id_shop FROM ps_shop WHERE name='$tienda'), 1, 'Información');"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_lang\` (\`id_cms_block\`, \`id_lang\`, \`name\`) 
						VALUES ((SELECT id_shop FROM ps_shop WHERE name='$tienda'), 2, 'Información');"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_lang\` (\`id_cms_block\`, \`id_lang\`, \`name\`) 
						VALUES ((SELECT id_shop FROM ps_shop WHERE name='$tienda'), (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 'Información');"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_page\` (\`id_cms_block_page\`, \`id_cms_block\`, \`id_cms\`, \`is_category\`) 
						VALUES (NULL, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 1, 0);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_page\` (\`id_cms_block_page\`, \`id_cms_block\`, \`id_cms\`, \`is_category\`) 
						VALUES (NULL, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 2, 0);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_page\` (\`id_cms_block_page\`, \`id_cms_block\`, \`id_cms\`, \`is_category\`) 
						VALUES (NULL, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 0);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_page\` (\`id_cms_block_page\`, \`id_cms_block\`, \`id_cms\`, \`is_category\`) 
						VALUES (NULL, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 4, 0);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -b $DB_NAME -e "INSERT IGNORE INTO \`ps_cms_block_page\` (\`id_cms_block_page\`, \`id_cms_block\`, \`id_cms\`, \`is_category\`) 
						VALUES (NULL, (SELECT id_shop FROM ps_shop WHERE name='$tienda'), 5, 0);"
						mysql -u $DB_USER --password=$DB_PASSWD -h $DB_SERVER -P $DB_PORT -e "INSERT IGNORE INTO \`ps_webservice_account_shop\` (\`id_webservice_account\`, \`id_shop\`) VALUES ('1', (SELECT id_shop FROM ps_shop WHERE name='$tienda'));" -b $DB_NAME
						echo "   + Añadiendo $tienda a .htaccess"
						echo "RedirectMatch 302 /$tienda/img/(.*) /img//\$1" >> .htaccess
						echo "RedirectMatch 302 /$tienda/themes/(.*) /themes//\$1" >> .htaccess
						echo "RedirectMatch 302 /$tienda/js/(.*) /js//\$1" >> .htaccess
						echo "RedirectMatch 302 /$tienda/modules/(.*) /modules//\$1" >> .htaccess
					done
					id_shop_group=$(($id_shop_group + 1))
				done
			fi
		fi
	fi
fi

echo "* Configurando htaccess por defecto"
cp -R /tmp/html.org/.htaccess /var/www/html/
chown www-data:www-data .htaccess
chmod 774 .htaccess
mv .htaccess .deployhtaccess
sed "s&{{CHANGE}}&$PS_DOMAIN&g" .deployhtaccess > /var/www/html/.htaccess
rm -rf .deployhtaccess

touch /var/www/html/config/KEY
chown www-data:www-data -R /var/www/html/

echo "= Almost ! Starting Apache now\n";
exec apache2-foreground
