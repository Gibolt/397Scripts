#!/usr/bin/perl -w
# $Rev: 11 $
# $Author: artem $
# $Date: 2009-05-23 23:09:47 -0700 (Sat, 23 May 2009) $

# http://beerpla.net/2008/03/27/parsing-json-in-perl-by-example-southparkstudioscom-south-park-episodes/
 
# use WWW::Mechanize;
use JSON -support_by_pp;
use strict;
# use LWP::Simple;
use LWP::UserAgent;
use Data::Dumper;

# my $titleIn="Avatar";
# if ($argv[0]) $titleIn=$argv[0];
my $ua = new LWP::UserAgent;
$ua->timeout(120); 
#fetch_json_page("http://www.omdbapi.com/?i=&t=Avatar");

for (my $i = 0; $i<$#ARGV+1; $i++) {
	 print $ARGV[$i]."\n";
	fetch_title($ARGV[$i]);
}

sub fetch_title
{
	my $titleIn = @_;
	my $url = "http://www.omdbapi.com/?i=&t=".$titleIn;
	fetch_json_page($url);
}

sub fetch_json_page
{
	my ($json_url) = @_;
	# my $browser = WWW::Mechanize->new();
	# my $cmd = "curl $json_url";
	my $request = new HTTP::Request('GET', $json_url); 
	my $response = $ua->request($request);
	my $movieData = $response->content();
	# my $movieData = system($cmd);
	print $movieData."\n\n"; #stringReturned
  
	# download the json page:
	print "Getting json $json_url\n\n";
	# $browser->get( $json_url );
	# my $content = $browser->content();
	my $json = new JSON;
	print $json."\n\n";
	# these are some nice json options to relax restrictions a bit:
	my $data = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($movieData);

	# my $title = escapeSingleQuote($data->{"Title"});
	# my $year = escapeSingleQuote($data->{Year});
	# my $rated = escapeSingleQuote($data->{Rated});
	# print $title.$year.$rated;
	print Dumper $data;
	print keys $data;
	print $data->{'Title'}."\n";
	print $data->{'Year'}."\n";
	
	my $title = $data->{'Title'};
	my $year = $data->{'Year'};
	my $released = $data->{'Released'};
	my $genre = $data->{'Genre'};
	my $actors = $data->{'Actors'};
	my $director = $data->{'Director'};
	my $rating = $data->{'Rated'};
	my $writer = $data->{'Writer'};
	my $runtime = $data->{'Runtime'};
	my $plot = $data->{'Plot'};
	my $imdb = $data->{'imdbID'};
	my $votes = $data->{'imdbVotes'};
	my $poster = $data->{'Poster'};
	my $rated = $data->{'Rated'};
	
	print $votes;
  
}