#!/bin/bash

# Script to create GitHub issues from feature proposals
# Usage: ./create_issues.sh
# Requires: gh CLI authenticated with appropriate permissions

set -e

REPO="Acidicts/Eventful"

echo "Creating GitHub issues for Eventful feature proposals..."
echo "Repository: $REPO"
echo ""

# Check if gh is authenticated
if ! gh auth status > /dev/null 2>&1; then
    echo "Error: GitHub CLI is not authenticated."
    echo "Please run: gh auth login"
    exit 1
fi

# Feature 1: Complete Role-Based Permission System
echo "Creating issue 1: Complete Role-Based Permission System..."
gh issue create --repo "$REPO" \
    --title "Complete Role-Based Permission System" \
    --label "enhancement,security,high-priority" \
    --body "## Description
The role-based permission system is partially implemented but not fully enforced across the application. Models exist (\`OrganisationRole\`, \`RolePermission\`) but permissions are rarely checked in controllers.

## Current State
- ✅ Models created (OrganisationRole, RolePermission)
- ✅ HABTM relationships established
- ✅ Permissions created during role creation
- ❌ Permission enforcement in controllers is incomplete
- ❌ Admin/member role distinction not consistently applied

## Implementation Plan
1. Create a permission checking service/concern
2. Add \`before_action\` filters to controllers to enforce permissions
3. Update all admin actions to check for appropriate permissions
4. Add tests for permission enforcement
5. Document the permission system

## Files to Update
- \`app/controllers/application_controller.rb\` - Add permission checking methods
- \`app/controllers/dashboard/*\` - Add permission checks
- Create \`app/services/permission_checker.rb\` or similar
- Add tests in \`test/controllers/*\`

## Related Models
- \`app/models/organisation_role.rb\`
- \`app/models/role_permission.rb\`

## Priority
High - Security and access control issue"

# Feature 2: Event Reminder and Notification System
echo "Creating issue 2: Add Event Reminder and Notification System..."
gh issue create --repo "$REPO" \
    --title "Add Event Reminder and Notification System" \
    --label "enhancement,feature,high-priority,notifications" \
    --body "## Description
Implement automated notifications to keep attendees informed about upcoming events, schedule changes, and important deadlines.

## Current State
- ✅ Email infrastructure exists (ActionMailer, multiple mailers)
- ✅ Event model tracks dates and times
- ❌ No automated reminder system
- ❌ No schedule change notifications
- ❌ No application deadline reminders

## Planned Notifications
1. **Event Reminders**
   - 1 week before event
   - 1 day before event
   - 1 hour before event
   - Configurable by organizer

2. **Schedule Changes**
   - Location changes
   - Time/date changes
   - Cancellations

3. **Application Deadlines**
   - Deadline approaching (3 days, 1 day)
   - Application accepted/rejected

4. **Check-in Reminders**
   - QR code reminder email before event

## Implementation Plan
1. Create \`EventNotification\` model to track notification preferences
2. Add background jobs for scheduled reminders
3. Create email templates for each notification type
4. Add preference controls for attendees (opt-in/opt-out)
5. Add organizer controls to customize notification timing
6. Implement job scheduling (using Solid Queue)
7. Add tests for notification delivery

## Files to Update
- Create new mailer methods in \`app/mailers/event_mailer.rb\`
- Create background jobs in \`app/jobs/\`
- Add notification preferences to Event model
- Update event forms to include notification settings

## Priority
High - Improves attendee experience"

# Feature 3: Complete Gallery System
echo "Creating issue 3: Complete Gallery System Implementation..."
gh issue create --repo "$REPO" \
    --title "Complete Gallery System Implementation" \
    --label "enhancement,feature,medium-priority" \
    --body "## Description
The Gallery system was planned but is minimally implemented. Models exist but functionality is limited compared to the original specification.

## Current State
- ✅ Gallery model created
- ✅ Photo model created with Active Storage
- ✅ Photos can be associated with events and attendees
- ❌ Gallery integration is minimal
- ❌ Gallery sharing between organizations not implemented
- ❌ README notes \"Not implemented yet\"

## Planned Features
- Photo galleries for events
- Gallery sharing across organizations
- Attendee photo uploads
- Photo moderation/approval system

## Implementation Plan
1. Complete Gallery controller with CRUD operations
2. Add gallery views and UI
3. Implement photo upload and display for attendees
4. Add photo moderation interface for organizers
5. Implement cross-organization gallery sharing (if needed)
6. Add tests for gallery functionality

## Files to Update
- \`app/controllers/dashboard/galleries_controller.rb\` - Expand functionality
- Create gallery views in \`app/views/dashboard/galleries/\`
- Update \`app/models/gallery.rb\` with additional methods
- Add attendee photo upload views
- Add tests

## Priority
Medium - Feature completion"

# Feature 4: Post-Event Survey System
echo "Creating issue 4: Implement Post-Event Survey and Feedback System..."
gh issue create --repo "$REPO" \
    --title "Implement Post-Event Survey and Feedback System" \
    --label "enhancement,feature,medium-priority" \
    --body "## Description
Add a comprehensive feedback system to collect post-event surveys from attendees and analyze responses.

## Current State
- ❌ No survey models exist
- ❌ No feedback collection mechanism
- ✅ Messaging system exists (could be extended)

## Planned Features
1. Survey builder for organizers
   - Multiple question types (text, multiple choice, rating, etc.)
   - Optional/required questions
   - Custom survey templates

2. Attendee survey submission
   - Post-event survey link/notification
   - Anonymous or identified responses
   - Mobile-friendly form

3. Survey analysis
   - Response aggregation
   - Visualization (charts, graphs)
   - Export to CSV/PDF
   - Sentiment analysis (optional)

## Implementation Plan
1. Create models: \`Survey\`, \`SurveyQuestion\`, \`SurveyResponse\`
2. Build survey builder interface for organizers
3. Create attendee survey submission flow
4. Add email notification for survey availability
5. Build analytics dashboard for survey results
6. Add tests for all components

## Priority
Medium - Valuable for event improvement"

# Feature 5: Analytics Dashboard
echo "Creating issue 5: Build Analytics and Reporting Dashboard..."
gh issue create --repo "$REPO" \
    --title "Build Analytics and Reporting Dashboard" \
    --label "enhancement,feature,analytics,medium-priority" \
    --body "## Description
Create a comprehensive analytics dashboard for organizers to track event performance, attendance patterns, and demographic insights.

## Current State
- ✅ Attendance data is collected
- ✅ Attendee information stored (age, dietary requirements, etc.)
- ❌ No analytics aggregation
- ❌ No visualization of data
- ❌ No demographic analysis
- ❌ No export functionality

## Planned Analytics Features
1. **Attendance Metrics**
   - Check-in rate (signed_in / total registered)
   - No-show rate
   - Sign-out patterns
   - Peak attendance times

2. **Demographic Analysis**
   - Age distribution
   - Dietary requirement breakdown
   - Geographic distribution

3. **Event Performance**
   - Application to attendance ratio
   - Capacity utilization
   - Historical trends across multiple events

4. **Visualizations**
   - Charts and graphs (using Chart.js or similar)
   - Exportable reports (PDF/CSV)
   - Real-time dashboard updates

## Implementation Plan
1. Create \`EventAnalytics\` service to calculate metrics
2. Build analytics dashboard view
3. Add charting library (Chart.js or ApexCharts)
4. Implement data export functionality (CSV/Excel/PDF)
5. Add caching for expensive calculations
6. Create analytics API endpoints for real-time updates
7. Add tests for analytics calculations

## Priority
Medium - Valuable insights for organizers"

# Feature 6: Time Tracking
echo "Creating issue 6: Implement Detailed Check-in/Check-out Time Tracking..."
gh issue create --repo "$REPO" \
    --title "Implement Detailed Check-in/Check-out Time Tracking" \
    --label "enhancement,feature,medium-priority,tracking" \
    --body "## Description
Currently, the system only stores the final attendance status (signed_in, signed_out, no_show, pending) but doesn't track the specific times when attendees checked in or out.

## Current State
- ✅ Attendance status is tracked
- ✅ QR code scanning works
- ❌ Check-in timestamp not stored
- ❌ Check-out timestamp not stored
- ❌ Can't analyze time spent at event
- ❌ Can't track late arrivals or early departures

## Planned Features
1. **Time Tracking**
   - Record check-in timestamp
   - Record check-out timestamp
   - Calculate duration of attendance
   - Track multiple check-ins/check-outs if needed

2. **Reporting**
   - Late arrival report
   - Early departure report
   - Average time spent at event
   - Peak attendance periods

## Implementation Plan
1. Add migration to add \`checked_in_at\` and \`checked_out_at\` columns to \`attendees\` table
2. Update QR code scanning logic to record timestamps
3. Add \`AttendanceHistory\` model for multiple check-ins (optional)
4. Update attendee show page to display check-in/check-out times
5. Add analytics for time-based metrics
6. Add tests for timestamp recording

## Priority
Medium - Enhances tracking capabilities"

# Feature 7: Export Functionality
echo "Creating issue 7: Export Attendance Data (CSV/Excel)..."
gh issue create --repo "$REPO" \
    --title "Export Attendance Data (CSV/Excel)" \
    --label "enhancement,feature,export,medium-priority" \
    --body "## Description
Allow organizers to export attendee lists and attendance data in common formats (CSV, Excel) for external analysis, reporting, and record-keeping.

## Current State
- ✅ Attendee data is stored
- ✅ Attendance tracking is functional
- ❌ No export functionality
- ❌ Data locked in the system

## Planned Export Features
1. **Attendee List Export**
   - All attendees with full details
   - Filtered by status (signed_in, no_show, etc.)
   - Custom field selection

2. **Attendance Report Export**
   - Check-in/check-out times (when implemented)
   - Attendance summary statistics
   - Waiver status
   - Dietary requirements

3. **Format Options**
   - CSV (simple, universal)
   - Excel/XLSX (formatted, multiple sheets)
   - PDF (printable report)

## Implementation Plan
1. Add \`Export\` button to attendees index page
2. Create \`ExportService\` to generate files
3. Use gems: \`csv\` (built-in), \`caxlsx\` or \`spreadsheet\` for Excel
4. Add controller action to generate and download exports
5. Add background job for large exports (email download link)
6. Add tests for export functionality

## Priority
Medium - Useful for reporting"

# Feature 8: Waitlist Management
echo "Creating issue 8: Add Waitlist Management for Events..."
gh issue create --repo "$REPO" \
    --title "Add Waitlist Management for Events" \
    --label "enhancement,feature,medium-priority" \
    --body "## Description
When events reach capacity, allow attendees to join a waitlist and automatically notify them when spots become available.

## Current State
- ✅ Events have capacity limits
- ✅ Application system exists
- ❌ No waitlist functionality
- ❌ Can't handle overbooking
- ❌ Manual management when spots open up

## Planned Features
1. **Waitlist Enrollment**
   - Automatic waitlist when event is full
   - Manual waitlist join option
   - Priority ordering (FIFO or custom)

2. **Automatic Notifications**
   - Email when spot becomes available
   - Time-limited offer (e.g., 24 hours to confirm)
   - Auto-promote from waitlist

3. **Organizer Controls**
   - View waitlist
   - Manually promote attendees
   - Set waitlist size limits
   - Configure auto-promotion rules

## Implementation Plan
1. Add \`waitlist_position\` column to \`attendees\` table
2. Create \`waitlist_status\` enum (waiting, offered, expired, declined)
3. Add background job to handle spot availability
4. Create waitlist promotion service
5. Add email notifications for waitlist updates
6. Build organizer waitlist management interface
7. Add tests for waitlist logic

## Priority
Medium - Nice to have feature"

# Feature 9: Calendar Integration
echo "Creating issue 9: Calendar Integration (iCal/ICS Export)..."
gh issue create --repo "$REPO" \
    --title "Calendar Integration (iCal/ICS Export)" \
    --label "enhancement,feature,low-priority" \
    --body "## Description
Allow attendees and organizers to add events to their personal calendars via iCal/ICS file downloads.

## Implementation Plan
1. Add gem \`icalendar\` to Gemfile
2. Create service to generate ICS files
3. Add download link to event pages
4. Include all event details (location, time, description)

## Files to Update
- Create \`app/services/calendar_export_service.rb\`
- Add route and controller action for ICS download
- Update event views with calendar export buttons

## Priority
Low - Nice to have"

# Feature 10: Ticket/Badge Generation
echo "Creating issue 10: Ticket/Badge Generation System..."
gh issue create --repo "$REPO" \
    --title "Ticket/Badge Generation System" \
    --label "enhancement,feature,low-priority" \
    --body "## Description
Generate printable tickets or badges for attendees with QR codes, event info, and attendee details.

## Planned Features
1. PDF ticket generation with QR code
2. Badge templates (name badges for printing)
3. Bulk generation for all attendees
4. Custom branding per organization

## Implementation Plan
1. Extend \`SignedWaiverGenerator\` service or create new \`TicketGenerator\`
2. Design ticket/badge templates
3. Add download buttons to attendee portal and dashboard
4. Support bulk generation as ZIP file

## Files to Update
- Create \`app/services/ticket_generator.rb\`
- Add controller actions for ticket downloads
- Design PDF templates using Prawn

## Priority
Low - Enhancement"

echo ""
echo "✅ All issues created successfully!"
echo "View issues at: https://github.com/$REPO/issues"
