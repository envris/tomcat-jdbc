#!/bin/bash
set -eo pipefail
export CONTEXT=$(basename -s .war $(ls webapps/*.war | head -n 1))
perl tomcat-users.pl ${CATALINA_HOME}/conf/tomcat-users.xml
perl context.pl ${CATALINA_HOME}/conf/Catalina/localhost/${CONTEXT}.xml
exec catalina.sh run
