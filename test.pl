#!/usr/bin/perl
use warnings;
use DBI;
use CGI;
use DBD::mysql;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
warningsToBrowser(1);
use Data::Dumper;
use HTML::Make;
use CGI::Simple;
use Array::Utils qw(:all);
$q    = new CGI::Simple;
%hash = $q->Vars;
my $cgi = new CGI;
print $cgi->header;




print '

<style>






* {
margin: 1%;
padding: 1%;
background:rgba(0,0,0,0.1);
}

</style>
';
our %forms = (
    first_name => {
        human_readable => "First Name",
        example        => "John",
        regex          => '^[a-zA-Z\']{1,15}$',
        fix_data       => 'use letters from the english alphabet only.'
    },

    last_name => {
        human_readable => "Last Name",
        example        => "Smith",
        regex          => '^[a-zA-Z\'-]{1,15}$',
        fix_data       => 'use letters from the english alphabet only.'
    },

    gender => {
        regex          => '^[mf]{1,1}$',
        fix_data       => 'enter m or f.',
        human_readable => "Gender",
    },

    years_running => {
        regex          => '^\d{1,2}$',
        function       => 'range(0,20)',
        fix_data       => 'enter 0 through 19.',
        human_readable => "Years Running",
    },

    year_of_birth => {
        regex          => '^[0-9]{4,4}$',
        function       => 'range(1900,2099)',
        fix_data       => 'enter 1900 through 2099.',
        human_readable => "Year of Birth"
    },

    currently_on_team => {
        regex          => '^[yn]{1,1}$',
        fix_data       => 'enter either y or n.',
        human_readable => "Currently on Team?",
    },

);

our $form_title           = "Enter Runners...";
our @array_of_form_hashes = (
    'first_name',        'last_name',
    'gender',            'year_of_birth',
    'currently_on_team', 'years_running'
);

sub create_form {
    my $form_title = shift;
    my (@form_fields) = @_;
    my ($current_file) = $0 =~ m'[^/]+(?=/$|$)';
    print
      "<form method='post' action='test.pl' ><div><h1>$form_title</h1></div>";
    unless (%errors) { undef %valid; }
    print "<div class='container'>";
    foreach my $field (@form_fields) {

        print "<div class=\"entry\">";
        if ( $forms{$field} ) {
            if ( $errors{$field} ) {
                print
"<input placeholder=\"$forms{$field}{human_readable}\" type=\"text\" name=\"$field\" ><b>Please $errors{$field}</b>";
            }
            else {
                if ( $valid{$field} ) {

                    print
" $forms{$field}{human_readable}: <input type=\"text\" name=\"$field\" value=\"$valid{$field}\">";
                }
                else {

                    print
"<input placeholder=\"$forms{$field}{human_readable}\" type=\"text\" name=\"$field\">";
                }

            }
        }
        print "</div>";

        #print "$field->{human_readable}... Example: $field->{example}<br>\n";
    }
    print "</div>";
    print "<div><input type=\"submit\" value=\"Submit\" ></div>";
    print "</form>";
}

my $dbh = DBI->connect( 'dbi:mysql:team', 'team', 'teampasswd' );
$column_info = $dbh->column_info( undef, undef, "runners", undef )
  or die "dang, $!";
$column_info_ref = $column_info->fetchall_arrayref;
our @array_of_table_columns;
for my $outside_ref (@$column_info_ref) {
    push( @array_of_table_columns, ${$outside_ref}[3] );
}

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
our %valid;

foreach $key ( keys %hash ) {
    our $value = $q->param($key);
    validate_form2( $key, $value );
    unless ( $errors{$key} ) {
        $valid{$key} = $value;
    }
    if ( $value =~ m/(\D)/ ) { $value = "\"$value\""; }
    push @keys,   $key;
    push @values, $value;
}

$key_scalar   = join( ',', @keys );
$value_scalar = join( ',', @values );

our %errors;

sub validate_form2 {

    our ( $form_name, $form_data ) = @_;
    foreach $form ( keys %forms ) {

        if ( $forms{$form_name} ) {
            if ( $forms{$form_name}->{regex} ) {
                unless ( $form_data =~ m/$forms{$form_name}{regex}/ ) {
                    unless ( $errors{$form_name} ) {
                        $errors{$form_name} = $forms{$form_name}{fix_data};
                    }
                }

            }

            if ( $forms{$form_name}->{function} ) {
                my ( $function, $args ) =
                  $forms{$form_name}->{function} =~ m/^(.+)\((.+)\)$/;
                @array = split( /,/, $args );
                push( @array, $form_data );
                unless ( $functions{$function}->(@array) ) {

                    unless ( $errors{$form_name} ) {
                        $errors{$form_name} = $forms{$form_name}{fix_data};
                    }

                }
            }
        }

    }

}

#create_form( $form_title, @array_of_form_hashes );
################################### TO DO: MAKE SURE THAT THE $KEYS ARE A SUBSET OF THE COLUMS OF A THE TABLE.. IF NOT, THEN SKIP THEM
my $sqlz = "INSERT INTO runners ($key_scalar) VALUES ($value_scalar)";

#print $sqlz;

if ( !%errors and $key_scalar ) {
    my $insert_data = $dbh->prepare($sqlz);
    $insert_data->execute;
}

our %database_hash;



hashify_database_query_by_pk_id("runners","pk_id");

sub hashify_database_query_by_pk_id{

our ($table,$pk_id_column_name) = @_;

my $sql = "select * from $table";
our $sth = $dbh->prepare($sql);
$sth->execute;




our @fields =  @{$sth->{NAME}};
print (join ('  -   ',@fields));
foreach my $field (@fields){
}

while (our $hash_ref = $sth->fetchrow_hashref) {

foreach our $field (@fields){
$database_hash{$table}{$$hash_ref{$pk_id_column_name}}{$field}=$$hash_ref{$field};
}
print "<br>";



}
}

print Dumper(\%database_hash);




=table_stuff
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
print $cgi->end_html;
