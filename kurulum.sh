#!/bin/bash

distro_check(){
	ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
	if [[ $ID == ubuntu ]]; then
		main
	else
		die "ubuntu only"
	fi
}

curl_ip(){
        var='/openvpn-monitor'
        ip=`dig +short myip.opendns.com @resolver1.opendns.com`
        echo ">> Kurulum tamamlandi <<"
        echo "http://"${ip}${var}
}

install_openvpn() {
	echo ">> OpenVPN kurulumu baslatiliyor"
	echo ">> indirme islemi basliyor"
	curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
	chmod +x openvpn-install.sh
	./openvpn-install.sh
	apt-get -y install git curl apache2 libapache2-mod-wsgi python-geoip2 python-ipaddr python-humanize python-bottle python-semantic-version geoip-database-extra geoipupdate
	echo "Apache config ayalari yapiliyor"
	echo "WSGIScriptAlias /openvpn-monitor /var/www/html/openvpn-monitor/openvpn-monitor.py" >> /etc/apache2/conf-available/openvpn-monitor.conf
	echo "<Directory /var/www/html/openvpn-monitor>" >> /etc/apache2/conf-available/openvpn-monitor.conf
	echo "Options FollowSymLinks" >> /etc/apache2/conf-available/openvpn-monitor.conf
	echo "AllowOverride All" >> /etc/apache2/conf-available/openvpn-monitor.conf
	echo "</Directory>" >> /etc/apache2/conf-available/openvpn-monitor.conf
	a2enconf openvpn-monitor
	systemctl restart apache2
	echo "OpenVPN-Monitor kurulumu baslatiliyor"
	cd /var/www/html
	git clone https://github.com/ufukguler/openvpn-monitor.git
	echo "duplicate-cn" >> /etc/openvpn/server/server.conf
	echo "management 127.0.0.1 5555" >> /etc/openvpn/server/server.conf
	service openvpn restart
	service openvpn-server@server restart

	echo "AuthType Basic" >> /var/www/html/openvpn-monitor/.htaccess
	echo 'AuthName "Restricted Files"' >> /var/www/html/openvpn-monitor/.htaccess
	echo "AuthUserFile /var/www/.monitor" >> /var/www/html/openvpn-monitor/.htaccess
	echo "Require valid-user" >> /var/www/html/openvpn-monitor/.htaccess
	echo "monitor sayfasina ulasim icin kullanici olusturuluyor"
	read -p 'lutfen bir kullanici adi giriniz: ' uservar
	echo "$uservar kullanicisi olusturuluyor"
	echo "$uservar icin parola giriniz"
	sudo htpasswd -c /var/www/.monitor $uservar
	systemctl restart apache2
}


main() {
	cd
	clear
	install_openvpn
	curl_ip
}

if [[ "$EUID" -ne 0 ]]; then
	echo "root olarak calistirin"
	exit
else
	distro_check
fi
