import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "filename", "placeholder", "hidden"];

  update() {
    const file = this.inputTarget.files?.[0];
    if (!file) return;

    if (this.filenameTarget) {
      this.filenameTarget.textContent = file.name;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target.result;

      if (this.previewTarget) {
        this.previewTarget.src = dataUrl;
        this.previewTarget.hidden = false;
      }
      if (this.hiddenTarget) {
        this.hiddenTarget.value = dataUrl;
      }
      if (this.placeholderTarget) {
        this.placeholderTarget.hidden = true;
      }
    };
    reader.readAsDataURL(file);
  }
}
