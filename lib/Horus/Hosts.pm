package Fusionone::Hosts;

use Fusionone::DB;
use strict;

$Fusionone::Hosts::VERSION = '$Revision: 1.2 $';

sub new {
  my $self = shift @_ || {};
  bless $self;
  $self->{db} = new Fusionone::DB;
  return $self;
}

1;
