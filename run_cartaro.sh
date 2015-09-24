service postgresql start
service tomcat7 start
service apache2 start
echo "Cartaro Demo is up and running."
tail -f /var/log/apache2/access.log
