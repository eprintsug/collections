#This is now handled by a workflow_id override in recollect...
#obviously this creates a daft dependency for the time being...
#Plan: A third plugin WorkflowWrangler to help Eprints handle multiple plugins and their multiple workflows and metadata profiles


=head1 NAME

EPrints::Plugin::Screen::EPrint::CollectionDetails

=cut

package EPrints::Plugin::Screen::EPrint::CollectionDetails;

@ISA = ( 'EPrints::Plugin::Screen::EPrint::Details' );

#use strict;
#
#sub workflow_id
#{
#        my ( $self ) = @_;
#
#        if( $self->{processor}->{eprint}->value("type") eq "collection" )
#        {
#                return "collection";
#        }
#        return "default";
#}
1;
