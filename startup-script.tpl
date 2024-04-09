#!/bin/bash

# Create an .env file with database connection information
cat <<EOF > /opt/web-app/.env
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_PORT=${db_port}
EOF

# Adjust permissions for the .env file
chown csye6225:csye6225 /opt/web-app/.env
chmod 600 /opt/web-app/.env

# (Optional) Restart your application to ensure it picks up the new environment variables
# systemctl restart your_application_service
