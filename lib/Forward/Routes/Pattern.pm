package Forward::Routes;
use strict;
use warnings;
use mop;

use Carp 'croak';

my $TOKEN = '[^\/()?:]+';


class Pattern {

    has $pattern;
    has $captures;
    has $prefix;
    has $path;
    has $parts;
    has $constraints = {};
    has $exclude = {};

    method compile {

        return $self unless defined $pattern;

        return $self if ref $pattern eq 'Regexp';

        $captures = [];

        my $re = '';

        # leading slash
        $pattern = '/' . $pattern unless $pattern =~ m{\A/};

        if (defined $prefix) {
            $pattern = "/$prefix$pattern";
        }

        my $par_depth = 0;

        my @parts;

        my @open;

        my $current_path;

        pos $pattern = 0;
        while (pos $pattern < length $pattern) {

            # Slash /
            if ($pattern =~ m{ \G \/ }gcx) {

                # Regex
                $re .= '/';
                $current_path .= '/';

                # Parts
                unless ($pattern eq '/') {
                    push @parts, {
                      type     => 'slash'
                    }
                }
            }

            # Capture :foo
            elsif ($pattern =~ m{ \G :($TOKEN) }gcx) {

                # Regex
                my $name = $1;
                my $constraint;
                my $re_part;
                if (exists $self->constraints->{$name}) {
                    $constraint = $self->constraints->{$name};
                    $re_part = "$constraint";
                }
                else {
                    $re_part = '[^\/]+';
                }

                if(exists $exclude->{$name}){
                    my $exclude_temp;
                    my @words = @{$exclude->{$name}};
                    foreach my $word (@words) {
                        $exclude_temp .= "(?!$word".'\Z)';
                    }
                    $re_part = $exclude_temp.$re_part;
                }

                $re .= '('.$re_part.')';

                # Parts
                push @parts, {
                  type       => 'capture',
                  name       => $name,
                  constraint => $constraint ? qr/^$constraint$/ : undef
                };

                # Capture names
                push @{$captures}, $name;
            }

            # *foo
            elsif ($pattern =~ m{ \G \*($TOKEN) }gcx) {

                # Regex
                my $name = $1;
                $re .= '(.*)';

                # Parts
                push @parts, {
                  type => 'glob',
                  name => $name
                };

                # Capture names
                push @{$captures}, $name;
            }

            # Text
            elsif ($pattern =~ m{ \G ($TOKEN) }gcx) {

                # Regex
                my $text = $1;
                $re .= quotemeta $text;

                # Parts
                push @parts, {
                  type     => 'text',
                  text     => $text
                };

                $current_path .= $text;
            }

            # Open group (
            elsif ($pattern =~ m{ \G \( }gcx) {

                # Group depth (optional and non optional groups)
                $par_depth++;

                # Regex
                $re .= '(?: ';

                # Parts
                # Optional saved in scalar ref, can bead justed later (right now,
                # we don't know whether this group will be optional or not
                my $var2 = '';
                push @parts, {
                  type     => 'open_group',
                  optional => \$var2
                };

                # Push scalar ref in array to make it available when the group is closed
                push @open, \$var2;

            }

            # Close optional group
            elsif ($pattern =~ m{ \G \)\? }gcx) {

                # Parts (optional must be saved as scalar ref, as optional
                # always has to be scalar ref)
                my $optional = 1;
                push @parts, {
                  type     => 'close_group',
                  optional => \$optional
                };

                # Adjust optional level in "open group"
                my $open = pop @open;
                $$open = $par_depth;

                # Depth
                $par_depth--;

                # Regex
                $re .= ' )?';

            }
            # Close non optional group
            elsif ($pattern =~ m{ \G \) }gcx) {

                # Parts
                my $optional = 0;
                push @parts, {
                  type     => 'close_group',
                  optional => \$optional
                };

                # Depth
                $par_depth--;

                # Regex
                $re .= ' )';

                # Optional param in "open_group" can remain empty, so just remove
                # from open tags array
                my $open = pop @open;

            }

        }

        if ($par_depth != 0) {
            croak qq/Parentheses are not balanced in pattern '$pattern'/;
        }

        $re = qr/\A $re/xi;

        $path    = $current_path unless @{$captures};
        $parts   = [@parts];
        $pattern = $re;

        return $self;
    }

    method path {
        return $path unless $_[0];

        $path = $_[0];
        return $self;
    }

    method prefix {
        return $prefix unless $_[0];

        $prefix = $_[0];
        return $self;
    }

    method pattern {
        return $pattern unless $_[0];

        $pattern = $_[0];
        return $self;
    }

    method parts {
        $parts ||= [];
        return $parts unless $_[0];

        $parts = $_[0];
        return $self;
    }

    method captures {
        $captures ||= [];
        return $captures unless $_[0];

        $captures = $_[0];
        return $self;
    }

    method constraints {
        return $constraints unless defined $_[0];

        my %new_constraints = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

        %$constraints = (%$constraints, %new_constraints);

        return $self;
    }

    method exclude {
        $exclude;
    }

}


1;
