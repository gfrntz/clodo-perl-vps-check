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

my $login = 'chainwolf@gmail.com';
my $key = '1625aa135130ceffae4facb4fbfb4c7a';
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
	$id_loop
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
my $id = $options->id;

sub auth_api {
	my $ua = LWP::UserAgent->new;
	my $request = HTTP::Request->new('GET', $apiurl,
							[   'X-Auth-User' => $login,
								'X-Auth-Key'  => $key,
							]
	);

	my $response = $ua->request($request);

	if ($response->is_success(204)) {

		$xtoken = $response->header('X-Auth-Token');
		$cmdurl = $response->header('X-Server-Management-Url');
		
		if ($options->verbose) {			
			print $response->as_string;
			print "X-token = $xtoken\n";
			print "Cmd url = $cmdurl\n";
		}
	} else {
		die $response->status_line;
	}

}

sub get_servers {
	my ($i,$j);
	my $ua = LWP::UserAgent->new;
	my $request = HTTP::Request->new('GET', $cmdurl . "/servers",
									[	'X-Auth-Token' => $xtoken,
										'Accept' => "application/json"
									 ]
								);
	my $response = $ua->request($request);

	if ($response->is_success(200)) {
		my $res = $response->content;
			
		if ($options->verbose) {
			print "/servers response content\n";
			print "$res\n";
		}

		my ($json_res,@srv_ids);
		my $json_any = JSON::Any->new;
		$json_res = $json_any->from_json($res);


		for my $ids( @{$json_res->{servers}} ){
			push @srv_ids, $ids->{full_id};
		}
	
		$j = @srv_ids;
	
		if ($options->verbose) {
			print "Number of servers in acc - $j\n";
		}
	
		for ($i=0;$i<$j;$i++) {
			if($srv_ids[$i] eq $id) {
				if ($options->verbose) {
					print "This is $srv_ids[$i]\n";
				}
				$id_loop = $i;
				last;
			} 
		}

	} else {
		print "Not ok.\n";
		die $response->status_line;
	}
	
}

sub check_state {
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
		my $res = $response->content;
		my $json_any = JSON::Any->new;
		my $json_res = $json_any->from_json($res);
		my $stat = $json_res->{servers}->[$id_loop]->{status};
		print "$id - $stat\n";
	} else {
		$np->nagios_exit(CRITICAL, "Could not connect to api url /servers.");
	}
	

	
	
}
auth_api();
get_servers();
check_state();




