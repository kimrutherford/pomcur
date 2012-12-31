use utf8;
package PomCur::TrackDB::Cursprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::TrackDB::Cursprop

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<cursprop>

=cut

__PACKAGE__->table("cursprop");

=head1 ACCESSORS

=head2 cursprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 curs

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cursprop_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "curs",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cursprop_id>

=back

=cut

__PACKAGE__->set_primary_key("cursprop_id");

=head1 RELATIONS

=head2 cur

Type: belongs_to

Related object: L<PomCur::TrackDB::Curs>

=cut

__PACKAGE__->belongs_to(
  "cur",
  "PomCur::TrackDB::Curs",
  { curs_id => "curs" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<PomCur::TrackDB::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "PomCur::TrackDB::Cvterm",
  { cvterm_id => "type" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-31 21:59:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CkYus7oCqEAuNtgjITJ9vQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
