#!/usr/bin/perl
use strict;

sub magnify($){
   my $in = shift or die ;
   $in =~ s/^http:\/\/(www\.)*//;
   $in =~ s/\..*$//;
   $in =~ s/[\?\@\!\#\=]/ /g;
   $in =~ /^(.{1})(.*)/;
   $in = uc($1) . "$2" ;
   return $in ;	
}

my $fullname = shift or die ;
my $url = $fullname;
$url =~ s/.*\///;
$url =~ s/\-.*//;
my $html = `wget -T15 -t1 -O - "$url" 2>/dev/null`;
my $type = "gif|jpg|jpeg|tiff|bmp";
my $name = "";
while($html =~ /\"([^\"]*logo[^\"]*)\.($type)\"/gi){
   my $base = $1 ; my $ext = $2 ;
   if($base =~ /(http|www|corner|small)/i){
      next;
   }
   system( "wget -T15 -t1 -O \"${fullname}_.$ext\" \"$url/$base.$ext\" >/dev/null 2>&1" );
   print "Found: ${fullname}_.$ext\n";
   last;
}	

