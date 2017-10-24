Docker base images for Tomcat applications which use JDBC database connections. Alpine versions are less than half the size of standard images but have virtually no packages installed and use busybox instead of bash. 

## Supported tags and respective `Dockerfile` links
* `7-jre7` ([7-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/7-jre7.Dockerfile))
* `7-jre7-alpine` ([7-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/alpine/7-jre7-alpine.Dockerfile))
* `7-jre8` ([7-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/7-jre8.Dockerfile))
* `7-jre8-alpine` ([7-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/-alpine/7-jre8-alpine.Dockerfile))
* `8-jre7` ([8-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/8-jre7.Dockerfile))
* `8-jre7-alpine` ([8-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/-alpine/8-jre7-alpine.Dockerfile))
* `8-jre8` ([8-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/8-jre8.Dockerfile))
* `8-jre8-alpine` ([8-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/-alpine/8-jre8-alpine.Dockerfile))

## Build
```bash
for file in *.Dockerfile; do
    tag=$(basename $file ".Dockerfile")
    docker build -t "envris/tomcat-jdbc:${tag}" --file $file .
done
```

## Usage
Use `envris/tomcat-jdbc` as the base image for your application's image.

Place your Tomcat web application WAR file in the context directory, and any JDBC driver JAR files in the lib subdirectory. Docker onbuild instructions will add these files for you.

Example Dockerfile:
```dockerfile
FROM envris/tomcat-jdbc:8-jre7
```

### Configuration
To configure each JDBC resource, set the below environment variables and secrets, replacing `MYRESOURCE` with an identifier for that JDBC resource.
Multiple JDBC resources can be defined.

For each JDBC resource, you must specify `RESOURCE` and either `URL` _or_ `HOST`, `PORT`, `NAME` and (optionally) `DRIVER`.

| Name | Type | Value | Default value |
|------|------|-------|---------------|
| `MYRESOURCE_RESOURCE` | Environment Variable | Name of the JDBC Resource | N/A |
| `MYRESOURCE_USER` | Environment Variable | DB username | N/A |
| `MYRESOURCE_URL` | Environment Variable | JDBC URL | N/A |
| `MYRESOURCE_DRIVER` | Environment Variable | DB JDBC Driver | oraclethin |
| `MYRESOURCE_HOST` | Environment Variable | DB hostname | N/A |
| `MYRESOURCE_PORT` | Environment Variable | DB tcp port | N/A |
| `MYRESOURCE_NAME` | Environment Variable | DB instance name | N/A |
| `myresource_pass` | Docker secret | DB password | N/A |
| `MYRESOURCE_MAXACTIVE` | Environment Variable | maxActive Attribute | 10 |
| `MYRESOURCE_MAXIDLE` | Environment Variable | maxIdle Attribute | 2 |
| `MYRESOURCE_MAXWAIT` | Environment Variable | maxWait Attribute | 2000 |

To configure Parameters, set the below environment variables for each Parameter, replacing `MYPARAM` with an identifier.

| Name | Value | Mandatory |
|------|-------|-----------|
| `PARAM_MYPARAM_NAME` | Parameter name | Yes |
| `PARAM_MYPARAM_VALUE` | Parameter value | Yes |
| `PARAM_MYPARAM_DESCRIPTION` | Parameter description | No |
| `PARAM_MYPARAM_NAME` | Parameter name | No |

To configure the Tomcat Manger application, set the below environment variables and secrets.
Omitting the `TOMCAT_ADMIN` environment variable will disable the admin user.

| Name | Type | Value |
|------|------|-------|
| `TOMCAT_ADMIN` | Environment Variable | Tomcat manager username |
| `tomcat_pass` | Docker secret | Tomcat manager password |

## Copyright
Copyright 2017 Australian Government Department of the Environment and Energy  
<devops@ris.environment.gov.au>

tomcat-jdbc is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

tomcat-jdbc is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with tomcat-jdbc.  If not, see <http://www.gnu.org/licenses/>.
