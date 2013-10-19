# Introduction
[Canto](http://curation.pombase.org/) is a generic genome annotation tool with
a focus on community curation.  This document describes Canto from the
adminstrators perspective.  It covers installation and maintenance.

The latest version of this document can always be found on the main
[Canto website](http://curation.pombase.org/pombe/docs/canto_admin) and the
source to it
[on GitHub](https://github.com/pombase/canto/blob/master/documentation/canto.md).

# Requirements for Canto
- Linux, BSD or UNIX
- Perl, clucene library

# Canto in a Virtual machine
Canto can be tested in a virtual machine using
[VirtualBox](http://www.virtualbox.org) and
[Vagrant](http://www.vagrantup.com/).  This combination is available on Linux,
MacOS and Windows.

These instructions have been tested on a 64 bit host.

## Installing VirtualBox

Installation packages for VirtualBox are available here:
  https://www.virtualbox.org/wiki/Downloads

On some operating systems, packages may be available from the default
repositories:

* Debian: `https://wiki.debian.org/VirtualBox`
* Ubuntu: `https://help.ubuntu.com/community/VirtualBox`
* RedHat/Centos: `http://wiki.centos.org/HowTos/Virtualization/VirtualBox`

## Installing Vagrant

Installation instructions for Vagrant are here:
`http://docs.vagrantup.com/v2/installation/index.html`

Users of recent versions of Debian and Ubuntu can install with:

    apt-get install vagrant

## Canto via Vagrant

Once VirtualBox and Vagrant are installed, use these commands to create a
virtual machine, install the operating system (Ubuntu) and install Canto and
its dependencies:

    cd canto
    vagrant box add precise64 http://files.vagrantup.com/precise64.box
    vagrant up

The `vagrant` commands will many minutes to complete.  If everything is
succesful, once `vagrant up` returns you can `ssh` to the virtual machine
with:

    vagrant ssh

From that shell, the Canto server can be started with:

    cd canto
    ./script/canto_start

Once started the server can be accessed on port 5500 of the host:

    http://localhost:5500/

# Manual installation

## Software requirements

The following software is needed for the installation:

- Perl
- Git
- GCC (for compiling part of the Perl libraries)
- Make
- CLucene v0.9.*
- Module::Install and Module::Install::Catalyst

## Installing prerequisites on Debian and Ubuntu 

On Debian and Ubuntu, the software requirements can be installed using the
package manager:

    sudo apt-get install perl gcc g++ tar gzip bzip2 make git-core \
      libclucene-dev libclucene0ldbl \
      libmodule-install-perl libcatalyst-devel-perl \
      libdist-checkconflicts-perl
  
To improve the installation speed, these packages can optionally be installed
before preceeding:

    sudo apt-get install libhash-merge-perl \
      libhtml-mason-perl libplack-perl libdbix-class-perl \
      libdbix-class-schema-loader-perl libcatalyst-modules-perl libio-all-lwp-perl \
      libwww-perl libjson-xs-perl libio-all-perl \
      libio-string-perl libmemoize-expirelru-perl libtry-tiny-perl \
      libarchive-zip-perl libtext-csv-xs-perl liblingua-en-inflect-number-perl \
      libcatalyst-modules-perl libmoose-perl libdata-compare-perl \
      libmoosex-role-parameterized-perl libfile-copy-recursive-perl \
      libxml-simple-perl libtext-csv-perl libtest-deep-perl

If these packages aren't installed these Perl modules will be installed using
CPAN, which is slower.

## Getting the code
Currently the easiest way to get the code is via GitHub.  Run this command
to get a copy of the code:

    git clone https://github.com/pombase/canto.git

This creates a directory called "`canto`".  The directory can be updated
later with the command:

    git pull

## Downloading an archive file

Alternatively, GitHub provides archive files for the current version:

- https://github.com/pombase/canto/archive/master.zip
- https://github.com/pombase/canto/archive/master.tar.gz

Note after unpacking, you'll have a directory called `canto-master`.  The text
below assumes `canto` so:

    mv canto-master canto

## CPAN tips
Use these commands at the `cpan` prompt avoid lots of questions while
installing:

    o conf prerequisites_policy follow
    o conf build_requires_install_policy no
    o conf commit

This command at the CPAN prompt will update CPAN and install Readline
support:

    install Bundle::CPAN

## Install dependencies

    perl Makefile.PL
    make

## Run the tests
To check that all prerequisites are installed and that the code Canto tests
pass:

    make test

# Quick start
To try the Canto server:

## Initialise the data directory
From the in the `canto` directory:

    mkdir canto-test
    ./script/canto_start --init canto-test

## Run the server

    ./script/canto_start

## Visit the application start page
The application should now be running at:

    http://localhost:5000


# Configuration
## canto.yaml
The default configuration is stored in `canto.yaml` in the top level
directory.  Any installation specific settings can be added to
`canto_deploy.yaml`, and will override the defaults.

The configuration files are [YAML format](http://en.wikipedia.org/wiki/YAML).

### name
A one word name for the site.  default: Canto
### long_name
A longer description of the site.  eg. The SlugBase community annotation tool
### database_name
Database name for prefixing identifiers when exporting.  eg. PomBase
### database_url
The URL of the database that this instance is installed for.  eg.
`http://curation.pombase.org/pombe/`
### header_image
A the path relative to `root/static` of the logo to put in the header.
### canto_url
The link for the main Canto web site.
### app_version
The software version, automatically updated each release.
### schema_version
The version of the schema.  This is incremented when the schema changes in an
incompatible way.

### authentication
Configuration for the Catalyst authentication code.  This shouldn't need changing.
### view_options
Configuration for the admin view pages.
#### max_inline_results_length
The maximum number of lines of results to show in a table on an object
page.
### db_initial_data
Data needed to initialise a Canto instance.
### class_info
Descriptions of table in the database used by the interface.  This
information is used for rendering the view and object pages.
### reports
A list of report names to show on the front page.
### export
Configuration for exporting.
### load
Configuration for loading data.
### track_db_template_file
The template database to use when creating a new Canto instance.
### curs_db_template_file
The template database to use when creating a new curation session.
### ontology_index_dir
The name of the directory used for the ontology Lucene index.  This index
is used to do autocompeletion in the interface.
### external_sources
URLs of external services.
### implementation_classes
Names of classes used to implement database query and storage.  This
allows the implementations to be swapped from the defaults.
#### gene_adaptor
Used to lookup gene identifier, name, synonyms and products.  The default
is to use the internal Canto database ("track").
### evidence_types
Short name (codes) and long names of evidence types.  Any evidence type
configured with the option "with_gene" set to true will cause the
interface to ask for a gene for later storage in the "with/from" column
of a GAF file.
### annotation_type_list
Configuration of the type of annotations possible in this Canto instance.
#### name
The identifier for this annotation type, used internally and in URLs.
#### category
One of: "ontology" or "interaction", used to select which Perl package
should be used for rendering and storing these annotation type.
### messages
### test_config_file
The path to the extra configuration file needed while testing.
### help_text
### external_links
### webservices
### ontology_external_links
### chado

## Loading data
### Organisms

    ./script/canto_load.pl --organism "<genus> <species> <taxon_id>"

### Gene data

    ./script/canto_load.pl --genes genes_file.tsv --for-taxon 4896

#### gene data format
Four tab separated columns with no header line:

- systematic identifier
- gene primary name
- synonyms (comma separated)
- product

### Ontology terms

    ./script/canto_load.pl --ontology ontology_file.obo

The ontology must be configured in the [annotation_type_list](#annotation_type_list) section of the
`canto.yaml` file.

# Implementation details
## Structure
There are two parts to the system.

"Track" run is the part that the adminstrator uses to add people,
publications and curation sessions to the database.

"Curs" handles the user curation sessions.
### Track - user, publication and session tracking
#### Database storage
##### SQLite for main database
### Curs - curation sessions
Each curation session has a cooresponding SQLite database.

## Databases
## Database structure
## Code
Canto is written in Perl, implemented using the Catalyst framework and
running on a Plack server.
## Autocomplete searching
- implemented using CLucene
- short names are weighted more highly so they appear at the top of the search list
- the term names are passed to CLucene for indexing
- all words appearing in the name or synonyms are joined into one string
  for separate indexing by CLucene

# Developing Canto
## Running tests
In general the tests can be run with: `make test` in the main canto
directory.  If the schema or test genes or ontologies are is changed the
test data will need to be re-initialised.

## Helper scripts
Scripts to help developers:

- `etc/db_initialise.pl` - create empty template database from the schemas
  and recreate the database classes in lib/Canto/TrackDB and
  lib/Canto/CursDB
- `etc/test_data_initialise.pl` - re-create test data files that don't change
  very often.  eg. the test PubMed XML file.  Currently this script only
  needs to be run if the list of publications for the test database
  changes
- `etc/test_initialise.pl` - initialise the test databases in t/data with
  a small number of genes and a mini version of the Gene Ontology
  database
- `etc/local_initialise.pl` - create a test instance of Canto in ./local

## Initialising test data
Run the following commands in the canto directory to create the test
database and to populate it with test data:

    ./etc/db_initialise.pl
    ./etc/test_initialise.pl

That will need to be done each time the schemas or test data change.

To create a local test instance of Canto, run `local_initialise.pl`

## Running the test instance
The server can be run from the top level directory with this command:

    CANTO_CONFIG_LOCAL_SUFFIX=local PERL5LIB=lib ./script/canto_server.pl -p 5000 -r -d

"5000" is the local port to connect on.  The server should then be
available at `http://localhost:5000/`

# Contact
For questions or help please contact helpdesk@pombase.org or kim@pombase.org.

Requests of new features can be made by email or by adding an issue on the
[GitHub Canto issue tracker](https://github.com/pombase/canto/issues)