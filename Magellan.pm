package GPS::Magellan;

use strict;
use warnings;

use GPS::Magellan::Message;
use GPS::Magellan::Coord;

use vars qw($AUTOLOAD);

our $VERSION = '0.5';

sub new {
    my $proto = shift;

    my $class = ref($proto) || $proto;

    my %args = @_;

    my $port = $args{port} || '/dev/ttyS0';

    my $self = bless {
        RUN_OFFLINE => $args{RUN_OFFLINE} || 0,
        port => $port,
        raw_file => 'magellan.log',
        debug => 1,
    }, $class;

    warn "calling init\n";
    magellan_init() unless $self->RUN_OFFLINE;
    $self;
}

sub connect {
    my $self = shift;
    return if $self->RUN_OFFLINE;
#    die sprintf("GPS::Magellan::new(): port not specified") unless $self->{port};
#    OpenPort($self->{port});
}

sub getPoints {
    my $self = shift;
    my $cmd = shift or die "getPoint( WAYPOINT | TRACKLOG )\n";

    my @messages = $self->_command($cmd);
    my @coords = (); 
    foreach my $msg (@messages){
        my $wpt = GPS::Magellan::Coord->new($msg->DATA);
        push @coords, $wpt;
    }
    return @coords;
}

sub _command {
    my $self = shift;
    my $cmd = shift;

    die "_command() needs cmd" unless $cmd;

    return $self->__command($cmd) unless $self->RUN_OFFLINE;

    my $data_file = "test-data/$cmd";

    open(DATA, "$data_file") or die "cannot open $data_file\n";
    my @result = <DATA>;
    close(DATA);

    map { 
        chomp;
        my $data = $_;
        $_ = GPS::Magellan::Message->new;
        $_->DATA($data);
    } @result;
    

# Record responses to file
#
#    open(DATA, ">$data_file") or die "cannot open $data_file\n";
#
#    my @result = $self->__command($cmd);
#
#    foreach my $line (@result) { 
#        next unless $line;
#        print DATA "$line\n";
#    }
#
#    close(DATA);

    return @result;

}

sub __command {
    my $self = shift;
    my $cmd = shift;

    die "_command() needs cmd" unless $cmd;

    magellan_handon();

    MagWriteMessageSum("PMGNCMD,$cmd");

    my @messages = ();

    while(1){
        my $raw_msg = magellan_findmessage('$PMGN') or next;

        my $msg = GPS::Magellan::Message->new($raw_msg);
        
        # print $msg->_dump;

        if($msg->COMMAND eq 'CMD'){
            last if $msg->DATA eq 'END';
        }

        my $chksum = $msg->CHECKSUM;

        my $ack = sprintf("PMGNCSM,%s", $chksum);

        MagWriteMessageNoAck($ack);
    
        push @messages, $msg;
    }
    return @messages;
}


# Accessors
sub _get {
    my $self = shift;
    my $attr = shift;
    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}

sub _debug_autoload {
    my $self = shift;
    $self->_set('_debug_autoload', shift) if @_;
    $self->_get('_debug_autoload');
}

    
sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;

    $attr =~ s/.*:://;

    return if $attr =~ /^_/;

    warn "AUTOLOAD: $attr\n" if $self->_debug_autoload;

    if(@_){
        $self->_set($attr, shift);
    }
    return $self->_get($attr);
}

sub DESTROY {
    ClosePort() unless shift->RUN_OFFLINE;
}

require XSLoader;
XSLoader::load('GPS::Magellan', $VERSION);





1;

__END__

=head1 NAME

GPS::Magellan - Module for communicating with Magellan receivers

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

Soming soon, until then see README, examples/magellan.pl and the 
test suite for example.

=head1 METHODS

=over 4

=cut

=item new ( )


=cut


=back 4

=head1 PREREQUISITES

L<>

=head1 AUTHOR

Peter Banik E<lt>peter@login-fo.netE<gt>

=head1 SEE ALSO

L<GPS::Magellan>

=head1 VERSION

$Id: Magellan.pm,v 1.1.1.1.4.8 2003/05/17 01:32:14 peter Exp $

=head1 BUGS

Please report bugs to the author.

=head1 COPYRIGHT

Copyright (c) 2003 

=cut



