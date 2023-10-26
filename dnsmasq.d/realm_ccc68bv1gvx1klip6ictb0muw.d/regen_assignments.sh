#! /usr/bin/perl -w
@ARGV= "fixed_assignments.conf";
my $x2= qr/[[:xdigit:]]{2}/;
open OUT, "| sort" or die $!;
while (defined($_= <>)) {
	chomp;
	my($p, $s)= /^
		( dhcp-host= (?: $x2 : ){2} )
		(?: $x2 : ){3} $x2
		, ( [0-9.]+ )
		$
	/x or die;
	print OUT $p . (
		join ":", map { sprintf "%02x", $_ } split /\./, $s
	) . "," . $s . "\n";
}
close OUT or die $!;
