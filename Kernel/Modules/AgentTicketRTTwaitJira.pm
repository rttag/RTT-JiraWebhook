#
# RTT-JiraWebhook
#
# Copyright (C) 2013-2014 Realtime Technology AG, http://rtt.ag/
# Copyright (C) 2014-2018 Dassault Systemes 3DEXCITE GmbH, http://3dexcite.de/
#
# Based on Znuny4OTRS-QuickClose
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/
#
# Author: Martin Gross <martin.gross@3ds.com>
# License: GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
package Kernel::Modules::AgentTicketRTTwaitJira;

use strict;
use warnings;
no warnings 'redefine';

use base qw(Kernel::Modules::AgentTicketActionCommon);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{LayoutObject} = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    $Self->{TicketObject} = $Kernel::OM->Get('Kernel::System::Ticket');
    $Self->{ConfigObject} = $Kernel::OM->Get('Kernel::Config');

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No TicketID is given!',
            Comment => 'Please contact the admin.',
        );
    }

    # check permissions
    my $Access = $Self->{TicketObject}->TicketPermission(
        Type     => 'close',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID}
    );

    # error screen, don't show ticket
    if ( !$Access ) {
        return $Self->{LayoutObject}->NoPermission(
            Message    => "You need $Self->{Config}->{Permission} permissions!",
            WithHeader => 'yes',
        );
    }

    my $State = $Self->{ConfigObject}->Get('RTT::JiraWebhook::waitState');
    if ($State) {
        my $Success = $Self->{TicketObject}->TicketStateSet(
            State    => $State,
            TicketID => $Self->{TicketID},
            UserID   => $Self->{UserID},
        );
        if ($Success) {
            $Self->{TicketObject}->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
        }
    }
    return $Self->{LayoutObject}->Redirect( OP => $Self->{LastScreenOverview} );
}
1;

