#!/bin/bash
#
#   ___        _        _____ _____ _
#  / _ \      | |      /  ___/  ___| |
# / /_\ \_   _| |_ ___ \ `--.\ `--.| |     __  __
# |  _  | | | | __/ _ \ `--. \`--. \ |     \ \/ /
# | | | | |_| | || (_) /\__/ /\__/ / |____  >  <
# \_| |_/\__,_|\__\___/\____/\____/\_____/ /_/\_\
#
# Description:
# A script to automate the setup of NGINX reverse proxy and SSL certificate (Certbot)
# for a service running on a local port.
#
#
# Usage: ./script.sh <email> <domain> <service_port>
# Example: ./script.sh johndoe@example.com sub.example.com 3000
#
#

# CONSTANT PATH
# The path to the nginx server block
nginx_dir="/etc/nginx/conf.d/default.conf"

# Condition:
# Checking if all the required arguments are provided
# If not, the script will output help and then exit.
if [ $# -ne 3 ]; then
    echo "Arguments Usage:"
    echo -e "\t <email> <domain> <service_port>"
    echo -e "\n<email> \t\t Your email address for the SSL certificate (required)"
    echo -e "<domain> \t\t Your domain name for the SSL certificate (required)"
    echo -e "<service_port> \t The port on which your service is running (required)"
    exit 1
fi

email=$1
domain=$2
service_port=$3

echo -e "\nChosen email: $email"
echo "Chosen domain for SSL and mapping service: $domain"
echo "Your service is running on local port localhost:$service_port"

echo -e "\nDo you want to continue? (y/n)"
read answer

# Condition:
# Exits the script if the user does not want to continue
# by checking the first character of the answer
if [ "$answer" == "${answer#[Yy]}" ] ; then
    echo "Exiting ..."
    exit 1
fi

# Updating the system
echo -e "\nUpdating the system ..."
dnf update -y
echo "System updated."

# Cleaning up previous residual files
# and removing the existing nginx installation
echo -e "\nCleaning up previous residual files ..."
rm -rf "$nginx_dir"
dnf remove nginx -y

# Installing nginx
echo -e "\nInstalling NGINX ..."
dnf install nginx -y

# Condition:
# Checking if nginx is installed correctly
if dnf list installed nginx > /dev/null 2>&1; then
    echo "NGINX installed."
else
    echo "Err: NGINX not installed."
    echo "Try re-running the script."
    exit 1
fi

# Starting nginx service
systemctl start nginx

# Condition:
# Checking if nginx is running
if systemctl is-active --quiet nginx; then
    echo "NGINX is running."
else
    echo "Err: Could not start NGINX, the process is not running."
    exit 1
fi

# Enabling nginx to start on boot
systemctl enable nginx

#
# ----
#   SERVER BLOCK CONFIGURATION
# ----
#

# Writing the input args to server-block
server_block="server {
        listen 80;

        # your domain name
        server_name $domain;

        location / {
                # The local port your application listens/running on
                proxy_pass http://127.0.0.1:$service_port;

                # Default HTTP headers
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;

                # Add custom headers here to forward to your service
                # ---
        }
}"

# Write the server block
# to /etc/nginx/conf.d/default.conf
printf "%s" "$server_block" > "$nginx_dir"
echo "Local server block setup and moved to /etc/nginx/conf.d/default.conf"

# Restarting nginx
systemctl restart nginx
echo "Restarted NGINX."
# Condition:
# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo "NGINX is running."
else
    echo "Err: Could not start NGINX, the process is not running."
    exit 1
fi

# Installing python3 and augeas-libs with dnf
# for later installing certbot with pip

# Multiple packages to install
packages=("python3" "augeas-libs")
for package in "${packages[@]}"; do
    dnf install "$package" -y

    # Condition:
    # Checking if the package is installed
    if dnf list installed "$package" > /dev/null 2>&1; then
        echo "$package is installed."
    else
        echo "Err: $package is not installed."
        exit 1
    fi
done

# Removing existing certbot installation
dnf remove certbot -y

# Installing certbot with a virtual environment
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip

# Multiple packages to install with pip
packages=("certbot" "certbot-nginx")
for package in "${packages[@]}"; do
    /opt/certbot/bin/pip install "$package"

    # Condition:
    # Checking if the package is installed
    if /opt/certbot/bin/pip show "$package" > /dev/null 2>&1; then
        echo "$package is installed."
    else
        echo "$package is not installed."
    fi
done

# Creating a symbolic link to the certbot binary
# to make it accessible globally (in PATH)
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Running certbot to get the certificate
echo "Running certbot to get the certificate ..."
certbot --nginx --non-interactive --agree-tos --email $email -d $domain
