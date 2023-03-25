# 3Sigma Invites SFDX Project

This repo holds the code for the 3Sigma Invites managed package.

The latest version of the packaged contents is available in the `/bin/latest.zip` archive.

An example invite can be found [here](https://x3st-invites-dev-ed.my.salesforce-sites.com/invite?eirId=a011I00000CLPXSQA5).

<br />

<img src="man/img/Example-Invite.png" width="49%" style="vertical-align: top;"/>
<img src="man/img/Invite-Others.png" width="49%" style="vertical-align: top;"/>

# Setup

Following installation you will need to ensure you have a publicly facing site and that the users of that site can read "Event Invite Responses" and that the default Org-wide Email Address is accessible to all profiles (as this email address will be used when invitees invite others). You will further need to ensure the "Calendar Invite" Custom Settings, shown below, are updated.

<img src="man/img/Invite-Custom-Settings.png" width="99%" style="vertical-align: top;"/>

<br />

# Sending Invites

<img src="man/img/Create-New-Invite.png" width="49%" style="vertical-align: top;"/>
<img src="man/img/One-Invite-Per-Case.png" width="49%" style="vertical-align: top;"/>

<br />

# Entity Relations

```mermaid
erDiagram
    "Case" ||..|{ "Event" : has
    "Event" ||..|| "Event Invite" : has
    "Event" ||..|{ "Event Invite (Canceled)" : has
    "Event" ||..|| "Contact" : has
    "Event Invite" ||..|{ "Event Invite Response" : contains
    "Event Invite Response" ||..|| "Contact" : has
```
