import { Controller } from "@hotwired/stimulus";
import Mark from "mark.js";

// Connects to data-controller="search-highlight"
// Scoped to .faa-guide-content.
// Highlights the search query term on arrival from search results,
// shows a match-count callout, and offers an "Expand matching sections"
// button that opens all <details> containing highlighted matches.
export default class extends Controller {
  static targets = ["context", "statusCallout", "statusText", "expandButton", "liveRegion"];
  static values = { query: String };

  connect() {
    this.instance = new Mark(this.contextTarget);
    this.sectionCounts = new Map();

    if (this.queryValue) {
      this.highlight(this.queryValue);
    }
  }

  highlight(term) {
    this._unmark();
    this.sectionCounts.clear();
    if (!term) return;

    this.instance.mark(term, {
      element: "mark",
      className: "search-highlight",
      separateWordSearch: true,
      accuracy: "partially",
      diacritics: true,
      caseSensitive: false,
      each: (node) => this._collect(node),
      filter: () => true,
      noMatch: () => this._hideCallout(),
      done: (counter) => this._onDone(counter, term)
    });
  }

  // Expand all <details> that contain search-highlight marks.
  expandMatches() {
    const marks = this.contextTarget.querySelectorAll("mark.search-highlight");
    const opened = new Set();
    marks.forEach((mark) => {
      const details = mark.closest("details");
      if (details && !details.open) {
        details.open = true;
        opened.add(details);
      }
    });
    if (opened.size > 0) {
      this._announce(`Expanded ${opened.size} section${opened.size === 1 ? "" : "s"}`);
    }
    this.expandButtonTarget.hidden = true;
  }

  // --- Private ---

  _unmark() {
    if (this.instance) this.instance.unmark();
  }

  _collect(node) {
    const section = node.closest("details") ||
                    node.closest("h2") || node.closest("h3") || node.closest("h4");
    const heading = section?.querySelector("summary, h2, h3, h4")?.textContent?.trim() || "Other";
    this.sectionCounts.set(heading, (this.sectionCounts.get(heading) || 0) + 1);
  }

  _onDone(counter, term) {
    if (counter === 0) {
      this._hideCallout();
      this._announce(`"${term}" not found in this guide`);
      return;
    }
    this._showCallout(counter);
    this._announce(`${counter} matches for "${term}" found`);
  }

  _showCallout(counter) {
    const sectionCount = this.sectionCounts.size;
    this.statusTextTarget.textContent =
      `${counter} match${counter === 1 ? "" : "es"} for "${this.queryValue}" in ${sectionCount} section${sectionCount === 1 ? "" : "s"}.`;
    this.statusCalloutTarget.hidden = false;
    this.expandButtonTarget.hidden = false;
  }

  _hideCallout() {
    this.statusCalloutTarget.hidden = true;
    this.expandButtonTarget.hidden = true;
  }

  _announce(message) {
    this.liveRegionTarget.textContent = "";
    requestAnimationFrame(() => {
      this.liveRegionTarget.textContent = message;
    });
  }
}
