---
title: feat: Implement homepage redesign
type: feat
status: active
date: 2026-06-10
---

# feat: Implement homepage redesign

## Summary

Replace the gutted `_home_text.html.erb` with the full mockup homepage: a `<pennlibs-hero>` with art-directed background image and dark-themed header + inline search box, a "Collection Guides" card grid sampled from YAML data, and a "A Regional Partnership" section with institution cards and a Leaflet map from YAML repo data — all using Penn Libraries Design System web components and CSS patterns.

---

## Problem Frame

The Finding Aids homepage currently shows only a comment placeholder (`# Gutted for Version 2.0 redesign`). The design (specced by Jon Earley, March–May 2026) provides a full hero-driven layout with search, collection card previews, and a regional partnership map. Without this implementation, the site has no meaningful homepage — users see a blank page on first visit.

---

## Requirements

- R1. Hero section with background image, dark-themed header, service name, lede text, and inline search box
- R2. Search box submits to Blacklight catalog search at `/records?q=...`
- R3. "Collection Guides" card grid showing sampled records from YAML data (fields: name, collection, identifier)
- R4. "A Regional Partnership" section with institution cards + Leaflet map from YAML data (fields: name, coordinate, count, slug)
- R5. Institution cards and map pin popups link to search results with repository facet applied (`/?f[repository_ssi][]=...`)
- R6. "Browse all institutions" link that functions similar to Digital Collections
- R7. Cards use DS utility classes (`pl-viewport-margins`, `pl-padding-y-2xl`, `pl-margin-b-m`, etc.) and match the responsive card-count rules from the mockup
- R8. Leaflet map loaded from CDN, scrollWheelZoom disabled, pin popups basic
- R9. Search bar in site header (outside hero) deferred to BL9 milestone

---

## Scope Boundaries

- "Browse all institutions" links to search results with all repos listed (no dedicated `/repositories` page in this iteration)
- Hero image uses a static JPEG/WebP asset (not a dynamic CMS-managed image)
- No Solr-backed counts for repository guides; counts are hardcoded in YAML
- No typeahead, autocomplete, or advanced search on homepage
- No Turbo/Stimulus integration for homepage interactivity
- Search bar in site-level header (Blacklight layout) unchanged — kept at current position

---

## Context & Research

### Relevant Code and Patterns

- **Existing header component** (`rails_app/app/components/header_component.rb`) renders `<pennlibs-header>` already — but homepage hero needs a separate dark-themed header inside the hero (does not replace the layout header)
- **Footer** (`rails_app/app/components/footer_component.html.erb`) already uses `<pennlibs-footer>` — pattern for DS web components established
- **BL base layout** (`rails_app/app/views/layouts/blacklight/base.html.erb`) loads `@penn-libraries/web@1.3.1` CSS/JS via CDN — same CDN approach for Leaflet
- **Homepage path**: `catalog#index` → `index.html.erb` → renders `_home` partial → renders `_home_text` partial. The `_home_text` partial is already overridden and gutted
- **Settings**: `pennlibs_web_version` in `config/settings.yml`
- **Blacklight**: v8.12.3 (BL9 upgrade pending as separate milestone)

### External References

- **Mockup**: https://philadelphia-area-archives-designs.netlify.app/
- **DS Hero pattern**: https://designsystem.library.upenn.edu/patterns/hero/
- **DS Header pattern**: https://designsystem.library.upenn.edu/patterns/header/ — `theme="dark"` attribute, `slot="end"` for search
- **DS Button pattern**: https://designsystem.library.upenn.edu/patterns/button/ — `pl-button--accent` for primary actions
- **Leaflet CDN**: https://cdn.jsdelivr.net/npm/leaflet@1/dist/leaflet.min.js / leaflet.min.css

### Key Patterns from Mockup CSS

- `.faa-cards`: CSS grid with `grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr))`
- `.faa-home-sections .faa-cards`: responsive card count — 4 cards at mobile, scaling up to 6 at desktop
- `.paa-search-box`: pill-shaped search bar with rounded corners, accent button
- `.pl-button--accent`: accent-colored button for "Find it" submit

---

## Key Technical Decisions

