#!/usr/bin/perl

use strict;
use warnings;

use lib 'simonsays-perl';

use Data::Dumper;
use Thrift;
use Thrift::BinaryProtocol;
use Thrift::Socket;
use Thrift::BufferedTransport;

use SimonSays;
use Types;
use Constants;

my $socket    = new Thrift::Socket('thriftpuzzle.facebook.com',9030);
my $transport = new Thrift::BufferedTransport($socket,1024,1024);
my $protocol  = new Thrift::BinaryProtocol($transport);
my $client    = new SimonSaysClient($protocol);

eval {
	$socket->setSendTimeout(1000);
	$socket->setRecvTimeout(1000);
	$transport->open();

	$client->registerClient('ezarko2010@gmail.com') || die "R:$@";
START:
	my $colors = $client->startTurn();
print "S:".join(" ",@$colors)."\n";
	for(@$colors) {
print "C:$_\n";
		$client->chooseColor($_) || goto START;
	}
print "E\n";
	goto START unless $client->endTurn();
print "W\n";
	print $client->winGame();

	$transport->close();
}; if($@){
    warn(Dumper($@));
}
