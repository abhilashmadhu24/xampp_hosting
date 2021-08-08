#!/bin/bash

#######################################
#SCRIPT NAME		:hostssl.sh
#DESCRIPTION		:Install ssl using letencrypt certbot and add details to configuration file
#USAGE			:run sh hostssl.sh
#			:give domain name and document root on prompt
#######################################

echo "###################### SSL INSTALLATION USING CERTBOT #####################################"


read -p " Domain : " DOMAIN
LOC="/opt/lampp"
HLOC="$LOC/htdocs/$DOMAIN"
IPADDR=$(hostname -I | awk '{print $1}')

          cp default_httpdssl default_httpdssl.txt
          cp default_htaccess default_htaccess.txt
	  sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt
	  sed -i "s/IPADDR/$IPADDR/g" default_httpdssl.txt


begin_ssl()

{
      grep "$DOMAIN" /$LOC/etc/httpd.conf | grep www
      if [ $? != 0 ];
      then
      echo "SSL without www"
      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN --register-unsafely-without-email --agree-tos
      else
      echo "SSL with www"
      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN --register-unsafely-without-email --agree-tos
      fi
}


cat $LOC/etc/httpd.conf | grep -q "$DOMAIN"

if [ $? != 0 ]
     then
     printf "\nNon-SSL entries not found for $DOMAIN.. Please run host.sh to continue....\n"
     echo "Process Terminated "
      
elif grep -q "$DOMAIN/cert.pem" $LOC/etc/httpd.conf ; then
     echo #####################################################################################################################
     echo ssl entries of $DOMAIN already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     echo #####################################################################################################################
else

echo "Checking whether $DOMAIN is pointed to this server......"
     			sleep 1
     			DNS=$(host -t A "$DOMAIN" | awk {'print $4'})
     			SERVER=$(curl ipinfo.io/ip)

			if [ "$SERVER" = "$DNS" ] ;
    				then
   	 				echo "\n###################################################################################"
	 				echo  "$DOMAIN is pointed to this server, Beginning SSL Installation using certbot......"
    	 				echo "###################################################################################"
    	 
    	 				echo "\n###################################################################################"
    	 				echo  "Checking certbot is available.."
    	 				echo "###################################################################################"
    	 		sleep 1
					/usr/bin/which certbot
					if [ $? = 0 ]; then
	    						begin_ssl
					else
					/usr/bin/which snapd
            					if [ $? = 0 ]; then
	     						snap install certbot -y
	     						begin_ssl
            					else
             						apt install snapd -y
             						snap install certbot -y
	     						begin_ssl
            					fi
					fi	 
	
			else

    			echo "${green}Please make sure to point correct records of $DOMAIN to this server  and run hostssl.sh for SSL installations......${clean}"
    			sleep 1

                        fi

   		if grep -q "$DOMAIN/cert.pem" $LOC/etc/httpd.conf ; then
			echo "\n#####################################################################################################################"
  			echo "ssl entries of $DOMAIN already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!"
			echo "#####################################################################################################################"
			sleep 1
    			else

				DATE=$(date +"%Y-%m-%d-%H-%M-%S")
				cp $LOC/etc/httpd.conf $LOC/etc/httpd_backups/httpd_ssl.conf-"$DATE"

			echo "\n#################################################################################################################"
			echo " SSL entres for $DOMAIN added to configuration file. Previous configuration is copied on "$LOC/etc/httpd_backups/httpd_ssl.conf-"$DATE"" "
			echo "#####################################################################################################################"

			cat default_httpdssl.txt  >> $LOC/etc/httpd.conf

			echo "Checking configuration file...."
			echo ""

			/opt/lampp/bin/apachectl -t > /dev/null 2>&1
 			if [ $? != 0 ]
	     			then
     				echo ""
     				echo " Errors found on configuration file. Process reversed "
     				echo ""
     				mv $LOC/etc/httpd_backups/httpd_ssl.conf-"$DATE" /$LOC/etc/httpd.conf
     				echo "\n ${red}SSL INSTALLATION TERMINATED Please check manually and run hostssl.sh${clean}"
     				echo ""
     				echo "Checking for any current syntax errors......"
     				/opt/lampp/bin/apachectl -t
           				if [ $? != 0 ];
           					then echo "
							${red}URGENT ERROR PLEASE CHECK CONFIGURATION BEFORE RELOADING SERVICE"
           				sleep 1
           				fi
     			else
	 		echo "Reloading service..."
         		/opt/lampp/lampp reloadapache
	 		echo ""
	 		echo " Successfully installed SSL for  $DOMAIN ..... "
	 		echo "Adding HTTPS redirection on .htaccess"
	 		touch .htaccess
	 		cat default_htaccess.txt >> .htaccess
	 		mv .htaccess /opt/lampp/htdocs/"$DOMAIN"/
	 		chmod 644 /opt/lampp/htdocs/$DOMAIN/.htaccess
	 		chown -R $USER.$USER /opt/lampp/htdocs/$DOMAIN/.htaccess
 			fi

fi		
fi

rm -rf default_htaccess.txt default_httpdssl.txt
