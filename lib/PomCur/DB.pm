package PomCur::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04006
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6MXa2PCFbpoh2+Fkr5IYsw

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::DB

You can also look for information at:

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Params::Validate qw(:all);
use Carp;

=head2 new

 Usage   : my $schema = PomCur::DB->new($c->config());
 Function: Return a new database connection (schema)
 Args    : $config - if null use the config file from the current directory
                     or some other default location (eg. /etc/smallrna.yaml)

=cut
sub new
{
  my $self = shift;
  my $smallrna_config = shift;

  if (!defined $smallrna_config) {
    croak "schema() needs a config hash as argument\n";
  }

  my $config_key = $self;

  my $config = $smallrna_config->{$config_key}{connect_info};

  if (!defined $config) {
    $config_key =~ s/.*::(.*)DB/Model::${1}Model/;
    $config = $smallrna_config->{$config_key}{connect_info};
    if (!defined $config) {
      die "can't find configuration for $self\n";
    }
  }

  return $self->connect($config->[0], $config->[1], $config->[2],
                        {
                         RaiseError => 1,
                         AutoCommit => 1
                        })
}

use PomCur::DB::ResultSet;

sub initialise {
  my $self = shift;
  for my $source (__PACKAGE__->sources()) {
    __PACKAGE__->source($source)->resultset_class('PomCur::DB::ResultSet');
  }
}

=head2 find_with_type

 Usage   : my $obj = $schema->find_with_type('Organism', 'abbreviation', 'SCHPO');
       or: my $obj = $schema->find_with_type('Organism', { genus => 'Arabidopsis',
                                                           species => 'thaliana' } );
 Function: Return the object of the given type that has the given key field with
           given value
 Args    : $type - an unqualified class name like 'Person'
           $field_name - the field name to use when searching
           $value - the value to search for
       or: $type - an unqualified class name like 'Person'
           $arg - reference of the hash or a scalar to pass to find
                  eg. $schema->find({...});  or  $schema->find(5);

=cut
sub find_with_type
{
  my $self = shift;
  my ($type, $arg, $value) = validate_pos(@_, 1, 1, 0);

  $type = ucfirst $type;

  my $rs = $self->resultset($type);

  my $obj;

  if (!defined $value) {
    $obj = $rs->find($arg);
    if (!defined $obj) {
      if (ref $arg) {
        my %args = %$arg;
        croak "error: could not find a '$type' with args: "
          . join "\n", map { "$_: $arg->{$_}" } keys %$arg;
      } else {
        croak "error: could not find a '$type' with arg: $arg";
      }
    }
  } else {
    my $field_name = $arg;
    $obj = $rs->find({ $field_name => $value });
    if (!defined $obj) {
      croak "error: could not find a '$type' with $field_name = '$value'\n";
    }
  }

  return $obj;
}

=head2 create_with_type

 Usage   : my $field_data = { first_name => 'Charles', last_name => 'Darwin',
                              organisation => $organisation };
           my $obj = $schema->create_with_type('Person', $field_data);
 Function: Create an object of the given type, initialising with the $field_data
 Args    : $type - an unqualified class name like 'Person'
           $field_data - a hashref containing all the fields to initialise in
           the new object
 Returns : a reference to the new object

