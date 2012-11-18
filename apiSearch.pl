#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use JSON -support_by_pp;
use strict;
use LWP::Simple;
use Data::Dumper;
use IMDB::Film; # Needs to be installed with dependencies Cache::CacheUtils, Text::Unidecode, and Error

my $ua = new LWP::UserAgent;
my $apikey = "rfbnqr2xpkahkypty6m6r3ee";
$ua->timeout(120); 

for (my $i = 0; $i<$#ARGV+1; $i++) {
	print $ARGV[$i]."\n";
	fetch_title("$ARGV[$i]");
}

sub fetch_title {
	my $titleIn = $_[0];
	# $titleIn =~ s/%20/ /g;
	$titleIn =~ s/(%20|\s|-|_)+/ /g;
	# $titleIn =~ s/\s+/ /g;
	print $titleIn ;
	# Check out Thetvdb.com for tv shows
	my $mainUrl = "http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=".$apikey;
	# fetch_rt_page($mainUrl."&q="."$titleIn"."&page_limit=1");
	# fetch_imdb_page($titleIn);
}

sub fetch_rt_page {
	my ($json_url) = @_;
	my $request = new HTTP::Request('GET', $json_url); 
	my $response = $ua->request($request);
	my $movieData = $response->content();
  
	# print "Getting json $json_url\n\n";
	my $json = new JSON;
	my $data = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($movieData);

	print Dumper $data;
	if (($data -> {'total'}) > 0) {
		print $data -> {'movies'}[0] -> {'alternate_ids'} -> {'imdb'};
		print "\n";
			# Fetch movie posters
		# getstore($data -> {'movies'}[0] -> {'posters'} -> {'profile'}, "profile.jpg");
		# getstore($data -> {'movies'}[0] -> {'posters'} -> {'detailed'}, "detailed.jpg");
		# getstore($data -> {'movies'}[0] -> {'posters'} -> {'thumbnail'}, "thumbnail.jpg");
		# getstore($data -> {'movies'}[0] -> {'posters'} -> {'original'}, "original.jpg");
		fetch_imdb_page($data -> {'movies'}[0] -> {'alternate_ids'} -> {'imdb'});  
	}
}

sub fetch_imdb_page {
	my ($movieId) = @_;
	my $imdbObj = new IMDB::Film(crit => $movieId); 
  
	print Dumper $imdbObj;
	if($imdbObj->status) {
        print "\nTitle: ".$imdbObj->title()."\n";
        print "Year: ".$imdbObj->year()."\n";
        print "Plot Summary: ".$imdbObj->plot()."\n";
	} else {
		print "Something wrong: ".$imdbObj->error;
	}
}