# Kube-admin (Pykube) - Automate Deployments in Google Container Engine

* [Guadaltech S.L.](http://www.guadaltech.es/)
* Juan Manuel Torres - [https://github.com/Tedezed](https://github.com/Tedezed)
* Version: Pre-alpha-0.0.2.0

kube-admin is a connector between WordPress requests of [Freyishop](http://freyishop.es) and Kubernetes

Example:

```
python kube-admin-2.py metodo=:odoo-simple CONF_NOMBRE=:test CONF_CALLE=:calle-test CONF_CIUDAD=:Sevilla CONF_COD_ZIP=:41710 CONF_WEB=:test.es CONF_TELF=:9000000 CONF_TELF_MOVIL=:70000000 CONF_MAIL=:'user@test.es' CONF_DNI=:XXXXXXXXX ODOO_USER=:xxxxxxx ODOO_PASS=:xxxxxxxx dominio=:empresa11.freyishop.es storage=:100 odoo_replicas=:1 limit_cpu=:500 limit_mem=:1024 limit_cpu_db=:500 limit_mem_db=:1024 ip_ingress=:80.XX.XX.XX USER_MOBILE=:"xxxxxxx" USER_MOBILE_PASS=:"xxxxxxx" NUM_CUENTA=:"2261 1134 84 0270267018" LOGO_BASE64=:"XXXXXXXX XXXXXXXX" debug=:true
```