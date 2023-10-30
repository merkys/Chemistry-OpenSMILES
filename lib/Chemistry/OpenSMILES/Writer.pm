package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Chemistry::OpenSMILES qw(
    is_aromatic
    is_chiral
    toggle_cistrans
);
use Chemistry::OpenSMILES::Parser;
use Graph::Traversal::DFS;
use List::Util qw( all any first min uniq );

# ABSTRACT: OpenSMILES format writer
# VERSION

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    write_SMILES
);

my @TB = (
    { axis => [ 1, 5 ], order => '@',  opposite =>  2 },
    { axis => [ 1, 5 ], order => '@@', opposite =>  1 },
    { axis => [ 1, 4 ], order => '@',  opposite =>  4 },
    { axis => [ 1, 4 ], order => '@@', opposite =>  3 },
    { axis => [ 1, 3 ], order => '@',  opposite =>  6 },
    { axis => [ 1, 3 ], order => '@@', opposite =>  5 },
    { axis => [ 1, 2 ], order => '@',  opposite =>  8 },
    { axis => [ 1, 2 ], order => '@@', opposite =>  7 },
    { axis => [ 2, 5 ], order => '@',  opposite => 11 },
    { axis => [ 2, 4 ], order => '@',  opposite => 12 },
    { axis => [ 2, 5 ], order => '@@', opposite =>  9 },
    { axis => [ 2, 4 ], order => '@@', opposite => 10 },
    { axis => [ 2, 3 ], order => '@',  opposite => 14 },
    { axis => [ 2, 3 ], order => '@@', opposite => 13 },
    { axis => [ 3, 5 ], order => '@',  opposite => 20 },
    { axis => [ 3, 4 ], order => '@',  opposite => 19 },
    { axis => [ 4, 5 ], order => '@',  opposite => 18 },
    { axis => [ 4, 5 ], order => '@@', opposite => 17 },
    { axis => [ 3, 4 ], order => '@@', opposite => 16 },
    { axis => [ 3, 5 ], order => '@@', opposite => 15 },
);

our @OH = (
    { shape => 'U', axis => [ 1, 6 ], order =>  '@' },
    { shape => 'U', axis => [ 1, 6 ], order => '@@' },
    { shape => 'U', axis => [ 1, 5 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 6 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 5 ], order =>  '@' },
    { shape => 'U', axis => [ 1, 4 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 4 ], order =>  '@' },
    { shape => '4', axis => [ 1, 6 ], order => '@@' },
    { shape => '4', axis => [ 1, 5 ], order => '@@' },
    { shape => '4', axis => [ 1, 6 ], order =>  '@' },
    { shape => '4', axis => [ 1, 5 ], order =>  '@' },
    { shape => '4', axis => [ 1, 4 ], order => '@@' },
    { shape => '4', axis => [ 1, 4 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 6 ], order => '@@' },
    { shape => 'Z', axis => [ 1, 5 ], order => '@@' },
    { shape => 'U', axis => [ 1, 5 ], order => '@@' },
    { shape => 'Z', axis => [ 1, 4 ], order => '@@' },
    { shape => 'U', axis => [ 1, 4 ], order => '@@' },
    { shape => 'U', axis => [ 1, 3 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 3 ], order =>  '@' },
    { shape => '4', axis => [ 1, 3 ], order => '@@' },
    { shape => '4', axis => [ 1, 3 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 3 ], order => '@@' },
    { shape => 'U', axis => [ 1, 3 ], order => '@@' },
    { shape => 'U', axis => [ 1, 2 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 2 ], order =>  '@' },
    { shape => '4', axis => [ 1, 2 ], order => '@@' },
    { shape => '4', axis => [ 1, 2 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 2 ], order => '@@' },
    { shape => 'U', axis => [ 1, 2 ], order => '@@' },
);

