salt-minion:
  service.running:
    - name: salt-minion
    - init_delay: 2

salt-minion-hostname:
  file.replace:
    - name: /etc/salt/minion
    - pattern: '^#?master:.*'
    - repl: 'master: {{ salt['pillar.get']('minion_hostname', '127.0.0.1') }}'
    - append_if_not_found: true
    - watch_in:
      - service: salt-minion

salt-master-accept-minion:
  module.wait:
    - name: saltutil.wheel
    - _fun: key.accept
    - args:
      - {{ grains['id'] }}
    - watch:
      - file: salt-minion-hostname