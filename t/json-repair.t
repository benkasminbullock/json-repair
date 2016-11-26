use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Repair 'repair_json';
use JSON::Parse 'parse_json';

my $repaired = repair_json ("{'fantastic':\"pump\",", verbose => undef);
#note ($repaired);
like ($repaired, qr/"fantastic"/, "Converted single to double quotes");
unlike ($repaired, qr/,/, "Removed trailing comma");
like ($repaired, qr/\}$/, "Added }");
my $repaired_array = repair_json ('[1,2,3,');
like ($repaired_array, qr/]\s*$/, "Added ] to array");
unlike ($repaired_array, qr/,\s*]\s*$/, "Removed trailing comma from array");
my $numbers;
my $eps = 1e-9;

$numbers = repair_json ('[.123,0123,1.e9]');
ok ($numbers, "No error parsing broken numbers");
my $n = parse_json ($numbers);
ok ($n->[0] && abs ($n->[0] - 0.123) < $eps, "repaired .123");
ok ($n->[1] && abs ($n->[1] - 123) < $eps, "repaired 0123");
ok ($n->[2] && abs ($n->[2] - 1e9) < $eps, "repaired 1.e9");

my $badstring = '"' . chr (9) . chr (0) . "\n" . '"';
#print "$badstring\n";
my $goodstring;
$goodstring = repair_json ($badstring);
like ($goodstring, qr/"\\t/, "Tab inserted");
like ($goodstring, qr/\\u0000/, "Unicode escape inserted");
like ($goodstring, qr/\\n"/, "Newline inserted");

my $empty = '';
my $notempty = repair_json ($empty);
is ($notempty, '""', "Repaired empty input to an empty string");

done_testing ();
