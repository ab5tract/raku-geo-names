#!/usr/bin/env raku

use DB::SQLite;

=begin pod

Note: This script is currently only capable of single threaded execution.

=item cities500.txt: 4-6 minutes
=item allCountries.txt: 14-18 minutes

One quick win would be to do this per country file, per thread. Rapid
ingestion by feeding a Supplier new files to handle and having a Supply
doing more or less the current script code in a guaranteed thread on a
much more reasonable basis.

By only having a single thread inserting/writing to each country file,
we can have many threads ingesting and writing out at a time.
=end pod
sub MAIN(:$db-path  = "./cities500.sqlite", :$csv-path = "./cities500.txt") {
    my @columns = <geonames_id name ascii_name alternate_names latitude longitude feature_class feature_code cc1 cc2 admin1 admin2 admin3 admin4 population elevation dem timezone modified>;
    my @types = <int text text text real real text text text text text text text text int int int text text>;
    my $placeholders = ('?' xx +@columns).join(',');

    my $s = DB::SQLite.new(filename => $db-path);
    $s.execute("create table locations ({ (([Z] @columns, @types>>.uc).join(', ')) })");

    say "Starting at ... " ~ my $now = DateTime.now;
    $csv-path.IO.lines.rotor(5200).map: -> @l {
        my $db = $s.db;
        my $sth = $db.prepare: "insert into locations values ($placeholders)";
        $db.begin;
        sleep 1 + (^10).roll;
        for @l -> $l {
            $sth.execute: $l.split("\t");
        }
        $db.commit.finish;
    };
    $s.finish;
    say "Took ...  { (DateTime.now - $now) / 60 } minutes";
}