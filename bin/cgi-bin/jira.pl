#!/usr/bin/perl
#
# RTT-JiraWebhook
#
# Copyright (C) 2013 Realtime Technology AG, http://rtt.ag/
#
# Based on Znuny4OTRS-QuickClose
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/
#
# Author: Martin Gross <martin.gross@rtt.ag>
# License: GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#

use strict;
use warnings;

#use ../../ as lib location
use FindBin qw($Bin);
use lib "$Bin/../..";
use lib "$Bin/../../Kernel/cpan-lib";
use lib "$Bin/../../Custom";

use Getopt::Long;
use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Main;
use Kernel::System::Ticket;

use Data::Dumper;
use CGI;
use JSON::XS;
use POSIX;

# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'JIRA Webhook',
    %CommonObject,
);
$CommonObject{MainObject}   = Kernel::System::Main->new(%CommonObject);
$CommonObject{TimeObject}   = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject}     = Kernel::System::DB->new(%CommonObject);
$CommonObject{TicketObject} = Kernel::System::Ticket->new(%CommonObject);

my $q = new CGI;
my @fields = $q->param();

print $q->header();

my $jsondata;

if (!defined($q->param('POSTDATA'))) {
    exit('No Postdata!');
}
$jsondata = decode_json($q->param('POSTDATA'));

my @TicketIDs = $CommonObject{TicketObject}->TicketSearch(
	Result 	=> 'ARRAY',
	DynamicField_JiraKey => {
		Equals	=> $jsondata->{'issue'}->{'key'},
	},
	UserID		=> '1',
	Permission	=> 'rw',
	CacheTTL 	=> '1',
);

