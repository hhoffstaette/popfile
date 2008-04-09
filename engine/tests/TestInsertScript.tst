# ----------------------------------------------------------------------------
#
# Tests for insert.pl
#
# Copyright (c) 2003-2006 John Graham-Cumming
#
#   This file is part of POPFile
#
#   POPFile is free software; you can redistribute it and/or modify it
#   under the terms of version 2 of the GNU General Public License as
#   published by the Free Software Foundation.
#
#   POPFile is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with POPFile; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
# ----------------------------------------------------------------------------

# global to store STDOUT when doing backticks

my @stdout;

rmtree( 'messages' );
rmtree( 'corpus' );
test_assert( rec_cp( 'corpus.base', 'corpus' ) );
rmtree( 'corpus/CVS' );
test_assert( `rm popfile.db` == 0);

unlink 'stopwords';
test_assert( copy ( 'stopwords.base', 'stopwords' ) );

my $insert = 'perl -I ../ ../insert.pl';

# One or no command line arguments

@stdout = `$insert`;
$code = ($? >> 8);
test_assert( $code != 0 );

my $line = shift @stdout;

test_assert_regexp( $line, 'insert mail messages into' );

@stdout = `$insert personal`;
test_assert( ($? >> 8) != 0 );
test_assert_regexp( shift @stdout, 'insert mail messages into' );

# Save STDERR

open my $old_stderr, ">&STDERR";

# Bad bucket name

open STDERR, ">temp.tmp";
system("$insert none TestMailParse021.wrd");
close STDERR;
$code = ($? >> 8);
test_assert( $code != 0 );
open TEMP, "<temp.tmp";
$line = <TEMP>;
close TEMP;
test_assert_regexp( $line, 'Error: Bucket `none\' does not exist, insert aborted' );

# Bad file name

open STDERR, ">temp.tmp";
system("$insert personal doesnotexist");
$code = ($? >> 8);
close STDERR;

test_assert( $code != 0 );
open TEMP, "<temp.tmp";
$line = <TEMP>;
close TEMP;
test_assert_regexp( $line, 'Error: File `doesnotexist\' does not exist, insert aborted' );


# Check that insertion actually works

my %words;

open WORDS, "<TestMailParse021.wrd";
while ( <WORDS> ) {
    if ( /(.+) (\d+)/ ) {
        $words{$1} = $2;
    }
}
close WORDS;

open STDERR, ">temp.tmp";
@stdout =`$insert personal TestMailParse021.msg`;
$code = ($? >> 8);
close STDERR;

# Restore STDERR

open STDERR, ">&", $old_stderr;

test_assert_equal( $code, 0 );

$line = shift @stdout;

test_assert_regexp( $line, 'Added 1 files to `personal\'' );

use POPFile::Loader;
my $POPFile = POPFile::Loader->new();
$POPFile->CORE_loader_init();
$POPFile->CORE_signals();

my %valid = ( 'Classifier/Bayes' => 1,
              'POPFile/Logger' => 1,
              'POPFile/MQ'     => 1,
              'POPFile/Database'     => 1,
              'POPFile/Configuration' => 1 );

$POPFile->CORE_load( 0, \%valid );
$POPFile->CORE_initialize();
$POPFile->CORE_config( 1 );
$POPFile->CORE_start();

my $b = $POPFile->get_module( 'Classifier/Bayes' );
my $session = $b->get_session_key( 'admin', '' );

foreach my $word (keys %words) {
    test_assert_equal( $b->get_base_value_( $session, 'personal', $word ), $words{$word}, "personal: $word $words{$word}" );
}

$b->release_session_key( $session );
$POPFile->CORE_stop();

1;


