#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Tk;
use Tk::Font;
use Tk::HList;
use Tk::JPEG;
use Data::Dumper;
use Fcntl qw(:flock);

my $lockfile = '/tmp/mylockfile';

sub BailOut {
   system( "logger -s Launcher is already running" );
   exit(1);
}

open(my $fhpid, '>', $lockfile) or die "error: open '$lockfile': $!";
flock($fhpid, LOCK_EX|LOCK_NB) or BailOut();

#my $BG_COL = "#788A94";
my $LBBG_COL = "#B8CAD4";
my $SELBG_COL = "#5c7293";
my $HDRBG_COL = "#004080";
my $APP_DIR = "/etc/gen2vdr/applications";
my $IMG_DIR = "/etc/gen2vdr/images";
my $DEF_TITLE = "G2V Launcher";
my $SUB_DIR = "";
my $NUM_ITEMS = 9;
my $OS_DIFF = 5;

my @apps = ();
my @text_item = ();

#my $startApp = shift;
my $startApp = "";
my $in_init = 1;
my $lb;
my $font_family = "times new roman";
my $lbfont_family = "courier new";
my $font_size   = `/etc/vdr/plugins/admin/getadmval.sh GUI_FONTSIZE`;
chomp($font_size);

my $font_normal = 'normal';
my $font_bold = 'bold';
my $act_item = 0;
my $top_item = 0;

my $mact_item = 0;
my $mtop_item = 0;

my $mw = new MainWindow();

my $hdr_font = create_font( $mw, $font_family, $font_size + 12, $font_bold );
my $item_font = create_font( $mw, $lbfont_family, $font_size + 6, $font_bold );

my $canv = $mw->Canvas( -relief => 'sunken',
                        -width =>  $mw->screenwidth,
                        -height => $mw->screenheight)->pack(-expand => 1, -fill => 'both');

my $img_file = get_image( $mw->screenwidth, $mw->screenheight );
print "IMG <$img_file>\n";
my $img = $mw->Photo( -file => $img_file );

$canv->createImage( 0,0,
                    -image  => $img,
                    -anchor => 'nw',
                    -tags   => ['img'] );

get_appls();
create_lb();
show_lb();

$mw->bind("<KeyPress>"       => \&print_keysym);
$mw->bind("<Return>"         => sub { execItem("") });
$mw->bind("<Up>"             => sub { item_select(-1) });
$mw->bind("<Down>"           => sub { item_select(+1) });
$mw->bind("<Left>"           => sub { item_select(-9) });
$mw->bind("<Right>"          => sub { item_select(+9) });
$mw->bind("<Prior>"          => sub { item_select(-9) });
$mw->bind("<Next>"           => sub { item_select(+9) });
$mw->bind("<0>"              => sub { item_select(+99) });
$mw->bind("<minus>"          => sub { resize_fonts(-1); });
$mw->bind("<plus>"           => sub { resize_fonts(+1); });
$mw->bind("<KP_Subtract>"    => sub { resize_fonts(-1); });
$mw->bind("<KP_Add>"         => sub { resize_fonts(+1); });
$mw->bind("<t>"              => sub { set_overscan("-t",+$OS_DIFF); });
$mw->bind("<b>"              => sub { set_overscan("-b",+$OS_DIFF); });
$mw->bind("<l>"              => sub { set_overscan("-l",+$OS_DIFF); });
$mw->bind("<r>"              => sub { set_overscan("-r",+$OS_DIFF); });
$mw->bind("<T>"              => sub { set_overscan("-t",-$OS_DIFF); });
$mw->bind("<B>"              => sub { set_overscan("-b",-$OS_DIFF); });
$mw->bind("<L>"              => sub { set_overscan("-l",-$OS_DIFF); });
$mw->bind("<R>"              => sub { set_overscan("-r",-$OS_DIFF); });
$mw->bind("<F2>"             => sub { move_item(-1); });
$mw->bind("<F3>"             => sub { move_item(+1); });
$mw->bind("<BackSpace>"      => sub { execItem(1) unless ( $SUB_DIR eq "" ); });
$mw->bind("<FocusOut>"       => sub { set_focus(0); });
$mw->bind("<FocusIn>"        => sub { set_focus(1); });

#if ( $startApp ne ""  ) {
#   system( "/_config/bin/gg_switch.sh $startApp" );
#}
#else {
#   system( "screen -dm sh -c \"/_config/bin/gg_setactapp.sh G2V-Launcher\"" );
#}
system( "screen -dm sh -c \"/_config/bin/gg_switch.sh $startApp\"" );

MainLoop;

sub print_keysym {
   my $widget = shift;
   my $e = $widget->XEvent;
   my ($keysym_text, $keysym_decimal) = ($e->K, $e->N);
   syslog( "keysym=$keysym_text, numeric=$keysym_decimal" );
   if ($keysym_decimal > 48 and $keysym_decimal < 58) {
      execItem( $keysym_decimal - 48 );
   }
}


