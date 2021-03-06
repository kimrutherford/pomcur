#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.
name 'PomCur';
all_from 'lib/PomCur.pm';

requires 'Catalyst::Runtime' => '5.80022';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Session::PerUser';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::View::JSON';
requires 'Catalyst::TraitFor::Request::ProxyBase';
requires 'CatalystX::RoleApplicator';
requires 'Catalyst::Helper';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Session::Store::DBI';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Authorization::ACL';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::PageCache';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::View::Mason';
requires 'File::Copy::Recursive';
requires 'DBD::SQLite';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::ResultSet::Data::Pageset';
requires 'DBIx::Class::ResultClass::HashRefInflator';
requires 'Cache';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'MooseX::Role::Parameterized';
requires 'Params::Validate';
requires 'XML::Simple';
requires 'LWP::Simple';
requires 'Plack';
requires 'Plack::Middleware::ReverseProxy';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::InteractiveDebugger';
requires 'Plack::Middleware::Expires';
requires 'Catalyst::Engine::PSGI';
requires 'LWP';
requires 'Data::Compare';
requires 'IO::All';
requires 'Test::Exception';
requires 'JSON::Any';
requires 'HTML::Mason';
requires 'Data::Rmap';
requires 'Clone';
requires 'MIME::Types';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'Lingua::EN::Inflect::Number';
requires 'Number::Format';
requires 'MooseX::SetOnce';
requires 'MooseX::Aliases';
requires 'GO::Parser';
requires 'Lucene';
requires 'Text::CSV';
requires 'JSON';
requires 'Try::Tiny';
requires 'String::Similarity';
requires 'Archive::Zip';
requires 'File::Basename';
requires 'Getopt::Long';
requires 'Data::Dumper';
requires 'Hash::Merge';
requires 'Memoize';
requires 'IO::String';
requires 'Package::Alias';
requires 'Catalyst::ScriptRunner';
requires 'HTTP::Message';
requires 'Sub::Exporter';
requires 'Config::General';
requires 'MooseX::Traits::Pluggable';
requires 'MooseX::MarkAsMethods';
requires 'DBD::Pg';
requires 'URI::Escape';
requires 'Data::JavaScript::Anon';
requires 'HTML::HTML5::Builder';
requires 'CHI';
requires 'CHI::Driver::Memcached';
requires 'Cache::Memcached';
requires 'Email::Simple';
requires 'Email::Sender';
requires 'Scalar::Util';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Deep';
test_requires 'Test::MockObject';
test_requires 'Test::Exception';
test_requires 'Web::Scraper';
test_requires 'LWP::Protocol::PSGI';
test_requires 'LWP::Protocol::https';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
