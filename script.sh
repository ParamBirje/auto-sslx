# Paths
config_file="./server-block.conf"
nginx_dir="/etc/nginx/conf.d/default.conf"

# Checking if all the required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage:"
    echo -e "\t$0 <email> <domain> <service_port> \n"
    echo -e "<email> \t\t Your email address for the SSL certificate (required)"
    echo -e "<domain> \t\t Your domain name for the SSL certificate (required)"
    echo -e "<service_port> \t The port on which your service is running (required)"
    exit 1
fi

email=$1
domain=$2
service_port=$3

echo "Chosen email: $email"
echo "Chosen domain for SSL and mapping service: $domain"
echo "Your service is running on local port localhost:$service_port"

echo "Do you want to continue? (y/n)"
read answer

# Exits the script if the user does not want to continue
# by checking the first character of the answer
if [ "$answer" == "${answer#[Yy]}" ] ; then
    echo "Exiting ..."
    exit 1
fi

# Updating the system
echo "Updating the system ..."
dnf update -y
echo "System updated."

# Installing nginx
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

# Writing the input args to server-block.conf
temp_file=$(mktemp)
new_proxy_pass="127.0.0.1:$service_port"

sed -e "s|^\s*proxy_pass.*$|                proxy_pass $new_proxy_pass;|"     -e "s|^\s*server_name.*$|        server_name $domain;|" "$config_file" > "$temp_file"

# Move the temp_file to the server block 
# in /etc/nginx/conf.d/default.conf
mv "$temp_file" "$nginx_dir"
echo "Local server block setup and copied to /etc/nginx/conf.d/default.conf"

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
dnf remove certbot

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
