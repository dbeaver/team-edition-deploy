## SSL certificate configuration

The cluster supports HTTP and HTTPS. By default, it contains a pre-configured SSL certificate. You can change it to your own existing certificate associated with your domain, or configure an SSL certificate along with a new domain using the Team Edition Domain Manager.

## Using Domain manager

### Generate certificate

1. Open your Team Edition instance.
2. If you are in the process of initial server configuration, navigate to **Domain manager** tab. If your Team Edition is already configured, navigate to **Settings -> Administration -> Domain Manager**.
3. Choose **Generate automatically**.
4. The system will guide you through obtaining a domain and setting up certificates.
5. After receiving the domain and setting up the certificates, you will be automatically redirected to the new domain.

### Add custom certificate

1. Open your Team Edition instance.
2. If you are in the process of initial server configuration, navigate to **Domain manager** tab. If your Team Edition is already configured, navigate to **Settings -> Administration -> Domain Manager**.
3. Choose **Set up manually**.
4. The system will guide you in setting up certificates.
5. Ensure your domain is pointing to the server's IP address.

Learn more in [Domain manager documentation](https://dbeaver.com/docs/cloudbeaver/Domain-Manager/)