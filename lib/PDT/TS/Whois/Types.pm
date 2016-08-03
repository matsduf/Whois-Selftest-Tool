package PDT::TS::Whois::Types;
use utf8;
use strict;
use warnings;
use 5.014;

use Carp;
use English;
use Readonly;
use URI;
use Regexp::IPv6;

use PDT::TS::Whois::UnicodeData;

=head1 NAME

PDT::TS::Whois::Types - Simple type checker class

=head1 DESCRIPTION

This class provides a number of types out of the box and a mechanism for
extending the default set with specialized types.

A type consists of a name and a sub. The sub takes a string value and returns a
list of validation error strings.

The default types are:
 * country code
 * dnssec
 * domain status
 * domain status code
 * email address
 * epp repo id
 * hostname
 * http url
 * ip address
 * key translation
 * phone number
 * positive integer
 * postal code
 * postal line
 * roid
 * time stamp
 * token
 * translation clause
 * u-label
 * domain name object additional field key
 * registrar object additional field key
 * name server object additional field key
 * void

=cut

Readonly my %DOMAIN_STATUS_CODES => (
    addPeriod                => 1,
    autoRenewPeriod          => 1,
    clientDeleteProhibited   => 1,
    clientHold               => 1,
    clientRenewProhibited    => 1,
    clientTransferProhibited => 1,
    clientUpdateProhibited   => 1,
    inactive                 => 1,
    ok                       => 1,
    pendingCreate            => 1,
    pendingDelete            => 1,
    pendingRenew             => 1,
    pendingRestore           => 1,
    pendingTransfer          => 1,
    pendingUpdate            => 1,
    redemptionPeriod         => 1,
    renewPeriod              => 1,
    serverDeleteProhibited   => 1,
    serverHold               => 1,
    serverRenewProhibited    => 1,
    serverTransferProhibited => 1,
    serverUpdateProhibited   => 1,
    transferPeriod           => 1,
);

Readonly my %DOMAIN_NAME_ADDITIONAL_FIELD_KEY_BLACKLIST => (
    'Domain Name'                  => 1,
    'Domain ID'                    => 1,
    'WHOIS Server'                 => 1,
    'Referral URL'                 => 1,
    'Updated Date'                 => 1,
    'Creation Date'                => 1,
    'Registry Expiry Date'         => 1,
    'Sponsoring Registrar'         => 1,
    'Sponsoring Registrar IANA ID' => 1,
    'Domain Status'                => 1,
    'Registrant ID'                => 1,
    'Registrant Name'              => 1,
    'Registrant Organization'      => 1,
    'Registrant Street'            => 1,
    'Registrant City'              => 1,
    'Registrant State/Province'    => 1,
    'Registrant Postal Code'       => 1,
    'Registrant Country'           => 1,
    'Registrant Phone'             => 1,
    'Registrant Phone Ext'         => 1,
    'Registrant Fax'               => 1,
    'Registrant Fax Ext'           => 1,
    'Registrant Email'             => 1,
    'Admin ID'                     => 1,
    'Admin Name'                   => 1,
    'Admin Organization'           => 1,
    'Admin Street'                 => 1,
    'Admin City'                   => 1,
    'Admin State/Province'         => 1,
    'Admin Postal Code'            => 1,
    'Admin Country'                => 1,
    'Admin Phone'                  => 1,
    'Admin Phone Ext'              => 1,
    'Admin Fax'                    => 1,
    'Admin Fax Ext'                => 1,
    'Admin Email'                  => 1,
    'Tech ID'                      => 1,
    'Tech Name'                    => 1,
    'Tech Organization'            => 1,
    'Tech Street'                  => 1,
    'Tech City'                    => 1,
    'Tech State/Province'          => 1,
    'Tech Postal Code'             => 1,
    'Tech Country'                 => 1,
    'Tech Phone'                   => 1,
    'Tech Phone Ext'               => 1,
    'Tech Fax'                     => 1,
    'Tech Fax Ext'                 => 1,
    'Tech Email'                   => 1,
    'DNSSEC'                       => 1,
    'Name Server'                  => 1,
    'IP Address'                   => 1,
);

