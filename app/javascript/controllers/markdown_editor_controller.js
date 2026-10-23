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

    // 3b. The textarea is hidden, so the browser cannot show its own
    // validation bubble for a required field ("an invalid form control is not
    // focusable") and the submit looks dead. Surface the message on the
    // visible editor instead.
    this.invalidHandler = this.handleInvalid.bind(this);
    this.element.addEventListener("invalid", this.invalidHandler);
    this.editor.codemirror.on("change", () => this.clearInvalid());

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
    if (this.invalidHandler) {
      this.element.removeEventListener("invalid", this.invalidHandler);
      this.invalidHandler = null;
    }
    this.clearInvalid();
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

  // The browser fired `invalid` on the hidden textarea, meaning a required
  // field is empty. It cannot show its own bubble here, so paint the error on
  // the visible editor and move the caret into it.
  handleInvalid(event) {
    event.preventDefault();

    const wrapper = this.editorWrapper();
    const container = this.editorContainer();
    if (!wrapper || !container) return;

    wrapper.classList.add("ring-2", "ring-error", "rounded-[4px]");

    if (!this.errorElement) {
      this.errorElement = document.createElement("p");
      this.errorElement.className = "text-[12px] text-error mt-1";
      this.errorElement.dataset.markdownEditorError = "";
      container.insertAdjacentElement("afterend", this.errorElement);
    }
    this.errorElement.textContent = this.element.validationMessage;

    this.editor.codemirror.focus();
  }

  clearInvalid() {
    if (this.errorElement) {
      this.errorElement.remove();
      this.errorElement = null;
    }

    this.editorWrapper()?.classList.remove(
      "ring-2",
      "ring-error",
      "rounded-[4px]",
    );
  }

  // The visible CodeMirror box inside EasyMDE's wrapper.
  editorWrapper() {
    return this.editor?.codemirror?.getWrapperElement() || null;
  }

  // EasyMDE's container, which holds the editor and its toolbar.
  editorContainer() {
    return this.editorWrapper()?.closest(".EasyMDEContainer") || null;
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
      console.error(
        "Turndown conversion failed, falling back to plain text:",
        error,
      );
      const plainText = event.clipboardData.getData("text/plain");
      cm.replaceSelection(plainText);
    }
  }
}
