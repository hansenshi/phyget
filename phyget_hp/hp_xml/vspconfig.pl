#!/usr/bin/perl 
# Copyright 2003,2016 Hewlett Packard Enterprise Development LP
# Modify files to allow iLO serial port redirection
#
#Using vspconfig.pl
#   This script will modify the following two files:
#  \etc\inittab
#  \etc\securetty

#     usage: vspconfig.pl [-h] -t [0|1|2|3] 
          
#          -h 	: This help message
#          -t	: Specify terminal (ttyS)

#     For information about the iLO Virtual Serial Port (VSP),
#     refer to:
#           Integrated Lights-Out Virtual Serial Port 
#           configuration and operation
     
#     This document can be found on www.hpe.com. 

use Getopt::Std;
use vars qw/ %opt /;

# VSP document name
my $vspDoc = "\tIntegrated Lights-Out Virtual Serial\n\tPort configuration and operation";
my $webAddr = "www.hpe.com";
# Serial port session string
my $iStr = "";
my $iStr0 = "S";
my $iStr1 = ":2345:respawn:/sbin/agetty 115200 ttyS";
my $iStr2 = " vt100";
# Non standard serial port address
my $spStr1 = "setserial /dev/";
my $spStr2 = " uart 16550A port 0x0408 irq 4";
# Generic terminal string
my $cStr = "ttyS";

my @cStr;
my @iStr;

sub cmdArgs {
	getopts( 'ht:', \%opt ) or die &usage;
	if ($opt{h} or !%opt) {
		&usage;
		exit;
	}
	if ($opt{t} =~ /[4-9]|\d{2,}/) {
		print "Unsupported terminal $opt{t}.\n";
		exit;
	}
	for($i=0;$i<4;$i++) {
		push(@cStr,($cStr.$i));
		push(@iStr,($iStr0.$i.$iStr1.$i.$iStr2));
	}
	# concat ttyS with terminal number
	$cStr = $cStr . $opt{t};
	$iStr = $iStr0 . $opt{t} . $iStr1 .$opt{t} . $iStr2;

}

 
sub printa {
	print @cStr;
	print "\n";
	print "@cStr";
	print "\n";
	print @cStr."";
}

sub usage {
	print STDERR << "EOF";

     usage: $0 [-h] -t [0|1|2|3] 
          
          -h 	: This help message
          -t	: Specify terminal (ttyS)

EOF
	&info;
	exit;
	
}

sub info {
	print STDERR << "EOF";

     For information about the iLO Virtual Serial Port (VSP),
     refer to:
           Integrated Lights-Out Virtual Serial Port 
           configuration and operation
     
     This document can be found on $webAddr.

EOF
}

sub remind {
	my $str = $spStr1 . $cStr . $spStr2;
	print STDERR << "EOF";

     Server must be rebooted before file changes take effect.

     For servers with a non-standard UART address, append rc.serial
     with the following string:
         $str;

EOF
}
sub prev_mod {
    
    print STDERR << "EOF";
    
 Warning:
    A terminal setting was detected in $_[0] on line $_[2]. 
    Line $_[2] contains the following terminal setting:
       $_[1]
    Modify line $_[2] to the desired setting with the following:
       $_[3]
    or remove line $_[2] and run this script again.    

EOF
}
sub files {

   my $count = 0;
   # Open specific file
   my $efile = "/$_[0]/$_[1]";
   open(EF,"$efile") || die "Cannot open $efile: $!"; 
  
   while($line = <EF>) {
      
      if( $line =~ m/$_[2]/) {        
      	print "File $efile is already appended with specified terminal.\n";
	close(EF);
	return;
      }
      foreach $next (@cStr) {
	if($line =~ /$next/) {
	   $count++;
	   &prev_mod($efile,$line,$count,$_[2]);
	   return;
	   last;
        }
      }	
   }
   open(EF,">>$efile") or die "Cannot write $efile: $!";
   # Update file with predefined text
   print EF "$_[2]\n";
   print "File $efile has been appended with:  $_[2]\n";
   # Note files have changed
   $change = 'y';
   close(EF);
}

sub main( ) {
    	$change;
	system("clear");
	&cmdArgs;
	&files("etc","inittab",$iStr);
	&files("etc","securetty",$cStr);

	# if changes were made, send a reminder message
	if ($change =~ /[y]/) {
	  &remind;
	  &info;
	}
  	exit;
}

&main;

