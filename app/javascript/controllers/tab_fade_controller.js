import { Controller } from "@hotwired/stimulus";

// Shows a trailing-edge fade over the horizontally-scrolling content-tabs strip
// while there is actually more content beyond the right edge. Hidden flatly on
// overflow AND when the user has scrolled to the end, so a wide viewport that
// shows every tab gets no gradient at all.
export default class extends Controller {
  static targets = ["scroller", "rightMask"];

  connect() {
    this.refresh();
    this._resizeHandler = () => this.refresh();
    this._scrollHandler = () => this.refresh();
    window.addEventListener("resize", this._resizeHandler);
    this.scrollerTarget.addEventListener("scroll", this._scrollHandler, {
      passive: true,
    });
  }

  disconnect() {
    window.removeEventListener("resize", this._resizeHandler);
    this.scrollerTarget.removeEventListener("scroll", this._scrollHandler);
  }

  refresh() {
    const scroller = this.scrollerTarget;
    const atEnd =
      scroller.scrollLeft + scroller.clientWidth >= scroller.scrollWidth - 1;
    const overflowing = scroller.scrollWidth > scroller.clientWidth;
    this.rightMaskTarget.classList.toggle("hidden", !(overflowing && !atEnd));
  }
}
