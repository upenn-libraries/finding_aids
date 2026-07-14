import { Controller } from "@hotwired/stimulus";
import Mark from "mark.js";

// Connects to data-controller="search-highlight"
// Scoped to a content element (data-search-highlight-target="context").
// Marks search terms, provides in-page search input with match-summary
// listbox, status callout, ARIA live region, and keyboard navigation
// with on-demand section expansion.
export default class extends Controller {
  static targets = ["context", "searchInput", "listbox", "statusCallout", "liveRegion"];
  static values = { query: String };

  connect() {
    this.instance = new Mark(this.contextTarget);
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts = new Map();
    this.scrollBehavior = this._reducedMotion() ? "instant" : "smooth";
    this._debounceTimer = null;
    this._searchTerm = null;

    this._bindKeyboard();

    if (this.queryValue) {
      this.highlight(this.queryValue, { navigate: true });
    }
  }

  // U3: Find bar input — syncs top input value on typing.
  onFindBarInput() {
    const findInput = document.getElementById("find-bar-input");
    if (this.hasSearchInputTarget && findInput) {
      this.searchInputTarget.value = findInput.value;
      this.searchInputTarget.dispatchEvent(new Event("input", { bubbles: true }));
    }
  }

  // Dismiss the find bar and clear all highlights.
  dismissFindBar() {
    if (this.hasSearchInputTarget) this.searchInputTarget.value = "";
    const findInput = document.getElementById("find-bar-input");
    if (findInput) findInput.value = "";
    this._clear();
    this._hideFindBar();
  }
  onSearchInput() {
    clearTimeout(this._debounceTimer);
    this._debounceTimer = setTimeout(() => {
      const term = this.searchInputTarget.value.trim();
      if (term) {
        this._searchTerm = term;
        this.highlight(term);
      } else {
        this._clear();
      }
    }, 200);
  }

  // U5: Navigate to next match. Opens collapsed <details> on the way.
  nextMatch() {
    if (this.markElements.length === 0) return;
    this.activeIndex = (this.activeIndex + 1) % this.markElements.length;
    this._navigateCurrent();
  }

  // U5: Navigate to previous match. Wraps around.
  prevMatch() {
    if (this.markElements.length === 0) return;
    this.activeIndex = this.activeIndex <= 0
      ? this.markElements.length - 1
      : this.activeIndex - 1;
    this._navigateCurrent();
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
      filter: (node, foundTerm, totalCounter, counter) =>
        this._filter(node, foundTerm, totalCounter, counter),
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
    this._searchTerm = null;
    this._unmark();
    this.markElements = [];
    this.activeIndex = -1;
    this.sectionCounts.clear();
    this._renderListbox();
    this._hideCallout();
    this._hideFindBar();
    this._announce("");
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

  // U4: Zero-match state.
  _onNoMatch(term) {
    this._renderListbox();
    this._showCallout(`No matches found for "${term}"`);
    this._announce(`No matches found for "${term}"`);
  }

  // U4: Match complete. Update callout, ARIA live, listbox.
  _onDone(counter) {
    this._renderListbox();
    const hasMatches = counter > 0;
    if (hasMatches) {
      this._showFindBar();
      const sectionCount = this.sectionCounts.size;
      this._showCallout(
        `${counter} match${counter === 1 ? "" : "es"} in ${sectionCount} section${sectionCount === 1 ? "" : "s"}`
      );
      this._announce(`${counter} matches found`);
    } else {
      this._onNoMatch(this._searchTerm || "");
    }
  }

  // U4: Show the status callout with the given text.
  _showCallout(text) {
    const el = this.statusCalloutTarget;
    el.textContent = text;
    el.hidden = false;
  }

  _hideCallout() {
    this.statusCalloutTarget.hidden = true;
  }

  // U4: Update the ARIA live region.
  _announce(message) {
    // Force re-announce by clearing then setting
    this.liveRegionTarget.textContent = "";
    requestAnimationFrame(() => {
      this.liveRegionTarget.textContent = message;
    });
  }

  // U3/U4: Render the match-summary listbox.
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
        this._navigateToSection(heading);
      });
      el.appendChild(item);
    }
    el.hidden = false;
  }

  // Navigate to first match in the named section.
  _navigateToSection(heading) {
    const sectionNode = this._findSectionNode(heading);
    if (!sectionNode) return;
    const mark = sectionNode.querySelector("mark.search-highlight");
    if (mark) {
      // Open details if collapsed
      const details = mark.closest("details");
      if (details && !details.open) details.open = true;
      // Update activeIndex to the first mark in this section
      const idx = this.markElements.indexOf(mark);
      if (idx >= 0) this.activeIndex = idx;
      this._focusMark(mark);
    }
  }

  _findSectionNode(heading) {
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

  // U5: Scroll into view, focus, and style the active mark.
  // Opens collapsed <details> if needed.
  _focusMark(mark) {
    const details = mark.closest("details");
    if (details && !details.open) details.open = true;

    mark.scrollIntoView({ block: "center", behavior: this.scrollBehavior });
    mark.setAttribute("tabindex", "-1");
    mark.focus();
  }

  // U5: Navigate to current activeIndex and update UI.
  _navigateCurrent() {
    if (this.activeIndex < 0 || this.activeIndex >= this.markElements.length) return;

    // Remove active class from previous mark
    const prevActive = this.contextTarget.querySelector("mark.search-highlight--active");
    if (prevActive) prevActive.classList.remove("search-highlight--active");

    const mark = this.markElements[this.activeIndex];
    mark.classList.add("search-highlight--active");
    this._focusMark(mark);

    // Update find bar counter with position
    this._updateFindBarCounter();

    // Update ARIA live
    const total = this.markElements.length;
    const section = mark.closest("details") ||
                    mark.closest("h2") ||
                    mark.closest("h3") ||
                    mark.closest("h4");
    const heading = section?.querySelector("summary, h2, h3, h4")?.textContent?.trim() || "";
    this._announce(`Match ${this.activeIndex + 1} of ${total}${heading ? `: ${heading}` : ""}`);
  }

  _showFindBar() {
    const bar = document.getElementById("search-find-bar");
    const input = document.getElementById("find-bar-input");
    if (!bar || !input) return;
    bar.hidden = false;
    if (this.hasSearchInputTarget) {
      input.value = this.searchInputTarget.value;
    }
    this._updateFindBarCounter();
  }

  _hideFindBar() {
    const bar = document.getElementById("search-find-bar");
    if (bar) bar.hidden = true;
  }

  _updateFindBarCounter() {
    const counter = document.querySelector('[data-search-highlight-target="findBarCounter"]');
    if (!counter) return;
    const total = this.markElements.length;
    const pos = this.activeIndex >= 0 ? this.activeIndex + 1 : 0;
    counter.textContent = pos > 0
      ? `${pos} of ${total}`
      : `${total} match${total === 1 ? "" : "es"}`;
  }

  // U5: Bind keyboard shortcuts on the search input.
  _bindKeyboard() {
    if (!this.hasSearchInputTarget) return;
    this.searchInputTarget.addEventListener("keydown", (event) => {
      // Enter = next match, Shift+Enter = previous match
      // Only when the listbox is not open/handling its own keyboard nav
      if (event.key === "Enter" && !this.listboxTarget.querySelector(":focus")) {
        event.preventDefault();
        if (event.shiftKey) {
          this.prevMatch();
        } else {
          this.nextMatch();
        }
      }
    });
  }

  _reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
}
