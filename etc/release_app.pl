#!/usr/bin/perl -w

# Script to install or update an existing installation, including the apache
# configuration
#
# Usage:
#   <script_path> <app_name> [<version_tag>]
#
# where:
#   <app_name> is something like "test" or "prod"
#
# The application will appear as http://the.server/<app_name>

use strict;
use warnings;
use Carp;

use IO::All;
use File::Path qw(make_path);
use Getopt::Long;
use POSIX ":sys_wait_h";

my $version_prefix = 'v';

my $apache_dir = '/etc/apache2/pomcur.d';
my $pomcur_dir = '/var/pomcur';
my $run_dir = "$pomcur_dir/run";
my $apps_dir = "$pomcur_dir/apps";
my $repo = "$pomcur_dir/pomcur.git";
my $apache_conf_dir = '/etc/apache2/pomcur.d/';
my $config_file_name = 'pomcur_deploy.yaml';

my $start_script = "script/pomcur_start";
my $plack_handler = undef;
my $preload = undef;
my $workers = undef;
my $google_analytics_id;

my $start_port = 5100;
my $end_port = 6000;

GetOptions ("server|s=s" => \$plack_handler,
            "preload-app" => \$preload,
            "workers=i" => \$workers,
            "google-analytics-id=s" => \$google_analytics_id,
          );

sub get_from_run_file
{
  my $app_name = shift;
  my $key = shift;

  my $run_file = "$run_dir/$app_name";
  my $contents = io($run_file)->slurp();

  if ($contents =~ /^\s*$key:\s*(\d+)/m) {
    return $1;
  } else {
    die "can't find $key in $run_file";
  }
}

sub get_port
{
  my $app_name = shift;

  my %ents = %{io($run_dir)};

  if (defined $ents{$app_name}) {
    return get_from_run_file($app_name, 'port');
  } else {
    my %current_ports = ();

    for my $file_name (keys %ents) {
      $current_ports{get_from_run_file($file_name, 'port')} = 1;
    }

    for (my $p = $start_port; $p <= $end_port; $p++) {
      if (!exists $current_ports{$p}) {
        return $p;
      }
    }

    die "can't find a free port between $start_port and $end_port\n";
  }
}

my $app_name = shift;

die "no application name given\n" unless $app_name;

my $port = get_port($app_name);

my $data_dir = "$pomcur_dir/data/${app_name}_data";

my $app_tag = shift;

if (!defined $app_tag) {
  chdir $repo;
  my $describe_cmd = 'git describe --tags --match "$version_prefix*"';
  $app_tag = `$describe_cmd`;

  if (defined $app_tag) {
    $app_tag =~ s/($version_prefix\d+).*/$1/s;
  } else {
    warn "$describe_cmd failed to return a tag - using HEAD\n";
    $app_tag = 'HEAD';
  }
}

print "using version: $app_tag\n";

my $app_subdir;
my $app_version;

chdir $apps_dir or die "$!";

my $full_app_path = "$apps_dir/$app_name";

if (-d $full_app_path) {
  print "updating $full_app_path\n";
  chdir $full_app_path;
  system "git reset --hard";
  system "git pull --tags origin master";
  system "git reset --hard $app_tag";
  print 'now at: ', `git describe --tags`;

  my $pid_file = "$run_dir/$app_name";

  if (-f $pid_file) {
    my $pid = get_from_run_file($app_name, 'pid');
    print "killing $pid ...\n";
    kill 2, $pid;
  }
} else {
  if (-d $data_dir) {
    die "new application directory ($full_app_path) doesn't exist, but there is " .
      "data directory ($data_dir) - won't continue";
  }

  print "creating $full_app_path\n";
  system "git clone -v $repo $full_app_path";
  chdir $full_app_path;
  system "git checkout $app_tag";

  system "./script/pomcur_start --initialise $data_dir";

  if (defined $google_analytics_id) {
    open my $config_file, '>>', $config_file_name
      or die "can't open $config_file_name: $!\n";

    print "google_analytics_id: $google_analytics_id\n";

    close $config_file;
  }
}

my $pid = fork;

if ($pid) {
  "pid: $pid\nport: $port\n" > io("$run_dir/$app_name");
  print "started server with pid: $pid on port: $port\n";
} else {
  my @exec_args = ("./$start_script", "--port", $port);
  if (defined $workers) {
    push @exec_args, '--workers', $workers;
  }
  if (defined $plack_handler) {
    push @exec_args, '-s', $plack_handler;
  }
  if (defined $preload) {
    push @exec_args, '--preload-app';
  }

  exec @exec_args;
}

my $apache_conf = <<"CONF";
<Location /$app_name>
  RequestHeader set X-Request-Base /$app_name
</Location>

ProxyPass /$app_name http://localhost:$port retry=1
ProxyPassReverse /$app_name http://localhost:$port
CONF

$apache_conf > io("$apache_conf_dir/$app_name");

system "sudo -n /etc/init.d/apache2 restart";
