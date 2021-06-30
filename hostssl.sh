#!/bin/bash

#######################################
#SCRIPT NAME		:hostssl.sh
#DESCRIPTION		:Install ssl using letencrypt certbot and add details to configuration file
#USAGE			    :run sh hostssl.sh
#			        :give domain name and document root on prompt
#######################################

echo "###################### SSL INSTALLATION USING CERTBOT #####################################"

read -p " Domain : " DOMAIN
LOC="/opt/lampp"
HLOC="$LOC/htdocs/$DOMAIN"

cd /usr/local/scripts/hosting_script

cp default_httpdssl default_httpdssl.txt
cp default_htaccess default_htaccess.txt



grep -rq "ServerName $DOMAIN" $LOC/etc/vhosts/

if [ $? != 0 ]
     then
     printf "\nNon-SSL entries not found for $DOMAIN.. Please run host.sh to continue....\n"
     echo "Process Terminated "
      
elif grep -rq "$DOMAIN/cert.pem" $LOC/etc/vhosts/ ; then
     echo #####################################################################################################################
     echo ssl entries of $DOMAIN already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     echo #####################################################################################################################
else

printf "\nChecking whether $DOMAIN is pointed to this server...... \n"

SERVER=$(host -t A $DOMAIN | awk {'print $4'})
if [ $SERVER = '41.59.227.152' ] ;
    then
    printf "$DOMAIN is pointed to this server, Beginning SSL Installation using certbot......\n"
    echo " "

    grep $DOMAIN /$LOC/etc/httpd.conf | grep www
      if [ $? != 0 ]
      then
	     echo " SSL without www"
             sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
             sed -i "s/www.//g" default_htaccess.txt
             sed -i "s/www.//g" default_httpdssl.txt
             sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt

      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN --register-unsafely-without-email --agree-tos
      else
	      echo " SSL with www"
	      sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt

      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN -d www.$DOMAIN --register-unsafely-without-email --agree-tos
     fi



DATE=$(date +"%Y-%m-%d-%H-%M-%S")

cp $LOC/etc/vhosts/$DOMAIN.conf $LOC/etc/vhosts/$DOMAIN.conf-$DATE

sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt

echo ""
echo " SSL entries for $DOMAIN added to configuration file. Current configuration is copied as "$LOC/etc/httpd_backups/httpd_ssl.conf-$DATE" "
echo ""

cat default_httpdssl.txt  >> $LOC/etc/vhosts/$DOMAIN.conf

rm -f default_httpdssl.txt
echo " checking configuration file...."
echo ""

/opt/lampp/bin/apachectl -t

 if [ $? != 0 ]
     then
     echo ""
     echo " Errors found on configuration file. Process reversed "
     echo ""
     mv $LOC/etc/vhosts/$DOMAIN.conf-$DATE /$LOC/etc/vhosts/$DOMAIN.conf
     echo " SSL INSTALLATION TERMINATED!!!!!!!!!!!!!"
     echo ""
     echo "Checking for any current syntax errors......"
     /opt/lampp/bin/apachectl -t
           if [ $? != 0 ]
           then echo " URGENT ERROR PLEASE CHECK CONFIGURATION BEFORE RELOADING SERVICE "
           fi     
     else
	 echo "Reloading service..."
         /opt/lampp/lampp reloadapache
	 echo ""
	 echo " Successfully installed SSL for  $DOMAIN ..... "
	 echo ""
	 printf "\n Adding HTTPS redirection and exclude POST request on .htaccess\n"
         touch .htaccess
         cat default_htaccess.txt >> .htaccess
         mv .htaccess /opt/lampp/htdocs/$DOMAIN/
         chmod 644 /opt/lampp/htdocs/$DOMAIN/.htaccess
         chown tanzanitebus.tanzanitebus /opt/lampp/htdocs/$DOMAIN/.htaccess
 fi
else echo "Please check $DOMAIN have correct records pointed to this domain and try again"
rm -f default_httpdssl.txt default_htaccess.txt > /dev/null 2>&1
fi
fi

echo "#############################################################"

rm -f default_httpdssl.txt default_htaccess.txt > /dev/null 2>&1
