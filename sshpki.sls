include:
  - salt-master

salt-sshpki:
  file.directory:
    - name: /srv/sshpki
  cmd.run:
    - name: ssh-keygen -q -N '' -C "Salt SSHPKI CA Key" -f /srv/sshpki/ca_key
    - creates: /srv/sshpki/ca_key
    - require:
      - file: salt-sshpki

salt-master-sshpki-config:
  salt.runner:
    - name: saltutil.sync_all
  file.managed:
    - name: /etc/salt/master.d/50-sshpki-ext-pillar.conf
    - contents: |
        ext_pillar:
          - sshpki_pillar:
              pki_root: /srv/sshpki
              ca_privkey: /srv/sshpki/ca_key

        reactor:
          - 'salt/minion/*/start':
            - salt://_reactors/sshpki-pull-keys.sls

        schedule:
          sshpki-pull-keys:
            function: sshpki.pull_pubkeys
            days: 1
            args:
              - '*'
    - makedirs: true
    - require:
      - cmd: salt-sshpki
      - salt: salt-master-sshpki-config
    - watch_in:
      - service: salt-master
