package Throwable::Subs;

our $VERSION = '0.01';

use strict qw(vars subs);
use warnings;
BEGIN { require Moo };

use parent qw(Exporter::Tiny);


my %seen;

sub _underscores2camel_case {
    my $name = shift;
    my @parts = split (/_/, $name);
    s/^(.)/uc $1/e for @parts;
    join('', @parts);
}

sub _exporter_expand_sub {
    my ($class, $name, @more) = @_;
    my $code = $seen{$class}{$name};
    unless ($code) {
        if ($name =~ /^throw_(.+)_exception$/) {
            my $exception_class = $class . '::' . _underscores2camel_case($1);
            eval <<EOP;
unless (\@${exception_class}::ISA) {
  package $exception_class;
  Moo->import;
  extends('Throwable::Error');
}
EOP
            die "Internal error: $@" if $@;
            $code = $seen{$class}{$name} = sub {
                my $method = $exception_class->can('throw')
                    or die "Internal error: 'throw' method not found in class $exception_class";
                unshift @_, $exception_class;
                goto &$method; # goto is used in order to remove this
                               # completely uninteresting frame from
                               # the stacktrace
            };
        }
        else {
            $class->_exporter_fail($name, @more);
            return ()
        }
    }
    ($name, $code)
}

1;
__END__

=head1 NAME

Throwable::Subs - build and throw exception objects with minimal boilerplate

=head1 SYNOPSIS

  package My::App::Exception;
  use parent 'Throwable::Subs'
  1;

  package My::App;
  use My::App::Exception qw(throw_foo_exception);

  try {
    do_something()
        or throw_foo_exception("something is wrong");
        # throws an object of class My::App::Exception::Foo
  }
  catch {
    if ($_->isa('My::App::Exception::Foo')) {
      ...
    }
  }


=head1 DESCRIPTION

This module allows to create easyly a package where exception clases
are defined and later throwing objects of that classes from other
packages.

=head1 SEE ALSO

L<Throwable::Error>, L<Exporter::Tiny>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Qindel Formacion y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
