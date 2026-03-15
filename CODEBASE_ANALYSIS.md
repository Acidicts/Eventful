# Eventful Rails Application - Comprehensive Codebase Analysis

## Executive Summary

**Eventful** is a comprehensive event management system built with Ruby on Rails 8.1. It enables organizations to create events, manage attendees, collect waivers, track attendance via QR codes, and facilitate communication between organizers and attendees. The application uses Hack Club's OAuth provider for user authentication and includes advanced features like PDF waiver generation, QR code scanning, location autocomplete, and a dedicated attendee portal.

---

## What the Application Does

Eventful is an **event management and attendance tracking platform** that serves the Hack Club ecosystem. It provides:

1. **Event Management** - Create, edit, and manage events with detailed information
2. **Attendance Tracking** - QR code-based check-in/check-out with real-time scanning
3. **Waiver Management** - Digital waiver signing with PDF generation and signature capture
4. **Attendee Portal** - Self-service portal for attendees to view QR codes, sign waivers, and communicate
5. **Organization Management** - Multi-organization support with role-based access control
6. **Messaging System** - Facilitate communication between attendees and event organizers
7. **Gallery Management** - Share event photos organized in galleries

---

## Core Architecture

### Framework & Stack
- **Framework**: Rails 8.1.2
- **Database**: SQLite (dev/test), PostgreSQL (production-ready)
- **Frontend**: Hotwire (Turbo + Stimulus), vanilla JavaScript
- **Authentication**: OmniAuth with custom Hack Club OAuth strategy
- **File Storage**: Active Storage (local in dev, configurable in prod)
- **Task Queue**: Solid Queue
- **Cache**: Solid Cache
- **Real-time**: Solid Cable (Action Cable wrapper)
- **Deployment**: Kamal + Docker + Thruster

### Key Dependencies
- **QR Codes**: `rqrcode` (generation), `zxing` (decoding)
- **PDF Handling**: `combine_pdf`, `prawn` (for waiver generation)
- **HTTP Requests**: `faraday` (for OAuth token refresh)
- **Image Processing**: `image_processing`, MiniMagick (for image variants)
- **Markdown**: `redcarpet` + `sanitize` (for HTML content rendering)
- **Testing**: Capybara, Selenium WebDriver

---

## Data Models & Relationships

### Models Overview

#### 1. **User**
Represents authenticated users (primarily event organizers and administrators).

**Attributes:**
- OAuth credentials: `provider`, `uid`, `email`, `name`, `slack_id`, `verification_status`
- Tokens: `access_token`, `refresh_token`, `expires_at`
- Roles: `role` (member/admin/superadmin), `organisation_role` (member/admin)

**Relationships:**
- `belongs_to :organisation` (optional primary org)
- `has_many :organisations` (all orgs user is member of)
- `has_many :announcements` (as creator)
- `has_many :messages` (as answerer)

**Key Methods:**
- `from_omniauth(auth)` - Creates/updates user from OAuth response
- `refresh_access_token!` - Rotates OAuth tokens when expired
- `hackclub_get(path)` - Makes authenticated API calls to Hack Club

---

#### 2. **Organisation**
Represents an organization that creates and manages events.

**Attributes:**
- `name`, `description`, `img` (logo URL)
- `user_id` (owner), `signing_user_id` (waiver signer)
- `self_found` (boolean flag), `join_requirements` (auto-add rule)
- `nil_org` (placeholder org), `eventful_branding` (display Eventful branding)

**Relationships:**
- `belongs_to :user` (owner)
- `has_many :users` (members)
- `has_many :events`, `has_many :announcements`, `has_many :galleries`
- `has_many :attendees` (through events)
- `belongs_to :signing_user` (User who signs waivers)

**Key Features:**
- Organization-scoped member access (via `for_user` scope)
- Auto-add users based on OAuth provider (e.g., all Hack Club members)
- Signing user management for waiver authentication

---

#### 3. **Event**
Represents a specific event that attendees can join.