Readonly my %REGISTRAR_ADDITIONAL_FIELD_KEY_BLACKLIST => (
    'Registrar Name'    => 1,
    'Street'            => 1,
    'City'              => 1,
    'State/Province'    => 1,
    'Postal Code'       => 1,
    'Country'           => 1,
    'Phone Number'      => 1,
    'Email'             => 1,
    'WHOIS Server'      => 1,
    'Referral URL'      => 1,
    'Admin Contact'     => 1,
    'Technical Contact' => 1,
    'Fax Number'        => 1,
);

Readonly my %NAME_SERVER_ADDITIONAL_FIELD_KEY_BLACKLIST => (
    'Server Name'  => 1,
    'IP Address'   => 1,
    'Registrar'    => 1,
    'WHOIS Server' => 1,
    'Referral URL' => 1,
);

my $ROID_SUFFIX = {};
my %default_types;

%default_types = (
    'positive integer' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected positive integer' );
        }

        if ( $value !~ /^[1-9][0-9]*$/o ) {
            return ( 'expected positive integer' );
        }

        return ();
    },
    'country code' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected country code' );
        }

        if ( $value !~ /^[a-zA-Z]{2}$/o ) {
            return ( 'expected country code' );
        }

        return ();
    },
    'dnssec' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected dnssec delegation status' );
        }

        if ( $value !~ /^(?:signedDelegation|unsigned)$/o ) {
            return ( 'expected dnssec delegation status' );
        }

        return ();
    },
    'domain status code' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected domain status code' );
        }

        if ( !exists $DOMAIN_STATUS_CODES{$value} ) {
            return ( 'expected domain status code' );
        }

        return ();
    },
    'key translation' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected key translation' );
        }

        if ( !$value || $value =~ /^ /o || $value =~ /[\(\)]/o || $value =~ / $/o ) {
            return ( 'expected key translation' );
        }

        return ();
    },
    'translation clause' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected translation clause' );
        }

        if ( $value =~ /^ \((.*)\)$/o ) {
            my @errors;
            for my $key_translation ( split qr{/}, $1 ) {
                push @errors, $default_types{'key translation'}->( $key_translation );
            }
            return @errors;
        }

        return ( 'expected translation clause' );
    },
    'hostname' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected hostname' );
        }

        if (   $value !~ /^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])*\.){1,}[a-zA-Z]([a-zA-Z0-9-]*[a-zA-Z0-9])\.?$/o
            || ( $value =~ /\.$/o && length( $value ) > 255 )
            || ( $value !~ /\.$/o && length( $value ) > 254 ) )
        {
            return ( 'expected hostname' );
        }

        foreach ( split( /\./o, $value ) ) {
            if ( length( $_ ) > 63 ) {
                return ( 'expected hostname' );
            }
        }

        return ();
    },
    'u-label' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected u-label' );
        }

        if ( $value && $default_types{hostname}->( $value ) ) {
            return ();
        }

        return ( 'expected u-label' );
    },
    'roid' => sub {
        my $value = shift;

        if ( !defined $value ) {
            return ( 'expected roid' );
        }
        elsif ( $default_types{token}->( $value ) ) {
            return ( 'expected roid' );
        }
        elsif ( $value =~ /^(.{1,80})-(.{1,8})$/ ) {
            my $prefix = $1;
            my $suffix = $2;
            if ( grep { !is_word_char( $_ ) && $_ ne '_' } split //, $prefix ) {
                return ( 'expected roid' );
            }
            elsif ( $default_types{'roid suffix'}->( $suffix ) ) {
                return ( 'expected roid' );
            }
            elsif ( !exists $ROID_SUFFIX->{$suffix} ) {
                return ( 'expected roid suffix to be a registered epp repo id' );
            }
            else {
                return ();
            }
        }
        else {
            return ( 'expected roid' );
        }
    },
    'roid suffix' => sub {
        my $value = shift;

        if ( !defined $value ) {
            return ( 'expected roid suffix' );
        }
        elsif ( $default_types{token}->( $value ) ) {
            return ( 'expected roid suffix' );
        }
        elsif ( $value =~ /^(.{1,8})$/ ) {
            my $suffix = $1;
            if ( grep { !is_word_char( $_ ) } split //, $suffix ) {
                return ( 'expected roid suffix' );
            }
            else {
                return ();
            }
        }
        else {
            return ( 'expected roid suffix' );
        }
    },
    'http url' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected http url' );
        }

        my $uri = URI->new( $value );
        if ( $uri->scheme && $uri->scheme =~ /^https?$/oi && $uri->opaque ) {
            return ();
        }

        return ( 'expected http url' );
    },
    'time stamp' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected time stamp' );
        }

        #
        # Regex taken from https://mxr.mozilla.org/comm-central/source/calendar/base/modules/calProviderUtils.jsm#316
        # Modified to remove extraction of values and timezone offset at the end
        #
        if ( $value !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}(?:[Tt][0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?)?[Zz]?$/o ) {
            return ( 'expected time stamp' );
        }

        return ();
    },
    'token' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected token' );
        }

        if ( !$value || $value =~ /[\r\n\t]/o || $value =~ /^ /o || $value =~ / $/o || $value =~ /  /o ) {
            return ( 'expected token' );
        }

        return ();
    },
    'domain status' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected domain status' );
        }

        if ( $value =~ qr{^([^ ]+) {1,9}https://icann\.org/epp\#(.+)$} ) {
            if ( exists $DOMAIN_STATUS_CODES{$1} ) {
                if ( $1 eq $2 ) {
                    return ();
                }
                elsif ( $1 eq 'ok' && $2 eq 'OK' ) {
                    return ();
                }
            }
        }

        return ( 'expected domain status' );
    },
    'postal line' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected postal line' );
        }

        if ( length( $value ) < 1 || length( $value ) > 255 || $value =~ /[\r\n\t]/o ) {
            return ( 'expected postal line' );
        }

        return ();
    },
    'postal code' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected postal code' );
        }

        if ( length( $value ) > 16 || $default_types{token}->( $value ) ) {
            return ( 'expected postal code' );
        }

        return ();
    },
    'phone number' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected phone number' );
        }

        if ( length( $value ) > 17 || $default_types{token}->( $value ) || $value !~ /^\+[0-9]{1,3}\.[0-9]{1,14}$/o ) {
            return ( 'expected phone number' );
        }

        return ();
    },
    'email address' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected email address' );
        }

        my ( $localpart, $domain ) = split( '@', $value, 2 );

        if ( !$localpart || $default_types{hostname}->( $domain ) || $domain =~ /\.$/o ) {
            return ( 'expected email address' );
        }

        foreach ( split( '.', $localpart ) ) {
            unless ( /^[a-zA-Z0-9!#\$\%\&'\*\+\-\/=\?\^_`{}\|~]+$/o ) {
                return ( 'expected email address' );
            }
        }

        return ();
    },
    'ip address' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected ip address' );
        }

        if ( $value =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/o ) {
            foreach ( ( $1, $2, $3, $4 ) ) {
                if ( $_ eq '0' ) {
                    next;
                }
                if ( $default_types{'positive integer'}->( $_ ) || $_ > 255 ) {
                    return ( 'expected ip address' );
                }
            }
            return ();
        }

        if ( $value =~ /^$Regexp::IPv6::IPv6_re$/o ) {
            return ();
        }

        return ( 'expected ip address' );
    },
    'epp repo id' => sub {
        my $value = shift;

        unless ( defined $value ) {
            return ( 'expected epp repo id' );
        }

        if ( $default_types{roid}->( $value ) ) {
            return ( 'expected epp repo id' );
        }

        return ();
    },
    'domain name object additional field key' => sub {
        my $value = shift;

        unless ( $value ) {
            return ( 'expected domain name object additional field key' );
        }

        if ( exists $DOMAIN_NAME_ADDITIONAL_FIELD_KEY_BLACKLIST{$value} ) {
            return ( 'forbidden domain name object additional field key' );
        }

        return ();
    },
    'registrar object additional field key' => sub {
        my $value = shift;

        unless ( $value ) {
            return ( 'expected registrar object additional field key' );
        }

        if ( exists $REGISTRAR_ADDITIONAL_FIELD_KEY_BLACKLIST{$value} ) {
            return ( 'forbidden registrar object additional field key' );
        }

        return ();
    },
    'name server object additional field key' => sub {
        my $value = shift;

        unless ( $value ) {
            return ( 'expected name server object additional field key' );
        }

        if ( exists $NAME_SERVER_ADDITIONAL_FIELD_KEY_BLACKLIST{$value} ) {
            return ( 'forbidden name server object additional field key' );
        }

        return ();
    },
    'void' => sub {
        return ( 'no values are allowed for type void' );
    },
);

