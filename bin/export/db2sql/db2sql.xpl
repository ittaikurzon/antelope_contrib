
#
#   Copyright (c) 2009-2010 Lindquist Consulting, Inc.
#   All rights reserved. 
#                                                                     
#   Written by Dr. Kent Lindquist, Lindquist Consulting, Inc. 
#
#   This software is licensed under the New BSD license: 
#
#   Redistribution and use in source and binary forms,
#   with or without modification, are permitted provided
#   that the following conditions are met:
#   
#   * Redistributions of source code must retain the above
#   copyright notice, this list of conditions and the
#   following disclaimer.
#   
#   * Redistributions in binary form must reproduce the
#   above copyright notice, this list of conditions and
#   the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#   
#   * Neither the name of Lindquist Consulting, Inc. nor
#   the names of its contributors may be used to endorse
#   or promote products derived from this software without
#   specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
#   CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
#   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
#   PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
#   THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
#   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
#   USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
#   IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
#   USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#

require "getopts.pl";

use strict;

use DBI;
use Datascope;
use Datascope::db2sql;
use Datascope::dbmon;

our( $opt_1, $opt_l, $opt_n, $opt_p, $opt_r, $opt_v, $opt_V );

our( $datascope_dbname, $sql_dbname );
our( $refresh_interval_sec, $schema_create_errors_nonfatal, $enable_mysql_auto_reconnect, @table_subset );
our( $dbh, $hookname );

sub inform {
	my( $msg ) = @_;

	if( $opt_v || $opt_V ) {

		elog_notify( $msg );
	}
}

sub Inform {
	my( $msg ) = @_;

	if( $opt_V ) {

		elog_notify( $msg );
	}
}

sub sqldb_is_present {
	my( $dbh, $sqldbname ) = @_;

	my @dbnames = map { @$_ } @{$dbh->selectall_arrayref( "SHOW DATABASES" )};

	if( grep( /^$sqldbname$/, @dbnames ) ) {
		
		return 1;

	} else {

		return 0;
	}

}

sub init_sql_database {
	my( $dbh, $sqldbname, $rebuild, @db ) = @_;

	if( sqldb_is_present( $dbh, $sqldbname ) ) {

		if( ! $rebuild ) {

			my( $cmd ) = "USE $sqldbname;";

			Inform( "Executing SQL Command:\n$cmd\n\n" );

			unless( $dbh->do( $cmd ) ) {

				elog_die( "Failed to switch to database '$sqldbname'. Bye.\n" );
			}

			return;

		} else {

			inform( "Database '$sqldbname' already exists. Dropping '$sqldbname'\n" );

			my( $cmd ) = "DROP DATABASE $sqldbname;";

			Inform( "Executing SQL Command:\n$cmd\n\n" );

			unless( $dbh->do( $cmd ) ) {

				elog_die( "Failed to drop pre-existing database '$sqldbname'. Bye.\n" );
			}
		}
	}

	my( $cmd ) = "CREATE DATABASE $sqldbname;";

	Inform( "Executing SQL Command:\n$cmd\n\n" );

	unless( $dbh->do( $cmd ) ) {

		elog_die( "Failed to create database '$sqldbname'. Bye.\n" );
	}

	$cmd = "USE $sqldbname;";

	Inform( "Executing SQL Command:\n$cmd\n\n" );

	unless( $dbh->do( $cmd ) ) {

		elog_die( "Failed to switch to database '$sqldbname'. Bye.\n" );
	}

	foreach $cmd ( sql_create_commands( @db, @table_subset ) ) {

		Inform( "Executing SQL Command:\n$cmd\n\n" );

		unless( $dbh->do( $cmd ) ) {

			if( $schema_create_errors_nonfatal ) {

				elog_complain( "Table creation failed for '$sqldbname' using command\n\n$cmd\n\nContinuing.\n\n" );

			} else {

				elog_die( "Table creation failed for '$sqldbname' using command\n\n$cmd\n\nBye.\n\n" );
			}
		}
	}

	return;
}

sub sql_create_commands {
	my( @db ) = splice( @_, 0, 4 );
	my( @table_subset ) = @_;

	my( @cmds, $table );

	if( @table_subset > 0 ) {

		while( $table = shift( @table_subset ) ) {
			
			@db = dblookup( @db, "", $table, "", "" );

			push( @cmds, dbschema2sqlcreate( @db ) );
		}

	} else {

		@cmds = dbschema2sqlcreate( @db );
	}
	
	return @cmds;
}

