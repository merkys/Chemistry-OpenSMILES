package SSSR;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(
    sort_ring_elements
);

sub sort_ring_elements
{
    my( @elements ) = @_;

    return @elements if scalar @elements <= 1;

    my $min_index;
    my $reverse;
    for my $i (0..$#elements) {
        next if defined $min_index && $elements[$i] ge
                                      $elements[$min_index];
        $min_index = $i;
        $reverse = $elements[($i-1) % scalar @elements] lt
                   $elements[($i+1) % scalar @elements];
    }

    if( $reverse ) {
        @elements = reverse @elements;
        $min_index = $#elements - $min_index;
    }

    return @elements[$min_index..$#elements],
           @elements[0..$min_index-1];
}

1;
