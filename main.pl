#!/usr/bin/perl -w
# Clodo perl vps checker. v 2.0 stable by zen 
# Contact me: chainwolf@clodo.ru
# Git repo: https://github.com/Cepnoy/clodo-perl-vps-check



use strict;
use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;
use HTTP::Request;
use LWP::UserAgent;
use JSON::Any;
use Net::Ping;

my $apiurl = 'https://api.clodo.ru';

use vars qw(
	$np
	$options
	$extra
	$usage
	$version
	$apiurl
	$xtoken
	$cmdurl
	$small_id
	$vps_type
	$vps_ip
	$login
	$key
	%content
	$content
	$response
	$hash
	$res
	$json_res
	$json_any
	$cpu_stat
	$mem_stat
	$hdd_stat

);

$version = "v2.0 stable";

$usage = <<'EOT';
clodo_monit --ip=1.1.1.1 --login=some@login.ru --key=kdkd93k3d90dk
			[--mcci=value] [--mcc=value] [--httpcheck]
			[--mm=value] [--mio=value] [--mhu=value]
			[--checkbalance] [--version]
EOT

$extra = <<'EOT';
Some examples 

DEFAULT:
clodo_monit.pl --ip=1.2.1.2 --login=some@mail.tld --key=222222ddaesdfaesfes3 

OUTPUT:
CLODO_MONIT CRITICAL - CPU Critical - 49;

If all checks ok, then nothing.

With extra options:
clodo_monit.pl --ip=1.2.1.2 --login=some@mail.tld --key=222222ddaesdfaesfes3 --wmhu=2 --mhu=10
CLODO_MONIT CRITICAL - CPU Critical - 49; Hdd usage critical - 17 %

Or like this:
clodo_monit.pl --ip=1.2.1.2 --login=some@mail.tld --key=222222ddaesdfaesfes3 --wmhu=2 --mhu=90
CLODO_MONIT CRITICAL - CPU Critical - 49 Hdd usage warning - 17 %

EOT

$np = Nagios::Plugin->new( shortname => 'CLODO_MONIT' );

	$options = Nagios::Plugin::Getopt->new(
		usage	=> $usage,
		extra   => $extra,
		version	=> $version,
		url		=> 'https://github.com/Cepnoy/clodo-perl-vps-check',
		blurb	=> 'Check clodo corp client\'s vps',
	);	
			
	$options->arg(
		spec	=> 'ip=s',
		help	=>	'set vps ip',
		required => 1,
	);
	
	$options->arg(
		spec	=> 'login=s',
		help	=> 'set vps login',
		required => 1,
	);
	
	$options->arg(
		spec	=> 'key=s',
		help	=> 'set api key',
		required => 1,
	);
	
	$options->arg(
		spec	=> 'mcu=i',
		help	=> 'set max cpu critical value in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'wmcu=i',
		help	=> 'set min cpu warning value in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'mm=i',
		help	=> 'set max memory critical value in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'wmm=i',
		help	=> 'set min memory warning value in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'mhu=i',
		help	=> 'set max hdd usage in percent in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'wmhu=i',
		help	=> 'set min hdd usage warning value in integers',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'checkbalance',
		help	=> 'check negative balance',
		required => 0,
	);
	
	$options->arg(
		spec	=> 'httpcheck',
		help	=> 'check http 200 ok',
		required => 0,
	);

	
	$options->getopts();

$login = $options->login;
$key = $options->key;
$vps_ip = $options->ip;

sub auth {
	my $url = shift;
	
	if (!defined $url) {
		my $ua = LWP::UserAgent->new;
		my $request = HTTP::Request->new('GET', $apiurl,
							[   'X-Auth-User' => $login,
								'X-Auth-Key'  => $key,
							]
		);
		
		$response = $ua->request($request);
				
	} else {
		
		if ($options->verbose) {
			print "else\n";
			print "X-token = $xtoken\n";
			print "Cmd url = $cmdurl" . "$url\n";
		}

		my $ua = LWP::UserAgent->new;
		my $request = HTTP::Request->new('GET', $cmdurl . $url,
									[	'X-Auth-Token' => $xtoken,
										'Accept' => "application/json"
									 ]
		);
		
		$response = $ua->request($request);		
	}
}

