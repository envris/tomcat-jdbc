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
our @EXPORT_OK = qw(get_env_var get_secret);

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
