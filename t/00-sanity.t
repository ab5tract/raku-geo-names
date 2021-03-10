use Geo::Names;
use Test;

plan 1;

my $db;
lives-ok {
    say  $*CWD ~ '/t/data/sample.sqlite';
    $db = Geo::Names.new: db-path => $*CWD ~ '/t/data/sample.sqlite';
}, "Geo::Names instantiates as an object";

done-testing;