foreach my $TicketID(@TicketIDs) {
	# Get the Ticket
	my %Ticket = $CommonObject{TicketObject}->TicketGet(
		TicketID	=> $TicketID,
		UserID		=> 1,
	);

	# Only work on Tickets that are not closed
	# As "wait JIRA" is also defined as a closed-state, update anyway 
	if ( ($Ticket{StateType} ne 'closed') || ($Ticket{State} eq $CommonObject{ConfigObject}->Get('RTT::JiraWebhook::waitState')) ) {
	#if ( ($Ticket{StateType} ne 'closed') || (index($CommonObject{ConfigObject}->Get('RTT::JiraWebhook::waitState'), $Ticket{State}) != -1) ) {

		my @JiraFields = (
			['JiraSummary', $jsondata->{'issue'}->{'fields'}->{'summary'}],
			['JiraStatus', $jsondata->{'issue'}->{'fields'}->{'status'}->{'iconUrl'} . '|' . $jsondata->{'issue'}->{'fields'}->{'status'}->{'name'}],
			['JiraIssueType', $jsondata->{'issue'}->{'fields'}->{'issuetype'}->{'iconUrl'} . '|' . $jsondata->{'issue'}->{'fields'}->{'issuetype'}->{'name'}],
			['JiraPriority', $jsondata->{'issue'}->{'fields'}->{'priority'}->{'iconUrl'} . '|' . $jsondata->{'issue'}->{'fields'}->{'priority'}->{'name'}],
			['JiraAssignee', $jsondata->{'issue'}->{'fields'}->{'assignee'}->{'avatarUrls'}->{'16x16'} . '|' . $jsondata->{'issue'}->{'fields'}->{'assignee'}->{'displayName'}],
			['JiraLastChanged', strftime("%04Y-%02m-%02d %02H:%02M:%02S", localtime($jsondata->{'timestamp'}/1000))],
		);
		
		# Update JIRA-DynamicFields	
		foreach my $JiraField(@JiraFields) {
			my @JiraField = $JiraField;

			$CommonObject{TicketObject}->{DynamicFieldBackendObject}->ValueSet(
				DynamicFieldConfig => $CommonObject{TicketObject}->{DynamicFieldObject}->DynamicFieldGet(Name => $JiraField[0][0]),
				ObjectID           => $TicketID,
				Value              => $JiraField[0][1],
				UserID             => 1,
			);
		}
		
		my $jiraurl = $CommonObject{ConfigObject}->Get('RTT::JiraWebhook::JiraUrl');
		my $jiratext = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"><style>
		/* Changing the layout to use less space for mobiles */
		@media screen and (max-device-width: 480px), screen and (-webkit-min-device-pixel-ratio: 2) {
		    #email-body { min-width: 30em !important; }
		    #email-page { padding: 8px !important; }
		    #email-banner { padding: 8px 8px 0 8px !important; }
		    #email-avatar { margin: 1px 8px 8px 0 !important; padding: 0 !important; }
		    #email-fields { padding: 0 8px 8px 8px !important; }
		    #email-gutter { width: 0 !important; }
		}
		</style>
		<div id="email-body">
			<table id="email-wrap" align="center" border="0" cellpadding="0" cellspacing="0" style="background-color:#f0f0f0;color:#000000;width:100%;">
				<tr valign="top">
					<td id="email-page" style="padding:16px !important;">
						<table align="center" border="0" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border:1px solid #bbbbbb;color:#000000;width:100%;">
							<tr valign="top">
								<td bgcolor="#343434" style="background-color:#343434;color:#ffffff;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;line-height:1;">
									<img src="http://ji01.rtt.local:8080/s/en_US-sbcs3i-418945332/843/30/_/jira-logo-scaled.png" alt="" style="vertical-align:top;">
								</td>
							</tr>
							<tr valign="top">
								<td id="email-banner" style="padding:32px 32px 0 32px;">
									<table align="left" border="0" cellpadding="0" cellspacing="0" width="100%" style="width:100%;">
										<tr valign="top">
											<td style="color:#505050;font-family:Arial,FreeSans,Helvetica,sans-serif;padding:0;">
												<img id="email-avatar" src="' . $jsondata->{'user'}->{'avatarUrls'}->{'48x48'} . '" alt="" height="48" width="48" border="0" align="left" style="padding:0;margin: 0 16px 16px 0;">
												<div id="email-action" style="padding: 0 0 8px 0;font-size:12px;line-height:18px;">
													<a class="user-hover" rel="' .  $jsondata->{'user'}->{'emailAddress'} . '" id="email_' .  $jsondata->{'user'}->{'emailAddress'} . '" href="' . $jiraurl . 'secure/ViewProfile.jspa?name=' . $jsondata->{'user'}->{'name'} . '" style="color:#326ca6;">' . $jsondata->{'user'}->{'displayName'} . '</a>
													updated <img src="' . $jsondata->{'issue'}->{'fields'}->{'issuetype'}->{'iconUrl'} .'" height="16" width="16" border="0" align="absmiddle" alt="' . $jsondata->{'issue'}->{'fields'}->{'issuetype'}->{'name'} . '"> <a style="color:#326ca6;text-decoration:none;" href="' . $jiraurl . 'browse/' . $jsondata->{'issue'}->{'key'} .'">' . $jsondata->{'issue'}->{'key'} . '</a>
												</div>
												<div id="email-summary" style="font-size:16px;line-height:20px;padding:2px 0 16px 0;">
													<a style="color:#326ca6;text-decoration:none;" href="' . $jiraurl . 'browse/' . $jsondata->{'issue'}->{'key'} . '"><strong>' . $jsondata->{'issue'}->{'fields'}->{'summary'} . '</strong></a>
												</div>
											</td>
										</tr>
									</table>
								</td>
							</tr>
							<tr valign="top">
								<td id="email-fields" style="padding:0 32px 32px 32px;">
									<table border="0" cellpadding="0" cellspacing="0" style="padding:0;text-align:left;width:100%;" width="100%">
										<tr valign="top">
											<td id="email-gutter" style="width:64px;white-space:nowrap;"></td>
											<td>
												<table border="0" cellpadding="0" cellspacing="0" width="100%">';
		
		if (length($jsondata->{'comment'})) {	
			$jiratext = $jiratext . '<tr valign="top">
						    <td colspan="2" style="color:#000000;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;padding:0 0 16px 0;width:100%;">
							<div class="comment-block" style="background-color:#edf5ff;border:1px solid #dddddd;color:#000000;padding:12px;">
									<p>' . $jsondata->{'comment'}->{'body'} . '</p>
								</div>
							<div style="color:#505050;padding:4px 0 0 0;">&nbsp;</div>
						    </td>
						</tr>';
		}

		$jiratext = $jiratext . '<tr valign="top">
						<td style="color:#000000;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;padding:0 10px 10px 0;white-space:nowrap;">
							<strong style="font-weight:normal;color:#505050;">Change By:</strong>
						</td>
						<td style="color:#000000;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;padding:0 0 10px 0;width:100%;">
							<a class="user-hover" rel="' .  $jsondata->{'user'}->{'emailAddress'} . '" id="email_' .  $jsondata->{'user'}->{'emailAddress'} . '" href="' . $jiraurl . 'secure/ViewProfile.jspa?name=' . $jsondata->{'user'}->{'name'} . '" style="color:#326ca6;">' . $jsondata->{'user'}->{'displayName'} . '</a>
							' . strftime("%d.%m.%Y %H:%M", localtime($jsondata->{'timestamp'}/1000)) . '
						</td>
					</tr>';

		foreach my $changeitem(@{$jsondata->{'changelog'}->{'items'}}) {
			$jiratext = $jiratext . '<tr valign="top">
							<td style="color:#000000;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;padding:0 10px 10px 0;white-space:nowrap;">
								<strong style="font-weight:normal;color:#505050;">' . $changeitem->{'field'} . '</strong>
							</td>
							<td style="color:#000000;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:12px;padding:0 0 10px 0;width:100%;">
								<span class="diffremovedchars" style="background-color:#ffe7e7;text-decoration:line-through;">' . $changeitem->{'fromString'} . '</span>
								<span class="diffaddedchars" style="background-color:#ddfade;">' . $changeitem->{'toString'} . '</span>
							</td>
						</tr>';
		}

		$jiratext = $jiratext . '</table>
											</td>
										</tr>
									</table>
								</td>
							</tr>
						</table>
					</td><!-- End #email-page -->
				</tr>
				<tr valign="top">
					<td style="color:#505050;font-family:Arial,FreeSans,Helvetica,sans-serif;font-size:10px;line-height:14px;padding: 0 16px 16px 16px;text-align:center;">
						This message is automatically generated by the OTRS-JIRA-bridge.<br>
						If you think it was sent incorrectly, please contact your OTRS administrators<br>
					</td>
				</tr>
			</table><!-- End #email-wrap -->
		</div><!-- End #email-body -->';

		# Insert new Article with information, what changed
		$CommonObject{TicketObject}->ArticleCreate(
			TicketID	 => $TicketID,
			ArticleType      => 'note-internal',
			SenderType       => 'system',
			From             => 'JIRA',
			Subject          => 'JIRA Update!',
			Body             => $jiratext,
			Charset          => 'utf-8',
			MimeType         => 'text/html',
			HistoryType      => 'AddNote',
			HistoryComment   => 'Update from linked JIRA-case',
			UserID           => 1,
		);
		
		# Update TicketState to "open"
		$CommonObject{TicketObject}->TicketStateSet(
			TicketID	=> $TicketID,
			State		=> $CommonObject{ConfigObject}->Get('RTT::JiraWebhook::JiraUpdatedState'),
			UserID		=> 1,
		);
	}
}

