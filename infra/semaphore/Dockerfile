ARG SEMAPHORE_BASE_IMAGE=semaphoreui/semaphore:v2.17.37-ansible2.16.5
FROM ${SEMAPHORE_BASE_IMAGE}

USER root

RUN /opt/semaphore/apps/ansible/9.4.0/venv/bin/pip install --no-cache-dir --upgrade 'ansible==10.*'
RUN /opt/semaphore/apps/ansible/9.4.0/venv/bin/pip install --no-cache-dir 'netaddr'

RUN /opt/semaphore/apps/ansible/9.4.0/venv/bin/ansible-playbook --version | sed -n '1p' | grep -E '^ansible-playbook \[core 2\.17\.'

USER semaphore
