package PomCur::Track::OntologyLookup;

=head1 NAME

PomCur::Track::OntologyLookup - Lookup/search methods for ontologies

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Track::GOLookup

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Carp;
use Moose;

use String::Similarity;

use PomCur::Track::OntologyIndex;
use PomCur::Track::LoadUtil;

with 'PomCur::Role::Configurable';
with 'PomCur::Track::TrackAdaptor';

has load_util => (is => 'ro', isa => 'PomCur::Track::LoadUtil',
                  lazy_build => 1, init_arg => undef);

sub _build_load_util
{
  my $self = shift;

  return PomCur::Track::LoadUtil->new(schema => $self->schema());
}

sub _get_synonyms
{
  my $cvterm = shift;
  my $synonym_type = shift;

  my $synonyms = $cvterm->synonyms()->search({}, { prefetch => 'type' });

  return [
    grep {
      $_->{type} eq $synonym_type;
    } map {
      { name => $_->synonym(), type => $_->type()->name() };
    } $synonyms->all()
  ];
}

sub _make_term_hash
{
  my $cvterm = shift;
  my $cv_name = shift;
  my $include_definition = shift;
  my $include_children = shift;
  my $include_exact_synonyms = shift;
  my $matching_synonym = shift;

  my %term_hash = ();

  $term_hash{id} = $cvterm->db_accession();
  $term_hash{name} = $cvterm->name();
  if (defined $matching_synonym) {
    $term_hash{matching_synonym} = $matching_synonym;
  }
  my $annotation_namespace = $cvterm->cv()->name();
  $term_hash{annotation_namespace} = $annotation_namespace;

  if ($include_definition) {
    $term_hash{definition} = $cvterm->definition();
    my $comment_prop =
      $cvterm->cvtermprop_cvterms()->search({ 'type.name' => 'comment' },
                                            {
                                              join => 'type',
                                            })->first();
    if ($comment_prop) {
      $term_hash{comment} = $comment_prop->value();
    }
  }

  if ($include_children) {
    @{$term_hash{children}} = ();

    my @child_cvterms = $cvterm->cvterm_relationship_objects()
      ->search_related('subject', {}, { order_by => 'name' })->all();

    for my $child_cvterm (@child_cvterms) {
      if ($child_cvterm->cv()->name() eq $cv_name) {
        push @{$term_hash{children}}, {
          _make_term_hash($child_cvterm,
                          $child_cvterm->cv()->name(), 0, 0, 0)
        };
      }
    }
  }

  if ($include_exact_synonyms) {
    $term_hash{synonyms} = _get_synonyms($cvterm, 'exact');
  }

  return %term_hash;
}

sub _clean_string
{
  my $text = shift;

  $text =~ s/\W+/ /g;
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;

  return $text;
}


=head2 lookup

 Usage   : my $lookup = PomCur::Track::OntologyLookup->new(...);
           my $result = $lookup->lookup(search_string => $search_string,
                                        ontology_name => $ontology_name);
 Function: Return matching ontology terms from a given ontology
 Args    : ontology_name - the ontology to search
           search_string - the text to use when searching, if this is a ontology
                           ID (eg. "GO:0012345") return just that match
           max_results - maximum hits to return (ignored when search_string is
                         an ontology ID)
           include_children - include data about the child terms (default: 0)
           include_definition - include the definition for terms (default: 0)
           include_exact_synonyms - include all the exact synonyms in the result
 Returns : [ { id => '...', name => '...', definition => '...',
               matching_synonym => '...',
               children => [ { id => '...' }, { id => '...' }, ... ] } ]

           Note: if the search_string matches a synonym more exactly
           than it matches the cvterm name, the matching_synonym field
           is name that synonym, otherwise matching_synonym won't be
           returned in the hash

