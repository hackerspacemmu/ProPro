import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="markdown-editor"
export default class extends Controller {
  connect() {
    // 1. Guard against double-initialization
    if (this.editor) return;

    // 2. Initialize EasyMDE
    this.editor = new window.EasyMDE({
      element: this.element,
      forceSync: true,
      status: false,
      spellChecker: false,
      unorderedListStyle: "-",
      toolbar: [
        "bold",
        "italic",
        "heading",
        "|",
        "ordered-list",
        "unordered-list",
        "|",
        "code",
        "quote",
        "link",
        "table",
        "|",
        "preview",
        "guide",
      ],
    });

    this.editor.codemirror.setOption("viewportMargin", Infinity);

    // 3. Force hide the original textarea
    this.element.style.setProperty("display", "none", "important");

    // Watch the textarea for DOM changes
    this.observer = new MutationObserver(() => {
      // If Turbo strips the hidden style, instantly put it back!
      if (this.element.style.display !== "none") {
        this.element.style.setProperty("display", "none", "important");
      }

      // If Turbo updates the textarea with autofill data, sync it into EasyMDE!
      const currentValue = this.element.value || this.element.textContent;
      if (this.editor && currentValue !== this.editor.value()) {
        this.editor.value(currentValue);
      }
    });

    // Start bodyguard duty on the textarea
    this.observer.observe(this.element, {
      attributes: true,
      childList: true,
      characterData: true,
    });
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
    if (this.editor) {
      this.editor.toTextArea();
      this.editor = null;
    }
  }
}
