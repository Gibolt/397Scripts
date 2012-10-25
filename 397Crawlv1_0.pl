#!/usr/bin/perl -s 

# note the use of -s for switch processing. Under NT/2000, you will need to 
# call this script explicitly with -s (i.e., pen l -s script) if you do not 
# have perl file associations in place. 
# -s is also considered 'retro', many programmers prefer to load 
# a separate module (from the Getopt:: family) for switch parsing. 

# Following line can be used to keep a log
#open FILES, ">", "files.txt" or die $!; open DIRECTORIES, ">", "directories.txt" or die $!; 
use Cwd;
@videoTypes = (".avi",".mp4",".mkv",".mov",".wmv",".flv");
@audioTypes = (".wav",".mp3",".flac",".midi",".aac",".m4a",".mp4");
@imageTypes = (".gif",".jpg",".jpeg",".png",".ico",".bmp",".m4a",".mp4");
@acceptedTypes = (@videoTypes,@audioTypes,@imageTypes);
%acceptedTypesMap = map { $_ => 1 } @acceptedTypes;

if (1>=$#ARGV+1) {
	chdir($ARGV[0]);
	&ScanDirectory($ARGV[0]);
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
			}
			else {
				print "Found unmatched file:        $name in $workdir!\n";
			}
		}
		else {				# Is the given name something else?
			print "Found some unknown file:      $name\n";
		}
	}
	chdir($startdir) or die "Unable to change to dir $startdir:$!\n"; 
}
 