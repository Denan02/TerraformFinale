#!/bin/bash

echo "Configuring ECS agent"
cat <<'EOF' | sudo tee /etc/ecs/ecs.config
ECS_CLUSTER=arm_ecs_cluster
ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
EOF
apt-get update -y
apt-get install -y docker.io

systemctl enable --now docker

# Preuzimanje i pokretanje ECS agenta
docker run --name ecs-agent \
  --detach=true \
  --restart=always \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --volume=/var/log/ecs/:/log \
  --volume=/var/lib/ecs/data:/data \
  --net=host \
  --env=ECS_CLUSTER=${cluster_name} \
  --env=ECS_LOGFILE=/log/ecs-agent.log \
  --env=ECS_DATADIR=/data \
  amazon/amazon-ecs-agent:latest

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
