#!/usr/bin/perl

$/ = undef;
$count = <>;

for(1..$count) {
	if(!($_ % 15)) {
		print "Hop\n";
	} elsif (!($_ % 3)) {
		print "Hoppity\n";
	} elsif (!($_ % 5)) {
		print "Hophop\n";
	}
}
