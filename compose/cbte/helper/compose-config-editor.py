#!/usr/local/bin/python
import os
import sys
import yaml


class IndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)


cb_scheme = os.environ.get('CLOUDBEAVER_SCHEME', "http")

le = 0
if len(sys.argv) > 1 and sys.argv[1] == "le":
	le = 1
	cb_scheme = "https"


with open('/docker-compose.tmpl.yml') as file:
    document = yaml.full_load(file)

use_external_db = os.environ.get('USE_EXTERNAL_DB', "false")
if use_external_db.lower() == "true":
	del document['services']['postgres']

certbot_config = {
	"image": "certbot/certbot",
	"entrypoint": "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'",
	"volumes": [
  		"./data/certbot/conf:/etc/letsencrypt",
  		"./data/certbot/www:/var/www/certbot"
  	]
}


nginx_http_volumes = [
	"./nginx/nginx.http.conf.template:/etc/nginx/templates/cloudbeaver.conf.template",
	"./nginx/cloudbeaver.locations:/etc/nginx/conf.d/cloudbeaver.locations"
	]
nginx_ssl_volumes = [
	"./nginx/nginx.https.conf.template:/etc/nginx/templates/cloudbeaver.conf.template",
	"./nginx/cloudbeaver.locations:/etc/nginx/conf.d/cloudbeaver.locations",
	"./nginx/ssl:/etc/nginx/ssl"
	]
nginx_le_volumes = [
	"./nginx/cloudbeaver.locations:/etc/nginx/conf.d/cloudbeaver.locations",
	"./nginx/nginx.le.conf.template:/etc/nginx/templates/cloudbeaver.conf.template",
	"./data/certbot/conf:/etc/letsencrypt",
	"./data/certbot/www:/var/www/certbot"
	]

if le and cb_scheme == "https":
	document['services']['certbot'] = certbot_config
	document['services']['nginx']['volumes'] = nginx_le_volumes
elif cb_scheme == "https":
	document['services']['nginx']['volumes'] = nginx_ssl_volumes
else:
	document['services']['nginx']['volumes'] = nginx_http_volumes


####### AWS AMI helper
volume_local_paths = {
  "metadata_data": "/var/dbeaver/postgre",
  "te_data": "/var/dbeaver/cloudbeaver/workspace",
  "dc_data": "/var/dbeaver/domain-controller/workspace",
  "rm_data": "/var/dbeaver/resource-manager/workspace",
  "qm_data": "/var/dbeaver/query-manager/workspace",
  "tm_data": "/var/dbeaver/task-manager/workspace"
}

def volumes_config(volume):
	volume_config = {
	    "driver": "local",
	    "driver_opts": {
	      	"type": "none",
	      	"o": "bind",
	      	"device": volume_local_paths.get(volume)
	    }
	}
	return volume_config

if os.environ.get("DBEAVER_TEAM_EDITION_AMI") is not None:
	for volume in document['volumes']:
		if volume == "kafka_data":
			continue
		document['volumes'][volume] = volumes_config(volume)



with open('/docker-compose.yml', 'w') as file:
    documents = yaml.dump(document, file, Dumper=IndentDumper, sort_keys=False)
