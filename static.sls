{% set config_dir = salt['environ.get']('CONFIG_DIR', '/tmp') %}

salt-master-state-tree:
  module.run:
    - name: file.copy
    - src: {{ config_dir }}/salt
    - dst: /srv/salt
    - recurse: true
    - onlyif:
      - test -d "{{ config_dir }}/salt"
      - test ! -d /srv/salt || test -z "$(ls -A /srv/salt)"

salt-master-pillar-tree:
  module.run:
    - name: file.copy
    - src: {{ config_dir }}/pillar
    - dst: /srv/pillar
    - recurse: true
    - onlyif:
      - test -d "{{ config_dir }}/pillar"
      - test ! -d /srv/pillar || test -z "$(ls -A /srv/pillar)"
