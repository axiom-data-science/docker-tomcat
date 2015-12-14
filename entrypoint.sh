#!/bin/bash
set -e

if [ "$1" = 'catalina.sh' ]; then
	chown -R tomcat:tomcat .
	exec gosu tomcat "$@"
fi

exec "$@"
