import { Controller } from "@hotwired/stimulus";
import Mark from "mark.js";

// Connects to data-controller="search-highlight"
//
// Scoped to a content element (data-search-highlight-target="context").
// Marks search terms with <mark class="search-highlight"> using mark.js.
// Provides in-page search input with a match-summary listbox (U3).
export default class extends Controller {
  static targets = ["context", "searchInput", "listbox"];
  static values = { query: String };

  connect() {
    this.instance = new Mark(this.contextTarget);
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts = new Map();
    this.scrollBehavior = this._reducedMotion() ? "instant" : "smooth";
    this._debounceTimer = null;

    if (this.queryValue) {
      this.highlight(this.queryValue, { navigate: true });
    }
  }

  // U3: Live in-page search triggered by input events.
  // Debounced to avoid excessive re-marking while typing.
  onSearchInput() {
    clearTimeout(this._debounceTimer);
    this._debounceTimer = setTimeout(() => {
      const term = this.searchInputTarget.value.trim();
      if (term) {
        this.highlight(term);
      } else {
        this._clear();
      }
    }, 200);
  }

  highlight(term, { navigate = false } = {}) {
    this._unmark();
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts.clear();

    if (!term) return;

    this.instance.mark(term, {
      element: "mark",
      className: "search-highlight",
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

  _clear() {
    this._unmark();
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts.clear();
    this._renderListbox();
  }

  _unmark() {
    if (this.instance) this.instance.unmark();
  }

  _collect(node) {
    this.markElements.push(node);
    const section = node.closest("details") ||
                    node.closest("h2") ||
                    node.closest("h3") ||
                    node.closest("h4");
    const heading = section?.querySelector("summary, h2, h3, h4")?.textContent?.trim() || "Other";
    this.sectionCounts.set(heading, (this.sectionCounts.get(heading) || 0) + 1);
  }

  _filter(node, foundTerm) {
    return true;
  }

  _onNoMatch(term) {
    // Will be expanded in U4
  }

  _onDone(counter) {
    this._renderListbox();
    // U4 will add callout + ARIA live region
  }

  // U3: Render the match-summary listbox from sectionCounts.
  // Each entry is a keyboard-navigable <li role="option"> with section name + count.
  _renderListbox() {
    const el = this.listboxTarget;
    el.innerHTML = "";
    el.hidden = true;

    if (this.sectionCounts.size === 0) return;

    const sorted = [...this.sectionCounts.entries()].sort((a, b) => b[1] - a[1]);
    for (const [heading, count] of sorted) {
      const item = document.createElement("li");
      item.setAttribute("role", "option");
      item.setAttribute("tabindex", "-1");
      const strong = document.createElement("strong");
      strong.textContent = heading;
      item.appendChild(strong);
      item.appendChild(document.createTextNode(" \u2014 "));
      const countSpan = document.createElement("span");
      countSpan.className = "faa-small-name";
      countSpan.textContent = `${count} match${count === 1 ? "" : "es"}`;
      item.appendChild(countSpan);
      item.addEventListener("click", () => {
        // Navigate to the first mark in this section (U5 will handle full nav)
        const sectionNode = this._findSectionNode(heading);
        if (sectionNode) {
          const mark = sectionNode.querySelector("mark.search-highlight");
          if (mark) {
            mark.scrollIntoView({ block: "center", behavior: this.scrollBehavior });
            mark.setAttribute("tabindex", "-1");
            mark.focus();
          }
        }
      });
      el.appendChild(item);
    }
    el.hidden = false;
  }

  _findSectionNode(heading) {
    // Walk all mark elements, find the first one whose nearest section heading matches.
    for (const mark of this.markElements) {
      const section = mark.closest("details") ||
                      mark.closest("h2") ||
                      mark.closest("h3") ||
                      mark.closest("h4");
      const sectionHeading = section?.querySelector("summary, h2, h3, h4")?.textContent?.trim();
      if (sectionHeading === heading) return section;
    }
    return null;
  }

  _navigateCurrent() {
    // Will be expanded in U5
  }

  _reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
}
