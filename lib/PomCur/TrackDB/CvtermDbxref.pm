use utf8;
package PomCur::TrackDB::CvtermDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::TrackDB::CvtermDbxref

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<cvterm_dbxref>

=cut

__PACKAGE__->table("cvterm_dbxref");

=head1 ACCESSORS

=head2 cvterm_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_for_definition

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cvterm_dbxref_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_for_definition",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cvterm_dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("cvterm_dbxref_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cvterm_id_dbxref_id_unique>

=over 4

=item * L</cvterm_id>

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cvterm_id_dbxref_id_unique", ["cvterm_id", "dbxref_id"]);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<PomCur::TrackDB::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "PomCur::TrackDB::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 dbxref

Type: belongs_to

Related object: L<PomCur::TrackDB::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "PomCur::TrackDB::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-31 21:59:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+Yff5+g268KzHiocNEzOGw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
