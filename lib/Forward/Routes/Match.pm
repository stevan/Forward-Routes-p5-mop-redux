package Forward::Routes;
use strict;
use warnings;
use mop;


class Match {

    has $name;
    has $app_namespace;
    has $namespace;
    has $params_instance = {};
    has $captures = {};
    has $is_bridge;

    method _add_params ($params) {
        %{$self->params} = (%$params, %{$self->params});
        return $self;
    }


    method _add_captures ($params) {
        %{$self->captures} = (%$params, %{$self->captures});
        return $self;
    }


    method _add_name (@params) {
        $name = $params[0] if @params;
        return $self;
    }


    method _add_namespace (@params) {
        $namespace = $params[0] if @params;
        return $self;
    }


    method _add_app_namespace (@params) {
        $app_namespace = $params[0] if @params;
        return $self;
    }


    method params ($key) {
        return $params_instance unless defined $key && length $key;
        return $params_instance->{$key};
    }


    method captures ($key) {
        return $captures unless defined $key && length $key;
        return $captures->{$key};
    }


    method set_params {
        $params_instance = $_[0];
        return $self;
    }


    method set_captures {
        $captures = $_[0];
        return $self;
    }


    method is_bridge (@is_bridge) {
        return $is_bridge unless @is_bridge;
        $is_bridge = $is_bridge[0];
        return $self;
    }


    method name {
        return $name;
    }


    method controller {
        return $params_instance->{controller};
    }


    method namespace {
        return $namespace;
    }


    method app_namespace {
        return $app_namespace;
    }


    method class {
        return undef unless $params_instance->{controller};

        my @class;

        push @class, $app_namespace if $app_namespace;

        push @class, $namespace if $namespace;

        push @class, $params_instance->{controller};

        return join('::', @class);
    }


    method action {
        return $params_instance->{action};
    }
}

1;
