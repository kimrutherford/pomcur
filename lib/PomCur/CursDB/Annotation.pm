use utf8;
package PomCur::CursDB::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::CursDB::Annotation

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<annotation>

=cut

__PACKAGE__->table("annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 status

  data_type: 'text'
  is_nullable: 0

=head2 pub

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 creation_date

  data_type: 'text'
  is_nullable: 0

=head2 data

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "status",
  { data_type => "text", is_nullable => 0 },
  "pub",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "creation_date",
  { data_type => "text", is_nullable => 0 },
  "data",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</annotation_id>

=back

=cut

__PACKAGE__->set_primary_key("annotation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<annotation_id_status_type_unique>

=over 4

=item * L</annotation_id>

=item * L</status>

=item * L</type>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "annotation_id_status_type_unique",
  ["annotation_id", "status", "type"],
);

=head1 RELATIONS

=head2 allele_annotations

Type: has_many

Related object: L<PomCur::CursDB::AlleleAnnotation>

=cut

__PACKAGE__->has_many(
  "allele_annotations",
  "PomCur::CursDB::AlleleAnnotation",
  { "foreign.annotation" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_annotations

Type: has_many

Related object: L<PomCur::CursDB::GeneAnnotation>

=cut

__PACKAGE__->has_many(
  "gene_annotations",
  "PomCur::CursDB::GeneAnnotation",
  { "foreign.annotation" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub

Type: belongs_to

Related object: L<PomCur::CursDB::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "PomCur::CursDB::Pub",
  { pub_id => "pub" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-11 23:28:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TwnwsW1NctI4poakpHZhfw


__PACKAGE__->many_to_many('genes' => 'gene_annotations', 'gene');
__PACKAGE__->many_to_many('alleles' => 'allele_annotations', 'allele');

use YAML qw(Load Dump);

__PACKAGE__->inflate_column('data', {
  inflate => sub { my @res = Load(shift); $res[0] },
  deflate => sub { Dump(shift) },
});


=head2 delete

 Usage   : $annotation->delete();
 Function: Delete this Annotation and any gene and allele references that
           depend on it
 Args    : none
 Returns : nothing

=cut
sub delete
{
  my $self = shift;

  $self->gene_annotations()->delete();
  $self->allele_annotations()->delete();
  $self->SUPER::delete();
}

__PACKAGE__->meta->make_immutable;

1;
