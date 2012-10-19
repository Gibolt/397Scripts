#!/usr/bin/perl -s 

# note the use of -s for switch processing. Under NT/2000, you will need to 
# call this script explicitly with -s (i.e., pen l -s script) if you do not 
# have perl file associations in place. 
# -s is also considered 'retro', many programmers prefer to load 
# a separate module (from the Getopt:: family) for switch parsing. 

#open FILES, ">", "files.txt" or die $!; open DIRECTORIES, ">", "directories.txt" or die $!; 
use Cwd; # module for finding the current working directory 
@videoTypes = (".avi",".mp4",".mkv",".mov",".wmv",".flv");
@audioTypes = (".wav",".mp3",".flac",".midi",".aac",".m4a",".mp4");
@imageTypes = (".gif",".jpg",".jpeg",".png",".ico",".bmp",".m4a",".mp4");
#@acceptedTypes = (".gif",".jpg",".png",".ico",".css",".sit",".eps",".wmf",".mpg",".gz",".rpm",".tgz",".mov", ".exe",".jpeg",".bmp",".js"); 
@acceptedTypes = (@videoTypes,@audioTypes,@imageTypes);
%acceptedTypesMap = map { $_ => 1 } @acceptedTypes;
#@excludedFileNames = ("crawlFilesystem.p1", "directories.txt", "files.txt"); 
#@excludedTypes = gif","GIF","jpg","JPG","png","PNG","ico","ICO","css","CSS","sit","SIT","eps","EPS","wmf", "WMF","zip","ZIP","ppt","PPT","mpg","MPG","xls","XLS","gz","GZ","rpm","RPM","tgz","TGZ","mo v","MOV","exe","EXE","jpeg","JPEG","bmp","BMP","js","JS"); 

if (1>=$#ARGV+1) {
	&ScanDirectory($ARGV[0]);
}


# This subroutine takes the name of a directory and recursively scans 
# down the filesystem 
sub ScanDirectory{
	my ($workdir) = shift; 
	my ($startdir) = &cwd; # keep track of where we began 
	
	chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
	opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
	my @names = readdir(DIR) or die "Unable to read $workdir:$!\n";
	closedir(DIR); 
	
	foreach my $name (@names){ 
		next if ($name eq "."); 
		next if ($name eq ".."); 

		if (-d $name){ 		# is this a directory? 
			print  "Found directory: $name in $workdir!\n"; 
			&ScanDirectory($name); 
			next; 
		}
		elsif (-f $name) {
			# print "Found file: $name in $workdir!\n";
			my $ext;
			if ($name =~ /(\.[^.]+)$/) {
				$ext = $1;
			}
			print "Found file: $name in $workdir! - $ext\n";
			my $fullPath = $startdir.'/'.$workdir.'/'.$name;
			if(exists($acceptedTypesMap{$ext})) {

				print "Found file: $name in $workdir!\n";
				# TODO: Send files to appropriate parsing scripts and online syncs
			}
		}
		print $name."\n";
		chdir($startdir) or die "Unable to change to dir $startdir:$!\n"; 
	}
}
#&ScanDirectory("."); 