- **Data format**: YAML files over database/seeds — matches issue spec ("hard code in a YAML file") and keeps data lightweight without migrations
- **Data sampling**: `Array#sample(n)` in a helper method — simple, no state needed
- **Search form action**: `/records` (Blacklight catalog path) with `method="get"` and `name="q"` — matches existing search URL pattern
- **Facet URL construction**: `/?f[repository_ssi][]=<URL-encoded name>` — follows Blacklight's standard facet constraint URL convention
- **Leaflet**: CDN-loaded in the homepage template only (not in layout head) — avoids loading map assets on every page
- **Hero image**: Static asset in `app/assets/images/` served via Propshaft — no separate image optimization pipeline needed for MVP

---

## Implementation Units

### U1. Create YAML data files

**Goal:** Provide sample collection guides and repository data for homepage card grids.

**Requirements:** R3, R4, R5

**Dependencies:** None

**Files:**
- Create: `data/collection_guides.yml`
- Create: `data/repositories.yml`

**Approach:**
- `data/collection_guides.yml`: array of entries with `name`, `collection`, `identifier` fields. ~10 entries matching the mockup data (Haverford, Penn Kislak, etc.). Fields: `name` (collection title), `collection` (holding institution), `identifier` (record ID for potential linking)
- `data/repositories.yml`: array of entries with `name`, `slug`, `count`, `lat`, `lng` fields. ~19 entries matching the mockup's inline JSON data (Haverford, Princeton Manuscripts, Penn Kislak, etc.). The `slug` field matches the mockup's URL pattern for potential future use; `lat`/`lng` are Leaflet coordinates

**Patterns to follow:**
- Existing `data/endpoints.csv` shows `data/` is the right directory for static data files

**Test scenarios:**
- Happy path: YAML files parse correctly as arrays of hashes
- Happy path: Each entry has all required fields populated
- Edge case: File not found or malformed (handled by app startup error)

**Verification:**
- `YAML.load_file(Rails.root.join('data/collection_guides.yml'))` returns expected array
- `YAML.load_file(Rails.root.join('data/repositories.yml'))` returns expected array

---

### U2. Add homepage CSS

**Goal:** Add the card grid, search box, and responsive card-visibility styles from the mockup.

**Requirements:** R3, R4, R7

**Dependencies:** None (can be done in parallel with U1, U3)

**Files:**
- Create: `app/assets/stylesheets/homepage.css`
- Modify: `app/assets/stylesheets/application.css` (add `@import 'homepage.css'`)

**Approach:**
- Create `homepage.css` containing:
  - `.faa-cards` grid layout with `auto-fill, minmax(12rem, 1fr)` — mirrors Digital Collections card pattern
  - `.faa-cards__card`, `.faa-cards__card-heading`, `.faa-cards__card-sub`, `.faa-cards__card-link` — card styling with full-link overlay (`::after` pseudo-element)
  - `.faa-home-sections` responsive card visibility — `nth-child(-n+4)` at mobile, scaling through breakpoints
  - `.paa-search-box` — flex container with pill shape, `pl-button--accent` for submit
  - `.faa-hero-search` container for the inline search form
  - DS utility classes (`.pl-padding-y-2xl`, `.pl-viewport-margins`, etc.) are already available from the DS stylesheet — no need to redefine
- Import in `application.css` with `@import 'homepage.css'`

**Patterns to follow:**
- `app/assets/stylesheets/application.css` is the manifest file
- Mockup CSS at https://philadelphia-area-archives-designs.netlify.app/css/styles.css provides the exact rules

**Test scenarios:**
- Test expectation: none — pure CSS, no behavioral logic

**Verification:**
- Homepage renders with card grid and search box styled per mockup

---

### U3. Build homepage hero section

**Goal:** Replace the gutted `_home_text.html.erb` with the hero, collection guides card grid, and regional partnership section (minus Leaflet map init, which is U4).

**Requirements:** R1, R2, R3, R4, R5, R6, R9

**Dependencies:** U1 (YAML data), U2 (CSS)

**Files:**
- Create: `app/views/catalog/_home_text.html.erb` (replace existing content)
- Create or add: helper for data access — `app/helpers/homepage_helper.rb`
- Test: `spec/views/catalog/_home_text.html.erb_spec.rb`

