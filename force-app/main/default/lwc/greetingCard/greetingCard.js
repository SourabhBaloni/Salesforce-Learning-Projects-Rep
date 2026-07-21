import { LightningElement, api } from "lwc";

export default class GreetingCard extends LightningElement {
  @api name = "";

  get message() {
    return this.name ? `Hello, ${this.name}!` : "Hello, World!";
  }
}
