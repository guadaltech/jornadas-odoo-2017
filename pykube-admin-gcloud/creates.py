#!/usr/bin/python
# -*- coding: utf-8 -*-

# Juan Manuel Torres - https://github.com/Tedezed

import sys
import pykube
from tools import *
from tools_gcloud import *

def create_gcloudDisks(volume_name, volume_capacity, dic_argv, ruta, project, zone):
	from oauth2client.client import GoogleCredentials
	from googleapiclient import discovery
	import os

	os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = ruta
	os.environ["GCLOUD_PROJECT"] = project

	credentials = GoogleCredentials.get_application_default()
	compute = discovery.build('compute', 'v1', credentials=credentials)
	if not dic_argv["debug"]:
		createDisk(compute, project, zone, volume_name, volume_capacity)
		pass
	else:
		print "gcloud disks json: " + str(list_disks(compute, project, zone)) + "\n"

def create_volumes_gcloud(volume_name, volume_capacity, dic_argv, api):
	pv_yaml = load_file_yaml("kuberntetes_yaml/odoo-pg/%s" % ("pv_gcloud.yaml"))
	pvc_yaml = load_file_yaml("kuberntetes_yaml/odoo-pg/%s" % ("pvc.yaml"))
	pv_yaml["metadata"]["name"] = volume_name
	pv_yaml["spec"]['gcePersistentDisk']['pdName'] = volume_name
	pv_yaml["spec"]["capacity"]["storage"] = volume_capacity + "Gi"
	pvc_yaml["metadata"]["name"] = volume_name
	pvc_yaml["spec"]["resources"]["requests"]["storage"] = volume_capacity + "Gi"
	if not dic_argv["debug"]:
		print "Creando volumenen %s" % (volume_name)
		pykube.objects.PersistentVolume(api, pv_yaml).create()
		pykube.objects.PersistentVolumeClaim(api, pvc_yaml).create()
	else:
		pass

def create_service_odoo_ps(nombre_odoo, nombre_db, dic_argv, api, metodo):
	for i in ["db-svc.yaml", "odoo-svc.yaml"]:
		svc_yaml = ""
		svc_yaml = load_file_yaml("kuberntetes_yaml/odoo-pg/%s" % (i))
		if i == "db-svc.yaml":
			nombre = nombre_db
			svc_yaml["spec"]["selector"]["provider"] = nombre
		if i == "odoo-svc.yaml":
			nombre = nombre_odoo
			svc_yaml["spec"]["selector"]["app"] = nombre
		if i == "odoo-svc-gcloud.yaml":
			nombre = nombre_odoo
			svc_yaml["spec"]["selector"]["app"] = nombre

		svc_yaml["metadata"]["name"] = nombre
		svc_yaml["metadata"]["labels"]["app"] = nombre
		svc_yaml["metadata"]["labels"]["provider"] = nombre
		svc_yaml["metadata"]["labels"]["metodo"] = metodo

		if not dic_argv["debug"]:
			print "Creando servicio con %s" % (i)
			pykube.Service(api, svc_yaml).create()
		else:
			pass

def create_service(nombre, dic_argv, api, dir_name, name_yaml_svc, metodo):
	svc_yaml = load_file_yaml("kuberntetes_yaml/%s/%s" % (dir_name, name_yaml_svc))
	svc_yaml["spec"]["selector"]["app"] = nombre
	svc_yaml["spec"]["selector"]["provider"] = nombre
	svc_yaml["metadata"]["name"] = nombre
	svc_yaml["metadata"]["labels"]["app"] = nombre
	svc_yaml["metadata"]["labels"]["provider"] = nombre
	svc_yaml["metadata"]["labels"]["metodo"] = metodo

	if not dic_argv["debug"]:
		print "Creando servicio con %s" % (nombre)
		pykube.Service(api, svc_yaml).create()
	else:
		pass

def add_limit_resources(rc_yaml, limit_replicas, limit_cpu, limit_mem):
	rc_yaml["spec"]["replicas"] = int(limit_replicas)
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["resources"]\
	["limits"]["cpu"] = limit_cpu + "m"
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["resources"]\
	["limits"]["memory"] = limit_mem + "Mi"
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["resources"]\
	["requests"]["cpu"] = str(int(limit_cpu)/2) + "m"
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["resources"]\
	["requests"]["memory"] = str(int(limit_mem)/2) + "Mi"
	return rc_yaml

