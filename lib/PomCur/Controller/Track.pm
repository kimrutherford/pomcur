package PomCur::Controller::Track;

use parent 'Catalyst::Controller';

=head1 NAME

PomCur::Controller::Track - Actions for managing PomCur

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Controller::Track

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Carp;

use Moose;

sub index_page :Path :Args(0) {
  my ($self, $c) = @_;

  my $st = $c->stash();

  $st->{title} = 'Admin page';
  $st->{template} = 'track/index.mhtml';

  $st->{model} = 'track';

  $st->{use_bootstrap} = 1;
}

sub set_corresponding_author :Local {
  my ($self, $c) = @_;

  my $config = $c->config();

  my $return_path = $c->req()->param('pub-view-path');

  if (defined $c->req->param('curs-pub-assign-submit')) {
    my $person_id = $c->req()->param('pub-corresponding-author-person-id');

    if (!defined $person_id || length $person_id == 0) {
      $c->flash()->{message} = "No person chosen - corresponding author not set";
      $c->res->redirect($return_path);
      $c->detach();
    }

    my $pub_id = $c->req()->param('pub-id');

    my $schema = $c->schema('track');
    my $pub = $schema->resultset('Pub')->find({ pub_id => $pub_id });

    my $curs_schema;

    my $curs;

    my $proc = sub {
      $pub->corresponding_author($person_id);
      $pub->update();
    };

    $schema->txn_do($proc);
  } else {
    # cancelled
  }

  $c->res->redirect($return_path);
  $c->detach();
}

1;
