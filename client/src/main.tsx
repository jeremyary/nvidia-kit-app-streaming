// This project was developed with assistance from AI tools.
import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { StreamViewer } from "./StreamViewer";

interface AppConfig {
  signalingServer: string;
  turn?: {
    urls: string;
    username: string;
    credential: string;
  };
  stream?: {
    width: number;
    height: number;
    fps: number;
  };
}

function App() {
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/config.json")
      .then((r) => {
        if (!r.ok) throw new Error(`config.json: ${r.status}`);
        return r.json();
      })
      .then(setConfig)
      .catch((err) => setError(err.message));
  }, []);

  if (error) {
    return (
      <div style={{ color: "#e55", padding: 32, fontFamily: "monospace" }}>
        Failed to load config: {error}
      </div>
    );
  }

  if (!config) {
    return (
      <div style={{ color: "#888", padding: 32, fontFamily: "monospace" }}>
        Loading configuration...
      </div>
    );
  }

  return <StreamViewer signalingServer={config.signalingServer} turn={config.turn} stream={config.stream} />;
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
