# POPFILE LOADABLE MODULE
package POPFile::History;

use POPFile::Module;
@ISA = ("POPFile::Module");

#----------------------------------------------------------------------------
#
# This module handles POPFile's history.  It manages entries in the POPFile
# database and on disk that store messages previously classified by POPFile.
#
# Copyright (c) 2004 John Graham-Cumming
#
#   This file is part of POPFile
#
#   POPFile is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
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
#----------------------------------------------------------------------------

use strict;
use warnings;
use locale;

use Date::Parse;
use Digest::MD5 qw( md5_hex );

my $slot_fields = 'history.id, hdr_from, hdr_to, hdr_cc, hdr_subject,
hdr_date, hash, inserted, buckets.name, usedtobe';

#----------------------------------------------------------------------------
# new
#
#   Class new() function
#----------------------------------------------------------------------------
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = POPFile::Module->new();

    # List of committed history items waiting to be committed
    # into the database, it consists of lists containing three
    # elements: the slot id, the bucket classified to and the
    # magnet if used

    $self->{commit_list__} = ();

    # Contains queries started with start_query and consists
    # of a mapping between unique IDs and quadruples containing
    # a reference to the SELECT and a cache of already fetched
    # rows and a total row count.  These quadruples are implemented
    # as a sub-hash with keys query, count, cache, fields

    $self->{queries__} = ();

    $self->{firsttime__} = 1;

    # Will contain the database handle retrieved from
    # Classifier::Bayes

    $self->{db__} = undef;

    $self->{classifier__} = 0;

    bless($self, $class);

    $self->name( 'history' );

    return $self;
}

#----------------------------------------------------------------------------
#
# initialize
#
# Called to initialize the history module
#
#----------------------------------------------------------------------------
sub initialize
{
    my ( $self ) = @_;

    # Keep the history for two days

    $self->config_( 'history_days', 2 );

    # If 1, Messages are saved to an archive when they are removed or expired
    # from the history cache

    $self->config_( 'archive', 0 );

    # The directory where messages will be archived to, in sub-directories for
    # each bucket

    $self->config_( 'archive_dir', 'archive' );

    # This is an advanced setting which will save archived files to a
    # randomly numbered sub-directory, if set to greater than zero, otherwise
    # messages will be saved in the bucket directory
    #
    # 0 <= directory name < archive_classes

    $self->config_( 'archive_classes', 0 );

    # Need TICKD message for history clean up, COMIT when a message
    # is committed to the history

    $self->mq_register_( 'TICKD', $self );
    $self->mq_register_( 'COMIT', $self );

    return 1;
}

#----------------------------------------------------------------------------
#
# start
#
# Called to start the history module
#
#----------------------------------------------------------------------------
sub start
{
    my ( $self ) = @_;

    return 1;
}

#----------------------------------------------------------------------------
#
# db__
#
# Since we don't know the order in which the start() methods of PLMs
# is called we cannot be sure that Classifier::Bayes will have started
# and connected to the database before us, hence we can't set our
# database handle at start time.  So instead we access the db handle
# through this method
#
#----------------------------------------------------------------------------
sub db__
{
    my ( $self ) = @_;

    if ( !defined( $self->{db__} ) ) {
        $self->{db__} = $self->{classifier__}->db()->clone;
    }

    return $self->{db__};
}

#----------------------------------------------------------------------------
#
# service
#
# Called periodically so that the module can do its work
#
#----------------------------------------------------------------------------
sub service
{
    my ( $self ) = @_;

    if ( $self->{firsttime__} ) {
        $self->upgrade_history_files__();
        $self->{firsttime__} = 0;
    }

    # Commit pending history items to the database

    $self->commit_history__();

    return 1;
}

