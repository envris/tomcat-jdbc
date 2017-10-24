#!/bin/bash
set -eo pipefail
export CONTEXT="$(basename $(ls webapps/*.war | head -n 1) .war)"
tomcat-users.pl ${CATALINA_HOME}/conf/tomcat-users.xml
context.pl ${CATALINA_HOME}/conf/Catalina/localhost/${CONTEXT}.xml
exec catalina.sh run
