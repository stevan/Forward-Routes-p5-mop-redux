use strict;
use warnings;
use mop;

use Forward::Routes::Resources::Plural;
use Forward::Routes::Resources::Singular;
use Carp;


class Forward::Routes::Resources extends Forward::Routes {

    has $only;
    has $nested_resources_parent_name;
    has $resource_name;
    has $resource_name_part;
    has $ctrl;

    method add_member_route ($pattern, @params) {
        my $members = $self->members;

        # makes sure that inheritance works
        my $child = Forward::Routes->new->BUILD($pattern, @params);
        $members->add_child($child);

        # name
        my $member_route_name = $pattern;
        $member_route_name =~s|^/||;
        $member_route_name =~s|/|_|g;


        # Auto set controller and action params and name
        $child->to($ctrl . '#' . $member_route_name);
        $child->name($self->name . '_' . $member_route_name);

        return $child;
    }


    method id_constraint {
    }


    method init_options ($options) {
        # default
        $self->id_constraint(qr/[^.\/]+/);

        if ($options) {
            $self->id_constraint($options->{constraints}->{id}) if $options->{constraints}->{id};
            $only = $options->{only};
            $self->pattern->pattern($options->{as}) if exists $options->{as};
        }

        my $ns_name_prefix = $self->namespace ? Forward::Routes::Resources->namespace_to_name($self->namespace) . '_' : '';
        my $route_name = ($nested_resources_parent_name ? $nested_resources_parent_name . '_' : '') . $ns_name_prefix . $resource_name;
        $self->name($route_name);

        $resource_name_part = $ns_name_prefix . $resource_name;


        $ctrl = Forward::Routes::Resources->format_resource_controller->($resource_name);
    }


    method members {
        return $self;
    }


    method namespace_to_name ($namespace) {
        my @new_parts;

        my @parts = split /::/, $namespace;

        for my $part (@parts) {
            my @words;
            while ($part =~ s/([A-Z]{1}[^A-Z]*)//){
                my $word = lc $1;
                push @words, $word;
            }
            push @new_parts, join '_', @words;
        }
        return join '_', @new_parts;
    }


    method _adjust_nested_resources ($parent) {
        $parent->_is_plural_resource || return;

        my $parent_name = $parent->resource_name_part;

        my $parent_id_name = $self->singularize->($parent_name) . '_id';

        $self->pattern->pattern(':' . $parent_id_name . '/' . $resource_name);
        $self->constraints($parent_id_name => $parent->id_constraint);

        if (defined $parent->name) {
            $nested_resources_parent_name = $parent->name;
        }
    }


    method _ctrl (@params) {
        return $ctrl unless @params;

        $ctrl = $params[0];

        return $self;
    }


    method _prepare_resource_options (@names) {
        my @final;
        while (@names) {
            my $name = shift(@names);

            if ($name =~m/^-/){
                $name =~s/^-//;
                push @final, {} unless ref $final[-1] eq 'HASH';
                $final[-1]->{$name} = shift(@names);
            }
            else {
                push @final, $name;
            }
        }
        return \@final;
    }


    method resource_name {
        return $resource_name unless @_;
        $resource_name = $_[0];
        return $self;
    }

    method resource_name_part {
        $resource_name_part;
    }


    method only {
        $only;
    }


}

1;
