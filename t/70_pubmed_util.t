use strict;
use warnings;
use Test::More tests => 66;

use PomCur::TestUtil;
use PomCur::Track::PubmedUtil;
use PomCur::TrackDB;

my $test_util;

BEGIN {
  $test_util = PomCur::TestUtil->new();
}

package PomCur::Track::PubmedUtil;

no warnings;

# override for testing
sub get_pubmed_xml_by_ids
{
  local ($/) = undef;

  my $xml_file_name = $test_util->publications_xml_file();
  open my $pubmed_xml, '<', $xml_file_name
    or die "can't open '$xml_file_name': $!";

  my $ret_val = <$pubmed_xml>;

  close $pubmed_xml or die "$!";
  return $ret_val;
}

use warnings;


package main;

$test_util->init_test();

my $config = $test_util->config();
my $schema = PomCur::TrackDB->new(config => $config);

my $pub_rs = $schema->resultset('Pub');
my @pub_results = $pub_rs->search();

sub _check_embo_pub
{
  my $embo_pub = $pub_rs->find({ uniquename => 'PMID:17304215' });

  is ($embo_pub->title(), "Fission yeast Swi5/Sfr1 and Rhp55/Rhp57 differentially regulate Rhp51-dependent recombination outcomes.");
  like ($embo_pub->abstract(), qr/Several accessory proteins referred to as mediators are required/);
  is ($embo_pub->citation(), "EMBO J. 2007 Mar 7;26(5):1352-62");
  is ($embo_pub->publication_date(), "7 Mar 2007");
  is ($embo_pub->affiliation(), "International Graduate School of Arts and Sciences, Yokohama City University, Yokohama, Kanagawa, Japan.");
  is ($embo_pub->authors(), "Akamatsu Y, Tsutsui Y, Morishita T, Siddique MS, Kurokawa Y, Ikeguchi M, Yamao F, Arcangioli B, Iwasaki H");
}

isnt(@pub_results, 0);

my $defined_count = 0;

for my $pub (@pub_results) {
  $defined_count++ if defined $pub->title();
}

my $xml = $test_util->get_pubmed_test_xml();
my $count = PomCur::Track::PubmedUtil::load_pubmed_xml($schema, $xml, 'admin_load');

is($count, 23);

my @new_pub_results = $pub_rs->search();

is(@new_pub_results, @pub_results);

for my $pub (@new_pub_results) {
  # all should have titles
  ok(defined $pub->title());
  ok(defined $pub->abstract(), "has abstract: " . $pub->uniquename());
}

_check_embo_pub();

is ($pub_rs->search({ abstract =>  undef })->count(), 0);

$pub_rs->search({ -or => [ uniquename => 'PMID:19436749',
                           uniquename => 'PMID:17304215'
                         ]})->update({ title => undef,
                                       abstract => undef,
                                       authors => undef,
                                       affiliation => undef,
                                       pubmed_type => undef,
                                       citation => undef,
                                       publication_date => undef,
                                     });

is ($pub_rs->search({ abstract => undef })->count(), 2);

PomCur::Track::PubmedUtil::add_missing_fields($config, $schema);

is ($pub_rs->search({ abstract => undef })->count(), 0);
is ($pub_rs->search({ citation => undef })->count(), 0);
is ($pub_rs->count(), 23);

_check_embo_pub();
