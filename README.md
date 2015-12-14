# Tomcat on Docker

A feature full Tomcat (SSL over APR, etc.) running in Docker

Available versions:

* `axiom/docker-tomcat` (latest stable release)
* `axiom/docker-tomcat:8.0` (currently `8.0.30`)

### tl;dr

**Quickstart**

```bash
$ docker run \
    -d \
    -p 80:8080 \
    -p 443:8443 \
    axiom/docker-tomcat
```

**Production**


```bash
$ docker run \
    -d \
    -p 80:8080 \
    -p 443:8443 \
    -v /path/to/your/ssl.crt:/opt/tomcat/conf/ssl.crt \
    -v /path/to/your/ssl.key:/opt/tomcat/conf/ssl.key \
    -v /path/to/your/tomcat-users.xml:/opt/tomcat/conf/tomcat-users.xml \
    --name tomcat \
    axiom/docker-tomcat
```

## Configuration

### Ports

Tomcat runs with two ports open

* 8080 - HTTP
* 8443 - HTTPS

Map the ports to local ports to access outside of the Docker ecosystem:
```bash
$ docker run \
    -p 80:8080 \
    -p 443:8443 \
    ... \
    axiom/docker-tomcat
```

### JVM

By default, the JVM is run with the [following options](https://github.com/axiom-data-science/docker-tomcat/blob/master/files/javaopts.sh):

* `-server` - server optimized jvm
* `-d64` - 64-bit jvm
* `-Xms4G` - reserve 4g of RAM
* `-Xmx4G` - use a max of 4g of RAM
* `-XX:MaxPermSize=256m` - increase perm size
* `-XX:+HeapDumpOnOutOfMemoryError` -  nice log dumps on out of memory errors
* `-Djava.awt.headless=true` - headless (no monitor)

A custom JVM options file may be used but must `export JAVA_OPTS` at the end
and include any already defined `JAVA_OPTS`, like so:

```bash
#!/bin/sh
NORMAL="-server -d64 -Xms16G -Xmx16G"  # More memory
MAX_PERM_GEN="-XX:MaxPermSize=128m"    # Less Perm
HEADLESS="-Djava.awt.headless=true"    # Still headless
JAVA_OPTS="$JAVA_OPTS $NORMAL $MAX_PERM_GEN $HEADLESS"
export JAVA_OPTS
```

Mount your own `javaopts.sh`:

```bash
$ docker run \
    -v /path/to/your/javaopts.sh:/opt/tomcat/bin/javaopts.sh \
    ... \
    axiom/docker-tomcat
```

### Users

By default, Tomcat will start with a single `admin` [user account](https://github.com/axiom-data-science/docker-tomcat/blob/master/files/tomcat-users.xml). The password is equal to the user name.

**You need to mount your own `tomcat-users.xml` file with different SHA1 digested passwords**.
If not, anyone who reads this document and knows your server address will have admin Tomcat privileges.

Mount your own `tomcat-users.xml`:

```bash
$ docker run \
    -v /path/to/your/tomcat-users.xml:/opt/tomcat/conf/tomcat-users.xml \
    ... \
    axiom/docker-tomcat
```

### SSL

By default, Tomcat will start with a self-signed certificate valid for 3650 days.
This certificate **does not change on run**, so if you are serious about SSL, you
should mount your own private key and certificate files.

Mount your own `ssl.crt` and `ssl.key`:

```bash
$ docker run \
    -v /path/to/your/ssl.crt:/opt/tomcat/conf/ssl.crt \
    -v /path/to/your/ssl.key:/opt/tomcat/conf/ssl.key \
    ... \
    axiom/docker-tomcat
```

If you want to disable SSL altogether, you will need to mount a [custom](https://github.com/axiom-data-science/docker-tomcat/blob/master/files/server.xml) `setup.xml`:

```bash
$ docker run \
    -v /path/to/your/setup.xml:/opt/tomcat/conf/setup.xml \
    ... \
    axiom/docker-tomcat
```
