#!/bin/bash

echo "Configuring ECS agent"
cat <<'EOF' | sudo tee /etc/ecs/ecs.config
ECS_CLUSTER=arm_ecs_cluster
ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
EOF

apt update -y
apt install -y apache2

a2enmod proxy proxy_http rewrite
cat <<EOT > /etc/apache2/sites-available/www.conf
<VirtualHost *:80>
  RewriteEngine On
  RewriteRule ^/$ http://localhost:3000/nekretnine.html [P,L]
  ProxyPass / http://localhost:3000/
  ProxyPassReverse / http://localhost:3000/
  ErrorLog /var/log/apache2/error.log
  CustomLog /var/log/apache2/access.log combined
  ProxyPreserveHost On
</VirtualHost>
EOT
a2ensite www.conf
a2dissite 000-default.conf
systemctl reload apache2
systemctl enable apache2