=cut
sub create_with_type
{
  my $self = shift;
  my ($type, $field_data) = validate_pos(@_, 1, 1);

  my $rs = $self->resultset($type);

  my $obj = undef;

  eval {
    $obj = $rs->create($field_data);
  };
  if ($@) {
    my $data_string = '{' . (join ', ', map {
      "'$_'" . ' => ' . "'" . ($field_data->{$_} // 'undef') . "'"
    } keys %$field_data) . '}';
    croak "error while creating $type: $@ with args: $data_string\n";
  }

  if (defined $obj) {
    return $obj;
  } else {
    croak "error: could not create a '$type'\n";
  }
}

=head2 find_or_create_with_type

 Usage   : my $field_data = { first_name => 'Charles', last_name => 'Darwin',
                              organisation => $organisation };
           my $obj = $schema->find_or_create_with_type('Person', $field_data);
 Function: Create an object of the given type, initialising with the
           $field_data, or return the existing object that matches the primary
           key
 Args    : $type - an unqualified class name like 'Person'
           $field_data - a hashref containing all the fields to initialise in
           the new object
 Returns : a reference to the new (or existing) object

=cut
sub find_or_create_with_type
{
  my $self = shift;
  my ($type, $field_data) = validate_pos(@_, 1, 1);

  my $rs = $self->resultset($type);

  my $obj = undef;

  eval {
    $obj = $rs->find_or_create($field_data);
  };
  if ($@) {
    my $data_string = '{' . (join ', ', map {
      "'$_'" . ' => ' . "'" . $field_data->{$_} . "'"
    } keys %$field_data) . '}';
    croak "error while creating $type: $@ with args: $data_string\n";
  }

  if (defined $obj) {
    return $obj;
  } else {
    croak "error: could not create a '$type'\n";
  }
}

=head2 class_name_of_table

 Usage   : my $class_name = PomCur::DB::class_name_of_table($table_name);
 Function: Return the class name of a given table name
 Args    : $table_name - the table name
 Returns : the qualified class name, eg. PomCur::DB::Person

=cut
sub class_name_of_table
{
  die if @_ != 2;
  my $self = shift;
  my $class_name = shift;
  my $db_name = ref($self) || $self;

  $class_name =~ s/_(\w)/uc $1/eg;
  return $db_name . '::' . ucfirst $class_name;
}

=head2 table_name_of_class

 Usage   : my $table_name = PomCur::DB::table_name_of_class($class_name);
 Function: Return the table name of a given class name
 Args    : $class_name - the class name, can be unqualified or qualified
 Returns : the table name

=cut
sub table_name_of_class
{
  my $class_name = shift;

  if (!defined $class_name) {
    croak "undefined class_name passed to table_name_of_class()\n";
  }

  $class_name =~ s/(?:.*::)//;
  $class_name = join '_', map { lc } ($class_name =~ m/([A-Z][a-z]+)/g);
  return $class_name;
}

=head2 class_name_of_relationship

 Usage   : my $name = PomCur::DB::class_name_of_relationship($object, $relname);
 Function: Return the class name of the object referred to by a relationship
 Args    : $object - an object
           $relname - the relationship name
 Returns : the class name

=cut
sub class_name_of_relationship
{
  my $object = shift;
  my $relname = shift;

  my %info = %{$object->relationship_info($relname)};
  return $info{class};
}

=head2 id_of_object

 Usage   : my $id = PomCur::DB::id_of_object($object);
 Function: Return the database id or primary key of the object, eg. for a
           sample, return the value in the sample_id column and for Protocol,
           return its name
 Args    : $object - an object

=cut
sub id_of_object
{
  my $object = shift;

  # multi-column primary keys aren't supported
  my $table_pk_field = ($object->primary_columns())[0];

  return $object->$table_pk_field();
}

=head2 display_name

 Usage   : my $display_name = PomCur::DB::display_name($object);
             or
           my $display_name = PomCur::DB::display_name($table_name);
             or
           my $display_name = PomCur::DB::display_name($class_name);
 Function: return a description of a table that is suitable for display.
           eg. turn "sequencing_run" into "sequencing run"

=cut
sub display_name
{
  my $arg = shift;

  if (ref $arg) {
    $arg = $arg->table();
  }

  if ($arg =~ /::/) {
    $arg = table_name_of_class($arg);
  }

  $arg =~ s/[_\-]/ /g;

  return "$arg";
}

=head2 column_type

 Usage   : my $column_type = SmallRNA::DB::column_type($field_info, $table_name,
                                                       $column_name);
 Function: Return 'attribute' if a field is a plain attribute or 'collection'
           if it is a collection.

=cut
sub column_type {
  my $self = shift;
  my $field_info = shift;
  my $table_name = shift;
  my $column_name = shift;

  my $class_name = $self->class_name_of_table($table_name);
  my $info_ref = $class_name->relationship_info($column_name);

  if ($field_info->{is_collection} ||
        (defined $info_ref && $info_ref->{attrs}->{join_type})) {
    return 'collection';
  } else {
    return 'attribute';
  }
}

1;
