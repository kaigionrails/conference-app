import { Controller } from "@hotwired/stimulus";
import JSZip from "jszip";
import QRCode from "qrcode";

export default class extends Controller {
  static targets = ["error"];

  static values = {
    sponsors: Array,
    zipFilename: String,
  };

  async download(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const { url, filename } = button.dataset;
    button.disabled = true;
    this.errorTarget.hidden = true;

    try {
      const dataUrl = await this.generateQrCode(url);
      this.downloadFile(dataUrl, filename);
    } catch {
      this.errorTarget.hidden = false;
    } finally {
      button.disabled = false;
    }
  }

  async downloadAll(event) {
    event.preventDefault();
    const button = event.currentTarget;
    button.disabled = true;
    this.errorTarget.hidden = true;

    try {
      const zip = new JSZip();

      for (const sponsor of this.sponsorsValue) {
        const dataUrl = await this.generateQrCode(sponsor.url);
        zip.file(sponsor.filename, dataUrl.split(",")[1], { base64: true });
      }

      const blob = await zip.generateAsync({ type: "blob" });
      const blobUrl = URL.createObjectURL(blob);
      try {
        this.downloadFile(blobUrl, this.zipFilenameValue);
      } finally {
        setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
      }
    } catch {
      this.errorTarget.hidden = false;
    } finally {
      button.disabled = false;
    }
  }

  generateQrCode(url) {
    return QRCode.toDataURL(url, {
      width: 1200,
      margin: 4,
      errorCorrectionLevel: "H",
    });
  }

  downloadFile(url, filename) {
    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.append(link);
    try {
      link.click();
    } finally {
      link.remove();
    }
  }
}
