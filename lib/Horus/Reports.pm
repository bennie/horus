=head1 Horus::Reports (Reports.pm)

=head2 Summary

This module provides methods to interact with stored host information.

=cut

package Horus::Reports;

use Horus::DB;
use strict;

sub new {
  my $self = {};
  bless $self;
  $self->{db} = new Horus::DB;
  $self->{chunksize} = 65000;
  return $self;
}

=head2 Methods

=head3 date_of($report_name)

Returns the last modified date of the given report.

=cut

sub date_of {
  my $self = shift @_;
  my $name = shift @_;
  return $self->{db}->single('select last_modified from reports where name=? order by part limit 1',$name);
}

=head3 get($report_name)

Returns an the text of the reqested report.

=cut

sub get {
  my $self = shift @_;
  my $name = shift @_;
  my $report = $self->{db}->column('select report from reports where name=? order by part',$name);
  return join '', @$report;
}


=head3 get_historic($report_name,$date)

Returns an the text of the reqested historic report.

=cut

sub get_historic {
  my $self = shift @_;
  my $name = shift @_;
  my $date = shift @_;
  my $report = $self->{db}->column('select report from reports_historic where name=? and date=? order by part',$name,$date);
  return join '', @$report;
}

=head3 list()

Returns an array or arrayref of the available reports.

=cut

sub list {
  my $self = shift @_;
  return $self->{db}->column('select name from reports order by name');
}

=head3 list_historic()

Returns an hash or hashref of the available reports. Key is report. Value is the array of available dates.

=cut

sub list_historic {
  my $self = shift @_;
  my $sth = $self->{db}->handle('select distinct name, date from reports_historic order by name, date');
  my %ret;
  while ( my $row = $sth->fetchrow_arrayref ) {
    push @{ $ret{$row->[0]} }, $row->[1];
  }
  return wantarray ? %ret : \%ret;
}

=head3 update($report_name,$report_text)

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

=head3 update_historic($report_name,$date,$report_text)

Updates the given historic report with the given text.

=cut

sub update_historic {
  my $self = shift @_;
  my $name = shift @_;
  my $date = shift @_;
  my @report = split '', shift @_;
  
  my $ret = $self->{db}->execute('delete from reports_historic where name=? and date=?',$name,$date);

  my $part = 1; my $chunk;  
  while ( scalar(@report) ) {
    for ( 1 .. $self->{chunksize} ) {
      $chunk .= shift @report if scalar(@report);
    }
    $ret = $self->{db}->execute('insert into reports_historic (name,date,part,report) values (?,?,?,?)',$name,$date,$part,$chunk);
    $part++; $chunk = undef;
  }
  
  return $ret;
}

=head1 Authorship:
 
  (c) 2007-YEARTAG, Horus, Inc.

  Work by Phil Pollard
    
=cut

1;
