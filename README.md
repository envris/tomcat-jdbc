Base images for Tomcat applications which use JDBC database connections.

## Supported tags and respective `Dockerfile` links
* `7-jre7` ([7-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/7-jre7.Dockerfile))
* `7-jre8` ([7-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/7-jre8.Dockerfile))
* `8-jre7` ([8-jre7.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/8-jre7.Dockerfile))
* `8-jre8` ([8-jre8.Dockerfile](http://github.com/envris/tomcat-jdbc/blob/master/8-jre8.Dockerfile))

## Usage
Use `envris/tomcat-jdbc` as the base image for your application's image.

Place your Tomcat web application WAR file in the context directory, and any JDBC driver JAR files in the lib subdirectory. Docker onbuild instructions will add these files for you.

Example Dockerfile:
```dockerfile
FROM envris/tomcat-jdbc:8-jre7
```

### Configuration
To configure each JDBC resource, set the below environment variables and secrets, replacing RESOURCE with the JDBC resource name.
Multiple JDBC resources can be defined.

| Name | Type | Value |
|------|------|-------|
| `RESOURCE_USER` | Environment Variable | DB username |
| `RESOURCE_HOST` | Environment Variable | DB hostname |
| `RESOURCE_PORT` | Environment Variable | DB tcp port |
| `RESOURCE_NAME` | Environment Variable | DB instance name |
| `resource_pass` | Docker secret | DB password |

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