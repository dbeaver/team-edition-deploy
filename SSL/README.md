## SSL certificate configuration

The cluster supports HTTP and HTTPS. By default, it contains a pre-configured SSL certificate. You can change it to your own existing certificate associated with your domain, or configure an SSL certificate along with a new domain using the Team Edition Domain Manager.


### How to add certificate from your domain provider

**Native mode:**

1. Open your Team Edition instance.
2. If you are in the process of initial server configuration, navigate to **Domain manager** tab. If your Team Edition is already configured, navigate to **Settings -> Administration -> Domain Manager**.
3. Choose **Set up manually**.
4. The system will guide you in setting up certificates.
5. Ensure your domain is pointing to the server's IP address.

**Docker volumes mode:**

1. Connect to your server.
2. Copy the `fullchain.pem` and `privkey.pem` SSL certificates to the `/etc/nginx/ssl/live/databases.team` directory within the Nginx Docker container.
3. Open the `/etc/nginx/product-conf/cloudbeaver-te.conf` file inside the Nginx Docker container and set your domain name in the `server_name` variable.
4. Apply the new Nginx configurations by running `docker compose restart`.
5. Ensure your domain is pointing to the server's IP address.

Learn more in [Domain manager documentation](https://dbeaver.com/docs/cloudbeaver/Domain-Manager/)

### How to generate domain with Team Edition domain service

1. Open your Team Edition instance.
2. If you are in the process of initial server configuration, navigate to **Domain manager** tab. If your Team Edition is already configured, navigate to **Settings -> Administration -> Domain Manager**.
3. Choose **Generate automatically**.
4. The system will guide you through obtaining a domain and setting up certificates.
5. After receiving the domain and setting up the certificates, you will be automatically redirected to the new domain.

Learn more in [Domain manager documentation](https://dbeaver.com/docs/cloudbeaver/Domain-Manager/)
