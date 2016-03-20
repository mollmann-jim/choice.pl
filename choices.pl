eval 'exec /usr/bin/perl -w -S $0 $*'
  if 0;
use Data::Dumper;
sub choose;
sub incfile;
sub testit;
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

$debug = 0;
$dumpvars = 0;
srand( time() ^ ($$ + ($$ << 15)) );
$file="data";
$file=$ARGV[0] if $#ARGV>=0;
$tmpfile="/tmp/choices.$$";
open( TEMP, "> $tmpfile");
incfile($file);
close( TEMP );
open( INPUT, $tmpfile);
$first=<INPUT>;
chomp $first;
$maxgrplen = 0;
$i=0;
while(<INPUT>) {
    ($grp, $odds, $item, $nexts)=split /,/, $_, 4;
    next if !$grp;
    $count{$grp} = 0 if !$count{$grp};
    $maxgrplen = length($grp) if length($grp) > $maxgrplen;
    $item = trim($item);
    for ($j=0; $j<$odds; $j++) {
        $obj{$grp}[$count{$grp}]=$item;
        print "obj:$grp:$i = $item\n" if $debug;
        $count{$grp}++;
        $i++;
    }
    chomp $nexts if $nexts;
    $next{$grp}{$item} = $nexts;
    if ($nexts) {
        print "count:$grp:$item:$count{$grp} nexts:$nexts\n" if $debug;
    } else {
        print "count:$grp:$item:$count{$grp}\n" if $debug;
    }
}
close(INPUT);
testit($first, "");
choose($first);
if ($dumpvars) {
    print "\nobj:\n";
    print Dumper \%obj;
    print "\ncount:\n";
    print Dumper \%count;
    print "\nnext:\n";
    print Dumper \%next;
}
unlink($tmpfile);
exit 0;

sub choose {
    my $group = shift;
    my $pick;
    my $choice;
    my $nexts;
    my $i;
    my $x;

    if (!$count{$group}) {
        print STDERR "Group=$group undefined.\n";
        return;
    }
    $pick = int(rand $count{$group});
    $choice = $obj{$group}[$pick];
    print "grp:$group count:$count{$group} pick:$pick choice:$choice\n" if $debug;
    printf "%-${maxgrplen}s : %s\n", $group, $choice if !($choice =~ m/NONE/);
    $nexts = $next{$group}{$choice};
    return if !$nexts;
    for (($x, $nexts) = split /,/, $nexts, 2; $x;
         ($x, $nexts) = split /,/, $nexts, 2) {
        $x = trim($x);
        print "choose:$x\n" if $debug;
        choose($x);
        return if !$nexts;
    }
}

sub foundin {
    my $needle = shift;
    my @haystack = @_;
    my $i;
    for ($i = 0; $i<=$#haystack; $i++) {
        # print "found:$needle\n" if $haystack[$i] eq $needle;
        return 1 if $haystack[$i] eq $needle;
    }
    return 0;
}

sub testitin {
    my $group = shift;
    my $dbg = shift;
    my $p;
    my $choice;
    my $nexts;
    my $i;
    my $x;
    my $last = "";

    print "testitin: $group\n" if $dbg;
    if (!$count{$group}) {
        print STDERR "Actions for \"$group\" not found\n";
        return;
    }
    for ($i = 0; $i < $count{$group}; $i++) {
        #print "i:$i group:$group choice:$obj{$group}[$i]\n";
        $choice = $obj{$group}[$i];
        next if $last eq $choice;
        $last = $choice;
        print "$i: $choice\n" if $dbg;
        $nexts = $next{$group}{$choice};
        print "*done*\n" if !$nexts && $dbg;
        next if !$nexts;
        for (($x, $nexts) = split /,/, $nexts, 2; $x;
             ($x, $nexts) = split /,/, $nexts, 2) {
            $x = trim($x);
            if (!$done{$x}) {
                if (!foundin($x, @todo)) {
                    print "Add:$x\t" if $dbg;
                    push @todo, $x;
                    my $z = join(" : ", @todo);
                    print "ToDo:$z\n" if $dbg;
                }
            }
            last if !$nexts;
        }
    }
    $done{$group} = 1;
}

sub testit {
    my $x = shift;
    my $z;
    my $dbg = 0;

    @todo = ();
    testitin($x, $dbg);

    while ($x = pop @todo) {
        $z = join(" : ", @todo);
        print "Check:$x ToDo:$z\n" if $dbg;
        testitin($x, $dbg);
    }
}

sub incfile {
    my $filename = shift;
    local *INPUT;
    my $inc;
    my $infilename;

    chomp $filename;
    open( INPUT, $filename);
    while(<INPUT>) {
        ($inc, $incfilename) = split /\s+/, $_, 2;
       if ($inc eq "#include") {
            incfile($incfilename);
        } else {
            print TEMP $_;
        }
    }
    close(INPUT);
}

