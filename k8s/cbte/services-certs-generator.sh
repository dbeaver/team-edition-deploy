#!/bin/bash

CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Security/OU=IT Department/CN=cloudbeaver.io"

SECRET_CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Secret Security/OU=IT Department/CN=cloudbeaver.io"

function get_mesh_cert() {
	mkdir crossSsl
	cd crossSsl
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$CERT_CSR" -newkey rsa:2048 -keyout key.key -out cert.crt
	cd ..
}

function get_secret_cert() {
	mkdir secretSsl
	cd secretSsl
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$SECRET_CERT_CSR" -newkey rsa:2048 -keyout key.key -out cert.crt
	cd ..
}

if [ ! -d crossSsl ]; then
	get_mesh_cert
fi

if [ ! -d secretSsl ]; then
	get_secret_cert
fi

if [ ! -d ingressSsl ]; then
	mkdir ingressSsl
fi

