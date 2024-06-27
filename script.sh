# Updating the system
dnf update -y
echo "System updated."

# Installing nginx
dnf install nginx -y
# Check if nginx is installed --
echo "Nginx installed."

systemctl start nginx
# Check if nginx is running
echo "Nginx is running."

# Enabling nginx to start on boot
systemctl enable nginx