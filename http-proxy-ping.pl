#!/usr/bin/perl
#
# Program: HTTP PROXY PING 0.3 <http-proxy-ping.pl>
#
# Author: Borja Burgos-Galindo < bburgosg at andrew dot cmu dot edu >
#
# Current Version: 0.3
#
# Revision History:
# 
# Version 0.3
#  Added rudimentary basic error handling for HTTP requests
# Version 0.2
#  Added support for Average Latency
#
# Requirements:
#  Installation of module LWP::Protocol::socks
# 
# Purpose:
#  Reports latency of HTTP HEAD/GET requests to a webserver with support for HTTP/SOCKS proxies
#
# Known bugs:
#  Cache is not taken into consideration 
#
# License:
# Copyright © 2011 Borja Burgos-Galindo
#
#
# Usage: http-proxy-ping.pl 
#  -u URL   	 		(ie. http://www.example.com) 
#  -p proxy 		 	(ie. localhost:8080) 
#  -t proxytype 		{socks, http, none} 
#  -r request_type 	 	{head, get} 
#  -v 			 		verbose mode, prints html data from HTTP GET requests 
#  -d seconds 		 	delay time between requests 
#  -n number 		 	number of requests to be sent 
#  -h 			 		this help 
# 
# Example:
#  ./http-proxy-ping.pl -u http://www.cmu.edu -n 2 -d 5 -p localhost:8118 -t http -r head
#	Issuing 2 HTTP HEAD requests to http://www.cmu.edu every 5 seconds using proxy http://localhost:8118 :
#	Sun Dec  4 14:59:42 2011: Request #1 Latency = 8.374s 
#	Sun Dec  4 14:59:47 2011: Request #2 Latency = 0.007s 
# 	Average Latency = 4.190s 

####################################
# Required modules				   #
####################################
use Net::HTTP;
use Time::HiRes qw (time);
use Getopt::Std;
use LWP::UserAgent;

####################################
# Get the parameters from the user #
####################################
%options=();
getopts("d:hvp:u:t:r:n:",\%options);
my $delay = defined($options{d}) ? $options{d} : 5;
my $proxy = defined($options{p}) ? $options{p} : "localhost:8118";
my $server = defined($options{u}) ? $options{u} : "http://www.cmu.edu";
my $proxytype = defined($options{t}) ? $options{t} : "none";
my $reqtype = defined($options{r}) ? $options{r} : "head";
my $repetitions = defined($options{n}) ? $options{n} : 3;

if (defined $options{h} ) {
printf("\n HTTP PROXY PING 0.3 - Tool created by Borja Burgos-Galindo < bburgosg at andrew dot cmu dot edu > for CMU INI course 14-741\n");
printf("\n Usage: http-proxy-ping.pl \n -u URL \t\t (ie. http://www.example.com) \n -p proxy \t\t (ie. localhost:8080) \n -t proxytype \t\t {socks, http, none} \n -r request_type \t {head, get} \n -v \t\t\t verbose mode, prints html data from HTTP GET requests \n -d seconds \t\t delay time between requests \n -n number \t\t number of requests to be sent \n -h \t\t\t this help \n\n");
exit(1);
}
#######################################
# Let the user know what we are doing #
#######################################

printf("Issuing $repetitions HTTP" . " \U$reqtype " . "requests to $server every $delay seconds ");
if ($proxytype ne "none") {
	printf("using proxy $proxytype://$proxy :\n");
	}
else {printf("not using any proxy:\n")};

#######################################
# Setup UA and check for err. input   #
#######################################
my $ua = LWP::UserAgent->new(
  agent => q{Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.51.22 (KHTML, like Gecko) Version/5.1.1 Safari/534.51.22},
);

if ($proxytype eq "http"){
	$ua->proxy(['http'], "http://$proxy");
} elsif ($proxytype eq "socks") {
	$ua->proxy([qw/ http https /] => "socks://$proxy"); # Tor proxy
	} elsif ($proxytype ne "none") {	
		printf("Invalid proxy type.\n");
		exit(1);
		}
		
my $sum = 0;		
#my $cache = LWP::ConnCache->new;

for ($count = $repetitions; $count >= 1; $count--)
{
#	$cache->prune
	my $start = time();
	my $rsp = $ua->$reqtype($server);
 
#######################################
# Check for content return errors	  #
#######################################
	 if($rsp->content =~ m/500 Can't connect to/ || $rsp->content =~ m/500 write failed/ ) { 
		 printf ("Error: can't connect to $proxytype://$proxy\n"); 
		 exit(-1);
	 } elsif ($rsp->content =~ m/Tor is not an HTTP Proxy/) { 
		 printf ("Error: can't use SOCKS proxy as HTTP proxy\n"); 
		 exit(-1);
		 } elsif ($rsp->content =~ m/400 URL must be absolute/) { 
		 	printf ("Error: URL must be absolute (ie. http://www.example.com\n"); 
		 	exit(-1);
		 	} elsif ($rsp->content =~ m/501 Protocol scheme/) { 
		 		printf ("Error: Protocol scheme not supported\n"); 
		 		if($proxytype eq "socks") {
		 		printf("You may be need to install module LWP::Protocol::socks\n");
		 		}
		 		exit(-1);
		 		} elsif ($rsp->content =~ m/500 No Host option provided/) { 
		 		printf ("Error: No Host option provided\n"); 
		 		exit(-1);
		 		}

#######################################
# Verbos Mode: Print Contents		  #
#######################################
	 if (defined $options{v} and $reqtype eq "get") {
 		print $rsp->content . "\n";
 	} elsif (defined $options{v} and $reqtype eq "head") {
 		printf("Verbose mode does not return additional data when request type is HEAD\n");
 		}

#######################################
# Calculate and print time  		  #
#######################################
	 my $httpConnectionTime = time() - $start;
	 my $dt = scalar localtime time;
	 $sum = $sum + $httpConnectionTime;
	 printf("%s: Request #" . ($repetitions - $count + 1) . " Latency = %.3fs \n", $dt, $httpConnectionTime);
	 
#######################################
# Sleep until next request  		  #
#######################################
	if($count > 1) {
		sleep($delay);
		} else { 
			printf("Average Latency = %.3fs \n", ($sum/$repetitions));
			}
}





