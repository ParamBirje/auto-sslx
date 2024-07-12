# Paths
nginx_dir="/etc/nginx/conf.d/default.conf"

# Asking the user for input repeatedly 
# until a non-empty string is entered.
while [[ -z "$email" ]]; do
    echo "Enter your email address for the SSL certificate (important for expiry updates):"
    read email
done

while [[ -z "$domain" ]]; do
    echo "Enter your domain name you want the certificate for:"
    read domain
done

while [[ -z "$service_port" ]]; do
    echo "Enter the port on which your service is running:"
    read service_port
done

echo -e "\nChosen email: $email"
echo "Chosen domain for SSL and mapping service: $domain"
echo "Your service is running on local port localhost:$service_port"

echo -e "\nDo you want to continue? (y/n)"
read answer

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
echo -e "\nCleaning up previous residual files ..."
rm -rf "$nginx_dir"
dnf remove nginx -y

# Installing nginx
echo -e "\nInstalling NGINX ..."
dnf install nginx -y

# Checking if nginx is installed
if dnf list installed nginx > /dev/null 2>&1; then
    echo "NGINX installed."
else
    echo "Err: NGINX not installed."
    echo "Try re-running the script."
    exit 1
fi

systemctl start nginx
# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo "NGINX is running."
else
    echo "Err: Could not start NGINX, the process is not running."
    exit 1
fi

# Enabling nginx to start on boot
systemctl enable nginx

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
# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo "NGINX is running."
else
    echo "Err: Could not start NGINX, the process is not running."
    exit 1
fi

# Installing python3 and augeas-libs
# for later installing certbot with pip
packages=("python3" "augeas-libs")
for package in "${packages[@]}"; do
    dnf install "$package" -y

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

packages=("certbot" "certbot-nginx")
for package in "${packages[@]}"; do
    /opt/certbot/bin/pip install "$package"

    # Checking if the package is installed
    if /opt/certbot/bin/pip show "$package" > /dev/null 2>&1; then
        echo "$package is installed."
    else
        echo "$package is not installed."
    fi
done

# Creating a symbolic link to the certbot binary
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Running certbot to get the certificate
echo "Running certbot to get the certificate ..."
certbot --nginx --non-interactive --agree-tos --email $email -d $domain
