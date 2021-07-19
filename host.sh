#!/bin/bash
#######################################
#SCRIPT NAME            :host.sh
#DESCRIPTION            :Host domain on this server by adding on host file and creating document root

#USAGE                  :run sh host.sh
#                       :give domain name and document root on prompt
#######################################

cd /usr/local/scripts/hosting_script

rm -rf default_httpdssl.txt default_htaccess.txt default_httpd.txt > /dev/null 2>&1

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


if grep -rq "ServerAlias $DOMAIN" $LOC/etc/vhosts/ ; then
  echo "#####################################################################################################################"
  echo "Domain already found on configuration Please manually check /opt/lampp/etc/vhosts !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "#####################################################################################################################"
else

echo "###############################################"
echo "Domain name = $DOMAIN"
echo "Document root location = $HLOC \n"
echo "###############################################"

DATE=$(date +"%Y-%m-%d-%H-%M-%S")




printf "\nCreating directory and assigning ownership"
mkdir -p $HLOC
chown -R tanzanitebus.tanzanitebus $HLOC


printf "\nDomain added to configuration. " 

cat default_httpd.txt  > $LOC/etc/vhosts/$DOMAIN.conf

printf "\nChecking configuration file....\n"

/opt/lampp/bin/apachectl -t
 if [ $? != 0 ]
     then
     printf " Errors found on configuration file. Process reversed "
     rm -rf $LOC/etc/vhosts/$DOMAIN.conf
     rm -rf $HLOC 
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
if [ $SERVER = '41.59.227.152' ] ;
    then
    echo "###################################################################################"
    echo  "$DOMAIN is pointed to this server, Beginning SSL Installation using certbot......"
    echo "###################################################################################"
    
    grep $DOMAIN /$LOC/etc/vhosts/$DOMAIN.conf | grep www
      if [ $? != 0 ]
      then
	     echo "SSL without www" 
     certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN --register-unsafely-without-email --agree-tos
      else
	      echo "SSL with www"
     certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN -d www.$DOMAIN --register-unsafely-without-email --agree-tos
     fi     



if grep -rq "$DOMAIN/cert.pem" $LOC/etc/vhosts/ ; then
  echo "#####################################################################################################################"
  echo "ssl entries of $DOMAIN already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!"
  echo "#####################################################################################################################"
else

DATE=$(date +"%Y-%m-%d-%H-%M-%S")

cp $LOC/etc/vhosts/$DOMAIN.conf $LOC/etc/vhosts/$DOMAIN.conf-$DATE

echo "#####################################################################################################################"
echo " SSL entries for $DOMAIN added to configuration file. Previous configuration is copied on "$LOC/etc/vhosts/$DOMAIN.conf-$DATE" "
echo "#####################################################################################################################"

cat default_httpdssl.txt  >> $LOC/etc/vhosts/$DOMAIN.conf

printf "\nChecking configuration file...."
echo ""

/opt/lampp/bin/apachectl -t > /dev/null 2>&1

 if [ $? != 0 ]
     then
     echo ""
     echo " Errors found on configuration file. Process reversed "
     echo ""
     mv $LOC/etc/vhosts/$DOMAIN.conf-$DATE /$LOC/etc/vhosts/$DOMAIN.conf
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
	 chown tanzanitebus.tanzanitebus /opt/lampp/htdocs/$DOMAIN/.htaccess
 fi

rm -rf default_httpdssl.txt default_htaccess.txt default_httpd.txt 

fi

else
    printf "Please make sure to point correct records of $DOMAIN to this server (41.59.227.152) and run hostssl.sh for SSL installations......\n"
    echo "########################################################################################"


fi
fi
fi

echo "###############################################"
echo "Domain name = $DOMAIN"
echo "Document root location = $HLOC "
echo "###############################################"
rm -rf default_httpdssl.txt default_htaccess.txt default_httpd.txt > /dev/null 2>&1
