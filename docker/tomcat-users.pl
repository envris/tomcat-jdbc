#!/usr/bin/perl

=pod

=head1 SYNOPSIS

Generate a Tomcat tomcat-users.xml with an admin user from environment variables and secrets files.

=head1 DESCRIPTION

Generates Tomcat tomcat-users.xml files with an admin user.

Refer to the "Realm Configuration HOW-TO" article in the Apache Tomcat manual for details on Tomcat users configuration.

The program will die if a required environment variable or secret is not defined.

=head1 PARAMETERS

=over

=item path

File path to write the tomcat-users.xml file to. If this parameter isn't specified, the output will be written to standard output.

=back

=head1 ENVIRONMENT VARIABLES

Environment variables are always UPPERCASE.
RESOURCE should be replaced with the name of the resource, without the leading 'jdbc/'.

=over

=item SECRETS_DIR

Optional. Path to the directory containing secrets files, without trailing slash. Defaults to C</run/secrets>

=item TOMCAT_ADMIN

Username for the Tomcat admin user

=back

=head1 SECRETS

A secret file is a file containing a value. Secrets files are all located in one directory, and are refered to by their filename. Secret names are lowercased. resource should be replaced with the name of the resource, as per environment variables.
Docker secrets is where secrets are expected to come from.

=over

=item tomcat_pass

Password for the Tomcat admin user

=back

=head1 EXAMPLE

C<perl app.pl /usr/local/tomcat/conf/tomcat-users.xml>

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
use utf8;
use Env;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname(abs_path $0);
use TomcatContextUtil qw(get_env_var get_secret);

# Set output filename to first argument.
# Omit the argument to output to Standard Output.
my $output_file = $ARGV[0];

# Path to secrets directory. No trailing slash!
my $secrets_dir = get_env_var('', 'SECRETS_DIR', '/run/secrets');

my %vars = (
    user => get_env_var('', 'TOMCAT_ADMIN', ''),
    pass => get_secret('', 'tomcat_pass', $secrets_dir, ''),
);

my $result = generate_template(%vars);
if (defined $result) {
    if (defined $output_file) {
        # Output to file, if filename defined
        open(my $fh, ">:encoding(utf8)", $output_file)
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

# Return a string containing the output tomcat-users.xml file
sub generate_template {
    my %vars = @_;   # Hash of variables

    my $result .= '<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="admin-gui"/>
    <role rolename="manager-gui"/>' . "\n";
    
    # Only add a user if the TOMCAT_ADMIN environment variable was set
    if ($vars{'user'} ne '') {
        $result .= "    <user username=\"$vars{'user'}\" password=\"$vars{'pass'}\" roles=\"admin-gui,manager-gui\"/>\n";
    }
    $result .= "</tomcat-users>\n";

    return $result;
}