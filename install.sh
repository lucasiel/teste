systemctl stop wings
rm /usr/local/bin/wings
curl -L -o /usr/local/bin/wings.gz https://github.com/lucasiel/teste/raw/main/wings.gz
tar -xvzf /usr/local/bin/wings.gz -C /usr/local/bin/
chmod u+x /usr/local/bin/wings
chmod 777 -R /dev/kvm
chmod 777 -R /dev/kvm/
systemctl start wings
