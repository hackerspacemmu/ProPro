import { Controller } from "@hotwired/stimulus";
import TurndownService from "turndown";
import { tables, strikethrough } from "turndown-plugin-gfm";

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

    // 4. Convert rich clipboard paste (Word/Docs/Notion/ChatGPT) to markdown
    // Listener goes on codemirror — textarea is hidden, never gets paste events
    this.turndownService = this.buildTurndownService();
    this.handlePaste = this.handlePaste.bind(this);
    this.editor.codemirror.on("paste", this.handlePaste);

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
      this.editor.codemirror.off("paste", this.handlePaste);
      this.editor.toTextArea();
      this.editor = null;
    }
  }

  setValue(event) {
    const value = event.detail?.value || this.element.value;
  
    if (this.editor) {
      this.editor.value(value);
    }
  }

  // Mirror Redcarpet's enabled extensions so paste matches typed output
  buildTurndownService() {
    const service = new TurndownService({
      headingStyle: "atx",
      bulletListMarker: "-",
      codeBlockStyle: "fenced",
      fence: "```",
      emDelimiter: "_",
    });

    service.use([tables, strikethrough]);

    return service;
  }

  handlePaste(cm, event) {
    const html = event.clipboardData?.getData("text/html");

    // No HTML on clipboard -> nothing to convert, let default paste run
    if (!html) return;

    event.preventDefault();

    try {
      const markdown = this.turndownService.turndown(html);
      cm.replaceSelection(markdown);
    } catch (error) {
      // Turndown choked on this HTML -> fall back to plain text
      console.error("Turndown conversion failed, falling back to plain text:", error);
      const plainText = event.clipboardData.getData("text/plain");
      cm.replaceSelection(plainText);
    }
  }
}