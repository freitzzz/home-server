# exposing

This folder contains processes and bash scripts I use to expose services I run in my home server in a secure manner. 

## Reverse Proxy (NGINX)

All services exposed to the Internet are behind a NGINX reverse proxy. Having this proxy allows me to encrypt communication between clients (people) and servers (my services) using HTTPS, and centralize logs about requests that each service receives.

The following diagram visually explains how a reverse proxy works and the reason why it is important:

![sequence digram explaining flow between clients, services and the reverse proxy](src/reverse-proxy-explained.svg)

## Port Forwarding (Router)

...