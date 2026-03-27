import subprocess
import time
import sys
import os

def start_backend():
    print("🚀 Starting Flask Backend...")
    # Using 'python app.py' assuming typical flask setup
    # Adjust path if needed
    backend_path = os.path.join(os.getcwd(), "Backend")
    return subprocess.Popen([sys.executable, "app.py"], cwd=backend_path)

def start_flutter():
    print("📱 Starting Flutter App...")
    return subprocess.Popen(["flutter", "run"], shell=True)

if __name__ == "__main__":
    try:
        backend_proc = start_backend()
        time.sleep(2) # Give backend a moment to start
        flutter_proc = start_flutter()
        
        print("\n✅ System running! Press Ctrl+C to stop both.")
        
        # Keep main thread alive
        while True:
            time.sleep(1)
            if backend_proc.poll() is not None:
                print("⚠️ Backend process died. Restarting...")
                backend_proc = start_backend()
            
    except KeyboardInterrupt:
        print("\n🛑 Shutting down...")
        backend_proc.terminate()
        print("Done.")
