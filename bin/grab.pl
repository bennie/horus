#!/usr/bin/perl -I../lib

# --quiet option shuts up everything but the change report.
# Other argv's will become the machines to process

# --noconfigsave will stop the config save
# --config=foo Deal only with the textconfig foo.
# --noreport will skip emailing the change report.

# $Id: grab.pl,v 1.75 2009/04/08 23:43:50 ppollard Exp $

use Horus::Hosts;

use Getopt::Long;
use Storable;

use strict;

### Parse ARGV

my $use_expect = 0;

my @configs_to_save = undef;          # --config=foo, Override what config to process
my $email = 'dcops@fusionone.com';    # --email=foo, Email that change report is sent to
my $noconfigsave = 0;                 # --noconfigsave, do not update configs in the DB
my $noreport = 0;                     # --noreport, supress emailing the change report
my $subject = 'Server Change Report'; # --subject, change the report email subject line
my $quiet = 0;                        # --quiet, supress STDOUT run-time info

my $ret = GetOptions(
            'config=s' => \@configs_to_save, 'email=s' => \$email,  noconfigsave => \$noconfigsave,
            noreport => \$noreport, 'subject=s' => \$subject, quiet => \$quiet
);

@configs_to_save = grep !/^\s*$/, split(/,/,join(',',@configs_to_save)); # in case the configs are comma sep

debug( $noreport ? "Report will NOT be sent.\n" : "Report will go to $email\n" );
debug("Configs will NOT be saved.\n") if $noconfigsave;
debug("Only checking for the following config(s): ".join(', ',@configs_to_save)."\n") if scalar @configs_to_save > 0;
debug("\n");

### Global Vars

my $ver = (split ' ', '$Revision: 1.75 $')[1];

### Build up the storable files

for my $file ( qw/changes.store skipped.store uptime.store/ ) {
  my %blank = ();
  store \%blank, $file;
}

my %options = (
  configs_to_save => \@configs_to_save,
  noconfigsave => $noconfigsave,
  quiet => $quiet
);

store \%options, 'options.store';

### Sort out the hosts

my $fh = new Horus::Hosts;
my %all = $fh->all();

my @override;

if ( scalar @ARGV ) {
  for my $name (@ARGV) {
    my @possible = $fh->by_name($name);
    push @override, $possible[0] if $possible[0];
  }
}

### Main

my @hostids = ( scalar @override ? sort @override : sort { lc($all{$a}) cmp lc($all{$b}) } keys %all );

for my $hostid ( @hostids ) {
  system("perl grab-host.pl $hostid");
}

my %changes = %{ retrieve('changes.store') };
my %skipped = %{ retrieve('skipped.store') };
my %uptime  = %{ retrieve('uptime.store')  };

my @connect_errors;

for my $hostid ( @hostids ) {
  push @connect_errors, $hostid unless defined $skipped{$hostid} or defined $changes{$hostid};
}

&change_report();

for my $file ( qw/changes.store skipped.store uptime.store options.store/ ) {
  unlink $file;
}

### Subroutines

