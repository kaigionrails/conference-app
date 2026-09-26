import { Controller } from "@hotwired/stimulus";
import JSZip from "jszip";
import QRCode from "qrcode";

export default class extends Controller {
  static targets = ["error", "cardError", "cardProgress"];

  static values = {
    sponsors: Array,
    zipFilename: String,
    cards: Array,
    cardZipFilename: String,
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

      await this.downloadZip(zip, this.zipFilenameValue);
    } catch {
      this.errorTarget.hidden = false;
    } finally {
      button.disabled = false;
    }
  }

  async downloadCard(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const { url, filename } = button.dataset;
    button.disabled = true;
    this.hideCardError();

    try {
      this.downloadBlob(await this.fetchCard(url), filename);
    } catch {
      this.showCardError("Could not generate the QR card. Please try again.");
    } finally {
      button.disabled = false;
    }
  }

  // Cards are generated on the server one by one to keep the load low.
  // A card that fails is skipped so that the others can still be downloaded.
  async downloadAllCards(event) {
    event.preventDefault();
    const button = event.currentTarget;
    button.disabled = true;
    this.hideCardError();

    const total = this.cardsValue.length;
    const failedNames = [];

    try {
      const zip = new JSZip();

      for (const [index, card] of this.cardsValue.entries()) {
        try {
          zip.file(card.filename, await this.fetchCard(card.url));
        } catch {
          failedNames.push(card.name);
        }
        this.cardProgressTarget.textContent = `${index + 1} / ${total}`;
      }

      if (failedNames.length < total) {
        await this.downloadZip(zip, this.cardZipFilenameValue);
      }
      if (failedNames.length > 0) {
        this.showCardError(`Could not generate QR cards for: ${failedNames.join(", ")}`);
      }
    } catch {
      this.showCardError("Could not create the ZIP file. Please try again.");
    } finally {
      this.cardProgressTarget.textContent = "";
      button.disabled = false;
    }
  }

  // A redirect means the session has expired or the user is not an organizer.
  // Following it would save the HTML of the top page as a PNG.
  async fetchCard(url) {
    const response = await fetch(url, { redirect: "error" });
    if (!response.ok) {
      throw new Error(`Failed to generate a QR card: ${response.status}`);
    }
    return response.blob();
  }

  generateQrCode(url) {
    return QRCode.toDataURL(url, {
      width: 1200,
      margin: 4,
      errorCorrectionLevel: "H",
    });
  }

  async downloadZip(zip, filename) {
    this.downloadBlob(await zip.generateAsync({ type: "blob" }), filename);
  }

  downloadBlob(blob, filename) {
    const blobUrl = URL.createObjectURL(blob);
    try {
      this.downloadFile(blobUrl, filename);
    } finally {
      setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
    }
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

  showCardError(message) {
    this.cardErrorTarget.textContent = message;
    this.cardErrorTarget.hidden = false;
  }

  hideCardError() {
    this.cardErrorTarget.hidden = true;
  }
}
