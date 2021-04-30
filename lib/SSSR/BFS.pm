package SSSR::BFS;

use strict;
use warnings;

sub get_SSSR
{
    my( $graph ) = @_;

    for my $original_vertex ($graph->vertices) {
        my @current_stage = ( $original_vertex );
        my @next_stage;
        my %current_stage = ( $original_vertex => 0 );
        my %next_stage;
        my %paths = ( $original_vertex => [ $original_vertex ] );
        my %opened = ( $original_vertex => 1 );
        my %visited;

        while( @current_stage ) {
            for my $vertex (@current_stage) {
                next unless defined $vertex; # might be undefined
                next if $visited{$vertex};   # might be already visited
                $visited{$vertex} = 1;
                for my $neighbour ($graph->neighbours($vertex)) {
                    if( $visited{$neighbour} ) {
                        if( grep { $_ eq $neighbour } @{$paths->{$vertex}} ) {
                            # Found a vertex already in my path, nothing to do
                        } else {
                            # Closing a cycle unless there are common members
                            # TODO: report a cycle
                        }
                    } else {
                        if( exists $next_stage{$neighbour} ) {
                            # Closing a cycle unless there are common members,
                            # no need to go any further
                            # TODO: check and report a cycle
                            # No need to visit anything past this point
                            $visited{$neighbour} = 1;
                        } else {
                            # Put vertex in the queue for next iteration
                            $next_stage{$neighbour} = scalar @next_stage;
                            push @next_stage, $neighbour;
                            @{$paths{$neighbour}} = @{$paths{$vertex}}, $neighbour;
                        }
                    }
                }
            }
            @current_stage = @next_stage;
            %current_stage = %next_stage;
            @next_stage = ();
            %next_stage = ();
        }
    }
}

1;
