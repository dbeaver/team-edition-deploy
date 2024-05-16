#!/usr/local/bin/python
import os
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

####### AWS AMI helper
volume_local_paths = {
  "metadata_data": "/var/dbeaver/postgre",
  "te_data": "/var/dbeaver/cloudbeaver/workspace",
  "dc_data": "/var/dbeaver/domain-controller/workspace",
  "rm_data": "/var/dbeaver/resource-manager/workspace",
  "qm_data": "/var/dbeaver/query-manager/workspace",
  "tm_data": "/var/dbeaver/task-manager/workspace",
  "nginx_ssl_data": "/var/dbeaver/nginx/ssl",
  "nginx_conf_data": "/var/dbeaver/nginx/conf"
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