sub move_item {
   my $diff = shift;
   my $numItem = $act_item;
   my $switchItem = $numItem + $diff;
   if ( $switchItem >= 0 and $switchItem < scalar( @apps ) ) {
      @apps[$numItem,$switchItem] = @apps[$switchItem,$numItem];
      my $d1 = index( $apps[$numItem]{name}, "." );
      my $d2 = index( $apps[$switchItem]{name}, "." );
      my $newN1 = substr( $apps[$switchItem]{name}, 0, $d2 ) . substr( $apps[$numItem]{name}, $d1 );
      my $newN2 = substr( $apps[$numItem]{name}, 0, $d1 ) . substr( $apps[$switchItem]{name}, $d2 );
      print "<$apps[$numItem]{name}><$newN1>\n";
      print "<$apps[$switchItem]{name}><$newN2>\n";
      rename( $apps[$numItem]{name}, $newN1 );
      rename( $apps[$switchItem]{name}, $newN2 );
      $apps[$numItem]{name} = $newN1;
      $apps[$switchItem]{name} = $newN2;
      $act_item += $diff;
      if ( ($act_item < $top_item) or ($act_item >= $top_item + $NUM_ITEMS) ) {
         $top_item += $diff;
      }
      show_lb();
   }
}


sub execItem {
   my $sel_item = shift;
   my $num_item = $act_item;
   if ($sel_item ne "") {
      $num_item = $top_item + $sel_item - 1;
   }

   if ( $apps[$num_item]{user} eq ""  ) {
      if ( $apps[$num_item]{name} eq ".." ) {
         $SUB_DIR = "";
         $canv->itemconfigure( $text_item[0], -text => "$DEF_TITLE" );
         $act_item = $mact_item;
         $top_item = $mtop_item;
      }
      else {
         $SUB_DIR = $apps[$num_item]{name};
         $canv->itemconfigure( $text_item[0], -text => substr( $apps[$num_item]{name}, 3 ));
         $mact_item = $act_item;
         $mtop_item = $top_item;
         $act_item = 0;
         $top_item = 0;
      }
      get_appls();
      show_lb();
   }
   else {
      system( "screen -dm sh -c \"/_config/bin/gg_switch.sh $SUB_DIR/$apps[$num_item]{name}\"" );
   }
}


sub create_font {
   my ($w, $family, $size, $weight) = @_;

   my $h_font = { };

   # Create a new font
   $h_font->{'family'} = $family;
   $h_font->{'size'}   = $size;
   $h_font->{'font'}   = $w->Font(-family => $family, -size => $size, -weight => $weight);

   return $h_font;
}


sub resize_fonts {
   my $modify = shift;

   print "RF $modify  $font_size\n";
   $font_size += $modify;
   if ( $font_size > 7 and $font_size < 41 ) {
      $item_font->{'font'}->configure(-size => $font_size);
      $item_font->{'size'} = $font_size + 6;
      $hdr_font->{'font'}->configure(-size => $font_size + 4);
      $hdr_font->{'size'} = $font_size + 12;
      system( "/etc/vdr/plugins/admin/setadmval.sh -x GUI_FONTSIZE $font_size" );
   }
   print "RF $modify  $font_size\n";

   return;
}


sub get_appls {
   chdir( "$APP_DIR/$SUB_DIR" );
   my @APPLS = glob( "[0-9]*.*" );
   @apps = ();

   if ( "$SUB_DIR" ne "" ) {
      push( @apps, { name => "..", item => "[ Hauptmenu ]", user => "" } );
   }

   my $napp;
   my $di;
   my $user;
   foreach my $app (sort(@APPLS)) {
      print "Found <$SUB_DIR><$app>\n";
      $napp = $app;
      $napp =~ s/^[0-9]+\.//;
      if ( -d $app ) {
         $user = "";
         $napp = "[ $napp ]";
      }
      else {
         $di = index( $napp, "." );
         if ( $di < 1 ) {
            $user = "root";
         }
         else {
            $user = substr( $napp, 0, $di );
         }
         $napp = substr( $napp, $di + 1 );
      }
      push( @apps, { name => "$app", item => "$napp", user => "$user" } );
   }
}


sub item_select {
   my $diff = shift;
   my $oldA = $act_item;
   my $oldT = $top_item;

   if ($diff > $NUM_ITEMS) {
      if ($act_item >= scalar( @apps ) - 1) {
         $act_item = 0;
         $top_item = 0;
         $diff = 0;
      }
      else {
         $diff = $NUM_ITEMS;
      }
   }
   $act_item += $diff;

   print "ns <$act_item> ms <" . scalar(@apps) . "> cs <$act_item>\n";
   if ($act_item <= 0) {
      $act_item = 0;
      $top_item = 0;
   }
   elsif ($act_item >= scalar( @apps )) {
      $act_item = scalar( @apps ) - 1;
      $top_item = ( scalar( @apps ) > $NUM_ITEMS ) ? ( scalar( @apps ) - $NUM_ITEMS ) : 0;
   }
   else {
      if ( $act_item < $top_item ) {
         $top_item = ( $top_item >= $NUM_ITEMS ) ? ( $top_item - $NUM_ITEMS ) : 0;
      }
      elsif ( $act_item >= $top_item + $NUM_ITEMS ) {
         if ( $act_item > (scalar( @apps ) - $NUM_ITEMS) ) {
            $top_item = scalar( @apps ) - $NUM_ITEMS;
         }
         else {
            $top_item += $NUM_ITEMS;
         }
      }
   }
   if ( $act_item != $oldA or $top_item != $oldT ) {
      show_lb();
   }

   return;
}


