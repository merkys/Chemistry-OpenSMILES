package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Graph::Traversal::DFS;

# ABSTRACT: OpenSMILES format writer
# VERSION

sub write
{
    my( $what, $order_sub ) = @_;

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    $order_sub = \&_order unless $order_sub;

    for my $graph (@moieties) {
        my @symbols;
        my %vertex_symbols;
        my $nrings = 0;
        my %seen_rings;

        my $operations = {
            tree_edge     => sub { push @symbols, _tree_edge( @_ ) },
            non_tree_edge => sub { return if $seen_rings{join '|', sort @_[0..1]};
                                   $nrings++;
                                   ${$vertex_symbols{$_[0]}} .=
                                        _depict_bond( @_[0..1], $graph ) .
                                        $nrings;
                                   ${$vertex_symbols{$_[1]}} .=
                                        _depict_bond( @_[0..1], $graph ) .
                                        $nrings;
                                   $seen_rings{join '|', sort @_[0..1]} = 1; },

            pre  => sub { push @symbols, _pre_vertex( @_ );
                          $vertex_symbols{$_[0]} = \$symbols[-1] },
            post => sub { push @symbols, ')' },
        };

        if( $order_sub ) {
            $operations->{first_root} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
            $operations->{next_successor} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
        }

        my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
        $traversal->dfs;

        next unless @symbols;
        push @components, '(' . join '', @symbols;
    }

    return join '.', @components;
}

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    return '(' . _depict_bond( $u, $v, $self->graph );
}

sub _pre_vertex
{
    my( $vertex, $self ) = @_;

    # FIXME: proper atom depiction is required
    return $vertex->{symbol};
}

sub _depict_bond
{
    my( $u, $v, $graph ) = @_;

    # CAVEAT: '/' and '\' bonds are problematic
    return $graph->has_edge_attribute( $u, $v, 'bond' )
         ? $graph->get_edge_attribute( $u, $v, 'bond' )
         : '';
}

sub _order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$a}{number} <=>
                        $vertices->{$b}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

1;
