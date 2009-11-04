=head1 Horus::Reports (Reports.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Horus::Reports;

use Horus::DB;
use strict;

$Horus::Reports::VERSION = '$Revision: 1.4 $';

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  $self->{chunksize} = 65000;
  return $self;
}

=head2 Methods

=head3 get()

Returns an the text of the reqested report.

=cut

sub get {
  my $self = shift @_;
  my $name = shift @_;
  my $report = $self->{db}->column('select report from reports where name=? order by part',$name);
  return join '', @$report;
}

=head3 list()

Returns an array or arrayref of the available reports.

=cut

sub list {
  my $self = shift @_;
  return $self->{db}->column('select name from reports order by report');
}

=head3 update($report,$text)

Updates the given report with the given text.

=cut

sub update {
  my $self = shift @_;
  my $name = shift @_;
  my @report = split '', shift @_;
  
  my $ret = $self->{db}->execute('delete from reports where name=?',$name);

  my $part = 1; my $chunk;  
  while ( scalar(@report) ) {
    for ( 1 .. $self->{chunksize} ) {
      $chunk .= shift @report if scalar(@report);
    }
    $ret = $self->{db}->execute('insert into reports (name,part,report) values (?,?,?)',$name,$part,$chunk);
    $part++; $chunk = undef;
  }
  
  return $ret;
}

=head1 Authorship:
 
  (c) 2007-2009, Horus, Inc.

  Work by Phil Pollard
  $Revision: 1.4 $ $Date: 2009/11/04 19:42:44 $
    
=cut

1;
