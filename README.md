# Infinity

Infinity is a private, personal place to collect links, images, files, and inspiration found across social media and other platforms. Think Pinterest for your own references, without making the collection public by default.

## Stack

- Ruby on Rails 8.1
- SQLite with Solid Cache, Solid Queue, and Solid Cable
- Turbo, Stimulus, and import maps
- Propshaft and vanilla CSS
- Ruby Native for iOS and Android distribution
- Kamal deployment to Hetzner

The web application is the primary experience. Ruby Native packages the same Rails application for the App Store and Google Play, so views should remain compatible with its native shell and navigation.

## Development

### Prerequisites

- Ruby version specified in [`.ruby-version`](.ruby-version)
- SQLite 3

### Setup

```sh
bin/setup
bin/rails server
```

Visit `http://localhost:3000`.

### Local Seed Data

To prepare a local database and add repeatable manual-test data:

```sh
bin/rails db:prepare
bin/rails db:seed
```

The seeds run only in development. They create fictional `maya@example.test` and `leo@example.test` accounts with the password `password`, plus captures, a local upload, collections, placements, and tags. Running the command again does not create duplicates.

### Test And Quality Checks

```sh
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman
bin/bundler-audit check --update
```

Run the relevant checks before opening a pull request. Add focused tests for behavior changes, avoiding tests of Rails framework behavior.

## Engineering Principles

Project conventions are documented in [AGENTS.md](AGENTS.md). In brief:

- Keep dependencies minimal and prefer Rails' built-in capabilities.
- Use RESTful resources, thin controllers, rich models, and database constraints for data integrity.
- Reuse partials and existing UI patterns. Use semantic ERB, Stimulus only where needed, and readable vanilla CSS class names.
- Support current evergreen browsers and meet WCAG 2.2 AA as a minimum.
- Build GDPR requirements in from the start: minimize personal data, authorize all access, and support data access, export, and deletion where applicable.
- Treat remote URLs, media, and uploads as untrusted input.

## Git Workflow

Create focused, labeled GitHub issues and implement each feature in a branch based on an up-to-date `main`. Open a pull request, squash merge for a flat history, and delete the merged branch.

## Deployment

The application is deployed to Hetzner using Kamal. Deployment setup is managed manually. Do not add or alter deployment configuration unless the change specifically requires it.
