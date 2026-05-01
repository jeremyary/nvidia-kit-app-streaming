// This project was developed with assistance from AI tools.
import type React from "react";
import { useEffect, useRef, useState } from "react";
import { AppStreamer, StreamType, LogLevel, StreamStatus } from "@nvidia/omniverse-webrtc-streaming-library";

interface TurnConfig {
  urls: string;
  username: string;
  credential: string;
}

interface StreamConfig {
  width: number;
  height: number;
  fps: number;
}

interface StreamViewerProps {
  signalingServer: string;
  turn?: TurnConfig;
  stream?: StreamConfig;
}

export function StreamViewer({ signalingServer, turn, stream }: StreamViewerProps): React.ReactElement {
  const [status, setStatus] = useState<string>("connecting");
  const firstFrameFired = useRef(false);

  useEffect(() => {
    if (!signalingServer) return;

    let terminated = false;

    // RTCPeerConnection monkey-patch is applied in index.html (synchronous
    // script before module load) so the NVIDIA library sees it at import time.

    AppStreamer.connect({
      streamSource: StreamType.DIRECT,
      logLevel: LogLevel.DEBUG,
      streamConfig: {
        signalingServer,
        signalingPort: 443,
        forceWSS: true,
        videoElementId: "isaac-stream-video",
        audioElementId: "isaac-stream-audio",
        width: stream?.width ?? 1920,
        height: stream?.height ?? 1080,
        fps: stream?.fps ?? 30,
        maxReconnects: 20,
        reconnectDelay: 3000,
        onStart: () => {
          if (terminated) return;
          setStatus("streaming");
          if (!firstFrameFired.current) {
            firstFrameFired.current = true;
          }
        },
        onStop: () => {
          if (terminated) return;
          setStatus("reconnecting");
        },
      },
    }).catch((err) => {
      if (!terminated) {
        console.error("[StreamViewer] connect failed:", err);
        setStatus("error");
      }
    });

    return () => {
      terminated = true;
      if (AppStreamer.streamStatus !== StreamStatus.none) {
        AppStreamer.terminate().catch(() => undefined);
      }
    };
  }, [signalingServer, turn, stream]);

  return (
    <div style={{ width: "100%", height: "100%", position: "relative" }}>
      <video
        id="isaac-stream-video"
        autoPlay
        muted
        playsInline
        style={{ width: "100%", height: "100%", objectFit: "contain", background: "#1e1e1e" }}
      />
      <audio id="isaac-stream-audio" autoPlay muted playsInline style={{ display: "none" }} />
      {status !== "streaming" && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexDirection: "column",
            gap: 8,
            color: "#ccc",
            fontSize: 14,
            background: "rgba(30,30,30,0.85)",
            pointerEvents: "none",
          }}
        >
          <span>{status === "error" ? "WebRTC connection failed" : "Connecting to Isaac Sim..."}</span>
          {status === "reconnecting" && <span style={{ fontSize: 12, color: "#888" }}>Attempting to reconnect...</span>}
        </div>
      )}
    </div>
  );
}
