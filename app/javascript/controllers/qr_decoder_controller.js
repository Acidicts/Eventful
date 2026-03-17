import { Controller } from "@hotwired/stimulus";
import jsQR from "jsqr";

// Front‑end scanner that grabs frames from the camera and uses the
// jsQR library (loaded via importmap) to decode QR codes.
// includes debug logging to help diagnose detection issues.
export default class extends Controller {
  static targets = ["video", "canvas", "output", "manualInput", "successTick"];
  static values = {
    url: String,
    codeParamField: String, // name of the JSON field to carry the decoded string
    operation: String, // e.g. "sign_in", "sign_out", "lookup"
  };

  connect() {
    this.hideSuccessTick();
    this.startCamera();
  }

  async startCamera() {
    try {
      // if there's an existing stream, stop it first
      if (this.videoTarget.srcObject) {
        this.videoTarget.srcObject.getTracks().forEach((t) => t.stop());
      }

      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
      });
      this.videoTarget.srcObject = stream;
      this.videoTarget.setAttribute("playsinline", true); // iOS Safari
      this.videoTarget.play();
      requestAnimationFrame(this.tick.bind(this));
    } catch (err) {
      console.error("camera error", err);
      this.outputTarget.textContent = "Unable to access camera: " + err.message;
    }
  }

  tick() {
    if (this.videoTarget.readyState === this.videoTarget.HAVE_ENOUGH_DATA) {
      const canvas = this.canvasTarget;
      const context = canvas.getContext("2d");
      canvas.width = this.videoTarget.videoWidth;
      canvas.height = this.videoTarget.videoHeight;
      context.drawImage(this.videoTarget, 0, 0, canvas.width, canvas.height);
      const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
      let code = null;
      try {
        code = jsQR(imageData.data, imageData.width, imageData.height);
      } catch (e) {
        console.error("jsQR decode error", e);
      }
      if (code) {
        console.log("qr decoded", code.data);
        this.outputTarget.textContent = code.data;
        // stop the camera once we have a result
        this.videoTarget.srcObject.getTracks().forEach((track) => track.stop());

        if (this.hasUrlValue) {
          this.sendCode(code.data);
        }
        return;
      }
    }
    requestAnimationFrame(this.tick.bind(this));
  }

  // allow restarting the camera manually (bound via data-action)
  restart() {
    if (this.outputTarget) {
      this.outputTarget.textContent = "";
    }
    this.hideSuccessTick();
    this.startCamera();
  }

  hideSuccessTick() {
    if (this.hasSuccessTickTarget) {
      this.successTickTarget.style.display = "none";
    }
  }

  showSuccessTick() {
    if (this.hasSuccessTickTarget) {
      this.successTickTarget.style.display = "block";
    }
  }

  wasSuccessful(message) {
    if (!message || !this.hasOperationValue) return false;

    if (
      this.operationValue === "sign_in" ||
      this.operationValue === "sign_out"
    ) {
      return message.toLowerCase().includes("successfully");
    }

    return this.operationValue === "get_info";
  }

  // send a code value to the server using the same logic as the scanner
  sendCode(code) {
    const payload = {};
    const field = this.hasCodeParamFieldValue
      ? this.codeParamFieldValue
      : "text";
    payload[field] = code;
    if (this.hasOperationValue) payload.operation = this.operationValue;

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content,
      },
      body: JSON.stringify(payload),
    })
      .then((resp) => {
        if (resp.redirected) {
          this.showSuccessTick();
          window.location = resp.url;
        } else if (!resp.ok) {
          console.error("scan POST failed", resp.status);
        } else {
          resp
            .json()
            .then((json) => {
              if (json.message) {
                this.outputTarget.textContent = json.message;
                if (this.wasSuccessful(json.message)) {
                  this.showSuccessTick();
                } else {
                  this.hideSuccessTick();
                }
              }
            })
            .catch(() => {});
        }
      })
      .catch((err) => console.error("scan POST error", err));
  }

  // submit handler for manual entry form
  manualSubmit(event) {
    event.preventDefault();
    if (!this.hasManualInputTarget) return;
    const code = this.manualInputTarget.value.trim();
    if (code) {
      this.sendCode(code);
      this.manualInputTarget.value = "";
    }
  }
}
