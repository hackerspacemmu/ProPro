import { Controller } from "@hotwired/stimulus";

// Generic tab controller — deliberately NOT mobile_tabs_controller.js,
// which is hard-coded to 3 named targets for the project/topic show pages
// and out of scope for this work.
//
// Usage:
//   <div data-controller="tabs"
//        data-tabs-active-index-value="0"
//        data-tabs-active-class="..."
//        data-tabs-inactive-class="...">
//     <button data-tabs-target="tab" data-action="tabs#show"
//             data-tabs-index-param="0" data-tabs-key-param="overview">...</button>
//     <button ... index-param="1" key-param="to_review">...</button>
//     <div data-tabs-target="panel">...</div>
//     <div data-tabs-target="panel">...</div>
//   </div>
//
// The server renders the initially-active tab (from ?tab=) directly into the
// HTML — no flash of the wrong tab on load — while clicks write the tab's
// "key" (a stable id, independent of DOM position) back into the URL via
// replaceState. connect() prefers the URL's ?tab= key so reconnects stay on
// the tab the URL advertises (fresh loads AND Turbo snapshot restores, where
// the baked activeIndexValue can be stale), falling back to activeIndexValue.
//
// The "Settings" entry in the tab bar is a plain link_to (real navigation to
// a separate page), not a data-tabs-target="tab" — it doesn't participate in
// this controller at all.
export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active", "inactive"];
  static values = { activeIndex: { type: Number, default: 0 } };

  connect() {
    // Prefer the URL's ?tab= key over the server-baked activeIndexValue. The
    // server renders the initially-active tab from params[:tab], and clicks
    // keep the URL current via replaceState — so reading the URL here makes
    // every reconnect (fresh load AND Turbo snapshot restores where the baked
    // index can be stale) land on the same tab the URL already advertises.
    const urlTab = new URL(window.location.href).searchParams.get("tab");
    if (urlTab) {
      const keyed = this.tabTargets.findIndex(
        (tab) => tab.dataset.tabsKeyParam === urlTab,
      );
      if (keyed !== -1) this.setActive(keyed);
      return;
    }
    this.setActive(this.activeIndexValue);
  }

  show(event) {
    const index = Number(event.params.index);
    this.setActive(index);

    // replaceState, not pushState — switching tabs isn't a new page for
    // back-button purposes, it just needs to survive a refresh/share.
    const key = event.params.key;
    if (key) {
      const url = new URL(window.location.href);
      url.searchParams.set("tab", key);
      window.history.replaceState(window.history.state, "", url);
    }
  }

  setActive(index) {
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index);
    });

    this.tabTargets.forEach((tab, i) => {
      const isActive = i === index;

      const activeClasses = (
        this.hasActiveClass
          ? this.activeClass
          : "text-[#1A73E8] border-[#1A73E8]"
      ).split(" ");
      const inactiveClasses = (
        this.hasInactiveClass
          ? this.inactiveClass
          : "text-[#5F6368] hover:text-[#3C4043] border-transparent"
      ).split(" ");

      if (isActive) {
        tab.classList.add(...activeClasses);
        tab.classList.remove(...inactiveClasses);
      } else {
        tab.classList.add(...inactiveClasses);
        tab.classList.remove(...activeClasses);
      }

      tab.setAttribute("aria-selected", isActive);
      tab.setAttribute("tabindex", isActive ? "0" : "-1");
    });
  }
}
