import type { Spec } from "./NativeRNBootSplash";

function resolveAfter(delay: number) {
  return new Promise((resolve) => setTimeout(resolve, delay));
}

function removeNode(node: Node | null) {
  const parent = node?.parentNode;

  if (node != null && parent != null) {
    parent.removeChild(node);
  }
}

// Web state management
let webCurrentState = "default";

function updateStatusText() {
  const container = document.getElementById("bootsplash");
  if (!container) return;

  // Remove existing status text
  const existingStatus = document.getElementById("bootsplash-status");
  if (existingStatus) {
    existingStatus.remove();
  }

  // Add new status text if needed
  const statusText =
    webCurrentState === "updating"
      ? "updating..."
      : webCurrentState === "updated"
        ? "updated ✅"
        : "";

  if (statusText) {
    const statusDiv = document.createElement("div");
    statusDiv.id = "bootsplash-status";
    statusDiv.textContent = statusText;
    statusDiv.style.cssText = `
      position: absolute;
      bottom: 40px;
      left: 50%;
      transform: translateX(-50%);
      font-size: 16px;
      font-weight: 500;
      opacity: 0.8;
      text-align: center;
      color: inherit;
    `;
    container.appendChild(statusDiv);
  }
}

export default {
  getConstants: () => ({
    darkModeEnabled:
      typeof window !== "undefined" &&
      "matchMedia" in window &&
      window.matchMedia("(prefers-color-scheme: dark)").matches,
    currentState: webCurrentState,
  }),

  hide: (fade) =>
    document.fonts.ready.then(() => {
      const container = document.getElementById("bootsplash");
      const style = document.getElementById("bootsplash-style");

      if (container == null || !fade) {
        removeNode(container);
        removeNode(style);
      } else {
        container.style.transitionProperty = "opacity";
        container.style.transitionDuration = "250ms";
        container.style.opacity = "0";

        return resolveAfter(250).then(() => {
          removeNode(container);
          removeNode(style);
        });
      }
    }),

  isVisible: () => {
    const container = document.getElementById("bootsplash");
    return Promise.resolve(container != null);
  },

  setState: (state: "default" | "updating" | "updated") => {
    webCurrentState = state;
    updateStatusText();
  },
} satisfies Spec;
