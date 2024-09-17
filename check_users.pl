#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my $csv_users; # Input file. Format: fname,lname,email,telnumber,login,pager,orgunit
my $opt_show; # Show users.
my $opt_create_users; # Create non-existant users
my $update_pager; # Update pager

GetOptions ('check' => \$opt_show,
	   		'users=s' => \$csv_users,
			'pager=s' => \$update_pager,
			'make' => \$opt_create_users) or die "Error in command arguments\n";

sub check_user {
	my $login = shift;
	my $ipa_responce = `ipa user-show $login --all 2>&1`;
	if ($ipa_responce =~ /ERROR/i) { 
		print "User $login not found in active users\n";
		return 0;
	}
	my %user_hash;
	for (split /\n/, $ipa_responce) {
		my ($k, $v) = split /:/, $_;
		$k =~ s/^\s+//;
	   	$v =~ s/^\s+//;
		$user_hash{$k} = $v;
	}
	return \%user_hash;
}

sub main {
	open (my $fh, "<", $csv_users) or die "Can't open file $csv_users: $!\n";
	while (<$fh>) {
		my @csv_line = split /,/;
		my $user = &check_user($csv_line[4]);
		if ($user) {
			print $user->{"User login"} . "," . $user->{"First name"} . "," . $user->{"Last name"} . "\n";
		} else {
			next;
		}

	}
	close $fh;
}
&main if $opt_show;
