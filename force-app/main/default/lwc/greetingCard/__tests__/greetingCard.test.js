import { createElement } from "lwc";
import GreetingCard from "c/greetingCard";

describe("c-greeting-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("shows the default greeting when no name is set", () => {
    const element = createElement("c-greeting-card", { is: GreetingCard });
    document.body.appendChild(element);
    const div = element.shadowRoot.querySelector(".greeting");
    expect(div.textContent).toBe("Hello, World!");
  });

  it("shows a personalised greeting when a name is set", () => {
    const element = createElement("c-greeting-card", { is: GreetingCard });
    element.name = "Sourabh";
    document.body.appendChild(element);
    const div = element.shadowRoot.querySelector(".greeting");
    expect(div.textContent).toBe("Hello, Sourabh!");
  });

  it("upper-cases the greeting when uppercase is true", () => {
    const element = createElement("c-greeting-card", { is: GreetingCard });
    element.name = "Sourabh";
    element.uppercase = true;
    document.body.appendChild(element);
    const div = element.shadowRoot.querySelector(".greeting");
    expect(div.textContent).toBe("HELLO, SOURABH!");
  });
});
