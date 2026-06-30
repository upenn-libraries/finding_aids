import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['repository', 'title'];
  static values = { titles: Object };

  connect() {
    this.filterTitles();

    // If editing an existing record, restore the selected title after filtering
    if (this.titleTarget.dataset.selected) {
      this.titleTarget.value = this.titleTarget.dataset.selected;
    }

    this.titleTarget.disabled = !this.repositoryTarget.value;
  }

  filterTitles() {
    const repo = this.repositoryTarget.value;
    const titles = repo ? (this.titlesValue[repo] || []) : [];
    const selected = this.titleTarget.dataset.selected || this.titleTarget.value;

    this.titleTarget.disabled = !repo;
    this.titleTarget.innerHTML = '';

    this._addPlaceholderOption(repo);
    this._addTitleOptions(titles, selected);
  }

  _addPlaceholderOption(repo) {
    const option = document.createElement('option');
    option.value = '';
    option.textContent = repo ? 'Select a collection…' : 'Select a repository first…';
    this.titleTarget.appendChild(option);
  }

  _addTitleOptions(titles, selected) {
    titles.forEach((title) => {
      const option = document.createElement('option');
      option.value = title;
      option.textContent = title;
      if (title === selected) option.selected = true;
      this.titleTarget.appendChild(option);
    });
  }
}
