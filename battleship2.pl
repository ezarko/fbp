#!/usr/bin/perl

use strict;
use warnings;

use lib 'battleship2-perl';

use Data::Dumper;
use Thrift;
use Thrift::BinaryProtocol;
use Thrift::Socket;
use Thrift::BufferedTransport;

use Battleship2;
use Types;
use Constants;

my $socket    = new Thrift::Socket('thriftpuzzle.facebook.com',9031,sub{warn @_;});
my $transport = new Thrift::BufferedTransport($socket,1024,1024);
my $protocol  = new Thrift::BinaryProtocol($transport);
my $client    = new Battleship2Client($protocol);

my($email,$game) = @ARGV;

eval {
	$socket->setSendTimeout(1000);
	$socket->setRecvTimeout(5000);
	$socket->setDebug(1);
	$transport->open();

	if ($game) {
print "joining\n";
		print $client->join($game, $email) || die "J:$@";
	} else {
print "registering\n";
		printf "%d\n", $client->registerClient($email) || die "R:$@";
	}

	for my $piece (Ship::CARRIER, Ship::BATTLESHIP, Ship::DESTROYER, Ship::SUBMARINE, Ship::PATROL) {
		my $coord = new Coordinate();
#TODO: randomize placement and direction
		$coord->row(0);
		$coord->column($piece);
		my $horizontal = 0;
print "placing piece\n";
		$client->placePiece($piece, $coord, $horizontal) || die "failed to place piece: $@";
	}

	my %enemy = map {$_ => 1} Ship::CARRIER, Ship::BATTLESHIP, Ship::DESTROYER, Ship::SUBMARINE, Ship::PATROL;

my $m = 0;
	while (keys %enemy && $client->isMyTurn()) {
		my $coord = new Coordinate();
#TODO: randomize placement
		$coord->row(int($m/10));
		$coord->column($m%10);
++$m;
print ">";
		my $result = $client->attack($coord);
		if ($result == AttackResult::SUNK_CARRIER) {
print "got the carrier\n";
			delete $enemy{Ship::CARRIER};
		} elsif ($result == AttackResult::SUNK_BATTLESHIP) {
print "got the battleship\n";
			delete $enemy{Ship::BATTLESHIP};
		} elsif ($result == AttackResult::SUNK_DESTROYER) {
print "got the destroyer\n";
			delete $enemy{Ship::DESTROYER};
		} elsif ($result == AttackResult::SUNK_SUBMARINE) {
print "got the submarine\n";
			delete $enemy{Ship::SUBMARINE};
		} elsif ($result == AttackResult::SUNK_PATROL) {
print "got the patrol boat\n";
			delete $enemy{Ship::PATROL};
		} elsif ($result == AttackResult::HIT) {
print "hit\n";
		} elsif ($result == AttackResult::MISS) {
print "miss\n";
		} elsif ($result == AttackResult::NOT_YOUR_TURN) {
			warn "how did we get here?";
		} else {
			die "unexpected response: ".Dumper($result);
		}
	}

	unless (keys %enemy) {
print "you win\n";
		print $client->winGame();
	}

	$transport->close();
}; if($@){
    warn(Dumper($@));
}
