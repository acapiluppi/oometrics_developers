#!/usr/bin/perl -w

# A Capiluppi 2019

use POSIX;
use DBI;
use Statistics::Descriptive;
use List::Util qw( min max );

# database details
my $host = 'localhost';
my $db = 'BD_ALL';
my $db_user = 'XXX';
my $db_password = 'YYY';

$repo_name = $ARGV[0] || die "Usage: perl ./prova_TD_MD_BD.pl <project name>";
chomp $repo_name;

$dbh = DBI->connect("dbi:mysql:$db:$host", "$db_user", "$db_password", {RaiseError => 0, PrintError => 0} );
    
my $sql0 = qq{select ID from repositories where name = ?};
my $sth0 = $dbh->prepare($sql0) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth0->execute($repo_name);
while (@data = $sth0->fetchrow_array()) {
    $project_id = $data[0];
}

my %seen = ();

$dbh = DBI->connect("dbi:mysql:$db:$host", "$db_user", "$db_password", {RaiseError => 0, PrintError => 0} );
my $sql1 = qq{select scmlog.author_id, count(actions.file_id) from scmlog, actions, files where scmlog.id = actions.commit_id and files.id = actions.file_id and files.file_name like '%.java%' and scmlog.repository_id = ? group by scmlog.author_id, scmlog.id having count(actions.file_id) < 100 ;};
$sth = $dbh->prepare($sql1) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute($project_id);
while (@data = $sth->fetchrow_array()) {
        push(@authors, $data[0]);
        push(@author_touches_all, "$data[0]\t$data[1]");
}

@authors = grep { ! $seen{ $_ }++ } @authors;
foreach $a(@authors){
        chomp $a;
        $tot = 0;
        @found = grep /^$a\t/, @author_touches_all;
        foreach $f(@found){
                chomp $f;
                $f =~ s/.*\t//;
                $tot += $f;
        }
        push(@touches, $tot);
        push(@author_touches, "$a\t$tot");
#         print "$a\t$tot\n";
}

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@touches);
$q1 = $stat->quantile(1);
$q3 = $stat->quantile(3);
$min = min @touches;
$max = max @touches;
chomp $min; chomp $max;

if($#author_touches == 0){
            $author_touches[0] =~ s/\t/,/;
            print "$project_id,$author_touches[0],TD\n";
}

else {
            foreach $at(@author_touches){
                    chomp $at;
                    ($author, $sumfiles) = split(/\t/, $at);

                    if ($min <= $sumfiles && $sumfiles <= $q1){
                            print "$project_id,$author,$sumfiles,BD\n";
                    } elsif ($q1 < $sumfiles && $sumfiles <= $q3){
                            print "$project_id,$author,$sumfiles,MD\n";
                    } else {
                            print "$project_id,$author,$sumfiles,TD\n";
                    }
            }
}