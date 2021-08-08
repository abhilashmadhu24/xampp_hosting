#!/bin/bash
############################################################################################################
#SCRIPT NAME            :host.sh
#DESCRIPTION            :Host domain on this server by adding on host file and creating document root
#USAGE                  :run sh host.sh
#                       :give domain name, document root and FTP username on prompt
############################################################################################################

IPADDR=$(hostname -I | awk '{print $1}')
green='\033[0;32m'
clean='\033[0m'
yellow='\033[0;33m'
red='\033[0;31m'


begin_ssl()

{
      grep "$DOMAIN" /$LOC/etc/httpd.conf | grep www
      if [ $? != 0 ];
      then
      echo "SSL without www"
      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN --register-unsafely-without-email --agree-tos
      else
      echo "SSL with www"
      certbot certonly --debug --webroot -w /opt/lampp/htdocs/$DOMAIN -d $DOMAIN -d www.$DOMAIN --register-unsafely-without-email --agree-tos
      fi
}

rm -rf default_httpdssl.txt default_htaccess.txt default_httpd.txt .htaccess > /dev/null 2>&1

cp default_httpd default_httpd.txt
cp default_httpdssl default_httpdssl.txt
cp default_htaccess default_htaccess.txt
cp default_index default_index.txt
echo "
${yellow}###########################################################${clean}"
echo " Confirm wheather you like to add a new Domain or a sub-domain  "
echo "1 : Domain"
echo "2 : Sub-domain"

read -p "Enter your choice.. 1/2 : " CHOICE
if [ "$CHOICE" = "1" ]; then
          read -p "Domain name : " DOMAIN
          sed -i "s/IPADDR/$IPADDR/g" default_httpd.txt
	  sed -i "s/DOMAIN/$DOMAIN/g" default_httpd.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
          sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt
	  sed -i "s/IPADDR/$IPADDR/g" default_httpdssl.txt

elif [ "$CHOICE" = "2" ]; then
              read -p "Sub-domain name : " DOMAIN
              sed -i "s/IPADDR/$IPADDR/g" default_httpd.txt
              sed -i "s/www.//g" default_httpd.txt
              sed -i "s/DOMAIN/$DOMAIN/g" default_httpd.txt

	      sed -i "s/DOMAIN/$DOMAIN/g" default_htaccess.txt
	      sed -i "s/www.//g" default_htaccess.txt

	      sed -i "s/www.//g" default_httpdssl.txt
	      sed -i "s/DOMAIN/$DOMAIN/g" default_httpdssl.txt
	      sed -i "s/IPADDR/$IPADDR/g" default_httpdssl.txt
              
else
	     echo "Aborted!!!";
fi

	     LOC="/opt/lampp"
	     HLOC="$LOC/htdocs/$DOMAIN"
             read -p "Give your FTP USER_NAME : " USER

		if [ -z "$DOMAIN" ];
       		then
       		echo "${red}Domain name could not be empty${clean}"
       		echo "Try again!!!!!"
       		elif grep -q "ServerAlias $DOMAIN" $LOC/etc/httpd.conf ; then
			echo ""
  			echo "${yellow}#####################################################################################################################${clean}"
       			echo "Domain already found on configuration Please manually check /opt/lampp/etc/httpd.conf !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
       			echo "${yellow}#####################################################################################################################${clean}"
 
       		else    echo ""
			echo "${green}###############################################${clean}"
       			echo "Domain name = $DOMAIN"
       			echo "Document root location = $HLOC "
       			echo "${green}###############################################${clean}"
			sleep 1
      
			DATE=$(date +"%Y-%m-%d-%H-%M-%S")

      			mkdir -p $LOC/etc/httpd_backups/
      			cp $LOC/etc/httpd.conf $LOC/etc/httpd_backups/httpd.conf-"$DATE"

      			echo "Creating directory and assigning ownership "
     			 id -u $USER 
         		if [ $? -eq 0 ];then
	   			echo "USER $USER ALREADY EXISTS.....PLEASE USE OLD PASSWORD"
	   			echo "$USER" "$DOMAIN" > ftp_details
         		else  	
           		PASS=$(head -n 4096 /dev/urandom | tr -dc a-zA-Z0-9 | cut -b 1-16)
           		useradd -m $USER
	     		if [ $? -eq 0 ];then
	     		echo "$USER:$PASS" | chpasswd
	     		echo $DOMAIN $USER : $PASS > ftp_details
	     		fi
         		fi

      
     			mkdir -p "$HLOC"
			mv default_index.txt $HLOC/index.html
     			chown -R $USER.$USER "$HLOC"
			chmod -R 644  "$HLOC"
     			echo "Domain added to conf file. Previous configuration file is copied on $LOC/etc/httpd_backups/httpd.conf-$DATE"
     			sleep 1

     			cat default_httpd.txt  >> $LOC/etc/httpd.conf
     			echo "Checking configuration file...."

     			/opt/lampp/bin/apachectl -t
     			if [ $? != 0 ]
     				then
     					echo "
					${red}Errors found on configuration file. Process reversed${clean}"
     					mv $LOC/etc/httpd_backups/httpd.conf-"$DATE" /$LOC/etc/httpd.conf
     					echo "Checking for any current syntax errors....."
     					/opt/lampp/bin/apachectl -t
     					if [ $? != 0 ]
           					then echo "
							${red}URGENT ERROR PLEASE CHECK CONFIGURATION BEFORE RELOADIN SERVICE${clean}"
     					fi
     			else 
	 			echo "Reloading service..."
         			/opt/lampp/lampp reloadapache
	 			echo "\n ${green}###########################################${clean}"
	 			echo "Successfully hosted $DOMAIN ..... "
         			echo "${green}###########################################${clean}"
    			fi
   
			sleep 1

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
			echo " SSL entries for $DOMAIN added to configuration file. Previous configuration is copied on "$LOC/etc/httpd_backups/httpd_ssl.conf-"$DATE"" "
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
		

rm -rf default_httpdssl.txt default_htaccess.txt default_httpd.txt .htaccess default_index.txt index.html > /dev/null 2>&1
echo "
${green}###############################################${clean}"
echo "Domain name = $DOMAIN"
echo "Document root location = $HLOC "
echo "${green}###############################################${clean}
"