**Attributes:**
- `name`, `description`, `location`, `capacity`
- `start_date`, `end_date`, `finished` (status)
- `apply_token` (unique public URL for applications)
- `organiser_id` (User running the event)
- `organisation_id` (belongs to an org)
- `applied` (count of applications)

**Relationships:**
- `has_many :attendees` (all signups)
- `has_many :announcements`
- `belongs_to :organiser` (User)
- `belongs_to :organisation`

**File Attachments:**
- `has_one_attached :waiver` (PDF or TXT template)
- `has_one_attached :icon` (event image)

**Validations:**
- Waiver must be PDF/TXT, max 5MB
- Icon must be PNG/JPEG/GIF, max 2MB
- End date must be after start date

**Key Methods:**
- `finished?` - Checks if event has ended
- `to_param` - Returns apply_token for public URLs
- `generate_apply_token` - Creates secret token for public event access

---

#### 4. **Attendee**
Represents a person who has applied to or attended an event.

**Attributes:**
- Personal: `name`, `email`, `age`, `under_18`, `allergies`
- Dietary: `diet` (enum: none/pescitarian/vegetarian/vegan/other), `other_diet`
- Status: `status` (pending/approved/denied), `attendance` (pending/signed_in/signed_out/no_show)
- Waiver: `waiver_signed`, `waiver_signed_at`, `waiver_signature`, `parent_signature`
- Technical: `code` (unique QR code identifier), `ip` (registration IP)
- `event_id` (belongs to event)

**Enums:**
```ruby
enum :attendance, { pending: 0, signed_in: 1, signed_out: 2, no_show: 3 }
enum :status, { pending: 0, approved: 1, denied: 2 }
enum :diet, { none: 0, pescitarian: 1, vegetarian: 2, vegan: 3, other: 4 }
```

**Relationships:**
- `belongs_to :event`
- `has_one_attached :signed_waiver` (PDF/TXT copy)

**Key Validations:**
- Event capacity not exceeded
- IP address not reused (max 3 per event)
- Unique identifier code (auto-generated with "!" prefix)
- Waiver: requires signature OR uploaded file
- Under-18: requires parent signature if waiving

**File Attachments:**
- `has_one_attached :signed_waiver` (uploaded or generated PDF)

---

#### 5. **Announcement**
Event or organization-wide announcements/updates.

**Attributes:**
- `content` (markdown/rich text)
- `public` (boolean - visible to public or internal only)
- `creator_id` (User)
- `event_id` (optional - event-specific)
- `organisation_id`

**Relationships:**
- `belongs_to :creator` (User)
- `belongs_to :event` (optional)
- `belongs_to :organisation`

---

#### 6. **Message**
Communication system allowing attendees to contact organizers.

**Attributes:**
- `message` (content)
- `answer` (organizer response)
- `read` (boolean)
- `sender_id` (Attendee)
- `reciever_id` + `reciever_type` (polymorphic: User or Attendee)
- `answerer_id` (User who responded)

**Relationships:**
- `belongs_to :sender` (Attendee)
- `belongs_to :reciever` (polymorphic - User or Attendee)
- `belongs_to :answerer` (User, optional)

**Use Case**: Attendees ask questions → organizer or event organiser responds

---

#### 7. **Gallery & GalleryImage**
Photo galleries for organizations to share event photos.

**Gallery:**
- `organisation_id`
- `public` (boolean)

**GalleryImage:**
- `attendee_id` (who uploaded/is in photo)
- `gallery_id`
- `caption` (optional)
- `day_from` (date taken)

---

### Entity Relationship Diagram

```
User (OAuth authenticated)
├── owns → Organisation (one-to-many)
├── is_member_of → Organisation (many-to-many via join table)
├── creates → Announcement
├── signs → Waiver (as signing_user)
└── answers → Message

Organisation
├── has_many → Event
├── has_many → User (members)
├── has_many → Announcement
├── has_many → Gallery
└── has_many → Attendee (through events)

Event
├── belongs_to → Organisation
├── belongs_to → User (organiser)
├── has_many → Attendee
├── has_many → Announcement
├── has_attached → waiver (PDF/TXT)
└── has_attached → icon (image)

Attendee
├── belongs_to → Event
├── has_attached → signed_waiver (PDF/TXT)
└── has_many → Message (sender)

Message
├── sender → Attendee
├── reciever → (User OR Attendee, polymorphic)
└── answerer → User (optional)

Gallery
├── belongs_to → Organisation
└── has_many → GalleryImage

GalleryImage
├── belongs_to → Gallery
└── belongs_to → Attendee
```

