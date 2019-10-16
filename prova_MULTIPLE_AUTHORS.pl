#!/usr/bin/perl -w

# A Capiluppi 2019

use DBI;
# database details
my $host = 'localhost';
my $db = 'BD_ALL';
my $db_user = 'XXX';
my $db_password = 'YYY';

$repo_name = $ARGV[0] || die "Usage: perl ./prova_MULTIPLE_AUTHORS.pl <project name>";
chomp $repo_name;

$dbh = DBI->connect("dbi:mysql:$db:$host", "$db_user", "$db_password", {RaiseError => 0, PrintError => 0} );
    
    my $sql0 = qq{select ID from repositories where name = ?};
    my $sth0 = $dbh->prepare($sql0) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth0->execute($repo_name);
    while (@data = $sth0->fetchrow_array()) {
        $proj_ID = $data[0];
    }
    
    $file_out = "Authors/Authors_".$repo_name.".txt";
    open OUT, "> $file_out" or die "Can't open $file_out : $!";
    print OUT "RepoID,FileID,FileName,Authors\n";
    print "Doing repo: $repo_name\n";

    ## UNIQUE ID OF JAVA FILE
    my $sql1 = qq{select distinct file_links.file_id from files, file_links where repository_id = ? and file_links.file_id = files.id and file_name LIKE '%.java'};
    my $sth1 = $dbh->prepare($sql1) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth1->execute($proj_ID);
    
    while (@data = $sth1->fetchrow_array()) {
        $file_ID = $data[0];

        # INITIALIZATIONS ##
        $sum_distinct_committers = 0;
        @distinct_committers = ();
        for (keys %seen)
        {
            delete $seen{$_};
        }
        
        ## LATEST FULL PATH
        my $sql2 = qq{select file_path from file_links where file_links.file_id = ? order by commit_id desc limit 1;};
        my $sth2 = $dbh->prepare($sql2) or die "Couldn't prepare statement: " . $dbh->errstr;    
        $sth2->execute($file_ID);
        while (@data_path = $sth2->fetchrow_array()) {
            $full_path = $data_path[0];
        }
        
        ## DISTINCT AUTHORS
        my $sql3 = qq{select distinct(author_id) from scmlog, actions where actions.file_id = ? and actions.commit_id = scmlog.id;};
        my $sth3 = $dbh->prepare($sql3) or die "Couldn't prepare statement: " . $dbh->errstr;    
        $sth3->execute($file_ID);
        
        @reconciled_authors = `cat names_reconciliation/authors_reconciled-$proj_ID.txt`;
        while (@dataC = $sth3->fetchrow_array()) {
#                 print "$file_name\tCommitter ".$dataC[0].",";
                @found_reconciled = grep /\,$dataC[0]\,/, @reconciled_authors;
                if (@found_reconciled > 0){
                    $dataC[0] = $found_reconciled[0];
                    $dataC[0] =~ s/,*\,//;
                    push(@distinct_committers, $dataC[0]);
                } else {
                    push(@distinct_committers, $dataC[0]);
                }
        }
        
        @distinct_committers = grep { ! $seen{ $_ }++ } @distinct_committers;
        my $arrSize = @distinct_committers;
        $sum_distinct_committers += $arrSize;
        $full_path =~ s/^$repo_name\///;
        print OUT ("$repo_name,$file_ID,$full_path,$sum_distinct_committers\n");
    }
