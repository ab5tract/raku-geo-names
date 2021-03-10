unit class Geo::Names;

#| Backendish provides a quick stub spot for now but can be used later
#| to write backend-independent presentation stuff, such as a Locations::Result
#| class.
role Backendish {
    method query($query, @binds) {...}
    method get-by($field, $value) {...}
}

#| Backend::SQLite is the first option. HTTP against a service is an obvious next choice.
class Backend::SQLite does Backendish {
    use DB::SQLite;

    has %.db-config;
    has $.db;
    has %.cache;
    has Int $.min-pop;

    constant Fields = Set
            .new: <geonames_id name ascii_name alternate_names latitude longitude feature_class feature_code cc1 cc2 admin1 admin2 admin3 admin4 population elevation dem timezone modified>;

    subset DefinedFileLocation of Str where *.IO.e;
    subset ValidField of Str where { $^field (elem) Fields };
    subset PosInt of Int where *> 0;

    #| This is my first module since TWEAK went to 'first choice' as the best
    #| way to configure instance variables on a fully constructed object. Previously,
    #| this would have required a custom .new and a submethod BUILD.
    #|
    #| Submethods just mean that they are not meant to be called outside of the
    #| current class scope in the case of inheritance. In other words, TWEAK is
    #| guaranteed to be called only once per Backend::SQLite object
    #| -- and only per Backend::SQLite objects.
    submethod TWEAK(DefinedFileLocation :$db-path, PosInt :$min-pop = 50_000) {
        %!db-config = db-path => $db-path || ':memory';
        $!db = DB::SQLite.new: filename => %!db-config<db-path>;
        $!min-pop = $min-pop // 50_000;
    }

    method query($query, *@binds) {
        $!db.query($query, |@binds).hashes;
    }

    multi method get-by(ValidField $field, $value, :$all!) {
        self.query("select * from locations where $field = ?", $value);
    }

    #| One of my genuinely favorite features of Raku the Signature implementation
    #| is the ability to assign defaults. All I had to do here to introduce DWIM
    #| semantics around `min-pop` was to assign it as a default value.
    #|
    #| The argument is then defined by default, allowing me to use the PosIht guard
    #| to shore up the fact that I'm performing some dangerous SQL interpolation
    #| here.
    multi method get-by(ValidField $field, $value, PosInt :$min-pop = $!min-pop) {
        self.query("select * from locations where $field = ? and population > $min-pop", $value);
    }
}

my constant SupportedBackends = Set.new: <sqlite>;
my subset SupportedBackend of Str where { $^s (elem) SupportedBackends };

has $.backend handles <get-by query>;

#| Note that using constraints like SupportedBackend generally requires the setting
#| of default values, unless you explicitly design around defined-ness in the subset
#| definition. Doing that would feel too "at a distance" for me.
submethod TWEAK(SupportedBackend :$type = 'sqlite', *%options) {
    given $type {
        when * eq 'sqlite' { $!backend = Backend::SQLite.new: |%options }
    }
}