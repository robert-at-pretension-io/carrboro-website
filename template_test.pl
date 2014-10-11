#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use strict;
use warnings;
use Data::Dumper;
warningsToBrowser(1);
use HTML::Template;

my $cookie_ref = &read_cookie();



sub get_cookies { 
my $input;

if (defined($ENV{'REQUEST_METHOD'})  and  $ENV{'REQUEST_METHOD'} eq 'GET' ) {
	$input = $ENV{'QUERY_STRING'};
}
else {
	while (<STDIN>) {
		$input .= $_;
}
}
return $input;
}

our $input = &get_cookies();





#read the form parameters into $param hash reference
my $param = &read_parameters();

#present html file
if ($param->{password} eq "opensesame") {
print "Set-Cookie: login=granted\n";
}



sub read_parameters{
#	my $input = $ENV{'QUERY_STRING'};
	my $data = {};

	foreach (split("&", $input)) {
		my ($key, $value) = split( "=",$_);
		
		$value =~ s/%(..)/chr(hex($1))/ge;
		$data->{$key}=$value;
		}
return $data;
}

sub read_cookie {
my $input = $ENV {'HTTP_COOKIE'};
my $data = {};

foreach ( split ('; ', $input)) {
	my ($key,$val) = split ("=", $_);
	$data->{$key} = $val;
}
return $data;
}







print "Content-type: text/html\r\n\r\n";

my $tmpl = new HTML::Template( filename => "/home/website/index.tmpl");

if ($cookie_ref->{login} eq "granted") 
{$tmpl->param(cookie_test => "true")}

if ($param->{password} eq "opensesame") {
print '<meta http-equiv="refresh" content="0">';
}
print $tmpl->output();
