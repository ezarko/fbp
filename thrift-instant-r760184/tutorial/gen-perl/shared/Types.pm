#
# Autogenerated by Thrift
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#
require 5.6.0;
use strict;
use warnings;
use Thrift;

package shared::SharedStruct;
use Class::Accessor;
use base('Class::Accessor');
shared::SharedStruct->mk_accessors( qw( key value ) );
sub new {
my $classname = shift;
my $self      = {};
my $vals      = shift || {};
$self->{key} = undef;
$self->{value} = undef;
  if (UNIVERSAL::isa($vals,'HASH')) {
    if (defined $vals->{key}) {
      $self->{key} = $vals->{key};
    }
    if (defined $vals->{value}) {
      $self->{value} = $vals->{value};
    }
  }
return bless($self,$classname);
}

sub getName {
  return 'SharedStruct';
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
        $xfer += $input->readI32(\$self->{key});
      } else {
        $xfer += $input->skip($ftype);
      }
      last; };
      /^2$/ && do{      if ($ftype == TType::STRING) {
        $xfer += $input->readString(\$self->{value});
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
  $xfer += $output->writeStructBegin('SharedStruct');
  if (defined $self->{key}) {
    $xfer += $output->writeFieldBegin('key', TType::I32, 1);
    $xfer += $output->writeI32($self->{key});
    $xfer += $output->writeFieldEnd();
  }
  if (defined $self->{value}) {
    $xfer += $output->writeFieldBegin('value', TType::STRING, 2);
    $xfer += $output->writeString($self->{value});
    $xfer += $output->writeFieldEnd();
  }
  $xfer += $output->writeFieldStop();
  $xfer += $output->writeStructEnd();
  return $xfer;
}

1;
