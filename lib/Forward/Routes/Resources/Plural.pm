package Forward::Routes::Resources;
use strict;
use warnings;
use mop;


class Plural extends Forward::Routes::Resources {

    has $id_constraint;
    has $collection;
    has $members;

    method add_collection_route ($pattern, @params) {

        my $child = Forward::Routes->new->BUILD($pattern, @params);
        $self->collection->add_child($child);

        # name
        my $collection_route_name = $pattern;
        $collection_route_name =~s|^/||;
        $collection_route_name =~s|/|_|g;

        $members->pattern->exclude->{id} ||= [];
        push @{$members->pattern->exclude->{id}}, $collection_route_name;


        # Auto set controller and action params and name
        $child->to($self->_ctrl  . '#' . $collection_route_name);
        $child->name($self->name . '_' . $collection_route_name);

        return $child;
    }


    method collection {
        return $collection ||= $self->add_route;
    }


    method enabled_routes {
        my $only = $self->only;

        my %selected = (
            index       => 1,
            create      => 1,
            show        => 1,
            update      => 1,
            delete      => 1,
            create_form => 1,
            update_form => 1,
            delete_form => 1
        );

        if ($only) {
            %selected = ();
            foreach my $type (@$only) {
                $selected{$type} = 1;
            }
        }

        return \%selected;
    }


    method id_constraint (@params) {
        return $id_constraint unless @params;

        $id_constraint = $params[0];

        return $self;
    }


    method inflate {
        my $enabled_routes = $self->enabled_routes;
        my $route_name     = $self->name;
        my $ctrl           = $self->_ctrl;

        # collection
        my $collection_instance = $self->collection
          if $enabled_routes->{index} || $enabled_routes->{create} || $enabled_routes->{create_form};

        $collection_instance->add_route
          ->via('get')
          ->to($ctrl."#index")
          ->name($route_name.'_index')
          if $enabled_routes->{index};

        $collection_instance->add_route
          ->via('post')
          ->to($ctrl."#create")
          ->name($route_name.'_create')
          if $enabled_routes->{create};

        # new resource item
        $collection_instance->add_route('/new')
          ->via('get')
          ->to($ctrl."#create_form")
          ->name($route_name.'_create_form')
          if $enabled_routes->{create_form};


        # members
        if (    $enabled_routes->{show} || $enabled_routes->{update} || $enabled_routes->{delete}
             || $enabled_routes->{update_form} || $enabled_routes->{delete_form}
        ) {
            my $members_instance = $self->members;

            $members_instance->add_route
              ->via('get')
              ->to($ctrl."#show")
              ->name($route_name.'_show')
              if $enabled_routes->{show};

            $members_instance->add_route
              ->via('put')
              ->to($ctrl."#update")
              ->name($route_name.'_update')
              if $enabled_routes->{update};

            $members_instance->add_route
              ->via('delete')
              ->to($ctrl."#delete")
              ->name($route_name.'_delete')
              if $enabled_routes->{delete};

            $members_instance->add_route('edit')
              ->via('get')
              ->to($ctrl."#update_form")
              ->name($route_name.'_update_form')
              if $enabled_routes->{update_form};

            $members_instance->add_route('delete')
              ->via('get')
              ->to($ctrl."#delete_form")
              ->name($route_name.'_delete_form')
              if $enabled_routes->{delete_form};
        }

        return $self;
    }


    method members {
        return $members if $members;

        $id_constraint || die 'missing id constraint';

        $members = $self->add_route(':id')
          ->constraints('id' => $id_constraint);

        $members->pattern->exclude->{id} ||= [];
        push @{$members->pattern->exclude->{id}}, 'new';

        return $members;
    }
}

1;
