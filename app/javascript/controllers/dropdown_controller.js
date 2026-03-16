import { Controller } from "@hotwired/stimulus";

// Simple dropdown controller for toggling a menu and closing on outside click.
export default class extends Controller {
  static targets = ["menu"];
  static values = { open: Boolean };

  connect() {
    this.close();
  }

  toggle(event) {
    event.preventDefault();
    this.openValue = !this.openValue;
    this._update();
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close();
    }
  }

  close() {
    this.openValue = false;
    this._update();
  }

  _update() {
    if (!this.hasMenuTarget) return;
    this.menuTarget.hidden = !this.openValue;
    const trigger = this.element.querySelector("[data-dropdown-trigger]");
    if (trigger) {
      trigger.setAttribute("aria-expanded", String(this.openValue));
    }
  }
}
