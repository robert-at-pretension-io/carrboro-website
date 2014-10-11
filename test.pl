#!/usr/bin/perl
use warnings;
use DBI;
use CGI;
use DBD::mysql;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
warningsToBrowser(1);
use HTML::Make;
use CGI::Simple;
use Array::Utils qw(:all);
$q    = new CGI::Simple;
%hash = $q->Vars;
my $cgi = new CGI;
print $cgi->header;
print "<style>
th{
border-radius: 5px;
padding: 10px;
background:rgba(120,120,120,.3);
}
td { 
}
tr {border: none;
}
tr:hover {background:rgba(120,120,120,.3);
}
table { 
    font-family: 'Nobile', Helvetica, Arial, sans-serif;
    font-size: 13px;
    line-height: 25px;
	padding: 20px;
    border: 7px solid;
    border-radius: 25px;
	margin:20px;
float:left;
}
.errors {
float:left;
    border: 7px solid;
    border-radius: 25px;
margin:20px;
padding: 10px;
clear:right;
}
.error {
    font-family: 'Nobile', Helvetica, Arial, sans-serif;
    font-size: 15px;
    line-height: 20px;
	margin-left: 20px;
}
    .container {
 padding:30px;   
    font-family: 'Nobile', Helvetica, Arial, sans-serif;
    font-size: 13px;
margin: 20px;
    float:left;
        clear: both;
    border: 7px solid;
    border-radius: 25px;

}
    .container input {
margin-bottom: 10px;
width: 100%;
        clear: both;
-webkit-border-radius: 5px;
-moz-border-radius: 5px;
border-radius: 5px;   
}
h1 {
    font-family: 'Corben', Georgia, Times, serif;
    font-size: 40px;
    line-height: 45px;
	padding: 20px;
}
</style>";

=show_form
print "<div class=\"container\">
<form action=\"test.pl\" method=\"post\"><h1>Insert Runner Info</h1> <br>
First Name: <input type=\"text\" name=\"first_name\"><br>
Last Name: <input type=\"text\" name=\"last_name\"><br>
Gender(m/f): <input type=\"text\" name=\"gender\"><br>
Currently on team? (y/n): <input type=\"text\" name=\"currently_on_team\"><br>
Year Graduating (or graduated): <input type=\"text\" name=\"graduation_year\"><br>
Years Running: <input type=\"text\" name=\"years_running\"><br>
Year of birth: <input type=\"text\" name=\"year_of_birth\"><br>
<input type=\"submit\" value=\"Submit\" >
</form>
</div>"
  ;
=cut

our %forms = (
    first_name => {
        human_readable => "First Name",
        example        => "John",
        regex          => '^[a-zA-Z\']{1,5}$',
    	fix_data => 
	},

    last_name => {
        human_readable => "Last Name",
        example        => "Smith",
    },

    age => {
        human_readable => "Age of Runner",
        example        => "19",
    },

);

our $form_title = "Enter Runners...";
our @array_of_form_hashes = ( 'first_name', 'last_name', 'age' );

create_form( $form_title, @array_of_form_hashes );

sub create_form {
    my $form_title = shift;
    my (@form_fields) = @_;
    print "<div class=\"container\"><form>";
    print "<form action=\"$0\" method=\"post\"><h1>$form_title</h1> <br>";
    foreach my $field (@form_fields) {
        if ( $forms{$field} ) {
            print
"$forms{$field}{human_readable}: <input type=\"text\" name=\"$field\" value=\"$forms{$field}{example}\"><br>";
        }

        #print "$field->{human_readable}... Example: $field->{example}<br>\n";
    }
    print "</form></div>";
}

my $dbh = DBI->connect( 'dbi:mysql:team', 'team', 'teampasswd' );
$column_info = $dbh->column_info( undef, undef, "runners", undef )
  or die "dang, $!";
