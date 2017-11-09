include:
  - salt-master
  - mercurial
  - mercurial.hggit

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

salt-state-tree:
  cmd.run:
    - name: hg init /srv/salt
    - creates: /srv/salt/.hg
    - require:
      - file: salt-state-dir
      - pkg: mercurial
    - require_in:
      - hg: salt-state-tree
  hg.latest:
    - name: git://github.com/rlifshay/salt-master.git
    - target: /srv/salt
    - opts: --config extensions.hggit=
    - require:
      - file: salt-state-dir
      - pkg: mercurial
      - pip: mercurial-hggit-extension
  file.append:
    - name: /srv/salt/.hg/hgrc
    - text: |
        [hooks]
        changegroup.update = $HG update
    - unless: hg config -R /srv/salt hooks.changegroup.update
    - require:
      - hg: salt-state-tree