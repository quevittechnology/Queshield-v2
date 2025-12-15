// QueShield Web Dashboard JavaScript

// Fetch and display threat statistics
async function loadStats() {
    try {
        const response = await fetch('/api/threats');
        const data = await response.json();

        const threatCount = document.getElementById('threatCount');
        if (threatCount) {
            threatCount.textContent = data.totalThreats.toLocaleString();
        }
    } catch (error) {
        console.error('Failed to load stats:', error);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadStats();
});
