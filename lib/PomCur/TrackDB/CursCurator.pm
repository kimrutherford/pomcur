use utf8;
package PomCur::TrackDB::CursCurator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PomCur::TrackDB::CursCurator

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<curs_curator>

=cut

__PACKAGE__->table("curs_curator");

=head1 ACCESSORS

=head2 curs_curator_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 curs

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 curator

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 creation_date

  data_type: 'timestamp'
  is_nullable: 0

=head2 accepted_date

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "curs_curator_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "curs",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "curator",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creation_date",
  { data_type => "timestamp", is_nullable => 0 },
  "accepted_date",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</curs_curator_id>

=back

=cut

__PACKAGE__->set_primary_key("curs_curator_id");

=head1 RELATIONS

=head2 curator

Type: belongs_to

Related object: L<PomCur::TrackDB::Person>

=cut

__PACKAGE__->belongs_to(
  "curator",
  "PomCur::TrackDB::Person",
  { person_id => "curator" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 curs

Type: belongs_to

Related object: L<PomCur::TrackDB::Curs>

=cut

__PACKAGE__->belongs_to(
  "curs",
  "PomCur::TrackDB::Curs",
  { curs_id => "curs" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-03 08:54:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pk+T6BfYov5DaPiQnwCQ0Q

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

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
