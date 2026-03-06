import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="markdown-editor"
export default class extends Controller {
  connect() {
    this.editor = new window.EasyMDE({
      element: this.element,
      forceSync: true,
      status: false,
      spellChecker: false,
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
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea();
      this.editor = null;
    }
  }
}
