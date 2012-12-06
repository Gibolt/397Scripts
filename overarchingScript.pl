#!/usr/bin/perl -s 
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use Cwd;
use Image::ExifTool qw(:Public); # Needs to be installed
# use Music::Tag; # Needs to be installed, DateTimeX::Easy, DateTime::Format::Natural, boolean, DateTime::Format::Flexible, DateTime::Format::Builder, Class::Factory::Util, DateTime::Format::Strptime
use JSON -support_by_pp;
use strict;
use LWP::Simple;
use Data::Dumper;
use IMDB::Film;
use WebService::TVDB;
use XML::Simple;
# use DBI;

open (SQL, '>>sql.sql');

my @videoTypes = ("avi","mp4","mkv","mov","wmv","flv");
my %videoTypesMap = map { $_ => 1 } @videoTypes;
my @audioTypes = ("wav","mp3","flac","midi","aac","m4a","mp4","ogg");
my %audioTypesMap = map { $_ => 1 } @audioTypes;
my @imageTypes = ("gif","jpg","jpeg","png","ico","bmp");
my %imageTypesMap = map { $_ => 1 } @imageTypes;
my @acceptedTypes = (@videoTypes,@audioTypes,@imageTypes);
my %acceptedTypesMap = map { $_ => 1 } @acceptedTypes;
my $rtApiKey = "rfbnqr2xpkahkypty6m6r3ee";
my $tvdbApiKey = '064C9518B1E8731B';
my $ua = new LWP::UserAgent;
$ua->timeout(120); 
my $xs1 = XML::Simple->new();
my $localProgram;

my $db_user  = "sa";
my $db_pass  = "";
my $dsn_name = 'dbi:ODBC:data\\MediaData';

if ($#ARGV+1>=1) {
	chdir($ARGV[1]);
	$localProgram = $ARGV[0];
	my $currentDir= $ARGV[1] =~ /\/?([^\/]*)\/([^\/]*)$/;
	&ScanDirectory($ARGV[1]);
}
else {
	chdir(".");
	&ScanDirectory(".");
}

