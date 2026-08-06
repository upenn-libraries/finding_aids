import { Controller } from "@hotwired/stimulus";

// Passed to visibilityObserver as threshold for highlighting active/visible headings.
const VISIBILITY_OPTIONS = { rootMargin: "0px 0px -30% 0px" }

const ACTIVE_CLASS = "fa-toc--active"

export default class extends Controller {
    connect() {
        this.turboFrame = this.element.querySelector("turbo-frame");
        this.pendingDetailsToggles = 0;
        this.visibilityObserver = new IntersectionObserver(
            this.highlightVisibleHeadings,
            VISIBILITY_OPTIONS,
        );

        this.setup();

        if (this.turboFrame) this.turboFrame.loaded.then(() => this.setup());
    }

    // Sets up page before and after turbo frame loads
    setup = () => {
        this.buildTocMap();
        this.observeHeadings();
        this.restoreLocation();
    };

    disconnect() {
        this.visibilityObserver.disconnect();
    }

    // Action attached to this controller. Ensures opening a details updates the Url with the correct hash
    handleDetailsToggle = (event) => {
        if (this.pendingDetailsToggles > 0) {
            this.pendingDetailsToggles--;
            return;
        }
        const details = event.target;
        if (!details.open) return;
        const heading = details.querySelector(
            ":scope > summary > :is(h3, h4, h5, h6)",
        );
        if (!heading) return;
        history.replaceState(null, "", `#${heading.id}`);
    };

    // Action attached to this controller. Ensures clicking on nested table of contents links opens all the parent details
    handleTocClick = (event) => {
        const link = event.target.closest(".fa-toc a[href^='#']");
        if (!link) return;

        event.preventDefault();

        history.replaceState(null, "", link.hash);

        // On small screens the table of contents is an offcanvas panel. Bootstrap focuses the
        // toggle button once the panel has finished closing, which scrolls that button back
        // into view and undoes the jump — so wait for the panel to close before scrolling.
        // `.offcanvas-lg` is named explicitly: a responsive panel doesn't carry `.offcanvas`.
        const panel = link.closest(".offcanvas.show, .offcanvas-lg.show");
        if (panel) {
            panel.addEventListener("hidden.bs.offcanvas", this.navigateToLocation, { once: true });
            return;
        }

        this.navigateToLocation();
    };



    // Map to connect headings to table of content links. Keys are heading ids, and value is an object containing both
    // table of contents link and heading elements
    buildTocMap = () => {
        this.tocEntries = new Map();
        this.element.querySelectorAll('.fa-toc a[href^="#"]').forEach((link) => {
            const headingId = link.hash.slice(1);
            const heading = this.element.querySelector(link.hash);
            if (!heading) return;
            this.tocEntries.set(headingId, { heading, link });
        });
    };

    // Instruct visibility observer to observe headings
    observeHeadings = () => {
        this.visibilityObserver.disconnect();
        this.tocEntries.forEach(({ link, heading }, headingId) => {
            this.visibilityObserver.observe(heading);
        });
    };

    // visibilityObserver callback that toggles active class on ToC links
    highlightVisibleHeadings = (entries, observer) => {
        entries.forEach((entry) => {
            const tocEntry = this.tocEntries.get(entry.target.id);
            if (!tocEntry) return;
            tocEntry.link.classList?.toggle(ACTIVE_CLASS, entry.isIntersecting);
        });
    };

    // Used during set up to ensure incoming location hash is preserved while turbo frame loads. If the incoming location
    // hash is not present in the DOM, the top level parent details opens with loading spinner.
    restoreLocation = () => {
        const heading = this.findLocationHeading({ fallbackToTopLevel: true });
        if (!heading) return;

        this.openDetailsSilently(heading);

        heading.scrollIntoView({ block: "start", behavior: "instant" });
    };

    // Navigates to details at the current location in the URL. Expands all parent details.
    navigateToLocation = () => {
        const heading = this.findLocationHeading();
        if (!heading) return;

        this.openDetails(heading);

        heading.scrollIntoView({ block: "start", behavior: "instant" });
    };

    // Identify the heading that matches the location hash in the Url. Provides option to use top level heading as a
    // fallback to expand top level parent during while turbo frame loads.
    findLocationHeading = ({ fallbackToTopLevel = false } = {}) => {
        if (!location.hash) return;

        let heading = this.element.querySelector(location.hash);

        if (!heading && fallbackToTopLevel) {
            const topLevelId = location.hash.split("-", 2).join("-");
            heading = this.element.querySelector(topLevelId);
        }

        return heading;
    };

    // Travel through details hierarchy to open any unopened details
    openDetails = (heading) => {
        const detailsToOpen = this.detailsToOpen(heading);
        detailsToOpen.forEach((details) => {
            details.open = true;
        });
    };

    // Travel through details hierarchy to open any unopened details, while using a count of pending open events to
    // suppress toggle event from firing. Suppressing the toggle event during initial navigation ensures incoming location
    // hash is preserved while top level parent expands during turbo frame loading.
    openDetailsSilently = (heading) => {
        const detailsToOpen = this.detailsToOpen(heading);
        this.pendingDetailsToggles += detailsToOpen.length;
        detailsToOpen.forEach((details) => {
            details.open = true;
        });
    };

    // Collects details to open for a given heading ordered from outermost to innermost.
    detailsToOpen = (heading) => {
        let details = heading.closest("details");

        if (!details) return [];

        const toOpen = [];

        while (details) {
            if (!details.open) toOpen.push(details);
            details = details.parentElement?.closest("details");
        }

        return toOpen.reverse();
    };
}
