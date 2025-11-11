FROM python:3.12-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=ansible
ARG UID=1000
ARG GID=1000

# OS deps + SSH client/server + useful net tools
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-client openssh-server ca-certificates tini git bash \
      less iproute2 net-tools dnsutils iputils-ping nano rsync sshpass \
  && rm -rf /var/lib/apt/lists/*

# Create user and set passwords (DEV ONLY)
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
    echo "ansible:ansible" | chpasswd && \
    echo "root:ansible"    | chpasswd

# Work dirs
RUN mkdir -p /work /ssh /run/sshd && chown -R ${USER}:${USER} /work /ssh

# --- Ansible -----------------------------------------------------------------
# ansible-core provides ansible-galaxy (enough for collections)
RUN pip install --no-cache-dir \
      "ansible-core>=2.16" \
      docker \
      jmespath \
      requests

# Install collections used by your playbooks
#   - community.docker: manage/query Docker
#   - community.general: lots of general modules/filters
#   - ansible.posix: posix/cron/acl modules
#   - containers.podman: (optional) podman support
#   - ansible.utils: useful filters/validators
RUN ansible-galaxy collection install \
      community.docker \
      community.general \
      ansible.posix \
      containers.podman \
      ansible.utils \
    --collections-path /usr/share/ansible/collections
ENV ANSIBLE_COLLECTIONS_PATHS=/usr/share/ansible/collections

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

WORKDIR /work
EXPOSE 22
ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
