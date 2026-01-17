const toggleBtn = document.getElementById("menu-toggle");
const sidebar = document.getElementById("sidebar");

toggleBtn.addEventListener("click", () => {
    sidebar.classList.toggle("active");
});

// Fermer le menu après clic sur un lien
document.querySelectorAll("#sidebar a").forEach(link => {
    link.addEventListener("click", () => {
        sidebar.classList.remove("active");
    });
});
