package ProductOpener::Brands;

use utf8;
use Modern::Perl '2012';
use Exporter    qw< import >;

BEGIN
{
	use vars       qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = qw();            # symbols to export by default
	@EXPORT_OK = qw(
					&extract_brands_from_image

	
					);	# symbols to export on request
	%EXPORT_TAGS = (all => [@EXPORT_OK]);
}

use vars @EXPORT_OK ;
use experimental 'smartmatch';

use ProductOpener::Store qw/:all/;
use ProductOpener::Config qw/:all/;
use ProductOpener::Users qw/:all/;
use ProductOpener::Products qw/:all/;
use ProductOpener::TagsEntries qw/:all/;
use ProductOpener::Tags qw/:all/;
use ProductOpener::URL qw/:all/;

use Encode;
use Clone qw(clone);

use LWP::UserAgent;
use Encode;
use JSON::PP;

# MIDDLE DOT with common substitutes (BULLET variants, BULLET OPERATOR and DOT OPERATOR (multiplication))
my $middle_dot = qr/(?:\N{U+00B7}|\N{U+2022}|\N{U+2023}|\N{U+25E6}|\N{U+2043}|\N{U+204C}|\N{U+204D}|\N{U+2219}|\N{U+22C5})/i;
# Unicode category 'Punctuation, Dash', SWUNG DASH and MINUS SIGN
my $dashes = qr/(?:\p{Pd}|\N{U+2053}|\N{U+2212})/i;
my $separators = qr/(,|;|:|$middle_dot|\[|\{|\(|( $dashes ))|(\/)/i;


sub extract_brands_from_image($$$) {

	my $product_ref = shift;
	my $id = shift;
	my $ocr_engine = shift;
	
	my $path = product_path($product_ref->{code});
	my $status = 1;
	
	my $filename = '';
	
	my $lc = $product_ref->{lc};
	
	if ($id =~ /^front_(\w\w)$/) {
		$lc = $1;
	}
	else {
		$id = "front";
	}
	
	my $size = 'full';
	if ((defined $product_ref->{images}) and (defined $product_ref->{images}{$id})
		and (defined $product_ref->{images}{$id}{sizes}) and (defined $product_ref->{images}{$id}{sizes}{$size})) {
		$filename = $id . '.' . $product_ref->{images}{$id}{rev} ;
	}
	
	my $image = "$www_root/images/products/$path/$filename.full.jpg";
	my $image_url = format_subdomain('static') . "/images/products/$path/$filename.full.jpg";
	
	my $text;
	
	print STDERR "Brands.pm - extracts_brands_from_image - id: $id\n";

	my $url = "https://alpha-vision.googleapis.com/v1/images:annotate?key=" . $ProductOpener::Config::google_cloud_vision_api_key;
	# alpha-vision.googleapis.com/

	my $ua = LWP::UserAgent->new();

	my $api_request_ref = 		 
		{
			requests => 
				[ 
					{
						features => [{ type => 'LOGO_DETECTION'}], image => { source => { imageUri => $image_url}}
					}
				]
		}
	;
	my $json = encode_json($api_request_ref);
					
	my $request = HTTP::Request->new(POST => $url);
	$request->header( 'Content-Type' => 'application/json' );
	$request->content( $json );

	my $res = $ua->request($request);
		
	if ($res->is_success) {
	
		print STDERR "google cloud vision: success\n";
	
		my $json_response = $res->decoded_content;
		
		my $cloudvision_ref = decode_json($json_response);
		
		my $json_file = "$www_root/images/products/$path/$filename.full.jpg" . ".google_cloud_vision.json";
		
		print STDERR "google cloud vision: saving json response to $json_file\n";
		
		open (my $OUT, ">:encoding(UTF-8)", $json_file);
		print $OUT $json_response;
		close $OUT;			
		
		if ((defined $cloudvision_ref->{responses}) and (defined $cloudvision_ref->{responses}[0])
			and (defined $cloudvision_ref->{responses}[0]{logoAnnotation})
			and (defined $cloudvision_ref->{responses}[0]{logoAnnotation}{description})) {
			
			print STDERR "google cloud vision: found a text response\n";

			
			$product_ref->{ingredients_text_from_image} = $cloudvision_ref->{responses}[0]{logoAnnotation}{description};
			$status = 0;
		}
		
	}
	else {
		print STDERR "google cloud vision: not ok - code: " . $res->code . " - message: " . $res->message . "\n";
	}



	
	return $status;

}