---

## Major Features & Functionality

### 1. Authentication & Authorization

#### OAuth Integration (Hack Club)
- **Provider**: Hack Club's custom OAuth server
- **Scopes**: `openid profile email slack_id verification_status offline_access`
- **Token Management**: Automatic token refresh via refresh_token
- **Custom Strategy**: `lib/omniauth/strategies/hackclub.rb`

#### Role-Based Access Control
- **Global Roles** (User.role):
  - `member` - Regular user
  - `admin` - System administrator
  - `superadmin` - Super administrator

- **Organization Roles** (User.organisation_role):
  - `member` - Regular organization member
  - `admin` - Organization admin

#### Session Management
- OAuth via `SessionsController#create`
- Token refresh on API calls (automatic)
- Support for Hack Club API requests via `User#hackclub_get`

---

### 2. Event Management

#### Event CRUD
- **Create**: New events by organization members
- **Read**: View event details, attendee lists, announcements
- **Update**: Edit event details, capacity, location, dates
- **Delete**: Remove events (cascades to attendees and announcements)

#### Event Features
- **Public Apply Token**: Unique alphanumeric token for public event signup
- **Capacity Management**: Track attendee limit
- **Date Range**: Start/end times for event scheduling
- **Location**: With autocomplete (Google Maps Places API or Nominatim/OpenStreetMap)
- **Event Status**: "Finished" flag or automatic detection (end_date < now)
- **Icon**: Custom event image (PNG/JPEG/GIF)
- **Description**: Event details in markdown

#### Location Autocomplete
- **Google Maps Places API** (if API key configured)
  - Uses new HTTP POST endpoint `/v1/places:autocomplete`
  - Stimulus controller debounces requests
  - Configurable via `GOOGLE_MAPS_API_KEY` env var
  
- **OpenStreetMap/Nominatim** (free fallback)
  - Automatic when no Google key
  - Zero cost, no auth required

---

### 3. Attendee Management & QR Codes

#### Attendee Application
- **Public Apply Flow**: Via public event token
- **Application Form Fields**:
  - Name, email, age, dietary requirements, allergies
  - Approval status (pending/approved/denied)
  - IP-based duplicate prevention (max 3 per IP per event)

#### QR Code System
- **Generation**: `QrCodeGenerator.generate(code)`
  - SVG output (scalable, embeddable)
  - PNG output (Base64-encoded data URI)
  - Configurable module size

- **Storage**: Embedded in each attendee record (code = "!" + hex prefix)
- **Use Cases**:
  - Attendee portal displays personal QR code
  - Email delivery of QR code
  - Public QR code viewing via `/qrcode/:code` route

#### Attendance Tracking
- **States**: pending → signed_in → signed_out (or no_show)
- **QR Scanner Interface**: 
  - Real-time scan processing
  - Operations: sign_in, sign_out, get_info
  - Returns attendee status and confirmation

#### QR Code Decoding
- **Server-Side**: `QrCodeDecoder.decode_file(path)`, `.decode_blob(data)`
- **Technology**: ZXing (Java-based, lazy-loaded)
- **Client-Side**: Optional JavaScript-based scanning

---

### 4. Waiver Management

#### Waiver Signing Process
1. **Template Upload**: Organizer uploads PDF or TXT waiver to event
2. **Attendee Signs**: Via attendee portal (/attendee-portal/waiver)
3. **Signature Capture**: Typed signature or PDF upload
4. **Age-Specific Rules**: U18 requires parent signature (stored separately)
5. **PDF Generation**: Auto-generate signed copy if only signature provided

