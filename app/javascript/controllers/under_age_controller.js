import { Controller } from "@hotwired/stimulus";

// toggles form fields when attendee indicates they are under 18
export default class extends Controller {
  static targets = ["participant", "parent"]

  toggle(event) {
    const under = event.target.checked;
    // always keep participant field visible; only show parent when underage
    this.parentTarget.style.display = under ? "block" : "none";
    // optionally change the label text for participant field
    const label = this.participantTarget.querySelector('label');
    if (label) {
      label.textContent = under
        ? "Participant name"
        : "Type your name to sign the waiver";
    }
  }
}
