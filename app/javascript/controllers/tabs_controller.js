import { Controller } from "@hotwired/stimulus";

// Generic tab controller — deliberately NOT mobile_tabs_controller.js,
// which is hard-coded to 3 named targets for the project/topic show pages
// and out of scope for this work.
//
// Usage:
//   <div data-controller="tabs" data-tabs-active-class="...">
//     <button data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="0">...</button>
//     <button data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="1">...</button>
//     <div data-tabs-target="panel">...</div>
//     <div data-tabs-target="panel">...</div>
//   </div>
//
// The "Settings" entry in the tab bar is a plain link_to (real navigation
// to a separate page), not a data-tabs-target="tab" — it doesn't participate
// in this controller at all.
export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active", "inactive"];

  connect() {
    this.show({ params: { index: 0 } });
  }

  show(event) {
    const index = Number(event.params.index);

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
    });
  }
}
