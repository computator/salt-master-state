include:
  - salt-master
  - salt-master.sshpki
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

acl-utils:
  pkg.installed:
    - name: acl
    - require_in:
      - acl: salt-state-dir
      - acl: salt-pillar-dir

salt-state-dir:
  file.directory:
    - name: /srv/salt
    - group: salt
    - mode: 2775
    - require:
      - group: salt-group
  acl.present:
    - name: /srv/salt
    - acl_type: default:mask
    - perms: rwx
    - recurse: true
    - require:
      - file: salt-state-dir

salt-pillar-dir:
  file.directory:
    - name: /srv/pillar
    - group: salt
    - mode: 2770
    - require:
      - group: salt-group
  acl.present:
    - name: /srv/pillar
    - acl_type: default:mask
    - perms: rwx
    - recurse: true
    - require:
      - file: salt-state-dir

salt-state-tree:
  cmd.run:
    - name: hg init /srv/salt
    - creates: /srv/salt/.hg
    - require:
      - acl: salt-state-dir
      - pkg: mercurial
    - require_in:
      - hg: salt-state-tree
  file.append:
    - name: /srv/salt/.hg/hgrc
    - text: |
        [paths]
        default = git://github.com/rlifshay/salt-master.git
    - unless: hg config -R /srv/salt paths.default
    - require:
      - cmd: salt-state-tree
  hg.latest:
    - name: git://github.com/rlifshay/salt-master.git
    - target: /srv/salt
    - require:
      - acl: salt-state-dir
      - pkg: mercurial
      - file: mercurial-hggit-extension

salt-state-tree-subrepos:
  cmd.run:
    - name: rmap -r clone git://github.com/rlifshay/
    - onlyif: 'rmap -r root 2>&1 | grep -q "abort: repository .* not found!"'
    - cwd: /srv/salt
    - require:
      - hg: salt-state-tree
      - file: rmap
    - onchanges_in:
      - salt: salt-master-sshpki-config

salt-state-tree-hooks:
  file.append:
    - name: /srv/salt/.hg/hgrc
    - text: |
        [hooks]
        changegroup.update = $HG update
    - unless: hg config -R /srv/salt hooks.changegroup.update
    - require:
      - hg: salt-state-tree
  cmd.run:
    - name: for repo in $(rmap -r1 config hooks.changegroup.update | grep -vF '$HG update' | tr -d :); do echo -e '[hooks]\nchangegroup.update = $HG update\n' >> $repo/.hg/hgrc; done
    - onlyif: rmap -r1 config hooks.changegroup.update | grep -qvF '$HG update'
    - cwd: /srv/salt
    - require:
      - cmd: salt-state-tree-subrepos
      - file: rmap

extend:
  salt-sshpki:
    file.directory:
      - group: salt
      - mode: 2770
      - require:
        - group: salt-group
