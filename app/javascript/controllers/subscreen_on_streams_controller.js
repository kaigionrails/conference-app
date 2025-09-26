import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    shiratakiUrl: String,
    room: String,
    fontSize: { type: String, default: "text-7xl" },
  }

  static targets = ["jaTranscribe", "enTranscribe"]

  connect() {
    console.log(this.shiratakiUrlValue)
    this.currentJaElement = null
    this.currentEnElement = null
    this.listernShiratakiEvent()
  }

  listernShiratakiEvent() {
    // Japanese EventSource
    const jaEventSource = new EventSource(`${this.shiratakiUrlValue}/sse?room=${this.roomValue}&language=ja`)
    jaEventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        this.displayJaMessage(data)
      } catch (error) {
        console.error("Failed to parse Japanese message:", error)
      }
    }
    jaEventSource.onerror = (event) => {
      console.error("Japanese EventSource failed:", event)
      jaEventSource.close()
    }

    // English EventSource
    const enEventSource = new EventSource(`${this.shiratakiUrlValue}/sse?room=${this.roomValue}&language=en`)
    enEventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        this.displayEnMessage(data)
      } catch (error) {
        console.error("Failed to parse English message:", error)
      }
    }
    enEventSource.onerror = (event) => {
      console.error("English EventSource failed:", event)
      enEventSource.close()
    }
  }

  displayJaMessage(data) {
    // Check if message is in data.data format
    const messageData = data.data || data

    // Skip if no text
    if (!messageData.text) {
      console.log("No text in Japanese message:", data)
      return
    }

    // Check if is_final
    const isFinal = messageData.is_final === "true" || messageData.is_final === true

    if (isFinal) {
      // Create new element for finalized text
      const messageElement = document.createElement("span")
      messageElement.className = `mb-2 text-theme-primary ${this.fontSizeValue} leading-relaxed`
      messageElement.textContent = messageData.text

      // Remove current temporary element if exists
      if (this.currentJaElement) {
        this.currentJaElement.remove()
        this.currentJaElement = null
      }

      // Add finalized element
      this.jaTranscribeTarget.appendChild(messageElement)
    } else {
      // Update or create element for unfinalized text
      if (!this.currentJaElement) {
        this.currentJaElement = document.createElement("span")
        this.currentJaElement.className = `mb-2 text-gray-400 ${this.fontSizeValue} leading-relaxed italic`
        this.jaTranscribeTarget.appendChild(this.currentJaElement)
      }

      // Update text
      this.currentJaElement.textContent = messageData.text
    }

    // Auto scroll to show latest message
    this.jaTranscribeTarget.scrollTop = this.jaTranscribeTarget.scrollHeight
  }

  displayEnMessage(data) {
    // Check if message is in data.data format
    const messageData = data.data || data

    // Skip if no text
    if (!messageData.text) {
      console.log("No text in English message:", data)
      return
    }

    // Check if is_final
    const isFinal = messageData.is_final === "true" || messageData.is_final === true

    if (isFinal) {
      // Create new element for finalized text
      const messageElement = document.createElement("span")
      messageElement.className = `mb-2 text-theme-primary ${this.fontSizeValue} leading-relaxed`
      messageElement.textContent = messageData.text

      // Remove current temporary element if exists
      if (this.currentEnElement) {
        this.currentEnElement.remove()
        this.currentEnElement = null
      }

      // Add finalized element
      this.enTranscribeTarget.appendChild(messageElement)
    } else {
      // Update or create element for unfinalized text
      if (!this.currentEnElement) {
        this.currentEnElement = document.createElement("span")
        this.currentEnElement.className = `mb-2 text-gray-400 ${this.fontSizeValue} leading-relaxed italic`
        this.enTranscribeTarget.appendChild(this.currentEnElement)
      }

      // Update text
      this.currentEnElement.textContent = messageData.text
    }

    // Auto scroll to show latest message
    this.enTranscribeTarget.scrollTop = this.enTranscribeTarget.scrollHeight
  }
}
