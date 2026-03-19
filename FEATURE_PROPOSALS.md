# Feature Proposals for Eventful

This document contains comprehensive feature proposals based on analysis of the Eventful codebase. Each feature includes detailed implementation plans, affected files, and priority levels.

## Table of Contents
1. [High Priority Features](#high-priority-features)
2. [Medium Priority Features](#medium-priority-features)
3. [Lower Priority Features](#lower-priority-features)

---

## High Priority Features

### 1. Complete Role-Based Permission System

**Status:** Partially Implemented

**Description:**
The role-based permission system is partially implemented but not fully enforced across the application. Models exist (`OrganisationRole`, `RolePermission`) but permissions are rarely checked in controllers.

**Current State:**
- ✅ Models created (OrganisationRole, RolePermission)
- ✅ HABTM relationships established
- ✅ Permissions created during role creation
- ❌ Permission enforcement in controllers is incomplete
- ❌ Admin/member role distinction not consistently applied

**Implementation Plan:**
1. Create a permission checking service/concern
2. Add `before_action` filters to controllers to enforce permissions
3. Update all admin actions to check for appropriate permissions
4. Add tests for permission enforcement
5. Document the permission system

**Files to Update:**
- `app/controllers/application_controller.rb` - Add permission checking methods
- `app/controllers/dashboard/*` - Add permission checks
- Create `app/services/permission_checker.rb` or similar
- Add tests in `test/controllers/*`

**Related Models:**
- `app/models/organisation_role.rb`
- `app/models/role_permission.rb`

**Priority:** High - Security and access control issue

**Labels:** enhancement, security, high-priority

---

### 2. Add Event Reminder and Notification System

**Status:** Not Implemented

**Description:**
Implement automated notifications to keep attendees informed about upcoming events, schedule changes, and important deadlines.

**Current State:**
- ✅ Email infrastructure exists (ActionMailer, multiple mailers)
- ✅ Event model tracks dates and times
- ❌ No automated reminder system
- ❌ No schedule change notifications
- ❌ No application deadline reminders

**Planned Notifications:**
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

**Implementation Plan:**
1. Create `EventNotification` model to track notification preferences
2. Add background jobs for scheduled reminders
3. Create email templates for each notification type
4. Add preference controls for attendees (opt-in/opt-out)
5. Add organizer controls to customize notification timing
6. Implement job scheduling (using Solid Queue)
7. Add tests for notification delivery

**New Models/Jobs Needed:**
```ruby
EventNotification
  - belongs_to :event
  - notification_type, send_at, sent_at

Jobs:
  - EventReminderJob
  - ScheduleChangeNotificationJob
  - ApplicationDeadlineReminderJob
```

**Files to Update:**
- Create new mailer methods in `app/mailers/event_mailer.rb`
- Create background jobs in `app/jobs/`
- Add notification preferences to Event model
- Update event forms to include notification settings

**Priority:** High - Improves attendee experience

**Labels:** enhancement, feature, high-priority, notifications

---

## Medium Priority Features

### 3. Complete Gallery System Implementation

**Status:** Minimally Implemented

**Description:**
The Gallery system was planned but is minimally implemented. Models exist but functionality is limited compared to the original specification.

**Current State:**
- ✅ Gallery model created
- ✅ Photo model created with Active Storage
- ✅ Photos can be associated with events and attendees
- ❌ Gallery integration is minimal
- ❌ Gallery sharing between organizations not implemented
- ❌ README notes "Not implemented yet"

**Planned Features (from Planning.md):**
- Photo galleries for events
- Gallery sharing across organizations
- Attendee photo uploads
- Photo moderation/approval system

**Implementation Plan:**
1. Complete Gallery controller with CRUD operations
2. Add gallery views and UI
3. Implement photo upload and display for attendees
4. Add photo moderation interface for organizers
5. Implement cross-organization gallery sharing (if needed)
6. Add tests for gallery functionality

**Files to Update:**
- `app/controllers/dashboard/galleries_controller.rb` - Expand functionality
- Create gallery views in `app/views/dashboard/galleries/`
- Update `app/models/gallery.rb` with additional methods
- Add attendee photo upload views
- Add tests

**Related Files:**
- `app/models/gallery.rb`
- `app/models/photo.rb`
- `db/migrate/*_create_galleries.rb`

**Priority:** Medium - Feature completion

**Labels:** enhancement, feature, medium-priority

---

### 4. Implement Post-Event Survey and Feedback System

**Status:** Not Implemented

**Description:**
Add a comprehensive feedback system to collect post-event surveys from attendees and analyze responses.

**Current State:**
- ❌ No survey models exist
- ❌ No feedback collection mechanism
- ✅ Messaging system exists (could be extended)

**Planned Features:**
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

**Implementation Plan:**
1. Create models: `Survey`, `SurveyQuestion`, `SurveyResponse`
2. Build survey builder interface for organizers
3. Create attendee survey submission flow
4. Add email notification for survey availability
5. Build analytics dashboard for survey results
6. Add tests for all components

**New Models Needed:**
```ruby
Survey (belongs_to :event)
  - title, description, opens_at, closes_at

SurveyQuestion (belongs_to :survey)
  - question_text, question_type, required, options (JSON)

SurveyResponse (belongs_to :survey, :attendee)
  - answers (JSON), submitted_at
```

**Priority:** Medium - Valuable for event improvement

**Labels:** enhancement, feature, medium-priority

---

### 5. Build Analytics and Reporting Dashboard

**Status:** Not Implemented

**Description:**
Create a comprehensive analytics dashboard for organizers to track event performance, attendance patterns, and demographic insights.

**Current State:**
- ✅ Attendance data is collected
- ✅ Attendee information stored (age, dietary requirements, etc.)
- ❌ No analytics aggregation
- ❌ No visualization of data
- ❌ No demographic analysis
- ❌ No export functionality

**Planned Analytics Features:**
1. **Attendance Metrics**
   - Check-in rate (signed_in / total registered)
   - No-show rate
   - Sign-out patterns
   - Peak attendance times

2. **Demographic Analysis**
   - Age distribution
   - Dietary requirement breakdown
   - Geographic distribution (if location data available)

3. **Event Performance**
   - Application to attendance ratio
   - Capacity utilization
   - Historical trends across multiple events

4. **Visualizations**
   - Charts and graphs (using Chart.js or similar)
   - Exportable reports (PDF/CSV)
   - Real-time dashboard updates

**Implementation Plan:**
1. Create `EventAnalytics` service to calculate metrics
2. Build analytics dashboard view
3. Add charting library (Chart.js or ApexCharts)
4. Implement data export functionality (CSV/Excel/PDF)
5. Add caching for expensive calculations
6. Create analytics API endpoints for real-time updates
7. Add tests for analytics calculations

**New Service Classes:**
```ruby
app/services/event_analytics.rb
  - calculate_attendance_rate
  - calculate_demographics
  - generate_export_data

app/services/report_generator.rb
  - generate_pdf_report
  - generate_csv_export
```

**Files to Update:**
- Create `app/controllers/dashboard/analytics_controller.rb`
- Create views in `app/views/dashboard/analytics/`
- Add JavaScript for charts in `app/javascript/controllers/`
- Update navigation to include analytics link

**Priority:** Medium - Valuable insights for organizers

**Labels:** enhancement, feature, analytics, medium-priority

---

### 6. Implement Detailed Check-in/Check-out Time Tracking

**Status:** Partially Implemented

**Description:**
Currently, the system only stores the final attendance status (signed_in, signed_out, no_show, pending) but doesn't track the specific times when attendees checked in or out.

**Current State:**
- ✅ Attendance status is tracked
- ✅ QR code scanning works
- ❌ Check-in timestamp not stored
- ❌ Check-out timestamp not stored
- ❌ Can't analyze time spent at event
- ❌ Can't track late arrivals or early departures

**Planned Features:**
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

3. **Attendee History**
   - Show attendees their attendance history
   - Total time spent across events
   - Attendance patterns

**Implementation Plan:**
1. Add migration to add `checked_in_at` and `checked_out_at` columns to `attendees` table
2. Update QR code scanning logic to record timestamps
3. Add `AttendanceHistory` model for multiple check-ins (optional)
4. Update attendee show page to display check-in/check-out times
5. Add analytics for time-based metrics
6. Add tests for timestamp recording

**Database Changes:**
```ruby
add_column :attendees, :checked_in_at, :datetime
add_column :attendees, :checked_out_at, :datetime

# Optional: For multiple check-ins
create_table :attendance_logs do |t|
  t.references :attendee, null: false
  t.string :action # 'check_in' or 'check_out'
  t.datetime :timestamp
  t.timestamps
end
```

**Files to Update:**
- `db/migrate/*_add_timestamps_to_attendees.rb` (new migration)
- `app/controllers/dashboard/events_controller.rb` - Update `scan` action
- `app/models/attendee.rb` - Add time calculation methods
- `app/views/dashboard/attendees/show.html.erb` - Display timestamps
- Add tests

**Priority:** Medium - Enhances tracking capabilities

**Labels:** enhancement, feature, medium-priority, tracking

---

### 7. Export Attendance Data (CSV/Excel)

**Status:** Not Implemented

**Description:**
Allow organizers to export attendee lists and attendance data in common formats (CSV, Excel) for external analysis, reporting, and record-keeping.

**Current State:**
- ✅ Attendee data is stored
- ✅ Attendance tracking is functional
- ❌ No export functionality
- ❌ Data locked in the system

**Planned Export Features:**
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

4. **Export Controls**
   - Select specific events or date ranges
   - Filter by organization
   - Include/exclude sensitive data (dietary info, etc.)

**Implementation Plan:**
1. Add `Export` button to attendees index page
2. Create `ExportService` to generate files
3. Use gems: `csv` (built-in), `caxlsx` or `spreadsheet` for Excel
4. Add controller action to generate and download exports
5. Add background job for large exports (email download link)
6. Add tests for export functionality

**New Services/Controllers:**
```ruby
app/services/attendee_export_service.rb
  - to_csv
  - to_xlsx
  - to_pdf

app/controllers/dashboard/exports_controller.rb
  - create
  - download
```

**Dependencies:**
```ruby
# Add to Gemfile
gem 'caxlsx'
gem 'caxlsx_rails'
```

**Files to Update:**
- Create `app/services/attendee_export_service.rb`
- Create `app/controllers/dashboard/exports_controller.rb`
- Add export button to `app/views/dashboard/attendees/index.html.erb`
- Update routes
- Add tests

**Priority:** Medium - Useful for reporting

**Labels:** enhancement, feature, export, medium-priority

---

### 8. Add Waitlist Management for Events

**Status:** Not Implemented

**Description:**
When events reach capacity, allow attendees to join a waitlist and automatically notify them when spots become available.

**Current State:**
- ✅ Events have capacity limits
- ✅ Application system exists
- ❌ No waitlist functionality
- ❌ Can't handle overbooking
- ❌ Manual management when spots open up

**Planned Features:**
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

4. **Attendee Experience**
   - Waitlist position visibility
   - Opt-out from waitlist
   - Notification preferences

**Implementation Plan:**
1. Add `waitlist_position` column to `attendees` table
2. Create `waitlist_status` enum (waiting, offered, expired, declined)
3. Add background job to handle spot availability
4. Create waitlist promotion service
5. Add email notifications for waitlist updates
6. Build organizer waitlist management interface
7. Add tests for waitlist logic

**Database Changes:**
```ruby
add_column :attendees, :waitlist_position, :integer
add_column :attendees, :waitlist_status, :string
add_column :attendees, :waitlist_offer_expires_at, :datetime
```

**New Jobs/Services:**
```ruby
app/jobs/waitlist_promotion_job.rb
app/services/waitlist_manager.rb
  - promote_next_from_waitlist
  - expire_waitlist_offers
  - calculate_positions
```

**Files to Update:**
- Add migration for waitlist columns
- Update `app/models/attendee.rb` with waitlist logic
- Create `app/services/waitlist_manager.rb`
- Add waitlist views to dashboard
- Update `app/mailers/attendee_mailer.rb` for waitlist emails
- Add tests

**Priority:** Medium - Nice to have feature

**Labels:** enhancement, feature, medium-priority

---

## Lower Priority Features

### 9. Calendar Integration (iCal/ICS Export)

**Status:** Not Implemented

**Description:**
Allow attendees and organizers to add events to their personal calendars via iCal/ICS file downloads.

**Implementation Plan:**
1. Add gem `icalendar` to Gemfile
2. Create service to generate ICS files
3. Add download link to event pages
4. Include all event details (location, time, description)

**Files to Update:**
- Create `app/services/calendar_export_service.rb`
- Add route and controller action for ICS download
- Update event views with calendar export buttons

**Priority:** Low - Nice to have

**Labels:** enhancement, feature, low-priority

---

### 10. Ticket/Badge Generation System

**Status:** Not Implemented

**Description:**
Generate printable tickets or badges for attendees with QR codes, event info, and attendee details.

**Planned Features:**
1. PDF ticket generation with QR code
2. Badge templates (name badges for printing)
3. Bulk generation for all attendees
4. Custom branding per organization

**Implementation Plan:**
1. Extend `SignedWaiverGenerator` service or create new `TicketGenerator`
2. Design ticket/badge templates
3. Add download buttons to attendee portal and dashboard
4. Support bulk generation as ZIP file

**Files to Update:**
- Create `app/services/ticket_generator.rb`
- Add controller actions for ticket downloads
- Design PDF templates using Prawn

**Priority:** Low - Enhancement

**Labels:** enhancement, feature, low-priority

---

### 11. Multi-Event Series Management

**Status:** Not Implemented

**Description:**
Allow organizers to create event series (recurring events) and manage them as a group.

**Planned Features:**
1. Create event templates
2. Clone events with modifications
3. Series management dashboard
4. Bulk operations on series

**Implementation Plan:**
1. Add `event_series_id` to events table
2. Create `EventSeries` model
3. Add cloning functionality
4. Build series management interface

**Files to Update:**
- Add migration for event series
- Create `app/models/event_series.rb`
- Update event forms to include series options
- Add series management views

**Priority:** Low - Advanced feature

**Labels:** enhancement, feature, low-priority

---

### 12. Enhanced Messaging with Read Receipts

**Status:** Partially Implemented

**Description:**
Add read receipts, typing indicators, and other chat-like features to the messaging system.

**Current State:**
- ✅ Basic messaging works
- ❌ No read receipts
- ❌ No typing indicators
- ❌ No real-time updates (Solid Cable exists but not used)

**Implementation Plan:**
1. Add `read_at` timestamp to messages
2. Implement Solid Cable for real-time updates
3. Add typing indicator using Stimulus
4. Show unread message counts

**Files to Update:**
- Add migration for `read_at` column
- Update `app/models/message.rb`
- Create Cable channels for real-time messaging
- Add JavaScript for typing indicators

**Priority:** Low - Enhancement

**Labels:** enhancement, feature, low-priority, real-time

---

### 13. Two-Factor Authentication for Organizers

**Status:** Not Implemented

**Description:**
Add 2FA for organizer accounts to improve security.

**Implementation Plan:**
1. Add gem `devise-two-factor` or similar
2. Add TOTP secret to users table
3. Build 2FA setup and verification flow
4. Add backup codes

**Files to Update:**
- Add migration for 2FA columns
- Update `app/models/user.rb`
- Create 2FA setup controllers and views
- Update authentication flow

**Priority:** Low - Security enhancement (OAuth provides some protection)

**Labels:** enhancement, security, low-priority

---

### 14. Audit Logging for Administrative Actions

**Status:** Not Implemented

**Description:**
Track all administrative actions for compliance and debugging.

**Implementation Plan:**
1. Add gem `paper_trail` or `audited`
2. Enable auditing on sensitive models
3. Create audit log viewer for admins
4. Add filters and search

**Files to Update:**
- Add auditing gem to Gemfile
- Enable auditing on models
- Create audit log controller and views
- Add admin-only access controls

**Priority:** Low - Compliance/debugging feature

**Labels:** enhancement, audit, low-priority

---

### 15. Bulk Attendee Import

**Status:** Not Implemented

**Description:**
Allow organizers to import attendee lists from CSV files for pre-registration.

**Implementation Plan:**
1. Create CSV upload form
2. Parse and validate CSV data
3. Create attendees in bulk
4. Show import results with errors
5. Send email notifications to imported attendees

**Files to Update:**
- Create `app/services/attendee_import_service.rb`
- Add import controller action
- Create import form view
- Add background job for large imports

**Priority:** Low - Administrative convenience

**Labels:** enhancement, feature, low-priority

---

## Implementation Notes

### General Recommendations
1. **Phase Implementation**: Tackle high-priority features first
2. **Testing**: Add comprehensive tests for each feature
3. **Documentation**: Update README.md as features are added
4. **Migrations**: Follow Rails 8.1 migration patterns (ActiveRecord::Migration[8.1])
5. **Background Jobs**: Use Solid Queue for async processing
6. **Caching**: Use Solid Cache for expensive operations
7. **Real-time**: Leverage Solid Cable for live updates where appropriate

### Architecture Considerations
- Maintain RESTful controller patterns
- Use services for complex business logic
- Keep views simple with helpers
- Follow existing naming conventions (including preserved typos like `reciever`)
- Add enum prefixes to avoid method collisions
- Use `dependent: :destroy` or `:nullify` appropriately on associations

### Security Considerations
- Validate all user inputs
- Use strong parameters in controllers
- Implement proper authorization checks
- Sanitize file uploads
- Rate limit public endpoints
- Secure sensitive data (waivers, personal info)

---

## How to Use This Document

Each feature proposal can be converted into a GitHub issue by:
1. Using the feature title as the issue title
2. Copying the description, current state, and implementation plan as the issue body
3. Adding the suggested labels
4. Assigning appropriate priority

For manual issue creation, visit: https://github.com/Acidicts/Eventful/issues/new

---

**Document Created:** 2026-03-19
**Repository:** Acidicts/Eventful
**Analysis Method:** Comprehensive codebase exploration and pattern analysis
