import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    console.info("profiles controller");
  }

  addProfileImageField(event, className) {
    event.preventDefault();
    const insertTargetElement = document.getElementById("profile-image-fields");
    let fieldElement = document.createElement("input");
    fieldElement.setAttribute("type", "file");
    fieldElement.setAttribute("name", "profile[images][]");
    fieldElement.setAttribute("accept", "image/png, image/jpeg");
    fieldElement.setAttribute("class", className);
    insertTargetElement.append(fieldElement);
  }

  addProfileImageFieldForPc(event) {
    const className =
      "block w-96 text-sm text-gray-900 border border-gray-300 rounded-md cursor-pointer bg-white focus:outline-none mb-4";
    this.addProfileImageField(event, className);
  }

  addProfileImageFieldForSp(event) {
    const className =
      "block w-full text-sm text-gray-900 border border-gray-300 rounded-md cursor-pointer bg-white focus:outline-none mb-4";
    this.addProfileImageField(event, className);
  }
}
