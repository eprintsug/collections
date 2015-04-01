=pod

=head1 NAME

B<EPrints::Plugin::Collection> - Extends the EPrint dataobject in 
order to provide collections of resources.

=head1 DESCRIPTION

This module extends the EPrint dataobject to create a collection. A 
collection is in effect a list of relations to other EPrint 
dataobjects. These other data objects are considered the content of 
the collection.

=over 4

=cut

package EPrints::Plugin::Collection;

no warnings;

use strict;

our @ISA = qw/ EPrints::Plugin /;

#####################################################################
=pod

=item $result = EPrints::Plugin::Collection::my_bookmarks_installed( [$bookmark_plugin] );

Returns whether or not this repository has the OneShare MyBookmarks
plugin installed. By default it looks for EPrints::Plugin::MyBookmarks,
but if you have installed the plugin under a different name for
whatever reason then you can specifiy the full perl name of the bookmark
plugin. e.g. EPrints::Plugin::OneShareBookmarks.

=cut
#####################################################################
sub my_bookmarks_installed
{
	my $installed = 0;

	$installed = 1 if( defined EPrints::Utils::require_if_exists( 'EPrints::Plugin::Bookmarks' ) );

	return $installed;
}

package EPrints::DataObj::EPrint;

#####################################################################
=pod

=item $result = $session->is_collection;

Returns whether the EPrint dataobject should be considered as a
collection or not. If the OneShare MyBookmarks plugin is installed
then the bookmarks EPrint is considered a collection.

=cut
#####################################################################
sub is_collection
{
	my( $self ) = @_;

	my $is_collection = 0;

	if( EPrints::Plugin::Collection::my_bookmarks_installed )
	{
		$is_collection = $is_collection || $self->get_value( 'type' ) eq 'bookmarks';
	}

	$is_collection = $is_collection || $self->get_value( 'type' ) eq 'collection';

	return $is_collection;
}

sub render
{
        my( $self, $preview ) = @_;

        my( $dom, $title, $links );

	my $status = $self->get_value( "eprint_status" );
    
	if( $self->is_collection )
	{
		if( $status eq "deletion" )
        	{
        	        $title = $self->{session}->html_phrase(
        	                "Collection:collection_gone_title" );
        	        $dom = $self->{session}->make_doc_fragment;
        	        $dom->appendChild( $self->{session}->html_phrase(
        	                "Collection:collection_gone" ) );
        	}
        	else
        	{
			( $dom, $title, $links ) =
                	       	$self->{session}->get_repository->call(
                	       	        "collection_render",
                	       	        $self, $self->{session}, $preview );
		}
	}
	else
	{
		if( $status eq "deletion" )
		{
			$title = $self->{session}->html_phrase(
				"lib/eprint:eprint_gone_title" );
			$dom = $self->{session}->make_doc_fragment;
			$dom->appendChild( $self->{session}->html_phrase(
				"lib/eprint:eprint_gone" ) );
#RM replacedby removed from 3.3.13 so removing... will take advisement on better ways to handle the deletion case...
#			my $replacement = new EPrints::DataObj::EPrint(
#				$self->{session},
#				$self->get_value( "replacedby" ) );
#			if( defined $replacement )
#			{
#				my $cite = $replacement->render_citation_link;
#				$dom->appendChild(
#					$self->{session}->html_phrase(
#						"lib/eprint:later_version",
#						citation => $cite ) );
#			}
		}
		else
		{
			( $dom, $title, $links ) =
				$self->{session}->get_repository->call(
					"eprint_render",
					$self, $self->{session}, $preview );
		}
	}

	my $content = $self->{session}->make_element( "div", class=>"ep_summary_content" );
	my $content_top = $self->{session}->make_element( "div", class=>"ep_summary_content_top" );
	my $content_left = $self->{session}->make_element( "div", class=>"ep_summary_content_left" );
	my $content_main = $self->{session}->make_element( "div", class=>"ep_summary_content_main" );
	my $content_right = $self->{session}->make_element( "div", class=>"ep_summary_content_right" );
	my $content_bottom = $self->{session}->make_element( "div", class=>"ep_summary_content_bottom" );
	my $content_after = $self->{session}->make_element( "div", class=>"ep_summary_content_after" );
	
	$content_left->appendChild( render_box_list( $self->{session}, $self, "summary_left" ) );
	$content_right->appendChild( render_box_list( $self->{session}, $self, "summary_right" ) );
	$content_bottom->appendChild( render_box_list( $self->{session}, $self, "summary_bottom" ) );
	$content_top->appendChild( render_box_list( $self->{session}, $self, "summary_top" ) );
	
	$content->appendChild( $content_left );
	$content->appendChild( $content_right );
	$content->appendChild( $content_top );
	$content->appendChild( $content_main );
	$content_main->appendChild( $dom );
	$content->appendChild( $content_bottom );
	$content->appendChild( $content_after );
	$dom = $content;
	
	if( !defined $links )
        {
               	$links = $self->{session}->make_doc_fragment;
        }

	return( $dom, $title, $links );
}


#####################################################################
=pod

=item $collections_list = $eprint->get_collection_membership;

Returns an EPrints::List of all the published Collections that the 
EPrint belongs to. If the supplied EPrint is a collection itself then
 the result will always be undefined.

=cut
#####################################################################
sub get_collection_membership
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $list;
	
	if( !$self->is_collection )
	{
		my $ds = $session->get_repository->get_dataset( 'archive' );
		my $search = EPrints::Search->new(
			satisfy_all => 1,
			session => $session,
			dataset => $ds
		);
		$search->add_field( $ds->get_field( 'type' ), qw/ collection / );

		$list = $search->perform_search;
		$search->dispose;
	}

	return $list;
}

