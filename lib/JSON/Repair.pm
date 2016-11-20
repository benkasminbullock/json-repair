package JSON::Repair;
use parent Exporter;
our @EXPORT_OK = qw/repair_json/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Carp;
use JSON::Parse;
use C::Tokenize '$comment_re';
use 5.014;
our $VERSION = '0.01';

sub repair_json
{
    my $jp = JSON::Parse->new ();
    $jp->diagnostics_hash (1);
    my ($broken, %options) = @_;
    my $verbose = $options{verbose};
    my $output = $broken;
    my $count;
    while (1) {
	eval {
	    $jp->run ($output);
	};
	if (! $@) {
	    last;
	}
	my $error = $@->{error};
	#	    print STDERR "$error\n";
	# The type of thing where the error occurred
	my $type = $@->{'bad type'};
	if ($error eq 'Unexpected character') {
	    my $bad_byte = $@->{'bad byte contents'};
	    # $bad_byte is a number, so for convenient string
	    # comparison, turn it into a string.
	    my $bad_char = chr ($bad_byte);
	    my $valid_bytes = $@->{'valid bytes'};
	    # The position of the bad byte.
	    my $bad_pos = $@->{'bad byte position'};
	    if ($verbose) {
		print "Unexpected character '$bad_char' at byte $bad_pos.\n";
	    }
	    # Everything leading up to the bad byte.
	    my $previous = substr ($output, 0, $bad_pos - 1);
	    # Everything after the bad byte.
	    my $remaining = substr ($output, $bad_pos);
	    if ($bad_char eq "'" && $valid_bytes->[ord ('"')]) {
		# Substitute a ': in the remaining stuff as well, if
		# there is one, up to a comma or colon.
		$remaining =~ s/^([^,:]*)'(\s*[,:])/$1"$2/;
		$output = $previous . '"' . $remaining;
		if ($verbose) {
		    print "Changing single to double quote.\n";
		}
		next;
	    }
	    # An unexpected } or ] usually means there was a comma
	    # after an array or object entry, followed by the end
	    # of the object.
	    elsif ($bad_char eq '}' || $bad_char eq ']') {
		# Look for a comma at the end of it.
		if ($previous =~ /,\s*$/) {
		    $previous =~ s/,(\s*)$/$1/;
		    $output = $previous . $bad_char . $remaining;
		    if ($verbose) {
			print "Removing a trailing comma.\n";
		    }
		    next;
		}
		elsif ($bad_char eq '}' && $previous =~ /:\s*$/) {
		    # In the unlikely event that there was a colon
		    # before the end of the object, add a "null"
		    # to it.
		    $output = $previous . "null" . $remaining;
		    next;
		}
		else {
		    warn "Unexpected } or ] in $type\n";
		}
	    }
	    if (($type eq 'object' || $type eq 'array' ||
		 $type eq 'initial state') && $bad_char eq '/') {
		if ($verbose) {
		    print "Comments in object or array?\n";
		}
		$remaining = $bad_char . $remaining;
		if ($remaining =~ s/^($comment_re)//) {
		    if ($verbose) {
			print "Deleted comment $1.\n";
		    }
		    $output = $previous . $remaining;
		    next;
		}
	    }
	    if (($type eq 'object' || $type eq 'array') &&
		$valid_bytes->[ord (',')]) {
		if ($verbose) {
		    print "Missing comma in object or array?\n";
		}
		# Put any space at the end of $previous before the
		# comma, for aesthetic reasons only.
		my $join = ',';
		if ($previous =~ s/(\s+)$//) {
		    $join .= $1;
		}
		$join .= $bad_char;
		$output = $previous . $join . $remaining;
		next;
	    }
	    if ($type eq 'object' && $valid_bytes->[ord ('"')]
		&& $remaining =~ /:/) {
		if ($verbose) {
		    print "Unquoted key in object?\n";
		}
		if ($remaining =~ s/(^[^\}\]:,"]*)(\s*):/$1"$2:/) {
		    if ($verbose) {
			print "Adding quotes to key '$bad_char$1'\n";
		    }
		    $output = $previous . '"' . $bad_char . $remaining;
		    next;
		}
	    }
	    if ($type eq 'string') {
		if ($bad_char eq "\n") {
		    $output = $previous . "\\n" . $remaining;
		    if ($verbose) {
			print "Converting newline to escape.\n";
		    }
		    next;
		}
	    }
#	    print "$output\n";
	    warn "Could not handle unexpected character '$bad_char' in $type\n";
	    if ($verbose) {
		print_valid_bytes ($valid_bytes);
	    }
	}
	elsif ($error eq 'Unexpected end of input') {
	    #		for my $k (keys %{$@}) {
	    #		    print "$k -> $@->{$k}\n";
	    #		}
	    #		print "Unexpected end of input.\n";
	    if ($type eq 'string') {
		$output .= '"';
		if ($verbose) {
		    print "String ended unexpectedly: adding a quote.\n";
		}
		next;
	    }
	    elsif ($type eq 'object') {
		$output .= '}';
		if ($verbose) {
		    print "Object ended unexpectedly: adding a }.\n";
		}
		next;
	    }
	    elsif ($type eq 'array') {
		$output .= ']';
		if ($verbose) {
		    print "Array ended unexpectedly: adding a ].\n";
		}
		next;
	    }
	    else {
		warn "Unhandled unexpected end of input in $type";
	    }
	}
	warn "Unhandled error $error";
	$count++;
	if ($count > 2) {
	    carp "Repair failed";
	    $output = undef;
	    last;
	}
    }
    return $output;
}

sub print_valid_bytes
{
    my ($valid_bytes) = @_;
    for my $i (0..127) {
	my $ok = $valid_bytes->[$i];
	if ($ok) {
	    print "OK: '",chr ($i),"'\n";
	}
    }
}

1;
