package Web::Machine::Util::ContentNegotiation;
# ABSTRACT: Module to handle content negotiation

use strict;
use warnings;

use Web::Machine::Util qw[ first pair_key ];

use Web::Machine::Util::MediaType;
use Web::Machine::Util::MediaTypeList;
use Web::Machine::Util::PriorityList;

use Sub::Exporter -setup => {
    exports => [qw[
        choose_media_type
        match_acceptable_media_type
        choose_language
        choose_charset
        choose_encoding
    ]]
};

sub choose_media_type {
    my ($provided, $header) = @_;
    my $requested       = Web::Machine::Util::MediaTypeList->new_from_header_list( split /\s*,\s*/ => $header );
    my $parsed_provided = [ map { Web::Machine::Util::MediaType->new_from_string( $_ ) } @$provided ];

    my $chosen;
    foreach my $request ( $requested->iterable ) {
        my $requested_type = $request->[1];
        $chosen = media_match( $requested_type, $parsed_provided );
        last if $chosen;
    }

    ($chosen || return)
}

sub match_acceptable_media_type {
    my ($to_match, $accepted) = @_;
    my $content_type = Web::Machine::Util::MediaType->new_from_string( $to_match );
    if ( my $acceptable = first { $content_type->match( pair_key( $_ ) ) } @$accepted ) {
        return $acceptable;
    }
    return;
}

sub choose_language {
    my ($provided, $header) = @_;

    return 1 if scalar @$provided == 0;

    my $language;
    my $requested     = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*,\s*/ => $header );
    my $star_priority = $requested->priority_of('*');
    my $any_ok        = $star_priority && $star_priority > 0.0;

    my $accepted      = first {
        my ($priority, $range) = @$_;
        if ( $priority == 0.0 ) {
            $provided = [ grep { language_match( $range, $_ )  } @$provided ];
            return 0;
        }
        else {
            return (grep { language_match( $range, $_ ) } @$provided) ? 1 : 0;
        }
    } $requested->iterable;

    if ( $accepted ) {
        $language = first { language_match( $accepted->[-1], $_ ) } @$provided;
    }
    elsif ( $any_ok ) {
        $language = $provided->[0];
    }

    $language;
}

sub choose_charset {
    my ($provided, $header) = @_;

    return 1 if scalar @$provided == 0;

    my @charsets = map { pair_key( $_ ) } @$provided;
    # NOTE:
    # Making the default charset UTF-8, which
    # is maybe sensible, I dunno.
    # - SL
    if ( my $charset = make_choice( \@charsets, $header, 'UTF-8' )) {
        return $charset;
    }

    return;
}

sub choose_encoding {
    my ($provided, $header) = @_;
    my @encodings = keys %$provided;
    if ( my $encoding = make_choice( \@encodings, $header, 'identity' ) ) {
        return $encoding;
    }
    return;
}

## ....

sub media_match {
    my ($requested, $provided) = @_;
    return $provided->[0] if $requested->matches_all;
    return first { $_->match( $requested ) } @$provided;
}

sub language_match {
    my ($range, $tag) = @_;
    ((lc $range) eq (lc $tag)) || $range eq "*" || $tag =~ /^$range\-/i;
}

sub make_choice {
    my ($choices, $header, $default) = @_;

    return if @$choices == 0;
    return if $header eq '';

    $choices = [ map { lc $_ } @$choices ];

    my $accepted         = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*,\s*/ => $header );
    my $default_priority = $accepted->priority_of( $default );
    my $star_priority    = $accepted->priority_of( '*' );

    my ($default_ok, $any_ok);

    if ( not defined $default_priority ) {
        if ( defined $star_priority && $star_priority == 0.0 ) {
            $default_ok = 0;
        }
        else {
            $default_ok = 1;
        }
    }
    elsif ( $default_priority == 0.0 ) {
        $default_ok = 0;
    }
    else {
        $default_ok = 1;
    }

    if ( not defined $star_priority ) {
        $any_ok = 0;
    }
    elsif ( $star_priority == 0.0 ) {
        $any_ok = 0;
    }
    else {
        $any_ok = 1;
    }

    my $chosen = first {
        my ($priority, $acceptable) = @$_;
        if ( $priority == 0.0 ) {
            $choices = [ grep { lc $acceptable ne $_ } @$choices ];
        } else {
            return $acceptable if grep { lc $acceptable eq $_ } @$choices;
        }
    } $accepted->iterable;

    return $chosen->[-1] if $chosen;
    return $choices->[0] if $any_ok;
    return $default      if $default_ok && grep { $default eq $_ } @$choices;
    return;
}


1;

__END__

=head1 SYNOPSIS

  use Web::Machine::FSM::ContentNegotiation;

=head1 DESCRIPTION

This module provides a set of functions used in content negotiation.

=head1 FUNCTIONS

=over 4

=item C<choose_media_type ( $provided, $header )>

Given an ARRAY ref of media type strings and an HTTP header, this will
return the appropriatly matching L<Web::Machine::Util::MediaType> instance.

=item C<match_acceptable_media_type ( $to_match, $accepted )>

Given a media type string to match and an ARRAY ref of media type objects,
this will return the first matching one.

=item C<choose_language ( $provided, $header )>

Given a list of language codes and an HTTP header value, this will attempt
to negotiate the best language match.

=item C<choose_charset ( $provided, $header )>

Given a list of charset name and an HTTP header value, this will attempt
to negotiate the best charset match.

=item C<choose_encoding ( $provided, $header )>

Given a list of encoding name and an HTTP header value, this will attempt
to negotiate the best encoding match.

=back









