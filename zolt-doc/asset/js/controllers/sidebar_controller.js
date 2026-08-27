import { Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

export default class extends Controller {
  static targets = ["link"]

  activate(event) {
    this.linkTargets.forEach(el => el.classList.remove("active"))
    event.currentTarget.classList.add("active")
  }
}
