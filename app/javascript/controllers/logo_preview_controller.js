import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "filename", "placeholder", "hidden"];

  connect() {
    // no-op: this controller only reacts to file input changes
  }

  update() {
    const input = this.hasInputTarget
      ? this.inputTarget
      : this.element.querySelector('input[type="file"]');
    const file = input?.files?.[0];
    if (!file) return;

    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = file.name;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target.result;
      const preview = this.hasPreviewTarget
        ? this.previewTarget
        : this.element.querySelector('[data-logo-preview-target="preview"]');

      if (preview) {
        preview.src = dataUrl;
        preview.hidden = false;
      }

      const hiddenInput = this.hasHiddenTarget
        ? this.hiddenTarget
        : this.element.querySelector('[data-logo-preview-target="hidden"]');
      if (hiddenInput) {
        hiddenInput.value = dataUrl;
      }

      const placeholder = this.hasPlaceholderTarget
        ? this.placeholderTarget
        : this.element.querySelector(
            '[data-logo-preview-target="placeholder"]',
          );
      if (placeholder) {
        placeholder.hidden = true;
      }
    };
    reader.readAsDataURL(file);
  }
}
