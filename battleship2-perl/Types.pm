#
# Autogenerated by Thrift
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#
require 5.6.0;
use strict;
use warnings;
use Thrift;

package Ship;
use constant CARRIER => 1;
use constant BATTLESHIP => 2;
use constant DESTROYER => 3;
use constant SUBMARINE => 4;
use constant PATROL => 5;
package AttackResult;
use constant SUNK_CARRIER => 1;
use constant SUNK_BATTLESHIP => 2;
use constant SUNK_DESTROYER => 3;
use constant SUNK_SUBMARINE => 4;
use constant SUNK_PATROL => 5;
use constant HIT => 6;
use constant MISS => 7;
use constant NOT_YOUR_TURN => 8;
package Coordinate;
use Class::Accessor;
use base('Class::Accessor');
Coordinate->mk_accessors( qw( row column ) );
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
$self->{row} = undef;
$self->{column} = undef;
  if (UNIVERSAL::isa($vals,'HASH')) {
    if (defined $vals->{row}) {
      $self->{row} = $vals->{row};
    }
    if (defined $vals->{column}) {
      $self->{column} = $vals->{column};
    }
  }
return bless($self,$classname);
}

sub getName {
  return 'Coordinate';
}

sub read {
  my $self  = shift;
  my $input = shift;
  my $xfer  = 0;
  my $fname;
  my $ftype = 0;
  my $fid   = 0;
  $xfer += $input->readStructBegin(\$fname);
  while (1) 
  {
    $xfer += $input->readFieldBegin(\$fname, \$ftype, \$fid);
    if ($ftype == TType::STOP) {
      last;
    }
    SWITCH: for($fid)
    {
      /^1$/ && do{      if ($ftype == TType::I32) {
        $xfer += $input->readI32(\$self->{row});
      } else {
        $xfer += $input->skip($ftype);
      }
      last; };
      /^2$/ && do{      if ($ftype == TType::I32) {
        $xfer += $input->readI32(\$self->{column});
      } else {
        $xfer += $input->skip($ftype);
      }
      last; };
        $xfer += $input->skip($ftype);
    }
    $xfer += $input->readFieldEnd();
  }
  $xfer += $input->readStructEnd();
  return $xfer;
}

sub write {
  my $self   = shift;
  my $output = shift;
  my $xfer   = 0;
  $xfer += $output->writeStructBegin('Coordinate');
  if (defined $self->{row}) {
    $xfer += $output->writeFieldBegin('row', TType::I32, 1);
    $xfer += $output->writeI32($self->{row});
    $xfer += $output->writeFieldEnd();
  }
  if (defined $self->{column}) {
    $xfer += $output->writeFieldBegin('column', TType::I32, 2);
    $xfer += $output->writeI32($self->{column});
    $xfer += $output->writeFieldEnd();
  }
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

package NoMovesMadeException;
use base('Thrift::TException');
use Class::Accessor;
use base('Class::Accessor');
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
return bless($self,$classname);
}

sub getName {
  return 'NoMovesMadeException';
}

sub read {
  my $self  = shift;
  my $input = shift;
  my $xfer  = 0;
  my $fname;
  my $ftype = 0;
  my $fid   = 0;
  $xfer += $input->readStructBegin(\$fname);
  while (1) 
  {
    $xfer += $input->readFieldBegin(\$fname, \$ftype, \$fid);
    if ($ftype == TType::STOP) {
      last;
    }
    SWITCH: for($fid)
    {
        $xfer += $input->skip($ftype);
    }
    $xfer += $input->readFieldEnd();
  }
  $xfer += $input->readStructEnd();
  return $xfer;
}

sub write {
  my $self   = shift;
  my $output = shift;
  my $xfer   = 0;
  $xfer += $output->writeStructBegin('NoMovesMadeException');
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

package GameOverException;
use base('Thrift::TException');
use Class::Accessor;
use base('Class::Accessor');
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
return bless($self,$classname);
}

sub getName {
  return 'GameOverException';
}

sub read {
  my $self  = shift;
  my $input = shift;
  my $xfer  = 0;
  my $fname;
  my $ftype = 0;
  my $fid   = 0;
  $xfer += $input->readStructBegin(\$fname);
  while (1) 
  {
    $xfer += $input->readFieldBegin(\$fname, \$ftype, \$fid);
    if ($ftype == TType::STOP) {
      last;
    }
    SWITCH: for($fid)
    {
        $xfer += $input->skip($ftype);
    }
    $xfer += $input->readFieldEnd();
  }
  $xfer += $input->readStructEnd();
  return $xfer;
}

sub write {
  my $self   = shift;
  my $output = shift;
  my $xfer   = 0;
  $xfer += $output->writeStructBegin('GameOverException');
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

package UnregisteredException;
use base('Thrift::TException');
use Class::Accessor;
use base('Class::Accessor');
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
return bless($self,$classname);
}

sub getName {
  return 'UnregisteredException';
}

sub read {
  my $self  = shift;
  my $input = shift;
  my $xfer  = 0;
  my $fname;
  my $ftype = 0;
  my $fid   = 0;
  $xfer += $input->readStructBegin(\$fname);
  while (1) 
  {
    $xfer += $input->readFieldBegin(\$fname, \$ftype, \$fid);
    if ($ftype == TType::STOP) {
      last;
    }
    SWITCH: for($fid)
    {
        $xfer += $input->skip($ftype);
    }
    $xfer += $input->readFieldEnd();
  }
  $xfer += $input->readStructEnd();
  return $xfer;
}

sub write {
  my $self   = shift;
  my $output = shift;
  my $xfer   = 0;
  $xfer += $output->writeStructBegin('UnregisteredException');
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

package DuplicateEmailException;
use base('Thrift::TException');
use Class::Accessor;
use base('Class::Accessor');
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
return bless($self,$classname);
}

sub getName {
  return 'DuplicateEmailException';
}

sub read {
  my $self  = shift;
  my $input = shift;
  my $xfer  = 0;
  my $fname;
  my $ftype = 0;
  my $fid   = 0;
  $xfer += $input->readStructBegin(\$fname);
  while (1) 
  {
    $xfer += $input->readFieldBegin(\$fname, \$ftype, \$fid);
    if ($ftype == TType::STOP) {
      last;
    }
    SWITCH: for($fid)
    {
        $xfer += $input->skip($ftype);
    }
    $xfer += $input->readFieldEnd();
  }
  $xfer += $input->readStructEnd();
  return $xfer;
}

sub write {
  my $self   = shift;
  my $output = shift;
  my $xfer   = 0;
  $xfer += $output->writeStructBegin('DuplicateEmailException');
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

1;