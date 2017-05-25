FROM envris/tomcat-jdbc:8-jre8

# Modify run.sh to do everything except start Tomcat.
# Don't include any of this for a production application.
RUN head -n -1 bin/run.sh > bin/example-run.sh && \
    echo '/usr/bin/tail -f /dev/null' >> bin/example-run.sh && \
    chmod +x bin/example-run.sh
CMD ["example-run.sh"]
