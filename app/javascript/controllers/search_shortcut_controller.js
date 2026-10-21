import { Controller } from "@hotwired/stimulus";

// Global "/" shortcut, GitHub/Gmail-style: focuses the search input on the
// current course tab page instead of opening anything new. Each tab is its
// own route now (route-per-tab, ADR 0019), so there is one content area per
// page and at most one input target on it.
//
// Pages without a search input (Overview) fall back to the Groups tab's link
// (the fallbackLink target, only present on grouped courses): clicking it
// navigates via Turbo Drive, and the module-scope flag below survives the body
// swap so the new page's controller focuses #groups-search after arrival. The
// flag lives at module scope (not on the controller element) because Stimulus
// re-connects a fresh controller instance after every Drive visit. On an
// ungrouped course there is no fallback link — "/" is a no-op on Overview.
//
// Scoped to the same element as the tab shell's <main>, so every DOM query
// below stays within this page's tab strip and content.
//
// Search inputs opt in with:
//   data-search-shortcut-target="input"        <- any tab page's search box
//   data-search-shortcut-target="fallbackLink" <- the Groups tab link only
let focusAfterNavigation = false;

export default class extends Controller {
  static targets = ["input", "fallbackLink"];

  connect() {
    this.boundOnKeydown = this.onKeydown.bind(this);
    window.addEventListener("keydown", this.boundOnKeydown);

    this.boundOnTurboLoad = this.onTurboLoad.bind(this);
    document.addEventListener("turbo:load", this.boundOnTurboLoad);

    // A Drive visit may fire turbo:load before this fresh instance connects;
    // checking here too means the flag is honored either way.
    this.focusPendingInput();
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundOnKeydown);
    document.removeEventListener("turbo:load", this.boundOnTurboLoad);
  }

  onKeydown(event) {
    if (event.key !== "/") return;
    if (this.isTypingTarget(event.target)) return;
    if (document.querySelector("dialog[open]")) return;

    event.preventDefault();
    this.focusRelevantInput();
  }

  onTurboLoad() {
    this.focusPendingInput();
  }

  isTypingTarget(target) {
    if (!target) return false;
    if (target.isContentEditable) return true;
    return ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);
  }

  focusRelevantInput() {
    const input = this.inputTargets[0];
    if (input) {
      input.focus();
      return;
    }
    this.jumpToFallback();
  }

  jumpToFallback() {
    if (!this.hasFallbackLinkTarget) return;

    focusAfterNavigation = true;
    this.fallbackLinkTarget.click();
  }

  focusPendingInput() {
    if (!focusAfterNavigation) return;
    if (!this.inputTargets.length) return;

    focusAfterNavigation = false;
    this.inputTargets[0].focus();
  }
}
