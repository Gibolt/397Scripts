#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-11-19 $

use strict;
use XML::SIMPLE;
use LWP::UserAgent;
use Data::Dumper;

my $ua = new LWP::UserAgent;
$ua->timeout(120); 
my $xs1 = XML::Simple->new();

queryMusicBrainz($ARGV[0], $ARGV[1], $ARGV[2]);

# sub fetch_title {
	# my $titleIn = $_[0];
	# $titleIn =~ s/%20|-|\s+/ /g;
	# $titleIn =~ s/&/%26/g;
	# my $mainUrl = "http://musicbrainz.org/ws/2/recording/?limit=1&query=";
	# my $queryUrl = $mainUrl.$titleIn;
	# print "Fetching data for file \"$titleIn\" to url \"$queryUrl\" :\n";
	# fetch_xml_page($queryUrl);
# }

sub queryMusicBrainz {
	my $titleIn = $_[0]; # Song Title
	# my $artist = $_[1] ? " AND artist:\"$_[1]\"" : ""; # Song Artist
	my $artist = $_[1] ? " AND artist:$_[1]" : ""; # Song Artist
	# my $album = $_[2] ? " AND album:\"$_[2]\"" : ""; # Song Album
	my $album = $_[2] ? " AND album:$_[2]" : ""; # Song Album
	if ($album =~ /\Q$titleIn/) {$album=""};
	$titleIn =~ s/%20|-|\s+/ /g;
	$titleIn =~ s/&/%26/g;
	my $mainUrl = "http://musicbrainz.org/ws/2/recording/?limit=1&query=";
	# my $queryUrl = $mainUrl."\"".$titleIn."\"".$artist.$album;
	my $queryUrl = $mainUrl.$titleIn.$artist.$album;
	print "Fetching data for file \"$titleIn\" to url \"$queryUrl\" :\n";
	return fetch_xml_page($queryUrl);
}

sub queryMusicBrainzAlbum {
	my $titleIn = $_[0]; # Song Title
	my $artist = $_[1] ? " AND artist:$_[1]" : ""; # Song Artist
	my $album = $_[2] ? "album:$_[2]" : ""; # Song Album
	if ($album =~ /\Q$titleIn/) {$album=""};
	$titleIn =~ s/%20|-|\s+/ /g;
	$titleIn =~ s/&/%26/g;
	my $mainUrl = "http://musicbrainz.org/ws/2/release/?limit=1&inc=recordings&query=";
	my $queryUrl = $mainUrl.$album.$artist;
	print "Fetching data for album \"$album\" to url \"$queryUrl\" :\n";
	return fetch_xml_page($queryUrl);
}

sub fetch_xml_page {
	my $xml_url = $_[0];
	my $request = new HTTP::Request('GET', $xml_url); 
	my $response = $ua->request($request);
	my $musicData = $response->content();
  
	print $musicData."\n";
	my $data = $xs1->XMLin($musicData);
	# print Dumper $data;
	# print "\n\n";
	print Dumper $data->{'recording-list'}->{'recording'};
	$data = $data->{'recording-list'}->{'recording'};
	
	my $recordingTitle = $data->{'title'};
	my $recordingId = $data->{'id'};
	
	my $artist = $data->{'artist-credit'}->{'name-credit'}->{'artist'};
	my $artistName = $artist->{'name'};
	my $artistId = $artist->{'id'};
	
	my $release = $data-> {'release-list'}->{'release'};
	my $releaseDate = $release->{'date'};
	my $releaseTitle = $release->{'title'};
	my $releaseId = $release->{'id'};
	my $releaseTrack = $release->{'medium-list'}->{'medium'}->{'track-list'}->{'track'}->{'number'};
	my $releaseTracks = $release->{'medium-list'}->{'track-count'};
	# my $releaseTrackTitle = $release->{'medium-list'}->{'medium'}->{'track-list'}->{'track'}->{'title'};
	my $releaseType = $release->{'id'};
}