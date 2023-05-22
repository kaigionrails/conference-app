import { Controller } from "@hotwired/stimulus"

const profileFormField = ""

export default class extends Controller {

  connect() {
    console.info("profiles controller")
  }

  addProfileImageField(event) {
    event.preventDefault()
    const insertTargetElement = document.getElementById("profile-image-fields")
    let fieldElement = document.createElement("input")
    fieldElement.setAttribute("type", "file")
    fieldElement.setAttribute("name", "profile[images][]")
    fieldElement.setAttribute("accept", "image/png, image/jpeg")
    insertTargetElement.append(fieldElement)
  }
}
