#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use warnings;
use DBI;
use CGI;
use CGI::Simple;
use DBD::mysql;
use Data::Dumper;
warningsToBrowser(1);
#check for cookies so that perl knows how to load the page
my $cookie_ref = &read_cookie();

#
#our @show_this_html;

#foreach our $cookie_name (keys $cookie_ref) {
#push @show_this_html, [$cookie_ref->{$cookie_name},[$]];
# }

#############add this later


if ( $cookie_ref->{login} eq "granted" ) { $is_cookie_set = "true"; }

our $html_head = "<!DOCTYPE html>
<html class=\"no-js\">
    <head>
        <meta charset=\"utf-8\">
        <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">
        <title></title>
        <meta name=\"description\" content=\"\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <link rel=\"stylesheet\"  href=\"../css/normalize.min.css\">
        <link rel=\"stylesheet\" type=\"text/css\" href=\"../css/main.css\">
        <script src=\"../js/vendor/modernizr-2.6.2-respond-1.1.0.min.js\"></script>
    </head>";
$html_non_logic_body = "
    <body>
        <!--[if lt IE 7]>
            <p class=\"browsehappy\">You are using an <strong>outdated</strong> browser. Please <a href=\"http://browsehappy.com/\">upgrade your browser</a> to improve your experience.</p>
        <![endif]-->
        <div class=\"header-container\">
            <header class=\"wrapper clearfix\">
                <h1 class=\"title\">CXC Home Page</h1>
                <!-- no nav for now
                <nav>
                    <ul>
                        <li><a href=\"#\">Add Runners</a></li>
                    </ul>
                </nav>
                --> 
            </header>
        </div>
        <div class=\"main-container\">
            <div class=\"main wrapper clearfix\">
                <article>";
$html_login = "                
                    <header>
                        <h1>Login</h1>
                        <p>Welcome to the Carrboro Cross Country management page.<br>Please enter your password below.</p>
                    </header>
                <p>        
                <form method=post action=test_param.pl>
                Password: <input type=\"text\" name=\"password\"><br>
                <!-- TEST: <input type=\"text\" name=\"test\"><br>-->
                <input type=\"submit\" value=\"Submit\">
                </form>
                </p>
<!-- send data to cgi-bin/set_cookie.pl -->";
#$html_logout = " <form method= post action=test_param.pl> <input type=\"submit\" value=\"Logout\" name=\"logout\"> </form>";


$html_intro = "   
                        <section>   
                     <h1>Current Functionality</h1>
                <p>... You can log into this page!</p>  
                    </section>
                    <section>
                        <h2>Upcoming Features:</h2> <p><ul><li>Add runners to database</li><li>Add races to database<li>Associate runners with races</li><li>Display database info</li><li>Add feature to correct the database</li><li>Add feature to display the information visually</li><li>Add better site security (low priority)</li><li>Make site \"more dynamic\"/better written</li> </ul> </p> </section></article>";
$html_coaches = "
             <aside>
                    <h3>Welcome coaches!</h3>
                   <ul> 
                        <li>Mimi O\'G.</li>
                        <li>Neil S.</li>
                        <li>Elliot P.S.</li>
                        </ul>
                </aside>
";
$html_end_of_page = "
            </div> <!-- #main -->
        </div> <!-- #main-container -->
        <div class=\"footer-container\">
            <footer class=\"wrapper\">
                <small>CXC 2014</small>
            </footer>
        </div>
        <script src=\"js/main.js\"></script>
    </body>
</html>";


sub get_cookies {
    my $input;
    if ( defined( $ENV{'REQUEST_METHOD'} )
        and $ENV{'REQUEST_METHOD'} eq 'GET' )
    {
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
our $param = &read_parameters();
our %HoH   = (
    password => { opensesame => "login=granted", },
    logout => { "logout" => "login=ungranted",},
    #jetsons => {
    #    lead      => "george",
    #    wife      => "jane",
    #    "his boy" => "elroy",
    #},
    #simpsons => {
    #    lead => "homer",
    #    wife => "marge",
    #    kid  => "bart",
    #},
);
our @actions_by_cookie;
foreach our $form_name ( keys %HoH ) {
    foreach our $send_name ( keys $param ) {
        if ( $send_name =~ m/$form_name/ ) {
            foreach our $form_value ( keys %{ $HoH{$form_name} } ) {
                if ( $param->{$form_name} eq $form_value ) {
                    push @actions_by_cookie, "$HoH{$form_name}{$form_value}";
                }
            }
        }
    }
}
foreach (@actions_by_cookie) {
    print "Set-Cookie: $_\n";
}
our $number = int( rand(100) );

sub read_parameters {
    my $data = {};
    foreach ( split( "&", $input ) ) {
        my ( $key, $value ) = split( "=", $_ );
        $value =~ s/%(..)/chr(hex($1))/ge;
        $data->{$key} = $value;
    }
    return $data;
}

sub read_cookie {
    my $input = $ENV{'HTTP_COOKIE'};
    my $data  = {};
    foreach ( split( '; ', $input ) ) {
        my ( $key, $val ) = split( "=", $_ );
        $data->{$key} = $val;
    }
    return $data;
}
if ($is_cookie_set){
my $dbh = DBI->connect( 'dbi:mysql:team', 'team', 'teampasswd' );
my $sql = q/select * from runners/;
my $sth = $dbh->prepare($sql);
$sth->execute;
}

print "Content-type: text/html\r\n\r\n";

if ( $param->{password} eq "opensesame" ) {
    print '<meta http-equiv="refresh" content="0">';
}



print $html_head;
print $html_non_logic_body;
if ($is_cookie_set) {print $html_intro, $html_coaches; }else {print $html_login;}  


print $html_end_of_page;



