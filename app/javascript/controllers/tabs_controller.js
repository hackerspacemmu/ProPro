import { Controller } from "@hotwired/stimulus";

// Generic tab controller — deliberately NOT mobile_tabs_controller.js,
// which is hard-coded to 3 named targets for the topic show page
// and out of scope for this work.
//
// Usage:
//   <div data-controller="tabs"
//        data-tabs-persist-key-value="propro_tab_course_42"
//        data-tabs-active-class="..."
//        data-tabs-inactive-class="...">
//     <button data-tabs-target="tab" data-action="tabs#show"
//             data-tabs-index-param="0" data-tabs-slug-param="overview">...</button>
//     <button ... index-param="1" slug-param="topics">...</button>
//     <div data-tabs-target="panel">...</div>
//     <div data-tabs-target="panel">...</div>
//   </div>
//
// data-tabs-persist-key-value is optional. When present, the selected tab's
// slug is written to a plain cookie under that key on every user-initiated
// switch, so the *server* can render the right panel un-hidden on the next
// full page load. connect() trusts whatever the server already rendered
// rather than forcing tab 0, so it never fights that server-side choice
// (that's what would reintroduce the flash-of-wrong-tab problem).
//
// The "Settings" entry in the tab bar is a plain link_to (real navigation to
// a separate page), not a data-tabs-target="tab" — it doesn't participate in
// this controller at all.
export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active", "inactive"];
  static values = { persistKey: String };

  connect() {
    const alreadyVisible = this.panelTargets.findIndex(
      (panel) => !panel.classList.contains("hidden"),
    );
    this.applyState(alreadyVisible === -1 ? 0 : alreadyVisible);
  }

  show(event) {
    const index = Number(event.params.index);
    this.applyState(index);
    this.persist(event.params.slug);
  }

  applyState(index) {
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
          : "text-[#5F6368] border-transparent"
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

  persist(slug) {
    if (!slug || !this.hasPersistKeyValue) return;
    const secure = window.location.protocol === "https:" ? "; secure" : "";
    document.cookie =
      `${this.persistKeyValue}=${slug}; path=/; max-age=31536000; samesite=lax${secure}`;
  }
}
