#!/usr/bin/perl

=pod

=head1 SYNOPSIS

Generate a Tomcat context.xml with JDBC resources from environment variables and secrets files.

=head1 DESCRIPTION

Generates Tomcat context.xml files with any number of JDBC resources and Paramters.
Each JDBC resource is defined with a set of enviroment variables and secrets files. The variables for a resource must share the same prefix.

Refer to the "The Context Container" article in the Apache Tomcat manual for more details on the context.xml file.
Refer to the "Tomcat JDBC Connection Pool" article in the Apache Tomcat manual for details on JDBC resource configuration.

The program will die if a required environment variable or secret is not defined.

=head1 PARAMETERS

=over

=item path

File path to write the context.xml file to. If this parameter isn't specified, the output will be written to standard output.

=back

=head1 ENVIRONMENT VARIABLES

=over

=item CONTEXT

The context path of the Web Application.

=item SECRETS_DIR

Optional. Path to the directory containing secrets files, without trailing slash. Defaults to C</run/secrets>

=back

=head2 RESOURCE ENVIRONMENT VARIABLES

MYRESOURCE should be replaced with an identifier for that JDBC resource.
Resource names starting with PARAM_ will be ignored.

=over

=item MYRESOURCE_RESOURCE

Name of the JDBC Resource, without the leading 'jdbc/'

=item MYRESOURCE_USER

Username for the JDBC connection

=item MYRESOURCE_HOST

Hostname for the JDBC connection - part of the url

=item MYRESOURCE_PORT

Port number for the JDBC connection - part of the url

=item MYRESOURCE_NAME

Instance name for the JDBC connection - part of the url

=item MYRESOURCE_MAXACTIVE

Optional. maxActive configuration value

=item MYRESOURCE_MAXIDLE

Optional. maxIdle configuration value

=item MYRESOURCE_MAXWAIT

Optional. maxWait configuration value

=back

=head2 PARAMETER ENVIRONMENT VARIABLES

MYPARAM should be replaced with an identifier for that parameter.

=over

=item PARAM_MYPARAM_NAME

Name of the Parameter

=item PARAM_MYPARAM_VALUE

Value of the Parameter

=item PARAM_MYPARAM_DESCRIPTION

Optional. Human-readable description of the Parameter

=item PARAM_MYPARAM_OVERRIDE

Optional. Set this to false if you do not want a <context-param> for the same parameter name.

=back

=head1 SECRETS

A secret file is a file containing a value. Secrets files are all located in one directory, and are refered to by their filename. Secret names are lowercased. resource should be replaced with the name of the resource, as per environment variables.
Docker secrets is where secrets are expected to come from.

=over

=item myresource_pass

Password for the JDBC connection

=back

=head1 EXAMPLE

C<perl app.pl /usr/local/tomcat/conf/webapp.xml>

=head1 COPYRIGHT

Copyright 2017 Australian Government Department of the Environment and Energy
<devops@ris.environment.gov.au>

This file is part of tomcat-jdbc.

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

=cut

use strict;
use warnings;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(abs_path $0);
use TomcatContextUtil qw(get_env_var get_secret);

# Set output filename to first argument.
# Omit the argument to output to Standard Output.
my $output_file = $ARGV[0];

# Path to secrets directory. No trailing slash!
my $secrets_dir = get_env_var('', 'SECRETS_DIR', '/run/secrets');

my $context = get_env_var('', 'CONTEXT');

# Find all the defined resources.
my @resources = map /^((?!PARAM)[\w]+)_RESOURCE$/, keys %ENV;
if (scalar @resources == 0) {
    die "No JDBC Resources defined";
}
# Array of hashes with details of each JDBC resource
my @resource_values;

# Add each value to a hash, then add to @resource_values
foreach my $resource (@resources) {
    push @resource_values, {
        resource => get_env_var($resource, 'RESOURCE'),
        user => get_env_var($resource, 'USER'),
        host => get_env_var($resource, 'HOST'),
        port => get_env_var($resource, 'PORT'),
        name => get_env_var($resource, 'NAME'),

        maxactive => get_env_var($resource, 'MAXACTIVE', '10'),
        maxidle => get_env_var($resource, 'MAXIDLE', '2'),
        maxwait => get_env_var($resource, 'MAXWAIT', '2000'),

        pass => get_secret(lc($resource), 'pass', $secrets_dir),
    };
}

# Find all the defined parameters
my @parameters = map /^PARAM_([\w]+)_NAME$/, keys %ENV;
# Array of hashes with details of each Parameter
my @parameter_values;

# Add each value to a hash, then add to @parameter_values
foreach my $parameter (@parameters) {
    push @parameter_values, {
        name => get_env_var('PARAM_' . $parameter, 'NAME'),
        value => get_env_var('PARAM_' . $parameter, 'VALUE'),
        description => get_env_var('PARAM_' . $parameter, 'DESCRIPTION', ''),
        override => get_env_var('PARAM_' . $parameter, 'OVERRIDE', ''),
    };
}

my $result = generate_template($context, \@resource_values, \@parameter_values);
if (defined $result) {
    if (defined $output_file) {
        # Output to file, if filename defined
        open(my $fh, ">", $output_file)
            or die "Couldn't open file $output_file: $!";
        print $fh $result;
        close $fh;
    } else {
        # Else, print to standard output
        print $result;
    }
} else {
    die "Couldn't fill in template: $!";
}

# Return a string containing the output context.xml file
sub generate_template {
    my (
        $context,    # Context path
        $resources_ref,     # Array of resource hashes, passed by reference
        $parameters_ref,    # Array of parameter hashes, passed by reference
    ) = @_;
    # Dereference arrays
    my @resources = @{ $resources_ref };
    my @parameters = @{ $parameters_ref };

    my $result = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $result .= "<Context path=\"/$context\">\n";

    for my $i (0..$#resources) { # Loop over array of hashes
        # Interpolate template with values in hash
        $result .= "    <Resource name=\"jdbc/$resources[$i]{'resource'}\"\n";
        $result .= "        auth=\"Container\"\n";
        $result .= "        type=\"javax.sql.DataSource\"\n";
        $result .= "        maxActive=\"$resources[$i]{'maxactive'}\"\n";
        $result .= "        maxIdle=\"$resources[$i]{'maxidle'}\"\n";
        $result .= "        maxWait=\"$resources[$i]{'maxwait'}\"\n";
        $result .= "        username=\"$resources[$i]{'user'}\"\n";
        $result .= "        password=\"$resources[$i]{'pass'}\"\n";
        $result .= "        driverClassName=\"oracle.jdbc.driver.OracleDriver\"\n";
        $result .= "        url=\"jdbc:oracle:thin:\@$resources[$i]{'host'}:$resources[$i]{'port'}:$resources[$i]{'name'}\"\n";
        $result .= "        validationQuery=\"select 1 from dual\"\n";
        $result .= "    />\n";
    }

    for my $j (0..$#parameters) {
        $result .= "    <Parameter name=\"$parameters[$j]{'name'}\"\n";
        if ($parameters[$j]{'description'} ne '') {
            $result .= "        description=\"$parameters[$j]{'description'}\"\n";
        }
        $result .= "        value=\"$parameters[$j]{'value'}\"\n";
        if ($parameters[$j]{'override'} ne '') {
            $result .= "        override=\"$parameters[$j]{'override'}\"\n";
        }
        $result .= "    />\n";
    }

    $result .= "</Context>\n";

    return $result;
}
