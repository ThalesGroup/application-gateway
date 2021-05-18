# **Overview**

The SafeNet Agent for Application Gateway provides a containerized secure web reverse proxy, adding authentication and authorization protection to your application using identity provider SafeNet Trusted Access (STA).

Please refer to STA documentation for more information about SafeNet Agent for Application Gateway.

# **Pre-Requisites**

Install Docker-Compose

- Run this command to download docker-compose

$ sudo curl -L&quot;https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)&quot;-o /usr/local/bin/docker-compose

- Apply executable permissions to the binary:

$ sudo chmod +x /usr/local/bin/docker-compose

- Test the installation.

$ docker-compose –version

# **Accessing the Image**

To load the image from Docker Hub the &#39;docker pull&#39; command should be used. The image name should be supplied with the pull command, along with a tag which corresponds to the image version number. For example:

docker pull thalesgroup/application-gateway:1.0.0

# **How to use this image**

**...via docker-compose.yml**

docker-compose.yml for application-gateway:

      version: "3.3"

      services:

        application-gateway:

          image: "thalesgroup/application-gateway:1.0.0"

          container_name: application-gateway

          ports:

            - "443:9443"

            - "8443:8443"

         environment:

            ADMIN_CONSOLE_USER: admin

            ADMIN_CONSOLE_PASSWORD: admin

         logging:

            driver: "json-file"

            options:

              max-file: "5"

              max-size: "50m"

        restart: always

The following environment variables are used for configuring login credentials for application-gateway Admin Console

- ADMIN_CONSOLE_USER=... (defaults to "admin")
- ADMIN_CONSOLE_PASSWORD=... (defaults to "admin")

The default port mapping are as-

- 443:9443= serves requests from users and proxies the connection to internal services.
- 8443:8443= for configuring application-gateway(used for administrative purposes). Port 8443 should not be publicly exposed and restrict traffic to authorized networks only.
Or to allow access of Application Gateway admin console only from local server, map external port number with localhost
like : 127.0.0.1:8443:8443

# **Examine the log file of the container.**

docker logs -f application-gateway

# **Documentation**

The official documentation of the SafeNet Agent for Application Gateway is available at SafeNet Trusted Access (STA).

This image is officially supported on Docker version v18.04 (or above).
