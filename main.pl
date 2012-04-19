#!/usr/bin/perl -w
# Clodo perl vps checker. v 0.1 by zen 
# Contact me: chainwolf@clodo.ru
# Git repo: https://github.com/Cepnoy/clodo-perl-vps-check

push(@INC,"./");

use strict;
use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;
use HTTP::Request;
use LWP::UserAgent;

my $login = 'chainwolf@gmail.com';
my $key = '1625aa135130ceffae4facb4fbfb4c7a';
my $apiurl = 'http://testapi.kh.clodo.ru';

use vars qw(
	$np
	$options
	$usage
	$extra
	$version
	$response
	$request
	$ua
	$apiurl
	$verbose
	$xtoken
);

$version = "v0.1";

$usage = <<'EOT';
clodo_monit --id=11111
			[--testapi] [--mcci=value] [--mcc=value]
			[--mm=value] [--mio=value] [--mhu=value]
			[--checkbalance] [--version]
EOT


$np = Nagios::Plugin->new( shortname => 'CLODO_MONIT' );

	$options = Nagios::Plugin::Getopt->new(
		usage	=> $usage,
		version	=> $version,
		url		=> 'https://github.com/Cepnoy/clodo-perl-vps-check',
		blurb	=> 'Check clodo corp client\'s vps',
	);	
		
	$options->arg(
		spec	=> 'testapi',
		help	=> 'test api connect',
		required => 0,
	);

	$options->arg(
		spec	=> 'id=s',
		help	=>	'set vps id',
		required => 1,
	);
	
	$options->arg(
		spec	=> 'mcc=i',
		help	=> 'set max cpu critical value',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'mm=i',
		help	=> 'set max memory critical value in KB',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'mii=i',
		help	=> 'set max interface input traffic',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'mio=i',
		help	=> 'set max output interface traffic',
		required => 0,
	);

	$options->arg(
		spec	=> 'mhu=i',
		help	=> 'set max hdd usage',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'checkbalance',
		help	=> 'check negative balance',
		required => 0,
	);
	
	$options->getopts();


sub auth_api {
	$ua = LWP::UserAgent->new;
	$request = HTTP::Request->new('GET', $apiurl,
							[   'X-Auth-User' => $login,
								'X-Auth-Key'  => $key,
							]
	);

	$response = $ua->request($request);

	if ($response->is_success(204)) {
		if ($options->verbose) {
			print $response->as_string;
		}
		$xtoken = $response->header('X-Auth-Token');
		print "$xtoken\n";
	} else {
		die $response->status_line;
	}

}
	
auth_api();