# This function takes the name of a directory and recursively scans down the filesystem hierarchy
sub ScanDirectory {
	my $workdir = shift; 
	my $parentFolder = shift;
	chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
	my $startdir = &cwd; # keep track of where we began 
	print "Entered directory: $workdir\n";

	opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
	my @names = readdir(DIR) or die "Unable to read $workdir:$!\n";
	closedir(DIR); 
	my $xmlData;
	my $count=0;
	my $tvInfo;
	foreach my $name (@names){ 
		next if ($name eq "."); 
		next if ($name eq ".."); 
		if (-d $name){ 		# Is the given name a directory?
			print  "Found directory:   $name in $workdir!\n"; 
			my $parentFolder;
			&ScanDirectory($name, $workdir, $parentFolder); 
			next; 
		}
		elsif (-f $name) {	# Is the given name a file?
			my $info = ImageInfo($name);
			#print "FileType => $$info{'FileType'}\n";
			my $ext = '';
			my $filenameExt;
			if ($info->{'FileType'}) {
				$ext = lc($info->{'FileType'});
			}
			if ($name =~ /\.([^.]+)$/) {
				$filenameExt = lc($1);
				if (not $ext) {$ext = lc($1);}
			}
			# my $fullPath = $startdir.'/'.$workdir.'/'.$name;  # TODO: Not currently used. Will be for unique database id
			my $fullPath = $startdir.'/'.$name;
			$name = substr($name,0,rindex($name,$ext)-1);
			my $filename = $name =~ s/[\s\.\_\-\[\]\\\/]+/ /g;
			my $insertIntoFileTableString;
			my $insertIntoImageTableString;
			my $insertIntoMovieTableString;
			my $insertIntoSongTableString;
			my $insertIntoTvEpisodeTableString;
			my $insertIntoAudioFileDetailsTableString;
			my $insertIntoVideoFileDetailsTableString;
			my $insertIntoPosterTableString;
			my $determinedType="O";
			# my $insertIntoMovieDetailsTableString;
			# my $insertIntoRTSearchTableString;
			if(exists($acceptedTypesMap{$ext})) {
				print "Found acceptable media file: $name in $workdir!\n";
				if(exists($videoTypesMap{$ext})) {
					print "\nAnalyzing Video File - $name\n";
					my $episodeNum;
					my $seasonNum;
					my $success;
					if ($workdir =~ /((season|s)?[\s\.\_\-\[\]\\\/]*(\d+)[\s\.\_\-\[\]\\\/]*(episode|ep|e)?[\s\.\_\-\[\]\\\/]*(\d*))/i) {
						$seasonNum = $3;
						$episodeNum = $5;
					}
					elsif ($parentFolder =~ /((season|s)?[\s\.\_\-\[\]\\\/]*(\d+)[\s\.\_\-\[\]\\\/]*(episode|ep|e)?[\s\.\_\-\[\]\\\/]*(\d*))/i) {
						$seasonNum = $3;
						$episodeNum = $5;
					}
					if (not $episodeNum) { 
						if ($name =~ /((season|s)?[\s\.\_\-\[\]\\\/0]*(\d+)[\s\.\_\-\[\]\\\/]*(episode|ep|e)?[\s\.\_\-\[\]\\\/0]*(\d*))/i) {
							$episodeNum = $5; 
							if (not $seasonNum) {
								$seasonNum = $3;
							}
						}
					}
					if ($seasonNum) {
						my $title; 
						my $endFileName;
						if ($name =~ /((season|s)?[\s\.\_\-\[\]\\\/]*(\d+)[\s\.\_\-\[\]\\\/]*(episode|ep|e)?[\s\.\_\-\[\]\\\/]*(\d*))/i) {
							$title = substr($name,0,rindex($name,$1));
							$endFileName = substr($name,rindex($name,$1)+length($1));
						} else {
							$title = $name;
						}
						if (not $tvInfo) {
							my $tvdb = WebService::TVDB->new(api_key => $tvdbApiKey, language => 'English', max_retries => 10);
							my $series_list = $tvdb->search($title);
							my $series = @{$series_list}[0];
							if ($series) {
								$series->fetch();
								$tvInfo = $series;
							}
						}
						if ($tvInfo) {
							$success = 1;
							my $showName = $tvInfo->{'SeriesName'};
							my $showOverview = $tvInfo->{'Overview'};
							my $showRating = $tvInfo->{'Rating'};
							my $showAired = $tvInfo->{'FirstAired'};

							my $episodeInfo;
							for my $episode (@{ $tvInfo->episodes }){
								if ($episode->{'SeasonNumber'} == $seasonNum
								 && $episode->{'EpisodeNumber'} == $episodeNum ) {
									$episodeInfo = $episode;
									last;
								}
							}
							my $episodeName;my $episodeId;my $episodeRating;my $episodeOverview;my $episodeAired;my $episodeImage;
							if ($episodeInfo->{'EpisodeName'}) {$episodeName=$episodeInfo->{'EpisodeName'};}
							if ($episodeInfo->{'id'}) {$episodeId=$episodeInfo->{'id'};}
							if ($episodeInfo->{'Rating'}) {$episodeRating=$episodeInfo->{'Rating'};}
							if ($episodeInfo->{'Overview'}) {$episodeOverview=$episodeInfo->{'Overview'};}
							if ($episodeInfo->{'FirstAired'}) {$episodeAired=$episodeInfo->{'FirstAired'};}
							if ($episodeInfo->{'filename'}) {
								$episodeImage=$episodeInfo->{'filename'};
								getstore("http://thetvdb.com/banners/".$episodeImage, $localProgram."/images/$episodeId"."Clip.jpg");
							}
							$episodeOverview =~ s/\'/\\'/g;
							$episodeName =~ s/\'/\\'/g;
							
							$insertIntoTvEpisodeTableString = "Insert into TvEpisode Values('$fullPath','$seasonNum','$episodeNum',
									'$episodeId','$episodeName','$episodeRating','$episodeAired','$episodeOverview','$episodeImage');";
							print "Show:$showName+Episode:$episodeName+S$seasonNum E$episodeNum\n";
							$determinedType = "T";
						}
					}
					if (not $success) { 	# Search as if it is a movie using Rotten Tomatoes
						# Check out Thetvdb.com for tv shows
						$name =~ s/(%20|\s|-|_)+/ /g;
						my $mainUrl = "http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=".$rtApiKey;
						my $json_url = $mainUrl."&q="."$name"."&page_limit=1";
						my $response = $ua->request(new HTTP::Request('GET', $json_url));
						my $movieData = $response->content();
					  
						my $json = new JSON;
						my $data = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($movieData);			
						if (($data -> {'total'}) > 0) {
							$success = 1;
							$data = $data->{'movies'}[0];
							
							print "Successfully connected to movie information for $name\n";
							$determinedType = "M";
							my $title;my $year;my $rtid;my $imdbid;my $mpaaRating;my $posterUrl;
							if ($data->{'title'}) {$title=$data->{'title'};}
							if ($data->{'year'}) {$year=$data->{'year'};}
							if ($data->{'id'}) {$rtid=$data->{'id'};}
							if ($data->{'alternate_ids'}) {if ($data->{'alternate_ids'}->{'imdb'}) {$imdbid=$info->{'alternate_ids'}->{'imdb'};}}
							if ($data->{'mpaa_rating'}) {$mpaaRating=$data->{'mpaa_rating'};}
							my $posterProfile;my $posterThumb;my $posterDetailed;my $posterOriginal;
							if ($data->{'posters'}) {
								if ($data->{'posters'}->{'detailed'})  {$posterDetailed=$data->{'posters'}->{'detailed'};}
								if ($data->{'posters'}->{'original'})  {$posterOriginal=$data->{'posters'}->{'original'};}
								if ($data->{'posters'}->{'thumbnail'}) {$posterThumb=$data->{'posters'}->{'thumbnail'};}
								if ($data->{'posters'}->{'profile'})   {$posterProfile=$data->{'posters'}->{'profile'};}
								$posterUrl=$rtid."Thumb.jpg";
								getstore($posterThumb, $localProgram."/images/".$posterUrl);
								print "\n".$localProgram."/images/".$posterUrl."\n";
								$insertIntoPosterTableString = "Insert Into Poster Values('$fullPath','$title',$year,'$posterDetailed','$posterOriginal','$posterThumb','$posterProfile');";
							}
							$insertIntoMovieTableString = "Insert Into Movie Values('$fullPath','$title',$year,'$rtid','$imdbid','$mpaaRating');";
						}
					}
					if (not $success) { 	# Failed to recognize as TV or Movie
						print "Failed to process video file : $filename\n$success\n";
						$determinedType = "V";
					}
					my $duration;my $width;my $height;my $codec;my $audioRate;my $audioEncoding;my $frameRate;
					if ($info->{'Duration'}) {$duration=$info->{'Duration'};}
					if ($info->{'ImageHeight'}) {$width=$info->{'ImageHeight'};}
					if ($info->{'ImageWidth'}) {$height=$info->{'ImageWidth'};}
					if ($info->{'VideoCodec'}) {$codec=$info->{'VideoCodec'};}
					if ($info->{'AudioSampleRate'}) {$audioRate=$info->{'AudioSampleRate'};}
					if ($info->{'Encoding'}) {$audioEncoding=$info->{'Encoding'};}
					if ($info->{'FrameRate'}) {$frameRate=$info->{'FrameRate'};}
					$insertIntoVideoFileDetailsTableString = "Insert Into VideoFileDetails Values ('$fullPath','$duration',$width,$height,'$codec',$audioRate,'$audioEncoding','$frameRate');";
				}
				elsif(exists($audioTypesMap{$ext})) {
					print "\nAnalyzing Audio File - $name\n";
					my $songTitle = $info->{"Title"};
					if (not $songTitle) {$songTitle = $name;}
					my $songArtist = $info->{"Artist"};
					my $songAlbum = $info->{"Album"};
					print "Title,Artist,Album",$songTitle, $songArtist, $songAlbum;

					if ($songAlbum =~ /\Q$songTitle/) {$songAlbum="";}
					$songTitle =~ s/%20|-|\s+/ /g;
					$songTitle =~ s/&/%26/g;
					my $queryUrl = "http://musicbrainz.org/ws/2/recording/?limit=1&query=";
					$queryUrl .= "recording:\"$songTitle\"";
					if ($songArtist) {$queryUrl.= " AND artist:\"songArtist\"";}
					if ($songAlbum) {$queryUrl.= " AND album:\"songAlbum\"";}
					print "Fetching data for file \"$songTitle\" to url \"$queryUrl\" :\n";

					my $request = new HTTP::Request('GET', $queryUrl); 
					my $response = $ua->request($request);
					my $musicData = $response->content();
				  
					my $data = $xs1->XMLin($musicData);
					if ($data->{'recording-list'}->{'count'} > 0) {
						$data = $data->{'recording-list'}->{'recording'};
						
						my $recordingTitle = $data->{'title'};
						my $recordingId = $data->{'id'};
						
						my $artist; my $artistName; my $artistId;
						if($data->{'artist-credit'}) {if ($data->{'artist-credit'}->{'name-credit'}) {if ($data->{'artist-credit'}->{'name-credit'}->{'artist'}) {$artist=$data->{'artist-credit'}->{'name-credit'}->{'artist'};}}}						
						if($artist) {
							if($artist->{'name'}) {$artistName = $artist->{'name'};}
							if($artist->{'id'})   {$artistId   = $artist->{'id'};}
						}
						
						my $release = $data-> {'release-list'}->{'release'};
						my $releaseDate = $release->{'date'};
						my $releaseTitle = $release->{'title'};
						my $releaseId = $release->{'id'};
						my $releaseTrack = $release->{'medium-list'}->{'medium'}->{'track-list'}->{'track'}->{'number'};
						my $releaseTracks = $release->{'medium-list'}->{'track-count'};
						my $releaseType = $release->{'id'};
						$insertIntoSongTableString = "Insert into Song Values('$recordingTitle','$artistName','$releaseDate',
														'$fullPath','$releaseTitle','$releaseTrack');";
						$determinedType = "S"; # If song
					}
					else {
						$determinedType = "A"; # If audio
					}
					my $bitRate;my $audioLayer;my $channelMode;my $sampleRate;my $duration;
					if ($info->{'AudioBitrate'}) {$bitRate=$info->{'AudioBitrate'};}
					if ($info->{'AudioLayer'}) {$audioLayer=$info->{'AudioLayer'};}
					if ($info->{'ChannelMode'}) {$channelMode=$info->{'ChannelMode'};}
					if ($info->{'SampleRate'}) {$sampleRate=$info->{'SampleRate'};}
					if ($info->{'Duration'}) {$duration=$info->{'Duration'};}
					$insertIntoAudioFileDetailsTableString = "Insert Into AudioFileDetails Values ('$fullPath','$bitRate','$audioLayer','$channelMode',$sampleRate,'$duration');";
				
				}
				elsif(exists($imageTypesMap{$ext})) {
					print "\nAnalyzing Image File - $name\n";
					my $interlace;my $imageHeight;my $imageWidth;my $imageSize;my $colorType;my $bitDepth;my $gamma;
					if ($info->{'Interlace'}) {$interlace=$info->{'Interlace'};}
					if ($info->{'ImageHeight'}) {$imageHeight=$info->{'ImageHeight'};}
					if ($info->{'ImageWidth'}) {$imageWidth=$info->{'ImageWidth'};}
					if ($info->{'ImageSize'}) {$imageSize=$info->{'ImageSize'};}
					if ($info->{'ColorType'}) {$colorType=$info->{'ColorType'};}
					if ($info->{'BitDepth'}) {$bitDepth=$info->{'BitDepth'};}
					if ($info->{'Gamma'}) {$gamma=$info->{'Gamma'};}
					$determinedType = "I";
					$insertIntoImageTableString = "Insert Into Image Values ('$fullPath','$interlace',$imageHeight,$imageWidth,'$imageSize','$colorType','$bitDepth','$gamma');";
				}
			}
			else {
				print "Found unmatched file:        $name in $workdir!\n";
			}
			$insertIntoFileTableString = "Insert into File ('$fullPath','$name',
			'$determinedType','".$info->{'filesize'}."','$ext','$filenameExt');";
			# my $insertIntoOwnsTableString = "Insert into Owns ('$fullPath','$userName',
			# 0,'',False,False,-1)";
			
			print SQL "-- Submit file $fullPath\n";
			if ($insertIntoFileTableString) {print SQL $insertIntoFileTableString."\n";}
			if ($insertIntoImageTableString) {print SQL $insertIntoImageTableString."\n";}
			if ($insertIntoMovieTableString) {print SQL $insertIntoMovieTableString."\n";}
			if ($insertIntoSongTableString) {print SQL $insertIntoSongTableString."\n";}
			if ($insertIntoTvEpisodeTableString) {print SQL $insertIntoTvEpisodeTableString."\n";}
			if ($insertIntoAudioFileDetailsTableString) {print SQL $insertIntoAudioFileDetailsTableString."\n";}
			if ($insertIntoVideoFileDetailsTableString) {print SQL $insertIntoVideoFileDetailsTableString."\n";}
			if ($insertIntoPosterTableString) {print SQL $insertIntoPosterTableString."\n";}
			print SQL "\n\n";
		}
		else {				# Is the given name something else?
			print "Found some unknown file:     $name\n";
		}
	}
	print "Exiting directory: $workdir\n";
	chdir("..") or die "Unable to change to dir $startdir:$!\n"; 
}
 
 close (SQL);
 unlink("sqllock");