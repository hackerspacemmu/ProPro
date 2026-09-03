import { Controller } from "@hotwired/stimulus";

// Global "/" shortcut, GitHub/Gmail-style: focuses the search input on the
// current tab panel instead of opening anything new. If the current panel
// has no search input (Overview / Topics), switches to the Groups tab first
// — confirmed default, since Groups search matches both groups and students
// — then focuses that input.
//
// Scoped to the same element as the "tabs" controller in courses/show.html.erb
// (data-controller="tabs search-shortcut" lives on the same <main>), so every
// DOM query below stays within this page's tab bar/panels.
//
// Search inputs opt in with:
//   data-search-shortcut-target="input"                 <- any tab's search box
//   data-search-shortcut-target="input fallbackInput"    <- Groups tab's box only
export default class extends Controller {
  static targets = ["input", "fallbackInput"];

  connect() {
    this.boundOnKeydown = this.onKeydown.bind(this);
    window.addEventListener("keydown", this.boundOnKeydown);
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundOnKeydown);
  }

  onKeydown(event) {
    if (event.key !== "/") return;
    if (this.isTypingTarget(event.target)) return;
    if (document.querySelector("dialog[open]")) return;

    event.preventDefault();
    this.focusRelevantInput();
  }

  isTypingTarget(target) {
    if (!target) return false;
    if (target.isContentEditable) return true;
    return ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);
  }

  focusRelevantInput() {
    const input = this.currentPanelInput();
    if (input) {
      input.focus();
      return;
    }
    this.jumpToFallback();
  }

  currentPanelInput() {
    const panel = this.element.querySelector(
      '[data-tabs-target="panel"]:not(.hidden)',
    );
    if (!panel) return null;
    return this.inputTargets.find((input) => panel.contains(input)) || null;
  }

  jumpToFallback() {
    if (!this.hasFallbackInputTarget) return;

    const panels = Array.from(
      this.element.querySelectorAll('[data-tabs-target="panel"]'),
    );
    const panel = this.fallbackInputTarget.closest(
      '[data-tabs-target="panel"]',
    );
    const index = panels.indexOf(panel);
    if (index === -1) return;

    const tabButton = this.element.querySelectorAll('[data-tabs-target="tab"]')[
      index
    ];
    tabButton?.click();
    this.fallbackInputTarget.focus();
  }
}
