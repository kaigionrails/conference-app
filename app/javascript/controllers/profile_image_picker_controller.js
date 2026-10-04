import { Controller } from "@hotwired/stimulus";

// Previews the images picked on the profile form, and lets one be taken out
// of the selection before the form is sent.
export default class extends Controller {
  static targets = ["input", "previews", "template"];

  connect() {
    this.objectUrls = [];
  }

  disconnect() {
    this.revokeObjectUrls();
  }

  // Picking again replaces the selection, as the browser does on its own.
  preview() {
    this.revokeObjectUrls();
    this.previewsTarget.replaceChildren(
      ...Array.from(this.inputTarget.files, (file, index) =>
        this.buildPreview(file, index)
      )
    );
  }

  remove({ params: { index } }) {
    const dataTransfer = new DataTransfer();
    Array.from(this.inputTarget.files).forEach((file, i) => {
      if (i !== index) dataTransfer.items.add(file);
    });
    // Assigning files does not fire change, so the previews are redrawn here.
    this.inputTarget.files = dataTransfer.files;
    this.preview();
  }

  buildPreview(file, index) {
    const preview = this.templateTarget.content.cloneNode(true);
    const url = URL.createObjectURL(file);
    this.objectUrls.push(url);

    const img = preview.querySelector("img");
    img.src = url;
    img.alt = file.name;
    preview.querySelector("button").dataset.profileImagePickerIndexParam = index;
    return preview;
  }

  revokeObjectUrls() {
    this.objectUrls.forEach((url) => URL.revokeObjectURL(url));
    this.objectUrls = [];
  }
}
