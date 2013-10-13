#!/usr/bin/env perl
use strict;
use PMS;
use DBIx::Custom;

sub Help {
    print <<_EOF_;
Commands available:

-vu user domain.com          Validate user
-au user domain.com pass     Add user
-ad domain.com               Add domain
-al user domain.com alias    Alias user
-mf file.json                Make filters file json
-sd                          Show domains
-du domain.com               Show users of domain

_EOF_
}

my $db = DBIx::Custom->connect(
    dsn => "dbi:mysql:database=pms:127.0.0.1",
    user => 'pms',
    password => '',
    option => {mysql_enable_utf8 => 1},
    );

my $C = PMS->new($db);

Help() if $ARGV[0] eq '-h';

$C->valid_user($ARGV[0],$ARGV[1]) if $ARGV[0] eq '-vu';
$C->add_user($ARGV[0],$ARGV[1],$ARGV[2]) if $ARGV[0] eq '-au';
$C->add_domain($ARGV[0]) if $ARGV[0] eq '-ad';
$C->alias_user($ARGV[0],$ARGV[1],$ARGV[2]) if $ARGV[0] eq '-al';
$C->make_filters($ARGV[0]) if $ARGV[0] eq '-mf';
$C->domains() if $ARGV[0] eq '-sd';
$C->domains_user($ARGV[0]) if $ARGV[0] eq '-du';