**Approach:**
- Replace `_home_text.html.erb` content entirely with new template
- Build helper methods in `app/helpers/homepage_helper.rb`:
  - `sample_collection_guides(n = 8)` — loads and samples from YAML
  - `sample_repositories(n = 6)` — loads and samples from YAML
  - `repository_facet_path(name)` — builds `/?f[repository_ssi][]=<encoded_name>` URL
- Template structure (using DS web components and utility classes):
  1. `<pennlibs-hero>` containing:
     - `<picture hero="art-direction">` with art-directed hero image (JPEG + WebP sources)
     - `<pennlibs-header theme="dark" slot="start" service-name="Philadelphia Area Archives" service-lede="Finding Aids at the University of Pennsylvania">` with search form in `<div slot="end">`
     - `<h1 hero="heading">` with "Stories held in archives"
     - `<p hero="sub-heading">` with lede text
     - Search form: `<form class="paa-search-box" action="/records" method="get">` with `<input type="search" name="q">` + `<button class="pl-button pl-button--accent">`
  2. Collections guides section: `<section class="pl-padding-y-2xl">` with heading, lede, and `<ol class="faa-cards">` iterating over sampled guides
  3. Regional partnership section: `<section class="pl-padding-t-2xl" style="background: var(--pl-color-bg-subtle)">` with heading, lede with "browse all institutions" link, and `<ol class="faa-cards">` iterating over sampled repos
  4. Map container: `<div id="map" style="height: 20rem;" class="pl-margin-t-2xl"></div>` (Leaflet init in U4)
- Search form action is `/records` (Blacklight catalog path), input `name="q"` — Rails helper `search_form` adds CSRF but a plain `<form method="get">` doesn't need it
- "Browse all institutions" links to `/?f%5Brepository_ssi%5D%5B%5D=` (empty facet constraint shows all repos in sidebar)

**Patterns to follow:**
- Existing DS component usage in `header_component.html.erb` and `footer_component.html.erb`
- Mockup HTML at https://philadelphia-area-archives-designs.netlify.app/

**Test scenarios:**
- Happy path: Homepage renders hero with search form, service name, headings
- Happy path: Collection guides section shows cards with names and institution names
- Happy path: Regional partnership section shows institution cards and "browse all institutions" link
- Happy path: Institution card links point to facet-filtered search URL
- Edge case: YAML file not found — template renders gracefully (empty sections or logged error)
- Edge case: YAML file has fewer items than sample count — renders all available items

**Verification:**
- Visit `/` and see hero with image, search form, headings
- Collection guides section shows sampled cards (varies per request)
- Regional partnership section shows institution cards
- Clicking a card link goes to `/records?f[repository_ssi][]=...`

---

### U4. Add Leaflet map

**Goal:** Initialize Leaflet map in the regional partnership section with repo pin markers and popup links.

**Requirements:** R4, R5, R8

**Dependencies:** U3 (map container exists in template), U1 (YAML data with coordinates)

**Files:**
- Modify: `app/views/catalog/_home_text.html.erb` (add Leaflet script block)
- Modify: `app/views/layouts/blacklight/base.html.erb` (add Leaflet CSS in `<head>`)

**Approach:**
- Add Leaflet CSS to the layout `<head>` (only on homepage would be better, but layout-level inclusion is simpler):
  ```erb
  <%= stylesheet_link_tag "https://cdn.jsdelivr.net/npm/leaflet@1/dist/leaflet.min.css" %>
  ```
- Add Leaflet JS and map initialization inline in `_home_text.html.erb`, wrapped in a `content_for :head` block so it only loads on the homepage:
  ```erb
  <% content_for(:head) do %>
    <%= javascript_import_module_tag "https://cdn.jsdelivr.net/npm/leaflet@1/dist/leaflet.min.js" %>
  <% end %>
  ```
  Wait — `javascript_import_module_tag` is for ES modules. Leaflet umd is a script tag. Better to use a plain `<script>` tag in the template body, or use `javascript_include_tag` if Propshaft supports it. Let me use a simpler approach: inline `<script>` after the map container.
- Map initialization script:
  ```javascript
  document.addEventListener('DOMContentLoaded', function() {
    var map = L.map('map', { scrollWheelZoom: false }).setView([39.98, -75.19], 11);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);
    // repo data from YAML, embedded as JSON in a data attribute
    var repos = JSON.parse(document.getElementById('map').dataset.repos);
    repos.forEach(function(repo) {
      if (repo.lat && repo.lng) {
        L.marker([repo.lat, repo.lng]).addTo(map)
          .bindPopup('<strong>' + repo.name + '</strong><br>' + repo.count.toLocaleString() + ' guides');
      }
    });
  });
  ```