def create_rc_ps(key_api_ps, nombre_ps, image_ps, nombre_odoo, nombre_mysql, \
	pass_mysql, nom_dom_ps, dic_argv, api):
	rc_yaml = load_file_yaml("kuberntetes_yaml/ps-mysqlps-rc-vol.yaml")
	rc_yaml["metadata"]["name"] = nombre_ps
	rc_yaml["metadata"]["labels"]["app"] = nombre_ps
	rc_yaml["metadata"]["labels"]["provider"] = nombre_ps
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["image"] = image_ps
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["name"] = nombre_ps
	rc_yaml["spec"]["template"]["metadata"]["labels"]["app"] = nombre_ps
	rc_yaml["spec"]["template"]["metadata"]["labels"]["provider"] = nombre_ps
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][0]["value"] = nom_dom_ps
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][1]["value"] = nombre_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][3]["value"] = pass_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][4]["value"] = "http://" + nombre_odoo
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][7]["value"] = dic_argv["ODOO_USER"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][8]["value"] = dic_argv["ODOO_PASS"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][12]["value"] = key_api_ps
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][13]["value"] = dic_argv["ADMIN_MAIL"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][14]["value"] = dic_argv["ADMIN_PASSWD"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][15]["value"] = dic_argv["PS_NOM_USER"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][16]["value"] = dic_argv["PS_APELLIDO_USER"]
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["env"][17]["value"] = dic_argv["PS_THEME"]
	rc_yaml = add_limit_resources(rc_yaml, dic_argv["ps_replicas"],\
	 dic_argv["limit_cpu"], dic_argv["limit_mem"])
	rc_yaml["spec"]["template"]["spec"]["containers"][0]\
		["volumeMounts"][0]["subPath"] = "%s/ps/html" % (nombre_odoo)
	rc_yaml["spec"]["template"]["spec"]["volumes"][0]\
		["persistentVolumeClaim"]["claimName"] = nombre_odoo

	if not dic_argv["debug"]:
		print "Creando rc con %s" % (nombre_ps)
		pykube.ReplicationController(api, rc_yaml).create()
	else:
		pass

