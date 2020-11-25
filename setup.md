# Install the Database

Its recommended to install the database on a virtual server or as docker-image. 

Within a virtual machine, the server may be run as normal user.

First, check the presence of Java
```
> java --version
  java 12.0.2 2019-07-16

```

To install in an unix environment, download the binary from https://orientdb.org/download
and copy the archive-file to the appropriate destination or

```
 wget https://s3.us-east-2.amazonaws.com/orientdb3/releases/3.1.4/orientdb-3.1.4.tar.gz

```

unzip there, create a link and run `server.sh`

```
 tar -zxvf orientdb-community-3.1.0-beta1.tar.gz
 ln -s  orientdb-3.1.4  orientdb
 cd orientdb/bin
 ./server.sh

 # ...
+---------------------------------------------------------------+
|                WARNING: FIRST RUN CONFIGURATION               |
+---------------------------------------------------------------+
| This is the first time the server is running. Please type a   |
| password of your choice for the 'root' user or leave it blank |
| to auto-generate it.                                          |
|                                                               |
| To avoid this message set the environment variable or JVM     |
| setting ORIENTDB_ROOT_PASSWORD to the root password to use.   |
+---------------------------------------------------------------+

Root password [BLANK=auto generate it]: ***********
Please confirm the root password: ***********

```

Finally install it as service. Edit `bin/orientdb.sh` and follow the instructions there
and copy the modified script to  `/etc/init.d`
```
sudo cp  orientdb.sh /etc/init.d/orientdb

```

Finally start the service through `service orientdb start`

On _systemd-Systems `systemctl` is used to manage services as the OrientDB-Database-Server.

The `orientdb.service`-file is placed in the bin directory. To install copy the orientdb.service
to /etc/systemd/  and Edit the file. 

To start, run
```
systemctl start orientdb.service

systemctl enable  orientdb.service  #  starts the database.server during boot.
```

### New User

To introduce a new user, just edit `config/orientdb-server-config.xml` and add

```
 <user resources="*" password="hc" name="hctw"/>

```
to  the `<users>` section. Then the User `hctw` has access to anything. 







