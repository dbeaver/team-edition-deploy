#!/usr/local/bin/python
import os
import re
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
  		"./nginx/letsencrypt/:/etc/letsencrypt/",
  		"./data/certbot/www:/var/www/certbot"
  	]
}

nginx_ssl_volumes = [
	"./nginx/nginx.https.conf:/etc/nginx/conf.d/default.conf",
	"./nginx/ssl:/etc/nginx/ssl"
	]

nginx_le_volumes = [
	"./nginx/nginx.le.conf:/etc/nginx/conf.d/default.conf",
	"./nginx/letsencrypt/:/etc/letsencrypt/",
	"./data/certbot/www:/var/www/certbot"
	]

if le and cb_scheme == "https":
	document['services']['certbot'] = certbot_config
	document['services']['nginx']['volumes'] = nginx_le_volumes
elif cb_scheme == "https":
	document['services']['nginx']['volumes'].extend(nginx_ssl_volumes)

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
file.close()

compose_project_name = os.environ.get("COMPOSE_PROJECT_NAME")
replica_count_te = int(os.environ.get("REPLICA_COUNT_TE"))

servers_config = "{\n            " + ",\n            ".join(
    f'te{i} = "http://{compose_project_name}-cloudbeaver-te-{i}:8978"' for i in range(1, replica_count_te + 1)
) + "\n        }"

with open("dbeaver-te.locations", "r") as file:
    default_content = file.read()
file.close()

new_content = re.sub(r'local servers = {[^}]*}', f'local servers = {servers_config}', default_content)

with open("dbeaver-te.locations", "w") as file:
    file.write(new_content)
file.close()