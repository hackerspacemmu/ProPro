// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "project_template_fields";
import htmx from "htmx.org";

document.addEventListener("turbo:load", function () {
  htmx.process(document.body);
});