sub write_SMILES
{
    my( $what, $order_sub ) = @_;

    if( ref $what eq 'HASH' ) {
        # subroutine will also accept and properly represent a single
        # atom:
        return _pre_vertex( $what );
    }

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    $order_sub = \&_order unless $order_sub;

    for my $graph (@moieties) {
        my @symbols;
        my %vertex_symbols;
        my $nrings = 0;
        my %seen_rings;
        my @chiral;
        my %discovered_from;

        my $rings = {};

        my $operations = {
            tree_edge     => sub { my( $seen, $unseen, $self ) = @_;
                                   if( $vertex_symbols{$unseen} ) {
                                       ( $seen, $unseen ) = ( $unseen, $seen );
                                   }
                                   push @symbols, _tree_edge( $seen, $unseen, $self, $order_sub );
                                   $discovered_from{$unseen} = $seen },

            non_tree_edge => sub { my @sorted = sort { $vertex_symbols{$a} <=>
                                                       $vertex_symbols{$b} }
                                                     @_[0..1];
                                   $rings->{$vertex_symbols{$_[0]}}
                                           {$vertex_symbols{$_[1]}} =
                                   $rings->{$vertex_symbols{$_[1]}}
                                           {$vertex_symbols{$_[0]}} =
                                        _depict_bond( @sorted, $graph ) },

            pre  => sub { my( $vertex, $dfs ) = @_;
                          push @chiral, $vertex if is_chiral $vertex;
                          push @symbols,
                          _pre_vertex( { map { $_ => $vertex->{$_} }
                                         grep { $_ ne 'chirality' }
                                         keys %$vertex } );
                          $vertex_symbols{$vertex} = $#symbols },

            post => sub { push @symbols, ')' },
            next_root => undef,
        };

        if( $order_sub ) {
            $operations->{first_root} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
            $operations->{next_successor} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
        }

        my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
        $traversal->dfs;

        if( scalar keys %vertex_symbols != scalar $graph->vertices ) {
            warn scalar( $graph->vertices ) - scalar( keys %vertex_symbols ) .
                 ' unreachable atom(s) detected in moiety' . "\n";
        }

        next unless @symbols;
        pop @symbols;

        # Dealing with chirality
        for my $atom (@chiral) {
            next unless $atom->{chirality} =~ /^@(@?|SP[123]|TB1?[1-9]|TB20)$/;

            my @neighbours = $graph->neighbours($atom);
            my $has_lone_pair;
            if( $atom->{chirality} =~ /^@(@?|SP[123])$/ ) {
                if( scalar @neighbours < 3 || scalar @neighbours > 4 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process tetrahedral chiral or square planar centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 3;
            }
            if( $atom->{chirality} =~ /^\@TB..?$/ ) {
                if( scalar @neighbours < 4 || scalar @neighbours > 5 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process trigonal bipyramidal centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 4;
            }
            if( $atom->{chirality} =~ /^\@OH..?$/ ) {
                if( scalar @neighbours < 5 || scalar @neighbours > 6 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process octahedral centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 5;
            }

            my $chirality_now = $atom->{chirality};
            if( $atom->{chirality_neighbours} ) {
                if( scalar @neighbours !=
                    scalar @{$atom->{chirality_neighbours}} ) {
                    warn 'number of neighbours does not match the length ' .
                         "of 'chirality_neighbours' array, cannot process " .
                         'such chiral centers' . "\n";
                    next;
                }

                my %indices;
                for (0..$#{$atom->{chirality_neighbours}}) {
                    my $pos = $_;
                    if( $has_lone_pair && $_ != 0 ) {
                        # Lone pair is always second in the chiral neighbours array
                        $pos++;
                    }
                    $indices{$vertex_symbols{$atom->{chirality_neighbours}[$_]}} = $pos;
                }

                my @order_new;
                # In the newly established order, the atom from which this one
                # is discovered (left hand side) will be the first, if any
                if( $discovered_from{$atom} ) {
                    push @order_new,
                         $indices{$vertex_symbols{$discovered_from{$atom}}};
                }
                # Second, there will be ring bonds as they are added before all of the neighbours
                if( $rings->{$vertex_symbols{$atom}} ) {
                    push @order_new, map  { $indices{$_} }
                                     sort { $a <=> $b }
                                     keys %{$rings->{$vertex_symbols{$atom}}};
                }
                # Finally, all neighbours are added, uniq will remove duplicates
                push @order_new, map  { $indices{$_} }
                                 sort { $a <=> $b }
                                 map  { $vertex_symbols{$_} }
                                      @neighbours;
                @order_new = uniq @order_new;

                if( $has_lone_pair ) {
                    # Accommodate the lone pair
                    if( $discovered_from{$atom} ) {
                        @order_new = ( $order_new[0], 1, @order_new[1..$#order_new] );
                    } else {
                        unshift @order_new, 1;
                    }
                }

                if( $atom->{chirality} =~ /^@@?$/ ) {
                    # Tetragonal centers
                    if( join( '', _permutation_order( @order_new ) ) ne '0123' ) {
                        $chirality_now = $chirality_now eq '@' ? '@@' : '@';
                    }
                } elsif( $atom->{chirality} =~ /^\@SP[123]$/ ) {
                    # Square planar centers
                    $chirality_now = _square_planar_chirality( @order_new, $chirality_now );
                } elsif( $atom->{chirality} =~ /^\@TB..?$/ ) {
                    # Trigonal bipyramidal centers
                    $chirality_now = _trigonal_bipyramidal_chirality( @order_new, $chirality_now );
                } else {
                    # Octahedral centers
                }
            }

            my $parser = Chemistry::OpenSMILES::Parser->new;
            my( $graph_reparsed ) = $parser->parse( $symbols[$vertex_symbols{$atom}],
                                                    { raw => 1 } );
            my( $atom_reparsed ) = $graph_reparsed->vertices;
            $atom_reparsed->{chirality} = $chirality_now;
            $symbols[$vertex_symbols{$atom}] =
                write_SMILES( $atom_reparsed );
        }

        # Adding ring numbers
        my @ring_ids = ( 1..99, 0 );
        my @ring_ends;
        for my $i (0..$#symbols) {
            if( $rings->{$i} ) {
                for my $j (sort { $a <=> $b } keys %{$rings->{$i}}) {
                    next if $i > $j;
                    if( !@ring_ids ) {
                        # All 100 rings are open now. There is no other
                        # solution but to terminate the program.
                        die 'cannot represent more than 100 open ring' .
                            ' bonds';
                    }
                    $symbols[$i] .= $rings->{$i}{$j} .
                                    ($ring_ids[0] < 10 ? '' : '%') .
                                     $ring_ids[0];
                    $symbols[$j] .= ($rings->{$i}{$j} eq '/'  ? '\\' :
                                     $rings->{$i}{$j} eq '\\' ? '/'  :
                                     $rings->{$i}{$j}) .
                                    ($ring_ids[0] < 10 ? '' : '%') .
                                     $ring_ids[0];
                    push @{$ring_ends[$j]}, shift @ring_ids;
                }
            }
            if( $ring_ends[$i] ) {
                # Ring bond '0' must stay in the end
                @ring_ids = sort { ($a == 0) - ($b == 0) || $a <=> $b }
                                 (@{$ring_ends[$i]}, @ring_ids);
            }
        }

        push @components, join '', @symbols;
    }

    return join '.', @components;
}

# DEPRECATED
sub write
{
    &write_SMILES;
}

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    return '(' . _depict_bond( $u, $v, $self->graph );
}

sub _pre_vertex
{
    my( $vertex ) = @_;

    my $atom = $vertex->{symbol};
    my $is_simple = $atom =~ /^[bcnosp]$/i ||
                    $atom =~ /^(F|Cl|Br|I|\*)$/;

    if( exists $vertex->{isotope} ) {
        $atom = $vertex->{isotope} . $atom;
        $is_simple = 0;
    }

    if( is_chiral $vertex ) {
        $atom .= $vertex->{chirality};
        $is_simple = 0;
    }

    if( $vertex->{hcount} ) { # if non-zero
        $atom .= 'H' . ($vertex->{hcount} == 1 ? '' : $vertex->{hcount});
        $is_simple = 0;
    }

    if( $vertex->{charge} ) { # if non-zero
        $atom .= ($vertex->{charge} > 0 ? '+' : '') . $vertex->{charge};
        $atom =~ s/([-+])1$/$1/;
        $is_simple = 0;
    }

    if( $vertex->{class} ) { # if non-zero
        $atom .= ':' . $vertex->{class};
        $is_simple = 0;
    }

    return $is_simple ? $atom : "[$atom]";
}

sub _depict_bond
{
    my( $u, $v, $graph ) = @_;

    if( !$graph->has_edge_attribute( $u, $v, 'bond' ) ) {
        return is_aromatic $u && is_aromatic $v ? '-' : '';
    }

    my $bond = $graph->get_edge_attribute( $u, $v, 'bond' );
    return $bond if $bond ne '/' && $bond ne '\\';
    return $bond if $u->{number} < $v->{number};
    return toggle_cistrans $bond;
}

# Reorder a permutation of elements 0, 1, 2 and 3 by taking an element
# and moving it two places either forward or backward in the line. This
# subroutine is used to check whether a sign change of tetragonal
# chirality is required or not.
sub _permutation_order
{
    # Safeguard against endless cycles due to undefined values
    if( (scalar @_ != 4) ||
        (any { !defined || !/^[0-3]$/ } @_) ||
        (join( ',', sort @_ ) ne '0,1,2,3') ) {
        warn '_permutation_order() accepts only permutations of numbers ' .
             "'0', '1', '2' and '3', unexpected input received";
        return 0..3; # Return original order
    }

    while( $_[2] == 0 || $_[3] == 0 ) {
        @_ = ( $_[0], @_[2..3], $_[1] );
    }
    if( $_[0] != 0 ) {
        @_ = ( @_[1..2], $_[0], $_[3] );
    }
    while( $_[1] != 1 ) {
        @_[1..3] = ( @_[2..3], $_[1] );
    }
    return @_;
}

sub _square_planar_chirality
{
    my $chirality = pop @_;
    my @source = 0..3;
    my @target = @_;

    if( join( ',', sort @_ ) ne '0,1,2,3' ) {
        die '_square_planar_chirality() accepts only permutations of ' .
            "numbers '0', '1', '2' and '3', unexpected input received";
    }

    # Rotations until 0 is first
    while( $source[0] != $target[0] ) {
        push @source, shift @source;
        my %tab = ( '@SP1' => '@SP1', '@SP2' => '@SP3', '@SP3' => '@SP2' );
        $chirality = $tab{$chirality};
    }

    if( $source[3] == $target[1] ) { # Swap the right side
        ( $source[2], $source[3] ) = ( $source[3], $source[2] );
        my %tab = ( '@SP1' => '@SP3', '@SP2' => '@SP2', '@SP3' => '@SP1' );
        $chirality = $tab{$chirality};
    }

    if( $source[2] == $target[1] ) { # Swap the center
        ( $source[1], $source[2] ) = ( $source[2], $source[1] );
        my %tab = ( '@SP1' => '@SP2', '@SP2' => '@SP1', '@SP3' => '@SP3' );
        $chirality = $tab{$chirality};
    }

    if( $source[3] == $target[2] ) { # Swap the right side
        ( $source[2], $source[3] ) = ( $source[3], $source[2] );
        my %tab = ( '@SP1' => '@SP3', '@SP2' => '@SP2', '@SP3' => '@SP1' );
        $chirality = $tab{$chirality};
    }

    return $chirality;
}

sub _trigonal_bipyramidal_chirality
{
    my $chirality = pop @_;
    my @order = @_;

    $chirality = int substr $chirality, 3;
    my $TB = $TB[$chirality - 1];
    my @axis = map { $_ - 1 } @{$TB->{axis}};
    my $order = $TB->{order};
    my $opposite = $TB->{opposite};

    if( $order[$axis[0]] == $axis[0] && $order[$axis[1]] == $axis[1] ) {
        # No changes to the axis
        @order = grep { $_ != $axis[0] && $_ != $axis[1] } @order;
        while( $order[0] != min @order ) {
            push @order, shift @order;
        }
        return '@TB' . $chirality if $order[1] < $order[2];
        return '@TB' . $opposite;
    } elsif( $order[$axis[0]] == $axis[1] && $order[$axis[1]] == $axis[0] ) {
        # Axis inversion
        @order = grep { $_ != $axis[0] && $_ != $axis[1] } @order;
        while( $order[0] != min @order ) {
            push @order, shift @order;
        }
        ( $chirality, $opposite ) = ( $opposite, $chirality );
        return '@TB' . $chirality if $order[1] < $order[2];
        return '@TB' . $opposite;
    } else {
        # Axis has changed
        my @axis_now = ( (first { $order[$_] == $axis[0] } 0..4),
                         (first { $order[$_] == $axis[1] } 0..4) );
        $chirality = 1 +  first { $TB[$_]->{axis}[0] == $axis_now[0] + 1 &&
                                  $TB[$_]->{axis}[1] == $axis_now[1] + 1 &&
                                  $TB[$_]->{order}   eq $order } 0..$#TB;
        $opposite = $TB[$chirality - 1]->{opposite};
        @order = grep { $_ != $axis_now[0] && $_ != $axis_now[1] } @order;
        while( $order[0] != min @order ) {
            push @order, shift @order;
        }
        return '@TB' . $chirality if $order[1] < $order[2];
        return '@TB' . $opposite;
    }
}

sub _octahedral_chirality
{
    my $chirality = pop @_;
    my @order = @_;

    $chirality = int substr $chirality, 3;
    my $OH = $OH[$chirality - 1];
}

sub _order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$a}{number} <=>
                        $vertices->{$b}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

1;
