# ---------------------------------------------------------------------------------------------
#
# Tests for WordMangle.pm
#
# Copyright (c) 2003 John Graham-Cumming
#
# ---------------------------------------------------------------------------------------------

use Classifier::WordMangle;

my $w = new Classifier::WordMangle;

# Test basic mangling functions

test_assert_equal( $w->mangle( 'BIGWORD' ), 'bigword' );
test_assert_equal( $w->mangle( 'BIG+/?*|()[]{}^$.WORD' ), 'big..............word' );
test_assert_equal( $w->mangle( 'awordthatisfartolongtobeacceptableforuseinclassification' ), '' );
test_assert_equal( $w->mangle( 'A1234BEF66' ), '' );
test_assert_equal( $w->mangle( 'BIG:WORD' ), 'bigword' );
test_assert_equal( $w->mangle( 'BIG:WORD', 1 ), 'big:word' );

# Test stop words
test_assert_equal( $w->mangle( 'BIGWORD' ), 'bigword' );
test_assert_equal( $w->add_stopword( 'bigword' ), 1 );
test_assert_equal( $w->mangle( 'BIGWORD' ), '' );
test_assert_equal( $w->remove_stopword( 'bigword' ), 1 );
test_assert_equal( $w->mangle( 'BIGWORD' ), 'bigword' );
test_assert_equal( $w->add_stopword( '' ), 0 );
test_assert_equal( $w->remove_stopword( '' ), 0 );
test_assert_equal( $w->add_stopword( 'A1234bef66' ), 0 );
test_assert_equal( $w->remove_stopword( 'A1234bef66' ), 0 );

# Getter/setter
my %stops = ( 'oneword', 1 );
$w->stopwords( \%stops );
test_assert_equal( $w->mangle( 'oneWORD' ), '' );
my @stopwords = $w->stopwords();
test_assert_equal( $#stopwords, 0 );
test_assert_equal( $stopwords[0], 'oneword' );
$w->load_stopwords();

# Make sure that stopwords got to disk
test_assert_equal( $w->add_stopword( 'bigword' ), 1 );
open WORDS, "<stopwords";
my $found = 0;
while (<WORDS>) {
    if ( $_ =~ /bigword/ ) {
        $found = 1;
        last;
    }
}
close WORDS;
test_assert( $found );
test_assert_equal( $w->remove_stopword( 'bigword' ), 1 );