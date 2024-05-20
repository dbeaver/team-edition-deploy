#!/usr/local/bin/python
import os
import re
import sys
import yaml


class IndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)


cb_scheme = os.environ.get('CLOUDBEAVER_SCHEME', "http")

with open('/docker-compose.tmpl.yml') as file:
    document = yaml.full_load(file)

use_external_db = os.environ.get('USE_EXTERNAL_DB', "false")
if use_external_db.lower() == "true":
	del document['services']['postgres']

nginx_ssl_volumes = [
	"./nginx/nginx.https.conf:/etc/nginx/conf.d/default.conf",
	"./nginx/ssl:/etc/nginx/ssl"
	]

if cb_scheme == "https":
	document['services']['nginx']['volumes'].extend(nginx_ssl_volumes)
	
	
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

volumes_without_mapping = ['kafka_data', 'nginx_ssl_data', 'nginx_conf_data']

if os.environ.get("DBEAVER_TEAM_EDITION_AMI") is not None:
	for volume in document['volumes']:
		if volume in volumes_without_mapping:
			continue
		document['volumes'][volume] = volumes_config(volume)



with open('/docker-compose.yml', 'w') as dcFile:
    documents = yaml.dump(document, dcFile, Dumper=IndentDumper, sort_keys=False)
dcFile.close()

compose_project_name = os.environ.get("COMPOSE_PROJECT_NAME")
replica_count_te = int(os.environ.get("REPLICA_COUNT_TE"))

if replica_count_te != 1:

	servers_config = "{\n            " + ",\n            ".join(
		f'te{i} = "http://{compose_project_name}-cloudbeaver-te-{i}:8978"' for i in range(1, replica_count_te + 1)
	) + "\n        }"

	with open("dbeaver-te.locations", "r") as readLocationsFile:
		default_content = readLocationsFile.read()
	readLocationsFile.close()
	new_content = re.sub(r'local servers = {[^}]*}', f'local servers = {servers_config}', default_content)

	with open("dbeaver-te.locations", "w") as writeLocationsFile:
		writeLocationsFile.write(new_content)
	writeLocationsFile.close()