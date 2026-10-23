import { Controller } from "@hotwired/stimulus";

// Drag-resize for the comments panel (#comments-drawer) on the project/topic
// show pages. Desktop only (>=1245px), where the panel is a static column in
// the layout; below that it is a fixed overlay whose width belongs to the
// breakpoint, not to us.
//
// The width is applied as the CSS variable --comments-w on the drawer, which
// the class list consumes only under min-[1245px]: so the mobile overlay is
// never affected. The value is persisted in a cookie
// (propro_comments_panel_width) written by this controller and read back
// server-side (ApplicationHelper#comments_panel_width), so the first paint
// already carries the saved width - no flash, and it survives the full-page
// redirect that follows posting a comment.
//
// This controller deliberately does not touch translate-x-full, shadow-2xl,
// border-l, the backdrop or the trigger's aria-expanded: those belong to
// comments_drawer_controller.js.
export default class extends Controller {
  static targets = ["drawer", "handle"];
  static DESKTOP_QUERY = "(min-width: 1245px)";
  static MIN_WIDTH = 320;
  static MAX_WIDTH = 560;
  static DEFAULT_WIDTH = 360;
  static STEP = 16;
  // Shift multiplies the keyboard step: 16px normally, 48px with Shift held.
  static SHIFT_MULTIPLIER = 3;
  static COOKIE_NAME = "propro_comments_panel_width";

  connect() {
    this.onPointerDown = this.onPointerDown.bind(this);
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.onLostPointerCapture = this.onLostPointerCapture.bind(this);
    this.onKeydown = this.onKeydown.bind(this);
    this.onDblClick = this.onDblClick.bind(this);

    const handle = this.handleTarget;
    handle.addEventListener("pointerdown", this.onPointerDown);
    handle.addEventListener("pointermove", this.onPointerMove);
    handle.addEventListener("pointerup", this.onPointerUp);
    handle.addEventListener("pointercancel", this.onPointerUp);
    handle.addEventListener("lostpointercapture", this.onLostPointerCapture);
    handle.addEventListener("keydown", this.onKeydown);
    handle.addEventListener("dblclick", this.onDblClick);

    this.dragging = false;
    this.width = this.readWidth();
    this.updateAria(this.width);
  }

  disconnect() {
    if (this.hasHandleTarget) {
      const handle = this.handleTarget;
      handle.removeEventListener("pointerdown", this.onPointerDown);
      handle.removeEventListener("pointermove", this.onPointerMove);
      handle.removeEventListener("pointerup", this.onPointerUp);
      handle.removeEventListener("pointercancel", this.onPointerUp);
      handle.removeEventListener(
        "lostpointercapture",
        this.onLostPointerCapture,
      );
      handle.removeEventListener("keydown", this.onKeydown);
      handle.removeEventListener("dblclick", this.onDblClick);
    }
    this.endDrag();
  }

  isDesktop() {
    return window.matchMedia(this.constructor.DESKTOP_QUERY).matches;
  }

  // The width the server rendered into the drawer's inline --comments-w.
  readWidth() {
    const raw = getComputedStyle(this.drawerTarget).getPropertyValue(
      "--comments-w",
    );
    const parsed = parseFloat(raw);
    if (!Number.isFinite(parsed)) return this.constructor.DEFAULT_WIDTH;
    return this.clamp(parsed);
  }

  clamp(width) {
    return Math.min(
      Math.max(width, this.constructor.MIN_WIDTH),
      this.constructor.MAX_WIDTH,
    );
  }

  applyWidth(width) {
    this.width = this.clamp(width);
    this.drawerTarget.style.setProperty("--comments-w", `${this.width}px`);
    this.updateAria(this.width);
    return this.width;
  }

  writeCookie(width) {
    const secure = window.location.protocol === "https:" ? "; secure" : "";
    document.cookie = `${this.constructor.COOKIE_NAME}=${width}; path=/; max-age=31536000; samesite=lax${secure}`;
  }

  updateAria(width) {
    const handle = this.handleTarget;
    handle.setAttribute("aria-valuenow", String(width));
    handle.setAttribute("aria-valuemin", String(this.constructor.MIN_WIDTH));
    handle.setAttribute("aria-valuemax", String(this.constructor.MAX_WIDTH));
  }

  onPointerDown(event) {
    if (!this.isDesktop()) return;
    if (event.button !== 0) return;

    this.dragging = true;
    this.startX = event.clientX;
    this.startWidth = this.width;

    try {
      this.handleTarget.setPointerCapture(event.pointerId);
    } catch {
      // A pointer event that was synthesised (or a pointer already released)
      // has no active pointer to capture. The drag still works: the move
      // listener sits on the handle itself.
    }
    document.body.classList.add("select-none", "cursor-col-resize");
    event.preventDefault();
    this.handleTarget.focus();
  }

  onPointerMove(event) {
    if (!this.dragging) return;
    if (!this.isDesktop()) return;

    // The handle sits on the drawer's left edge, so dragging it left (a
    // decreasing clientX) widens the panel.
    this.applyWidth(this.startWidth + (this.startX - event.clientX));
  }

  onPointerUp() {
    if (!this.dragging) return;
    this.endDrag();
    this.writeCookie(this.width);
  }

  onLostPointerCapture() {
    if (!this.dragging) return;
    this.endDrag();
    this.writeCookie(this.width);
  }

  endDrag() {
    this.dragging = false;
    document.body.classList.remove("select-none", "cursor-col-resize");
  }

  onKeydown(event) {
    if (!this.isDesktop()) return;

    const step =
      this.constructor.STEP *
      (event.shiftKey ? this.constructor.SHIFT_MULTIPLIER : 1);

    let next = null;
    if (event.key === "ArrowLeft") next = this.width + step;
    else if (event.key === "ArrowRight") next = this.width - step;
    else return;

    event.preventDefault();
    this.writeCookie(this.applyWidth(next));
  }

  onDblClick(event) {
    if (!this.isDesktop()) return;

    event.preventDefault();
    this.writeCookie(this.applyWidth(this.constructor.DEFAULT_WIDTH));
  }
}
