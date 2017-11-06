#!/bin/bash
set -eo pipefail
export CONTEXT="$(basename $(ls webapps/*.war | head -n 1) .war)"

# Redirect root path to application path
echo "<% response.sendRedirect(\"/$CONTEXT\"); %>" \
	> ${CATALINA_HOME}/webapps/ROOT/index.jsp

tomcat-users.pl ${CATALINA_HOME}/conf/tomcat-users.xml
context.pl ${CATALINA_HOME}/conf/Catalina/localhost/${CONTEXT}.xml
exec catalina.sh run
