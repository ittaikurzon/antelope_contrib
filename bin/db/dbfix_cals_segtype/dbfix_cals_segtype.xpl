use Datascope;

if( $#ARGV != 0 ) {
	die( "Usage: dbfix_cals_segtype dbname\n" );
} else {
	$dbname = $ARGV[0];
}

@db = dbopen( $dbname, "r+" );
if( $db[0] < 0 ) {
	die( "dbfix_cals_segtype: failed to open $dbname. Bye.\n" );
}

@db = dblookup( @db, "", "calibration", "", "" );
if( ! dbquery( @db, "dbTABLE_PRESENT" ) ) {
	die( "dbfix_cals_segtype: no calibration table in $dbname. Bye.\n" );
}

# prepare for future loop over multiple tables 
$table = "wfdisc"; 
@db = dblookup( @db, "", "$table", "", "" );
if( ! dbquery( @db, "dbTABLE_PRESENT" ) ) {
	die( "dbfix_cals_segtype: no $table table in $dbname. Bye.\n" );
}
system( "dbjoin $dbname.$table calibration | dbset -v - $table.calib 'calib == NULL' calibration.calib; dbjoin $dbname.$table calibration |  dbset -v - $table.calper 'calper == NULL' calibration.calper ; dbjoin $dbname.$table calibration | dbset -v - $table.segtype 'segtype== NULL' calibration.segtype" );

