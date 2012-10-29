#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-10-29 $

use strict;
use XML::SIMPLE;
use LWP::UserAgent;
use Data::Dumper;

my $ua = new LWP::UserAgent;
$ua->timeout(120); 
my $xs1 = XML::Simple->new();

for (my $i = 0; $i<$#ARGV+1; $i++) {
	print $ARGV[$i]."\n";
	fetch_title("$ARGV[$i]");
}

sub fetch_title {
	my $titleIn = $_[0];
	$titleIn =~ s/%20|-/ /g;
	# $titleIn =~ s/-/ /g;
	$titleIn =~ s/\s+/ /g;
	my $mainUrl = "http://musicbrainz.org/ws/2/work/?limit=1&query=";
	my $queryUrl = $mainUrl.$titleIn;
	print "Fetching data for file \"$titleIn\" to url \"$queryUrl\" :\n";
	fetch_xml_page($queryUrl);
}

sub fetch_xml_page {
	my $xml_url = $_[0];
	my $request = new HTTP::Request('GET', $xml_url); 
	my $response = $ua->request($request);
	my $musicData = $response->content();
  
	print $musicData."\n";
	my $data = $xs1->XMLin($musicData);

	print "\nKeys at each step:\n";
	print keys $data;
	print "\n";# print $data->{'Title'}."\n";
	print keys $data->{'work-list'};# print $data->{'Title'}."\n";
	print "\n";
	print keys $data->{'work-list'}->{'work'};
	print "\n";
	print Dumper $data->{'work-list'}->{'work'};
	print "\n";
	# print $data->{'Year'}."\n";
}