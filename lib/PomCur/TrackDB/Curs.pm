use utf8;
package PomCur::TrackDB::Curs;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::TrackDB::Curs

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<curs>

=cut

__PACKAGE__->table("curs");

=head1 ACCESSORS

=head2 curs_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 assigned_curator

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pub

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 curs_key

  data_type: 'text'
  is_nullable: 0

=head2 creation_date

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "curs_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "assigned_curator",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pub",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "curs_key",
  { data_type => "text", is_nullable => 0 },
  "creation_date",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</curs_id>

=back

=cut

__PACKAGE__->set_primary_key("curs_id");

=head1 RELATIONS

=head2 assigned_curator

Type: belongs_to

Related object: L<PomCur::TrackDB::Person>

=cut

__PACKAGE__->belongs_to(
  "assigned_curator",
  "PomCur::TrackDB::Person",
  { person_id => "assigned_curator" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 curs_curators

Type: has_many

Related object: L<PomCur::TrackDB::CursCurator>

=cut

__PACKAGE__->has_many(
  "curs_curators",
  "PomCur::TrackDB::CursCurator",
  { "foreign.curs" => "self.curs_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cursprops

Type: has_many

Related object: L<PomCur::TrackDB::Cursprop>

=cut

__PACKAGE__->has_many(
  "cursprops",
  "PomCur::TrackDB::Cursprop",
  { "foreign.curs" => "self.curs_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub

Type: belongs_to

Related object: L<PomCur::TrackDB::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "PomCur::TrackDB::Pub",
  { pub_id => "pub" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-31 21:59:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h7gyTLDt/wN2JzsfghLuLQ

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

use Carp;
use PomCur::Util;

sub new {
  my ( $class, $attrs ) = @_;

  if (defined $attrs->{creation_date}) {
    croak "don't set creation_date in the constructor - it defaults to now";
  }

  $attrs->{creation_date} = PomCur::Util::get_current_datetime();

  my $new = $class->next::method($attrs);

  return $new;
}

1;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
