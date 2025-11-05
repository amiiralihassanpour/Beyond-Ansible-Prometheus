FROM python:3.12-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=ansible
ARG UID=1000
ARG GID=1000

# OS deps + SSH client/server + useful net tools
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-client openssh-server ca-certificates tini git bash \
      less iproute2 net-tools dnsutils iputils-ping nano \
  && rm -rf /var/lib/apt/lists/*

# Create user and set passwords (DEV ONLY)
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
    echo "ansible:ansible" | chpasswd && \
    echo "root:ansible"    | chpasswd

# Work dirs
RUN mkdir -p /work /ssh /run/sshd && chown -R ${USER}:${USER} /work /ssh

# Ansible
RUN pip install --no-cache-dir ansible-core

# Install ansible.posix collection
RUN ansible-galaxy collection install ansible.posix -p /usr/share/ansible/collections
RUN apt-get update && apt-get install -y --no-install-recommends rsync && rm -rf /var/lib/apt/lists/*



# SSHD config: allow root & password auth (DEV ONLY)
RUN sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveCountMax 3'  >> /etc/ssh/sshd_config

# Helpful pager for ansible-doc
ENV ANSIBLE_PAGER=cat
ENV SSH_DIR=/ssh
ENV ANSIBLE_CONFIG=/work/ansible.cfg

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


WORKDIR /work
EXPOSE 22
ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
