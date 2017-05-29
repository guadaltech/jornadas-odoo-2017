#!/usr/bin/python
# -*- coding: utf-8 -*-

# Juan Manuel Torres - https://github.com/Tedezed

import os
import sys
import yaml
import operator
import pykube
from tools import *
from creates import *

ruta_exec = os.path.dirname(os.path.realpath(__file__)) + "/"
api = pykube.HTTPClient(pykube.KubeConfig.from_file(ruta_exec + "credentials/config"))

# Arguments 
list_argv=[]
sys.argv.remove(sys.argv[0])
for elements in sys.argv:
	variable_entrada = elements.split("=:")
	print variable_entrada
	if len(variable_entrada) == 1 or variable_entrada[1] == '':
		raise NameError('Error: Parametros de entrada no validos \
			[python ejemplo.py variable=:contenido]> =:')
	list_argv.append(variable_entrada)

error=True
for argv in list_argv:
	if argv[0] == 'metodo':
		error=False
		metodo=argv[1]
		list_argv.remove(argv)
		dic_argv = arguments_to_dic(list_argv)

		try:
			print "MODO DEBUG: %s" % (dic_argv["debug"])
			dic_argv["debug"] = True
		except:
			dic_argv["debug"] = False

		# Random
		cod_referencia = "%s-%s" % (string_pass_random(4, "lower"), \
			key_id(ruta_exec + "id_number"))
		nombre_db = "db-%s" % (cod_referencia)
		pass_db = string_pass_random(45, "upper")
		master_pass = string_pass_random(67, "lower")
		nombre_odoo = "odoo-%s" % (cod_referencia)
		nombre_ps = "ps-%s" % (cod_referencia)
		nombre_mysql = "mysql-%s" % (cod_referencia)
		pass_mysql = string_pass_random(45, "upper")
		key_api_ps = string_pass_random(32, "upper")

		if metodo == "odoo-test":
			image_odoo = "odoo"
			image_db = "postgres"
			init_verify(metodo, dic_argv)
			create_volumes_gcloud(nombre_odoo, dic_argv["storage"], dic_argv,api)
			create_service_odoo_ps(nombre_odoo, nombre_db, dic_argv, api, metodo)
			create_rc_odoo(nombre_odoo, master_pass, image_odoo, nombre_db, pass_db, \
				image_db, dic_argv, api, metodo, nombre_mysql, pass_mysql, key_api_ps, \
				kminion_ip)
			create_ingress(nombre_odoo, dic_argv, api, "odoo")
		elif metodo == "odoo-simple":
			image_odoo = "gcr.io/gcloud-project/odoo-10-xxx:latest"
			image_db = "gcr.io/gcloud-project/postgresql-xxx:latest"
			init_verify(metodo, dic_argv)
			create_volumes_gcloud(nombre_odoo, dic_argv["storage"], dic_argv,api)
			create_service_odoo_ps(nombre_odoo, nombre_db, dic_argv, api, metodo)
			create_rc_odoo(nombre_odoo, master_pass, image_odoo, nombre_db, pass_db, \
				image_db, dic_argv, api, metodo, nombre_mysql, pass_mysql, key_api_ps, \
				kminion_ip)
			create_ingress(nombre_odoo, dic_argv, api, "odoo")
		elif metodo == "odoo-prestashop":
			image_odoo = "gcr.io/gcloud-project/odoo-10-xxx:latest"
			image_db = "gcr.io/gcloud-project/postgresql-xxx:latest"
			image_ps = "gcr.io/gcloud-project/ps-xxx:latest"
			image_mysql = "gcr.io/gcloud-project/mysql-xxx:latest"
			nom_dom_ps = dic_argv["ps_dominio"] 
			init_verify(metodo, dic_argv)
			create_gcloudDisks(nombre_odoo, dic_argv["storage"], dic_argv, \
				ruta_exec + 'credentials/application_default_credentials.json', \
				'plasma-weft-162417', 'us-central1-a')
			create_volumes_gcloud(nombre_odoo, dic_argv["storage"], dic_argv,api)
			create_service_odoo_ps(nombre_odoo, nombre_db, dic_argv, api, metodo)
			create_rc_odoo(nombre_odoo, master_pass, image_odoo, nombre_db, pass_db, \
			 image_db, dic_argv, api, metodo, nombre_mysql, pass_mysql, key_api_ps, \
			 kminion_ip)
			create_service(nombre_ps, dic_argv, api, "prestashop", "ps-svc.yaml", metodo)
			create_service(nombre_mysql, dic_argv, api, "prestashop",\
			 "mysql-svc-vol.yaml", metodo)
			create_rc_mysql(nombre_mysql, image_mysql, nombre_odoo,\
			 pass_mysql, nom_dom_ps, dic_argv, api)
			create_rc_ps(key_api_ps, nombre_ps, image_ps,\
			 nombre_odoo, nombre_mysql, pass_mysql, nom_dom_ps, dic_argv, api)
			create_ingress(nombre_odoo, dic_argv, api, "odoo")
			create_ingress(nombre_ps, dic_argv, api, "ps")
if error:
	raise NameError('[ERROR 1001] No encontro metodo valido.')
else:
	print_summary (nombre_odoo, master_pass, nombre_db, pass_db,\
	 nombre_ps, nombre_mysql, pass_mysql, key_api_ps, dic_argv, metodo)