def create_rc_mysql(nombre_mysql, image_mysql, nombre_odoo, pass_mysql, \
	nom_dom_ps, dic_argv, api):
	rc_yaml = load_file_yaml("kuberntetes_yaml/ps-mysqlmysql-rc-vol.yaml")
	rc_yaml["metadata"]["name"] = nombre_mysql
	rc_yaml["metadata"]["labels"]["app"] = nombre_mysql
	rc_yaml["metadata"]["labels"]["provider"] = nombre_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["image"] = image_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["name"] = nombre_mysql
	rc_yaml["spec"]["template"]["metadata"]["labels"]["app"] = nombre_mysql
	rc_yaml["spec"]["template"]["metadata"]["labels"]["name"] = nombre_mysql
	rc_yaml["spec"]["template"]["metadata"]["labels"]["provider"] = nombre_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"][0]\
		["value"] = pass_mysql
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"][1]\
		["value"] = dic_argv["PS_THEME"]
	rc_yaml = add_limit_resources(rc_yaml, "1", dic_argv["limit_cpu_db"], \
		dic_argv["limit_mem_db"])
	rc_yaml["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]\
		["subPath"] = "%s/mysql" % (nombre_odoo)
	rc_yaml["spec"]["template"]["spec"]["volumes"][0]\
		["persistentVolumeClaim"]["claimName"] = nombre_odoo

	if not dic_argv["debug"]:
		print "Creando rc con %s" % (nombre_mysql)
		pykube.ReplicationController(api, rc_yaml).create()
	else:
		pass

def create_rc_odoo(nombre_odoo, master_pass, image_odoo, nombre_db, \
	pass_db, image_db, dic_argv, api, metodo, nombre_mysql, pass_mysql, \
	key_api_ps, kminion_ip):
	for i in ["db-rc-vol.yaml", "odoo-rc-vol.yaml"]:
		rc_yaml = load_file_yaml("kuberntetes_yaml/odoo-pg/%s" % (i))
		if i == "db-rc-vol.yaml":
			nombre = nombre_db
			rc_yaml["metadata"]["labels"]["provider"] = nombre
			rc_yaml["spec"]["template"]["metadata"]["labels"]["provider"] = nombre
			rc_yaml["spec"]["template"]["spec"]["containers"][0]["image"] = image_db

			cont = 0
			for e in rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"]:
				if e["name"] == "POSTGRES_PASSWORD":
					rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"][cont]\
						["value"] = pass_db
				cont += 1

			rc_yaml["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]\
				["subPath"] = "%s/postgresql" % (nombre_odoo)
			rc_yaml["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]\
				["claimName"] = nombre_odoo
			
			if metodo == "odoo-simple" or metodo == "odoo-prestashop":
				try:
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_NOMBRE', 'value': dic_argv["CONF_NOMBRE"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_CALLE', 'value': dic_argv["CONF_CALLE"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_CIUDAD', 'value': dic_argv["CONF_CIUDAD"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_COD_ZIP', 'value': dic_argv["CONF_COD_ZIP"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_WEB', 'value': dic_argv["CONF_WEB"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_TELF', 'value': dic_argv["CONF_TELF"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_TELF_MOVIL', 'value': dic_argv["CONF_TELF_MOVIL"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_MAIL', 'value': dic_argv["CONF_MAIL"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'CONF_DNI', 'value': dic_argv["CONF_DNI"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'ODOO_USER', 'value': dic_argv["ODOO_USER"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'ODOO_PASS', 'value': dic_argv["ODOO_PASS"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'USER_MOBILE', 'value': dic_argv["USER_MOBILE"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'USER_MOBILE_PASS', 'value': dic_argv["USER_MOBILE_PASS"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'NUM_CUENTA', 'value': dic_argv["NUM_CUENTA"]})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'LOGO_BASE64', 'value': dic_argv["LOGO_BASE64"]})
					if metodo == "odoo-prestashop":
						rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"].append({'name': 'MYSQL_SERVER', 'value': nombre_mysql})
						rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"].append({'name': 'MYSQL_PASSWD', 'value': pass_mysql})
						rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"].append({'name': 'PS_WEBSERVICE_KEY', 'value': key_api_ps})
						rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"].append({'name': 'PS_DOMAIN', 'value': dic_argv["ps_dominio"]})
						rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"].append({'name': 'ODOO_TYPE', 'value': metodo})
				except KeyError:
					print "[ERROR 1006] Falta parametros necesarios."
					sys.exit(0)
			rc_yaml = add_limit_resources(rc_yaml, "1", dic_argv["limit_cpu_db"], \
				dic_argv["limit_mem_db"])
		if i == "odoo-rc-vol.yaml":
			nombre = nombre_odoo
			rc_yaml["metadata"]["labels"]["app"] = nombre
			rc_yaml["spec"]["template"]["spec"]["containers"][0]["image"] = image_odoo
			if metodo == "odoo-pg" or metodo == "odoo-simple" or \
			metodo == "odoo-prestashop":
				cont = 0
				for e in rc_yaml["spec"]["template"]["spec"]["containers"][0]["env"]:
					if e["name"] == "HOST":
						rc_yaml["spec"]["template"]["spec"]["containers"][0]\
							["env"][cont]["value"] = nombre_db
					if e["name"] == "PASSWORD":
						rc_yaml["spec"]["template"]["spec"]["containers"][0]\
							["env"][cont]["value"] = pass_db
					cont += 1
				rc_yaml["spec"]["template"]["spec"]["containers"][0]\
					["env"].append({'name': 'MASTER_PASS', 'value': master_pass})
				if metodo == "odoo-prestashop":
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'ODOO_TYPE', 'value': metodo})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'KMINION', 'value': kminion_ip})
					rc_yaml["spec"]["template"]["spec"]["containers"][0]\
						["env"].append({'name': 'PS_DOMAIN', 'value': dic_argv["ps_dominio"]})
			rc_yaml = add_limit_resources(rc_yaml, dic_argv["odoo_replicas"], \
				dic_argv["limit_cpu"], dic_argv["limit_mem"])
			rc_yaml["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]\
				["subPath"] = "%s/odoo/odoo-lib" % (nombre_odoo)
			rc_yaml["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][1]\
				["subPath"] = "%s/odoo/external-addons" % (nombre_odoo)
			rc_yaml["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][2]\
				["subPath"] = "%s/odoo/etc-odoo" % (nombre_odoo)
			rc_yaml["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]\
				["claimName"] = nombre_odoo
		rc_yaml["metadata"]["name"] = nombre
		rc_yaml["spec"]["template"]["metadata"]["labels"]["app"] = nombre
		rc_yaml["spec"]["template"]["spec"]["containers"][0]["name"] = nombre

		if not dic_argv["debug"]:
			print "Creando rc con %s" % (i)
			pykube.ReplicationController(api, rc_yaml).create()
		else:
			pass

def create_ingress(nombre, dic_argv, api, svc):
	if svc == "odoo":
		ingress_yaml = load_file_yaml("kuberntetes_yaml/odoo-pg/%s" % ("ingress.yaml"))
		ingress_yaml["spec"]["rules"][0]["host"] = dic_argv["dominio"]
	elif svc == "ps":
		ingress_yaml = load_file_yaml("kuberntetes_yaml/ps-mysql%s" % ("ingress.yaml"))
		ingress_yaml["spec"]["rules"][0]["host"] = dic_argv["ps_dominio"]
	ingress_yaml["metadata"]["name"] = nombre
	ingress_yaml["spec"]["rules"][0]["http"]["paths"][0]\
		["backend"]["serviceName"] = nombre
	if not dic_argv["debug"]:
		print "Creando ingress para %s" % (nombre)
		pykube.Ingress(api, ingress_yaml).create()
	else:
		pass