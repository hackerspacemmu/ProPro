import { Controller } from "@hotwired/stimulus";

// Page-level lightbox: a native <dialog> showing the enlarged screenshot of the
// section's media button that opened it. Page scroll locks while the dialog is
// open and the trigger that opened it regains focus on close. Escape closes
// natively; the close button and clicking the dark margin outside the image
// close too.
export default class extends Controller {
  static targets = ["image"];

  connect() {
    this.lastOpener = null;
    this.triggers = Array.from(
      document.querySelectorAll("[data-lightbox-target='trigger']"),
    );
    this.triggers.forEach((trigger) =>
      trigger.addEventListener("click", this.open),
    );
    this.element.addEventListener("close", this.onClose);
  }

  disconnect() {
    this.triggers.forEach((trigger) =>
      trigger.removeEventListener("click", this.open),
    );
    this.element.removeEventListener("close", this.onClose);
  }

  open = (event) => {
    const trigger = event.currentTarget;
    const shot = trigger.querySelector("[data-landing-target='image']");
    if (!shot) return;
    this.imageTarget.src = shot.src;
    this.imageTarget.alt = shot.alt;
    this.lastOpener = trigger;
    document.documentElement.style.overflow = "hidden";
    this.element.showModal();
  };

  close() {
    this.element.close();
  }

  backdrop = (event) => {
    if (event.target !== event.currentTarget) return;
    this.element.close();
  };

  onClose = () => {
    document.documentElement.style.overflow = "";
    if (this.lastOpener && this.lastOpener.focus) this.lastOpener.focus();
    this.lastOpener = null;
  };
}
