use strict;
use warnings;
use Test::More tests => 31;

use Plack::Test;
use Plack::Util;

use PomCur::TestUtil;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test('1_curs');

my $config = $test_util->config();
my $schema = $test_util->track_schema();

my $root_url = "http://localhost:5000";

my %test_app_conf = %{$test_util->plack_app(login => $root_url)};
my $app = $test_app_conf{app};
my $cookie_jar = $test_app_conf{cookie_jar};

my $triage_url = "$root_url/tools/triage";

my $triaging_re = qr/Triaging (PMID:\d+)/;

sub _check_for_pub
{
  my $res = shift;
  my $pub = shift;
  my $remaining_count = shift;

  if ($res->content() =~ $triaging_re) {
    is ($1, $pub->uniquename());
  } else {
    fail("page contents didn't match $triaging_re: " . $res->content());
  }

  my $re = qr/(\d+) remaining/;

  if ($res->content() =~ $re) {
    is ($1, $remaining_count);
  } else {
    fail("page contents didn't match $re: " . $res->content());
  }
}

test_psgi $app, sub {
  my $cb = shift;

  # make sure there is a link to the triage page
  {
    my $uri = new URI("$root_url/track/");
    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);

    is ($res->code, 200);
    like ($res->content(), qr/Triage publications/);
  }

  # make sure we can't triage if not logged in
  {
    my $uri = new URI($triage_url);
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is ($res->code, 200);
    like ($res->content(), qr/Log in as administrator to allow triaging/);
  }

  my $cv = $schema->find_with_type('Cv',
                                   { name => 'PomCur publication triage status' });
  my $new_cvterm = $schema->find_with_type('Cvterm',
                                           { cv_id => $cv->cv_id(),
                                             name => 'New' });

  my $first_pub = PomCur::Controller::Tools::_get_next_triage_pub($schema, $new_cvterm);

  is ($first_pub->triage_status()->cvterm_id(), $new_cvterm->cvterm_id());

  # check triage page when logged in
  {
    my $uri = new URI($triage_url);
    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);

    is ($res->code, 200);

    _check_for_pub($res, $first_pub, 19);
  }

  my $curatable_cvterm = $schema->find_with_type('Cvterm',
                                                 { cv_id => $cv->cv_id(),
                                                   name => 'Curatable' });

  my $priority_cv = $schema->find_with_type('Cv',
                                            { name => 'PomCur curation priorities' });
  my $low_cvterm = $schema->find_with_type('Cvterm',
                                           { cv_id => $priority_cv->cv_id(),
                                             name => 'low' });
  my $high_cvterm = $schema->find_with_type('Cvterm',
                                            { cv_id => $priority_cv->cv_id(),
                                              name => 'high' });

  my $second_pub;

  # check triage form submission
  {
    my $uri = new URI($triage_url);
    $uri->query_form('triage-pub-id' => $first_pub->pub_id(),
                     submit => $curatable_cvterm->name(),
                     'experiment-type' => [$curatable_cvterm->name()],
                     'triage-curation-priority' => [$low_cvterm->cvterm_id()],
                     'triage-corresponding-author-add-name' => 'Val Wood',
                     'triage-corresponding-author-add-email' => 'val@test.com',
                    );

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 302;

    my $redirect_url = $res->header('location');

    my $redirect_req = HTTP::Request->new(GET => $redirect_url);
    $cookie_jar->add_cookie_header($redirect_req);
    my $redirect_res = $cb->($redirect_req);

    # refetch to get database changes
    $first_pub = $schema->find_with_type('Pub', $first_pub->pub_id());

    is ($first_pub->curation_priority()->name(), 'low');

    is ($first_pub->triage_status_id(), $curatable_cvterm->cvterm_id());

    my @pubprops = $first_pub->pubprops();

    is (scalar(@pubprops), 1);
    is ($pubprops[0]->value(), $curatable_cvterm->name());
    is ($pubprops[0]->type()->name(), "experiment_type");

    $second_pub = PomCur::Controller::Tools::_get_next_triage_pub($schema, $new_cvterm);

    _check_for_pub($redirect_res, $second_pub, 18);
  }

  # check triage return-pub-id works
  {
    my $uri = new URI($triage_url);
    $uri->query_form('triage-pub-id' => $first_pub->pub_id(),
                     'triage-return-pub-id' => $first_pub->pub_id(),
                     submit => $curatable_cvterm->name(),
                     'experiment-type' => [$curatable_cvterm->name()],
                     'triage-curation-priority' => [$high_cvterm->cvterm_id()],
                     'triage-corresponding-author-add-name' => 'Val Wood',
                     'triage-corresponding-author-add-email' => 'test@test.com',
                    );

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 302;

    my $redirect_url = $res->header('location');

    my $redirect_req = HTTP::Request->new(GET => $redirect_url);
    $cookie_jar->add_cookie_header($redirect_req);
    my $redirect_res = $cb->($redirect_req);

    my $content = $redirect_res->content();

    unlike($content, qr|You must choose a corresponding author|);

    # refetch to get database changes
    $first_pub = $schema->find_with_type('Pub', $first_pub->pub_id());

    is ($first_pub->curation_priority()->name(), 'high');
    is ($first_pub->triage_status_id(), $curatable_cvterm->cvterm_id());

    my @pubprops = $first_pub->pubprops();

    is (scalar(@pubprops), 1);
    is ($pubprops[0]->value(), $curatable_cvterm->name());
    is ($pubprops[0]->type()->name(), "experiment_type");

    $second_pub = PomCur::Controller::Tools::_get_next_triage_pub($schema, $new_cvterm);

    unlike($content, $triaging_re);
    my $pub_page_re = "Details for publication: " . $first_pub->uniquename();
    like($content, qr/$pub_page_re/);
  }

  # test when there are no more publications to triage, by setting all
  # but one publication as "Curatable"
  $schema->resultset('Pub')
    ->search({ pub_id => { '<>' => $second_pub->pub_id() } })
    ->update({ triage_status_id =>
               $curatable_cvterm->cvterm_id() });


  {
    my $uri = new URI($triage_url);
    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 200;

    _check_for_pub($res, $second_pub, 1);
  }

  {
    my $uri = new URI($triage_url);
    my $person = $schema->resultset('Person')->first();
    $uri->query_form('triage-pub-id' => $second_pub->pub_id(),
                     submit => $curatable_cvterm->name(),
                     'triage-corresponding-author-person-id' => $person->person_id(),
                    );
    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 302;

    my $redirect_url = $res->header('location');
    my $redirect_req = HTTP::Request->new(GET => $redirect_url);

    $cookie_jar->add_cookie_header($redirect_req);
    my $redirect_res = $cb->($redirect_req);

    is $redirect_res->code, 200;

    like ($redirect_res->content(), qr/Triaging finished/);
  }

};

done_testing;
