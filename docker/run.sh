#!/bin/bash
set -eo pipefail
export CONTEXT=$(basename -s .war $(ls webapps/*.war | head -n 1))
tomcat-users.pl ${CATALINA_HOME}/conf/tomcat-users.xml
context.pl ${CATALINA_HOME}/conf/Catalina/localhost/${CONTEXT}.xml
exec catalina.sh run
