use strict;
use warnings;
use Test::More tests => 9;
use Test::Deep;

use PomCur::Chado::OntologyAnnotationLookup;
use PomCur::TestUtil;

my $test_util = PomCur::TestUtil->new();

$test_util->init_test();

my $config = $test_util->config();

my $lookup =
  PomCur::Chado::OntologyAnnotationLookup->new(config => $test_util->config());

ok(defined $lookup->schema());

sub check_res {
  my $res = shift;

  is(@$res, 1);

  cmp_deeply($res->[0],
             {
               gene => {
                 identifier => 'SPBC12C2.02c',
                 name => 'ste20',
                 organism_taxonid => '4896',
               },
               ontology_term => {
                 ontid => 'GO:0030133',
                 term_name => 'transport vesicle',
                 ontology_name => 'cellular_component'
               },
               evidence_code => 'IMP',
               with => 'GeneDB_Spombe:SPBC2G2.01c',
               from => undef,
               is_not => 0,
               annotation_id => 1,
               publication => {
                 uniquename => 'PMID:10467002'
               }
             });

}

my $res = $lookup->lookup({pub_uniquename => 'PMID:10467002',
                           ontology_name => 'cellular_component',
                           }
                         );

check_res($res);

$res = $lookup->lookup({pub_uniquename => 'PMID:10467002',
                        ontology_name => 'cellular_component',
                        gene_identifier => 'SPBC12C2.02c',
                      }
                     );

check_res($res);

$res = $lookup->lookup({pub_uniquename => 'PMID:10467002',
                        ontology_name => 'cellular_component',
                        gene_identifier => 'unknown_id',
                      }
                     );

is(@$res, 0);


# check that the is_not parameter is returned correctly
my $chado_schema = PomCur::ChadoDB->new(config => $config);

my $spbc12c2_02c = $chado_schema->resultset('Feature')->find({ uniquename => 'SPBC12C2.02c.1' });
my $fcs = $spbc12c2_02c->feature_cvterms();
is ($fcs->count(), 2);

map { $_->is_not(1); $_->update(); } $fcs->all();

$res = $lookup->lookup({pub_uniquename => 'PMID:10467002',
                        ontology_name => 'cellular_component',
                        gene_identifier => 'SPBC12C2.02c',
                      }
                     );

is(@$res, 1);

is ($res->[0]->{is_not}, 1);