#### Waiver Features
- **Storage**: Active Storage (local or configurable backend)
- **Formats**: PDF (template) or plain text
- **Signed Copy**: Generated via `SignedWaiverGenerator`
  - Uses Prawn for PDF creation
  - Overlays signature text on original
  - Stamped on all pages

#### Waiver Validations
- Template max 5MB
- File format: PDF or TXT only
- Requires signature OR file upload
- Parent signature required for U18 signers

---

### 5. Attendee Portal

A self-service portal for attendees (code-based login, no account needed).

#### Routes
- `/attendee-portal/login` - Code entry form
- `/attendee-portal/` - Dashboard (profile view)
- `/attendee-portal/qr-code` - Display personal QR
- `/attendee-portal/waiver` - Sign waiver
- `/attendee-portal/contact` - Message organizer
- `/attendee-portal/logout`

#### Features
- **Code-Based Auth**: No account creation, just unique code
- **Profile**: View/edit attendee information
- **QR Display**: Printable/scannable personal QR code
- **Waiver Signing**: Type signature or upload PDF
- **Messaging**: Contact event organizer or staff
- **Email Integration**: QR codes sent via email

---

### 6. Messaging System

#### Message Flow
- **Sender**: Attendee
- **Recipients**: Event organizer or other attendees
- **Use Case**: Q&A, requests, clarifications
- **Responses**: Organizer (User) can reply to messages
- **Status**: Read flag for tracking

#### Message Model
- Polymorphic receiver (User or Attendee)
- Optional answerer (User who responded)
- Content stored as text
- Used in attendee portal for post-event communication

---

### 7. Announcements

#### Event Announcements
- **Scope**: Organization or Event-specific
- **Visibility**:
  - Public: Visible to all (via announcements API route)
  - Internal: Visible only to org members
- **Content**: Markdown-supported
- **Creator**: Tracked (User)

#### Public Announcements Route
- `GET /events/:id/announcements` - Public endpoint for event announcements
- Filters for `public: true` only
- Ordered by creation date (most recent first)

---

### 8. Gallery Management

#### Gallery System
- **Organization-level** photo galleries
- **Images**: Uploaded by attendees
- **Metadata**: Caption, day_from (date taken)
- **Visibility**: Public/private galleries
- **Use**: Share event photos across organization

---

### 9. Communication & Notifications

#### Email (via ActionMailer)
- **AttendeeMailer**: Sends QR codes to attendees
- **System Mailer**: Base configuration
- Jobs tracked in Solid Queue

#### Announcements
- **Internal**: To organization members
- **Public**: Published announcements accessible via public routes

---

## API & Routes

### Public Routes (No Auth Required)
```
GET  /                          → HomeController#index
GET  /landing                   → HomeController#unregistered
GET  /landing/events            → HomeController#events
GET  /events/:id/announcements  → EventsController#announcements
GET  /:apply_token/apply        → EventsController#apply_by_token
POST /:apply_token/apply        → EventsController#apply_create
GET  /qrcode/:code              → QrCodesController#show (public QR display)
GET  /up                        → Rails health check
```

### Attendee Portal Routes (Code-based Auth)
```
GET    /attendee-portal/login      → Login form
POST   /attendee-portal/login      → Authenticate with code
GET    /attendee-portal/            → Dashboard
GET    /attendee-portal/qr-code    → View QR
GET    /attendee-portal/waiver     → Waiver form
PATCH  /attendee-portal/waiver     → Sign waiver
PATCH  /attendee-portal/           → Update profile
GET    /attendee-portal/contact    → Messaging
POST   /attendee-portal/contact    → Send message
DELETE /attendee-portal/logout     → Logout
```

### OAuth Routes
```
GET    /auth/hackclub/callback  → SessionsController#create
GET    /logout                  → SessionsController#destroy
DELETE /logout
```

### QR Code Tools
```
GET  /qr_code/new     → Form for generating QR
POST /qr_code         → Generate QR
GET  /qr_code/decode  → QR decoder form
```

