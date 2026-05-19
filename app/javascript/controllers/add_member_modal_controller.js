import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "overlay",
    "confirmOverlay",
    "groupName",
    "search",
    "studentList",
    "confirmBtn",
    "confirmTitle",
    "confirmBody",
    "submitBtn",
  ]

  connect() {
    this._groupId   = null
    this._groupName = null
    this._studentId = null
  }

  // ── Open / close main modal

  open(event) {
    const btn = event.currentTarget
    this._groupId   = btn.dataset.groupId
    this._groupName = btn.dataset.groupName
    this._studentId = null

    this.groupNameTarget.textContent = this._groupName
    this.searchTarget.value          = ""
    this.confirmBtnTarget.disabled   = true

    this._resetRows()  // clear selection + show all rows
    this._filter("")   // re-apply empty filter (shows all)

    this.overlayTarget.classList.remove("hidden")
    this.searchTarget.focus()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this._groupId   = null
    this._groupName = null
    this._studentId = null
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) this.close()
  }

  // Search 

  filter() {
    this._filter(this.searchTarget.value)
  }

  _filter(query) {
    const q = query.toLowerCase()
    this._rows().forEach(row => {
      const name   = (row.dataset.studentName   || "").toLowerCase()
      const instid = (row.dataset.studentInstid || "").toLowerCase()
      row.classList.toggle("hidden", !(name.includes(q) || instid.includes(q)))
    })
  }

  // Select 

  select(event) {
    const row = event.currentTarget

    // Deselect all rows
    this._rows().forEach(r => {
      r.classList.remove("bg-blue-50")
      r.querySelector(".modal-student-check")?.classList.add("hidden")
    })

    // Select clicked row
    row.classList.add("bg-blue-50")
    row.querySelector(".modal-student-check")?.classList.remove("hidden")

    this._studentId = row.dataset.studentId
    this.confirmBtnTarget.disabled = false
  }

  // ── Confirm dialog ───────────────────────────────────────────────────────

  showConfirm() {
    if (!this._studentId || !this._groupName) return

    const row    = this._rowById(this._studentId)
    const name   = row?.dataset.studentName   || ""
    const instid = row?.dataset.studentInstid || ""

    this.confirmTitleTarget.textContent = `Add ${name} to ${this._groupName}?`
    this.confirmBodyTarget.textContent  =
      `${name}${instid ? " (" + instid + ")" : ""} will be added to ${this._groupName} and removed from the ungrouped list.`

    this.confirmOverlayTarget.classList.remove("hidden")
  }

  closeConfirm() {
    this.confirmOverlayTarget.classList.add("hidden")
  }

  closeConfirmOnBackdrop(event) {
    if (event.target === this.confirmOverlayTarget) this.closeConfirm()
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  submit() {
    if (!this._studentId || !this._groupId) return

    const courseId = this.element.dataset.courseId

    const form  = document.createElement("form")
    form.method = "POST"
    form.action = `/courses/${courseId}/project_groups/${this._groupId}/members`

    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (csrf) {
      const token   = document.createElement("input")
      token.type    = "hidden"
      token.name    = "authenticity_token"
      token.value   = csrf.content
      form.appendChild(token)
    }

    const uid   = document.createElement("input")
    uid.type    = "hidden"
    uid.name    = "user_id"
    uid.value   = this._studentId
    form.appendChild(uid)

    document.body.appendChild(form)
    form.submit()
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  _rows() {
    return Array.from(this.studentListTarget.querySelectorAll(".modal-student-row"))
  }

  _rowById(id) {
    return this.studentListTarget.querySelector(`[data-student-id="${id}"]`)
  }

  _resetRows() {
    this._rows().forEach(row => {
      row.classList.remove("bg-blue-50", "hidden")
      row.querySelector(".modal-student-check")?.classList.add("hidden")
    })
    this._studentId = null
    this.confirmBtnTarget.disabled = true
  }
}