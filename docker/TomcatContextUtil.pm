=pod

=head1 SYNOPSIS

Utilities for getting values from environment variables and secrets files

=head1 get_env_var

Get the value of an environment variable. 
If the environment variable is optional, set a default value.
If a non-optional variable is not set, the program will raise an error.

=head2 PARAMETERS

=over

=item PREFIX

A string to prefix to the name of the environment variable, joined with an underscore (_).
Pass an empty string to omit a prefix.

=item VAR

The name of the environment variable.

=item DEFAULT

The default value to return. Omit to treat this environment variable as non-optional.

=back

=head1 get_secret

Get the value of a secret file.
If the secret is optional, set a default value.
If a non-optional secret is empty or missing, the program will raise an error.

A secret file is a file containing a value. Secrets files are all located in one directory, and are refered to by their filename. Secret names are lowercased. resource should be replaced with the name of the resource, as per environment variables.
Docker secrets is where secrets are expected to come from.

=head2 PARAMETERS

=over

=item PREFIX

A string to prefix to the name of the secret, joined with an underscore (_).
Pass an empty string to omit a prefix.

=item SECRET

The name of the secret.

=item PATH

Path to the directory containing secrets files, without trailing slash.

=item DEFAULT

The default value to return. Omit to treat this secret as non-optional.

=back

=head1 get_resource
Return the data for a JDBC resource.
Fetch data using the supplied method (e.g. reading environment vars or files).

=head2 PARAMETERS

=over

=item RESOURCE

Name of the resource

=item READ_RESOURCE

Reference to method for fetching data, see get_env_var or get_resource_file

=item PASSWORD

Password for the resource

=item REFERENCE

Reference to resource id/location, to be passed to read_resource method.
Optional. Defaults to $resource if ommitted.

=back

=head1 get_resource_file

Return the value of a given resource file.
If it doesn't exist, return the default value or die.

=head2 PARAMETERS

=over

=item PATH

Path of the directory corresponding to the resource

=item NAME

Name of the file to fetch

=item DEFAULT

Default value to return if file doesn't exist
Omit if you want the program to die if the file doesn't exist

=back

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

package TomcatContextUtil;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(get_env_var get_secret get_resource get_resource_file);
use File::Slurp qw(read_file);
use File::Spec::Functions 'catfile';

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

1;

# Return the value of a given environment variable.
# If it doesn't exist, return the default value or die.
# Environment variables are in the format [$prefix_]$var
sub get_env_var {
    my (
        $prefix,    # Prefix to variable. Set to the empty string to omit a prefix
        $var,       # Name of the variable
        $default    # Default value to return if variable doesn't exist
                    #   Omit if you want the program to die if the environment variable doesn't exist
    ) = @_;

    # Set prefix if one was specified
    my $env_var;
    if ($prefix eq '') {
        $env_var = $var;
    } else {
        $env_var = $prefix . '_' . $var; 
    }
    
    if (exists $ENV{$env_var}) {
        # Return the value if it exists
        return $ENV{$env_var};
    } elsif (defined $default) {
        # Otherwise, return the default if it exists
        return $default
    } else {
        # Else, die
        die "Environment variable $env_var not defined";
    }
}

# Return the value of a given secret file.
# If it doesn't exist, return the default value or die.
# Secrets are stored in files with the path $path/[$prefix_]$secret
sub get_secret {
    my (
        $prefix,    # Prefix to variable. Set to the empty string to omit a prefix
        $secret,    # Name of the secret
        $path,      # Path to secrets directory
        $default    # Default value to return if secret doesn't exist
                    #   Omit if you want the program to die if the secret doesn't exist
    ) = @_;

    # Set prefix if one was specified
    my $filename;
    if ($prefix eq '') {
        $filename = $path . '/' . $secret;
    } else {
        $filename = $path . '/' . $prefix . '_' . $secret;
    }

    if (-s $filename) {
        # Return the secret if the secret file is not empty
        open(my $fh, "<", $filename)
            or die "Couldn't open file $filename: $!";
        my $value;
        { local $/ = undef; $value = <$fh>; } # Slurp the whole file into a scalar.
        close $fh;
        return $value;
    } elsif (defined $default) {
        # Otherwise, return the default if it exists
        return $default;
    } else {
        # Else, die
        die "Secret $filename empty or not defined.";
    }
}

# Return the data for a JDBC resource.
# Fetch data using the supplied method (e.g. reading environment vars or files).
sub get_resource {
    my (
        $resource,       # Name of the resource
        $read_resource,  # Reference to method for fetching data, see get_env_var or get_resource_file
        $password,       # Password for the resource
        $reference       # Reference to resource id/location, to be passed to read_resource method.
                         #   Optional. Defaults to $resource if ommitted.
    ) = @_;

    if(!defined $ref) {
        $ref = $resource
    }

    my $url = $read_resource->($ref, 'URL', '-1');
    my $driver;

    # If environment variable MYRESOURCE_URL was set
    if ($url ne '-1') {
        # Detect the driver type
        if ($url =~ /oracle:thin/) {
            return 'oraclethin';
        } elsif ($url =~ /oracle:oci/) {
            return 'oracleoci';
        } elsif ($url =~ /mysql/) {
            return 'mysql';
        } elsif ($url =~ /microsoft:sqlserver/) {
            return 'mssql';
        } else {
            die "Unable to detect driver for JDBC URL $url";
        }
    } else {
        # Construct the JDBC URL
    
        $driver = lc($read_resource->($ref, 'DRIVER', 'oraclethin'));

        if($driver eq 'oraclethin') {
            $url = "jdbc:oracle:thin:\@${\$read_resource->($ref, 'HOST')}:${\$read_resource->($ref, 'PORT')}:${\$read_resource->($ref, 'NAME')}";
        } elsif ($driver eq 'oracleoci') {
            $url = "jdbc:oracle:oci:\@${\$read_resource->($ref, 'NAME')}";
        } elsif ($driver eq 'mysql') {
            $url = "jdbc:mysql://${\$read_resource->($ref, 'HOST')}:${\$read_resource->($ref, 'PORT')}/${\$read_resource->($ref, 'NAME')}";
        } elsif ($driver eq 'mssql') {
            $url = "jdbc:microsoft:sqlserver://${\$read_resource->($ref, 'HOST')}:${\$read_resource->($ref, 'PORT')};databaseName=${\$read_resource->($ref, 'NAME')}";
        } else {
            die "Unsupported driver specified for resource $resource ($driver)";
        }
    }

    return {
        resource => $read_resource->($ref, 'RESOURCE'),
        user => $read_resource->($ref, 'USER'),
        url => $url,
        driverclass => $driverclasses{$driver},
        validation => $validations{$driver},

        maxactive => $read_resource->($ref, 'MAXACTIVE', '10'),
        maxidle => $read_resource->($ref, 'MAXIDLE', '2'),
        maxwait => $read_resource->($ref, 'MAXWAIT', '2000'),
        pass => $password
    }
}

# Return the value of a given resource file
# If it doesn't exist, return the default value or die.
sub get_resource_file {
    my (
        $path,    # Path of the directory corresponding to the resource
        $name,    # Name of the file to fetch
        $default  # Default value to return if file doesn't exist
                  #   Omit if you want the program to die if the file doesn't exist
    ) = @_;

    my $file = catfile($path, lc($name));

    if(-e $file) {
        # Return the value if it exists
        chomp(my $response = read_file($file));
        return $response;
    } elsif(defined $default) {
        # Otherwise, return the default if it exists
        return $default;
    } else {
        # Else, die
        die "Resource file $file does not exist";
    }
}