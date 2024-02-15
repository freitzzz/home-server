# exposing

This folder contains processes and bash scripts I use to expose services I run in my home server in a secure manner. 

## Reverse Proxy (NGINX)

All services exposed to the Internet are behind a NGINX reverse proxy. Having this proxy allows me to encrypt communication between clients (people) and servers (my services) using HTTPS, and centralize logs about requests that each service receives.

The following diagram visually explains how a reverse proxy works and the reason why it is important:

![sequence digram explaining flow between clients, services and the reverse proxy](src/reverse-proxy-explained.svg)

## Port Forwarding (Router)

To expose a reverse proxy to the Internet, I have to configure my router to forward TCP packets it receives on a specific port (the port that will be exposed) to a port that is exposed in the internal network (port which the reverse proxy is available).

This configuration varies from router to router, but in my case the process is as follows:

1. Open router configuration web platform (`192.168.1.1`)
2. Authenticate
3. Click on settings icon
4. Navigate to Routing Rules > IPV4 Port Mapping
5. Click "New" and again "New"
6. Fill form
    1. Type: `Default`
    2. Application Name: `<service label>`
    3. WAN Name: `Internet`
    4. Internal Host: `<home server IP>`
    5. Protocol: `TCP`
    6. Internal Port: `<reverse proxy port> - <reverse proxy port>`
    7. External Port: `<exposed port> - <exposed port>`
7. Click "Apply"

## Domain Resolving (DNS)

To expose a service to the Internet a domain name is required for two reasons: TLS certificates and being able to access different services without recurring to multiple locations under the same host. For reference, I buy and manage my domains at [Porkbun](https://porkbun.com).

After acquiring a domain, you need to tell DNS servers to translate the domain to your home server public IP address. These are the steps to do it:

1. Grab the home server public IP address (`wget -qO- https://ifconfig.me`)
2. Enter the domain management portal of your domain
3. Add new record:
    1. Select `A` record (or `AAAA` if IPV6)
    2. Write the domain or subdomain to resolve the IP address
    3. Paste the public IP address
4. Save

You can confirm if DNS servers are resolving the public IP address with `dig` (it might take some minutes for all configurations to roll out):

```bash
dig <domain/subdomain> +short
```

## Certificates Generation (TLS)

Free TLS certificates can be acquired for free from [Let's Encrypt](https://letsencrypt.org/). To automate the process of generating one for the service to expose, the `certbot` is used (`sudo apt install certbot python3-certbot-nginx`).

The certbot tool has to complete a challenge with `Let's Encrypt` to prove that the requesting client owns the domain and is trustworthy, and for that a file must be exposed in the `.well-known` directory of NGINX default site (running on port **80**).

The process to generate a new certificate is as follows:

1. Add port forwarding rule on router for port **80** (connecting to port 80 of home server)
2. Run `sudo certbot --nginx -d <subdomain/domain>` (take about 15 seconds to finish)
3. Remove port forwarding rule

## Exposing a new Service (Manual)

Exposing a new service is a process that takes no more than 5 minutes, but requires prior decision on which domain/subdomain will be used to access the service:

1. Start the service and note the port it's exposed
2. Create a new NGINX site configuration for (`sudo cp /etc/nginx/conf.d/<existing_site>.conf /etc/nginx/conf.d/<subdomain>.<domain>.conf`)
3. Edit the newly created configuration file and add the following information:
    1. `server_name <subdomain/domain>;`
    2. `listen <exposing port> ssl;`
    3. `access_log /var/log/nginx/<subdomain/domain>.access.log customformat;`
    4. Now under `location /`
    ```nginx
        proxy_pass http://0.0.0.0:<service_port>;
	    proxy_set_header Host              $http_host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # http://nginx.org/en/docs/http/websocket.html
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_redirect off;
    ```
4. Save file
5. Generate TLS certificate following [steps mentioned above](#certificates-generation-tls)
