#include <stdlib.h>
#include "db.h"
#include "stock.h"
#include "dbmon.h"
#include "db2sql.h"

void newrow( Dbptr db, char *table, long irecord, char *sync, void *private );
void delrow( Dbptr db, char *table, char *sync, void *private );

void
newrow( Dbptr db, char *table, long irecord, char *sync, void *private )
{ 
	char	row[10*STRSZ];
	FILE	*fp = (FILE *) private;

	dbget( db, row );
	
	fprintf( fp, "New Row %ld in '%s' [sync '%s']: %s\n", irecord, table, sync, row );

	return;
}

void
delrow( Dbptr db, char *table, char *sync, void *private )
{ 
	FILE	*fp = (FILE *) private;

	fprintf( fp, "Deleted row from '%s' with sync '%s'\n", table, sync );

	return;
}

int
main(int argc, char **argv )
{
	Dbptr	db;
	char	dbname[FILENAME_MAX];
	char	command[STRSZ];
	Hook	*dbmon_hook = NULL;
	Tbl	*tables = (Tbl *) NULL; 

	if( argc != 2 ) {

		elog_die( 0, "Usage: %s dbname\n", argv[0] );

	} else {
		
		strcpy( dbname, argv[1] );
	}

	dbopen_database( dbname, "r", &db );

	dbmon_hook = dbmon_init( db, tables, newrow, delrow, 0 );

	dbmon_update( dbmon_hook, (void *) stdout );

	fprintf( stdout, "Adding new arrival table:\n" );

	sprintf( command, "cp data/mod.new.demo.arrival results/dbmon/demo.arrival" );
	system( command );

	sleep( 1 );

	dbmon_update( dbmon_hook, (void *) stdout );

	fprintf( stdout, "Shortening arrival table:\n" );

	sprintf( command, "cp data/mod.shorter.demo.arrival results/dbmon/demo.arrival" );
	system( command );

	sleep( 1 );

	dbmon_update( dbmon_hook, (void *) stdout );

	fprintf( stdout, "Lengthening arrival table:\n" );

	sprintf( command, "cp data/mod.longer.demo.arrival results/dbmon/demo.arrival" );
	system( command );

	sleep( 1 );

	dbmon_update( dbmon_hook, (void *) stdout );

	fprintf( stdout, "Chimney-collapsing arrival table:\n" );

	sprintf( command, "cp data/mod.chimney.demo.arrival results/dbmon/demo.arrival" );
	system( command );

	sleep( 1 );

	dbmon_update( dbmon_hook, (void *) stdout );

	dbmon_status( stdout, dbmon_hook );

	clear_register( 1 );

	free_hook( &dbmon_hook );

	dbclose( db );

	exit( 0 );
}
