#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util::MediaType');
}

{
    my $parsed_media_type = Web::Machine::Util::MediaType->new_from_string('application/xml;charset=UTF-8');
    isa_ok($parsed_media_type, 'Web::Machine::Util::MediaType');

    is($parsed_media_type->type, 'application/xml', '... got the right type');
    is_deeply(
        $parsed_media_type->params,
        { 'charset' => 'UTF-8' },
        '... got the right params'
    );

    is($parsed_media_type->major, 'application', '... got the right major portion');
    is($parsed_media_type->minor, 'xml', '... got the right minor portion');

    is($parsed_media_type->to_string, 'application/xml;charset=UTF-8', '... the string representation');

    my $media_type = Web::Machine::Util::MediaType->new('application/xml', => ( 'charset' => 'UTF-8' ));
    isa_ok($media_type, 'Web::Machine::Util::MediaType');
    is($media_type->to_string, 'application/xml;charset=UTF-8', '... the string representation');

    ok($parsed_media_type->equals( $media_type ), '... these types are equal');
    ok($parsed_media_type->equals('application/xml;charset=UTF-8'), '... these types are equal');

    ok(!$parsed_media_type->matches_all, '... this is not a matches_all type');

    ok($parsed_media_type->exact_match('application/xml;charset=UTF-8'), '... these types are an exact match');
    ok($parsed_media_type->exact_match('application/*;charset=UTF-8'), '... these types are an exact match');
    ok($parsed_media_type->exact_match('*/*;charset=UTF-8'), '... these types are an exact match');

    ok(!$parsed_media_type->exact_match('application/json;charset=UTF-8'), '... these types are not an exact match');
    ok(!$parsed_media_type->exact_match('application/xml;charset=Latin-1'), '... these types are not an exact match');

    ok($parsed_media_type->match('application/xml'), '... these types are a match');

    ok(!$parsed_media_type->match('application/xml;charset=UTF-8;version=1'), '... these types are not a match');
    ok(!$parsed_media_type->match('application/*;charset=UTF-8;version=1'), '... these types are not a match');
    ok(!$parsed_media_type->match('*/*;charset=UTF-8;version=1'), '... these types are a match');
    ok(!$parsed_media_type->match('application/xml;charset=Latin-1;version=1'), '... these types are not a match');
    ok(!$parsed_media_type->match('application/json;charset=UTF-8;version=1'), '... these types are not a match');
}

{
    my $matches_all = Web::Machine::Util::MediaType->new_from_string('*/*');

    is($matches_all->type, '*/*', '... got the right type');
    is_deeply(
        $matches_all->params,
        {},
        '... got the right params'
    );

    is($matches_all->to_string, '*/*', '... the string representation');

    ok($matches_all->matches_all, '... this type does match all');
}

{
    my $multiline = Web::Machine::Util::MediaType->new_from_string(q[multipart/form-data;
boundary=----------------------------2c46a7bec2b9]);

    is($multiline->type, 'multipart/form-data', '... got the right type');
    is_deeply(
        $multiline->params,
        { 'boundary' => '----------------------------2c46a7bec2b9' },
        '... got the right params'
    );

    is($multiline->to_string, 'multipart/form-data;boundary=----------------------------2c46a7bec2b9', '... the string representation');
}

# test multiple params ...
{
    my $mt = Web::Machine::Util::MediaType->new_from_string('application/json;v=3;foo=bar');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar' },
        '... got the right params'
    );

    is($mt->to_string, 'application/json;v=3;foo=bar', '... got the right string representation');
}

# test a lot of params ...
{
    my $mt = Web::Machine::Util::MediaType->new_from_string('application/json;v=3;foo=bar;q=0.25;testing=123');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar', q => 0.25, testing => 123 },
        '... got the right params'
    );

    is($mt->to_string, 'application/json;v=3;foo=bar;q=0.25;testing=123', '... got the right string representation');
}

done_testing;


