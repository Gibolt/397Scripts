#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use XML::SIMPLE;
use strict;
use LWP::UserAgent;
use Data::Dumper;


my $file = 'files/camelids.xml';


# foreach my $key (keys (%{$doc->{species}})){
   # print $doc->{species}->{$key}->{'common-name'} . ' (' . $key . ') ';
   # print $doc->{species}->{$key}->{conservation}->final . "\n";
# }
my $ua = new LWP::UserAgent;
$ua->timeout(120); 
my $xs1 = XML::Simple->new();

for (my $i = 0; $i<$#ARGV+1; $i++) {
	print $ARGV[$i]."\n";
	fetch_title("$ARGV[$i]");
}

sub fetch_title {
	my $titleIn = $_[0];
	print $titleIn;
	$titleIn =~ s/%20/ /g;
	$titleIn =~ s/-/ /g;
	$titleIn =~ s/\s+/ /g;
	print $titleIn;
	my $mainUrl = "http://musicbrainz.org/ws/2/work/?query=";
	fetch_xml_page($mainUrl.$titleIn."&limit=1");
}

sub fetch_xml_page {
	my $xml_url = $_[0];
	my $request = new HTTP::Request('GET', $xml_url); 
	my $response = $ua->request($request);
	my $musicData = $response->content();
  
	# if ($musicData =~ m/(<work> .*<work)/) {
		# my $reduced = $1;
		# print "\n--".$reduced."--\n";
	# }
	print "Getting xml $xml_url\n\n";
	print $musicData."\n";
	my $data = $xs1->XMLin($musicData);
	# my $data = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($movieData);

	print Dumper $data."\n";
    # print $data->{'work'};#->{'title'} . ' (' . $key . ') ';
	# foreach my $key (keys (%{$data->{'work-list'}})){
		# print $key."\n";
	    # print $data->{'species'}->{$key}->{'conservation'}->final . "\n";
	# }
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