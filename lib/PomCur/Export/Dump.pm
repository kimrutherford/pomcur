package PomCur::Export::Dump;

=head1 NAME

PomCur::Dump::Dump - Code to export the contents of the track and
                      curs databases

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Dump::Dump

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2011 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Carp;

use Moose;

use PomCur::Track::Serialise;

with 'PomCur::Role::Configurable';

sub export
{
  my $self = shift;

  my $config = $self->config();

  my $track_schema = PomCur::TrackDB->new(config => $config);

  print PomCur::Track::Serialise::json($config, $track_schema), "\n";
}

1;