import { Application } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

import SidebarController from "./controllers/sidebar_controller.js"
import PageController from "./controllers/page_controller.js"

window.Stimulus = Application.start()
Stimulus.register("sidebar", SidebarController)
Stimulus.register("page", PageController)
