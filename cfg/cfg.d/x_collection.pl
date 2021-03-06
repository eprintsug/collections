$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_top} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_right} = 1100;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_bottom} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_left} = undef;
$c->{plugins}->{"Collection"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::CollectionSelect"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::NewCollection"}->{params}->{disable} = 0;

$c->{plugins}->{"InputForm::Component::Field::AddToCollection"}->{params}->{disable} = 0;

#$c->{plugins}->{"Screen::EPrint::CollectionEdit"}->{params}->{disable} = 0;
#$c->{plugin_alias_map}->{"Screen::EPrint::Edit"} = "Screen::EPrint::CollectionEdit";
#$c->{plugin_alias_map}->{"Screen::EPrint::CollectionEdit"} = undef;


$c->{z_collection_validate_eprint} = $c->{validate_eprint};

$c->{validate_eprint} = sub
{
	my( $eprint, $session, $for_archive ) = @_;

	my @problems = ();

	if( $eprint->get_type eq 'collection' ){
		return( @problems );
	}

	@problems = $session->get_repository()->call("z_collection_validate_eprint", $eprint, $session, $for_archive);

	return( @problems );
};

$c->{z_collection_eprint_warnings} = $c->{eprint_warnings};

$c->{eprint_warnings} = sub
{
        my( $eprint, $session ) = @_;

        my @problems = ();

        if( $eprint->get_type eq 'collection' ){
                return( @problems );
        }

        @problems = $session->get_repository()->call("z_collection_eprint_warnings", $eprint, $session );

        return( @problems );
};

$c->{collection_session_init} = $c->{session_init};

$c->{session_init} = sub {
        my ($repository, $offline) = @_;

        push @{$repository->{types}->{eprint}}, "collection";

        $repository->call("collection_session_init");
};

$c->{collection_eprint_render} = $c->{eprint_render};

#overwrite collection_render in order to make a custom render method for collections
$c->{collection_render} = $c->{eprint_render};
#Overwritten for data in cfg.d/xx_collection_render_for_data.pl, remove this file for default/alternative render

$c->{eprint_render} = sub
{
        my( $eprint, $session, $preview ) = @_;
	
	if( $eprint->value("type") ne "collection" )
	{
        	return $session->get_repository->call("collection_eprint_render", $eprint, $session, $preview );
	}
	
        return $session->get_repository->call("collection_render", $eprint, $session, $preview );

};

#This will allow us to override the render fundtion for relations and provide links between collection and collected
push @{ $c->{fields}->{eprint} },
{
        name => "relation",
        type=>"compound", multiple=>1,
        fields => [
                {
                        sub_name => "type",
                        type => "text",
                        replace_core => 1,
                },
                {
                        sub_name => "uri",
                        type => "text",
                        replace_core => 1,
                },
        ],
        render_value => "render_relation",
        replace_core => 1,
};
#TODO see what this does to other relation types...
$c->{render_relation} = sub
{
        my( $session, $field, $value, $alllangs, $nolink, $object) = @_;

        my $repo = $session->get_repository();
        my $frag = $session->make_doc_fragment();
	$frag->appendChild(my $ul = $repo->make_element("ul", class=>"relations_list"));
	if($object->is_collection){
		for my $part($object->get_related_objects("http://purl.org/dc/terms/hasPart")){
			$ul->appendChild(my $li = $repo->make_element("li"));
			$li->appendChild(my $a =$repo->make_element("a", href=> $part->uri));
			$a->appendChild($part->render_citation("brief"));
		}
	}else{
		for my $part($object->get_related_objects("http://purl.org/dc/terms/isPartOf")){
			$ul->appendChild(my $li = $repo->make_element("li"));
			$li->appendChild(my $a =$repo->make_element("a", href=> $part->uri));
			$a->appendChild($part->render_citation("brief"));
		}
    	}
        return $frag;
};
