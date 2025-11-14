# Prometheus Configuration with Ansible (Dev Environment)

This repository contains an **Ansible-based development environment** for automating the installation and configuration of **Prometheus** — the leading open-source monitoring and alerting toolkit.  
The setup runs inside a **containerized dev environment** using a Dockerfile and a startup script to bootstrap SSH access and testing.


## Dev 

This repository provides a containerized development environment for working with Ansible using Docker. The container setup includes Ansible installation and SSH access, allowing you to develop and test Ansible playbooks in an isolated environment.

### Prerequisites
- Docker installed on your machine.

## Building the Image
Build the Docker image using the following command:
```bash
docker build -t ansible-box --progress=plain .
```

## Runnig a Container
```bash
docker run -d -p 2222:22 \
  -v ${PWD}:/work \
  -v ansible_ssh_key:/ssh \
  --name ansible-dev \
  ansible-box
```

## Connecting to the Container Through SSH
```bash
ssh -p 2222 root@localhost
# Pass: ansible
```

**ssh-key will be generate automatically in this directory: /ssh/**

**working directory is: /work/**

**Note: In my managed node I have this directory -> /home/prometheus**

## prometheus exportes
Prometheus exporters are lightweight programs (or built-in modules) that collect metrics from a system, service, or hardware and expose them in a format that Prometheus can scrape.

Think of exporters as metric translators:

They take internal metrics from a system → convert them → expose them on an HTTP endpoint like `/metrics`.
Prometheus then scrapes that endpoint and stores the metrics in its time-series database.

### Why do we need exportes
Because most applications, databases, or OS components don’t speak Prometheus format natively.
Exporters solve this by making almost anything “observable” by Prometheus.