package PomCur::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use IO::All;

__PACKAGE__->config->{namespace} = '';

=head1 NAME

PomCur::Controller::Root - Root Controller for PomCur tracking application

=head1 METHODS

=cut

=head2 default

 Return the page not found message

=cut
sub default :Path
{
  my ($self, $c) = @_;

  my $st = $c->stash;

  $st->{title} = "Page not found";
  $st->{show_title} = 0;
  $st->{template} = 'not_found_404.mhtml';
  $c->response->status(404);
}

=head2 end

 Attempt to render a view, if needed.

=cut
sub end : Private
{
  my $self = shift;
  my $c = shift;

  my $st = $c->stash();

  my $is_admin = $c->user_exists() && $c->user()->role()->name() eq 'admin';
  $c->stash()->{is_admin_user} = $is_admin;

  if (scalar @{ $c->error }) {
    my @pomcur_errors =
      map {
            warn 'internal error: ', $_;
            {
              title => 'Internal error',
              text => $_
            }
          } @{$c->error()};
    $st->{error} = \@pomcur_errors;
    $st->{title} = 'Error';
    $st->{template} = $st->{error_template} // 'error.mhtml';
    $c->forward('PomCur::View::Mason');
    $c->error(0);
    return 0;
  }

  # copied from RenderView.pm
  if (! $c->response->content_type ) {
    $c->response->content_type( 'text/html; charset=utf-8' );
  }
  return 1 if $c->req->method eq 'HEAD';
  return 1 if defined $c->response->body && length($c->response->body);
  return 1 if scalar @{ $c->error } && !$st->{template};
  return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;
  $c->forward('PomCur::View::Mason');
}

# go to the "local" front page
sub local_front : Global
{
  my ($self, $c) = @_;

  $c->forward($c->config()->{local_front_page});
  $c->detach();
}

# redirect to the tracking application
sub front :Path :Args(0)
{
  my ($self, $c) = @_;

  $c->forward($c->config()->{instance_front_path});
  $c->detach();
}


sub _do_local_and_docs
{
  my ($docs_path, $self, $c, $page_name) = @_;

  my $config = $c->config();

  my $st = $c->stash();

  $st->{title} = $config->{long_name};
  $st->{show_title} = 1;

  if (!defined $page_name) {
    my $default_page = $config->{"default_${docs_path}_page"};
    if (defined $default_page) {
      $page_name = $default_page;
    } else {
      $page_name //= 'index';
    }
  }

  my $template_file_name = "$page_name.mhtml";

  my $template_file =
    $c->path_to('root', $docs_path, $template_file_name);

  my $hide_header = 0;
  my $hide_footer = 0;
  my $use_bootstrap = 0;

  if (-f $template_file) {
    my @lines = io($template_file)->slurp;
    for my $line (@lines) {
      if ($line =~ /<!--\s*PAGE_TITLE:\s*(.*?)\s*-->/) {
        my $title = PomCur::WebUtil::substitute_paths($1, $config);
        $st->{title} = $title;
      }
      if ($line =~ /<!--\s*PAGE_SUBTITLE:\s*(.*?)\s*-->/) {
        my $sub_title = PomCur::WebUtil::substitute_paths($1, $config);
        $st->{sub_title} = $sub_title;
      }
      if ($line =~ /<!--\s*FLAGS:\s*(.*?)\s*-->/) {
        my $all_flags = $1;
        my @flags = split /\s+/, $all_flags;
        if (grep { $_ eq 'hide_header' } @flags) {
          $hide_header = 1;
        }
        if (grep { $_ eq 'hide_footer' } @flags) {
          $hide_footer = 1;
        }
        if (grep { $_ eq 'use_bootstrap' } @flags) {
          $use_bootstrap = 1;
        }
      }
    }
    $st->{hide_header} = $hide_header;
    if ($hide_header) {
      # no login button, so we can cache it
      $c->cache_page(300);
    }
    $st->{hide_footer} = $hide_footer;
    $st->{use_bootstrap} = $use_bootstrap;
    $st->{template} = "$docs_path/$template_file_name";
  } else {
    $c->stash()->{error} =
      { title => "No such page",
        text => "$page_name doesn't exist" };
    $c->forward('/default');
    $c->detach();
  }
}

=head2 local

 Function: Render an HTML template from the local directory
 Args    : $name - page name