=cut
sub lookup
{
  my $self = shift;
  my %args = @_;

  my $ontology_name = $args{ontology_name};
  my $search_string = $args{search_string};
  my $max_results = $args{max_results} || 10;
  my $include_definition = $args{include_definition};
  my $include_children = $args{include_children};
  my $include_exact_synonyms = $args{include_exact_synonyms};

  my $config = $self->config();
  my $index_path = $config->data_dir_path('ontology_index_dir');
  my $ontology_index = PomCur::Track::OntologyIndex->new(index_path => $index_path);

  my @results;

  if ($search_string =~ /^\s*([a-zA-Z]+:\d+)\s*$/) {
    return [$self->lookup_by_id(id => $search_string,
                                include_definition => $include_definition,
                                include_children => $include_children,
                                include_exact_synonyms => $include_exact_synonyms)];
  } else {
    if (!defined $ontology_name || length $ontology_name == 0) {
      croak "no ontology_name passed to lookup()";
    }

    @results = $ontology_index->lookup($ontology_name, _clean_string($search_string),
                                       $max_results);

    my $schema = $self->schema();

    my @limited_hits = ();

    for my $result (@results) {
      my $doc = $result->{doc};
      my $cvterm_id = $doc->get('cvterm_id');
      my $term_name = $doc->get('term_name');
      my $cvterm = $schema->find_with_type('Cvterm', $cvterm_id);

      my %ret_hit = (
        doc => $doc, score => $result->{score},
        cvterm_id => $cvterm_id,
        cvterm_name => $term_name,
        cvterm => $cvterm,
        cv_name => $ontology_name,
      );

      if ($term_name ne $doc->get('text')) {
        $ret_hit{matching_synonym} = $doc->get('text');
      }

      push @limited_hits, \%ret_hit;
    }

    my @ret_list = ();

    for my $hit_hash (@limited_hits) {
      my $doc = $hit_hash->{doc};
      my $name = $doc->get('name');
      my $matching_synonym = $hit_hash->{matching_synonym};
      my $cvterm = $hit_hash->{cvterm};

      my %term_hash =
        _make_term_hash($cvterm,
                        $ontology_name,
                        $include_definition, $include_children,
                        $include_exact_synonyms,
                        $matching_synonym);

      push @ret_list, \%term_hash;
    }

    return \@ret_list;
  }
}


sub _find_cv
{
  my $self = shift;
  my $ontology_name = shift;

  my $cv = $self->schema()->resultset('Cv')->find({ name => $ontology_name });

  die "no cv with name: $ontology_name" unless defined $cv;

  return $cv;
}


=head2 lookup_by_name

 Usage   : my $result = $lookup->lookup_by_name(ontology_name => $ontology_name,
                                                term_name => $term_name);
 Function: Return the detail of the term that matches $term_name in the given
           ontology.
 Args    : ontology_name - the ontology to search
           term_name - the name of the term to find
           include_children - include data about the child terms (default: 0)
           include_definition - include the definition for terms (default: 0)
           include_exact_synonyms - include all the exact synonyms in the result
 Returns : A hash ref of details about the term, or undef if there is no term
           with that name.  The hash will have the same field as returned by
           lookup().
           eg.
           {
             name => '...',
             definition => '...',
             id => '...',
           }

=cut

sub lookup_by_name
{
  my $self = shift;
  my %args = @_;

  my $ontology_name = $args{ontology_name};
  if (!defined $ontology_name) {
    croak "no ontology_name passed to OntologyLookup::lookup_by_name()";
  }

  my $term_name = $args{term_name};

  my $include_definition = $args{include_definition};
  my $include_children = $args{include_children};
  my $include_exact_synonyms = $args{include_exact_synonyms};

  my $schema = $self->schema();

  my $cv = $self->_find_cv($ontology_name);
  my $cvterm = $schema->resultset('Cvterm')->find({ cv_id => $cv->cv_id(),
                                                    name => $term_name });

  if (!defined $cvterm) {
    my $synonym_rs =
      $schema->resultset('Cvtermsynonym')
        ->search({ synonym => $term_name })
        ->search_related('cvterm', { cv_id => $cv->cv_id() });;
    if ($synonym_rs->count() > 1) {
      die qq(more than one cvterm matching "$term_name");
    }

    if ($synonym_rs->count() == 1) {
      $cvterm = $synonym_rs->first();
    }
  }

  if (defined $cvterm) {
    return { _make_term_hash($cvterm, $cv->name(), $include_definition,
                             $include_children, $include_exact_synonyms) };
  } else {
    return undef;
  }
}

