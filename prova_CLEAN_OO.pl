#!/usr/bin/perl -w

$in = $ARGV[0] || die "Usage: perl ./prova_CLEAN_OO.pl CK-METRICS/<project_name)-CK-ClassMetrics.txt";
$proj = $in;
$proj =~ s/-CK-ClassMetrics.txt//;
$proj =~ s/CK-Metrics\///;

# STARS

print "Project,filename,IFANIN,CBO,NOC,NIM,NIV,WMC,RFC,DIT,LCOM\n";
@all = `cat $in`;
for($i=1; $i<=$#all; $i++){
        chomp $all[$i];
        @data = split(/\,/, $all[$i]);
        $size = @data;
        
        if(($size == 12)&&($all[$i] !~ /,,,/)){
                    $classname = $data[1];
                    $fn = $data[2];
                    $fn =~ s/.*\/NEWSAMPLE\/$proj\///;
                    $fn =~ s/.*\/ALLPROJ\/$proj\///;
                    $fn =~ s/.*\/NEWSAMPLE-FORKS\/$proj\///;
                    $OO = "$data[3],$data[4],$data[5],$data[6],$data[7],$data[8],$data[9],$data[10],$data[11]";
                    print "$proj,$classname,$fn,$OO\n";
        }
}
