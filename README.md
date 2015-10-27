[![RTT Logo](http://www.rtt.ag/static/system/modules/com.realtimetechnology.corporatewebsite/1.5.7/resources/img/logo_rtt.png) **CHALLENGING REALITY. Every day**](http://rtt.ag/)

RTT-JiraWebhook
===============

This package allows you to connect your OTRS to a Atlassin Jira.

**Installation**

Download the opm-Package and install it via the admin-interface using the package manager.

**Prerequisites**

- OTRS 5.0.x
- An unmaintained version for OTRS 3.2.x can be found at https://github.com/rttag/RTT-JiraWebhook/tree/v1.0.0
- An unmaintained version for OTRS 3.3.x can be found at https://github.com/rttag/RTT-JiraWebhook/tree/v1.0.1

**Configuration OTRS**

In the OTRS SysConfig you should at least update the RTT::JiraWebhook::JiraUrl-setting to point to your local Jira-Installation.

**Configuration Jira**

Setup a Webhook pointing to http://your-otrs/jira.pl

**Functionality**

The plugin provides you with some new Custom Fields which you may choose to display in various places. To use this module, you'll need to enter the Jira-Key into the Custom Field "Jira ID". Please not, that you can only enter one Jira-Key per OTRS-Ticket.

As soon as the issue is updated in Jira, a call is dispatched to OTRS and additonal information like the summary, the status, the issue-type, the priority, the assigned person and the last time the Jira-entry has been changed will be added to the respective custom-fields.

Additionally, a Jira-Style update-message is inserted as an article into the Ticket and the state of the ticket is changed to "open" (can be changed via SysConfig at RTT::JiraWebhook::JiraUpdatedState).

You may choose to acknowledge this change by putting the ticket "back to sleep" by pressing the new "wait Jira"-button in the ticket-toolbar. By default, this ticket-state is called "wait Jira" and is considered by OTRS internally as "closed". Of course, this can also be changed in SysConfig (RTT::JiraWebhook::waitState).

Please note, that closed tickets are not reopened by the plugin except when they are in the state defined by RTT::JiraWebhook::waitState (defaults to: "wait Jira").

**Caveats**

At this moment, the module does not feature any kind of authentication for the incoming data. Please make shure to have security-measures in place, that only authorized parties may use the Endpoint.

**Acknowledgements**

Part of this module is based on the Znuny4OTRS-QuickClose-plugin, released at https://github.com/znuny/Znuny4OTRS-QuickClose

**License**

This module is licensed according to the terms of the GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007. You can find a copy of the license in the file called LICENSE.

**Warranty/Liability**

THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.


(c) 2013-2014 Realtime Technology AG - http://rtt.ag/
