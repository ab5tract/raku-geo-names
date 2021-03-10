use Test;

plan 7;

use Geo::Names;

my $db = Geo::Names.new: db-path => $*CWD ~ '/t/data/sample.sqlite', min-pop => 500_000;

my $res;
lives-ok {
    $res = $db.get-by(<ascii_name>, <Bogota>, :all);
}, "Geo::Names object can query using .get-by(field, value)";

my @bogota;
lives-ok {
    @bogota = |$res.grep({ %^l<ascii_name> eq <Bogota> });
}, "Result finds a matching hash";
is +@bogota, 2, "Expected number of results for query based on input data";

my $real-bogota;
lives-ok {
    my $res = $db.get-by(<geonames_id>, 3688689);
    die unless +$res == 1;
    $real-bogota = $res.first;
    die unless $real-bogota<ascii_name> eq 'Bogota';
    # only one result from $db because it has a custom min-pop set to 500_000
    die unless $db.get-by(<geonames_id>, 3688689) ~~ $db.get-by(<ascii_name>, <Bogota>)
}, "Can get-by with id";

my (@more-boulder, @boulder);
lives-ok {
    @boulder        = |$db.get-by(<ascii_name>, <Boulder>, :min-pop(50_000));
    @more-boulder   = |$db.get-by(<ascii_name>, <Boulder>, :min-pop(1));
}, "Can get-by with custom min-pop";

is      +@more-boulder, 4,          "Number of esults for Boulder where min-pop > 1 is 4";
isnt    +@more-boulder, +@boulder,  "Result counts differ when min-pop differs for the same choice";

done-testing;
