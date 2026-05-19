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

  // ── Open / close main modal ──────────────────────────────────────────────

  open(event) {
    const btn = event.currentTarget
    this._groupId   = btn.dataset.groupId
    this._groupName = btn.dataset.groupName
    this._studentId = null

    this.groupNameTarget.textContent      = this._groupName
    this.searchTarget.value               = ""
    this.confirmBtnTarget.disabled        = true
    this._renderList()

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

  // ── Search / select ──────────────────────────────────────────────────────

  filter() {
    this._renderList()
  }

  select(event) {
    const row       = event.currentTarget
    this._studentId = row.dataset.studentId
    this.confirmBtnTarget.disabled = false
    this._renderList()
  }

  // ── Confirm dialog ───────────────────────────────────────────────────────

  showConfirm() {
    if (!this._studentId || !this._groupName) return

    const el     = this._ungroupedEl(this._studentId)
    const name   = el?.dataset.studentName   || ""
    const instid = el?.dataset.studentInstid || ""

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

  // ── Private ──────────────────────────────────────────────────────────────

  _ungroupedEl(id) {
    return document.querySelector(`#ungrouped-students-list [data-student-id="${id}"]`)
  }

  _renderList() {
    const q        = this.searchTarget.value.toLowerCase()
    const students = Array.from(
      document.querySelectorAll("#ungrouped-students-list [data-student-id]")
    )

    const filtered = students.filter(el => {
      const name   = (el.dataset.studentName   || "").toLowerCase()
      const instid = (el.dataset.studentInstid || "").toLowerCase()
      return name.includes(q) || instid.includes(q)
    })

    if (!filtered.length) {
      this.studentListTarget.innerHTML =
        '<p class="text-xs text-gray-400 px-2 py-3">No ungrouped students match.</p>'
      return
    }

    this.studentListTarget.innerHTML = filtered.map(el => {
      const id       = el.dataset.studentId
      const name     = el.dataset.studentName
      const instid   = el.dataset.studentInstid || ""
      const initials = name.split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase()
      const selected = id === String(this._studentId)

      return `
        <div class="flex items-center gap-2.5 px-2 py-2 rounded-[3px] cursor-pointer transition-colors ${selected ? "bg-blue-50" : "hover:bg-gray-50"}"
             data-student-id="${id}"
             data-action="click->add-member-popup#select">
          <div class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-gray-200 text-[11px] font-bold text-gray-600 shrink-0">
            ${initials}
          </div>
          <div class="leading-tight min-w-0">
            <span class="text-sm text-gray-800 block truncate">${name}</span>
            ${instid ? `<span class="text-xs text-gray-400 font-mono">${instid}</span>` : ""}
          </div>
          ${selected ? '<svg class="ml-auto shrink-0 text-[#1F78D1]" xmlns="http://www.w3.org/2000/svg" height="16px" viewBox="0 -960 960 960" width="16px" fill="currentColor"><path d="M382-240 154-468l57-57 171 171 367-367 57 57-424 424Z"/></svg>' : ""}
        </div>
      `
    }).join("")
  }
}