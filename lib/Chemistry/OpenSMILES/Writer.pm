package Chemistry::OpenSMILES::Writer;

# ABSTRACT: OpenSMILES format writer
# VERSION

use strict;
use warnings;

use Chemistry::OpenSMILES qw(
    %bond_symbol_to_order
    %normal_valence
    can_unsprout_hydrogen
    is_aromatic
    is_chiral
    is_chiral_octahedral
    is_chiral_planar
    is_chiral_tetrahedral
    is_chiral_trigonal_bipyramidal
    toggle_cistrans
    valence
);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo::Tables qw( @OH @TB );
use Graph::Traversal::DFS;
use List::Util qw( all any first min none sum0 uniq );
use Set::Object qw( set );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    write_SMILES
);

my %shape_to_SP = ( 'U' => '@SP1', '4' => '@SP2', 'Z' => '@SP3' );
my %SP_to_shape = reverse %shape_to_SP;

# write_SMILES() does not necessary respect the order subroutine: if performs DFS guided by the requested order.
# Thus before calling write_SMILES(), the exact post-order is not known.
# Only pre-order is known, thus relative properties, such as cis/trans markers, have to be adjusted to pre-order.
# Thus order-dependent markers have to be adjusted to pre-order.
sub write_SMILES
{
    my( $what, $options ) = @_;
    # Backwards compatibility with the old API where second parameter was
    # a subroutine reference for ordering:
    my $order_sub = defined $options && ref $options eq 'CODE' ? $options : \&_order;
    $options = {} unless defined $options && ref $options eq 'HASH';

    $options->{explicit_aromatic_bonds} = 1
        unless exists $options->{explicit_aromatic_bonds};
    $options->{immediately_reuse_ring_numbers} = 1
        unless exists $options->{immediately_reuse_ring_numbers};

    $order_sub = $options->{order_sub} if $options->{order_sub};
    my $raw = $options->{raw};

    # Subroutine will also accept and properly represent a single atom:
    return _depict_atom( $what, undef, $options ) if ref $what eq 'HASH';

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    for my $graph (@moieties) {
        my %seen;
        my %discovered_from;
        my @ring_bonds;

        my $operations = {
            tree_edge     => sub { my( $u, $v ) = @_;
                                   ( $u, $v ) = ( $v, $u ) if $seen{$v};
                                   $discovered_from{$v} = $u },

            non_tree_edge => sub { push @ring_bonds, [ @_[0..1] ] },

            pre => sub { $seen{$_[0]} = 1 },

            next_root => undef,
        };

        $operations->{first_root} =
            sub { $order_sub->( $_[1], $_[0]->graph ) };
        $operations->{next_successor} =
            sub { $order_sub->( $_[1], $_[0]->graph ) };

        my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
        $traversal->dfs;
        my @order = $traversal->preorder;
        my $order_by_vertex = sub { first { $order[$_] == $_[0] } 0..$#order };

        if( @order != $graph->vertices ) {
            warn $graph->vertices - @order . ' unreachable atom(s) detected in moiety' . "\n";
        }

        next unless @order;

        if( $options->{unsprout_hydrogens} ) {
            @order = grep { !can_unsprout_hydrogen( $graph, $_ ) } @order;
        }

        # Create both old and new ring data structures
        my $rings;
        for my $ring_bond (@ring_bonds) {
            my @sorted = sort { $order_by_vertex->($a) <=> $order_by_vertex->($b) } @$ring_bond;
            $rings->{$order_by_vertex->($ring_bond->[0])}
                    {$order_by_vertex->($ring_bond->[1])} =
            $rings->{$order_by_vertex->($ring_bond->[1])}
                    {$order_by_vertex->($ring_bond->[0])} =
                    { bond => _depict_bond( @sorted, $graph, $options ) };
        }

        # Deal with chirality
        my %chirality;
        for my $atom (@order) {
            next unless is_chiral $atom;
            next unless is_chiral_tetrahedral( $atom ) ||
                        is_chiral_planar( $atom ) ||
                        is_chiral_trigonal_bipyramidal( $atom ) ||
                        is_chiral_octahedral( $atom );

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

            next unless exists $atom->{chirality_neighbours};

            my $chirality_now = $atom->{chirality};
            if( @neighbours != @{$atom->{chirality_neighbours}} ) {
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
                $indices{$order_by_vertex->($atom->{chirality_neighbours}[$_])} = $pos;
            }

            my @order_new;
            # In the newly established order, the atom from which this one
            # is discovered (left hand side) will be the first, if any
            if( $discovered_from{$atom} ) {
                push @order_new,
                     $indices{$order_by_vertex->($discovered_from{$atom})};
            }
            # Second, there will be ring bonds as they are added before all of the neighbours
            if( $rings->{$order_by_vertex->($atom)} ) {
                push @order_new, map  { $indices{$_} }
                                 sort { $a <=> $b }
                                 keys %{$rings->{$order_by_vertex->($atom)}};
            }
            # Finally, all neighbours are added, uniq will remove duplicates
            push @order_new, map  { $indices{$_} }
                             sort { $a <=> $b }
                             map  { $order_by_vertex->($_) }
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
                $chirality_now = _octahedral_chirality( @order_new, $chirality_now );
            }
            $chirality{$atom} = $chirality_now;
        }

        # Write the SMILES
        my $component = '';
        my @ring_ids = ( 1..99, 0 );
        for my $i (0..$#order) {
            my $vertex = $order[$i];
            if( $discovered_from{$vertex} ) {
                if( $options->{explicit_parentheses} ||
                    _has_more_unseen_children( $discovered_from{$vertex}, $i, $order_by_vertex, $graph, $rings, $options ) ) {
                    $component .= '(';
                }
                $component .= _depict_bond( $discovered_from{$vertex}, $vertex, $graph, $options );
            }
            if( $chirality{$vertex} ) {
                $component .=
                    _depict_atom( { %$vertex, chirality => $chirality{$vertex} },
                                  $graph,
                                  { %$options, raw => 1 } );
            } else {
                $component .=
                    _depict_atom( $vertex,
                                  $graph,
                                  { %$options, omit_chirality => 1 } );
            }
            if( $rings->{$i} ) {
                my @rings_closed;
                for my $j (sort { $a <=> $b } keys %{$rings->{$i}}) {
                    if( $i < $j ) {
                        if( !@ring_ids ) {
                            # All 100 rings are open now.
                            # There is no other solution but to terminate the program.
                            die 'cannot represent more than 100 open ring bonds' . "\n";
                        }
                        $rings->{$i}{$j}{ring} = shift @ring_ids;
                        $component .=  $rings->{$i}{$j}{bond} .
                                      ($rings->{$i}{$j}{ring} < 10 ? '' : '%') .
                                       $rings->{$i}{$j}{ring}
                    } else {
                        $component .= toggle_cistrans( $rings->{$j}{$i}{bond} ) .
                                      ($rings->{$i}{$j}{ring} < 10 ? '' : '%') .
                                       $rings->{$j}{$i}{ring};
                        if( $options->{immediately_reuse_ring_numbers} ) {
                            # Ring bond '0' must stay in the end
                            @ring_ids = sort { ($a == 0) - ($b == 0) || $a <=> $b }
                                             ($rings->{$j}{$i}{ring}, @ring_ids);
                        } else {
                            push @rings_closed, $rings->{$j}{$i}{ring};
                        }
                    }
                }
                if( !$options->{immediately_reuse_ring_numbers} ) {
                    @ring_ids = sort { ($a == 0) - ($b == 0) || $a <=> $b }
                                     (@rings_closed, @ring_ids);
                }
            }
            my $where = $i < $#order ? $discovered_from{$order[$i+1]} : $order[0];
            while( $vertex != $where ) {
                if( $options->{explicit_parentheses} ||
                    _has_more_unseen_children( $discovered_from{$vertex}, $i, $order_by_vertex, $graph, $rings, $options ) ) {
                    $component .= ')';
                }
                $vertex = $discovered_from{$vertex};
            }
        }

        push @components, $component;
    }

    return join '.', @components;
}