sub sql_insert_commands {
	my( @db ) = splice( @_, 0, 4 );
	my( @table_subset ) = @_;

	my( @cmds, $table );

	if( @table_subset > 0 ) {

		while( $table = shift( @table_subset ) ) {
			
			@db = dblookup( @db, "", $table, "", "" );

			push( @cmds, db2sqlinsert( @db, \&dbmon_compute_row_sync ) );
		}

	} else {

		@cmds = db2sqlinsert( @db, \&dbmon_compute_row_sync );
	}
	
	return @cmds;
}

sub newrow {
	my( @db ) = splice( @_, 0, 4 );
	my( $table, $irecord, $sync, $dbh ) = @_;

	my( $cmd ) = db2sqlinsert( @db, \&dbmon_compute_row_sync );

	Inform( "Executing SQL Command:\n$cmd\n\n" );

	unless( $dbh->do( $cmd ) ) {
		
		elog_complain( "Failed to create new database row in table '$table'\n" .
			       "record $irecord, sync '$sync'\n" .
			       "while executing command '$cmd'\n" );
	}

	return;
}

sub delrow {
	my( @db ) = splice( @_, 0, 4 );
	my( $table, $sync, $dbh ) = @_;

	my( $cmd ) = db2sqldelete( @db, $sync );

	Inform( "Executing SQL Command:\n$cmd\n\n" );

	unless( $dbh->do( $cmd ) ) {

		elog_complain( "Failed to delete database row in table '$table', sync '$sync'\n" .
			       "while executing command '$cmd'\n" );
	}

	return;
}

my( $path, $Program_name ) = parsepath( $0 );

elog_init( $Program_name, @ARGV );

our( $Pf ) = "db2sql";

our( $Usage ) = "Usage: db2sql [-lrvV] [-p pfname] datascope_dbname[.table] [sql_dbname]\n";

if( ! Getopts( '1lp:rvV' ) ) { 

	elog_die( $Usage );
} 

if( $opt_l ) {

	if( @ARGV != 1 ) {

		elog_die( $Usage );

	} else {

		$datascope_dbname = pop( @ARGV );
	}

} else {

	if( @ARGV != 2 ) {

		elog_die( $Usage );

	} else {

		$sql_dbname = pop( @ARGV );
		$datascope_dbname = pop( @ARGV );
	}
}

if( $opt_p ) {

	$Pf = $opt_p;
}

our( @db ) = dbopen_database( $datascope_dbname, "r" );

if( $db[0] < 0 ) {

	elog_die( "Failed to open database '$datascope_dbname' for reading. Bye.\n" );
}

if( $db[1] >= 0 ) {

	push( @table_subset, dbquery( @db, dbTABLE_NAME ) );

} else {
	
	@table_subset = @{pfget( $Pf, "table_subset" )};
}

if( $opt_l ) {

	print join( "\n", sql_create_commands( @db, @table_subset ) );

	print join( "\n", sql_insert_commands( @db, @table_subset ) );

	exit( 0 );
}

inform( "Importing '$datascope_dbname' into '$sql_dbname' starting at " . strtime(now()) . " UTC\n" );

pfconfig_asknoecho();

$refresh_interval_sec = pfget( $Pf, "refresh_interval_sec" );
$schema_create_errors_nonfatal = pfget_boolean( $Pf, "schema_create_errors_nonfatal" );
$enable_mysql_auto_reconnect = pfget_boolean( $Pf, "enable_mysql_auto_reconnect" );

my( $dsn ) = pfget( $Pf, "dsn" );
my( $user ) = pfget( $Pf, "user" );

my( $pw ) = pfget( $Pf, "password" );

unless( $dbh = DBI->connect( $dsn, $user, $pw ) ) {

	elog_die( "Failed to connect to '$dsn' as user '$user'. Bye.\n" );
}

undef( $pw );

if( $enable_mysql_auto_reconnect ) {

	Inform( "Enabling 'mysql_auto_reconnect'\n" );

	$dbh->{mysql_auto_reconnect} = 1;
}

init_sql_database( $dbh, $sql_dbname, $opt_r, @db );

$hookname = "dbmon_hook";

dbmon_init( @db, $hookname, \&newrow, \&delrow, @table_subset );

dbmon_update( $hookname, $dbh );

inform( "Imported first snapshot of '$datascope_dbname' into '$sql_dbname' at " . strtime(now()) . " UTC\n" );

while( ! $opt_1 ) {

	sleep( $refresh_interval_sec );

	dbmon_update( $hookname, $dbh );

	Inform( "Updated snapshot of '$datascope_dbname' into '$sql_dbname' at " . strtime(now()) . " UTC\n" );
}

$dbh->disconnect();

dbmon_close( $hookname );

inform( "Done importing '$datascope_dbname' into '$sql_dbname' at " . strtime(now()) . " UTC\n" );

exit( 0 );
