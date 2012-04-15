#!/usr/bin/perl -w
# Clodo perl vps checker. v 0.1 by zen 
# Contact me: chainwolf@clodo.ru
# Git repo: https://github.com/Cepnoy/clodo-perl-vps-check

push(@INC,"./");

use strict;
#use api_key; # get api
use Nagios::Plugin::Getopt;
use Getopt::Long;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;
use HTTP::Headers;
use HTTP::Request;


