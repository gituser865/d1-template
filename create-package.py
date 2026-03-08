import os
import shutil
import zipfile
from pathlib import Path

def create_project_package():
    """Create complete Task Marketplace package"""
    
    project_name = "task-marketplace"
    
    # Create directory structure
    base_dir = Path(project_name)
    
    # Backend directories
    (base_dir / "backend/src/config").mkdir(parents=True, exist_ok=True)
    (base_dir / "backend/src/middleware").mkdir(parents=True, exist_ok=True)
    (base_dir / "backend/src/models").mkdir(parents=True, exist_ok=True)
    (base_dir / "backend/src/routes").mkdir(parents=True, exist_ok=True)
    (base_dir / "backend/src/services").mkdir(parents=True, exist_ok=True)
    
    # Frontend directories
    (base_dir / "frontend/pages").mkdir(parents=True, exist_ok=True)
    (base_dir / "frontend/components").mkdir(parents=True, exist_ok=True)
    (base_dir / "frontend/store").mkdir(parents=True, exist_ok=True)
    (base_dir / "frontend/utils").mkdir(parents=True, exist_ok=True)
    
    # Docs and GitHub
    (base_dir / "docs").mkdir(parents=True, exist_ok=True)
    (base_dir / ".github/workflows").mkdir(parents=True, exist_ok=True)
    (base_dir / "uploads").mkdir(parents=True, exist_ok=True)
    
    print(f"✅ Project structure created: {project_name}/")
    
    # Create ZIP file
    zip_path = f"{project_name}.zip"
    shutil.make_archive(project_name, 'zip', '.', project_name)
    
    print(f"✅ ZIP file created: {zip_path}")
    print(f"📦 File size: {os.path.getsize(zip_path) / (1024*1024):.2f} MB")
    print(f"\n✨ Download ready!")

if __name__ == "__main__":
    create_project_package()