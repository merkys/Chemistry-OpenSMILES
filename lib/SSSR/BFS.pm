package SSSR::BFS;

use strict;
use warnings;

use List::Util qw( uniq );
use SSSR qw( sort_ring_elements );

sub get_SSSR
{
    my( $graph ) = @_;

    my @cycles;

    for my $original_vertex ($graph->vertices) {
        my @current_stage = ( $original_vertex );
        my @next_stage;
        my %paths = ( $original_vertex => [ [ $original_vertex ] ] );
        my %opened = ( $original_vertex => 1 );
        my %visited;

        while( @current_stage ) {
            for my $vertex (@current_stage) {
                print "AT $vertex";
                next if $visited{$vertex}; # might be already visited
                $visited{$vertex} = 1;
                for my $neighbour ($graph->neighbours($vertex)) {
                    print "\t$vertex -> $neighbour";
                    if( $visited{$neighbour} ) {
                        print ">>> ALREADY VISITED";
                        for my $path (@{$paths{$neighbour}}) {
                            my @common = common( $paths{$vertex}[0], $path );
                            next if scalar @common != 1;
                            push @cycles,
                                 [ @{$paths{$vertex}[0]}, reverse @$path ]; # really?
                            pop @{$cycles[-1]};
                        }
                        # Recording a new path to the vertex
                        push @{$paths{$neighbour}},
                             [ @{$paths{$vertex}[0]}, $neighbour ];
                    } else {
                        if( $opened{$neighbour} ) {
                            print ">>> ALREADY OPENED";
                            for my $path (@{$paths{$neighbour}}) {
                                my @common = common( $paths{$vertex}[0],
                                                     $path );
                                next if scalar @common != 1;
                                push @cycles,
                                     [ @{$paths{$vertex}[0]}, reverse @$path ];
                                pop @{$cycles[-1]};
                            }
                            # No need to visit anything past this point
                            $visited{$neighbour} = 1;
                        } else {
                            print "\t\tOPENED";
                            # Put vertex in the queue for next iteration
                            $paths{$neighbour} = [ [ @{$paths{$vertex}[0]},
                                                     $neighbour ] ];
                            $opened{$neighbour} = 1;
                            push @next_stage, $neighbour;
                        }
                    }
                }
            }
            @current_stage = @next_stage;
            @next_stage = ();
        }
        print "-" x 75;
    }

    return uniq map { join ',', sort_ring_elements( @$_) } @cycles;
}

sub common
{
    my( $A, $B ) = @_;

    use Data::Dumper;
    print Dumper [ $A, $B ];

    my @A = sort @$A;
    my @B = sort @$B;

    my @common;
    while( @A && @B ) {
        if( $A[0] lt $B[0] ) {
            shift @A;
        } elsif( $A[0] gt $B[0] ) {
            shift @B;
        } else {
            push @common, $A[0];
            shift @A;
            shift @B;
        }
    }

    return @common;
}

1;
