# cartaro-docker
Dockerfile for Cartaro Docker container hosted on DockerHub: https://hub.docker.com/r/geops/cartaro/

In order to use the Cartaro Docker container, you can either create your own image based on the Dockerfile or simply use the image hosted on DockerHub

See http://www.cartaro.org for more information about Cartaro

Please note: This container is not ready for usage on production systems! 

# DockerHub Image usage

This image contains a complete Cartaro Installation, including Apache, Geoserver, PostgreSQL+PostGIS.

For the full documentation, see: http://cartaro.org/documentation/using-demo-docker-container.

## Command Reference

### Quickstart

Download the image:

    $ sudo docker pull geops/cartaro

Start the container:

    $ sudo docker run -p 8000:80  geops/cartaro

You can access Cartaro at http://localhost:8000/ (username "admin", password "geoserver").

### Persistent storage

Create a data container:

    $ sudo docker run --name cartaro-data geops/cartaro /bin/echo "Data container for cartaro"

Start Cartaro with the volumes from the data container:

    $ sudo docker run --volumes-from cartaro-data -p 8000:80 geops/cartaro

