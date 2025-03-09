 #!/usr/bin/env bash
 ###################### Start Safe Header #######################
 # Developed by: Nataliia Stasiukova
 # Purpose: hw_8_nginx
 # Date: 07/03/2025
 # Version: 0.0.1
 set -x                  # display running logs
 set -o errexit          # error exit
 set -o pipefail
 set -o noclobber        # error on override file
 ###################### End Safe Header #########################

# Create shell script that will setup user_dir, auth, auth with pam and CGI scripting.
 
function install_ngnix {
	echo 'Installing nginx'
	echo "$user_password" | sudo -S apt update
	echo "$user_password" | sudo -S apt install nginx
}

function check_nginx {
	# Check in nginx installed
	nginx -v
	isInstalled=$?
	echo $isInstalled
	if [$isInstalled -gt '0']; then
		install_ngnix;
	else
		echo 'Nginx installed, skiping installation'; 
fi
}


function configure_nginx {
	echo "configure nginx"
	if [ -f /etc/nginx/sites-available/example.com ]; then
		echo 'File example.com already exist, skipping configuration';
	else
		echo 'Creating and configuring file example.com'
		echo "$user_password" | sudo -S tee /etc/nginx/sites-available/default > /dev/null <<EOF
			 server {
        			listen 80;
        			server_name example.com;
        			root /var/www/example.com;
        			index index.html;
			}
EOF

		echo "$user_password" | sudo -S ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
	fi
	
	# Configure nginx config
        echo $user_password | sudo -S tee /etc/nginx/nginx.conf > /dev/null <<EOF
		worker_processes 2;
		user www-data;

		error_log /var/log/nginx/error.log info;

		events {
        		use epoll;
        		worker_connections 128;
		}	

		http {
       			include /etc/nginx/sites-enabled/*;
       			include /etc/nginx/sites-available/*;
		} 		
EOF

echo 'Restarting nginx'
echo "$user_password" | sudo -S systemctl restart nginx
}

function configure_ssl {
	#echo 1 | certbot -v
 	#isCertbotInstalled=$?
 	#echo $isCertbotInstalled
 	#if ['$isCertbotInstalled' -gt '0']; then
		# Install certbot
	#	echo 'Insatlling certbot';
 	#	echo "$user_password" | sudo -S apt install certbot
        #else
 	#	echo 'Certbot installed, skiping installation';
	#fi
	#certbox python3-certbot-nginx -v
	
	#if ['$isCertbotNginxInsatlled' -gt '0'];then
	#	echo 'Installing phyton3-certbot-nginx';
		apt install python3-certbot-nginx
	#else 
	#	echo 'python3-certbot-nginx installed, skipping installation';
	#fi
	# Configure certbot
	# echo "$user_password" | sudo -S certbot --nginx -d example.com -d www.example.com
	 certbot certonly --standalone -d example.com -d www.example.com
         tee /etc/nginx/sites-available/default > /dev/null <<EOF
		server {
        		#listen 443 ssl http2 default_server;
        		#listen [::]:443 ssl http2 default_server;
    			listen 80;
        		server_name localhost;
    			root /var/www/html;
    			index index.html index.htm index.nginx-debian.html;

    			# Use the SSL certificates obtained by Certbot
    			# ssl_certificate "/etc/letsencrypt/live/www.example.com/fullchain.pem";
    			# ssl_certificate_key "/etc/letsencrypt/live/www.example.com/privkey.pem";
     			# ssl_session_cache shared:SSL:1m;
    			# ssl_session_timeout  10m;

    			location / {
            			try_files \$uri \$uri/ =404;
         		}

    			location ~ ^/~(.+?)(/.*)?$ {
		        	alias /home/$1/public_html$2;
   			}
		}


EOF
	# Restart nginx
	systemctl restart nginx
}

function install_dependencies {
	echo "install dependencies"
}

function configure_user_dir {
	cd /home/$1
        mkdir -p public_html
	tee /home/$1/public_html/index.html > /dev/null <<EOF
		<h1>Hello Nginx!</h1>
EOF
      	#usermod -a -G $1 www-data
      	chown -R $1:www-data /home/$1/public_html
 	chmod -R 755 /home/$1/public_html
 	systemctl restart nginx
}

function main {
	# Check that nginx is installed.
	check_nginx
	# Check that virtual host is configured, if not ask for virtual-host name and configure it.
	configure_nginx
	# Configure SSL
	# configure_ssl
	# Configure user dir
	configure_user_dir "$1"
	# Check that dependencies of user_dir, auth and CGI are present, if not install.
	install_dependencies
}

# Get sudo password
read -s -p "Password:" user_password

# Run script
main "$1"

# Remove sudo massword
unset user_password


