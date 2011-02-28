#!/usr/bin/perl

my $count = <>;
chomp($count);

my %members = ();
my @deferred = ();
sub add_accusation {
	my($accuser, $accused) = @_;
	if (!%members || $members{$accuser} < 0 || $members{$accused} > 0) {
		--$members{$accuser};
		++$members{$accused};
	} elsif ($members{$accused} < 0 || $members{$accuser} > 0) {
		++$members{$accuser};
		--$members{$accused};
	} else {
		push @deferred, [$accuser, $accused];
		return;
	}
	return 1;
}
for(1..$count) {
	$_ = <>;
	my($accuser,$count) = /^([a-zA-Z]+)\s+(\d+)$/;
	for(1..$count) {
		$_ = <>;
		my($accused) = /^([a-zA-Z]+)$/;
		add_accusation($accuser, $accused);
	}
}
my $spinlock = 100;
add_accusation(@{shift @deferred}) || --$spinlock || die "spinlock exceeded, increase value or correct data" while ($spinlock && @deferred);
printf "%d %d\n", sort {$b <=> $a} scalar(grep {$_>0} values %members), scalar(grep {$_<0} values %members);