sub auth_api {

	&auth;

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
	
	auth("/servers");
		
	if ($response->is_success(204)) {

		 $res = $response->content;

		if ($options->verbose) {
			print "/servers response content\n";
			print "$res\n";
		}
		
		$json_any = JSON::Any->new;
		$json_res = $json_any->from_json($res);
		
		for $hash( @{$json_res->{servers}} ){
			%content = ();
			$content{full_id} = $hash -> {full_id};
			$content{id}	  = $hash -> {id};
			$content{adddresses} = $hash -> {addresses} -> {public} -> [0] -> {ip};
			$content{status} = $hash -> {status};
		
			if ($vps_ip eq $content{adddresses}) {
				if ($options->verbose) {			
					print "Вот он!! Вот он адрес моей мечты!\n";
					print "full_id - $content{full_id} id - $content{id} ip - $content{adddresses} status - $content{status}\n";
				}
				last
			}
			$hash++;
		}
		
		if ($content{status} eq "is_disabled") {
			$np->nagios_exit(OK, "Nothing to do");
		}
		
		my $p = Net::Ping->new("icmp",5);
		if ($p->ping($vps_ip) == 0 && $content{status} eq "is_disabled") {
			$np->nagios_exit(CRITICAL,"VPS  disabled in panel, but started.");
			$p->close();
		}
		
		my $ip_http = "http://" . $vps_ip;

		if ($options->httpcheck) {
			my $ua = LWP::UserAgent->new;
			my $get_ok = HTTP::Request->new('GET', $ip_http);
			my $get_ok_response = $ua->request($get_ok);
		
			if ($get_ok_response->code != 200) {
				$np->add_message(WARNING, "VPS enabled, ping ok, but http not 200.");
			}
		}
		
	} else {
			$np->nagios_exit(CRITICAL, "Could not connect to api");
	}
	
	auth("/servers/$content{id}");
	
	if ($response->is_success(204)) {
		$res = $response->content;

		if ($options->verbose) {
			print "/servers/$content{id} response content\n";
			print "$res\n";
		}
	
		$json_any = JSON::Any->new;
		$json_res = $json_any->from_json($res);
		
		$cpu_stat = $json_res->{server}->{vps_cpu_load};
		$mem_stat = $json_res->{server}->{vps_mem_load};
		$hdd_stat = $json_res->{server}->{vps_disk_load};
		
		if ($options->verbose) {
			print "CPU STAT - $cpu_stat%\n";
			print "MEM STAT - $mem_stat%\n";
			print "HDD STAT - $hdd_stat%\n";
		}
	} else {
			$np->nagios_exit(CRITICAL, "Could not connect to /servers/$content{id} api");
	}
	
}	




sub check_cpu_load {
		$cpu_stat = int($cpu_stat);
		if (defined $options->mcu && defined $options->wmcu) {
				my $mcu = $options->mcu;
				my $wmcu = $options->wmcu;
				die ("Critical value cannot be less max value\n") if ($mcu < $wmcu);										
				if ($cpu_stat >= $wmcu && $cpu_stat < $mcu) {
					$np->add_message(WARNING, "Warning cpu value - $cpu_stat");
				} elsif ($cpu_stat >= $mcu) {
					$np->add_message(CRITICAL, "CPU Critical - $cpu_stat");
				}
		} else {
			if ($cpu_stat >= 10 && $cpu_stat < 20) {
				$np->add_message(WARNING, "Warning cpu value - $cpu_stat");
			} elsif ($cpu_stat >= 20) {
				$np->add_message(CRITICAL, "CPU Critical - $cpu_stat");
			}
		}
}

sub check_mem_load {
		$mem_stat = int($mem_stat);
		
		if ($options->mm && $options->wmm) {
			
			my $mm = $options->mm;
			my $wmm = $options->wmm;
			die ("Critical value cannot be less max value\n") if ($mm < $wmm);
			
			if ($mem_stat >= $wmm && $mem_stat < $mm) {
				$np->add_message(WARNING, "Memory load warning - $mem_stat %\n");
			} elsif ($mem_stat >= $mm) {
				$np->add_message(CRITICAL, "Memory load critical - $mem_stat %\n");
			}
		} else {
			if ($mem_stat >= 60 && $mem_stat < 98) {
				$np->add_message(WARNING, "Memory load warning - $mem_stat %\n");
			} elsif ($mem_stat >= 98) {
				$np->add_message(CRITICAL, "Memory load critical - $mem_stat %\n");
			}
		}	
}


sub check_disk_load {
		
		if ($options->mhu && $options->wmhu) {
			my $mhu = $options->mhu;
			my $wmhu = $options->wmhu;
			
			die ("Critical value cannot be less max value\n") if ($mhu < $wmhu);
			
			if ($hdd_stat >= $wmhu && $hdd_stat < $mhu) {
				$np->add_message(WARNING, "Hdd usage warning - $hdd_stat %\n");
			} elsif ($hdd_stat >= $mhu) {
				$np->add_message(CRITICAL, "Hdd usage critical - $hdd_stat %\n");
			}
		} else {
			if ($hdd_stat >= 80 && $hdd_stat < 98) {
				$np->add_message(WARNING, "Memory load - $hdd_stat %\n");
			} elsif ($hdd_stat >= 99) {
				$np->add_message(CRITICAL, "Hdd usage critical - $hdd_stat %\n");
			}
		}		
}

sub check_balance {
	auth("/user/");

	if ($response->is_success(200)) {
		
		my $res = $response->content;
		my $json_any = JSON::Any->new;
		my $json_res = $json_any->from_json($res);
		my $balance_stat = $json_res->{user}->{users_balance};
		if ($options->verbose) {
			print $response->as_string;
			print "Account balance - $balance_stat" . " rur" . "\n";
		}
		
		if ($balance_stat < 0) {
			$np->add_message(CRITICAL, "Negative account balance.\n");
		}
		
	} else {
		$np->add_message(CRITICAL, "Could not connect to api url /user/ for balance_check");
	}
	
}



auth_api();



get_servers();


check_mem_load();

check_cpu_load();

check_disk_load();

if ($options->checkbalance) {
	check_balance();
}

=pod
if (@critical) {
    nagios_exit( CRITICAL, join(' ', @critical) );
  } elsif (@warning) {
    nagios_exit( WARNING, join(' ', @warning) );
  }
=cut
my ($code, $message) = $np->check_messages(join => '; ', join_all => ' ');

$np->nagios_exit(
				message => $message,
				return_code => $code,
);