#----------------------------------------------------------------------------
#
# deliver
#
# Called by the message queue to deliver a message
#
# There is no return value from this method
#
#----------------------------------------------------------------------------
sub deliver
{
    my ( $self, $type, $message, $parameter ) = @_;

    # If a day has passed then clean up the history

    if ( $type eq 'TICKD' ) {
        $self->cleanup_history__();
    }

    if ( $type eq 'COMIT' ) {
        $parameter =~ /([^:]*):(.*)/;
        push ( @{$self->{commit_list__}}, [ $message, $1, $2 ] );
    }
}

# ---------------------------------------------------------------------------
#
# forked
#
# This is called inside a child process that has just forked, since the 
# child needs access to the database we open it
#
# ---------------------------------------------------------------------------
sub forked
{
    my ( $self ) = @_;

    $self->{db__} = undef;
}

#----------------------------------------------------------------------------
#
# ADDING TO THE HISTORY
#
# To add a message to the history the following sequence of calls
# is made:
#
# 1. Obtain a unique ID and filename for the new message by a call
#    to reserve_slot
#
# 2. Write the message into the filename returned
#
# 3. Call commit_slot with the bucket into which the message was
#    classified
#
# If an error occurs after #1 and the slot is unneeded then call
# release_slot
#
#----------------------------------------------------------------------------
#
# FINDING A HISTORY ENTRY
#
# 1. If you know the slot id then call get_slot_file to obtain
#    the full path where the file is stored
#
# 2. If you know the message hash then call get_slot_from hash
#    to get the slot id
#
# 3. If you know the message headers then use get_message_hash
#    to get the hash
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
#
# reserve_slot
#
# Called to reserve a place in the history for a message that is in the
# process of being received.  It returns a unique ID for this slot and
# the full path to the file where the message should be stored.  The
# caller is expected to later call either release_slot (if the slot is not
# going to be used) or commit_slot (if the file has been written and the
# entry should be added to the history).
#
#----------------------------------------------------------------------------
sub reserve_slot
{
    my ( $self ) = @_;

    # Pick a large random number and try to insert it into the database
    # if the insert fails then pick another

    my $r;
    while (1) {
        $r = int( 2 + rand(4294967294) );

        # TODO Replace the hardcoded user ID 1 with the looked up
        # user ID from the session key

        my $ok = $self->db__()->do(
            "insert into history ( userid, committed ) values ( 1, $r );" );
        if ( defined( $ok ) ) {
            last;
        }
        $self->log_( 0, "Failed to insert $r" );
    }

    my $result = $self->db__()->selectrow_arrayref(
                 "select id from history where committed = $r limit 1;");

    my $slot = $result->[0];
    return ( $slot, $self->get_slot_file( $slot ) );
}

#----------------------------------------------------------------------------
#
# release_slot
#
# See description with reserve_slot; release_slot releases a history slot
# previously allocated with reserve_slot and discards it.
#
# id              Unique ID returned by reserve_slot
#
#----------------------------------------------------------------------------
sub release_slot
{
    my ( $self, $slot ) = @_;

    # Remove the entry from the database and delete the file
    # if present

    $self->db__()->do( "delete from history where id = $slot;" );
    unlink $self->get_slot_file( $slot );
}

#----------------------------------------------------------------------------
#
# commit_slot
#
# See description with reserve_slot; commit_slot commits a history
# slot to the database and makes it part of the history.  Before this
# is called the full message should have been written to the file
# returned by reserve_slot.  Note that commit_slot queues the message
# for insertion and does not commit it until some (short) time later
#
# id              Unique ID returned by reserve_slot
# bucket          Bucket classified to
# magnet          Magnet if used
#
#----------------------------------------------------------------------------
sub commit_slot
{
    my ( $self, $slot, $bucket, $magnet ) = @_;

    $self->mq_post_( 'COMIT', $slot, "$bucket:$magnet" );
}

