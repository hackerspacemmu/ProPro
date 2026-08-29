# ADR 003 — Keep EasyMDE; the mockup toolbar is decorative

Date: 2026-08-28
Status: Accepted

## Context

The mockup shows a six-button toolbar (bold/italic/underline/lists/link/code)
on the description editor. The application already uses EasyMDE (loaded
app-wide in the layout) via `data-controller="markdown-editor"`, tuned to
mirror the `commonmarker` renderer used across the app (tables,
strikethrough, turndown paste conversion).

## Decision

Keep EasyMDE and the existing `markdown_editor_controller` unchanged. Restyle
its container to the mockup's Field surface (label, border, hint). The
mockup's toolbar is a visual stand-in, not a functional spec.

## Consequences

- No new editor dependency and no custom toolbar wiring.
- Rich-text behavior (paste conversion, preview, guide) stays consistent app-wide.