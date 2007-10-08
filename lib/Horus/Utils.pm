=head1 Fusionone::Utils (Utils.pm)

=head2 Summary:

This module has many exportable handy utilities as described below.

=cut

use Exporter;
use vars qw(@ISA @EXPORT_OK @EXPORT);

package Fusionone::Utils;
$Fusionone::Utils::VERSION = '$revision: $';

@ISA       = qw/Exporter/;
@EXPORT    = qw//;
@EXPORT_OK = qw/cleancard comma dollar html_box html_date percent strip_to_num simple_date zt/;

=head3 cleancard($num)

Produces a nice dash-delimited display of the given credit card number.

=cut

sub cleancard {
  my $num = shift @_;
  if ( $num !~ /-/ ) {
    1 while $num =~ s/([^-]{4})([^-]+)/$1-$2/;
  }
  return $num;
}

=head3 comma($num)

Puts commas in the appropriate place in a displayed number.

=cut

sub comma {
  my $input = shift @_;
  1 while $input =~ s/(\d)(\d{3})(?!\d)/$1,$2/;
  return $input;
}

=head3 dollar($num)

Prints out a value in human-readable dollars and cents.

 12 would become $12.00

=cut

sub dollar {
  my $input = $_[0];
  return '$0.00' unless $input;

  $input =~ s/[^\.\d]//g;
  $input = int($input*100);

  return '$0.00' if $input eq '0';

  return '$0.'.$input if $input =~ /^\d\d$/;

  warn "Weird dollar amount of '$_[0]' ?" unless $input =~ /^(\d+)(\d\d)$/;
  my $dollar = $1;
  my $cents  = $2;
  
  1 while $dollar =~ s/(\d)(\d{3})(?!\d)/$1,$2/;

  #return sprintf("\$%.2f",$input/100);
  return '$'.$dollar.'.'.$cents;
}

=head3 html_box($cgi,$text,[$width])

# Returns a nice preety box

=cut

sub html_box {
  my $cgi   = shift @_;
  my $text  = shift @_;
  my $width = shift @_;
  
  if ($width > 10) {
    return $cgi->table({-bgcolor=>'#000000', -cellpadding=>1,
                        -border=>0,          -cellspacing=>0  },
             $cgi->Tr(
               $cgi->td(
                 $cgi->table({-bgcolor=>'#000000', -cellpadding=>5,
                              -border=>0,          -cellspacing=>1,
                              -width=>$width },
                   $text
                 )
               )
             )
           );
  } else {
    return $cgi->table({-bgcolor=>'#000000', -cellpadding=>1,
                        -border=>0,          -cellspacing=>0  },
             $cgi->Tr(
               $cgi->td(
                 $cgi->table({-bgcolor=>'#000000', -cellpadding=>5,
                              -border=>0,          -cellspacing=>1  },
                   $text
                 )
               )
             )
           );
  }
}

=head3 html_date($date)

Takes a Mysql date (YYYYMMDDHHMMSS or YYYYMMDD) and returns it as a human 
readable string:

  19001201 would become Dec 1, 1900

=cut

sub html_date {
  my $raw = $_[0];

  return '&nbsp;' if $raw =~ /^00000000/;

  my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

  $raw =~ s/-//g if $raw =~ /-/;
  $raw =~ /^(\d{4})(\d{2})(\d{2})/ or return "Can't Parse: \"$_[0]\"";

  my $day   = $3 + 0;
  my $month = $months[ $2 - 1 ];

  return "$month $day, $1";
}

=head3 percent($num)

Returns a numeric as a human readable percent:

  0.7 becomes 70%

=cut

sub percent {
  return sprintf '%05.2f%%', $_[0] * 100;
}

=head3 simple_date($epoch)

Returns the date formatted YYYY-MM-DD from an URC seconds value. If no time is given, the current date is returned.

=cut

sub simple_date {
  my @local = localtime( shift @_ || time() );
  return sprintf('%0.4d-%0.2d-%0.2d', ($local[5]+1900), ($local[4]+1), $local[3]);
}

=head3 strip_to_num($string)

Removes all but digit characters from a string.

  XMN6DS781 would become 6781

=cut

sub strip_to_num {
  my $num = shift @_;
  $num =~ s/\D//g;
  return $num;
}

=head3 zt($num)

Returns a singular number back with a 0 pre appended

"zt" is short for "zero_ten"

=cut

sub zt {
  my $in = shift @_;
  $in += 0;
  if ($in < 10) { $in = '0'.$in; }
  return $in
}

=head1 Authorship:

  (c) 2007, Fusionone, Inc.
  
  Work by Phil Pollard
  $Revision: 1.1 $ $Date: 2007/10/08 23:58:58 $

  The majority of this module is (c) 1999-2007, Phillip Pollard
  and released under GPL v2.

=cut

1;