=head2 lookup_by_id

 Usage   : my $result = $lookup->lookup_by_id(id => $term_name);
 Function: Return the detail of the with the given id
 Args    : id - the id to search for
           include_children - include data about the child terms (default: 0)
           include_definition - include the definition for terms (default: 0)
 Returns : A hash ref of details about the term, or undef if there is no term
           with that id.  The hash will have the same field as returned by
           lookup().
           eg.
           {
             name => '...',
             definition => '...',
             id => '...',
           }

=cut

sub lookup_by_id
{
  my $self = shift;
  my %args = @_;

  my $include_definition = $args{include_definition};
  my $include_children = $args{include_children};
  my $include_exact_synonyms = $args{include_exact_synonyms};

  my $term_id = $args{id};
  if (!defined $term_id) {
    croak "no id passed to OntologyLookup::lookup_by_id()";
  }

  my $dbxref;

  eval {
    $dbxref = $self->load_util()->find_dbxref($term_id);
  };

  if (!defined $dbxref) {
    return undef;
  }

  my @terms = $dbxref->cvterms();

  if (@terms > 1) {
    die "internal error: looked up $term_id and got more than one result";
  }

  my $cvterm;

  if (@terms == 0) {
    my @cvterm_dbxrefs = $dbxref->cvterm_dbxrefs();

    if (@cvterm_dbxrefs > 1) {
      die "internal_error: looked up $term_id and got more than one " .
        "result via the cvterm_dbxref table";
    }

    if (@cvterm_dbxrefs == 0) {
      return undef;
    } else {
      $cvterm = $cvterm_dbxrefs[0]->cvterm();
    }
  } else {
    $cvterm = $terms[0];
  }

  return { _make_term_hash($cvterm, $cvterm->cv()->name(),
                           $include_definition, $include_children,
                           $include_exact_synonyms) };
}


=head2 get_all

 Usage   : my $lookup = PomCur::Track::OntologyLookup->new(...);
           my @all_terms = $lookup->get_all(ontology_name => $ontology_name,
                                            include_children => 1|0,
                                            include_definition => 1|0,
                                            include_exact_synonyms => 1|0);
 Function: Return all the terms from an ontology
 Args    : ontology_name - the ontology to search
           include_children - include data about the child terms (default: 0)
           include_definition - include the definition for terms (default: 0)
           include_exact_synonyms - include all the exact synonyms in the
                                    result (default: 0)
 Returns : returns an array of hashes in the same format as lookup()
           but with no matching_synonym keys

=cut
sub get_all
{
  my $self = shift;
  my %args = @_;

  my $ontology_name = $args{ontology_name};
  if (!defined $ontology_name) {
    croak "no ontology_name passed to OntologyLookup::get_all()";
  }

  my $include_definition = $args{include_definition};
  my $include_children = $args{include_children};
  my $include_exact_synonyms = $args{include_exact_synonyms};

  my $schema = $self->schema();
  my @ret_list = ();

  my $cv = $self->_find_cv($ontology_name);
  my $cvterm_rs = $schema->resultset('Cvterm')->search({ cv_id => $cv->cv_id() });

  while (defined (my $cvterm = $cvterm_rs->next())) {
    my %term_hash =
      _make_term_hash($cvterm, $ontology_name,
                      $include_definition, $include_children,
                      $include_exact_synonyms);

    push @ret_list, \%term_hash;
  }

  return @ret_list;
}

1;
