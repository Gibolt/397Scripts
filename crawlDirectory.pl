#!/usr/bin/perl -s 
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use Cwd;
use Image::ExifTool qw(:Public); # Needs to be installed
use Music::Tag; # Needs to be installed, DateTimeX::Easy, DateTime::Format::Natural, boolean, DateTime::Format::Flexible, DateTime::Format::Builder, Class::Factory::Util, DateTime::Format::Strptime
@videoTypes = ("avi","mp4","mkv","mov","wmv","flv");
%videoTypesMap = map { $_ => 1 } @videoTypes;
@audioTypes = ("wav","mp3","flac","midi","aac","m4a","mp4","ogg");
%audioTypesMap = map { $_ => 1 } @audioTypes;
@imageTypes = ("gif","jpg","jpeg","png","ico","bmp");
%imageTypesMap = map { $_ => 1 } @imageTypes;
@acceptedTypes = (@videoTypes,@audioTypes,@imageTypes);
%acceptedTypesMap = map { $_ => 1 } @acceptedTypes;

if (1>=$#ARGV+1) {
	chdir($ARGV[0]);
	my $currentDir= $ARGV =~ /\/?([^\/]*)\/([^\/]*)$/;
	&ScanDirectory($ARGV[0]);
}
else {
	chdir(".");
	&ScanDirectory(".");
}

# This function takes the name of a directory and recursively scans down the filesystem hierarchy
sub ScanDirectory {
	my ($workdir) = shift; 
	chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
	my ($startdir) = &cwd; # keep track of where we began 
	print "Entered directory: $workdir\n";

	opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
	my @names = readdir(DIR) or die "Unable to read $workdir:$!\n";
	closedir(DIR); 
	my $xmlData;
	my $count=0;
	foreach my $name (@names){ 
		next if ($name eq "."); 
		next if ($name eq ".."); 
		if (-d $name){ 		# Is the given name a directory?
			print  "Found directory:   $name in $workdir!\n"; 
			&ScanDirectory($name); 
			next; 
		}
		elsif (-f $name) {	# Is the given name a file?
			my $info = ImageInfo($name);
			my $ext = '';
			if ($info->{'FileType'}) {
				$ext = lc($info->{'FileType'});
			}
			elsif ($name =~ /\.([^.]+)$/) {
				$ext = lc($1);
			}
			#my $info = ImageInfo($name);
			#print "FileType => $$info{'FileType'}\n";
			print $ext;
			my $fullPath = $startdir.'/'.$workdir.'/'.$name;
			if(exists($acceptedTypesMap{$ext})) {
				print "Found acceptable media file: $name in $workdir!\n";
				$name = substr($name,0,rindex($name,$ext));
				my $info = ImageInfo($name);
				foreach (keys %$info) {
					print "$_ => $$info{$_}\n";
				}
				if(exists($videoTypesMap{$ext})) {
					print "\nAnalyzing Video File - $name\n";
					$name =~ s/\s/%20/g;
					system('perl C:/Git/397Scripts/apiSearch.pl '.$name);
				}
				elsif(exists($audioTypesMap{$ext})) {
					# my $id3Info = Music::Tag->new($name);
					# $id3Info->get_tag();
					# print Dumper $id3Info;
					print "\nAnalyzing Audio File - $name\n";
					$name =~ s/\s/%20/g;
					# $name = substr($name,0,rindex($name,$ext));
					my $songTitle = $info->{"Title"};
					if (not $songTitle) {$songTitle = $name;}
					my $songArtist = $info->{"Artist"};
					my $songAlbum = $info->{"Album"};
					print "Title,Artist,Album",$songTitle, $songArtist, $songAlbum;
					$songTitle ? system("perl C:/Git/397Scripts/musicApiSearch.pl \"$songTitle\" \"$songArtist\" \"$songAlbum\"") : system("perl C:/Git/397Scripts/musicApiSearch.pl \"$name\" \"$songArtist\" \"$songAlbum\"");
				}
				elsif(exists($imageTypesMap{$ext})) {
					print "\nAnalyzing Image File - $name\n";
					# $name =~ s/\s/%20/g;
				}
			}
			else {
				print "Found unmatched file:        $name in $workdir!\n";
			}
		}
		else {				# Is the given name something else?
			print "Found some unknown file:     $name\n";
		}
	}
	print "Exiting directory: $workdir\n";
	chdir("..") or die "Unable to change to dir $startdir:$!\n"; 
}