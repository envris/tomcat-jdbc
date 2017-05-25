FROM tomcat:8-jre8

# Copy tomcat manager application configuration
COPY docker/manager.xml conf/Catalina/localhost/

# Copy configuration and run scripts
COPY docker/run.sh bin/
COPY docker/*.pl /usr/local/bin/

CMD ["run.sh"]

# Copy JARs and WARs
ONBUILD COPY lib/*.jar lib/
ONBUILD ADD *.war webapps/