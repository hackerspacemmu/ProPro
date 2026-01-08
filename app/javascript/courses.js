const progress = document.getElementById("progress");
const steps = document.querySelectorAll(".step");

const statusOrder = [
  "not_submitted",
  "rejected",
  "pending",
  "redo",
  "approved",
];
const currentStatus = '<%= @project&.status || "pending" %>';

updateStatusBar();

function updateStatusBar() {
  if (currentStatus === "none" || currentStatus === "rejected") {
    progress.style.width = "0%";
    return;
  }

  const idx = statusOrder.indexOf(currentStatus);
  if (idx < 0) return;

  steps.forEach((step, i) => {
    step.classList.toggle("active", i <= idx);
  });

  const pct = (idx / (statusOrder.length - 1)) * 100;
  progress.style.width = pct + "%";
}