sub change_report {
  my $detail;
  
  # Uptimes
 
  my @uptimes = sort { $uptime{$b}{years} <=> $uptime{$a}{years} || $uptime{$b}{days} <=> $uptime{$a}{days} || $uptime{$b}{hours} <=> $uptime{$a}{hours} || $uptime{$b}{mins} <=> $uptime{$a}{mins} } keys %uptime;
  my @best_uptime = map { $uptimes[$_] if  $uptimes[$_] } ( 0 .. 9 );
  my @worst_uptime = map { pop @uptimes if scalar(@uptimes) } ( 0 .. 9 );
 
  my $best_uptime = '<ul>';
  for my $up (@best_uptime) {
    $best_uptime .= "<li> $uptime{$up}{string} - <b>".&href($all{$up})."</b>\n";
  }
  $best_uptime .= '</ul>';

  my $worst_uptime = '<ul>';
  for my $up (@worst_uptime) {
    $worst_uptime .= "<li> $uptime{$up}{string} - <b>".&href($all{$up})."</b>\n";
  }
  $worst_uptime .= '</ul>';
   
  # Sort out what hosts changed, didn't change, and were skipped
 
  my $changeheader;
  my @nochange; my @change;
  
  for my $hostid ( sort { lc($all{$a}) cmp lc($all{$b}) } keys %changes ) {
    my $count = scalar(keys %{$changes{$hostid}{changes}});
    my $host = $all{$hostid};
    if ( $count ) {
      $changeheader .= "<li><b>" . &href($host) . "</b><ul>\n";

      push @change, $host; #"<a href='#$host'>$host</a>";

      $detail .= "\n<p><b><font size='+1'><a name='#$host'></a>$host</font></b></p>\n";
      $detail .= "\n<p>$count config changes noted.</p>\n";

      for my $file ( sort { lc($a) cmp lc($b) } keys %{$changes{$hostid}{changes}} ) {
        my $table = &reformat_table($changes{$hostid}{changes}{$file});
        $changeheader .= "<li>$file</li>\n";
        $detail .= "\nFile: <tt>$file</tt><br />\n$table\n";
      }

      $changeheader .= "</ul></li>\n";
    } else {
      push @nochange, $host unless $skipped{$hostid};
    }
  }

  my @skip = sort map { $all{$_} } keys %skipped;
  my @connect_errors = sort map { $all{$_} } @connect_errors;

  # alpha sort them
  
  @change   = sort { lc($a) cmp lc($b) } @change;
  @skip     = sort { lc($a) cmp lc($b) } @skip;
  @nochange = sort { lc($a) cmp lc($b) } @nochange;

  # Print the report

  open REPORT, '>/tmp/change.html';
  print REPORT "To: $email\nFrom: horus\@horus.fusionone.com\nSubject: $subject\nContent-Type: text/html; charset=\"us-ascii\"\n\n";
  print REPORT "<html><body>\n\n";

  print REPORT "<hr noshade /><font size='+2'><b>Change Report</b></font><hr noshade />\n"
             . scalar(localtime)."<br /><small>Report version $ver</small>\n"
             . "<p>Changes were found on these hosts:</p><blockquote><ul>\n" . $changeheader . "\n</ul></blockquote>\n"
             . ( scalar(@connect_errors) ? "<p>There were connection errors reaching the following hosts:</p><blockquote>" . join(', ', map {&href($_)} @connect_errors ) . "</blockquote>\n" : '' )
             . "<p>We skipped checking the following hosts:</p><blockquote>" . join(', ', map {&href($_)} @skip ) . "</blockquote>\n"
             . "<p>The following hosts appear unchaged:</p><blockquote>".  join(', ', map {&href($_)} @nochange ) . "</blockquote>\n";

  print REPORT "<hr noshade /><font size='+2'><b>General Stats</b></font><hr noshade />\n"
             . "<p>Highest uptimes:</p>$best_uptime<p>Lowest uptimes:</p>$worst_uptime";

  print REPORT "<hr noshade /><font size='+2'><b>Change Detail</b></font><hr noshade />\n" if $detail;

  print REPORT '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">'
             . '<tr><td bgcolor="#666699"><b>Color Key</b></td></tr>'
             . '<tr><td bgcolor="#FFFACD">This is a modified line.</td></tr>'
             . '<tr><td bgcolor="#99CC99">This is a new line.</td></tr>'
             . '<tr><td bgcolor="#CC9999">This is a deleted line.</td></tr>'
             . '</table></td></tr></table>' if $detail;

  print REPORT $detail if $detail;
  
  print REPORT "\n</body></html>\n";
  close REPORT;

  exec("/usr/sbin/sendmail $email < /tmp/change.html") unless $noreport;
  
  print "Skipping emaling the report.\n";
}

sub debug {
  return if $quiet;
  print STDERR @_;
}

sub href {
  return '<a href=\'http://horus.fusionone.com/index.cgi/host/'.$_[0].'\'>'.$_[0]."</a>\n";
}

