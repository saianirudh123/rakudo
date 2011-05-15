class Perl6::Metamodel::ClassHOW
    does Perl6::Metamodel::Naming
    does Perl6::Metamodel::Versioning
    does Perl6::Metamodel::AttributeContainer
    does Perl6::Metamodel::MethodContainer
    does Perl6::Metamodel::MultiMethodContainer
    does Perl6::Metamodel::RoleContainer
    does Perl6::Metamodel::MultipleInheritance
    does Perl6::Metamodel::C3MRO
{
    has $!composed;

    method new_type(:$name = '<anon>', :$repr = 'P6opaque', :$ver, :$auth) {
        my $metaclass := self.new(:name($name), :ver($ver), :auth($auth));
        pir::repr_type_object_for__PPS($metaclass, $repr);
    }

    method compose($obj) {
        # XXX Roles

        # Some things we only do if we weren't already composed once, like building
        # the MRO.
        unless $!composed {
            self.compute_mro($obj);
            $!composed := 1;
        }

        # Incorporate any new multi candidates (needs MRO built).
        self.incorporate_multi_candidates($obj);

        # Compose attributes.
        for self.attributes($obj, :local) {
            $_.compose($obj);
        }

        # Publish type and method caches.
        # XXX self.publish_type_cache($obj);
        self.publish_method_cache($obj);

        $obj
    }

    method publish_method_cache($obj) {
        # Walk MRO and add methods to cache, unless another method
        # lower in the class hierarchy "shadowed" it.
        my %cache;
        for self.mro($obj) {
            my %methods := $_.HOW.method_table($_);
            for %methods {
                unless %cache{$_.key} {
                    %cache{$_.key} := $_.value;
                }
            }
        }
        pir::publish_method_cache($obj, %cache)
    }
    
    method is_composed($obj) {
        $!composed
    }
}