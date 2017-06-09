Example Tomcat application using `envris/tomcat-jdbc`.

Dummy files show where a JDBC driver JAR and the Webapp WAR files should be placed.

## Usage
Build the image:
```bash
docker build -t my-oracle-webapp:latest .
```

Run the container as a Docker service:
```bash
docker stack deploy -c docker-compose.yml example
```

## Output
The automatically generated files can be found in the container, with the contents as below.

### Tomcat Users configuration
Path: `/usr/local/tomcat/conf/tomcat-users.xml`

```bash
 docker exec -it "example_app.1.$(docker service ps example_app -q | head -n1)" cat conf/tomcat-users.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="admin-gui"/>
    <role rolename="manager-gui"/>
    <user username="tomcat" password="T0mc4t" roles="admin-gui,manager-gui"/>
</tomcat-users>
```

### Web application context.xml
Path: `/usr/local/tomcat/conf/Catalina/localhost/oracle-webapp.xml`

```bash
docker exec -it $(docker ps --filter="name=example_app" --format "{{.Names}}") cat conf/Catalina/localhost/oracle-webapp.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/oracle-webapp">
    <Resource name="jdbc/MYDB"
        auth="Container"
        type="javax.sql.DataSource"
        maxActive="5000"
        maxIdle="2"
        maxWait="2000"
        username="DB-Admin"
        password="P@ssw0rd1"
        driverClassName="oracle.jdbc.driver.OracleDriver"
        url="jdbc:oracle:thin:database.example.com:1521:MYDB"
        validationQuery="select 1 from dual"
    />
</Context>
```
