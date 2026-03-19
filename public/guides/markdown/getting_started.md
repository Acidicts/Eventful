# Getting Started

Welcome to the Eventful.

This section provides documentation on how to use the tool's features effectively.

## Features
- Organisation 
- Event management
- Attendee tracking
- Analytics and reporting
- A waiver system ( don't rely on this, we recommend your own custom waiver system, or a seperate system like waiversign.com )

## Some Slang
- Orgs: Organisations
- Dash: Dashboard
- QR: QR codes

## Organisation Setup
To get started, if you are part of hackclub you will be in the hackclub organisation by default, and will be able to create a sub team (once this is added as a feature). If not contact a site admin to create you a organisation.

#### The Organisation has a few key details during setup:
- Name: The name of your organisation
- Timezone: The timezone your organisation operates in (Not yet implemented, will be added soon?, will be UTC by default)
- Logo: The logo for your organisation
- Custom domain: A custom domain for your organisation (Not yet implemented, will be added soon, perhaps)
- Branding - so umm colours and stuff, not yet implemented, will be added soon? - You can get "Eventful" on the top left replaced with your org name ig
- Description: A description of your organisation, this is optional and can be left blank

## Events
With this you can make this without end but deleting them is another story, don't overdo it or it will haunt you as site admins won't delete them for you (we might add a delete feature in the future, but for now contact a site admin if you need an event deleted).
These are the key parts of this tool which every attendee is attached to in the code at least.
The Dash for events shows you remaining capacity and a few other details, and you can click into the event to see more details and manage attendees. But the main thing to remember there is the button to dispatch the QR Codes for participants, this is important if you want to use our check in system, which is the only way to track attendance at the moment.

#### Event details:
- Name: The name of your event
- Date and time: When your event is happening
- Location: Where your event is happening (Not yet implemented, will be added soon?)
- Capacity: How many people can attend your event
- Description: A description of your event, this is optional and can be left blank
- And Some other stuff which listing would be a waste of time

## Attendees
Attendees are the people who attend your events, well obviously...
They can be created through your event's apply form, which is shown in you event dash at the bottom.
Attendees are checked in through the QR code system, which is the only way to track attendance, so make sure to dispatch those QR codes before your event. You can also check in attendees manually through the attendee details page, which is accessed through the event dash. This is useful for checking in attendees who didn't receive their QR code, or if the QR code system isn't working for some reason (prob too many emails being dispatched - Email Timeout D:<).

## Galleries
Once an event has ended an email is automatically sent to all participants with a link to the evnt gallery for them to share photos from the event, this is a simple form which allows them to upload photos and share them with other attendees. The gallery is only accessible to attendees of the event, and is a great way to share memories from the event.

## Site Admins
Site admins are the people who have access to the backend of the tool, they can manage organisations, events, and attendees, they can also manage the content of this guide and the FAQs (non existant). If you need any help with the tool, or if you have any feedback, please contact a site admin (you can find a contact email at the bottom of the page - not monitored often).