# Reformat the diff table to HTML
sub reformat_table {
  my $raw = shift @_;
  chomp $raw;
  
  my $out = '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">';
  my $header = '<tr><td bgcolor="#666699">Line</td><td bgcolor="#666699">Old Data</td><td bgcolor="#666699">Line</td><td bgcolor="#666699">New Data</td></tr>';

  $out .= $header;

  my @lines = split "\n", $raw;

  if ( $lines[0] =~ /^Note/ ) { # new file

    $header = '<tr><td bgcolor="#666699">Line</td><td bgcolor="#666699">New Data</td></tr>';
    $out = ( shift @lines ) ."\n". '<table border="0" bgcolor="#000000" cellpadding="0" cellspacing="0"><tr><td><table border="0" bgcolor="#000000" cellpadding="5" cellspacing="1">' . $header;

    $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+([\-]+)\+/ or die "Bad parse on new lines?!";

    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $l2 = length($3); # numbers and data
    my $v2 = length($4);

    shift @lines; pop @lines; # remove top and bottom border

    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$l2})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$line2,$col4,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      $out .= "<tr><td bgcolor='#99CC99' align='center'><tt>$line2</tt></td>\n<td bgcolor='#99CC99' nowrap><tt>$val2</tt></td></tr>\n";
      }
    $out .= '</table></td></tr></table>';

    return $out;


  } elsif ( $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+([\-]+)\+/ ) { # 4 column change table
    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $l2 = length($3); # numbers and data
    my $v2 = length($4);
    
    shift @lines; pop @lines; # remove top and bottom border
    
    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$l2})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$line2,$col4,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      my $color1 = '#FFFFFF';
      my $color2 = '#FFFFFF';

      $color1 = $color2 = '#FFFACD' if $col1 eq '*' and $col5 eq '*'; # Line modified
      $color1 = '#CC9999' if $col1 eq '*' and $col3 eq '*' and $col5 eq '|'; # Line deleted
      $color2 = '#99CC99' if $col1 eq '|' and $col3 eq '*' and $col5 eq '*'; # Line added
      
      $out .= "<tr><td bgcolor='$color1' align='center'><tt>$line1</tt></td>\n<td bgcolor='$color1' nowrap><tt>$val1</tt></td>\n<td bgcolor='$color2' align='center'><tt>$line2</tt></td>\n<td bgcolor='$color2' nowrap><tt>$val2</tt></td></tr>\n"
    }
    $out .= '</table></td></tr></table>';

    return $out;

  } elsif ( $lines[0] =~ /\+([\-]+)\+([\-]+)\+([\-]+)\+/ ) { # 3 column change table
    my $l1 = length($1); # Use the top line to measure
    my $v1 = length($2); # text width to parse out line
    my $v2 = length($3); # numbers and data

    shift @lines; pop @lines; # remove top and bottom border
    
    for my $line ( @lines ) {
      warn "BAD TABLE PARSE!" and return '<pre>'.$raw.'</pre>' unless
        $line =~ /([\|\*\+])(.{$l1})([\|\*\+])(.{$v1})([\|\*\+])(.{$v2})([\|\*\+])/;
      my ($col1,$line1,$col2,$val1,$col3,$val2,$col5) = ($1,$2,$3,$4,$5,$6,$7);

      my $line2 = $line1; # This format omits the second line number columns

      $out .= $header and next if $col1 eq '+'; # Breaker row.

      $val1 =~ s/</&lt;/g;   $val1 =~ s/>/&gt;/g;   # Safe HTML viewing
      $val2 =~ s/</&lt;/g;   $val2 =~ s/>/&gt;/g;   #
      $val1 =~ s/ /&nbsp;/g; $val2 =~ s/ /&nbsp;/g; #

      my $color1 = '#FFFFFF';
      my $color2 = '#FFFFFF';

      $color1 = $color2 = '#FFFACD' if $col1 eq '*' and $col5 eq '*'; # Line modified
      $color1 = '#CC9999' if $col1 eq '*' and $col3 eq '*' and $col5 eq '|'; # Line deleted
      $color2 = '#99CC99' if $col1 eq '|' and $col3 eq '*' and $col5 eq '*'; # Line added
      
      $out .= "<tr><td bgcolor='$color1' align='center'><tt>$line1</tt></td>\n<td bgcolor='$color1' nowrap><tt>$val1</tt></td>\n<td bgcolor='$color2' align='center'><tt>$line2</tt></td>\n<td bgcolor='$color2' nowrap><tt>$val2</tt></td></tr>\n"
    }
    $out .= '</table></td></tr></table>';

    return $out;

  } else {
    return '<pre>'.$raw.'</pre>';
  }
}
