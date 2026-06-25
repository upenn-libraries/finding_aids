import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['list'];
  static values = { url: String };

  connect() {
    this.draggedRow = null;

    this.listTarget.querySelectorAll('.sortable-item').forEach((row) => {
      row.draggable = true;
      row.addEventListener('dragstart', (e) => this.onDragStart(e));
      row.addEventListener('dragover', (e) => this.onDragOver(e));
      row.addEventListener('drop', (e) => this.onDrop(e));
      row.addEventListener('dragend', () => this.onDragEnd());
    });
  }

  onDragStart(e) {
    this.draggedRow = e.currentTarget;
    this.draggedRow.classList.add('table-active');
    e.dataTransfer.effectAllowed = 'move';
  }

  onDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';

    const target = e.currentTarget;
    if (target !== this.draggedRow) {
      const rect = target.getBoundingClientRect();
      const midpoint = rect.top + rect.height / 2;
      if (e.clientY < midpoint) {
        target.parentNode.insertBefore(this.draggedRow, target);
      } else {
        target.parentNode.insertBefore(this.draggedRow, target.nextSibling);
      }
    }
  }

  onDrop(e) {
    e.preventDefault();
  }

  onDragEnd() {
    if (this.draggedRow) {
      this.draggedRow.classList.remove('table-active');
      this.draggedRow = null;
    }
    this.saveOrder();
  }

  saveOrder() {
    const ids = Array.from(this.listTarget.querySelectorAll('.sortable-item'))
      .map((row) => row.dataset.id);

    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ ids }),
    });
  }
}