#---------------------------------------------------------------------------
#
# get_slot_fields
#
# Returns the fields associated with a specific slot.  We return the
# same collection of fields as get_query_rows.
#
# slot           The slot id
#
#---------------------------------------------------------------------------
sub get_slot_fields
{
    my ( $self, $slot ) = @_;

    return $self->db__()->selectrow_array(
        "select $slot_fields from history, buckets
             where history.id = $slot and
                   buckets.id = history.bucketid" );
}

#---------------------------------------------------------------------------
#
# commit_history__
#
# (private) Used internally to commit messages that have been committed
# with a call to commit_slot to the database
#
#----------------------------------------------------------------------------
sub commit_history__
{
    my ( $self ) = @_;

    if ( $#{$self->{commit_list__}} == -1 ) {
        return;
    }

    my $session = $self->{classifier__}->get_session_key( 'admin', '' );

    foreach my $entry (@{$self->{commit_list__}}) {
        my ( $slot, $bucket, $magnet ) = @{$entry};

        my $file = $self->get_slot_file( $slot );

        # Committing to the history requires the following steps
        #
        # 1. Parse the message to extract the headers
        # 2. Compute MD5 hash of Message-ID, Date and Subject
        # 3. Update the related row with the headers and
        #    committed set to 1

        my %header;
        my $last;

        if ( open FILE, "<$file" ) {
            while ( <FILE> ) {
                if ( /^[\r\n]*$/ ) {
                    last;
                }

                if ( /^([^ \t]+):[ \t]*([^\r\n]+)/ ) {
                    $last = lc($1);
                    $header{$last} .= $2;
                } else {
                    if ( defined $last ) {
                        $header{$last} .= $_;
                    }
                }
            }
            close FILE;
        }

        my $hash = $self->get_message_hash( $header{'message-id'},
                                            $header{date},
                                            $header{subject} );
        $hash = $self->db__()->quote( $hash );

        # Make sure that the headers we are going to insert into
        # the database have been defined and are suitably quoted

        my @required = ( 'from', 'to', 'cc', 'subject' );

        foreach my $h (@required) {
            if ( !defined $header{$h} ) {
                $header{$h} = '';
            }

            $header{$h} = $self->db__()->quote( $header{$h} );
        }

        # If we do not have a date header then set the date to
        # 0 (start of the Unix epoch), otherwise parse the string
        # using Date::Parse to interpret it and turn it into the
        # Unix epoch.

        if ( !defined( $header{date} ) ) {
            $header{date} = 0;
        } else {
            $header{date} = str2time( $header{date} );
        }

        # Get the date/time now which will be stored in the database
        # so that we can sort on the Date: header in the message and
        # when we received it

        my $now = time;

        # Figure out the ID of the bucket this message has been
        # classified into (and the same for the magnet if it is
        # defined)

        my $bucketid = $self->{classifier__}->get_bucket_id(
                           $session, $bucket );

        # TODO Handle magnets

        my $magnetid = 0;

        my $result = $self->db__()->do(
            "update history set hdr_from    = $header{from},
                                hdr_to      = $header{to},
                                hdr_date    = $header{date},
                                hdr_cc      = $header{cc},
                                hdr_subject = $header{subject},
                                committed   = 1,
                                bucketid    = $bucketid,
                                usedtobe    = 0,
                                magnetid    = $magnetid,
                                inserted    = $now,
                                hash        = $hash
                            where id = $slot;" );
    }

    $self->{commit_list__} = ();
    $self->{classifier__}->release_session_key( $session );
    $self->force_requery__();
}

# ---------------------------------------------------------------------------
#
# delete_slot
#
# Deletes an entry from the database and disk, optionally archiving it
# if the archive parameters have been set
#
# $slot              The slot ID
# $archive           1 if it's OK to archive this entry
#
# ---------------------------------------------------------------------------
sub delete_slot
{
    my ( $self, $slot, $archive ) = @_;

    my $file = $self->get_slot_file( $slot );
    $self->log_( 2, "delete_slot called for slot $slot, file $file" );

    if ( $archive && $self->config_( 'archive' ) ) {
        my $path = $self->get_user_path_( $self->config_( 'archive_dir' ) );

        $self->make_directory__( $path );

        my @b = $self->db__()->selectrow_array( 
            "select buckets.name from history, buckets
                 where history.bucketid = buckets.id and
                       history.id = $slot;" );

        my $bucket = $b[0];

        if ( ( $bucket ne 'unclassified' ) &&
             ( $bucket ne 'unknown class' ) ) {
            $path .= "\/" . $bucket;
            $self->make_directory__( $path );

            if ( $self->config_( 'archive_classes' ) > 0) {

                # Archive to a random sub-directory of the bucket archive

                my $subdirectory = int( rand(
                    $self->config_( 'archive_classes' ) ) );
                $path .= "\/" . $subdirectory;
                $self->make_directory__( $path );
            }

            # Previous comment about this potentially being unsafe (may have
            # placed messages in unusual places, or overwritten files) no longer
            # applies. Files are now placed in the user directory, in the
            # archive_dir subdirectory

            $self->copy_file__( $file, $path, "popfile$slot.msg" );
        }
    }

    # Now remove the entry from the database, and the file from disk,
    # and also invalidate the caches of any open queries since they
    # may have been affected

    $self->release_slot( $slot );
    $self->force_requery__();
}

#----------------------------------------------------------------------------
#
# get_slot_file
#
# Used to map a slot ID to the full path of the file will contain
# the message associated with the slot
#
#----------------------------------------------------------------------------
sub get_slot_file
{
    my ( $self, $slot ) = @_;

    # The mapping between the slot and the file goes as follows:
    #
    # 1. Convert the file to an 8 digit hex number (with leading
    #    zeroes).
    # 2. Call that number aabbccdd
    # 3. Build the path aa/bb/cc
    # 4. Name the file popfiledd.msg
    # 5. Add the msgdir location to obtain
    #        msgdir/aa/bb/cc/popfiledd.msg
    #
    # Hence each directory can have up to 256 entries

    my $hex_slot = sprintf( '%8.8x', $slot );
    my $path = $self->get_user_path_(
                   $self->global_config_( 'msgdir' ) .
                       substr( $hex_slot, 0, 2 ) . '/' );

    $self->make_directory__( $path );
    $path .= substr( $hex_slot, 2, 2 ) . '/';
    $self->make_directory__( $path );
    $path .= substr( $hex_slot, 4, 2 ) . '/';
    $self->make_directory__( $path );

    my $file = 'popfile' .
               substr( $hex_slot, 6, 2 ) . '.msg';

    return $path . $file;
}

#----------------------------------------------------------------------------
#
# get_message_hash
#
# Used to compute an MD5 hash of the headers of a message
# so that the same message can later me identified by a
# call to get_slot_from_hash
#
# messageid              The message id header
# date                   The date header
# subject                The subject header
#
# Note that the values passed in are everything after the : in
# header without the trailing \r or \n.  If a header is missing
# then pass in the empty string
#
#----------------------------------------------------------------------------
sub get_message_hash
{
    my ( $self, $messageid, $date, $subject ) = @_;

    $messageid = '' if ( !defined( $messageid ) );
    $date      = '' if ( !defined( $date      ) );
    $subject   = '' if ( !defined( $subject   ) );

    return md5_hex( "[$messageid][$date][$subject]" );
}

#----------------------------------------------------------------------------
#
# get_slot_from_hash
#
# Given a hash value (returned by get_message_hash), find any
# corresponding message in the database and return its slot
# id.   If the message does not exist then return the empty
# string.
#
# hash                 The hash value
#
#----------------------------------------------------------------------------
sub get_slot_from_hash
{
    my ( $self, $hash ) = @_;

    $hash = $self->db__()->quote( $hash );
    my $result = $self->db__()->selectrow_arrayref(
        "select id from history where hash = $hash limit 1;" );

    return defined( $result )?$result->[0]:'';
}

#----------------------------------------------------------------------------
#
# QUERYING THE HISTORY
#
# 1. Start a query session by calling start_query and obtain a unique
#    ID
#
# 2. Set the query parameter (i.e. sort, search and filter) with a call
#    to set_query
#
# 3. Obtain the number of history rows returned by calling get_query_size
#
# 4. Get segments of the history returned by calling get_query_rows with
#    the start and end rows needed
#
# 5. When finished with the query call stop_query
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
#
# start_query
#
# Used to start a query session, returns a unique ID for this
# query.  When the caller is done with the query they return
# stop_query.
#
#----------------------------------------------------------------------------
sub start_query
{
    my ( $self ) = @_;

    # Think of a large random number, make sure that it hasn't
    # been used and then return it

    while (1) {
        my $id = sprintf( '%8.8x', int(rand(4294967295)) );

        if ( !defined( $self->{queries__}{$id} ) ) {
            $self->{queries__}{$id}{query} = 0;
            $self->{queries__}{$id}{count} = 0;
            $self->{queries__}{$id}{cache} = ();
            return $id
        }
    }
}

#----------------------------------------------------------------------------
#
# stop_query
#
# Used to clean up after a query session
#
# id                The ID returned by start_query
#
#----------------------------------------------------------------------------
sub stop_query
{
    my ( $self, $id ) = @_;

    # If the cache size hasn't grown to the row
    # count then we didn't fetch everything and so
    # we fill call finish to clean up

    my $q = $self->{queries__}{$id}{query};

    if ( ( defined $q ) && ( $q != 0 ) ) {
        if ( $#{$self->{queries__}{$id}{cache}} !=
             $self->{queries__}{$id}{count} ) {
           $q->finish;
        }
    }

    delete $self->{queries__}{$id};
}

#----------------------------------------------------------------------------
#
# set_query
#
# Called to set up a query with sort, filter and search options
#
# id            The ID returned by start_query
# filter        Name of bucket to filter on
# search        From/Subject line to search for
# sort          The field to sort on (from, subject, to, cc, bucket, date)
#               (optional leading - for descending sort)
#
#----------------------------------------------------------------------------
sub set_query
{
    my ( $self, $id, $filter, $search, $sort ) = @_;

    # If this query has already been done and is in the cache
    # then do no work here

    if ( defined( $self->{queries__}{$id}{fields} ) &&
         ( $self->{queries__}{$id}{fields} eq "$filter:$search:$sort" ) ) {
        return;
    }

    $self->{queries__}{$id}{fields} = "$filter:$search:$sort";

    # We do two queries, the first to get the total number of rows that
    # would be returned and then we start the real query.  This is done
    # so that we know the size of the resulting data without having
    # to retrieve it all

    my $select = 'select COUNT(*) from history, buckets where history.userid = 1
                                                          and committed = 1';

    # If there's a search portion then add the appropriate clause
    # to find the from/subject header

    if ( $search ne '' ) {
        $search = $self->db__()->quote( '%' . $search . '%' );
        $select .= " and ( hdr_from like $search or
                           hdr_to   like $search )";
    }

    # If there's a filter option then we'll need to get the bucket
    # id for the filtered bucket and add the appropriate clause

    if ( $filter ne '' ) {
        my $session = $self->{classifier__}->get_session_key( 'admin', '' );
        my $bucketid = $self->{classifier__}->get_bucket_id(
                           $session, $filter );
        $self->{classifier__}->release_session_key( $session );
        $select .= " and bucketid = $bucketid";
    }

    $select .= ' and bucketid = buckets.id';

    # Add the sort option (if there is one)

    if ( $sort ne '' ) {
        $sort =~ s/^(\-)//;
        my $direction = defined($1)?'desc':'asc';
        if ( $sort eq 'bucket' ) {
            $sort = 'buckets.name';
        } else {
            if ( $sort ne 'inserted' ) {
                $sort = "hdr_$sort";
            }
        }
        $select .= " order by $sort $direction;";
    } else {
        $select .= ' order by inserted desc;';
    }

    $self->{queries__}{$id}{count} =
        $self->db__()->selectrow_arrayref( $select )->[0];

    $select =~ s/COUNT\(\*\)/$slot_fields/;
    $self->{queries__}{$id}{query} = $self->db__()->prepare( $select );
    $self->{queries__}{$id}{query}->execute;
    $self->{queries__}{$id}{cache} = ();
}

#----------------------------------------------------------------------------
#
# get_query_size
#
# Called to return the number of elements in the query.
# Should only be called after a call to set_query.
#
# id            The ID returned by start_query
#
#----------------------------------------------------------------------------
sub get_query_size
{
    my ( $self, $id ) = @_;

    return $self->{queries__}{$id}{count};
}

#----------------------------------------------------------------------------
#
# get_query_rows
#
# Returns the rows in the range [$start, $end) from a query that has
# already been set up with a call to set_query.  The first row is row 1.
#
# id            The ID returned by start_query
# start         The first row to return
# count         Number of rows to return
#
# Each row contains the fields:
#
#    id (0), from (1), to (2), cc (3), subject (4), date (5), hash (6),
#    inserted date (7), bucket name (8), reclassified id (9)
#----------------------------------------------------------------------------
sub get_query_rows
{
    my ( $self, $id, $start, $count ) = @_;

    # First see if we have already retrieved these rows from the query
    # if we have then we can just return them from the cache.  Otherwise
    # fetch the rows from the database and then return them

    my $size = $#{$self->{queries__}{$id}{cache}}+1;

    $self->log_( 2, "Request for rows $start ($count), current size $size" );

    if ( ( $size < ( $start + $count - 1 ) ) ) {
        my $rows = $start + $count - $size;
        $self->log_( 2, "Getting $rows rows from database" );
        push ( @{$self->{queries__}{$id}{cache}},
            @{$self->{queries__}{$id}{query}->fetchall_arrayref(
                undef, $start + $count - $size )} );
    }

    my ( $from, $to ) = ( $start-1, $start+$count-2 );

    $self->log_( 2, "Returning $from..$to" );

    return @{$self->{queries__}{$id}{cache}}[$from..$to];
}

# ---------------------------------------------------------------------------
#
# make_directory__
#
# Wrapper for mkdir that ensures that the path we are making doesn't end in
# / or \ (Done because your can't do mkdir 'foo/' on NextStep.
#
# $path        The directory to make
#
# Returns whatever mkdir returns
#
# ---------------------------------------------------------------------------
sub make_directory__
{
    my ( $self, $path ) = @_;

    $path =~ s/[\\\/]$//;

    return 1 if ( -d $path );
    return mkdir( $path );
}

# ---------------------------------------------------------------------------
#
# compare_mf__
#
# Compares two mailfiles, used for sorting mail into order
#
# ---------------------------------------------------------------------------
sub compare_mf__
{
    $a =~ /popfile(\d+)=(\d+)\.msg/;
    my ( $ad, $am ) = ( $1, $2 );

    $b =~ /popfile(\d+)=(\d+)\.msg/;
    my ( $bd, $bm ) = ( $1, $2 );

    if ( $ad == $bd ) {
        return ( $bm <=> $am );
    } else {
        return ( $bd <=> $ad );
    }
}

# ---------------------------------------------------------------------------
#
# upgrade_history_files__
#
# Looks for old .MSG/.CLS history entries and sticks them in the database
#
# ---------------------------------------------------------------------------
sub upgrade_history_files__
{
    my ( $self ) = @_;

    # See if there are any .MSG files in the msgdir, and if there are 
    # upgrade them by placing them in the database

    my @msgs = sort compare_mf__ glob $self->get_user_path_( 
        $self->global_config_( 'msgdir' ) . 'popfile*.msg' );

    if ( $#msgs != -1 ) {
        print "\nFound old history files, moving them into database\n    ";

        my $i = 0;
        $self->db__()->begin_work;
        foreach my $msg (@msgs) {
            if ( ( ++$i % 100 ) == 0 ) {
                print "[$i]";
                flush STDOUT;
            }

            # NOTE.  We drop the information in $usedtobe, so that
            # reclassified messages will no longer appear reclassified
            # in upgraded history.

            my ( $reclassified, $bucket, $usedtobe, $magnet ) =
                $self->history_read_class__( $msg );

            if ( $bucket ne 'unknown_class' ) {
                my ( $slot, $file ) = $self->reserve_slot();
                rename $msg, $file;
                $self->commit_slot( $slot, $bucket, $magnet );
            }
        }
        $self->db__()->commit;

        print "\nDone upgrading history\n";
    }
}

# ---------------------------------------------------------------------------
#
# history_read_class__ - load and delete the class file for a message.
#
# returns: ( reclassified, bucket, usedtobe, magnet )
#   values:
#       reclassified:   boolean, true if message has been reclassified
#       bucket:         string, the bucket the message is in presently, 
#                       unknown class if an error occurs
#       usedtobe:       string, the bucket the message used to be in 
#                       (null if not reclassified)
#       magnet:         string, the magnet
#
# $filename     The name of the message to load the class for
#
# ---------------------------------------------------------------------------
sub history_read_class__
{
    my ( $self, $filename ) = @_;

    $filename =~ s/msg$/cls/;

    my $reclassified = 0;
    my $bucket = 'unknown class';
    my $usedtobe;
    my $magnet = '';

    if ( open CLASS, "<$filename" ) {
        $bucket = <CLASS>;
        if ( defined( $bucket ) && ( $bucket =~ /([^ ]+) MAGNET ([^\r\n]+)/ ) ) {
            $bucket = $1;
            $magnet = $2;
        }

        $reclassified = 0;
        if ( defined( $bucket ) && ( $bucket =~ /RECLASSIFIED/ ) ) {
            $bucket       = <CLASS>;
            $usedtobe = <CLASS>;
            $reclassified = 1;
            $usedtobe =~ s/[\r\n]//g;
        }
        close CLASS;
        $bucket =~ s/[\r\n]//g if defined( $bucket );
        unlink $filename;
    } else {
        return ( undef, $bucket, undef, undef );
    }

    $bucket = 'unknown class' if ( !defined( $bucket ) );

    return ( $reclassified, $bucket, $usedtobe, $magnet );
}

#----------------------------------------------------------------------------
#
# cleanup_history__
#
# Removes the popfile*.msg files that are older than a number of days
# configured as history_days.
#
#----------------------------------------------------------------------------
sub cleanup_history__
{
    my ( $self ) = @_;

    my $seconds_per_day = 24 * 60 * 60;
    my $old = time - $self->config_( 'history_days' ) * $seconds_per_day;
    $self->db__()->begin_work;
    my $d = $self->db__()->prepare( "select id from history
                                         where inserted < $old;" );
    $d->execute;
    my @row;
    while ( @row = $d->fetchrow_array ) {
        $self->delete_slot( $row[0], 1 );
    }
    $self->db__()->commit;
}

# ---------------------------------------------------------------------------
#
# copy_file__
#
# Utility to copy a file and ensure that the path it is going to
# exists
#
# $from               Where to copy from
# $to_dir             The directory it will be copied to
# $to_name            The name of the destination (without the directory)
#
# ---------------------------------------------------------------------------
sub copy_file__
{
    my ( $self, $from, $to_dir, $to_name ) = @_;

    if ( open( FROM, "<$from") ) {
        if ( open( TO, ">$to_dir\/$to_name") ) {
            binmode FROM;
            binmode TO;
            while (<FROM>) {
                print TO $_;
            }
            close TO;
        }

        close FROM;
    }
}

# ---------------------------------------------------------------------------
#
# force_requery__
#
# Called when the database has changed to invalidate any queries that are
# open so that cached data is not returned and the database is requeried
#
# ---------------------------------------------------------------------------
sub force_requery__
{
    my ( $self ) = @_;
    # Force requery since the messages have changed

    foreach my $id (keys %{$self->{queries__}}) {
        $self->{queries__}{$id}{fields} = '';
    }
}

# SETTER

sub classifier
{
    my ( $self, $classifier ) = @_;

    $self->{classifier__} = $classifier;
}


1;
