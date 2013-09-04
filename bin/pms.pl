#!/usr/bin/env perl
use strict;
use PMS;
use DBIx::Custom;

my $db = DBIx::Custom->connect(
    dsn => "dbi:mysql:database=pms:127.0.0.1",
    user => 'pms',
    password => '',
    option => {mysql_enable_utf8 => 1},
    );

my $C = PMS->new($db);

#$C->valid_user('user','email.com');
#$C->add_user('user','email.com','pass');
#$C->add_domain('email.com');
#$C->alias_user('user','email.com','alias');
#$C->make_filters('json.json');
#$C->domains();
#$C->domains_user('email.com');
