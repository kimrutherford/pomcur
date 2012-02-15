#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;

use File::Basename;
use Getopt::Long;

BEGIN {
  my $script_name = basename $0;

  if (-f $script_name && -d "../etc") {
    # we're in the scripts directory - go up
    chdir "..";
  }
};

use lib qw(lib);

use PomCur::Config;
use PomCur::TrackDB;
use PomCur::Track::LoadUtil;
use PomCur::Meta::Util;

my $add_cvterm = 0;
my $dry_run = 0;
my $verbose = 0;
my $do_help = 0;

my $result = GetOptions ("cvterm" => \$add_cvterm,
                         "verbose|v" => \$verbose,
                         "dry-run|T" => \$dry_run,
                         "help|h" => \$do_help);

sub usage
{
  my $message = shift;

  if (defined $message) {
    $message .= "\n";
  } else {
    $message = '';
  }

  die qq|${message}usage:
  $0 --cvterm "cv_name term_name [db_name:accession [definition]]"

Options:
  --cvterm  - add a cvterm to the database
        - cv_name - the name of an existing CV from the cv table
        - term_name - the new term name
        - db_name:accession - optionally, the termid to use for the new dbxref
                              for the cvterm
        - definition - optionally, the term definition
      (if not given the termid defaults to the db_name:term_name where the
       db_name is the "name" from the pomcur.yaml file)
|;
}

if (!$result || $do_help) {
  usage();
}

if ($add_cvterm && (@ARGV < 2 || @ARGV > 4)) {
  usage();
}

if (!$add_cvterm) {
  usage();
}

my $app_name = PomCur::Config::get_application_name();

$ENV{POMCUR_CONFIG_LOCAL_SUFFIX} ||= 'deploy';

my $suffix = $ENV{POMCUR_CONFIG_LOCAL_SUFFIX};

if (!PomCur::Meta::Util::app_initialised($app_name, $suffix)) {
  die "The application is not yet initialised, try running the pomcur_start " .
    "script\n";
}

my $config = PomCur::Config::get_config();
my $schema = PomCur::TrackDB->new(config => $config);

my $load_util = PomCur::Track::LoadUtil->new(schema => $schema);

if (defined $add_cvterm) {
  my $cv_name = shift;
  my $term_name = shift;
  my $termid = shift;
  my $definition = shift;

  my $proc = sub {
    my $cv = undef;
    eval {
      $cv = $load_util->find_cv($cv_name);
    };
    die "could not find CV for: $cv_name\n" if $@;

    eval {
      $load_util->find_cvterm(cv => $cv, name => $term_name);
    };
    die qq/term "$term_name" already exists in CV: $cv_name\n/ unless $@;

    if (defined $termid) {
      eval {
        $load_util->find_dbxref($termid);
      };
      die qq/$termid already exists in Dbxref/ unless $@;
    }

    $load_util->get_cvterm(cv => $cv,
                           term_name => $term_name,
                           ontologyid => $termid,
                           definition => $definition);
  };

  $schema->txn_do($proc);
}