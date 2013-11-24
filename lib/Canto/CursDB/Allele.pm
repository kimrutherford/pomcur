use utf8;
package Canto::CursDB::Allele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Canto::CursDB::Allele

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<allele>

=cut

__PACKAGE__->table("allele");

=head1 ACCESSORS

=head2 allele_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 primary_identifier

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 gene

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "allele_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "primary_identifier",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "gene",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</allele_id>

=back

=cut

__PACKAGE__->set_primary_key("allele_id");

=head1 RELATIONS

=head2 allele_genotypes

Type: has_many

Related object: L<Canto::CursDB::AlleleGenotype>

=cut

__PACKAGE__->has_many(
  "allele_genotypes",
  "Canto::CursDB::AlleleGenotype",
  { "foreign.allele" => "self.allele_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene

Type: belongs_to

Related object: L<Canto::CursDB::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Canto::CursDB::Gene",
  { gene_id => "gene" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-29 18:14:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9OVSoU8MchuwXKPiNPhr0w

__PACKAGE__->many_to_many('annotations' => 'allele_annotations',
                          'annotation');

use Canto::Curs::Utils;

=head2 display_name

 Usage   : my $display_name = $allele->display_name();
 Function: Return the name and description as one string of the form
           "name(description)";
 Args    : none

=cut
sub display_name
{
  my $self = shift;

  return Canto::Curs::Utils::make_allele_display_name($self->name(),
                                                       $self->description());
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
