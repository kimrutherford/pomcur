package PomCur::Chado::InteractionAnnotationLookup;

=head1 NAME

PomCur::Chado::InteractionAnnotationLookup - Lookup interactions in Chado

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Chado::InteractionAnnotationLookup

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Moose;

with 'PomCur::Role::Configurable';
with 'PomCur::Chado::ChadoLookup';

=head2

 Usage   : my $res = PomCur::Chado::InteractionAnnotationLookup($options);
 Function: lookup interaction annotation in a Chado database
 Args    : $options->{pub_uniquename} - the identifier of the publication,
               usually the PubMed ID to get annotations for
           $options->{gene_identifier} - the gene identifier to use to constrain
               the search; only annotations for the gene are returned (optional)
           $options->{interaction_type} - "physical" or "genetic"
 Returns : An array reference of annotation results:
            [ {
              gene => {
                identifier => "SPAC22F3.13",
                name => 'tsc1',
                organism_taxonid => 4896
              },
              publication => {
                uniquename => 'PMID:10467002',
              },
              evidence_code => 'Phenotypic Enhancement',
              interacting_gene => { ... },
            }, ... ]
          - where annotation_id is a unique ID for this annotation

=cut

sub lookup
{
  my $self = shift;
  my $args_ref = shift;
  my %args = %{$args_ref};

  my $pub_uniquename = $args{pub_uniquename};
  my $gene_identifier = $args{gene_identifier};
  my $interaction_type_name = $args{interaction_type_name};

  my $schema = $self->schema();

  my $interaction_types_cv =
    $schema->resultset('Cv')->find({ name => 'PomBase interaction types' }) //
    $schema->find_with_type('Cv', { name => 'interaction types' });

  my $interaction_type_cvterm;

  if ($interaction_type_name eq 'genetic_interaction') {
    $interaction_type_cvterm =
      $schema->find_with_type('Cvterm',
                              { name => 'interacts_genetically',
                                cv_id => $interaction_types_cv->cv_id() });
  } else {
    $interaction_type_cvterm =
      $schema->find_with_type('Cvterm',
                              { name => 'interacts_physically',
                                cv_id => $interaction_types_cv->cv_id() });
  }

  my $pub = $schema->resultset('Pub')->find({ uniquename => $pub_uniquename });

  if (!defined $pub) {
    return [];
  }

  my $relations = $pub
      ->search_related('feature_relationship_pubs')
      ->search_related('feature_relationship')
      ->search({ 'feature_relationship.type_id' => $interaction_type_cvterm->cvterm_id() },
               { prefetch => [
                 { subject => 'organism' },
                 { object => 'organism' } ] });

  my @res = ();

  while (defined (my $rel = $relations->next())) {
    my $subject = $rel->subject();
    my $object = $rel->object();

    my $rel_props = $rel->feature_relationshipprops();

    my $evidence_code = undef;

    for my $prop ($rel_props->all()) {
      if ($prop->type()->name() eq 'evidence') {
        $evidence_code = $prop->value(),
      }
    }

    push @res, {
      gene => {
        identifier => $subject->uniquename(),
        name => $subject->name(),
        taxonid => $subject->organism()->taxonid(),
      },
      interacting_gene => {
        identifier => $object->uniquename(),
        name => $object->name(),
        taxonid => $object->organism()->taxonid(),
      },
      publication => {
        uniquename => $pub_uniquename,
      },
      evidence_code => $evidence_code,
    };

  }

  return \@res;
}

1;