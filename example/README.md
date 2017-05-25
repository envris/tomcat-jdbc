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
```bash
 docker exec -it "example_app.1.$(docker se rvice ps example_app -q | head -n1)" bash
```

## Output
The automatically generated files can be found in the container, with the contents as below.

### Tomcat Users configuration
Path: `/usr/local/tomcat/conf/tomcat-users.xml`

```xml
```

### Web application context.xml
Path: `/usr/local/tomcat/conf/Catalina/localhost/oracle-webapp.war`

```xml
```
