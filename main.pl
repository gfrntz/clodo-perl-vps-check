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
use JSON::Any;

my $login = 'login@login';
my $key = 'key';
my $apiurl = 'https://testapi.kh.clodo.ru';

use vars qw(
	$np
	$options
	$usage
	$extra
	$version
	$apiurl
	$verbose
	$xtoken
	$cmdurl
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
	my $ua = LWP::UserAgent->new;
	my $request = HTTP::Request->new('GET', $apiurl,
							[   'X-Auth-User' => $login,
								'X-Auth-Key'  => $key,
							]
	);

	my $response = $ua->request($request);

	if ($response->is_success(204)) {
		if ($options->verbose) {
			print $response->as_string;
		}
		$xtoken = $response->header('X-Auth-Token');
		$cmdurl = $response->header('X-Server-Management-Url');
		print "$xtoken\n";
		print "$cmdurl\n";
	} else {
		die $response->status_line;
	}

}

sub get_limits {
	my $ua = LWP::UserAgent->new;
	my $request = HTTP::Request->new('GET', $cmdurl . "/servers",
									[	'X-Auth-Token' => $xtoken,
										'Accept' => "application/json"
									 ]
								);
	my $response = $ua->request($request);

	if ($response->is_success(200)) {
		if ($options->verbose) {
			print $response->as_string;
		}
		print "Ok.\n";
	} else {
		print "Not ok.\n";
		die $response->status_line;
	}
	
	my $res = $response->content;
	
	print "$res\n";
	my $json_res;
	my $json_xs = JSON::Any->new;
    my %json_res = $json_xs->from_json($res);
	print "$json_res->{id}\n";
	
}
auth_api();
get_limits();
