# Updating the system
dnf update -y
echo "System updated."

# Installing nginx
dnf install nginx -y
# Check if nginx is installed --
echo "NGINX installed."

systemctl start nginx
# Check if nginx is running
echo "NGINX is running."

# Enabling nginx to start on boot
systemctl enable nginx

# Copying local server block to /etc/nginx/conf.d/default.conf
cp server-block.conf /etc/nginx/conf.d/default.conf
echo "Local server block setup and copied to /etc/nginx/conf.d/default.conf"

# Restarting nginx
systemctl restart nginx
echo "Restarted NGINX."

# Installing python3 and augeas-libs
# for later installing certbot with pip
dnf install python3 augeas-libs
echo "Python3 and augeas-libs installed."

# Removing existing certbot installation
dnf remove certbot

# Installing certbot with a virtual environment
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-nginx
echo "Certbot installed."

# Creating a symbolic link to the certbot binary
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Running certbot to get the certificate
echo "Running certbot to get the certificate ..."
certbot --nginx --non-interactive --agree-tos --email your-email@example.com -d yourdomain.com