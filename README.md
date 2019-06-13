## Instalacija potrebnih alata

Prvi korak predstavlja minimalna instalacija za CentOS 7. Podrazumeva se da je 
mreža konfigurisana na odgovarajući način.


### Instalacija wget, curl i git
Instalirati `wget`, `curl` i `git` pomoću
```
yum -y install wget curl git
```

### Instalacija Java

Instalirati Javu pomoću:
```
yum install java-1.8.0-openjdk-devel
```

Proveriti instalaciju pomoću:
```
java -version
```

### Instalacija Maven

```
cd /usr/local
wget https://www-us.apache.org/dist/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz
tar xzf apache-maven-3.6.0-bin.tar.gz
ln -s apache-maven-3.6.0 maven
```

Dodati fajl `/etc/profile.d/maven.sh`:
```
#!/bin/bash
export M2_HOME=/usr/local/maven
export PATH=${M2_HOME}/bin:${PATH}
```

I na kraju
```
chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
```

Proveriti instalaciju:
```
mvn -version
```

[info](https://tecadmin.net/install-apache-maven-on-centos/#)

### Instalacija ant
```
cd /usr/local
wget https://www-us.apache.org/dist//ant/binaries/apache-ant-1.10.5-bin.tar.gz
tar xzf apache-ant-1.10.5-bin.tar.gz
ln -s apache-ant-1.10.5 ant
```

Dodati fajl `/etc/profile.d/ant.sh`:
```
#!/bin/bash
export ANT_HOME=/usr/local/ant
export PATH=$ANT_HOME/bin:$PATH
```

I na kraju:
```
chmod +x /etc/profile.d/ant.sh
source /etc/profile.d/ant.sh
```

Proveriti instalaciju:
```
ant -version
```

### Instalacija Apache Tomcat
```
cd /opt
wget https://www-us.apache.org/dist/tomcat/tomcat-8/v8.5.38/bin/apache-tomcat-8.5.38.tar.gz
tar zxvf apache-tomcat-8.5.38.tar.gz
ln -s apache-tomcat-8.5.38 tomcat
rm -f apache-tomcat-8.5.38.tar.gz
```

Dodati fajl `/etc/systemd/system/tomcat.service`:
```
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx2048M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Dfile.encoding=UTF-8 -Dorg.apache.el.parser.SKIP_IDENTIFIER_CHECK=true'

ExecStart=/opt/tomcat/bin/catalina.sh start
ExecStop=/opt/tomcat/bin/catalina.sh stop

User=root
Group=root

[Install]
WantedBy=multi-user.target
```

Izmeniti element `Connector` u fajlu `/opt/tomcat/conf/server.xml`:
```
<Connector port="80" protocol="HTTP/1.1"
           maxThreads="150"
           minSpareThreads="25"
           maxSpareThreads="75"
           enableLookups="false"
           acceptCount="100"
           disableUploadTimeout="true"
           URIEncoding="UTF-8"
           connectionTimeout="20000"
           redirectPort="8443" />
```

Pokrenuti Apache Tomcat:
```
systemctl start tomcat
```
Proveriti status:
```
systemctl status tomcat
```
Ako je sve u redu, registrovati servis za Apache Tomcat:
```
systemctl enable tomcat
```
Otvaranje porta 80:
```
firewall-cmd --zone=public --add-port=80/tcp --permanent
```
Ponovno pokretanje firewall servisa:
```
firewall-cmd --reload
```


## Instalacija PostgreSQL 9.6

### Instalacija EPEL repozitorijuma

```
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

[info](https://fedoraproject.org/wiki/EPEL)

### Instalacija PostgreSQL

Instalirati PostgreSQL yum repozitorijum:
```
yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
```

Zatim instalirati PostgreSQL 9.6:
```
yum install postgresql96-server postgresql96-contrib
```

Inicijalizovati bazu:
```
/usr/pgsql-9.6/bin/postgresql96-setup initdb
```

Pokrenuti server:
```
systemctl enable postgresql-9.6
systemctl start postgresql-9.6
```

Promeniti lozinku za `postgres` korisnika u bazi:
```
su - postgres
psql -d template1 -c "ALTER USER postgres WITH PASSWORD 'newpassword';"
```

[info](https://www.linode.com/docs/databases/postgresql/how-to-install-postgresql-relational-databases-on-centos-7)

Podesiti fajl `/var/lib/pgsql/9.6/data/pg_hba.conf` tako da u njemu dva
reda za autentifikaciju glase:
```
local  all   all                             md5
host   all   all     127.0.0.1/32            md5
```
čime se uključuje autentifikacija pomoću lozinke. Restartovati server:
```
systemctl restart postresql-9.6
```

[info](https://stackoverflow.com/questions/18664074/getting-error-peer-authentication-failed-for-user-postgres-when-trying-to-ge)

## Instalacija DSpace-CRIS

### Kreiranje baze podataka

Potrebno je kreirati korisnika `dspace` sa lozinkom `dspace`:
```
su - postgres
createuser -U postgres -d -A -P dspace
```
A zatim kreirati i bazu podataka sa nazivom `dspace`:
```
createdb -U dspace -E UNICODE dspace
```

### Preuzimanje izvornog koda

```
mkdir /opt/crisinstallation
cd /opt/crisinstallation
git clone  http://tiaclab.com:9001/BE-OPEN.git --branch master dspace-parent/
```

### Početna konfiguracija

Potrebno je podesiti parametre u fajlu `/opt/crisinstallation/dspace-parent/build.properties`:

```
dspace.install.dir=/dspace
dspace.hostname = localhost
dspace.baseUrl = http://localhost:8080
dspace.ui = jspui
dspace.url = ${dspace.baseUrl}
solr.server = http://localhost:8080/solr
```
Ostali parametri:
```
dspace.name = DSpace-CRIS at University of Novi Sad
mail.server = smtp.uns.ac.rs
mail.server.username=dspace
mail.server.password=*****
handle.canonical.prefix = ${dspace.url}/handle/
cris.ametrics.elsevier.scopus.enabled = true
cris.ametrics.elsevier.scopus.apikey = ****
cris.ametrics.google.scholar.enabled = true
cris.ametrics.altmetric.enabled = true
jspui.google.analytics.key	= ****
submission.lookup.scopus.apikey = ****
submission.lookup.webofknowledge.ip.authentication = true
scopus.query.param.default=affilorg("University of Novi Sad")
key.googleapi.maps = ****
cookies.policy.enabled = false
```

### Pokretanje mavena

```
mkdir /dspace
cd /opt/crisinstallation/dspace-parent/
mvn package
```

### Pokretanje anta

```
cd /opt/crisinstallation/dspace-parent/dspace/target/dspace-installer/
ant fresh_install
```

### Inicijalizacija baze
```
/dspace/bin/dspace database clean
/dspace/bin/dspace database migrate
/dspace/bin/dspace create-administrator
/dspace/bin/dspace load-cris-configuration -f /opt/crisinstallation/dspace-parent/install-tools/cris-configuration.xls
/dspace/bin/dspace load-cris-configuration -f /opt/crisinstallation/dspace-parent/install-tools/cris-configuration.xls
```

### Kopiranje webapp fajlova

Minimalno su potrebne `jspui` i `solr` aplikacije a po potrebi se mogu kopirati i druge.

```
systemctl stop tomcat
cd /dspace/webapps
cp -R jspui/ oai/ rdf/ rest/ solr/ sword/ swordv2/ /opt/tomcat/webapps
```

Aplikaciju `jspui` je potrebno preimenovati u `ROOT`.
```
cd /opt/tomcat/webapps
rm -rf ROOT
mv jspui/ ROOT
```

### Pokretanje

Pokrenuti Tomcat.
```
systemctl start tomcat
```

### Provera u browseru

Proveriti da li je pokrenut DSpace-CRIS: [http://localhost:8080/](https://localhost:8080/)

---
Uputstvo preuzeto i prilagodjeno sa [https://github.com/mbranko/dspacecris-setup](https://github.com/mbranko/dspacecris-setup)
