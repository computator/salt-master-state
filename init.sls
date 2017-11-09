salt-minion:
  file.managed:
    - name: /etc/salt/minion.d/99-master-address.conf
    - contents: 'master: {{ salt['pillar.get']('minion_hostname', 'localhost') }}'
    - watch_in:
      - service: salt-minion
  service.running:
    - init_delay: 2
  salt.wheel:
    - name: key.accept
    - match: {{ grains['id'] }}
    - onlyif: salt-key -l un | grep -iFe '{{ grains['id'] }}'
    - require:
      - service: salt-minion