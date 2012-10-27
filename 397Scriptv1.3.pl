#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use JSON -support_by_pp;
use strict;
use LWP::UserAgent;
use Data::Dumper;

my $ua = new LWP::UserAgent;
my $apikey = "rfbnqr2xpkahkypty6m6r3ee";
$ua->timeout(120); 

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
	# Check out Thetvdb.com for tv shows
	my $mainUrl = "http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=".$apikey;
	fetch_json_page($mainUrl."&q="."$titleIn"."&page_limit=1");
}

sub fetch_json_page {
	my ($json_url) = @_;
	my $request = new HTTP::Request('GET', $json_url); 
	my $response = $ua->request($request);
	my $movieData = $response->content();
  
	print "Getting json $json_url\n\n";
	my $json = new JSON;
	my $data = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($movieData);

	print Dumper $data;
	# print keys $data;
	# print $data->{'Title'}."\n";
	# print $data->{'Year'}."\n";
	
	# my $title = $data->{'Title'};
	# my $year = $data->{'Year'};
	# my $released = $data->{'Released'};
	# my $genre = $data->{'Genre'};
	# my $actors = $data->{'Actors'};
	# my $director = $data->{'Director'};
	# my $rating = $data->{'Rated'};
	# my $writer = $data->{'Writer'};
	# my $runtime = $data->{'Runtime'};
	# my $plot = $data->{'Plot'};
	# my $imdb = $data->{'imdbID'};
	# my $votes = $data->{'imdbVotes'};
	# my $poster = $data->{'Poster'};
	# my $rated = $data->{'Rated'};
	
	# print $votes;
  
}