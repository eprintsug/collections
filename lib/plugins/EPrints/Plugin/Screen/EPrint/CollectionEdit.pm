#This is now handled by a workflow_id override in recollect...
#obviously this creates a daft dependency for the time being...
#Plan: A third plugin WorkflowWrangler to help Eprints handle multiple plugins and their multiple workflows and metadata profiles

package EPrints::Plugin::Screen::EPrint::CollectionEdit;

@ISA = ( 'EPrints::Plugin::Screen::EPrint::Edit' );

#use strict;
#
#sub workflow_id
#{
#	my ( $self ) = @_;
#
#	$self->get_repository->log("In collections lib:workflow_id => ".$self->{processor}->{eprint}->value("type"));
#
#	if( $self->{processor}->{eprint}->value("type") eq "collection" )
#	{
#        	return "collection";
#	}
#	return "default";
#}
1;
