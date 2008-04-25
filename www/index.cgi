#!/usr/bin/perl

use CGI;
use strict;

my $cgi = new CGI;

print $cgi->header, $cgi->start_html( -title=> 'Hello, World!'), $cgi->p('Hello, World!'), $cgi->end_html;
