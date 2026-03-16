import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["filter", "options", "selected"];
  static values = {
    name: String,
    available: Array,
    selected: Array,
  };

  connect() {
    this.availableItems = Array.isArray(this.availableValue)
      ? [...this.availableValue]
      : [];
    this.selectedItems = [];

    const selected = Array.isArray(this.selectedValue)
      ? this.selectedValue
      : typeof this.selectedValue === "string"
        ? this.selectedValue
            .replace(/\[|\]|\s/g, "")
            .split(",")
            .map((v) => parseInt(v, 10))
            .filter((v) => !Number.isNaN(v))
        : [];

    if (selected.length > 0) {
      this.selectedItems = this.availableItems.filter((item) =>
        selected.includes(item.id),
      );
      this.availableItems = this.availableItems.filter(
        (item) => !selected.includes(item.id),
      );
    }

    this.render();
  }

  filter() {
    this.render();
  }

  render() {
    this.renderOptions();
    this.renderSelected();
  }

  renderOptions() {
    const query = this.filterTarget.value.toLowerCase().trim();
    const filtered = this.availableItems.filter((item) =>
      item.name.toLowerCase().includes(query),
    );

    this.optionsTarget.innerHTML = "";

    if (filtered.length === 0) {
      const empty = document.createElement("li");
      empty.textContent = "No matching items";
      empty.style.opacity = "0.6";
      this.optionsTarget.appendChild(empty);
      return;
    }

    filtered.forEach((item) => {
      const li = document.createElement("li");
      li.textContent = item.name;
      li.dataset.action = "click->multi-select#add";
      li.dataset.id = item.id;
      this.optionsTarget.appendChild(li);
    });
  }

  renderSelected() {
    this.selectedTarget.innerHTML = "";
    this.selectedItems.forEach((item) => {
      const pill = document.createElement("span");
      pill.className = "multi-select__pill";

      const label = document.createElement("span");
      label.textContent = item.name;
      pill.appendChild(label);

      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "×";
      remove.dataset.action = "click->multi-select#remove";
      remove.dataset.id = item.id;
      pill.appendChild(remove);

      const hidden = document.createElement("input");
      hidden.type = "hidden";
      hidden.name = this.nameValue;
      hidden.value = item.id;
      pill.appendChild(hidden);

      this.selectedTarget.appendChild(pill);
    });
  }

  add(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    const item = this.availableItems.find((i) => i.id === id);
    if (!item) return;

    this.selectedItems.push(item);
    this.availableItems = this.availableItems.filter((i) => i.id !== id);
    this.filterTarget.value = "";
    this.render();
  }

  remove(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    const itemIndex = this.selectedItems.findIndex((i) => i.id === id);
    if (itemIndex === -1) return;

    const [item] = this.selectedItems.splice(itemIndex, 1);
    this.availableItems.push(item);
    this.render();
  }
}