sub get_image {
   my ( $w, $h ) = @_;
   my $img = "${IMG_DIR}/g2v_${w}x${h}.jpg";
   if ( ! -e $img ) {
      my $img1 = "${IMG_DIR}/g2v_1920x1200.png";
      my $bw = 1920;
      my $bh = int( 1920 * $h / $w );
      if ( $bh > 1200 ) {
         $bw = int( 1200 * $w / $h );
         $bh = 1200;
      }
      $img1 = "${IMG_DIR}/g2v_${bw}x${bh}.png";
      if ( ! -e $img1 ) {
         my $dw = 1920 - $bw;
         my $dh = 1200 - $bh;
         system( "convert ${IMG_DIR}/g2v_1920_1200.png -crop ${bw}x${bh}+0+${dh} $img1" );
         syslog( "convert ${IMG_DIR}/g2v_1920_1200.png -crop ${bw}x${bh}+0+${dh} $img1" );
      }
      system( "convert $img1 -resize ${w}x${h}\! $img" );
      syslog( "convert $img1 -resize ${w}x${h}\! $img" );
   }
   return $img;
}


sub set_overscan {
   my ( $side, $diff ) = @_;
   system( "/_config/bin/gg_overscan.sh $side $diff" );
}


sub show_lb {
   my $txt = "";
   my $col = "black";
   my $actNum = 1;
   my $offset = 0;

   if ( $top_item > 0 ) {
      if ( ($top_item > 1) and (($top_item + $NUM_ITEMS) >= scalar( @apps )) ) {
         $canv->itemconfigure( $text_item[1], -text => " $apps[$top_item - 2]{item}", -fill => $col );
         $offset ++;
      }
      $canv->itemconfigure( $text_item[$actNum + $offset], -text => " $apps[$top_item - 1]{item}", -fill => $col );
      $offset ++;
   }
   elsif ( scalar( @apps ) <= $NUM_ITEMS ) {
      $canv->itemconfigure( $text_item[$actNum + $offset], -text => "", -fill => $col );
      $offset = 1;
   }
   for ( ; $actNum + $offset <= $NUM_ITEMS + 2; $actNum++ ) {
      $txt = "";
      $col = "black";
      if ( $actNum + $top_item <= scalar( @apps ) ) {
         my $an = ($actNum < 10) ? "$actNum" : "";
         $txt = "$an $apps[$top_item + $actNum - 1]{item}";
      }
      if ( $actNum + $top_item == $act_item + 1 ) {
         $col = "white";
      }
      $canv->itemconfigure( $text_item[$actNum + $offset], -text => $txt, -fill => $col );
   }
}


sub create_lb {
   my $offsety = int(($hdr_font->{'size'} / 2) + ($mw->screenheight / 20));
   my $offsetx = int( $mw->screenwidth * 0.6 );

   $text_item[0] = $canv->createText( $offsetx, $offsety,
                                      -font => $hdr_font->{'font'},
                                      -fill => $HDRBG_COL,
                                      -anchor => "w",
                                      -text => $DEF_TITLE );
   my $item_height = int( ( $mw->screenheight - ( 2 * $offsety ) ) / ( $NUM_ITEMS + 3 ) );
   $offsety += int( $item_height * 1.5 );

   for ( my $i = 1; $i <= $NUM_ITEMS +  2; $i++ ) {
      $text_item[$i] = $canv->createText( $offsetx - int(25 - (3-$i)*(3-$i)), $offsety,
                                          -font => $item_font->{'font'},
                                          -fill => "black",
                                          -anchor => "w",
                                          -text => "" );
      $offsety += $item_height;
   }
}


sub set_focus {
   my $hasFocus = shift;

   syslog( "Focus: $hasFocus" );
   if ( "$hasFocus" eq "1" ) {
      system( "screen -dm sh -c \"unclutter -root -idle 0\"" );
   }
#   if ( "$hasFocus" eq "1" ) {
#3      sleep(2);
#      my $actWin = `ratpoison -c info`;
#      chomp( $actWin );
#      my $actApp = `pidof -x /_config/bin/gg_startapp.sh`;
#      chomp( $actApp );
#      syslog( "Focus: $actWin - $actApp" );
#      if ( index( $actWin, "g_launcher" ) >= 0 && "$actApp" eq "" ) {
#         system( "screen -dm sh -c /_config/bin/gg_setactapp.sh G2V-Launcher" );
#      }
#   }
}


sub syslog {
   my $msg = shift;
   system( "logger -s \"$msg\"" );
}
