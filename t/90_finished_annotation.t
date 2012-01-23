use strict;
use warnings;
use Test::More tests => 21;

use Plack::Test;
use Plack::Util;
use HTTP::Request;
use HTTP::Cookies;

use PomCur::TestUtil;
use PomCur::Track::StatusStorage;
use PomCur::Role::MetadataAccess;
use PomCur::Controller::Curs;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test('curs_annotations_1');

my $config = $test_util->config();
my $track_schema = $test_util->track_schema();

my $status_storage = PomCur::Track::StatusStorage->new(config => $config);

my @curs_objects = $track_schema->resultset('Curs')->all();
is(@curs_objects, 1);

my $curs_key = $curs_objects[0]->curs_key();
my $app = $test_util->plack_app()->{app};
my $cookie_jar = HTTP::Cookies->new(
  file => '/tmp/pomcur_web_test_$$.cookies',
  autosave => 1,
);
my $curs_schema = PomCur::Curs::get_schema_for_key($config, $curs_key);
my $root_url = "http://localhost:5000/curs/$curs_key";

test_psgi $app, sub {
  my $cb = shift;

  {
    my $uri = new URI("$root_url/");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    like ($res->content(), qr/Choose a gene to annotate/s);
    like ($res->content(), qr/Publication details/s);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "ACTIVE");
  }

  my $further_information =
    "If you have further information about the publication";
  my $thank_you ="Thank you for your contribution to PomBase";
  my $your_annotations = "Your annotations have been sent to the curation team for inclusion in the database";

  {
    my $uri = new URI("$root_url/finish_form");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    (my $content = $res->content()) =~ s/\s+/ /g;

    like ($content, qr/$thank_you/s);
    like ($content, qr/Your annotations will now be sent to the curation team/s);
    like ($content, qr/$further_information/s);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "FINISHED");
  }

  # test submitting a message on the finsh form
  {
    my $test_text = "A text string";

    my $uri = new URI("$root_url/finish_form");
    $uri->query_form(finish_textarea => $test_text,
                     submit => 'Submit',
                    );

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);

    is $res->code, 302;

    my $redirect_url = $res->header('location');

    is ($redirect_url, "$root_url/finished_publication");

    my $redirect_req = HTTP::Request->new(GET => $redirect_url);
    my $redirect_res = $cb->($redirect_req);

    (my $content = $redirect_res->content()) =~ s/\s+/ /g;

    like ($content, qr/$thank_you/s);
    like ($content, qr/$your_annotations/s);
    unlike ($content, qr/$further_information/s);

    PomCur::Role::MetadataAccess::get_metadata($curs_schema, PomCur::Controller::Curs::MESSAGE_FOR_CURATORS_KEY);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "FINISHED");
  }

  # check that we now redirect to the "finished" page
  {
    my $uri = new URI("$root_url/");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    (my $content = $res->content()) =~ s/\s+/ /g;

    like ($content, qr/$thank_you/s);
    like ($content, qr/$your_annotations/s);
    unlike ($content, qr/$further_information/s);
    unlike ($content, qr/Admin only:/);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "FINISHED");
  }

  # log in
  {
    my $admin_role =
      $track_schema->resultset('Cvterm')->find({ name => 'admin' });

    my $admin_people =
      $track_schema->resultset('Person')->
        search({ role => $admin_role->cvterm_id() });

    my $first_admin = $admin_people->first();
    ok(defined $first_admin);

    my $uri = new URI("http://localhost:5000/login");
    $uri->query_form(email_address => $first_admin->email_address(),
                     password => $first_admin->password(),
                     return_path => 'http://localhost:5000/',
                     submit => 'login',
                   );

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 302;

    my $redirect_url = $res->header('location');
    is ($redirect_url, 'http://localhost:5000/');
  }

  # check that admin options are shown when logged in as admin
  {
    my $uri = new URI("$root_url/");

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);
    my $res = $cb->($req);

    is $res->code, 200;

    (my $content = $res->content()) =~ s/\s+/ /g;

    like ($content, qr/$thank_you/s);
    like ($content, qr/$your_annotations/s);
    unlike ($content, qr/$further_information/s);

    like ($content, qr/Admin only:/);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "FINISHED");
  }
};

done_testing;