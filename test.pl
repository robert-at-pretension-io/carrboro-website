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

#foreach my $keys (keys %hash){
#foreach my $values ($hash{$keys}) {

#print "key: $keys, value: $values.<br>";}}  #debugging

print '

<style>

.container{
width: 100%;
border-top: 1px solid rgba(0, 0, 0, 0.1);
padding: 20px;
}
h1{line-height: 40px;
margin-bottom:20px;
}

.entry{
margin-bottom:30px;
clear:both;
display: block;
}
td{
background:rgba(0,0,0,.1);
min-width: 50px;
}

table {
min-width: 100%;	
    font-size: 13px;
    line-height: 25px;
        padding: 20px;

border-top: 1px solid rgba(0, 0, 0, 0.1); border-bottom: 1px solid rgba(255, 255, 255, 0.3);
clear:both;

}




td 
{
    text-align:center; 
    vertical-align:middle;
}

th{
padding:10px;
}

#hr { border: 0; height: 0; border-top: 1px solid rgba(0, 0, 0, 0.1); border-bottom: 1px solid rgba(255, 255, 255, 0.3); padding:0; }

input{
border:0;
border-bottom: 1px solid rgba(0, 0, 0, 0.1); 
#border-bottom: 1px solid rgba(255, 255, 255, 0.3);
}


* {


#color:white;
margin: 0px;
padding: 0px;
#background:rgba(100,0,140,0.4);
}

</style>
';
our %forms = (

    alias => {
        human_readable => 'Name of Race',
        example        => 'Cummings High School, Wendy\'s invitational, etc',
        regex          => '[a-zA-Z ]',
        fix_data       => 'use only letters and spaces.',

    },

    location => {
        human_readable => 'Address of Race',
        example        => '123 Fake Street, City/Town, State, Zip',
        function       => 'address_check()',
        fix_data => 'use this form exactly: 123 Fake Street, City, State, Zip',

    },

    date => {
        human_readable => 'Date',
        example        => '1995-12-25 is the christmas of 95',
        regex          => '^\d{4,4}-\d{2,2}-\d{2,2}$',
        fix_data       => 'use this form: yyyy-mm-dd .'
    },
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

our $form_title = "Enter Runners...";
our @insert_new_runners =
  ( 'first_name', 'last_name', 'gender',  'currently_on_team',
  );

sub create_form {
    my $form_title             = shift;
    my $insert_into_this_table = shift;
    my (@form_fields)          = @_;
    my ($current_file) = $0 =~ m'[^/]+(?=/$|$)';
    print "<div class='container'>";
    print
      "<form method='post' action='test.pl' ><h1>$form_title</h1>";
    unless (%errors) { undef %valid; }

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
    print "<input type=\"submit\" value=\"Submit\" >";
    print "</form>";

    print "</div>";
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

    address_check => sub {
        my ($data) = @_;
        my ( $street_name_and_number, $city, $state, $zip ) =
          split( ',', $data );
        my $error;
        unless (
            $street_name_and_number =~ m/([0-9]+) ([a-zA-Z]+) ([a-zA-Z\.]+)/ )
        {
            return;
        }
        unless ( $city =~ m/[a-zA-Z]+/ ) {
            return;
        }
        unless ( $state =~ m/[a-zA-Z]+/ ) {
            return;
        }
        unless ( $zip =~ m/([0-9]{5,5})/ ) {
            return;
        }

        return "true";

    },
);
our @keys;
our @values;
our %valid;

#@names =  $q->param;
#foreach (@names){ print "$_ <br>";}

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
                  $forms{$form_name}->{function} =~ m/^(.+)\((.*)\)$/;
                my @array = split( /,/, $args );
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

create_form( "Enter New Runners", 'runners', @insert_new_runners );
create_form( "Enter New Race Locations", 'races', ( 'alias', 'location' ) );

################################### TO DO: MAKE SURE THAT THE $KEYS ARE A SUBSET OF THE COLUMS OF A THE TABLE.. IF NOT, THEN SKIP THEM
#my $sqlz = "INSERT INTO runners ($key_scalar) VALUES ($value_scalar)";

#print $sqlz;

sub send_sql {
    my $sql     = shift;
    my $do_work = $dbh->prepare($sql);
    $do_work->execute;
    return $do_work;
}

our %database_hash;

our @runner_columns = hashify_database_query_by_pk_id( "runners", "pk_id" );
our @race_columns   = hashify_database_query_by_pk_id( "races",   "pk_id" );

if ( !%errors and $key_scalar ) {

    unless ( array_minus( @keys, @runner_columns ) ) {
        my $sqlz = "INSERT INTO runners ($key_scalar) VALUES ($value_scalar)";
        send_sql($sqlz);
    }

    unless ( array_minus( @keys, @race_columns ) ) {
        my $sqlz = "INSERT INTO races ($key_scalar) VALUES ($value_scalar)";
        send_sql($sqlz);
    }
}

sub hashify_database_query_by_pk_id {

    our ( $table, $pk_id_column_name ) = @_;

    my $sql = "select * from $table";
    our $sth = $dbh->prepare($sql);
    $sth->execute;

    our @fields = @{ $sth->{NAME} };
    foreach my $field (@fields) {
    }

    while ( our $hash_ref = $sth->fetchrow_hashref ) {

        foreach our $field (@fields) {
            $database_hash{$table}{ $$hash_ref{$pk_id_column_name} }{$field} =
              $$hash_ref{$field};
        }

    }
    return @fields;
}



sub human_readable_label {
@data_label = @_;
my @human_readable;
foreach my $label (@data_label)
{
if ($forms{$label}{human_readable}){push (@human_readable, $forms{$label}{human_readable}); }

else{push (@human_readable,"Unique ID #")}
}
return @human_readable;

}



#print Dumper(\%database_hash);
print_table( 'runners', @runner_columns );
print_table( 'races',   @race_columns );

sub print_table {

    my ($db_table) = shift;

    my @fields = @_;
    my $sql    = "select * from $db_table";
    our $sth = $dbh->prepare($sql);
    $sth->execute;

	@fields =human_readable_label(@fields); #use this after done debugging
	
    my $table = HTML::Make->new('table');
    my $tr    = $table->push('tr');
    $tr->multiply( 'th', \@fields );
    my $rows = $sth->fetchall_arrayref;

    foreach my $row ( @{$rows} ) {
        my $tr = $table->push('tr');
        $tr->multiply( 'td', \@{$row} );
    }
	
    print $table->text();
}
print $cgi->end_html;
