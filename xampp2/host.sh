#!/bin/bash
#######################################
#SCRIPT NAME            :host.sh
#DESCRIPTION            :Host domain on this server by adding on host file and creating document root
#			:Default FTP user is managemybus as per cleint requirement
#USAGE                  :run sh host.sh
#                       :give domain name and document root on prompt
#######################################

cd /usr/local/scripts/

rm default_httpdssl.txt default_htaccess.txt default_httpd.txt .htaccess > /dev/null 2>&1

cp default_httpd default_httpd.txt
cp default_httpdssl default_httpdssl.txt
cp default_htaccess default_htaccess.txt


echo "###########################################################"
printf "\n \n"
printf " Confirm wheather you like to add a new Domain or a sub-domain\n"
echo "1 : Domain"
echo "2 : Sub-domain"

read -p "Enter your choice.. 1/2 : " CHOICE

if [ "$CHOICE" = "1" ]; then
          read -p "Domain name : " DOMAIN

	  sed -i "s/DOMAIN/$DOMAIN/g" default_httpd.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt

elif [ "$CHOICE" = "2" ]; then
              read -p "Sub-domain name : " DOMAIN

              sed -i "s/www.//g" default_httpd.txt
              sed -i "s/DOMAIN/$DOMAIN/g" default_httpd.txt

	      sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
	      sed -i "s/www.//g" default_htaccess.txt

	      sed -i "s/www.//g" default_httpdssl.txt
	      sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt
              
else
  echo "Aborted!!!";
fi

LOC="/opt/lampp"
HLOC="$LOC/htdocs/$DOMAIN"


if [ -z "$DOMAIN" ]
              then
              printf "\nDomain name could not be empty\n"
              echo "Try again!!!!!"
else


if grep -q "ServerAlias $DOMAIN" $LOC/etc/httpd.conf ; then
  echo "#####################################################################################################################"
  echo "Domain already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "#####################################################################################################################"
else

echo "###############################################"
echo "Domain name = $DOMAIN"
echo "Document root location = $HLOC \n"
echo "###############################################"

DATE=$(date +"%Y-%m-%d-%H-%M-%S")


mkdir -p $LOC/etc/httpd_backups/
cp $LOC/etc/httpd.conf $LOC/etc/httpd_backups/httpd.conf-$DATE


printf "\nCreating directory and assigning ownership "
mkdir -p $HLOC
chown -R managemybus.managemybus $HLOC


printf "\nDomain added to conf file. Previous configuration file is copied on "$LOC/etc/httpd_backups/httpd.conf-$DATE" "

cat default_httpd.txt  >> $LOC/etc/httpd.conf

printf "\nChecking configuration file....\n"

/opt/lampp/bin/apachectl -t
 if [ $? != 0 ]
     then
     printf " Errors found on configuration file. Process reversed "
     mv $LOC/etc/httpd_backups/httpd.conf-$DATE /$LOC/etc/httpd.conf
     printf "\nChecking for any current syntax errors....."
     /opt/lampp/bin/apachectl -t
     if [ $? != 0 ]
           then echo " URGENT ERROR PLEASE CHECK CONFIGURATION BEFORE RELOADING SERVICE "
           fi
     else 
	 echo "Reloading service..."
         /opt/lampp/lampp reloadapache
	 echo "###########################################"
	 echo "Successfully hosted $DOMAIN ..... "
         echo "###########################################"
 fi


printf "\nChecking whether $DOMAIN is pointed to this server...... \n"

SERVER=$(host -t A $DOMAIN | awk {'print $4'})
if [ $SERVER = '41.59.227.21' ] ;
    then
    echo "###################################################################################"
    echo  "$DOMAIN is pointed to this server, Beginning SSL Installation using certbot......"
    echo "###################################################################################"
    
    grep $DOMAIN /$LOC/etc/httpd.conf | grep www
      if [ $? != 0 ]
      then
	     echo "SSL without www" 
     /opt/letsencrypt/letsencrypt-auto certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN/ -d $DOMAIN --config /etc/letsencrypt/config.ini --agree-tos
      else
	      echo "SSL with www"
     /opt/letsencrypt/letsencrypt-auto certonly --debug --webroot -w /opt/lampp/htdocs/$DOC/ -d $DOMAIN -d www.$DOMAIN --config /etc/letsencrypt/config.ini --agree-tos
     fi     



if grep -q "$DOMAIN/cert.pem" $LOC/etc/httpd.conf ; then
  echo "#####################################################################################################################"
  echo "ssl entries of $DOMAIN already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!"
  echo "#####################################################################################################################"
else

DATE=$(date +"%Y-%m-%d-%H-%M-%S")

cp $LOC/etc/httpd.conf $LOC/etc/httpd_backups/httpd_ssl.conf-$DATE

echo "#####################################################################################################################"
echo " SSL entries for $DOMAIN added to configuration file. Previous configuration is copied on "$LOC/etc/httpd_backups/httpd_ssl.conf-$DATE" "
echo "#####################################################################################################################"

cat default_httpdssl.txt  >> $LOC/etc/httpd.conf

printf "\nChecking configuration file...."
echo ""

/opt/lampp/bin/apachectl -t > /dev/null 2>&1

 if [ $? != 0 ]
     then
     echo ""
     echo " Errors found on configuration file. Process reversed "
     echo ""
     mv $LOC/etc/httpd_backups/httpd_ssl.conf-$DATE /$LOC/etc/httpd.conf
     printf "\n SSL INSTALLATION TERMINATED Please check manually and run hostssl.sh\n"
     echo ""
     printf "\nChecking for any current syntax errors......\n"
     /opt/lampp/bin/apachectl -t
           if [ $? != 0 ]
           then printf "\nURGENT ERROR PLEASE CHECK CONFIGURATION BEFORE RELOADING SERVICE\n"
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
	 chown managemybus.managemybus /opt/lampp/htdocs/$DOMAIN/.htaccess
 fi

rm default_httpdssl.txt default_htaccess.txt default_httpd.txt 

fi

else
    printf "Please make sure to point correct records of $DOMAIN to this server (41.59.227.21) and run hostssl.sh for SSL installations......\n"
    echo "########################################################################################"


fi
fi
fi

echo "###############################################"
echo "Domain name = $DOMAIN"
echo "Document root location = $HLOC "
echo "###############################################"
