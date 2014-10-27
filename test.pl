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
use Scalar::Util qw(looks_like_number);
$Data::Dumper::Useqq = 1;
$q                   = CGI::Simple->new;
our %hash = $q->Vars;
my $cgi = new CGI;
print $cgi->header;

use POSIX qw(strftime);

#uses YYYY-MM-DD format
our $today = strftime "%Y-%m-%d", localtime;

#print Dumper(%hash);

foreach my $key ( keys %hash ) {
    my @value = split( /\0/, $hash{$key} );
}

#print "<br> \$key = '$key'";
#foreach (@value){
#print "\$_ = '$_'<br>";
#}

=usage
$happened = "1999-12-25";
$nothappened = "2015-12-25";
if (date_check($today,$happened) eq 1) {print "<br>this is expected<br>"} else {print "<br>WHAT?<br>";}
if (date_check($today,$nothappened) eq 0) {print "<br>this is expected<br>"} else {print "<br>WHAT?<br>";}
if (date_check($today,$today) eq 2){print "<br>this is expected<br>"} else {print "<br>WHAT?<br>";}
=cut

#takes ($today and $date), returns 0 if the day is yet to come, 1 if that day has passed and 2 if that day is today;
sub date_check {
    my ( $today, $date ) = @_;
    my ( $ty, $tm, $td ) = $today =~ m/(\d+)-(\d+)-(\d+)/;
    my ( $oy, $om, $od ) = $date  =~ m/(\d+)-(\d+)-(\d+)/;

    if ( $today eq $date ) { return 2; }

    if ( $oy <= $ty ) {
        return 1;
        if ( $om <= $tm ) {
            return 1;
            if ( $od <= $td ) {
                return 1;
            }
        }
    }

    else { return 0; }
}

my $dbh = DBI->connect( 'dbi:mysql:team', 'team', 'teampasswd' );

my $sql  = qq[ SHOW TABLES ];
my $rows = $dbh->selectall_arrayref($sql);

our @tables;
foreach ( @{$rows} ) {
    my $table = join( '', @{$_} );
    push( @tables, $table );
}

our %table_columns;
foreach my $table (@tables) {
    my @columns = column_names($table);
    my $columns = join( ',', @columns );
    $table_columns{$table} = $columns;
}

#print Dumper (\%table_columns);

our @hopefully_one_table = determine_table('pk_id');

#print "@hopefully_one_table";

sub determine_table {
    my @test_these_columns = @_;
    my @true_tables
      ; #tables containing the subset of columns -- if this is more than one table then there should be an error -- because the function will not know which table to interact with

    #make sure the the columns aren't the empty set
    if (@test_these_columns) {
        foreach my $table ( keys %table_columns ) {
            my @full_columns = split( /,/, $table_columns{$table} );

            #print "<br>\@full_columns of $table are @full_columns.<br>";

            unless ( array_minus( @test_these_columns, @full_columns ) )
            { #print "@test_these_columns is a subset of @full_columns<br><br>";
                push @true_tables, $table;
            }
        }

    }
    return @true_tables;
}
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
        fix_data       => 'use this form: yyyy-mm-dd .',
        function       => 'my_date()',
    },
    first_name => {
        human_readable => "First Name",
        example        => "John",
        regex          => '^[a-zA-Z\']{1,15}$',
        fix_data       => 'use letters from the english alphabet only.',
    },

    last_name => {
        human_readable => "Last Name",
        example        => "Smith",
        regex          => '^[a-zA-Z\'-]{1,15}$',
        fix_data       => 'use letters from the english alphabet only.',
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

    phone_number => {
        regex          => '(\(?[0-9]{3,3}\)?)?\s*[0-9]{3,3}\s*-?[0-9]{4,4}',
        fix_data       => 'Please enter a valid phone number.',
        human_readable => 'Phone number',
    },

    runner => {
        regex              => '\d',
        fix_data           => 'Something is broken, contact elliot',
        human_readable     => 'Runner Name',
        table              => 'runners',
        references_columns => 'first_name,last_name',
        row_identifier     => 'pk_id',
    },

    races => {
        regex              => '\d',
        fix_data           => 'Something is broken, contact elliot',
        human_readable     => 'Race Name',
        table              => 'races',
        references_columns => 'alias',
        row_identifier     => 'races_pk_id',
    },

    minutes => {
        regex          => '\d{0,2}',
        fix_data       => 'Please enter 2 numbers.',
        human_readable => "Minutes",
    },

    seconds => {
        regex          => '\d{0,2}',
        fix_data       => 'Please enter 0-60.',
        function => 'range(0,60)',
	human_readable => "Seconds",
    	
	},

);