=head1 CONSTRUCTORS

=head2 new

Creates a new type checker object with the default set of types.

    my $types = PDT::TS::Whois::Types->new();

=cut

sub new {
    my $class = shift;
    my $self = bless { _types => { %default_types, }, }, $class;
    return $self;
}

=head2 add_type

Adds (or updates) a type to the set recognized by this type checker.

    $types->add_type('my-type', sub {
        my $value = shift;
        if ( $value =~ /^my-[a-z-]+/ ) {
            return ( 'expected my-type' );
        }
        else {
            return ();
        }
    });

=cut

sub add_type {
    my $self      = shift;
    my $type_name = shift or croak 'Missing argument: $type_name';
    my $sub       = shift or croak 'Missing argument: $sub';
    ref $sub eq 'CODE' or croak 'Argument $sub must be a coderef';
    $self->{_types}{$type_name} = $sub;
    return;
}

=head2 has_type

Test if a type is recognized by this type checker.

    if ($types->has_type('my-type')) {
        say "Type my-type recognized!";
    }
    else {
        say "Unknown type my-type!";
    }

=cut

sub has_type {
    my $self = shift;
    my $type_name = shift or croak 'Missing argument: $type_name';
    return exists $self->{_types}{$type_name};
}

=head2 validate_type

Validate a value against a type.

    my @errors = $types->validate_type('my-type', 'my-value')
    if (@errors) {
        for my $error (@errors) {
            say "type error: $error";
        }
    }
    else {
        say "ok";
    }

