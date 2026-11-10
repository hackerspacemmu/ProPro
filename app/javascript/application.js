// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "project_template_fields";
import "htmx.org";

document.addEventListener("turbo:load", function () {
  window.htmx.process(document.body);
});

// A morph must not strip `open` from a showModal() dialog: the dialog would stay
// modal (page inert) while no longer rendering. Dialogs close themselves instead.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.target instanceof HTMLDialogElement && event.detail.attributeName === "open") {
    event.preventDefault();
  }
});

Turbo.config.drive.confirmationMethod = (message, element, submitter) => {
  return Promise.resolve(window.confirm(message));
};