include:
  - salt-master

{% set salt_admins = salt['pillar.get']('salt_admins', []) %}

salt-group:
  group.present:
    - name: salt
    - system: true
    {% if salt_admins %}
    - addusers:
      {% for user in salt_admins %}
      - {{ user }}
      {% endfor %}
    {% endif %}

salt-state-dir:
  file.directory:
    - name: /srv/salt
    - group: salt
    - mode: 2775
    - require:
      - group: salt-group

salt-pillar-dir:
  file.directory:
    - name: /srv/pillar
    - group: salt
    - mode: 2770
    - require:
      - group: salt-group
