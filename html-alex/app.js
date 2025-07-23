const progress = document.getElementById("progress");
const prevBtn = document.getElementById("prev");
const nextBtn = document.getElementById("next");
const steps = document.querySelectorAll(".step");
let activeIndex = 1;

updateUI();

nextBtn.addEventListener("click", () => {
  activeIndex++;
  if (activeIndex > steps.length) {
    activeIndex = steps.length;
  }
  updateUI();              
});

prevBtn.addEventListener("click", () => {
  activeIndex--;
  if (activeIndex < 1) {
    activeIndex = 1;
  }
  updateUI();
});

function updateUI() {
  steps.forEach((step) => {
      step.classList.remove("active")
    });

    if (activeIndex > 0 && activeIndex <= steps.length) {
      steps[activeIndex - 1].classList.add("active");
    }
  
  progress.style.width = ((activeIndex - 1) / (steps.length - 1)) * 100 + "%";
    
  if (activeIndex === 1) {
    prevBtn.disabled = true;
  } else if (activeIndex === steps.length) {
    nextBtn.disabled = true;
  } else {
    prevBtn.disabled = false;
    nextBtn.disabled = false;
  }
}