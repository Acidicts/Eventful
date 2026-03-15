# Eventful

A comprehensive event management and attendance tracking platform built for the Hack Club ecosystem. Eventful enables organizations to create events, collect attendee applications, manage digital waivers, track attendance in real-time via QR codes, and communicate with attendees through a self-service portal.

## 🌟 Key Features

### Event Management
- **Create & Manage Events** – detailed event information including dates, location, capacity, and custom metadata
- **Location Autocomplete** – powered by Google Maps API or free OpenStreetMap/Nominatim fallback
- **Event Icons** – visual representation of events with image upload support
- **Attendee Capacity Management** – track and manage event attendee limits

### Attendance Tracking
- **QR Code Generation** – automatically generate unique QR codes for each attendee for an event
- **Attendance Scanning** – real-time QR code scanning to mark attendees as present
- **QR Code Decoding** – process and validate QR codes with error handling - it just ignores invalid codes
- **Attendance Dashboard** – visualize who attended and who didn't

### Attendee Management
- **Attendee Applications** – collect applications with dietary requirements, allergies, and age verification
- **Self-Service Portal** – code-based login system (no account needed) for attendees to manage their profile
- **Waiver Management** – digital waiver signing with PDF generation
- **Waiver Stamping** – automatic PDF stamping with signature and verification data
- **Attendee Status Tracking** – applied, confirmed, checked-in, no-show status

### Communication
- **Attendee Messaging System** – two-way communication between attendees and organizers
- **Announcements** – create organization-wide or event-specific announcements
- **Public/Private Visibility** – control announcement visibility (public to attendees or private for organizers)
- **Email Notifications** – automated attendee notifications via mailers

### Content Management
- **Gallery System** – ~~share photos across organizations with gallery management~~ Not implemented yet
- **Image Uploads** – store images with Active Storage integration
- **Image Variants** – automatic variant generation for display optimization

### Organization Management
- **Multi-Organization Support** – manage multiple organizations/teams
- **Role-Based Access Control** – member, admin, signing admin. - No distinct diff yet

### User Authentication
- **OAuth with Hack Club** – single sign-on via Hack Club provider
- **Token Management** – automatic refresh token handling for long-lived sessions
- **User Profiles** – email, name, and verification status from OAuth provider
- **Session Management** – secure session handling with token storage

## 🛠️ Technology Stack

- **Framework** – Rails 8.1
- **Database** – SQLite (development/test), PostgreSQL (production)
- **Frontend** – Hotwire (Turbo + Stimulus), responsive HTML
- **File Storage** – Active Storage with cloud/local options
- **QR Codes** – rqrcode gem for SVG/PNG generation, zxing for scanning
- **PDF Generation** – Prawn for rendering, CombinePDF for manipulation
- **Background Jobs** – Solid Queue for job processing
- **Caching** – Solid Cache for performance
- **WebSocket** – Solid Cable for real-time features

## 🚀 Getting Started

### Prerequisites
- Ruby 3.2+
- Rails 8.1+
- SQLite or PostgreSQL
- ImageMagick (for image processing)
- Bundler

### Setup
```bash
# Clone and install dependencies
git clone <repo-url>
cd Eventful
bundle install

# Setup database
bin/rails db:setup

# Configure environment
cp .env.example .env
# Add HACKCLUB_CLIENT_ID and HACKCLUB_CLIENT_SECRET

# Start server
bin/rails server
```

### Development
```bash
# Run tests
bin/rails test

# Lint code
bin/rubocop
bin/brakeman

# Check dependencies for vulnerabilities
bin/bundler-audit
```

## 📋 Core Data Models

- **User** – Hack Club authenticated organizers and admins
- **Organisation** – teams/groups that host events
- **Event** – individual events with details and capacity
- **Attendee** – event applicants with application data and status
- **Announcement** – updates for organizations or events
- **Message** – communication between attendees and organizers
- **Gallery** – photo collections for organizations
- **GalleryImage** – individual photos within galleries

## 🔐 OAuth Integration

The application uses Hack Club's OAuth provider for user authentication, handled by OmniAuth with a custom [hackclub strategy](lib/omniauth/strategies/hackclub.rb).

### Configuration

1. **Environment variables** – set `HACKCLUB_CLIENT_ID` and `HACKCLUB_CLIENT_SECRET` (see `.env` for development; you can copy `.env.example`).
2. **Callback URL** – the provider must be configured to redirect to
   `#{OmniAuth.config.full_host}/auth/hackclub/callback`. In development we force
   `OmniAuth.config.full_host` to `http://dev.bing-bong.uk:3000`; adjust or
   change to `localhost:3000` depending on how you access the app.
