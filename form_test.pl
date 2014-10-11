#!/usr/bin/perl
use warnings;
use strict;

our %forms = (
    first_name => {
        human_readable => "First Name",
        example        => "John",
        regex          => '^[a-zA-Z\']{1,5}$',
    },

    last_name => {
	human_readable => "Last Name",
	example => "Smith",
      }

);

our $form_title           = "test form";
our @array_of_form_hashes = ( $forms{first_name}, $forms{last_name} );

create_form( $form_title, @array_of_form_hashes );

sub create_form {
    my $form_title = shift;
    my (@form_fields) = @_;
    print "title: $form_title\n";
    foreach my $field (@form_fields) {
        print '$field->{human_readable}... Example: $field->{example}<br>\n';
    }
}