$column_info_ref = $column_info->fetchall_arrayref;
our @array_of_table_columns;
for my $outside_ref (@$column_info_ref) {
    push( @array_of_table_columns, ${$outside_ref}[3] );
}
our @valid_form = (
    [
        "first_name",
        'REGEX:^[a-zA-Z\' ]{1,15}$',
        "use letters from the english alphabet only."
    ],
    [
        "last_name",
        'REGEX:^[a-zA-Z\'-]{1,15}$',
        "use letters from the english alphabet only."
    ],
    [ "gender", 'REGEX:^[mf]{1,1}$', "enter m or f." ],
    [
        "years_running",        'REGEX:^\d{1,2}$',
        'FUNCTION:range(0,19)', "enter 0 through 19."
    ],
    [
        "graduation_year",           'REGEX:^[0-9]{4,4}$',
        'FUNCTION:range(2000,2099)', "enter 2000 through 2099."
    ],
    [
        "year_of_birth",             'REGEX:^[0-9]{4,4}$',
        'FUNCTION:range(1900,2099)', "enter 1900 through 2099."
    ],
    [ "currently_on_team", 'REGEX:^[yn]{1,1}$', "enter either y or n." ]
);

our %functions = (
    range => sub {
        my ( $low_end, $high_end, $data ) = @_;
        if ( ( $data > $low_end ) and ( $data < $high_end ) ) {
            return "True";
        }
    },
);
our @keys;
our @values;
our $invalid;
foreach $key ( keys %hash ) {
    our $value = $q->param($key);
    validate_form( $key, $value );
    if ( $value =~ m/(\D)/ ) { $value = "\"$value\""; }
    push @keys,   $key;
    push @values, $value;
}

$key_scalar   = join( ',', @keys );
$value_scalar = join( ',', @values );
our %errors;

sub validate_form {
    our ( $form_name, $form_data, ) = @_;
    foreach $form (@valid_form) {
        if ( $form_name =~ m/@{$form}[0]/ ) {
            foreach $criteria ( @{$form} ) {
                if ( $criteria =~ m/REGEX:(.+)$/ ) {
                    unless ( $form_data =~ m/$1/ ) {
                        unless ( $errors{$form_name} ) {
                            $errors{$form_name} = @{$form}[-1];
                        }
                    }
                }
                if ( $criteria =~ m/FUNCTION:(.+)\((.+)\)$/ ) {
                    @array = split( /,/, $2 );
                    push( @array, $form_data );
                    unless ( $functions{$1}->(@array) ) {
                        unless ( $errors{$form_name} ) {
                            $errors{$form_name} = @{$form}[-1];
                        }
                    }
                }
            }
        }
    }
}
################################### TO DO: MAKE SURE THAT THE $KEYS ARE A SUBSET OF THE COLUMS OF A THE TABLE.. IF NOT, THEN SKIP THEM
my $sqlz = "INSERT INTO runners ($key_scalar) VALUES ($value_scalar)";
if ( !%errors and $key_scalar ) {
    my $insert_data = $dbh->prepare($sqlz);
    $insert_data->execute;
}
print '
<link href="http://fonts.googleapis.com/css?family=Corben:bold" rel="stylesheet" type="text/css">
<link href="http://fonts.googleapis.com/css?family=Nobile" rel="stylesheet" type="text/css">
';

=show_tables
my $sql = q/select * from runners/;
my $sth = $dbh->prepare($sql);
$sth->execute;
my $table = HTML::Make->new('table');
my $tr    = $table->push('tr');
$tr->multiply( 'th', \@{ $sth->{NAME} } );
my $rows = $sth->fetchall_arrayref;

foreach my $row ( @{$rows} ) {
    my $tr = $table->push('tr');
    $tr->multiply( 'td', \@{$row} );
}
print $table->text();
=cut

=show_errors
if (%errors) {
    print '<div class="errors">';
    foreach $key ( keys %errors ) {
        print
"<div class=\"error\"> <b>Invalid Entry</b>: For $key, Please $errors{$key}<br> </div>";
    }
    print '</div>';
}
=cut

print $cgi->end_html;
