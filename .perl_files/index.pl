#!/usr/bin/perl
use strict;
use warnings;
#use handy_perl_subroutines;


########################
#                      #
#   variables here     #
#                      #
########################
use Config::Tiny;
my $config = Config::Tiny->new;
$config = Config::Tiny->read ('index.pl.config');
my $full_name= $config ->{'index.pl.config'} -> {'full_name'};
########################

########################
# usage of Config::Tiny#
########################
=usage #comment this out to list all keys
foreach my $section (keys %{$config}) {
    # print "[$section]\n";
    foreach my $parameter (keys %{$config->{$section}}) {
        print "$parameter=$config->{$section}->{$parameter}\n";
    }
}
=cut #also comment this out to list all keys
########################




print "Content-type: text/html\r\n\r\n";


print "Your name is $full_name";
