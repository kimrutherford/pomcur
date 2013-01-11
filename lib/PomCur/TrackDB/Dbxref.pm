use utf8;
package PomCur::TrackDB::Dbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::TrackDB::Dbxref

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<dbxref>

=cut

__PACKAGE__->table("dbxref");

=head1 ACCESSORS

=head2 dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 db_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 accession

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "dbxref_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "db_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "accession",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("dbxref_id");

=head1 RELATIONS

=head2 cvterm_dbxrefs

Type: has_many

Related object: L<PomCur::TrackDB::CvtermDbxref>

=cut

__PACKAGE__->has_many(
  "cvterm_dbxrefs",
  "PomCur::TrackDB::CvtermDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterms

Type: has_many

Related object: L<PomCur::TrackDB::Cvterm>

=cut

__PACKAGE__->has_many(
  "cvterms",
  "PomCur::TrackDB::Cvterm",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 db

Type: belongs_to

Related object: L<PomCur::TrackDB::Db>

=cut

__PACKAGE__->belongs_to(
  "db",
  "PomCur::TrackDB::Db",
  { db_id => "db_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-31 21:59:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AABHQYzGy6TbxgLIwOZqTQ

=head2 db_accession

 Usage   : my $db_accession = $dbxref->db_accession();
 Function: Return the identifier for this term in "<db>:<identifier>" form,
           eg. "GO:0004022"
 Args    : none
 Returns : the database accession

=cut
sub db_accession
{
  my $dbxref = shift;

  my $db = $dbxref->db();

  return $db->name() . ':' . $dbxref->accession();
}


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
