#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = "build/web"

class CrossOriginIsolatedHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Allow SharedArrayBuffer and threads to clone natively in Chrome
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        # Prevent browser caching of stale JS and WASM files during development
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

if __name__ == "__main__":
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory '{DIRECTORY}' not found.", file=sys.stderr)
        print("Please run 'flutter build web' (or 'flutter build web --profile' for debugging) first!", file=sys.stderr)
        sys.exit(1)
        
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    try:
        with socketserver.ThreadingTCPServer(("", PORT), CrossOriginIsolatedHandler) as httpd:
            print(f"=========================================================================")
            print(f"🚀 Synapse 3D Editor (Multi-threaded Web) is running at:")
            print(f"👉 http://localhost:{PORT}")
            print(f"=========================================================================")
            print("HTTP Headers sent: Cross-Origin-Opener-Policy: same-origin")
            print("                   Cross-Origin-Embedder-Policy: require-corp")
            print("Use Ctrl+C to stop the server.")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}", file=sys.stderr)
        sys.exit(1)
