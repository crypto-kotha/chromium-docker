# Ubuntu Chromium & Nginx Setup for Headless

This script automates the setup of a **Chromium** container with **Nginx** reverse proxy on Ubuntu using **Docker** and **Docker Compose**. It also configures the **UFW firewall** to allow access from specific IP ranges and applies HTTP basic authentication for the Chromium instance.

### Docker Miniconda and others essential
```bash
wget https://raw.githubusercontent.com/crypto-kotha/ubuntu-setup/main/ubuntu_setup.sh && sudo chmod +x ubuntu_setup.sh && ./ubuntu_setup.sh
```
### Chromium and Nginx Setup
```bash
wget https://raw.githubusercontent.com/crypto-kotha/chromium-docker/main/chrome.sh && sudo chmod +x chrome.sh && ./chrome.sh
```

## Features

- Sets up **Chromium** and **Nginx** using Docker containers.
- Configures **Nginx** with basic authentication and IP-based access control.
- Configures the firewall using **UFW** to restrict access.
- Logs setup activities for traceability.
- Automatically pulls Docker images for **Chromium** and **Nginx**.
- Customizable username and password for the Chromium container.

## Requirements

- **Ubuntu** (or any Linux distribution with Docker support)
- **Docker** and **Docker Compose** installed.

If Docker and Docker Compose are not installed, the script will handle the setup process.

## Installation

To install and use this script, follow these steps:


