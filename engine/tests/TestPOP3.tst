# ---------------------------------------------------------------------------------------------
#
# Tests for POP3.pm
#
# Copyright (c) 2003 John Graham-Cumming
#
# ---------------------------------------------------------------------------------------------

use POPFile::Configuration;
use POPFile::MQ;
use POPFile::Logger;
use Proxy::POP3;
use Classifier::Bayes;
use IO::Handle;
use IO::Socket;

use POSIX ":sys_wait_h";

my $eol = "\015\012";

sub forker
{
    pipe my $reader, my $writer;
    my $pid = fork();

    if ( !defined( $pid ) ) {
        close $reader;
        close $writer;
        return (undef, undef);
    }

    if ( $pid == 0 ) {
        close $reader;

        use IO::Handle;
        $writer->autoflush(1);

        return (0, $writer);
    }

    close $writer;
    return ($pid, $reader);
}

sub pipeready
{
    my ( $pipe ) = @_;

    if ( !defined( $pipe ) ) {
        return 0;
    }

    if ( $^O eq 'MSWin32' ) {
        return ( ( -s $pipe ) > 0 );
    } else {
        my $rin = '';
        vec( $rin, fileno( $pipe ), 1 ) = 1;
        my $ready = select( $rin, undef, undef, 0.01 );
        return ( $ready > 0 );
    }
}

sub server
{
    my ( $client ) = @_;
    my @messages = sort glob 'TestMailParse*.msg';

    print $client "+OK Ready$eol";

    while  ( <$client> ) {
        my $command;

        $command = $_;
        $command =~ s/(\015|\012)//g;

        if ( $command =~ /USER (.*)/i ) {
	    if ( $1 =~ /(gooduser)/ ) {
                 print $client "+OK Welcome $1$eol";
	    } else {
                 print $client "-ERR Unknown user $1$eol";
            }
            next;
        }

        if ( $command =~ /PASS (.*)/i ) {
	    if ( $1 =~ /secret/ ) {
                 print $client "+OK Now logged in$eol";
	    } else {
                 print $client "-ERR Bad Password$eol";
            }
            next;
	}

        if ( ( $command =~ /LIST ?(.*)?/i ) ||
             ( $command =~ /UIDL ?(.*)?/i ) ||
             ( $command =~ /STAT/ ) ) {
            my $count = 0;
            my $size  = 0;
            for my $i (0..$#messages) {
	        if ( $messages[$i] ne '' ) {
                    $count += 1;
                    $size  += ( -s $messages[$i] );
	        }
	    }

            print $client "+OK $count $size$eol";

            if ( $command =~ /STAT/ ) {
                next;
	    }

            for my $i (0..$#messages) {
	        if ( $messages[$i] ne '' ) {
                     my $resp = ( $command =~ /LIST/ )?( -s $messages[$i] ):$messages[$i];
                     print $client ($i+1) . " $resp$eol";
	        }
	    }

            print $client ".$eol";

            next;
        }

        if ( $command =~ /QUIT/i ) {
            print $client "+OK Bye$eol";
            last;
        }

        if ( $command =~ /__QUIT__/i ) {
            print $client "+OK Bye$eol";
            return 0;
        }

        if ( $command =~ /RSET/i ) {
            @messages = sort glob 'TestMailParse*.msg';
            print $client "+OK Reset$eol";
            next;
        }

        if ( $command =~ /HELO/i ) {
            print $client "+OK Hello$eol";
            next;
        }

        if ( $command =~ /DELE (.*)/i ) {
            my $index = $1 - 1;
	    if ( defined( $messages[$index] ) && ( $messages[$index] ne '' ) ) {
                $messages[$index] = '';
                print $client "+OK Deleted $1$eol";
	    } else {
                print $client "-ERR No such message $1$eol";
            }
            next;
        }

        if ( $command =~ /RETR (\d+)/i ) {
            my $index = $1 - 1;
	    if ( defined( $messages[$index] ) && ( $messages[$index] ne '' ) ) {
                 print $client "+OK " . ( -s $messages[$index] ) . "$eol";

                 open FILE, "<$messages[$index]";
                 while ( <FILE> ) {
                     print $client $_;
		 }
                 close FILE;

                 print $client ".$eol";

	    } else {
                print $client "-ERR No such message $1$eol";
            }
            next;
        }

        if ( $command =~ /TOP (.*) (.*)/i ) {
            my $index = $1 - 1;
	    if ( $messages[$index] ne '' ) {
                 print $client "+OK " . ( -s $messages[$index] ) . "$eol";

                 open FILE, "<$messages[$index]";
                 while ( <FILE> ) {
                     print $client $_;

                     if ( !/[^ \t\r\n]/ ) {
                         last;
		     }
		 }
                 my $countdown = $2;
                 while ( <FILE> && ( $countdown > 0 ) ) {
                     print $client $_;
                     $countdown -= 1;
		 }
                 close FILE;

                 print $client ".$eol";

	    } else {
                print $client "-ERR No such message $1$eol";
            }
            next;
        }

        if ( $command =~ /CAPA/i ) {
            print $client "+OK I can handle$eol" . "AUTH$eol" . "USER$eol" . "APOP$eol.$eol";
            next;
        }

        if ( $command =~ /APOP (.*):((.*):)?(.*) (.*)/i ) {
            next;
        }

        if ( $command =~ /AUTH ([^ ]+)/ ) {
            next;
        }

        if ( $command =~ /AUTH/ ) {
            next;
        }

        if ( $command =~ /JOHN/ ) {
            print $client "+OK Hello John$eol";
            next;
        }

        print $client "-ERR unknown command or bad syntax$eol";
    }

    return 0;
}

