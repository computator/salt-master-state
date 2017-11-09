salt-minion:
  service.running:
    - init_delay: 2

salt-minion-hostname:
  file.managed:
    - name: /etc/salt/minion.d/99-master-address.conf
    - contents: 'master: {{ salt['pillar.get']('minion_hostname', 'localhost') }}'
    - watch_in:
      - service: salt-minion

salt-master-accept-minion:
  salt.wheel:
    - name: key.accept
    - match: {{ grains['id'] }}