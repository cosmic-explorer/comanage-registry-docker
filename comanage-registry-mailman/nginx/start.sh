#! /bin/bash

# Nginx for GNU Mailman 3 Core for COmanage Registry Dockerfile entrypoint
#
# Portions licensed to the University Corporation for Advanced Internet
# Development, Inc. ("UCAID") under one or more contributor license agreements.
# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# UCAID licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# exit immediately on failure
set -e

# Configuration details that may be injected through environment
# variables or the contents of files.

injectable_config_vars=( 
    MAILMAN_CORE_HOST
    MAILMAN_CORE_PORT
    SERVER_NAME
)

# Default values.
MAILMAN_CORE_HOST="mailman-core"
MAILMAN_CORE_PORT="8001"

# If the file associated with a configuration variable is present then 
# read the value from it into the appropriate variable. 

for config_var in "${injectable_config_vars[@]}"
do
    eval file_name=\$"${config_var}_FILE";

    if [ -e "$file_name" ]; then
        declare "${config_var}"=`cat $file_name`
    fi
done

# Copy HTTPS certificate and key into place.
if [ -n "${NGINX_HTTPS_CERT_FILE}" ] && [ -n "${NGINX_HTTPS_KEY_FILE}" ]; then
    cp "${NGINX_HTTPS_CERT_FILE}" /etc/nginx/https.crt
    cp "${NGINX_HTTPS_KEY_FILE}" /etc/nginx/https.key
    chmod 644 /etc/nginx/https.crt
    chmod 600 /etc/nginx/https.key
    chown www-data /etc/nginx/https.key
fi

# Copy DH parameters for EDH ciphers into place
if [ -n "${NGINX_DH_PARAM_FILE}" ]; then
    cp "${NGINX_DH_PARAM_FILE}" /etc/nginx/dhparam.pem
    chmod 600 /etc/nginx/dhparam.pem
    chown www-data /etc/nginx/dhparam.pem
fi

# Edit the nginx configuration file in place to set the server name.
sed -i -e s@%%SERVER_NAME%%@"${SERVER_NAME:-unknown}"@ /etc/nginx/nginx.conf

# Wait for the mailman core container to be ready.
until nc -z -w 1 "${MAILMAN_CORE_HOST}" "${MAILMAN_CORE_PORT}"
do
    echo "Waiting for Mailman core container..."
    sleep 1
done

# Start nginx.
exec nginx -g 'daemon off;'
