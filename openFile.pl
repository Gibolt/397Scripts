#!/usr/bin/perl -w
# $Author: Thomas Reese $
# $Date: 2012-10-27 $

for (my $i = 0; $i<$#ARGV+1; $i++) {
	print $ARGV[$i]."\n";
	fetch_title("$ARGV[$i]");
}

sub fetch_title {
	my $fileIn = $_[0];
	# A space gets passed in as %20 so not to conflict with the command line
	$fileIn =~ s/%20/ /g;
	my $command = "start \"\" \"$fileIn\"";
	print "$command\n";
	system($command);
}
