#!/bin/sh

CATALINA_HOME="/opt/tomcat"
export CATALINA_HOME

CATALINA_BASE=$CATALINA_HOME
export CATALINA_BASE

JAVA_HOME="/usr/lib/jvm/java-8-oracle"
export JAVA_HOME

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jni
export LD_LIBRARY_PATH

. $CATALINA_HOME/bin/javaopts.sh
