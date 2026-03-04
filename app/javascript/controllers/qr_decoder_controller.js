import { Controller } from "@hotwired/stimulus"
import jsQR from "jsqr"

// Front‑end scanner that grabs frames from the camera and uses the
// jsQR library (loaded via importmap) to decode QR codes.
// includes debug logging to help diagnose detection issues.
export default class extends Controller {
  static targets = ["video", "canvas", "output"]

  connect() {
    this.startCamera()
  }

  async startCamera() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" }
      })
      this.videoTarget.srcObject = stream
      this.videoTarget.setAttribute("playsinline", true) // iOS Safari
      this.videoTarget.play()
      requestAnimationFrame(this.tick.bind(this))
    } catch (err) {
      console.error("camera error", err)
      this.outputTarget.textContent = "Unable to access camera: " + err.message
    }
  }

  tick() {
    if (this.videoTarget.readyState === this.videoTarget.HAVE_ENOUGH_DATA) {
      const canvas = this.canvasTarget
      const context = canvas.getContext("2d")
      canvas.width = this.videoTarget.videoWidth
      canvas.height = this.videoTarget.videoHeight
      context.drawImage(this.videoTarget, 0, 0, canvas.width, canvas.height)
      const imageData = context.getImageData(0, 0, canvas.width, canvas.height)
      let code = null
      try {
        code = jsQR(imageData.data, imageData.width, imageData.height)
      } catch (e) {
        console.error("jsQR decode error", e)
      }
      if (code) {
        console.log("qr decoded", code.data)
        this.outputTarget.textContent = code.data
        // stop the camera once we have a result
        this.videoTarget.srcObject.getTracks().forEach(track => track.stop())
        return
      }
    }
    requestAnimationFrame(this.tick.bind(this))
  }
}
