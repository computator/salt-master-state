include:
  - salt-master
  - mercurial
  - mercurial.hggit
  - mercurial.rmap

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

salt-state-tree-subrepos:
  cmd.run:
    - name: rmap -r clone git://github.com/rlifshay/
    - onlyif: 'rmap -r root 2>&1 | grep -q "abort: repository .* not found!"'
    - cwd: /srv/salt
    - require:
      - hg: salt-state-tree
      - file: rmap
  salt.runner:
    - name: saltutil.sync_all
    - onchanges:
      - cmd: salt-state-tree-subrepos

salt-state-tree-subrepos-hooks:
  cmd.run:
    - name: for repo in $(rmap -r1 config hooks.changegroup.update | grep -vF '$HG update' | tr -d :); do echo -e '[hooks]\nchangegroup.update = $HG update\n' >> $repo/.hg/hgrc; done
    - onlyif: rmap -r1 config hooks.changegroup.update | grep -qvF '$HG update'
    - cwd: /srv/salt
    - require:
      - cmd: salt-state-tree-subrepos
      - file: rmap

salt-master-sshpki-module:
  pkg.installed:
    - name: python-pip
    - unless: which pip
  pip.installed:
    - editable: /srv/salt/lib/sshpki_pillar/lib/sshpki
    - unless: pip list | grep -q sshpki
    - require:
      - pkg: python-pip
      - cmd: salt-state-tree-subrepos

salt-master-sshpki-config:
  file.managed:
    - name: /etc/salt/master.d/50-sshpki-ext-pillar.conf
    - contents: |
        ext_pillar:
          - sshpki_pillar:
              pki_root: /srv/sshpki
              ca_privkey: /srv/sshpki/ca_key
    - watch_in:
      - service: salt-master

salt-sshpki:
  file.directory:
    - name: /srv/sshpki
    - group: salt
    - mode: 2770
    - require:
      - group: salt-group
  cmd.run:
    - name: ssh-keygen -q -N '' -C "Salt SSHPKI CA Key" -f /srv/sshpki/ca_key
    - creates: /srv/sshpki/ca_key
    - require:
      - file: salt-sshpki