test_assert( `rm -rf corpus` == 0 );
test_assert( `cp -R corpus.base corpus` == 0 );

my $c = new POPFile::Configuration;
my $mq = new POPFile::MQ;
my $l = new POPFile::Logger;
my $b = new Classifier::Bayes;

$c->configuration( $c );
$c->mq( $mq );
$c->logger( $l );

$c->initialize();

$l->configuration( $c );
$l->mq( $mq );
$l->logger( $l );

$l->initialize();

$mq->configuration( $c );
$mq->mq( $mq );
$mq->logger( $l );

$b->configuration( $c );
$b->mq( $mq );
$b->logger( $l );

$b->initialize();
$b->module_config_( 'html', 'port', 8080 );
$b->config_( 'hostname', '127.0.0.1' );
$b->start();

my $pid = fork();

if ( $pid == 0 ) {

    # CHILD THAT WILL RUN THE POP3 SERVER

    my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                    LocalAddr => 'localhost',
                                    LocalPort => 8110,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1 );

    my $selector = new IO::Select( $server );

    while ( 1 ) {
        if ( defined( $selector->can_read(0) ) ) {
            if ( my $client = $server->accept() ) {
                last if !server($client);
                close $client;
	    }
        }
    }

    exit(0);
} else {

    my $port = 9000 + int(rand(1000));
    my $pid2 = fork();

    if ( $pid2 == 0 ) {

        # CHILD THAT WILL RUN THE POP3 PROXY

        my $p = new Proxy::POP3;

        $p->configuration( $c );
        $p->mq( $mq );
        $p->logger( $l );
        $p->classifier( $b );

        $p->forker( \&forker );
        $p->pipeready( \&pipeready );

        $p->{version_} = 'test suite';
        $p->initialize();
        $p->config_( 'port', $port );
        $p->global_config_( 'timeout', 1 );
        $p->start();

        my $now = time;

        while ( $p->service() && ( ( $now + 5 ) > time ) ) {
	}

        my @kids = keys %{$p->{children__}};
        while ( $#kids >= 0 ) {
            $p->reaper();
            select( undef, undef, undef, 0.25 );
            @kids = keys %{$p->{children__}};
        }

        $p->stop();

        exit(0);
    } else {

        # PARENT THAT WILL SEND COMMAND TO THE PROXY

        my $client = IO::Socket::INET->new(
                        Proto    => "tcp",
                        PeerAddr => 'localhost',
                        PeerPort => $port );

        test_assert( defined( $client ) );
        test_assert( $client->connected );

        # Make sure that POPFile sends an appropriate banner

        my $result = <$client>;
        test_assert_equal( $result, "+OK POP3 POPFile (test suite) server ready$eol" );

        # Try a connection to a server that does not exist

        print $client "USER 127.0.0.1:8111:gooduser$eol";
        $result = <$client>;
        test_assert_equal( $result, "-ERR can't connect to 127.0.0.1:8111$eol" );

        # Check that we can connect to the remote POP3 server (should still be waiting
        # for us)

        print $client "USER 127.0.0.1:8110:gooduser$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK Welcome gooduser$eol" );

        # TODO check for LOGIN message

        # Now send a bad password

        print $client "PASS password$eol";
        $result = <$client>;
        test_assert_equal( $result, "-ERR Bad Password$eol" );

        # And then a good one

        print $client "PASS secret$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK Now logged in$eol" );

        # Test that the catch all code works for connected servers

        print $client "JOHN$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK Hello John$eol" );

        # Check that we handle HELO locally

        print $client "HELO$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK HELO POPFile Server Ready$eol" );

        # Get the LIST response and verify

        print $client "LIST$eol";

        my $count = 0;
        my $size  = 0;
        my @messages = sort glob 'TestMailParse*.msg';
        for my $i (0..$#messages) {
            if ( $messages[$i] ne '' ) {
                $count += 1;
                $size  += ( -s $messages[$i] );
	    }
	}

        $result = <$client>;
        test_assert_equal( $result, "+OK $count $size$eol" );

        for my $i (0..$#messages) {
	     if ( $messages[$i] ne '' ) {
                 my $resp = ( -s $messages[$i] );
                 $result = <$client>;
                 test_assert_equal( $result, ($i+1) . " $resp$eol" );
	    }
	}

        $result = <$client>;
        test_assert_equal( $result, ".$eol" );

        # Make such that UIDL works

        print $client "UIDL$eol";

        $result = <$client>;
        test_assert_equal( $result, "+OK $count $size$eol" );

        for my $i (0..$#messages) {
	     if ( $messages[$i] ne '' ) {
                 my $resp = $messages[$i];
                 $result = <$client>;
                 test_assert_equal( $result, ($i+1) . " $resp$eol" );
	    }
	}

        $result = <$client>;
        test_assert_equal( $result, ".$eol" );

        # Try getting a message (first a bad message number)

        my $notexist = $count + 1;
        print $client "RETR $notexist$eol";
        $result = <$client>;
        test_assert_equal( $result, "-ERR No such message $notexist$eol" );

        # Now get a message that actually exists

        print $client "RETR 1$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK " . ( -s $messages[0] ) . "$eol" );
        my $cam = $messages[0];
        $cam =~ s/msg$/cam/;

        open FILE, "<$cam";
        while ( <FILE> ) {
            my $line = $_;
            $result = <$client>;
            $result =~ s/popfile1=1/popfile0=0/;
            test_assert_equal( $result, $line );
	}
        close FILE;

        $result = <$client>;
        test_assert_equal( $result, "$eol" );
        $result = <$client>;
        test_assert_equal( $result, ".$eol" );

        # TODO check for NEWFL and CLASS messages

        # TODO check that the file was written to the history

        # Try an unsuccessful delete

        print $client "DELE $notexist$eol";
        $result = <$client>;
        test_assert_equal( $result, "-ERR No such message $notexist$eol" );

        # Try a successful delete

        print $client "DELE 1$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK Deleted 1$eol" );

        # Check that we echo the remote servers QUIT response

        print $client "QUIT$eol";
        $result = <$client>;
        test_assert_equal( $result, "+OK Bye$eol" );

        close $client;

        while ( waitpid( $pid, &WNOHANG ) != $pid ) {
        }
        while ( waitpid( $pid2, &WNOHANG ) != $pid2 ) {
        }
    }
}