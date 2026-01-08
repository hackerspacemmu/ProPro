import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static classes = ["active", "inactive"];
  connect() {
    // section is considered "active" if it hits 20%-60% of screen
    const observerOptions = {
      root: null,
      rootMargin: "-20% 0px -60% 0px",
      threshold: 0,
    };

    this.observer = new IntersectionObserver(
      this.onIntersect.bind(this),
      observerOptions,
    );

    this.sidebarLinks = this.element.querySelectorAll('a[href^="#"]');
    this.sidebarLinks.forEach((link) => {
      const id = link.getAttribute("href").replace("#", "");
      const section = document.getElementById(id);
      if (section) {
        this.observer.observe(section);
      }
    });
  }
  disconnect() {
    if (this.observer) this.observer.disconnect();
  }

  onIntersect(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        this.activate(entry.target.id);
      }
    });
  }

  activate(id) {
    this.sidebarLinks.forEach((link) => {
      const linkHref = link.getAttribute("href");
      if (linkHref === `#${id}`) {
        link.classList.remove(...this.inactiveClasses);
        link.classList.add(...this.activeClasses);
      } else {
        link.classList.remove(...this.activeClasses);
        link.classList.add(...this.inactiveClasses);
      }
    });
  }
}
