package PomCur::Track::Role::Schema;

=head1 NAME

PomCur::Track::Role::Schema - A Role to add a (TrackDB) schema attribute

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Track::Role::Schema

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use Moose::Role;

requires 'config';

has 'schema' => (
  is => 'ro',
  lazy_build => 1,
);

sub _build_schema {
  my $self = shift;

  my $config = $self->config();

  return PomCur::TrackDB->new(config => $config);
};

1;
