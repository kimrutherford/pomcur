use strict;
use warnings;
use Test::More tests => 11;

use Test::MockObject;

use PomCur::TestUtil;
use PomCur::EmailUtil;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test();

my $config = $test_util->config();

my $mock = Test::MockObject->new();
$mock->mock('config', sub { return $config; });
$mock->mock('_process_template', sub { PomCur::EmailUtil::_process_template(@_); });

my $curs_key = "aaaa0007";
my $root_url = "http://localhost:5000/curs/$curs_key";
my $pub_id = "PMID:10467002";
my $pub_title = "A clever paper";
my $help_url = "http://localhost:5000/docs/";
my $curator_name = "Val Wood";
my $curator_email = 'val@example.com';

my %args = (
  session_link => $root_url,
  publication_uniquename => $pub_id,
  publication_title => $pub_title,
  curator_name => $curator_name,
  curator_email => $curator_email,
  help_index => $help_url,
);

my ($subject, $body) =
  PomCur::EmailUtil::make_email_contents($mock, 'session_assigned', %args);

like ($subject, qr/publication has been assigned to you/);

ok ($body =~ /Dear $curator_name/);
ok ($body =~ /PMID:10467002 - "A clever paper"/);
ok ($body =~ /GO cellular component/);
ok ($body =~ /$help_url/);
ok ($body =~ /$root_url/);
ok ($body =~ /several previously curated annotations/);

$args{recipient_name} = "Test Name";
$args{recipient_email} = 'test@example.com';
$args{reassigner_name} = "Test Name";
$args{reassigner_email} = 'test@example.com';

($subject, $body) =
  PomCur::EmailUtil::make_email_contents($mock, 'reassigner', %args);

like ($body, qr/Thank you for reassigning/);
like ($body, qr/Below is a copy/);
like ($body, qr/Dear Val Wood/);
like ($body, qr/Test Name <test\@example.com> has invited/);
