#!/usr/bin/perl -s 
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

use Cwd;
use Image::ExifTool qw(:Public); # Needs to be installed
@videoTypes = (".avi",".mp4",".mkv",".mov",".wmv",".flv");
%videoTypesMap = map { $_ => 1 } @videoTypes;
@audioTypes = (".wav",".mp3",".flac",".midi",".aac",".m4a",".mp4");
%audioTypesMap = map { $_ => 1 } @audioTypes;
@imageTypes = (".gif",".jpg",".jpeg",".png",".ico",".bmp",".m4a",".mp4");
%imageTypesMap = map { $_ => 1 } @imageTypes;
@acceptedTypes = (@videoTypes,@audioTypes,@imageTypes);
%acceptedTypesMap = map { $_ => 1 } @acceptedTypes;

if (1>=$#ARGV+1) {
	chdir($ARGV[0]);
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
	
	foreach my $name (@names){ 
		next if ($name eq "."); 
		next if ($name eq ".."); 
		if (-d $name){ 		# Is the given name a directory?
			print  "Found directory:   $name in $workdir!\n"; 
			&ScanDirectory($name); 
			next; 
		}
		elsif (-f $name) {	# Is the given name a file?
			my $ext;
			if ($name =~ /(\.[^.]+)$/) {
				$ext = $1;
			}
			my $fullPath = $startdir.'/'.$workdir.'/'.$name;
			if(exists($acceptedTypesMap{$ext})) {
				print "Found acceptable media file: $name in $workdir!\n";
				# TODO: Send files to appropriate parsing scripts and online syncs
				# http://owl.phy.queensu.ca/~phil/exiftool/
				# if (Win32::File::GetAttributes(&cwd."/".$name, $attrib)) {
					# print $attrib, $/;
				# }
				
				my $info = ImageInfo($name);
				foreach (keys %$info) {
					print "$_ => $$info{$_}\n";
				}
				if(exists($videoTypesMap{$ext})) {
					print "\nAnalyzing File - $name\n";
					$name =~ s/\s/%20/g;
					$name = substr($name,0,rindex($name,$ext));
					system('perl C:/Git/397Scripts/397Scriptv1.3.pl '.$name);
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
 