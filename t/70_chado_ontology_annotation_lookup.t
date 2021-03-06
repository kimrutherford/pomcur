use strict;
use warnings;
use Test::More tests => 21;
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
  my $count = shift;
  my $res = shift;

  ok($count >= @$res);

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
               conditions => [],
               expression => undef,
               qualifiers => [],
               annotation_id => 1,
               publication => {
                 uniquename => 'PMID:10467002'
               }
             });

}

my ($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
                   ontology_name => 'cellular_component',
                 }
                );
check_res($all_annotations_count, $res);
is($lookup->cache()->get_keys(), 1);

($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
                   ontology_name => 'cellular_component',
                   gene_identifier => 'SPBC12C2.02c',
                 }
                );
check_res($all_annotations_count, $res);
is($lookup->cache()->get_keys(), 2);


# try the same thing again to check the cache
($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
                   ontology_name => 'cellular_component',
                   gene_identifier => 'SPBC12C2.02c',
                 }
                );
check_res($all_annotations_count, $res);
is($lookup->cache()->get_keys(), 2);


($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
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

$lookup->cache()->clear();

($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
                   ontology_name => 'cellular_component',
                   gene_identifier => 'SPBC12C2.02c',
                 }
                );

is(@$res, 1);

is ($res->[0]->{is_not}, 1);


# check a annotation to a term from the "PomBase annotation extension
# terms" cv - make sure we get the right name and ID back
($all_annotations_count, $res) =
  $lookup->lookup({pub_uniquename => 'PMID:10467002',
                   ontology_name => 'biological_process',
                 }
                );

is(@$res, 1);
cmp_deeply($res->[0],
           {
             'ontology_term' => {
               'ontid' => 'GO:0006810',
               'term_name' => 'transport',
               'ontology_name' => 'biological_process',
               'extension_term_name' => 'transport [requires_direct_regulator] SPCC1739.11c',
             },
             'evidence_code' => 'UNK',
             'annotation_id' => 2,
             'from' => undef,
             'gene' => {
               'identifier' => 'SPBC12C2.02c',
               'name' => 'ste20',
               'organism_taxonid' => '4896'
             },
             'conditions' => [],
             'expression' => undef,
             'qualifiers' => [],
             'publication' => {
               'uniquename' => 'PMID:10467002'
             },
             'is_not' => 1,
             'with' => undef
           });



# check a phenotpe annotation for an allele
($all_annotations_count, $res) =
  $lookup->lookup({
    pub_uniquename => 'PMID:10467002',
    ontology_name => 'phenotype',
  });

is(@$res, 1);

cmp_deeply($res->[0],
           {
             'gene' => {
               'identifier' => 'SPBC12C2.02c',
               'name' => 'ste20',
               'organism_taxonid' => '4896'
             },
             'ontology_term' => {
               'ontid' => 'FYPO:0000104',
               'term_name' => 'sensitive to cycloheximide',
               'ontology_name' => 'fission_yeast_phenotype'
             },
             'evidence_code' => 'UNK',
             'annotation_id' => 3,
             'from' => undef,
             'is_not' => 'false',
             'publication' => {
               'uniquename' => 'PMID:10467002'
             },
             'conditions' => [],
             'expression' => undef,
             'qualifiers' => [],
             'allele' => {
               'identifier' => 'SPBC12C2.02c:allele-1',
               'name' => 'ste20delta',
               'description' => 'del_x1',
               'organism_taxonid' => '4896'
             },
             'with' => undef
           });
