
sub title { 
    return &paragraph("Title", $_ ) if $_ !~ /^\s*$/ ; 
}

sub author { 
    my $result ;
    if ($_ !~ /^\s*$/ ) { 
	my @pieces = split( ',', $_ ) ; 
	my $piece = shift(@pieces) ;
	$result = &paragraph("Author", $piece )  ;
	foreach $piece ( @pieces ) { 
	    $result .= &paragraph("Location", $piece )  ;
	}
    }
    return $result ; 
}

sub publisher { 
    return &paragraph("Publisher", $_ ) if $_ !~ /^\s*$/ ; 
}


sub Examples { 
    return &paragraph("Examples", $_ ) if $_ !~ /^\s*$/ ; 
}

sub section { 
    return &paragraph("Heading1", $_ ) if $_ !~ /^\s*$/ ; 
}

sub subsection { 
    return &paragraph("Heading2", $_ ) if $_ !~ /^\s*$/ ; 
}

sub chapter { 
    return &paragraph("Heading1", $_ ) if $_ !~ /^\s*$/ ; 
}

sub body {
    $_ = gobble_to_space($_) ;
    return &paragraph("Body", $_) if $_ !~ /^\s*$/ ;
}

sub options { 
    return &paragraph("Indented", "") if /^\s*$/ ;
    my ($option, $desc ) = split ( "\t", $_, 2) ; 
    if ( $option =~ /(-\w+)\s+(\S+)/ ) { 
	$option = &string("$1 ") 
		  . &fontstring ( "ParameterName", $2 ) ; 
	$Parameters{$1} = 1 ; 
    } else { 
	$option = &string($option) ; 
    }
    $desc = &emphasize(\%Parameters, "ParameterName", "\t$desc") if $desc !~ /^\s*$/ ;
    return &paragraph("Indented", "#\n" . $option . "\t" . $desc ) ;
}

sub option { 
    return options($_) ;
}

sub library { 
    xf_popprocess;
    chomp () ;
    $title = $_ ;
    $library = xf_input() ;
    chomp($library) ;
    $_ = "lib$library : $title" ;
    $chapter = &chapter() ;
    $depends_on = xf_input() ; 
    chomp($depends_on) ;
    $macro = xf_input() ; 
    chomp($macro) ;
    $include = xf_input() ; 
    chomp($include) ;

    $desc = gobble_to_space("") ;

    @data = ($chapter) ;
    push ( @data, &paragraph("Body", $desc) );
    push ( @data, &paragraph("Spacer", "" ) );
    push ( @data, &paragraph("Indented", "include \"$include\"" ) ); 
    # push ( @data, &paragraph("Spacer", "" ) );
    if ( $macro ne "none" ) { 
	push ( @data, &paragraph("Indented", "ldlibs=\$($macro)" )) ;
    } else { 
	push ( @data, &paragraph("Indented", "ldlibs=-l$library $depends_on" ) );
    }
    push ( @data, &paragraph ( "Spacer", "" ) ) ;
    return @data ;
}

1;