our %functions = (
    range => sub {
        my ( $low_end, $high_end, $data ) = @_;

        if ( ( $data >= $low_end ) and ( $data <= $high_end ) ) {
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
    my_date => sub {
        my ($data) = @_;
        my ( $year, $month, $day ) = $data =~ m/^(\d+)-(\d+)-(\d+)$/;
        if ( $year > 2050 or $year < 2000 ) {
            return;
        }
        if ( $month > 12 or $month < 1 ) {
            return;
        }
        if ( $day > 31 or $day < 1 ) {
            return;
        }
        return "true";
    },

);

our %insert;
our @columns;
our %errors;
our $edit;
our $multivalue;
our %valid;
our $complete = 1;




my @keys = keys(%hash);
foreach my $key (@keys) {
    my ( $column, $id ) = split( /\./, $key );
    push @columns, $column;
}
my @tables = determine_table(@columns);

if ( @tables == 1 ) {
    our $selected_table = join( '', @tables );
    #print "@columns are in @tables<br>";
}
elsif(!%hash){}
else { print "The columns:'@columns' exist in multiple tables:'@tables'"; }

if ($selected_table) {
    foreach my $key ( keys %hash ) {
        foreach my $values ( $hash{$key} ) {
            our @split_values = split( /\0/, $values );
		$array_size = @split_values;
		if ($array_size == 0){undef $complete;}
		#print "\$array_size =", $array_size, "<br>";

		if ($array_size >1){ $multivalue = 1;}
            if (@split_values) {
		


                my ( $column, $id ) = split( /\./, $key );
		foreach my $value (@split_values){
		validate_form2($column,$value);
		}
                print
"<b>\$selected_table</b> = $selected_table <b>\$column</b> = $column <b>\$id</b> = $id <b>value</b> = @split_values<br>";
                my $value = join( ',', @split_values );

 $valid{$column} = $value; 
                if ($id) {
                    $insert{$id}{$column} = $value;
        		$edit = 1;  
	      }
                else {
                    $insert{$column} = $value;
                }


            }

        }
    }
}







#print Dumper(\%valid);
if (%insert){
print "<br>";
print Dumper( \%insert );
}
#if (%errors) {print Dumper(\%errors)};

if (!%errors and %hash and ($complete or $edit)){ #if there are no errors and an entry was made
undef %valid;
print "<br>INSERT DATA INTO DATABASE HERE<br>";

if ($edit){
print "<br>time to edit the table $selected_table<br>";
}
if ($multivalue){
print "<br>time to enter multiple values: '@split_values' into $selected_table<br>";
}

}


=blah
        if ( !$error{$key} ) { $valid{$key} = $value; }

        if ( !( $key eq 'date' ) ) {
            if ( $value =~ m/(\D)/ ) { $value = "\"$value\""; }
        }

        if ( !${$hash_ref}{$key} ) { $error = 1; }
        push @valuez,       $value;
        push @place_holder, '?';
    }

    my $joined_values = join( ',', @valuez );

    my $place_holder_j = join( ',', @place_holder );

    our $prepared;
    if (@valuez) {
        if ( !$error and !%errors ) {
            unless ( array_minus( @keys, @results_columns ) ) {

                if ( !$prepared ) {
                    @update = ( 'seconds', 'minutes' );
                    unless ( array_minus( @keys, @update ) ) {
                        my $sqlz =
"INSERT INTO results ($joined_keys) VALUES ($place_holder_j)";
                        our $sth = $dbh->prepare($sqlz);

                    }

                    else {
                        my $sqlz =
"INSERT INTO results ($joined_keys) VALUES ($place_holder_j)";
                        our $sth = $dbh->prepare($sqlz);
                    }

                    $prepared = 1;
                }

                $sth->execute(@valuez)
                  or die "Can't prepare statement: $DBI::errstr";
                undef @valuez;
            }

            unless ( array_minus( @keys, @runner_columns ) ) {
                my $sqlz =
                  "INSERT INTO runners ($joined_keys) VALUES ($joined_values)";

                send_sql($sqlz);
            }
            unless ( array_minus( @keys, @race_columns ) ) {
                my $sqlz =
                  "INSERT INTO races ($joined_keys) VALUES ($joined_values)";
                send_sql($sqlz);
            }

        }
    }
}
=cut

print '

<style>



