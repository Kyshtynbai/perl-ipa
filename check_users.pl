#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my $csv_users; # Input file. Format: fname,lname,email,telnumber,login,pager,orgunit
my $opt_show; # Show users.
my $opt_create_users; # Create non-existant users
my $pager; # Update pager
my $group_file;
my @groups;

GetOptions ('check' => \$opt_show,
	   		'users=s' => \$csv_users,
			'pager=s' => \$pager,
			'groups=s' => \$group_file,
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

sub print_user {
	my $user = shift;
	$user->{"Pager Number"} = "N/A" if !$user->{"Pager Number"};
	$user->{"Org. Unit"} = "N/A" if !$user->{"Org. Unit"};
	$user->{"Telephone Number"} = "N/A" if !$user->{"Telephone Number"};
	$user->{"Email address"} = "N/A" if !$user->{"Email address"};
	print $user->{"First name"} . "," . $user->{"Last name"} . "," . $user->{"Email address"} . "," . $user->{"Telephone Number"} . "," . $user->{"User login"} . "," . $user->{"Pager Number"} . "," . $user->{"Org. Unit"} . "\n";
}

sub create_user {
	my $user_arref = shift;
	(my $org = $user_arref->[6]) =~ s/\n+|\s+//g; # Removing newlines, which may be caught in original csv
	my $ipa_responce = `ipa user-add $user_arref->[4] --first="$user_arref->[1]" --last="$user_arref->[0]" --email="$user_arref->[2]" --phone="$user_arref->[3]" --pager="$user_arref->[5]" --orgunit="$org" 2>&1`;
	if ($ipa_responce !~ /ERROR/i) {
		print "User $user_arref->[4] created!\n";
	} else {
		print "Error while creating user $user_arref->[4]: $ipa_responce\n";
	}
}

sub update_pager {
	my $user = shift;
	my $pager = shift;
	my $new_pager;
	if ($user->{"Pager Number"}) {
		$new_pager = $user->{"Pager Number"};
	   	$new_pager .= " ";
		$new_pager .= $pager;
	} else {
		$new_pager = $pager;
	}
	print $new_pager . "\n";
	my $ipa_responce = `ipa user-mod $user->{"User login"} --pager="$new_pager" 2>&1`;
	}

sub add_member_to_group {
	my $login = shift;
	my $groups = shift;
	for (@$groups) {
		my $ipa_responce = `ipa group-add-member $_ --users $login 2>&1`;
		if ($ipa_responce !~ /ERROR/i) {
			print "User $login added to group $_\n";
		} else {
			print "Can't add user $login to group $_: \n    $ipa_responce\n";
		}
	}
}

sub main {
	open (my $fh, "<", $csv_users) or die "Can't open file $csv_users: $!\n";
	if ($group_file) {
		open (my $fh, "<", $group_file) or die "Can't open file $group_file: $!\n";
		while (<$fh>) {
			chomp;
			puch @groups, $_;
		}
		close $fh;
	}
	while (<$fh>) {
		my @csv_line = split /,/;
		my $user = &check_user($csv_line[4]);
		if ($user) {
			&print_user($user);
			&update_pager($user, $pager) if $pager;
			&add_member_to_group($user, \@groups) if $group_file;
		} else {
			$opt_create_users ? &create_user(\@csv_line) : next;
		}

	}
	close $fh;
}
&main if $opt_show;