# DEPRECATED
sub write { &write_SMILES }

sub _depict_atom
{
    my( $vertex, $graph, $options ) = @_;
    $options = {} unless $options;
    my( $omit_chirality,
        $raw ) =
      ( $options->{omit_chirality},
        $options->{raw} );

    my $atom = $vertex->{symbol};
    my $is_simple = $atom =~ /^[bcnosp]$/i ||
                    $atom =~ /^(F|Cl|Br|I|\*)$/;

    if( exists $vertex->{isotope} ) {
        $atom = $vertex->{isotope} . $atom;
        $is_simple = 0;
    }

    if( is_chiral $vertex && !$omit_chirality ) {
        $atom .= $vertex->{chirality};
        $is_simple = 0;
    }

    my $hcount = $vertex->{hcount} ? $vertex->{hcount} : 0;
    if( $options->{unsprout_hydrogens} && $atom ne 'H' ) {
        $hcount += grep { can_unsprout_hydrogen( $graph, $_ ) }
                        $graph->neighbours( $hcount );
    }

    # Decide what to do to atoms with usual/unusual valences
    if(  $is_simple && $graph && !$raw && $normal_valence{ucfirst $atom} &&
        !$vertex->{charge} &&
        !$vertex->{class} ) {
        my $valence = valence( $graph, $vertex );
        if( any { $_ == $valence } @{$normal_valence{ucfirst $atom}} ) {
            # Usual valence detected, no need to keep hcount
            $hcount = 0 if $options->{remove_implicit_hydrogens};
        } else {
            # Unusual valence detected, need square brackets
            $is_simple = 0;
        }
    }

    if( $hcount ) { # if non-zero
        $atom .= 'H' . ($hcount == 1 ? '' : $hcount);
        $is_simple = 0;
    }
    $is_simple = 0 if $raw && exists $vertex->{hcount};

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

# _depict_bond() gets vertices in order of their appearance in the post-order.
# It flips '/' <=> '\' if post-order is opposite from pre-order.
sub _depict_bond
{
    my( $u, $v, $graph, $options ) = @_;

    my $n_aromatic = grep { is_aromatic $_ } ( $u, $v );

    if( !$graph->has_edge_attribute( $u, $v, 'bond' ) ) {
        return $n_aromatic == 2 ? '-' : '';
    }

    my $bond = $graph->get_edge_attribute( $u, $v, 'bond' );
    return '' if $bond eq ':' && $n_aromatic && !$options->{explicit_aromatic_bonds};
    return $bond if $u->{number} < $v->{number};
    return toggle_cistrans $bond;
}

sub _has_more_unseen_children
{
    my( $vertex, $i, $order_by_vertex, $graph, $rings ) = @_;
    my $orders = set( grep { $_ > $i }
                      grep { defined $_ }
                      map  { $order_by_vertex->($_) }
                           $graph->neighbours( $vertex ) );
    $orders->remove( keys %{$rings->{$order_by_vertex->($vertex)}} )
        if $rings->{$order_by_vertex->($vertex)};
    return $orders->size;
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
            "numbers '0', '1', '2' and '3', unexpected input received\n";
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
    my @target = @_;

    if( join( ',', sort @target ) ne '0,1,2,3,4' ) {
        die '_trigonal_bipyramidal_chirality() accepts only permutations of ' .
            "numbers '0', '1', '2', '3' and '4', unexpected input received\n";
    }

    $chirality =~ s/^\@TB//;
    $chirality = int $chirality;

    my $TB = $TB[$chirality - 1];

    # First on, decode the source.
    # Axis will stay on @axis, and sides will be stored on @sides
    my @axis  = map { $_ - 1 } @{$TB->{axis}};
    my @sides = grep { $_ != $axis[0] && $_ != $axis[1] } 0..4;

    # Find the new location of the axis, remove it from @target
    my @axis_location = ( ( first { $target[$_] == $axis[0] } 0..4 ),
                          ( first { $target[$_] == $axis[1] } 0..4 ) );
    @target = grep { $_ != $axis[0] && $_ != $axis[1] } @target;

    # Invert the axis if needed
    if( $axis_location[0] > $axis_location[1] ) {
        @axis_location = reverse @axis_location;
        @target        = reverse @target;
    }

    # Cycle the sides clockwise until the first is aligned
    while( $sides[0] != $target[0] ) {
        push @sides, shift @sides;
    }
    my $order = $TB->{order};
    $order = $order eq '@' ? '@@' : '@' unless $sides[1] == $target[1];

    $chirality = 1 + first { $TB[$_]->{order} eq $order &&
                             $TB[$_]->{axis}[0] == $axis_location[0] + 1 &&
                             $TB[$_]->{axis}[1] == $axis_location[1] + 1 }
                           0..$#TB;
    return '@TB' . $chirality;
}

sub _octahedral_chirality
{
    my $chirality = pop @_;
    my @target = @_;

    if( join( ',', sort @target ) ne '0,1,2,3,4,5' ) {
        die '_octahedral_chirality() accepts only permutations of ' .
            "numbers '0', '1', '2', '3', '4' and '5, unexpected input received\n";
    }

    $chirality =~ s/^\@OH//;
    $chirality = int $chirality;

    # First on, decode the source.
    # Axis will stay on @axis, and sides will be stored on @sides in contiguous clockwise order.
    my @axis  = map { $_ - 1 } @{$OH[$chirality-1]->{axis}};
    my @sides = grep { $_ != $axis[0] && $_ != $axis[1] } 0..5;

    if( $OH[$chirality-1]->{shape} eq 'Z' ) {
        ( $sides[2], $sides[3] ) = ( $sides[3], $sides[2] );
    }

    if( $OH[$chirality-1]->{shape} eq '4' ) {
        ( $sides[0], $sides[3] ) = ( $sides[3], $sides[0] );
    }

    # Adjust for enumeration direction
    @sides = reverse @sides if $OH[$chirality-1]->{order} eq '@';

    # Align the axis start
    if(      $axis[0] == $target[0] ) { # same axis start, do nothing
    } elsif( $axis[1] == $target[0] ) { # axis inversion
        @axis  = reverse @axis;
        @sides = reverse @sides;
    } else { # axis start at one of the sides
        my $axis_index = first { $sides[$_] == $target[0] } 0..3;
        my @axis_now = ( $sides[$axis_index], $sides[($axis_index + 2) % 4] );
        ( $sides[$axis_index], $sides[($axis_index + 2) % 4] ) = reverse @axis;
        @axis = @axis_now;
    }

    shift @target; # axis start is no longer needed
    my $axis_end = first { $target[$_] == $axis[1] } 0..4;
    @target = map { $target[$_] } grep { $_ != $axis_end } 0..4; # remove axis end

    # Cycle the sides clockwise until the first is aligned
    while( $sides[0] != $target[0] ) {
        push @sides, shift @sides;
    }
    shift @sides;
    shift @target;

    # Check the alignment of the other sides to find the shape and order
    my $shape;
    my $order;
    if(      $target[0] == $sides[0] && $target[1] == $sides[1] ) {
        ( $shape, $order ) = ( 'U', '@@' );
    } elsif( $target[0] == $sides[0] && $target[1] == $sides[2] ) {
        ( $shape, $order ) = ( 'Z', '@@' );
    } elsif( $target[0] == $sides[1] && $target[1] == $sides[0] ) {
        ( $shape, $order ) = ( '4', '@' );
    } elsif( $target[0] == $sides[1] && $target[1] == $sides[2] ) {
        ( $shape, $order ) = ( '4', '@@' );
    } elsif( $target[0] == $sides[2] && $target[1] == $sides[0] ) {
        ( $shape, $order ) = ( 'Z', '@' );
    } elsif( $target[0] == $sides[2] && $target[1] == $sides[1] ) {
        ( $shape, $order ) = ( 'U', '@' );
    } else {
        die 'unexpected situation achieved in _octahedral_chirality()' . "\n";
    }
    $chirality = 1 + first { $OH[$_]->{shape}   eq $shape &&
                             $OH[$_]->{order}   eq $order &&
                             $OH[$_]->{axis}[1] == $axis_end + 2 }
                           0..$#OH;
    return '@OH' . $chirality;
}

sub _order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$a}{number} <=>
                        $vertices->{$b}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

1;
