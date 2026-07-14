import { Controller } from "@hotwired/stimulus";
import Mark from "mark.js";

// Connects to data-controller="search-highlight"
//
// Scoped to a content element (data-search-highlight-target="context").
// Marks search terms with <mark class="search-highlight"> using mark.js.
export default class extends Controller {
  static targets = ["context"];
  static values = { query: String };

  connect() {
    this.instance = new Mark(this.contextTarget);
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts = new Map();
    this.scrollBehavior = this._reducedMotion() ? "instant" : "smooth";

    if (this.queryValue) {
      this.highlight(this.queryValue, { navigate: true });
    }
  }

  highlight(term, { navigate = false } = {}) {
    this._unmark();
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts.clear();

    if (!term) return;

    this.instance.mark(term, {
      separateWordSearch: true,
      accuracy: "partially",
      diacritics: true,
      caseSensitive: false,
      acrossElements: false,
      each: (node) => this._collect(node),
      filter: (node, foundTerm, totalCounter, counter) => this._filter(node, foundTerm, totalCounter, counter),
      noMatch: (term) => this._onNoMatch(term),
      done: (counter) => this._onDone(counter)
    });

    if (navigate && this.markElements.length > 0) {
      this.activeIndex = 0;
      this._navigateCurrent();
    }
  }

  // --- Private ---

  _unmark() {
    if (this.instance) this.instance.unmark();
  }

  _collect(node) {
    this.markElements.push(node);
    const section = node.closest("details") ||
                    node.closest("h2") ||
                    node.closest("h3") ||
                    node.closest("h4");
    const heading = section?.querySelector("summary, h2, h3, h4")?.textContent || "Other";
    this.sectionCounts.set(heading, (this.sectionCounts.get(heading) || 0) + 1);
  }

  _filter(node, foundTerm) {
    return true;
  }

  _onNoMatch(term) {
    // Will be expanded in U4
  }

  _onDone(counter) {
    // Will be expanded in U4
  }

  _navigateCurrent() {
    // Will be expanded in U5
  }

  _reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
}