- Pass repo data via a `data-repos` attribute on the map div, serialized from the YAML data

**Patterns to follow:**
- Mockup's Leaflet initialization pattern (CDN source, view center, tile layer, repo markers)
- DS assets already use CDN (same pattern as `@penn-libraries/web`)

**Test scenarios:**
- Happy path: Map renders on homepage with markers matching YAML repos
- Happy path: Pin popups show repo name and guide count
- Happy path: scrollWheelZoom is disabled
- Edge case: Repo has null lat/lng — marker is skipped (no crash)
- Integration: Map markers link to facet-filtered search

**Verification:**
- Visit `/` and see Leaflet map with markers
- Click a pin → popup with name + count
- scrollWheelZoom does not zoom the map (page scrolls instead)

---

### U5. Add hero image asset

**Goal:** Add the hero background image to the Rails asset pipeline.

**Requirements:** R1

**Dependencies:** U3 (template needs the image)

**Files:**
- Add: `app/assets/images/hero/moelis-reading-room.jpg` (and optional WebP variant)
- Modify: `app/views/catalog/_home_text.html.erb` (reference the image path)

**Approach:**
- Source the hero image from the mockup or a Penn Libraries archival reading room photo
- Place in `app/assets/images/hero/` for organization
- Reference via `asset_path('hero/moelis-reading-room.jpg')` in the `<picture>` element
- Add `<source>` elements for WebP with `type="image/webp"` and responsive sizes via `media` queries
- With Propshaft, the digest path is handled automatically

**Patterns to follow:**
- Mockup uses art-directed `<picture>` with multiple sources
- Existing images in `app/assets/images/` (pacscl-logo.png)

**Test scenarios:**
- Test expectation: none — static asset, verified visually

**Verification:**
- Homepage hero shows background image
- Image loads on different screen sizes (art direction working)

---

## System-Wide Impact

- **Interaction graph:** `_home_text.html.erb` is rendered inside `catalog#index` → `_home.html.erb` — no other pages are affected
- **Error propagation:** Missing YAML files should not crash the homepage — helpers should handle gracefully with `rescue` and log a warning
- **Unchanged invariants:** The layout-level `<pennlibs-header>` (HeaderComponent) still renders on all pages including homepage — the hero's dark header is additive, not a replacement. The layout-level search bar (`SearchNavbarComponent`) still renders below the layout header on non-homepage pages; on the homepage the hero's inline search is the visible search. The existing `_home.html.erb` Blacklight view is not overridden — only the `_home_text` partial content is replaced

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Hero image not available / unclear license | Use a Penn Libraries owned photo (e.g., reading room). Defer image selection to Mike/Jon if needed |
| Leaflet CDN outage or version mismatch | Specify exact version `@1` (pinned). Widen CDN provider fallback if practical |
| YAML data drifts from real Solr data | Accept as intentional — issue specifies hardcoded data. Future iteration can add Solr-backed counts |
| Homepage search form conflicts with Blacklight search bar | Search form submits to same `/records` endpoint — no conflict. The BL search bar continues to work on results pages |
| `content_for(:head)` blocks from homepage template may not render | Verify the Bl8 `_home.html.erb` template structure supports `content_for` from nested partials. If not, move Leaflet CSS/JS to layout conditionally |

---

## Documentation / Operational Notes

- No database migrations or environment changes needed
- No new gem dependencies (Leaflet via CDN)
- YAML data files in `data/` are checked into version control
- Hero image should be < 500KB for performance

---

## Sources & References

- **Issue:** https://gitlab.library.upenn.edu/dld/finding-aids/-/issues/287
- **Design mockup:** https://philadelphia-area-archives-designs.netlify.app/
- **Design system (Hero):** https://designsystem.library.upenn.edu/patterns/hero/
- **Design system (Header):** https://designsystem.library.upenn.edu/patterns/header/
- **Design system (Button):** https://designsystem.library.upenn.edu/patterns/button/
- **Current Blacklight version:** 8.12.3
- **Penn Libraries DS web components version:** 1.3.1
