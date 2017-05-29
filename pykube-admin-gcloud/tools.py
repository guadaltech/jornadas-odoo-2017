#!/usr/bin/python
# -*- coding: utf-8 -*-

# Juan Manuel Torres - https://github.com/Tedezed

import os
import sys
import random
import string
import yaml
import base64
import binascii

def init_verify(metodo, dic_argv):
	try:
		if metodo == "odoo-prestashop":
			dic_argv['CONF_NOMBRE']
			dic_argv['CONF_CALLE']
			dic_argv['CONF_CIUDAD']
			dic_argv['CONF_COD_ZIP']
			dic_argv['CONF_WEB']
			dic_argv['CONF_TELF']
			dic_argv['CONF_TELF_MOVIL']
			dic_argv['CONF_MAIL']
			dic_argv['CONF_DNI']
			dic_argv['ODOO_USER']
			dic_argv['ODOO_PASS']
			dic_argv['ps_dominio']
			dic_argv['dominio']
			dic_argv['storage']
			dic_argv['ps_replicas']
			dic_argv['odoo_replicas']
			dic_argv['limit_cpu']
			dic_argv['limit_mem']
			dic_argv['limit_cpu_db']
			dic_argv['limit_mem_db']
			dic_argv['ADMIN_MAIL']
			dic_argv['ADMIN_PASSWD']
			dic_argv['PS_NOM_USER']
			dic_argv['PS_APELLIDO_USER']
			dic_argv['PS_THEME']
			dic_argv['ip_ingress']
			dic_argv['USER_MOBILE']
			dic_argv['USER_MOBILE_PASS']
			dic_argv['NUM_CUENTA']
			dic_argv['LOGO_BASE64']
		elif metodo == "odoo-simple":
			dic_argv['CONF_NOMBRE']
			dic_argv['CONF_CALLE']
			dic_argv['CONF_CIUDAD']
			dic_argv['CONF_COD_ZIP']
			dic_argv['CONF_WEB']
			dic_argv['CONF_TELF']
			dic_argv['CONF_TELF_MOVIL']
			dic_argv['CONF_MAIL']
			dic_argv['CONF_DNI']
			dic_argv['ODOO_USER']
			dic_argv['ODOO_PASS']
			dic_argv['dominio']
			dic_argv['storage']
			dic_argv['odoo_replicas']
			dic_argv['limit_cpu']
			dic_argv['limit_mem']
			dic_argv['limit_cpu_db']
			dic_argv['limit_mem_db']
			dic_argv['USER_MOBILE']
			dic_argv['USER_MOBILE_PASS']
			dic_argv['NUM_CUENTA']
			dic_argv['LOGO_BASE64']
	except KeyError, e:
		print "[ERROR 1002] Falta el parametro %s" % (e)
		sys.exit(0)
	if int(dic_argv["storage"]) < 5:
		print "[ERROR 1003] El almacenamiento no puede ser menor que 5Gi"
		sys.exit(0)
	if int(dic_argv["limit_mem_db"]) < 1024 and metodo == "odoo-prestashop":
		print "[ERROR 1004] RAM DB no puede ser inferior de 1Gi por MySQL"
		sys.exit(0)
	try:
		base64.decodestring(dic_argv["LOGO_BASE64"])
	except binascii.Error:
		print "[ERROR 1005] La cadena LOGO_BASE64 no esta\
		 correctamente codificada y no puede ser usada"
		sys.exit(0)

def key_id(file_id_number):
	file = open(file_id_number, 'r')
	old_id = int(file.readline())
	new_id = old_id + 1
	file.close()

	file = open(file_id_number, 'w')
	file.write(str(new_id))
	file.close()
	return new_id

def string_pass_random (num, tipe_p):
	if tipe_p == "upper":
		clave = ''.join(random.choice(string.ascii_uppercase + string.digits)\
		 for _ in range(num))
	if tipe_p == "lower":
		clave = ''.join(random.choice(string.lowercase + string.digits)\
		 for _ in range(num))
	return clave

def load_file_yaml (ruta):
	ruta_exec = os.path.dirname(os.path.realpath(__file__)) + "/"
	file_yaml = open(ruta_exec + ruta, "r")
	dic_yaml = yaml.load(file_yaml)
	file_yaml.close()
	return dic_yaml

def arguments_to_dic (list_p):
	dic = {}
	for z in list_p:
		dic[z[0]]=z[1]
	return dic

def print_summary (nombre_odoo, master_pass, nombre_db, \
	pass_db, nombre_ps, nombre_mysql, pass_mysql, key_api_ps, dic_argv, metodo):
	print "* Creado contenedores con metodo: <[ %s ]>" % (metodo)
	print "	Referencia en almacenamiento: %s" % (nombre_odoo)

	if not dic_argv["debug"]:
		print "Entrar en odoo con %s" % (dic_argv["dominio"])