#####################################################################
=pod

=item $eprint->render_collection_membership;
Renders the collections that this EPrint is a member of as an
unordered list.

=cut
#####################################################################
sub render_collection_membership
{
	my( $self ) = @_;

	my $session = $self->{session};
	#my $collections_list = $self->get_collection_membership;
	my @collections_list = @{ $self->get_parent_collections( $session ) };

	my $frag = $session->make_doc_fragment;

	my $collections_list_element = $session->make_element( 'ul' );
	if( @collections_list )
	{
		foreach my $collection_id ( @collections_list )
		{
			my $collection = new EPrints::DataObj::EPrint( $session, $collection_id );
			if( $collection->get_type eq 'collection' && $collection->get_value( 'eprint_status' ) eq 'archive' )
			{
				my $collections_list_item = $session->make_element( 'li' );
				my $collection_link = $session->make_element( 'a', href=>$collection->get_url );
				$collection_link->appendChild( $session->make_text( $collection->get_value( 'title' ) ) );
				$collections_list_item->appendChild( $collection_link );
				$collections_list_element->appendChild( $collections_list_item );
			}
		}
	}

	if( $collections_list_element->childNodes->size )
	{
		$frag->appendChild( $collections_list_element );
	}
	else
	{
		$frag->appendChild( $session->html_phrase( 'Plugin/Collection:no_parent_collections' ) );
	}

	return $frag;
}

sub belongs
{
	my( $self, $targetid ) = @_;

	return 0 unless( $self->is_collection );

	my $r = $self->value("relation");
	foreach my $relation_hash ( @$r )
	{
		$self->{session}->log($relation_hash->{uri}." == ".$targetid);
		if( $relation_hash->{uri} eq $targetid )
		{
			return 1;
		}
	}

	return 0;
}

sub get_blacklist
{
        my( $self, $fieldname ) = @_;

        my $blacklist = {};
        my $items = $self->get_value( $fieldname );
        foreach( @$items ) 
        {
                $blacklist->{$_->{uri}} = 1;
        }

        return $blacklist;
}

sub add_to_collection
{
#	my( $self, $targetid ) = @_;
	my( $self, $eprint ) = @_;
	
	
	my $repo = $self->{session};
	return 0 unless( $self->is_collection );

#	return 0 if( $self->belongs( $targetid ) );
	print STDERR "belongs? ".$self->belongs( $eprint->internal_uri )."\n";
	return 0 if( $self->belongs( $eprint->internal_uri ) );



	#my $eprint = $repo->eprint( $targetid );
#	my $eprint = EPrints::DataSet->get_object_from_uri( $repo, $targetid );
	if( !defined $eprint )
	{
		return 0; 
	}

	if( $eprint->value("type") eq 'collection' )
	{
		return 0;
	}

	my $r = $self->value("relation");

#	push @$r, { type => 'http://purl.org/dc/terms/hasPart', uri => $targetid };
	push @$r, { type => 'http://purl.org/dc/terms/hasPart', uri => $eprint->internal_uri };

	$self->set_value( 'relation', $r );
	$self->commit;
	$self->remove_static;

	#RM adds this inverse relation... it will cause a md5 carp if bazaar package is renabled...
	my $er = $eprint->value("relation");

	push @$er, { type => 'http://purl.org/dc/terms/isPartOf', uri => $self->internal_uri };

	$eprint->set_value( 'relation', $er );
	$eprint->commit;
	$eprint->remove_static;

	return 1;
}

sub remove_from_collection
{
	my( $self, $eprint ) = @_;

	return 0 unless( $self->is_collection );

	return 0 unless( $self->belongs( $eprint->internal_uri ) );

	my $r = $self->value("relation");
	my $newr;

	foreach( @$r )
	{
		push @$newr, $_ unless( $_->{uri} eq $eprint->internal_uri );
	}

	$self->set_value( 'relation', $newr );
	$self->commit;

	$self->remove_static;

	#RM adds inverse removal too	
#	my $eprint = EPrints::DataSet->get_object_from_uri( $self->{session}, $eprint->internal_uri );
	if( !defined $eprint )
	{
		return 0; 
	}
	my $er = $eprint->value("relation");
	my $newer;

	foreach( @$er ){
		push @$newer, $_ unless( $_->{uri} eq $self->internal_uri );
	}
	$eprint->set_value( 'relation', $newer );
	$eprint->commit;

	$eprint->remove_static;

	return 1;
}

sub get_parent_collections
{
	my( $self, $session ) = @_;

#	my $sql = 'SELECT eprintid FROM `eprint_relation_uri` WHERE relation_uri='.$self->get_id.';';
	my $sql = 'SELECT eprintid FROM `eprint_relation_uri` WHERE relation_uri='.$self->internal_uri.';';

	my $sth = $session->get_database->prepare( $sql );
	$session->get_database->execute( $sth, $sql );

	my @results;
	while( my $r = $sth->fetchrow_array )
	{
		push @results, $r;
	}

	$sth->finish;

	return \@results;
}

sub get_parent_collections_hash
{
	my( $self, $session ) = @_;
	
#	my $sql = 'SELECT eprintid FROM `eprint_relation_uri` WHERE relation_uri='.$self->get_id.';';
	my $sql = 'SELECT eprintid FROM `eprint_relation_uri` WHERE relation_uri='.$self->internal_uri.';';

	my $sth = $session->get_database->prepare( $sql );
	$session->get_database->execute( $sth, $sql );

	my %results;
	while( my $r = $sth->fetchrow_array )
	{
		$results{$r} = 1;
	}

	$sth->finish;

	return \%results;
}
1;
