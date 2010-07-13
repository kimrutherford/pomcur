package PomCur::TrackDB::Cvterm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cvterm");
__PACKAGE__->add_columns(
  "cvterm_id",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "cv_id",
  { data_type => "int", default_value => undef, is_nullable => 0, size => undef },
  "name",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "definition",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dbxref_id",
  { data_type => "int", default_value => undef, is_nullable => 0, size => undef },
  "is_obsolete",
  { data_type => "int", default_value => 0, is_nullable => 0, size => undef },
  "is_relationshiptype",
  { data_type => "int", default_value => 0, is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("cvterm_id");
__PACKAGE__->belongs_to("cv", "PomCur::TrackDB::Cv", { cv_id => "cv_id" });
__PACKAGE__->has_many(
  "pubstatuses",
  "PomCur::TrackDB::Pubstatus",
  { "foreign.status" => "self.cvterm_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-13 18:09:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z0BP3G7dM6luhavSSriN3A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
