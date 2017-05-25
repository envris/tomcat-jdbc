FROM tomcat:7-jre8

# Copy jars
COPY lib/*.jar lib/

# Copy application
ONBUILD ADD *.war webapps/

# Configure tomcat manager application
COPY docker/manager.xml conf/Catalina/localhost/

# Copy configuration and run scripts
COPY docker/* bin/

CMD ["run.sh"]
