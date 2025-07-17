#!/usr/bin/env python3
"""
Jekyll Development Server
A Python-based development server for Jekyll sites using FastAPI and uvicorn.
Provides auto-rebuild and live serving capabilities.
"""

import os
import sys
import subprocess
import asyncio
import argparse
import logging
import time
from pathlib import Path
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

class JekyllHandler(FileSystemEventHandler):
    """File system event handler for Jekyll site changes."""
    
    def __init__(self, build_callback):
        self.build_callback = build_callback
        self.last_build = 0
        self.debounce_seconds = 1  # Prevent rapid rebuilds
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        # Filter for relevant file types
        relevant_extensions = {'.md', '.html', '.yml', '.yaml', '.css', '.js', '.scss', '.sass'}
        file_path = Path(event.src_path)
        
        # Skip if in _site directory or other build artifacts
        if '_site' in file_path.parts or '.git' in file_path.parts:
            return
            
        if file_path.suffix.lower() in relevant_extensions or file_path.name == '_config.yml':
            current_time = time.time()
            if current_time - self.last_build > self.debounce_seconds:
                logger.info(f"File changed: {file_path.name}")
                self.build_callback()
                self.last_build = current_time

class JekyllDevServer:
    """Main Jekyll development server class."""

    def __init__(self, host: str = "127.0.0.1", port: int = 8000):
        self.host = host
        self.port = port
        self.site_dir = Path("_site")
        self.app = FastAPI(title="Jekyll Dev Server")
        self.observer = None


        
    def check_jekyll_installed(self) -> bool:
        """Check if Jekyll is installed and available."""
        # Set up environment with proper PATH for Jekyll
        env = os.environ.copy()
        env['PATH'] = '/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:' + env.get('PATH', '')

        try:
            result = subprocess.run(['jekyll', '--version'],
                                  capture_output=True, text=True, timeout=10, env=env)
            if result.returncode == 0:
                logger.info(f"Jekyll found: {result.stdout.strip()}")
                return True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

        logger.error("Jekyll not found! Please install Jekyll:")
        logger.error("  gem install jekyll bundler")
        logger.error("  or visit: https://jekyllrb.com/docs/installation/")
        return False
    
    def build_site(self) -> bool:
        """Build the Jekyll site."""
        logger.info("Building Jekyll site...")
        start_time = time.time()

        # Set up environment with proper PATH for Jekyll
        env = os.environ.copy()
        env['PATH'] = '/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:' + env.get('PATH', '')

        try:
            # Use jekyll build command
            result = subprocess.run(
                ['jekyll', 'build', '--incremental'],
                capture_output=True,
                text=True,
                timeout=60,
                env=env
            )

            build_time = time.time() - start_time

            if result.returncode == 0:
                logger.info(f"✅ Site built successfully in {build_time:.2f}s")
                return True
            else:
                logger.error(f"❌ Jekyll build failed:")
                logger.error(result.stderr)
                return False

        except subprocess.TimeoutExpired:
            logger.error("❌ Jekyll build timed out")
            return False
        except Exception as e:
            logger.error(f"❌ Build error: {e}")
            return False
    
    def setup_routes(self):
        """Setup FastAPI routes for serving static files."""

        @self.app.get("/")
        async def serve_index():
            """Serve the index page."""
            index_file = self.site_dir / "index.html"
            if index_file.exists():
                return FileResponse(index_file)
            else:
                return HTMLResponse(
                    "<h1>Site not built yet</h1><p>Building site, please wait...</p>",
                    status_code=503
                )

        @self.app.get("/health")
        async def health_check():
            """Health check endpoint."""
            return {"status": "ok", "site_built": self.site_dir.exists()}

        @self.app.get("/{path:path}")
        async def serve_file(path: str):
            """Serve files with GitHub Pages-like behavior."""
            # Handle root path
            if not path:
                return await serve_index()

            # Try to serve the exact file first
            file_path = self.site_dir / path
            if file_path.is_file():
                return FileResponse(file_path)

            # If requesting a .md file, try to serve the corresponding .html file
            if path.endswith('.md'):
                html_path = self.site_dir / (path[:-3] + '.html')
                if html_path.is_file():
                    return FileResponse(html_path)

            # If requesting a path without extension, try .html
            if '.' not in Path(path).name:
                html_path = self.site_dir / (path + '.html')
                if html_path.is_file():
                    return FileResponse(html_path)

            # If it's a directory, try index.html
            if file_path.is_dir():
                index_path = file_path / "index.html"
                if index_path.is_file():
                    return FileResponse(index_path)

            # File not found
            raise HTTPException(status_code=404, detail="File not found")
    
    def start_file_watcher(self):
        """Start the file system watcher."""
        event_handler = JekyllHandler(self.build_site)
        self.observer = Observer()
        
        # Watch current directory and subdirectories
        watch_paths = ['.']
        for path in watch_paths:
            if os.path.exists(path):
                self.observer.schedule(event_handler, path, recursive=True)
                logger.info(f"Watching {path} for changes...")
        
        self.observer.start()
    
    def stop_file_watcher(self):
        """Stop the file system watcher."""
        if self.observer:
            self.observer.stop()
            self.observer.join()
    
    async def run(self):
        """Run the development server."""
        # Check Jekyll installation
        if not self.check_jekyll_installed():
            return False
        
        # Initial build
        if not self.build_site():
            logger.error("Initial build failed. Please fix errors and try again.")
            return False
        
        # Setup routes
        self.setup_routes()
        
        # Start file watcher
        self.start_file_watcher()
        
        logger.info(f"🚀 Starting development server at http://{self.host}:{self.port}")
        logger.info("Press Ctrl+C to stop the server")
        
        try:
            config = uvicorn.Config(
                app=self.app,
                host=self.host,
                port=self.port,
                log_level="info",
                reload=True,  # Enable uvicorn auto-reload for Python code changes
                reload_dirs=["."],  # Watch current directory
                reload_excludes=["_site/*", ".git/*", "*.log"]  # Exclude build artifacts
            )
            server = uvicorn.Server(config)
            await server.serve()
        except KeyboardInterrupt:
            logger.info("Shutting down...")
        finally:
            self.stop_file_watcher()
        
        return True

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Jekyll Development Server")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    
    args = parser.parse_args()
    
    # Check if we're in a Jekyll site directory
    if not os.path.exists('_config.yml'):
        logger.error("No _config.yml found. Are you in a Jekyll site directory?")
        sys.exit(1)
    
    server = JekyllDevServer(host=args.host, port=args.port)
    
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
