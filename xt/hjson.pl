#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair 'repair_json';

# Examples of hjson from https://hjson.org/

my $hjson =<<'EOF';
{
  # specify rate in requests/second
  rate: 1000
}
--
{
  first: 1
  second: 2
}
--
{
  # hash style comments
  # (because it's just one character)

  // line style comments
  // (because it's like C/JavaScript/...)

  /* block style comments because
     it allows you to comment out a block */

  # Everything you do in comments,
  # stays in comments ;-}
}
--
{
  md:
    '''
    First line.
    Second line.
      This line is indented by two spaces.
    '''
}
--
{
  "key name": "{ sample }"
  "{}": " spaces at the start/end "
  this: is OK though: {}[],:
}
--
{
  // use #, // or /**/ comments,
  // omit quotes for keys
  key: 1
  // omit quotes for strings
  contains: everything on this line
  // omit commas at the end of a line
  cool: {
    foo: 1
    bar: 2
  }
  // allow trailing commas
  list: [
    1,
    2,
  ]
  // and use multiline strings
  realist:
    '''
    My half empty glass,
    I will fill your empty half.
    Now you are half full.
    '''
}
EOF
my @hjson = split /^--/sm, $hjson;
for my $crap (@hjson) {
    if (repair_json ($crap)) {
	print "OK.\n";
    }
    else {
	repair_json ($crap, verbose => 1);
	print "$crap was too awful.\n";
	exit;
    }
}
