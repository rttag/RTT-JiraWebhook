#
# RTT-JiraWebhook
#
# Copyright (C) 2013-2014 Realtime Technology AG, http://rtt.ag/
#
# Kernel/System/DynamicField/Driver/Text.pm - Delegate for DynamicField Text Driver
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
#
# Author: Martin Gross <martin.gross@rtt.ag>
# License: GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#

# --
# Kernel/System/DynamicField/Driver/Text.pm - Delegate for DynamicField Text Driver
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::IconText;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::DynamicFieldValue;

use base qw(Kernel::System::DynamicField::Driver::BaseText);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(ConfigObject EncodeObject LogObject MainObject DBObject)) {
        die "Got no $Needed!" if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }

    # create additional objects
    $Self->{DynamicFieldValueObject} = Kernel::System::DynamicFieldValue->new( %{$Self} );

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 1,
        'IsSortable'                   => 1,
        'IsFiltrable'                  => 0,
        'IsStatsCondition'             => 1,
        'IsCustomerInterfaceCapable'   => 1,
    };

    # get the Dynamic Field Backend custmom extensions
    my $DynamicFieldDriverExtensions
        = $Self->{ConfigObject}->Get('DynamicFields::Extension::Driver::IconText');

    EXTENSION:
    for my $ExtensionKey ( sort keys %{$DynamicFieldDriverExtensions} ) {

        # skip invalid extensions
        next EXTENSION if !IsHashRefWithData( $DynamicFieldDriverExtensions->{$ExtensionKey} );

        # create a extension config shortcut
        my $Extension = $DynamicFieldDriverExtensions->{$ExtensionKey};

        # check if extension has a new module
        if ( $Extension->{Module} ) {

            # check if module can be loaded
            if ( !$Self->{MainObject}->RequireBaseClass( $Extension->{Module} ) ) {
                die "Can't load dynamic fields backend module"
                    . " $Extension->{Module}! $@";
            }
        }

        # check if extension contains more behabiors
        if ( IsHashRefWithData( $Extension->{Behaviors} ) ) {

            %{ $Self->{Behaviors} } = (
                %{ $Self->{Behaviors} },
                %{ $Extension->{Behaviors} }
            );
        }
    }

    return $Self;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    # set HTMLOuput as default if not specified
    if ( !defined $Param{HTMLOutput} ) {
        $Param{HTMLOutput} = 1;
    }

    # get raw Title and Value strings from field value
    my $Value = defined $Param{Value} ? $Param{Value} : '';
    my @vals = split('\|', $Value);
    my $Title = '';

    if (@vals) {
        $Value = '<img src="' . $vals[0] . '"/> ' . $vals[1];
        $Title = $vals[1];
    }

    # set field link form config
    my $Link = $Param{DynamicFieldConfig}->{Config}->{Link} || '';

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
        Link  => $Link,
    };

    return $Data;
}

1;
