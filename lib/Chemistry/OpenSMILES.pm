package Chemistry::OpenSMILES;

use strict;
use warnings;
use 5.0100;

# ABSTRACT: OpenSMILES format reader and writer
# VERSION

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    is_aromatic
);

sub is_aromatic($)
{
    my( $atom ) = @_;
    return $atom->{symbol} ne ucfirst $atom->{symbol};
}

sub _validate($)
{
    my( $moiety ) = @_;

    for my $atom (sort { $a->{number} <=> $b->{number} } $moiety->vertices) {
        # TODO: TH and AL chiral centers also have to be checked
        if( $atom->{chirality} && $atom->{chirality} =~ /^@@?$/ &&
            $moiety->degree($atom) < 4 ) {
            # FIXME: tetrahedral allenes are false-positives
            warn sprintf 'chiral center %s(%d) has %d bonds while ' .
                         'at least 4 is required' . "\n",
                         $atom->{symbol},
                         $atom->{number},
                         $moiety->degree($atom);
        }

        # FIXME: this code yields false-positives, see COD entries
        # 1100780 and 1547257
        my %bond_types;
        for my $neighbour ($moiety->neighbours($atom)) {
            next if !$moiety->has_edge_attribute( $atom, $neighbour, 'bond' );
            my  $bond_type = $moiety->get_edge_attribute( $atom, $neighbour, 'bond' );
            if( $bond_type =~ /^[\\\/]$/ &&
                $atom->{number} > $neighbour->{number} ) {
                $bond_type = $bond_type eq '\\' ? '/' : '\\';
            }
            $bond_types{$bond_type}++;
        }
        foreach ('/', '\\') {
            if( $bond_types{$_} && $bond_types{$_} > 1 ) {
                warn sprintf 'atom %s(%d) has %d bonds of type \'%s\', ' .
                             'cis/trans definitions must not conflict' . "\n",
                             $atom->{symbol},
                             $atom->{number},
                             $bond_types{$_},
                             $_;
            }
        }
    }

    # TODO: cis/trans bond not next to a double bond
    # TODO: SP, TB, OH chiral centers
}

1;

__END__

=pod

=head1 NAME

Chemistry::OpenSMILES - OpenSMILES format reader and writer

=head1 SYNOPSIS

    use Chemistry::OpenSMILES::Parser;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( 'C#C.c1ccccc1' );

    $\ = "\n";
    for my $moiety (@moieties) {
        #  $moiety is a Graph::Undirected object
        print scalar $moiety->vertices;
        print scalar $moiety->edges;
    }

    use Chemistry::OpenSMILES::Writer qw(write_SMILES);

    print write_SMILES( \@moieties );

=head1 DESCRIPTION

Chemistry::OpenSMILES provides support for SMILES chemical identifiers
conforming to OpenSMILES v1.0 specification
(L<http://opensmiles.org/opensmiles.html>).

Chemistry::OpenSMILES::Parser reads in SMILES strings and returns them
parsed to arrays of L<Graph::Undirected|Graph::Undirected> objects. Each
atom is represented by a hash.

Chemistry::OpenSMILES::Writer performs the inverse operation. Generated
SMILES strings are by no means optimal.

=head2 Molecular graph

Disconnected parts of a compound are represented as separate
L<Graph::Undirected|Graph::Undirected> objects. Atoms are represented
as vertices, and bonds are represented as edges.

=head3 Atoms

Atoms, or vertices of a molecular graph, are represented as hash
references:

    {
        "symbol"    => "C",
        "isotope"   => 13,
        "chirality" => "@@",
        "hcount"    => 3,
        "charge"    => 1,
        "class"     => 0,
        "number"    => 0,
    }

Except for C<symbol>, C<class> and C<number>, all keys of hash are
optional. Per OpenSMIILES specification, default values for C<hcount>
and C<class> are 0.

=head3 Bonds

Bonds, or edges of a molecular graph, rely completely on
L<Graph::Undirected|Graph::Undirected> internal representation. Bond
orders other than single (C<->, which is also a default) are represented
as values of edge attribute C<bond>. They correspond to the symbols used
in OpenSMILES specification.

=head1 CAVEATS

Element symbols in square brackets are not limited to the ones known to
chemistry. Currently any single or two-letter symbol is allowed.

Deprecated charge notations (C<--> and C<++>) are supported.

OpenSMILES specification mandates a strict order of ring bonds and
branches:

    branched_atom ::= atom ringbond* branch*

Chemistry::OpenSMILES::Parser supports both the mandated, and inverted
structure, where ring bonds follow branch descriptions.

Whitespace is not supported yet. SMILES descriptors must be cleaned of
it before attempting reading with Chemistry::OpenSMILES::Parser.

The derivation of implicit hydrogen counts for aromatic atoms is not
unambiguously defined in the OpenSMILES specification. Thus only
aromatic carbon is accounted for as if having valence of 3.

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut
