#!/usr/bin/perl

use strict;
use Mail::POP3Client; 
use constant DEBUG => 0;

use vars qw($VERSION $SELF); # I want to move %OPT, and %C out of global space
$VERSION = 0.1;
$SELF = $0;

=head1 NAME

poptart

=head1 DESCRIPTION

Poptart connects to a POP3 mail account and selectively deletes
mail(s) that match the specified pattern(s). Useful mostly for 
clearing out spam from hosted mailboxes.

=head1 PREREQUISITES

This script requires the following modules: C<strict>, C<Mail::POP3Client>

=head1 README

Copyright (c) 2007 John Sargent. All rights reserved. 
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

usage: poptart [--test] [-v] host[:port] user password delete-option [...]

  where delete-option is one of the following (all can appear multiple times)

	-R:<zone>	  use <zone> for RBL lookups
	-t:<regex>	  delete mails with a To: header matching <regex>
	-f:<regex>	  delete mails with a From: header matching <regex>
	-s:<regex>	  delete mails with a Subject: header matching <regex>
	-r:<regex>	  delete mails with a Received: header matching <regex>
	-V 		  print version info
        -<header>:<regex>

=pod OSNAMES
any

=pod SCRIPT CATEGORIES
CPAN/mail


=cut





sub usage {
	print <<USAGE

Copyright (c) 2007 John Sargent. All rights reserved. 
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

usage: poptart [--test] [-v] host[:port] user password delete-option [...]

  where delete-option is one of the following (all can appear multiple times)

	-R:<zone>	  use <zone> for RBL lookups
	-t:<regex>	  delete mails with a To: header matching <regex>
	-f:<regex>	  delete mails with a From: header matching <regex>
	-s:<regex>	  delete mails with a Subject: header matching <regex>
	-r:<regex>	  delete mails with a Received: header matching <regex>
        -<header>:<regex>

USAGE

}


sub rbl {
	my ($ip, $rbl) = @_;

	my @quads = split '\.', $ip;

	return undef if $quads[0] == 127;

	my $host = "$quads[3].$quads[2].$quads[1].$quads[0].$rbl";

	my @addrs = (gethostbyname $host)[4];

	if ( @addrs ) {
		my @ip = unpack "C4", $addrs[0];
		print "RBL hit: ", join('.', @ip), "\n";
		return 1;
	}
	
	return undef;
}


my $test = undef;
my $verbose = undef;

foreach ( @ARGV ) {
	$test    = 1 and shift if $_ eq '--test';
	$verbose = 1 and shift if $_ eq '-v';
	print "$SELF $VERSION\n" and exit(0) if $_ eq '-V';
}

usage and exit 0 unless scalar @ARGV > 3;

my ($host,$user,$pass,@args) = @ARGV;
my %xhead;
my @rbls;


foreach ( @args ) {
    if ( /-t:(.+)/ ) {
        push @{$xhead{to}}, $1;
    }
    elsif ( /-s:(.+)/ ) {
        push @{$xhead{subject}}, $1;
    }
    elsif ( /-f:(.+)/ ) {
        push @{$xhead{from}}, $1;
    }
    elsif ( /-r:(.+)/ ) {
        push @{$xhead{received}}, $1;
    }
    elsif ( /-R:(.+)/ ) {
        push @rbls, $1;
    }


    elsif ( /-([a-z][^:]+):(.+)/ ) {
        push @{$xhead{lc $1}}, $2;
    }
}


my $port;
if ( $host =~ /^(.+):(\d+)/ ) { $host = $1; $port = $2; }
else { $port = 110; }


print "Connecting to $host as $user...";
my $pop = new Mail::POP3Client( 
                        HOST => "$host",
			PORT => $port, DEBUG => DEBUG ); 

if ( $pop ) {
    $pop->User($user);
    $pop->Pass($pass);
}
else {
    print STDERR "Cannot creat POP3 object\n";
    exit 1;
}

my $rv = $pop->Connect();
if ( $rv && $pop->State() ne 'DEAD' ) {
    my $count = $pop->Count();

    print "\n$count mails to check";
    
    for( my $i = 1; $i <= $count; $i++ ) { 
        print "\nChecking mail $i of $count...   \r";

	my $header;
	my @headers;

	# Unwrap if necessary
        foreach( $pop->Head( $i ) ) {
	    chomp;

	    if ( /^\s+/ ) {
		$_ =~ s/^\s+/ /;
	    	$header .= $_ and next;
	    } 
            else {
		push @headers, $header if $header;
		$header = $_;
            }
	}
	push @headers, $header if $header;

	foreach $header ( @headers ) {
                my ( $hname, $hval ) = split ( /:\s*/, $header, 2);
                $hname = lc $hname;

		print "\n  $hname => $hval" if $verbose;

	        my $skip = undef;        
                if ( exists $xhead{$hname} ) {
	                foreach my $pattern ( @{$xhead{$hname}} ) {
        	            if ( $hval =~ /$pattern/ ) {
				print "\nDeleting $hname: match ($pattern)\n";
                                $pop->Delete($i) if !$test;
                                $skip=1; 
                                last;
			    }
                	} 
		}

		if ( ! $skip && @rbls && $hname eq "received" ) {
			if ( my @ips = $hval =~ /\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/g ) {
				foreach ( @rbls ) {
					foreach my $ip ( @ips ) {
						if ( rbl($ip, $_) ) {
							print "\nDeleting RBL match ($ip on $_)\n";
        			                        $pop->Delete($i) if !$test;
                			                $skip=1; 
							last;
						}
					}
					last if $skip;
				}
			}
		}
        }
    } 

    print "\n"; 
} 
else {
    print STDERR "Error connecting: ", $pop->Message, "\n";
}

print "Done\n";
$pop->Close(); 