### Organization Scoped Routes
```
resources :organisations, path: "org" do
  resources :events do
    # Nested event actions
    get    :attendees
    post   :send_qr_codes
    get    :apply
    post   :apply
    post   :scan                    → QR scan endpoint
    get    :actions/sign-in
    get    :actions/sign-out
    get    :actions/get-info
    
    # Attendee nested resources
    get    :attendee/:attendee_id               → View attendee
    patch  :attendee/:attendee_id               → Update attendee
    get    :attendee/:attendee_id/edit          → Edit form
    get    :attendee/:attendee_id/waiver        → View waiver
    delete :attendee/:attendee_id/waiver        → Delete waiver
  end
end

# Organization dashboard routes
member do
  get :dashboard
  get :dashboard/attendees
  get :dashboard/events
end
```

---

## File Structure

```
app/
├── controllers/
│   ├── application_controller.rb        (base controller)
│   ├── attendee_portal_controller.rb    (attendee self-service)
│   ├── events_controller.rb             (event CRUD + scanning)
│   ├── events/
│   │   └── attendees_controller.rb      (attendee management)
│   ├── organisations_controller.rb      (org CRUD)
│   ├── organisations/
│   │   └── dashboard_controller.rb      (org admin dashboard)
│   ├── qr_codes_controller.rb           (QR tools)
│   ├── home_controller.rb               (landing page)
│   ├── sessions_controller.rb           (OAuth)
│   └── icons_controller.rb              (dynamic SVG icons)
├── models/
│   ├── user.rb
│   ├── organisation.rb
│   ├── event.rb
│   ├── attendee.rb
│   ├── announcement.rb
│   ├── message.rb
│   ├── gallery.rb
│   ├── gallery_image.rb
│   └── concerns/
├── services/
│   ├── qr_code_generator.rb             (SVG/PNG QR generation)
│   ├── qr_code_decoder.rb               (ZXing-based decoding)
│   └── signed_waiver_generator.rb       (PDF signature overlay)
├── mailers/
│   ├── application_mailer.rb
│   └── attendee_mailer.rb               (QR code emails)
├── jobs/
│   └── application_job.rb
├── helpers/
│   ├── application_helper.rb
│   └── attendee_portal_helper.rb
├── views/
│   ├── attendee_portal/
│   ├── events/
│   ├── organisations/
│   └── shared/
├── assets/
│   ├── images/
│   ├── stylesheets/
│   └── javascript/
│       └── controllers/                 (Stimulus controllers)
├── javascript/
│   ├── application.js
│   └── controllers/
│       └── location_autocomplete_controller.js
└── form_builders/

config/
├── routes.rb                    (all routes defined)
├── environments/
├── initializers/
├── cable.yml                    (Action Cable)
├── queue.yml                    (Solid Queue)
├── cache.yml                    (Solid Cache)
├── storage.yml                  (Active Storage)
├── database.yml                 (DB config)
├── credentials.yml.enc          (encrypted secrets)
└── importmap.rb                 (JS import map)

db/
├── schema.rb                    (current DB schema)
├── seeds.rb
└── migrate/                     (migration history)

lib/
├── omniauth/
│   └── strategies/
│       └── hackclub.rb          (custom OAuth strategy)
└── custom_markdown_renderer.rb  (markdown processing)
```

---

## Integrations & External Services

### 1. **Hack Club OAuth**
- **Purpose**: User authentication
- **Info Captured**: Name, email, Slack ID, verification status
- **Tokens**: Access & refresh tokens stored for API calls
- **API Endpoint**: `https://auth.hackclub.com/api/v1/me`
- **Configuration**: `HACKCLUB_CLIENT_ID`, `HACKCLUB_CLIENT_SECRET`

### 2. **Google Maps Places API** (Optional)
- **Purpose**: Event location autocomplete
- **Endpoint**: `https://places.googleapis.com/v1/places:autocomplete`
- **Fallback**: OpenStreetMap/Nominatim (free)
- **Configuration**: `GOOGLE_MAPS_API_KEY`

