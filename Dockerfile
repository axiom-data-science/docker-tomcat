FROM debian:stretch
MAINTAINER Kyle Wilcox <kyle@axiomdatascience.com>

ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update && \
    apt-get install -y \
        curl \
        gcc \
        libapr1 \
        libapr1-dev \
        libreadline-dev \
        libssl-dev \
        libterm-readline-gnu-perl \
        make \
        openssl \
        oracle-java8-installer \
        oracle-java8-set-default && \
    apt-get clean && \
    rm -rf /var/cache/oracle-jdk8-installer && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Tomcat keys - https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN \
    gpg --keyserver pool.sks-keyservers.net --recv-keys \
        05AB33110949707C93A279E3D3EFE6B686867BA6 \
        07E48665A34DCAFAE522E5E6266191C37C037D42 \
        47309207D818FFD8DCD3F83F1931D684307A10A5 \
        541FBE7D8F78B25E055DDEE13C370389288584E7 \
        61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
        79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
        9BA44C2621385CB966EBA586F72C284D731FABEE \
        A27677289986DB50844682F8ACB77FC2E86E29AC \
        A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
        DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
        F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
        F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

# Apache native libraries (apr)
ENV APACHE_NATIVE_VERSION 1.2.8
ENV APACHE_NATIVE_URL https://www.apache.org/dist/tomcat/tomcat-connectors/native/$APACHE_NATIVE_VERSION/source/tomcat-native-$APACHE_NATIVE_VERSION-src.tar.gz
RUN \
    curl -fSL "$APACHE_NATIVE_URL" -o native.tar.gz && \
    curl -fSL "$APACHE_NATIVE_URL.asc" -o native.tar.gz.asc && \
    gpg --verify native.tar.gz.asc && \
    tar zxf native.tar.gz -C /tmp && \
    cd /tmp/tomcat-native*-src/native/ && \
    ./configure \
        --with-apr=/usr/bin/apr-1-config \
        --with-java-home=/usr/lib/jvm/java-8-oracle \
        --with-ssl=yes \
        --libdir=/usr/lib/jni && \
    make && \
    make install && \
    apt-get purge -y \
        libssl-dev \
        libapr1-dev

# Tomcat
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.36
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

ENV CATALINA_HOME /opt/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

RUN \
    curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz && \
    curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc && \
    gpg --verify tomcat.tar.gz.asc && \
    tar -xvf tomcat.tar.gz --strip-components=1 && \
    rm bin/*.bat && \
    rm tomcat.tar.gz*

# Run Tomcat as the 'tomcat' user
RUN \
    groupadd -r tomcat -g 1000 && \
    useradd -u 1000 -r -g tomcat -d $CATALINA_HOME -s /bin/bash tomcat

# Tomcat user helpers
COPY files/.bash_profile $CATALINA_HOME/.bash_profile
COPY files/.bash_logout $CATALINA_HOME/.bash_logout

# Tomcat config
COPY files/setenv.sh $CATALINA_HOME/bin/setenv.sh
COPY files/javaopts.sh $CATALINA_HOME/bin/javaopts.sh
COPY files/server.xml $CATALINA_HOME/conf/server.xml
COPY files/tomcat-users.xml $CATALINA_HOME/conf/tomcat-users.xml

# Create a self-signed certificate for Tomcat to use
RUN \
    openssl req \
        -new \
        -newkey rsa:4096 \
        -days 3650 \
        -nodes \
        -x509 \
        -subj "/C=US/ST=Alaska/L=Anchorage/O=Axiom Data Science/CN=tomcat.example.com" \
        -keyout $CATALINA_HOME/conf/ssl.key \
        -out $CATALINA_HOME/conf/ssl.crt

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.9/gosu-$(dpkg --print-architecture)" && \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.9/gosu-$(dpkg --print-architecture).asc" && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

RUN chown -R tomcat:tomcat "$CATALINA_HOME"

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080 8443
CMD ["catalina.sh", "run"]
