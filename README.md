Hi folks,

This is an automated hosting script for xampp based webservers on ubuntu servers. For those, who are not aware about xampp, xampp is a web-server bundled with apache php and mariadb. Usually we do commandline operations on xambb servers for hosting a domain. But we can automate all things like hosting, Letsencrypt SSL installation, .htaccess,FTP user and default index creation with this one step hosting script.

For installing XAMPP web server
```
>> apt update
>> wget https://www.apachefriends.org/xampp-files/7.1.10/xampp-linux-x64-7.1.10-0-installer.run
>> chmod +x xampp-linux-x64-7.1.10-0-installer.run
>> ./xampp-linux-x64-7.1.10-0-installer.run
```

More commandline operations on : https://dzone.com/articles/lamppxampp-commands

===================================================================================

First we need to clone repo to server: 

```
git clone https://github.com/abhilashmadhu24/xampp_hosting.git
cd xampp_hosting
sh host.sh and follow instructions
```


```

###########################################################
 Confirm wheather you like to add a new Domain or a sub-domain  
1 : Domain
2 : Sub-domain
Enter your choice.. 1/2 : 1
Domain name : zxtestivan.cf
Give your FTP USER_NAME : ivan

###############################################
Domain name = zxtestivan.cf
Document root location = /opt/lampp/htdocs/zxtestivan.cf 
###############################################

Creating directory and assigning ownership 


Domain added to conf file. Previous configuration file is copied on /opt/lampp/etc/httpd_backups/httpd.conf-2021-08-08-04-09-10
Checking configuration file....
Syntax OK
Reloading service...
XAMPP: Reload Apache...ok.

###########################################
Successfully hosted zxtestivan.cf ..... 
###########################################

Checking whether zxtestivan.cf is pointed to this server......
  

###################################################################################
zxtestivan.cf is pointed to this server, Beginning SSL Installation using certbot......
###################################################################################

###################################################################################
Checking certbot is available..
###################################################################################
/snap/bin/certbot
    ServerName www.zxtestivan.cf

Saving debug log to /var/log/letsencrypt/letsencrypt.log

Requesting a certificate for zxtestivan.cf

Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/zxtestivan.cf/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/zxtestivan.cf/privkey.pem

#################################################################################################################
 SSL entries for zxtestivan.cf added to configuration file. Previous configuration is copied on /opt/lampp/etc/httpd_backups/httpd_ssl.conf-2021-08-08-04-09-16 
#####################################################################################################################
Checking configuration file....

Syntax OK

###############################################
Domain name = zxtestivan.cf
Document root location = /opt/lampp/htdocs/zxtestivan.cf 
###############################################

```


If you like to run SSL installation seperately, then run hostssl.sh.

FTP details can be obtained from ftp_details file created after running the script.
