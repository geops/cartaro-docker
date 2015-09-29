FROM ubuntu:14.04

RUN echo 'deb http://apt.geops.de trusty main' >> /etc/apt/sources.list
RUN apt-key adv --keyserver hkp://keys.gnupg.net --recv-keys B6AA9BC9E7BDBF3D

# Install packaged dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    php5 \
    php5-curl \
    php5-gd \
    php5-gdal \
    php5-pgsql \
    postgresql \
    postgresql-9.3-postgis-2.1 \
    postgresql-contrib \
    tomcat7 \
    unzip \
    wget

RUN php5enmod -s ALL gdal

# Download and install Geoserver
RUN wget -q http://sourceforge.net/projects/geoserver/files/GeoServer/2.7.2/geoserver-2.7.2-war.zip \
    && unzip geoserver-2.7.2-war.zip \
    && cp geoserver.war /var/lib/tomcat7/webapps \
    && echo 'JAVA_OPTS="$JAVA_OPTS -DENABLE_JSONP=true -XX:MaxPermSize=128m"' >> /etc/default/tomcat7

# Download drush and patch it to not drop existing tables
RUN wget -q http://ftp.drupal.org/files/projects/drush-7.x-5.4.tar.gz \
    && tar xzf drush-7.x-5.4.tar.gz \
    && sed -ri "s/'DROP TABLE '/'-- DROP TABLE '/g" drush/commands/sql/sql.drush.inc

# Configure PostgreSQL
RUN service postgresql start \
    && sudo -u postgres psql -c "create role cartaro with login password 'cartaro';" \
    && sudo -u postgres createdb -O cartaro -T template0 -E UTF-8 cartaro \
    && sudo -u postgres psql cartaro -c "create extension postgis;" \
    && sudo -u postgres psql cartaro -c "grant all on geometry_columns to cartaro; grant all on spatial_ref_sys to cartaro;"

# Configure Apache
COPY cartaro.conf /etc/apache2/sites-available/cartaro.conf
RUN a2enmod rewrite && a2enmod proxy && a2enmod proxy_http && a2dissite 000-default && a2ensite cartaro

# Download and install Cartaro
RUN wget -q http://ftp.drupal.org/files/projects/cartaro-7.x-1.8-core.tar.gz \
    && tar xzf cartaro-7.x-1.8-core.tar.gz \
    && mv cartaro-7.x-1.8 cartaro \
    && cd cartaro \
    && service postgresql start \
    && service tomcat7 start || /bin/true \
    && service apache2 restart \
    && PGPASSWORD=cartaro php -d sendmail_path=/bin/true /drush/drush.php site-install cartaro \
       install_configure_form.cartaro_demo=1 \
       install_configure_form.geoserver_workspace=cartaro \
       install_configure_form.geoserver_namespace=cartaro \
       install_configure_form.geoserver_url=http://localhost:8080/geoserver \
       --account-name=admin \
       --account-pass=geoserver \
       --site-name="Cartaro Demo" \
       --db-url=pgsql://cartaro:cartaro@localhost:5432/cartaro \
       --clean-url=1 \
       --yes \
    && chown -R www-data.www-data /cartaro/sites/default/files \
    && ln -s /cartaro /var/www/cartaro \
    && service apache2 restart \
    && php -d sendmail_path=/bin/true /drush/drush.php vset geoserver_url http://localhost:8000/geoserver

COPY run_cartaro.sh /run_cartaro.sh
CMD ./run_cartaro.sh
