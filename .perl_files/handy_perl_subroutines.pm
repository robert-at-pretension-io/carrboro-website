#!/usr/bin/perl
# package handy_perl_subroutines;
use strict;
use warnings;
use Array::Utils qw(:all);
 use Exporter qw(import);

our @EXPORT_OK = qw(get_variable_data);

##################################
#				 #
#       VARIABLES GO HERE        #
# 				 #
#################################



#################################

##############
#new function#
##############

sub get_variable_data {

my ($description,@rest)= @_;
print "Requesting data: $description\nType your answer and then press the Enter Key\n";

my $return_value = <STDIN>;
chomp $return_value;
return $return_value;

}


=get_variable_data_function____example_of_usage

my $age = collect_variable_data("What is your age?");

print "\nyour age is $age";


=cut



##############
#new function#
##############

sub safe_create_file {

my ($description,@rest)= @_;

print "$description\n";
my $answer = <STDIN>;
chomp $answer;

while (-e $answer) {
print "file exists already\nPick another name.\n";
$answer= <STDIN>;
chomp $answer;
}

print `touch $answer`;
}





=safe_create_file_function_____example_of_usage

safe_create_file("you are creating a config file, what would you like to name it?");

safe_create_file("what would you like to name your new file?");
=cut

##############
#new function#
##############

=not working :(((
sub validate_data {
my ($description,@rest)=@_;
my $answer1 =&get_variable_data($description);
my $answer2 =&get_variable_data("please verify by entering the same thing again.");

while (!($answer1 eq $answer2)){
my $answer1 =&get_variable_data($description);
my $answer2 =&get_variable_data("please verify by entering the same thing again.");
}

return $answer1;
}


=validate_data_function_____example_of_usage

my $question = "What is your favorite color?\n";
my $answer = validate_data($question);
print "your favorite color is, without a doubt, $answer!\n";

=cut

##############
#new function#
##############

sub clear_screen {
system $^O eq 'MSWin32' ? 'cls' : 'clear';
}



##############
#new function#
##############

sub check_if_subset (\@\@) {
my ($set1, $set2, @rest) = @_;
my @array= (array_minus (@{$set1},@{$set2}));

if (!(@array)) { #print "\nthis is a subset\n";
return @{$set1};		
}
else {#print "\nthis is not a subset\n";
return 0;
};
}

##############
#new function#
##############

sub if_input_equals_goto {
our ($input, $goto, @rest) = @_;
# print "\n \$input is $input\n\$goto is $goto";

our $check_if_this_equals_input = <>;
chomp $check_if_this_equals_input;
if ($check_if_this_equals_input eq $input)  {return $goto}
else {
print "continuing...\n";
return '';
}
}