3. **Scopes** – we request `openid profile email slack_id verification_status
   offline_access` so that:
   * we can read basic profile information (`/api/v1/me`), and
   * receive refresh tokens for long-lived sessions.
   The offline scope is what gives us a `refresh_token` from the API.
4. **SessionsController#create** stores the omniauth hash in the database.

### Token Storage & Refreshing

`User` records include `access_token`, `refresh_token` and `expires_at`
(columns added in `db/migrate/20260303180000_add_oauth_tokens_to_users.rb`).
`User.from_omniauth` saves credentials from the callback and provides
`refresh_access_token!` to rotate tokens when they expire. Example:

```ruby
if current_user.access_token_expired?
  current_user.refresh_access_token!
end
response = current_user.hackclub_get("/api/v1/me")
```

## 📍 Location Autocomplete

Events support address autocompletion with two different providers:

* **Google Maps Places API ("Autocomplete (New)")** – uses the new HTTP POST endpoint (`/v1/places:autocomplete`) so no Maps JavaScript library is required. A valid API key is still necessary; this request is billed under the Places SKU.
* **OpenStreetMap / Nominatim** – a free, unauthenticated service that returns basic place names and works automatically when no Google API key is configured.

### How It Works
The `location` field on the event form is wired up to a Stimulus controller (`LocationAutocompleteController`). The controller reads the key from a `<meta name="google-maps-api-key" …>` tag injected by the layout.

* When a key is present it sends debounced POST requests to `https://places.googleapis.com/v1/places:autocomplete` with a JSON body containing `{"input":"…"}`. The response is parsed and the first five suggestions are shown via a `<datalist>`.
* If the key is blank, Nominatim is used instead; this provides an identical fallback experience and also fills the datalist.

### Enabling Google Maps
1. Obtain an API key from the Google Cloud Console and enable the **Places API**.
2. Set `GOOGLE_MAPS_API_KEY` in your environment (e.g. in `.env` for development).
3. Restart the server. The layout will expose the key in a meta tag and the controller will begin calling the HTTP endpoint.

You can bias results using additional data-attributes if desired (e.g. `data-location-bias`), or modify the controller to include parameters such as `locationRestriction`, `regionCode`, etc. See Google's documentation for the full set of request options.

If you never configure a key, the Nominatim fallback ensures the form remains usable at no cost.

## 🖼️ Image Processing

Active Storage generates image variants for display (e.g. event icons). By default the `image_processing` gem prefers the `ruby-vips` backend which requires the `libvips` library to be installed on the system. In development and the CI container we don't rely on that library, so the application is configured to use `MiniMagick` instead.

You still need to have [ImageMagick](https://imagemagick.org) installed:

```sh
# Ubuntu / WSL
sudo apt-get install imagemagick
# macOS (Homebrew)
brew install imagemagick
```

Without ImageMagick the app will raise a 500 error when generating a variant:
```
MiniMagick::Error (executable not found: "convert")
```
The initializer included with the project will log a warning and automatically switch to `:vips` if the `libvips` library is already present (and the `ruby-vips` gem loaded successfully). In that case you can either install ImageMagick or simply leave the fallback in place.

If you *do* install `libvips` you can remove the initializer or change the processor back to `:vips` altogether.

## 🚢 Deployment

The application includes support for Docker and Kamal deployment orchestration:

- **Docker** – containerized application with production-ready setup
- **Kamal** – simple deployment to VPS or container platforms
- See `Dockerfile`, `config/deploy.yml`, and `bin/kamal` for deployment configuration

## 📄 Testing & Code Quality

- **Tests** – exercises the full sign-in flow (including credential storage) via OmniAuth's test mode. Run `bin/rails test` after migrating the test DB.
- **Linting** – use `bin/rubocop` to check code style
- **Security Scanning** – `bin/brakeman` for vulnerability detection and `bin/bundler-audit` for dependency vulnerabilities

## 📚 Project Structure

```
app/
├── controllers/        # Request handlers for events, attendees, organizations, QR codes, etc.
├── models/            # User, Event, Attendee, Organisation, Message, Announcement, Gallery, etc.
├── services/          # QR code generation/decoding, waiver generation
├── mailers/           # Email notifications for attendees
├── helpers/           # View helpers
├── views/             # UI templates
└── javascript/        # Stimulus controllers
```

## 🛠️ Key Services

- **QRCodeGenerator** – creates QR codes in SVG/PNG format
- **QRCodeDecoder** – parses and validates QR code data
- **SignedWaiverGenerator** – creates PDF waivers with digital signatures

Happy hacking!

