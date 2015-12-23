#!/usr/bin/env bash

#VER=$(docker --version | awk '{print $3}' | awk -F. '{print $1 * 10000 + $2 * 100 + $3}')
#if (( $VER >= 10900 )) ; then
#    sed -i -e "s|^#ARG|ARG|g" Dockerfile
#    docker build -t yhfu/owncloud-$(uname -m) --build-arg MYARCH=$(uname -m) .
#fi

sed -e "s|yhfudev/docker-lamp|yhfu/lamp-$(uname -m)|g" \
    -i Dockerfile
docker build -t yhfu/owncloud-$(uname -m) .

# example:
#
# DN_TLS=/srv/owncloud/sslcerts
# FN_CERT=server
# for i in data config apps sslcerts; do mkdir -p /srv/owncloud/$i ; done
# chown -R 33:33 /srv/owncloud/   # chown -R http:http /srv/owncloud/
# cd ${DN_TLS}
# Create a RSA private key for your Apache server
# openssl genrsa 2048 > ${DN_TLS}/${FN_CERT}.key
# Create a Certificate Signing Request (CSR)
# openssl req -new \
#     -key ${DN_TLS}/${FN_CERT}.key \
#     -out ${DN_TLS}/${FN_CERT}.csr
# Create a self-signed CA Certificate (X509 structure) with the RSA key of the CA
# openssl req -x509 -days 3650 \
#     -key ${DN_TLS}/${FN_CERT}.key \
#     -in  ${DN_TLS}/${FN_CERT}.csr \
#     -out ${DN_TLS}/${FN_CERT}.crt
# docker run \
#     -v /srv/owncloud/data:/usr/share/webapps/owncloud/data \
#     -v /srv/owncloud/config:/etc/webapps/owncloud/config \
#     -v /srv/owncloud/sslcerts:/https \
#     --name owncloud -p 10080:80 -p 10443:443 -d yhfu/owncloud-$(uname -m)

##     -v /srv/owncloud/apps:/usr/share/webapps/owncloud/apps
