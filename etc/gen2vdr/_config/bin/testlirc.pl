#/usr/bin/perl
use Lirc::Client; 
my $lirc = Lirc::Client->new( 'VDR' , 
     { # required 
       rcfile => "/etc/lircrc", # optional
       dev => "/dev/lircd", # optional
       debug => 0, # optional
       fake => 0, # optional
     } );

my $code;

do { # Loop while getting ir codes 
   $code = $lirc->next_code; # wait for a new ir code 
   system( "touch /tmp/.lirc_pressed" );
} while( defined $code ); # undef will be returned when lirc dev exists 
