package SSSR::BFS;

use strict;
use warnings;

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
                next if $visited{$vertex}; # might be already visited
                $visited{$vertex} = 1;
                for my $neighbour ($graph->neighbours($vertex)) {
                    if( $visited{$neighbour} ) {
                        for my $path (@{$paths{$neighbour}}) {
                            my @common = common( $paths{$vertex}, $path );
                            next if scalar @common != 1;
                            push @cycles,
                                 [ @{$paths{$vertex}}, reverse @path ];
                            pop @{$cycles[-1]};
                        }
                        # Recording a new path to the vertex
                        push @{$paths{$neighbour}},
                             [ $paths{$vertex}, $neighbour ];
                    } else {
                        if( $opened{$neighbour} ) {
                            for my $path (@{$paths{$neighbour}}) {
                                my @common = common( $paths{$vertex},
                                                     $path );
                                next if scalar @common != 1;
                                push @cycles,
                                     [ @{$paths{$vertex}}, reverse @path ];
                                pop @{$cycles[-1]};
                            }
                            # No need to visit anything past this point
                            $visited{$neighbour} = 1;
                        } else {
                            # Put vertex in the queue for next iteration
                            $next_stage{$neighbour} = scalar @next_stage;
                            @{$paths{$neighbour}} = @{$paths->{$vertex}},
                                                    $neighbour;
                            $opened{$neighbour} = 1;
                        }
                    }
                }
            }
            @current_stage = @next_stage;
            @next_stage = ();
        }
    }
}

sub common
{
    my( $A, $B ) = @_;

    my @A = sort @$A;
    my @B = sort @$B;

    my @common;
    while( @A || @B ) {
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
