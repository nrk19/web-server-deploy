# Makefile
# this file will be used to deploy the web server and all the dependencies

# usage: 
# 		 - `make all` will obtain the ssl certs and deploy the server
# 		 - `make deploy` will deploy the server without obtaining new ssl certificates

# first we stop the servere if is running, since cerbot test web server conflicts with main server
stop:
	docker-compose down

# build the test server image
build_le_apache:
	docker build -t lets-encrypt-apache certbot

# run the web container used for the certbot test
run_le_apache:
	docker run -d --rm --name le_apache \
		-p 8080:80 \
		-v $$PWD/certbot/httpd.conf:/usr/local/apache2/conf/httpd.conf \
		-v $$PWD/certbot/htdocs:/usr/local/apache2/htdocs/ \
		httpd

# run certbot to obtain the certs
# the certificates will be stored inside a docker volume called "certs"
run_certbot:
	docker run -it --rm --name certbot \
		-v $$PWD/certbot/html:/data/letsencrypt \
		-v certs:/etc/letsencrypt \
		certbot/certbot \
		certonly --webroot \
		--email jcg@nrk19.com --agree-tos --no-eff-email \
		--webroot-path=/data/letsencrypt \
		-d nrk19.com -d www.nrk19.com -d grafana.nrk19.com -d uptime-kuma.nrk19.com

# stop and remove the test web server
stop_le_apache:
	docker stop le_apache 

get_certs: stop build_le_apache run_le_apache run_certbot stop_le_apache

# deploy the server using docker-compose 
deploy: stop
	docker-compose up -d
	./test.sh

# obtain certs and deploy the lab
all: get_certs deploy