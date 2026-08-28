import { Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

export default class extends Controller {
  connect() {
    this.onPopState = this.onPopState.bind(this)
    this.onFrameLoad = this.onFrameLoad.bind(this)
    window.addEventListener("popstate", this.onPopState)
    this.element.addEventListener("turbo:frame-load", this.onFrameLoad)
    this.navigateToPage(this.pageFromURL())
  }

  disconnect() {
    window.removeEventListener("popstate", this.onPopState)
    this.element.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  get frame() {
    return this.element.querySelector("turbo-frame#doc-content")
  }

  pageFromURL() {
    return new URLSearchParams(window.location.search).get("page") || ""
  }

  navigateToPage(page) {
    page = page.trim()
    if (!page) return
    // Only allow safe, same-origin relative paths like doc/install.luau.
    if (!/^[A-Za-z0-9._/-]+$/.test(page) || page.startsWith("/") || page.includes("..")) return

    const frame = this.frame
    if (!frame) return

    const path = "/" + page
    if (frame.src === window.location.origin + path) return

    this.updateActiveLink(page)
    frame.src = path
  }

  onPopState() {
    this.navigateToPage(this.pageFromURL())
  }

  onFrameLoad() {
    const frame = this.frame
    if (!frame || !frame.src) return

    let path
    try {
      path = new URL(frame.src, window.location.origin).pathname.replace(/^\/+/, "")
    } catch {
      return
    }
    if (!path) return

    const next = "/?page=" + path
    if (window.location.search === "?page=" + path) {
      this.updateActiveLink(path)
      return
    }
    window.history.pushState(null, "", next)
    this.updateActiveLink(path)
  }

  updateActiveLink(page) {
    document.querySelectorAll('[data-sidebar-target="link"]').forEach(el => {
      el.classList.toggle("active", (el.getAttribute("href") || "").replace(/^\/+/, "") === page)
    })
  }
}
