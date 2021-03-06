package PomCur::Role::GeneLookupCache;

=head1 NAME

PomCur::Role::GeneLookupCache - A role the adds caching to a GeneLookup

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Role::GeneLookupCache

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Moose::Role;

with 'PomCur::Role::SimpleCache';

requires 'config';

around 'lookup' => sub {
  my $orig = shift;
  my $self = shift;

  my $organism_name = 'any';

  my @args;
  if (@_ == 1) {
    @args = @{$_[0]};
  } else {
    my $options = $_[0];
    if (exists $options->{search_organism}) {
      $organism_name = $options->{search_organism}->{genus} . '_' .
        $options->{search_organism}->{species};
    }
    @args = @{$_[1]};
  }

  my $cache_key = $organism_name . ':' . join '#@%', @args;
  my $cache = $self->cache();

  my $cached_value = $cache->get($cache_key);

  if (defined $cached_value) {
    return $cached_value;
  }

  my $ret_val = $self->$orig(@_);

  $cache->set($cache_key, $ret_val, $self->config()->{cache}->{default_timeout});

  return $ret_val;
};

1;