### 3. **OpenStreetMap / Nominatim** (Always Available)
- **Purpose**: Location autocomplete (free fallback)
- **No Authentication**: Public API
- **Automatic Fallback**: Used when no Google key configured

### 4. **Image Processing**
- **Libraries**: MiniMagick (ImageMagick wrapper) or ruby-vips
- **Usage**: Generate image variants for event icons
- **Configuration**: Automatic detection, prefers MiniMagick in dev

### 5. **PDF Generation & Manipulation**
- **Libraries**: Prawn (PDF creation), CombinePDF (PDF merging)
- **Usage**: Generate signed waiver PDFs with signature overlays
- **Features**: Multi-page support, centered text placement

### 6. **QR Code Processing**
- **Generation**: rqrcode (SVG/PNG output)
- **Decoding**: zxing (Java-based, optional)
- **Use**: Attendance tracking via QR scanning

---

## User Roles & Permissions

### User Role Types (Global)
1. **member** - Regular user, can own/manage organizations
2. **admin** - View/manage all organizations, users
3. **superadmin** - Full system access

### Organization Role Types
1. **member** - Regular member, view events/data
2. **admin** - Full organization management

### Implicit Roles (by activity)
- **Event Organizer** - User who created/manages an event
- **Organization Owner** - User who created the organization
- **Attendee** - Non-authenticated person who signed up for event
- **Signing User** - Organization-designated person who signs waivers

### Access Patterns

**Admin/Superadmin**:
- View all organizations
- Create/manage users
- System-wide settings

**Organization Member**:
- Create/edit events within org
- View attendee lists
- Send messages to attendees
- View announcements

**Organization Admin**:
- Full org management
- Member management
- Settings configuration
- Waiver signing authority

**Event Organizer**:
- Full event management
- Attendee lookup and editing
- QR scanning operations
- Send messages to attendees

**Attendee**:
- View personal QR code
- Sign waiver
- View event details
- Send messages to organizer

---

## Key Business Logic

### 1. Event Application Flow
```
1. Organizer creates event with public apply_token
2. Person visits /APPLY_TOKEN/apply
3. Fills application form (name, email, age, diet, allergies)
4. System validates capacity, prevents IP duplicates
5. Attendee is created in pending status
6. Attendee receives QR code via email
7. Organizer approves/denies in dashboard
```

### 2. Attendance Tracking (QR Scan)
```
1. Event staff scans QR code at check-in
2. POST to /org/:org_id/events/:event_id/actions/scan
3. Payload: { code: "...", operation: "sign_in" }
4. Attendee lookup by code
5. Update attendance state (pending → signed_in)
6. Return confirmation message
```

### 3. Waiver Signing
```
1. Attendee visits /attendee-portal/waiver
2. Views event waiver template (PDF/TXT)
3. Types signature + parent signature (if U18)
4. System generates signed PDF (if signature only)
5. Attaches to attendee record
6. Updates waiver_signed & waiver_signed_at
7. Organizer can download for records
```

### 4. Token Refresh
```
1. User calls API method (hackclub_get, etc.)
2. Check if access_token expired (expires_at < now)
3. If expired, exchange refresh_token for new pair
4. Update user record with new token & expiry
5. Proceed with API call
```

### 5. Organization Auto-Add
```
1. Org has join_requirements (e.g., "omniauth hackclub")
2. User signs in via OAuth
3. SessionsController triggers org.auto_add_users
4. Matches user.provider to join_requirements
5. Adds matching users to org.users
```

---

## Deployment & Configuration

### Environment Setup
**Development**:
- SQLite database
- MiniMagick for images
- Lazy-loaded zxing (QR decoding)
- Dev Containers support

**Production**:
- PostgreSQL recommended
- Kamal orchestration
- Docker container
- Thruster (HTTP acceleration)

### Key Environment Variables
- `HACKCLUB_CLIENT_ID` - OAuth client ID
- `HACKCLUB_CLIENT_SECRET` - OAuth client secret
- `GOOGLE_MAPS_API_KEY` - Optional location autocomplete
- `RAILS_MASTER_KEY` - Rails credentials encryption key
- `DATABASE_URL` - PG connection (optional)