.half_container{
float:left;
width: 40%;
border-top: 1px solid rgba(0, 0, 0, 0.1);
padding: 20px;
}

.full_container{
width: 100%;
border-top: 1px solid rgba(0, 0, 0, 0.1);
padding: 20px;
clear:both;
}

.checkboxes{
padding:20px;
float:left;
}


h1{line-height: 40px;
margin-bottom:20px;
}

.entry{
margin-bottom:30px;
#width:350px;
clear:both;
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

sub column_names {
    our ($table) = @_;
    our @array_of_database;
    my $sql = "select * from $table";
    our $sth = $dbh->prepare($sql);
    $sth->execute;

    our @fields = @{ $sth->{NAME} };
    return @fields;
}

sub hashify_database_table {

    our ($table) = @_;
    my @array_of_database;
    my $sql = "select * from $table";
    our $sth = $dbh->prepare($sql);
    $sth->execute;

    our @fields = @{ $sth->{NAME} };
    foreach my $field (@fields) {
    }

    while ( our $hash_ref = $sth->fetchrow_hashref ) {

        my %hash;
        foreach our $field (@fields) {

            $hash{$field} = $$hash_ref{$field};
        }

        push @array_of_database, \%hash;
    }
    return @array_of_database;
}

sub select_runners {
    my @runners = hashify_database_table('runners');
    my @races   = hashify_database_table('races');

    #select a location
    #wtih a drop down list of all the locations

    print "<div class='full_container'>";
    print "<form method='post'>";

    print "<h1>Enter Past or Upcoming Races</h1>";
    print "<select name='races'>";

    foreach my $hash_ref1 (@races) {
        print
"<option value='${$hash_ref1}{races_pk_id}'>${$hash_ref1}{alias}</option>";

    }
    print "</select><br>";

    #select the runners

    foreach our $hash_ref (@runners) {
        our $full_name = "${$hash_ref}{first_name} ${$hash_ref}{last_name}";
        if ($full_name) {
            print
"<div class='checkboxes'><input type='checkbox' name='runner' value='${$hash_ref}{pk_id}'> $full_name </div>";
        }

    }
    print "<div class=\"entry\">";
    our $field = 'date';
    if ( $forms{$field} ) {
        if ( $errors{$field} ) {
            print
"<input placeholder=\"$forms{$field}{human_readable}\" type=\"text\" name=\"$field\" ><br><b>Please $errors{$field}</b>";
        }
        else {
            if ( $valid{$field} ) {

                print
"$forms{$field}{human_readable}: <input type=\"text\" name=\"$field\" value=\"$valid{$field}\">";
            }
            else {

                print
"<input placeholder=\"$forms{$field}{human_readable}\" type=\"text\" name=\"$field\">";
            }

        }
    }
    print "</div>";

    print "<input type=\"submit\" value=\"Submit\" >";

    #enter the date

    print "</form></div>";

}

sub create_form {
    my $form_title             = shift;
    my $insert_into_this_table = shift;
    my (@form_fields)          = @_;
    #my ($current_file) = $0 =~ m'[^/]+(?=/$|$)';
    print "<div class='half_container'>";
    print "<form method='post' action='test.pl' ><h1>$form_title</h1>";
    #unless (%errors) { undef %valid; }

    foreach my $field (@form_fields) {

        print "<div class=\"entry\">";
        if ( $forms{$field} ) {
            if ( $errors{$field} ) {
                print
"<input placeholder=\"$forms{$field}{human_readable}\" type=\"text\" name=\"$field\" ><br><b>Please $errors{$field}</b>";
            }
            else {
                if ( $valid{$field} ) {

                    print
"$forms{$field}{human_readable}: <input type=\"text\" name=\"$field\" value=\"$valid{$field}\">";
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

$column_info = $dbh->column_info( undef, undef, "runners", undef )
  or die "dang, $!";
$column_info_ref = $column_info->fetchall_arrayref;
our @array_of_table_columns;
for my $outside_ref (@$column_info_ref) {
    push( @array_of_table_columns, ${$outside_ref}[3] );
}

sub validate_form2 {
    our ( $form_name, $form_data ) = @_;
    foreach ( keys %forms ) {
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

create_form( "Enter New Runners",
    'runners', ( 'first_name', 'last_name', 'gender', 'currently_on_team', ) );
create_form( "Enter New Race Locations", 'races', ( 'alias', 'location' ) );

sub send_sql {
    my $sql     = shift;
    my $do_work = $dbh->prepare($sql);
    $do_work->execute;
    return $do_work;
}

sub human_readable_label {
    @data_label = @_;
    my @human_readable;
    foreach my $label (@data_label) {
        if ( $forms{$label}{human_readable} ) {
            push( @human_readable, $forms{$label}{human_readable} );
        }

        else { push( @human_readable, "Unique ID #" ) }
    }
    return @human_readable;

}

foreach our $hash_ref (@results) {
    $get_this_pk_id = ${$hash_ref}{runner};
    if ($get_this_pk_id) {
        our $handle = send_sql(
"select first_name, last_name from runners where pk_id='$get_this_pk_id'"
        );
        our ( $first_name, $last_name ) = $handle->fetchrow_array();
        ${$hash_ref}{runner} = "$first_name $last_name";
    }
}

foreach our $hash_ref (@results) {
    $get_this_pk_id = ${$hash_ref}{races};
    if ($get_this_pk_id) {
        our $handle = send_sql(
            "select alias from races where races_pk_id='$get_this_pk_id'");
        our ($alias) = $handle->fetchrow_array();
        ${$hash_ref}{races} = "$alias";
    }
}

sub replace_with2 {
    my (
        $array_ref_to_table_with_numeric_values, $column_to_be_replaced,
        $readable_table_name,                    $readable_identifying_column,
        $array_ref_to_readable_columns
    ) = @_;
    foreach my $hash_ref ( @{$array_ref_to_table_with_numeric_values} ) {
        my $replace_me = ${$hash_ref}{$column_to_be_replaced};
        my $select     = join( ',', @{$array_ref_to_readable_columns} );
        my $handle     = send_sql(
"select $select from $readable_table_name where $readable_identifying_column='$replace_me'"
        );
        my (@values) = $handle->fetchrow_array();
        ${$hash_ref}{$column_to_be_replaced} = "@values";
    }
}

#print Dumper(@test_hash);

=next_form
foreach $result (@test_hash){
my $seconds = ${$result}{seconds};
my $minutes = ${$result}{minutes};
my $date = ${$result}{date};
my $runner = ${$result}{runner};
my $races = ${$result}{races};

if (!$seconds or !$minutes){
print "At $races, on $date, $runner does not have their time entered<br>";
}
}
=cut

sub print_table2 {
    my ($db_table) = shift;

    my @db_table = hashify_database_table($db_table);
    my $handle   = send_sql("select * from $db_table");

    our @fields = @{ $handle->{NAME} };

    foreach $column_name (@fields) {
        if ( $forms{$column_name}{table} ) {

            #print "<br> '$column_name' <br>";
            my $readable_table = $forms{$column_name}{table};
            my $row_identifier = $forms{$column_name}{row_identifier};
            my @readable_columns =
              split( ',', $forms{$column_name}{references_columns} );
            replace_with2(
                \@db_table,      $column_name, $readable_table,
                $row_identifier, \@readable_columns
            );

        }
    }

    our @human_readable_fields = human_readable_label(@fields);
    my $table = HTML::Make->new('table');
    my $tr    = $table->push('tr');
    $tr->multiply( 'th', \@human_readable_fields );

    foreach our $hash_ref (@db_table) {
        my @temp_array;
        foreach our $column (@fields) {
            push @temp_array, ${$hash_ref}{$column};
        }
        if (@temp_array) {
            my $tr = $table->push('tr');
            $tr->multiply( 'td', \@temp_array );
        }

    }

    print $table->text();
}

select_runners();

print_table2('runners');
print_table2('races');
print_table2('results');

my @results = hashify_database_table('results');
my @readable_columns = ( 'first_name', 'last_name' );
replace_with2( \@results, 'runner', 'runners', 'pk_id', \@readable_columns );
my @readable_columns = ('alias');
replace_with2( \@results, 'races', 'races', 'races_pk_id', \@readable_columns );

print "<form class='full_container'>";
foreach $hash_ref (@results) {
    unless ( ${$hash_ref}{seconds} ) {
        print
"<div class='entry'>${$hash_ref}{runner} ran ";
print "<input type='text' name='minutes.${$hash_ref}{pk_id}' placeholder='Minutes'>";
print " and ";
print "<input type='text' name='seconds.${$hash_ref}{pk_id}' placeholder='Seconds'>";
print " at ${$hash_ref}{races}. </div><br>";
    }
}
print "<input type='submit' value='Submit'>";
print "</form>";

#print Dumper($rows);

print $cgi->end_html;

#todo: make a method to save values from the form the updates minutes and second 
