#!/usr/bin/perl -w

# A Capiluppi 2019

$repo_name = $ARGV[0] || die "Usage: perl ./prova_OO_METRICS.pl <name_of_project>";
chomp $repo_name;
$i = $repo_name;

chomp $i;
print "Doing $i now\n";
`und create -db $i/$i.udb -languages Java`;
`find ./$i -name \"*.java\" > $i/all_source_files.txt`;
`und -db $i/$i.udb add \@$i/all_source_files.txt`;
`und analyze $i/$i.udb`;
`und import core.xml $i/$i.udb`;
`und metrics $i/$i.udb`;

open OUT, "> $i/$i-CK-ClassMetrics.txt";
print OUT "Kind,ClassName,PATH,IFANIN,CBO,NOC,NIM,NIV,WMC,RFC,DIT,LCOM\n";

@metrics = `cat $i/$i.csv`;
for($i=1; $i<=$#metrics; $i++){

    $line = $metrics[$i];
    chomp $line;
    if (($line =~ /Class|Interface\,/) && ($line !~ /^File\,/)){
        @data = split(/\,/, $line);
        if ($data[1] =~ /\(/){
            @path = split(/\./, $data[1]);
            $data[1] = $path[$#path-2]."_".$path[$#path-1];
        } else {
            @path = split(/\./, $data[1]);
            $data[1] = $path[$#path];
            $data[1] =~ s/\"//;
        }
        $data[2] =~ s/.*\/$i\///;
        $line = join(",",@data);
        print OUT $line."\n";
    }
}
