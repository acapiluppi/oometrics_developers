#!/usr/bin/perl -w

# A Capiluppi 2019

use DBI;
use Text::Unidecode;
use Encode qw( decode_utf8 );
use File::Path qw(make_path);
use utf8::all;

$project_name = $ARGV[0] || die "Usage: perl ./prova_AUTHOR_RECONCILIATION.pl <project_name>";

my $host = 'localhost';
my $db = 'BD_ALL';
my $db_user = 'XXX';
my $db_password = 'YYY';

my %count = ();

$dir = "names_reconciliation";
eval { make_path($dir) };
if ($@) {
        print "Couldn't create $dir: $@";
}

# DB querying for author metadata from CVSAnalY database
my $dbh = DBI->connect("dbi:mysql:$db:$host", "$db_user", "$db_password", {RaiseError => 0, PrintError => 0, mysql_enable_utf8 => 1} );
$dbh->do(qq{SET NAMES 'utf8';}); #special characters, Latin, Chinese etc

my $sql0 = qq{select ID from repositories where name = ?};
$sth = $dbh->prepare($sql0) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute($project_name);
while (@data = $sth->fetchrow_array()) {
        $p = $data[0];
#         print "$project_name\t$p\n";
        chomp $p;
        open (OUT, "> names_reconciliation/authors-$p.txt");
        print "doing project $project_name ($p)\n";
}

my $sql1 = qq{select repositories.name, people.name, people.id as devosp from people, scmlog, repositories where repository_id = ? and scmlog.repository_id = repositories.id and people.id = scmlog.author_id group by people.id order by people.name;};

$sth = $dbh->prepare($sql1) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute($p);

while (@data = $sth->fetchrow_array()) {
    $data[1] = unidecode( $data[1] );

#     several <authorA "and,&,+" authorB> to treat
    if ($data[1]=~/( and | \& | \+ |\()/){
            $data[1] =~ s/.* (and|\&|\+) //;
            $data[1] =~ s/.* \& //;
            $data[1] =~ s/\s?\(.*//;
    }
    
    $data[1] = lc($data[1]);
    print OUT "$data[0],$data[1],$data[2]\n";
}

@all_names = ();
@all = `cat names_reconciliation/authors-$p.txt`;
foreach $n(@all){
        chomp $n;
        @tokens = split(/\,/,$n);
        if ($tokens[1] =~ / /){
                $name_full = $tokens[1];
                push(@all_names, $name_full);
        }
}

# LOOKUP PATTERN: <Name Surname>
# Getting rid of duplicates
open (OUT1, "> names_reconciliation/authors_reconciled-$p.txt");
@all_names = grep { ++$count{$_} < 2 } @all_names;

foreach $an(@all_names){
        @found_names = grep /\Q,$an,\E/, @all;
        $base_ID = $found_names[0];
#         print "$an => $base_ID\n";
        $base_ID =~ s/.*\,//;
        
        foreach $fn(@found_names){
                $dev = "";
                @results_vector = split (/\,/,$fn);
                $old_id = $results_vector[$#results_vector];
#                 $project = $results_vector[0];
                for($m=1; $m<$#results_vector; $m++){
                    $dev = $dev.$results_vector[$m]."_";
                }
                $dev =~ s/\_$//;
                $dev =~ s/^\_\s//;
                $dev =~ s/\_\s/_/;
                $fn = join(",",$p,$dev,$old_id,$base_ID);
                print OUT1 "$fn\n";
        }
}

# PATTERN: <moniker>
# Attempting to match <moniker> to any <Name Surname>

# create an array of all monikers, per project
my %seen;
@all_monikers = ();
foreach $n(@all){
        chomp $n;
        @tokens = split(/\,/,$n);
        if ($tokens[1] !~ / /){
                $moniker = $tokens[1];
                $moniker = lc($moniker);
#                 print "$p: moniker: $moniker\,$tokens[2]\n";
                push(@all_monikers,  "$moniker\,$tokens[2]");
                push(@monik_dupes,  $moniker);
        }
}
@monik_dupes = grep { ! $seen{ $_ }++ } @monik_dupes;

#get rid of same monikers with multiple IDs
foreach $m(@monik_dupes){
        chomp $m;
        @found_same_moniker = grep/\Q$m\E\,/, @all_monikers;
        chomp $found_same_moniker[0];
        ($base_moniker, $base_ID) = split(/\,/, $found_same_moniker[0]);        

        $size = @found_same_moniker;
        if ($size > 1){
                for($j=0; $j<$size; $j++){
                            print OUT1 "$p,$found_same_moniker[$j],$base_ID\n";
                }
#                 break;
        } else {
                print OUT1 "$p,$base_moniker,$base_ID,$base_ID\n";
        }
}

# browse all <Surname> field in the <Name Surname> and try a match with <moniker>
foreach $an(@all_names){
        $surname = $an;
        $surname =~ s/.*\s//;
        
        $base_ID = $an;
        $base_ID =~ s/.*\,//;
        
        if(length($surname) >1){
                @found_moniker_match = grep/\Q$surname\E/, @all_monikers;
                if(($#found_moniker_match > -1) && (length($found_moniker_match[0])>2)){
                    @base_dev_meta = grep /\Q$an/, @all;
                    $base_ID = $base_dev_meta[0];
                    $base_ID =~ s/.*\,//;
                    $fn = join(",",$p,$found_moniker_match[0],$base_ID);
                    print OUT1 "$fn\n";
                }
        }
}