### Container Setup
- Ruby 3.4.8 slim image
- ImageMagick + libvips installed
- Boot optimized with Bootsnap
- Non-root user (rails:rails)

---

## Testing Infrastructure

### Test Stack
- **Capybara** - System/integration testing
- **Selenium WebDriver** - Browser automation
- **Security**: Brakeman (static analysis), bundler-audit (gem audit)
- **Style**: RuboCop Rails Omakase
- **OmniAuth Test Mode**: Full OAuth flow testing

### Database
- Separate test database (SQLite)
- Parallel test support (database pooling via SQLite replica)
- Schema loaded before test run

---

## Security Considerations

### Authentication
- OAuth tokens stored encrypted in credentials.yml.enc
- Refresh token rotation on each API call
- Session-based for user, code-based for attendees

### Data Protection
- IP address normalization & duplicate prevention
- Active Storage handles file security
- CSRF token verification on all state-changing requests
- Sanitized HTML in announcements (Redcarpet + Sanitize)

### File Upload Validations
- File type restrictions (PDF/TXT, PNG/JPEG/GIF)
- Size limits (5MB waivers, 2MB icons)
- Scanned for MIME type, not just extension

---

## Notable Architectural Patterns

### 1. **Stimulus Controllers**
- `LocationAutocompleteController` - Debounced API calls for location suggestions
- Real-time form enhancement

### 2. **Service Objects**
- `QrCodeGenerator` - Encapsulates generation logic
- `QrCodeDecoder` - Wraps ZXing dependency
- `SignedWaiverGenerator` - PDF generation with overlays

### 3. **Polymorphic Associations**
- `Message.reciever` - Can be User or Attendee
- Flexible recipient targeting

### 4. **Concerns** (app/models/concerns)
- Shared model behaviors documented but implementation details in concerns folder

### 5. **Nested Resources**
- Events nested under Organizations
- Attendees nested under Events
- Clear hierarchical routing

### 6. **OAuth Token Management**
- Automatic refresh on API calls
- Lazy loading of external dependencies (ZXing)

---

## Unimplemented/Future Features

From Planning.md, the following are planned but not yet implemented:

### Notifications
- [ ] Event announcements push
- [ ] Schedule reminders
- [ ] Application deadlines

### Feedback System
- [ ] Post-event surveys
- [ ] Feedback analytics
- [ ] Suggestion tracking

### Analytics
- [ ] Attendance rates
- [ ] Demographics analysis
- [ ] Event feedback reports

### Enhancements
- [ ] Phone number fields (optional)
- [ ] Past attendance history (check in/out times)
- [ ] Admin notification management

---

## Quick Reference: Key Files to Edit

| Feature | Files |
|---------|-------|
| Add OAuth scope | `lib/omniauth/strategies/hackclub.rb` |
| Event fields | `app/models/event.rb` + migration |
| Attendee fields | `app/models/attendee.rb` + schema |
| API endpoints | `config/routes.rb` + controller |
| Event form | Views under `app/views/events/` |
| Portal portal | `app/views/attendee_portal/` + `attendee_portal_controller.rb` |
| Emails | `app/mailers/attendee_mailer.rb` |
| QR generation | `app/services/qr_code_generator.rb` |
| Waiver logic | `app/services/signed_waiver_generator.rb` + `attendee_portal_controller` |
| Announcements | `app/models/announcement.rb` |
| Location search | `app/javascript/controllers/location_autocomplete_controller.js` |
| Dashboard | `app/controllers/organisations/dashboard_controller.rb` |

---

## Summary

Eventful is a sophisticated event management platform purpose-built for the Hack Club ecosystem. It seamlessly integrates OAuth authentication, advanced QR code scanning, digital waiver signing with PDF generation, and a comprehensive self-service attendee portal. The architecture follows Rails best practices with clear separation of concerns, organized routing, and flexible data models supporting multiple organizations, events, and user roles. The system is production-ready with Docker deployment, security hardening, and extensible design for future features like notifications and analytics.
