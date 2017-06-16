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

Path to the directory containing secrets files, without trailing slash.
Optional. Defaults value: C</run/secrets>

=back

=head2 RESOURCE ENVIRONMENT VARIABLES

MYRESOURCE should be replaced with an identifier for that JDBC resource.
Resource names starting with PARAM_ will be ignored.

=over

=item MYRESOURCE_RESOURCE

Name of the JDBC Resource, without the leading 'jdbc/'
Mandatory.

=item MYRESOURCE_USER

Username for the JDBC connection
Mandatory.

=item MYRESOURCE_URL

The JDBC URL.
If not set; HOST, PORT and NAME must be set.

=item MYRESOURCE_DRIVER

Type of database for the JDBC connections.
Optional. Default value: oraclethin
Value must be one of: mssql mysql oracleoci oraclethin

=item MYRESOURCE_HOST

Hostname for the JDBC connection - part of the url
Ignored if URL is set.

=item MYRESOURCE_PORT

Port number for the JDBC connection - part of the url
Ignored if URL is set.

=item MYRESOURCE_NAME

Instance or database name for the JDBC connection - part of the url
Ignored if URL is set.

=item MYRESOURCE_MAXACTIVE

maxActive configuration value
Optional. Default value: 10

=item MYRESOURCE_MAXIDLE

maxIdle configuration value
Optional. Default value: 2

=item MYRESOURCE_MAXWAIT

maxWait configuration value
Optional. Default value: 2000

=back

=head2 PARAMETER ENVIRONMENT VARIABLES

MYPARAM should be replaced with an identifier for that parameter.

=over

=item PARAM_MYPARAM_NAME

Name of the Parameter

=item PARAM_MYPARAM_VALUE

Value of the Parameter

=item PARAM_MYPARAM_DESCRIPTION

Human-readable description of the Parameter
Optional.

=item PARAM_MYPARAM_OVERRIDE

Set this to false if you do not want a <context-param> for the same parameter name.
Optional.

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
use Text::Template;

# JDBC driver class names
my %driverclasses = (
    mssql => "com.microsoft.jdbc.sqlserver.SQLServerDriver",
    mysql => "",
    oracleoci => "oracle.jdbc.OracleDriver",
    oraclethin => "oracle.jdbc.OracleDriver",
);

# JDBC validation queries
my %validations = (
    mssql => "select 1",
    mysql => "select 1",
    oracleoci => "select 1 from dual",
    oraclethin => "select 1 from dual",
);

# Set output filename to first argument.
# Omit the argument to output to Standard Output.
my $output_file = $ARGV[0];

# TODO: Set this a better way
my $template_file = dirname(abs_path $0) . '/context.xml.template';

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

    my $url = get_env_var($resource, 'URL', '-1');
    my $driver;

    # If environment variable MYRESOURCE_URL was set
    if ($url ne '-1') {
        # Detect the driver type
        if ($url =~ /oracle:thin/) {
            $driver = 'oraclethin';
        } elsif ($url =~ /oracle:oci/) {
            $driver = 'oracleoci';
        } elsif ($url =~ /mysql/) {
            $driver = 'mysql';
        } elsif ($url =~ /microsoft:sqlserver/) {
            $driver = 'mssql';
        } else {
            die "Unable to detect driver for JDBC URL $url";
        }
    } else {
        # Construct the JDBC URL
        $driver = lc(get_env_var($resource, 'DRIVER', 'oraclethin'));

        if ($driver eq 'oraclethin') {
            $url = "jdbc:oracle:thin:\@${\get_env_var($resource, 'HOST')}:${\get_env_var($resource, 'PORT')}:${\get_env_var($resource, 'NAME')}";
        } elsif ($driver eq 'oracleoci') {
            $url = "jdbc:oracle:oci:\@${\get_env_var($resource, 'NAME')}";
        } elsif ($driver eq 'mysql') {
            $url = "jdbc:mysql://${\get_env_var($resource, 'HOST')}:${\get_env_var($resource, 'PORT')}/${\get_env_var($resource, 'NAME')}";
        } elsif ($driver eq 'mssql') {
            $url = "jdbc:microsoft:sqlserver://${\get_env_var($resource, 'HOST')}:${\get_env_var($resource, 'PORT')};databaseName=${\get_env_var($resource, 'NAME')}";
        } else {
            die "Unsupported driver specified for resource $resource";
        }
    }

    push @resource_values, {
        resource => get_env_var($resource, 'RESOURCE'),
        user => get_env_var($resource, 'USER'),
        url => $url,
        driverclass => $driverclasses{$driver},
        validation => $validations{$driver},

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

my %vars = (
    context => \$context,
    resources => \@resource_values,
    parameters => \@parameter_values,
); 

my $result = Text::Template::fill_in_file($template_file, HASH => \%vars);

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
