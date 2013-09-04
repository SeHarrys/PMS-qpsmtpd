package PMS;

use JSON::XS;
use Digest::SHA1 qw(sha1_base64);

sub new {
    my $class = shift;
    
    my $self = {
        db     => shift
    };

    foreach my $V ( @{ $self->{db}->execute('SELECT * FROM config')->fetch_hash_all } ) {
	$self->{$V->{VAR}} = $V->{CONTENT};
    }

    return bless $self, $class;
}

sub valid_user {
    my $self = shift;

    my $C = $self->{db}->execute('SELECT * FROM control WHERE pw_name = :u AND pw_domain = :d', { u => shift , d => shift })->fetch_hash;

    return $C->{id} ? 1 : 0;
}

sub alias_user {
    my $self = shift;
    my $user = shift;
    my $host = shift;
    my $alias = shift;
    
    # Alias exists return
    return 0 if -e $self->{FS_MAILDIR}.$host.'/'.$alias;
    
    symlink $self->{FS_MAILDIR}.$host.'/'.$user,$self->{FS_MAILDIR}.$host.'/'.$alias;
}

sub add_user {
    my $self = shift;
    my $user = shift;
    my $host = shift;
    my $pass = shift;
    
    # Check if exists
    return 0 if $self->valid_user($user,$host);

    my $maildir = $self->{FS_MAILDIR}.'/'.$host.'/'.$user;

    $self->{db}->insert(
	{ 
	    pw_name   => lc $user, 
	    pw_domain => lc $host, 
	    pw_dir => $maildir, 
	    pw_clear_passwd => $pass,
	    pw_passwd => sha1_base64($pass),	    
	    status => 1 
	}, 
	table => 'control');

    $self->make_skeel($user,$host);
}

sub pause_user {
    my $self = shift;
    my $user = shift;
    my $host = shift;

    $self->update({ status => 0 }, table => 'control' , where => { pw_name => $user , pw_domain => $host });
}

sub del_user {
    my $self = shift;
    my $user = shift;
    my $host = shift;
    
    my $U = $self->{db}->execute('SELECT * FROM control WHERE pw_name = :u AND pw_domain = :d', { u => $user , d => $host })->fetch_hash;

    $dbi->delete(where => { id => $U->{id} }, table => 'control');
    $dbi->delete(where => { control => $U->{id} }, table => 'filters');

    #$self->del_skeel();
}

sub make_skeel {
    my $self = shift;
    my $vp;

    $vp->{user} = shift;
    $vp->{host} = shift;

    $vp->{dir} = $self->{FS_MAILDIR} . $vp->{host} ."/". $vp->{user} ."/";
    $vp->{maildir} = $vp->{dir} . "Maildir/";

    unless ( -e $vp->{dir} ) {
        my @skel = qw(cur new tmp);
        my @dirs = qw(SPAM NoSPAM TODO); # PMS default directorys
        
        mkdir $vp->{dir};
        mkdir $vp->{maildir};
	mkdir $vp->{maildir}.$_ for (@skel);

        foreach my $v (@dirs) {
            mkdir $vp->{maildir}.".".$v;
	    mkdir $vp->{maildir}.".".$v."/".$_ for (@skel);
        }

        #$vp->{user}."@".$vp->{host}." => ".$vp->{dir};
    }

}

sub delete_skeel {

}

sub add_domain {
    my $self = shift;
    my $domain = shift;

    return 0 if $self->valid_domain($domain);

    $self->{db}->insert(
        {
	    dominio    => $domain,
	    estado     => 1,
	    postmaster => 'pms_postmaster@'.$domain,
	    #alias      =>
	},
	table => 'domains',
	ctime => 'fecha_alta');
    
    mkdir $self->{FS_MAILDIR}.$domain;

    open(my $FD,">>",$self->{RCPTHOSTS}) or die "Error :$!";
    print $FD $d."\n";
    close($FD);
}

sub valid_domain {
    my $self = shift;

    my $D = $self->{db}->execute('SELECT * FROM domains WHERE dominio = :d', { d => shift })->fetch_hash;

    return $D->{id} ? 1 : 0;
}

=doc
    metod => from , headers
    method_arg => 
     from : domain / email
     headers : any header of the email
    value => Expression to check
    control => id of user
    out => Mailbox directory
=cut
sub make_filters {
    my $self = shift;
    my $file = shift;
    
    open(my $F,$file) or die "Error : $!";
    my $J = JSON::XS->new->decode(<$F>);
    close($F);

    foreach my $Filter ( @{ $j->{filters} } ) {
	$self->{db}->insert( $Filter , table => 'filters' );
    }

}

# Return @array with all domains
sub domains {
    my $self = shift;

    return $self->{db}->select('dominio', table=> 'domains')->flat;
}

# Returns @array with all user of a domain
sub domains_user {
    my $self = shift;

    return $self->{db}->select('pw_name', where => { pw_domain => shift } , table => 'control')->flat;
}

sub auth_log {

}

sub quota {

}

1;
