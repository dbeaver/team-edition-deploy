#!/bin/bash

set -euo pipefail

CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Security/OU=IT Department/CN=cloudbeaver.io"

SECRET_CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Secret Security/OU=IT Department/CN=cloudbeaver.io"


aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com


function get_secret_cert() {
	mkdir cert
	cd cert
	mkdir private
	mkdir public
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$CERT_CSR" -newkey rsa:2048 -keyout private/dc-key.key -out public/dc-cert.crt
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$SECRET_CERT_CSR" -newkey rsa:2048 -keyout private/secret-key.key -out private/secret-cert.crt
	cd ..
}


if [ ! -d cert ]; then
	get_secret_cert
fi

for svc in $TESERVICES; do
  echo Build \"$svc\"

  if [ "$svc" = "postgres" ]; then
    TEVERSION=16 
    docker pull dbeaver/dbeaver-"${svc}":${TEVERSION}
    docker build -t dbeaver-"${svc}" --build-arg TEVERSION=${TEVERSION} -f "${svc}".Dockerfile .
    docker tag dbeaver-"${svc}" ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DEPLOYMENT_ID}-team-"${svc}":${TEVERSION}
    docker push ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DEPLOYMENT_ID}-team-"${svc}":${TEVERSION}
  else
    docker pull dbeaver/team-"${svc}":${TEVERSION}
    docker build -t team-"${svc}" --build-arg TEVERSION=${TEVERSION} -f "${svc}".Dockerfile .
    docker tag team-"${svc}" ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DEPLOYMENT_ID}-team-"${svc}":${TEVERSION}
    docker push ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DEPLOYMENT_ID}-team-"${svc}":${TEVERSION}
  fi
 done