=cut
sub local : Global('local')  # local, Global, local ... oh dear
{
  _do_local_and_docs('local', @_);
}

=head2 docs

 Function: Render an HTML template from the docs directory
 Args    : $name - page name

=cut
sub docs : Global('docs')
{
  _do_local_and_docs('docs', @_);
}

=head2 account

 User page for logins

=cut
sub account :Global
{
  my ($self, $c) = @_;

  my $st = $c->stash;

  $st->{title} = "Log in to continue";
  $st->{template} = 'account.mhtml';

  $st->{return_path} = $c->req()->param("return_path");
}

=head2 login

 Try to authenticate a user based on email_address and password parameters

=cut
sub login : Global {
  my ( $self, $c ) = @_;
  my $email_address = $c->req->param('email_address');
  my $password = $c->req->param('password');

  my $return_path = $c->req->param('return_path');

  if (!defined $password || length $password == 0) {
    $c->stash()->{error} =
      { title => "Login error",
        text => "No password given, please try again" };
    $c->forward('account');
    $c->detach();
    return 0;
  }

  if ($c->authenticate({email_address => $email_address,
                        password => $password})) {
    $c->flash->{message} =
      { title => "Login successful" };

    if ($return_path =~ m/logout|login/) {
      $c->forward($c->config()->{instance_front_path});
      return 0;
    }
  } else {
    $c->stash()->{error} =
      { title => "Login error",
        text => "Incorrect email address or password, please try again" };
    $c->forward('account');
    $c->detach();
    return 0;
  }

  $c->res->redirect($return_path, 302);
  $c->detach();
  return 0;
}

=head2 logout

 Log out the user and return to the front page.

=cut

sub logout : Global {
  my ( $self, $c ) = @_;
  $c->logout;

  $c->stash()->{message} = "You have been logged out";
  $c->forward('front');
}


=head2 test_curs

 Usage   : Called by Catalyst
 Function: Create a new curation session for testing, then redirect to a page
           that links to it

=cut
sub test_curs :Global {
  my ($self, $c, $arg) = @_;

  my $st = $c->stash();

  $st->{template} = 'view_curs_test.mhtml';

  my $schema = $c->schema('track');
  my $config = $c->config();

  my $pub_uniquename = $config->{test_publication_uniquename};
  my $pub = $schema->find_with_type('Pub', { uniquename => $pub_uniquename });
  my $curs_key = PomCur::Curs::make_curs_key();

  $st->{title} = "Link to new test curation session " . $curs_key;

  my $person = $schema->resultset('Person')->first();
  my $curs = $schema->create_with_type('Curs',
                                       {
                                         pub => $pub,
                                         curs_key => $curs_key,
                                       });

  my $curs_schema = PomCur::Track::create_curs_db($config, $curs);

  $st->{curs_key} = $curs_key;

  if (defined $arg) {
    if ($arg >= 1) {
      my $curator_manager =
        PomCur::Track::CuratorManager->new(config => $config);

      $curator_manager->set_curator($curs->curs_key, 't.tester@example.com',
                                    'Dr T. Tester');
    }
    if ($arg >= 2) {
      my $gene_track_rs = $schema->resultset('Gene');
      my $gene1 = $gene_track_rs->next();
      my $gene2 = $gene_track_rs->next();

      my @test_gene_ids;

      if (exists $config->{test_gene_identifiers}) {
        @test_gene_ids = @{$config->{test_gene_identifiers}};
      } else {
        my $gene1_identifier = $gene1->primary_identifier();
        my $gene2_identifier = $gene2->primary_identifier();

        @test_gene_ids = ($gene1_identifier, $gene2_identifier);
      }

      use PomCur::Controller::Curs;
      my $res =
        PomCur::Controller::Curs->_find_and_create_genes($curs_schema, $config,
                                                         [@test_gene_ids], 1);
    }
  }
}

=head2 access_denied

 Usage   : Called by Catalyst
 Function: Redirect to account page if the user isn't logged in
 Args    : none
 Returns : redirects and then detaches

=cut
sub access_denied : Private {
  my ($self, $c, $action) = @_;
  my $local_path = $c->local_path();
  my $return_path_uri =
    $c->uri_for($local_path, $c->req()->params());
  $c->res->redirect($c->uri_for('/account',
                                { return_path => $return_path_uri }));
  $c->detach();
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
