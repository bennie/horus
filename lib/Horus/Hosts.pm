package Hosts;

use strict;

$Hosts::VERSION = '$Revision: 1.1 $';

sub new {
  my $self = shift @_ || {};
  bless $self;
  return $self;
}

1;
