#!/usr/bin/perl

use Modern::Perl '2012';
use utf8;

use CGI::Carp qw(fatalsToBrowser);

use ProductOpener::Config qw/:all/;
use ProductOpener::Store qw/:all/;
use ProductOpener::Index qw/:all/;
use ProductOpener::Display qw/:all/;
use ProductOpener::Tags qw/:all/;
use ProductOpener::Users qw/:all/;
use ProductOpener::Images qw/:all/;
use ProductOpener::Products qw/:all/;
use ProductOpener::Brands qw/:all/;

use CGI qw/:cgi :form escapeHTML/;
use URI::Escape::XS;
use Storable qw/dclone/;
use Encode;
use JSON::PP;

ProductOpener::Display::init();

$debug = 1;


my $code = normalize_code(param('code'));
my $id = param('id');



$debug and print STDERR "brands.pl - code: $code - id: $id\n";

if (not defined $code) {
	
	exit(0);
}
my $product_ref = retrieve_product($code);

my %results = ();

if (($id =~ /^front/) and (param('process_image'))) {
	$results{status} = extract_brands_from_image($product_ref, $id);
	if ($results{status} == 0) {
		$results{brands_from_image} = $product_ref->{brands_text_from_image};
		$results{brands_from_image} =~ s/\n/ /g;
	}
}
my $data =  encode_json(\%results);

print STDERR "brands.pl - JSON data output: $data\n";
	
print header ( -charset=>'UTF-8') . $data;


exit(0);