=cut

sub validate_type {
    my $self      = shift;
    my $type_name = shift;
    my $value     = shift;
    croak "$type_name: unknown type" unless exists $self->{_types}{$type_name};
    return $self->{_types}{$type_name}->( $value );
}

=head2 load_roid_suffix

Load ROID suffixes from a file. Croaks on error.

    $types->load_roid_suffix('/etc/pdt/iana-epp-rep-id.txt');

=cut

sub load_roid_suffix {
    my ( $self, $file ) = @_;
    my ( $fh, $roid_suffix, $line_no ) = ( undef, {}, 1 );

    open $fh, '<:encoding(UTF-8)', $file or croak "Couldn't open '$file': $OS_ERROR";
    my @lines = <$fh>;
    close( $fh ) or croak "Couldn't close '$file': $OS_ERROR";

    for ( @lines ) {
        s/[\r\n]+$//;

        if ( /^\s*#/ ) {
            next;
        }
        elsif ( /^(.{1,8})$/ ) {
            my $suffix = $1;
            if ( !grep { !is_word_char( $_ ) } split //, $suffix ) {
                $roid_suffix->{$suffix} = 1;
                $line_no++;
                next;
            }
        }
        die "$file line $line_no: Invalid syntax";
    }

    $ROID_SUFFIX = $roid_suffix;

    return;
}

1;
