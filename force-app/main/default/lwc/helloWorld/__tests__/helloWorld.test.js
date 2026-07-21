import { createElement } from "lwc";
import HelloWorld from "c/helloWorld";

describe("c-hello-world", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the default greeting", () => {
    const element = createElement("c-hello-world", { is: HelloWorld });
    document.body.appendChild(element);
    const p = element.shadowRoot.querySelector("p");
    expect(p.textContent).toBe("Hello, World!");
  });

  it("renders a custom greeting", () => {
    const element = createElement("c-hello-world", { is: HelloWorld });
    element.greeting = "Salesforce";
    document.body.appendChild(element);
    const p = element.shadowRoot.querySelector("p");
    expect(p.textContent).toBe("Hello, Salesforce!");
  });
});
