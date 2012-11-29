# Matching TV Show Season Directory

# Ex. foo.s01[]...._ \/   --e1hh
#use TVDB::API;		#add TVDB::API, Debug::Simple, DBM::Deep
use WebService::TVDB; # add WebService::TVDB, Object::Tiny
use Data::Dumper;
use IMDB::Film;
$tvdbApiKey = '064C9518B1E8731B';
# $tvdb = TVDB::API::new("064C9518B1E8731B");
# $tvdb = TVDB::API::new({ apikey    => "064C9518B1E8731B",
                           # lang      => 'en',
                           # cache     => 'filename',
                           # banner    => 'banner/path',
                           # useragent => 'My useragent'
                        # });
# my $tvdb = TVDB::API::new([["064C9518B1E8731B"], "en"]);
  # $tvdb->setApiKey($apikey);
  # $tvdb->setLang('en');
  # $tvdb->setUserAgent("TVDB::API/$VERSION");
  # $tvdb->setBannerPath("/foo/bar/banners");
  # $tvdb->setCacheDB("$ENV{HOME}/.tvdb.db");
# $tvdb->setApiKey("064C9518B1E8731B");



for (my $i = 0; $i<$#ARGV+1; $i++) {
	checkTv("$ARGV[$i]");
	theTvDbInfo("$ARGV[$i]");
}

sub checkTv {
	print $ARGV[$i]."\n";
	my $title = $_[0];
	# if ($title =~ /(season|s)?[\s\.\_\-\[\]]*(\d+)[\s\.\_\-\[\]]*(episode|ep|e)?[\s\.\_\-\[\]](\d*)/i) {
	if ($title =~ /(season|s)?[\s\.\_\-\[\]\\\/]*(\d+)[\s\.\_\-\[\]\\\/]*(episode|ep|e)?[\s\.\_\-\[\]\\\/]*(\d*)/i) {
		print "Title matches: $title\n";
		print "Season number: $2\n";
		if ($3) {
			# print "Episode number: $3\n";
			print "Episode number: $4\n";
		}
	}
}

#http://search.cpan.org/~behanw/TVDB-API-0.33/lib/TVDB/API.pm
sub theTvDbInfo {
	my $tvdb = WebService::TVDB->new(api_key => $tvdbApiKey, language => 'English', max_retries => 10);
	my $title = $_[0];
	#my $series = $tvdb->getSeriesAll($title);
	my $series_list = $tvdb->search($title);
	# Dumper($series_list);
	my $series = @{$series_list}[0];
	print Dumper($series);
	CORE::say $series->SeriesName;
	CORE::say $series->Overview;
	$series->fetch();
	# CoverArt is 'http://thetvdb.com/banners/'.$series->{'filename'};
	print Dumper($series);
	
	
	CORE::say $series->Rating;
	CORE::say $series->Status;
	
	fetchImdbTvData( $series->{'IMDB_ID'});
	
	# for my $episode (@{ $series->episodes }){
	  # # $episode is a WebService::TVDB::Episode
	  # CORE::say $episode->Overview;
	  # CORE::say $episode->FirstAired;
	# }
}

sub fetchImdbTvData {
	my ($movieId) = @_;
	print $movieId;
	my $imdbObj = new IMDB::Film(crit => $movieId); 
  
	print Dumper $imdbObj;
	while( my ($k) = each %$imdbObj ) {
        print "key: $k\n";
    }
	if($imdbObj->status) {
        print "\nTitle: ".$imdbObj->title()."\n";
        print "Year: ".$imdbObj->year()."\n";
        print "Plot Summary: ".$imdbObj->plot()."\n";
	} else {
		print "Something wrong: ".$imdbObj->error;
	}
}

sub fetchDetails {
	my $imdbObj = $_;
	my $duration = $imdbObj->duration();
	$duration =~ /(\d+)\s*episodes/;
	print $duration."\n";
	# my $cast = $imdbObj->cast[0];
	# for	
}