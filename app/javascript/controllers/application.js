import { Application } from "@hotwired/stimulus";
import Dropdown from "stimulus-dropdown";
import Lightbox from "stimulus-lightbox";

const application = Application.start();
application.register("dropdown", Dropdown);
application.register("lightbox", Lightbox);

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };
