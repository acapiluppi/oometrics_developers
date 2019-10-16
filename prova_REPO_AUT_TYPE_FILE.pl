#!/usr/bin/perl -w

# A Capiluppi 2019

use DBI;

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

my $host = 'localhost';
$db = 'newSamplingForks';
my $db_user = 'root';
my $db_password = 'sophia2003';

$dbh = DBI->connect("dbi:mysql:$db:$host", "$db_user", "$db_password", {RaiseError => 0, PrintError => 0} );
my $sql1 = qq{select scmlog.repository_id, scmlog.date, scmlog.id, scmlog.author_id, actions.file_id, files.file_name from scmlog, actions, files where scmlog.id = actions.commit_id and files.id = actions.file_id and files.file_name like '%.java%' and scmlog.repository_id =? group by actions.file_id, scmlog.id having count(actions.file_id) < 100 order by scmlog.date;};

$sth = $dbh->prepare($sql1) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute($project_id);

while (@data = $sth->fetchrow_array()) {
        $author_id = $data[3];
        chomp $author_id;
        my $sql2 = qq{select TDMDBD.type from TDMDBD where TDMDBD.authorID = ? and TDMDBD.projectID = ?;};
        $sth2 = $dbh->prepare($sql2) or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth2->execute($author_id,$project_id);

        while (@data2 = $sth2->fetchrow_array()) {
                $type = $data2[0];
                chomp $type;
        }

        print "$data[0],$data[3],$type,$data[4]\n";  
}