import subprocess
import sys
import os
import shutil

def get_installed_extensions(cmd_args):
    try:
        result = subprocess.run(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        extensions = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Filter out warning lines
            if 'extensionManagementService' in line or 'MESA-INTEL' in line or 'libva error' in line:
                continue
            extensions.append(line.lower())
        return set(extensions)
    except Exception as e:
        print(f"Warning: failed to get extensions using {' '.join(cmd_args)}: {e}")
        return set()

def main():
    print("Fetching extensions from VS Code, VSCodium, and Antigravity IDE...")
    code_exts = get_installed_extensions(["code", "--list-extensions"])
    codium_exts = get_installed_extensions(["codium", "--list-extensions"])
    antigravity_exts = get_installed_extensions(["/opt/Antigravity IDE/bin/antigravity-ide", "--list-extensions"])

    all_target_exts = code_exts.union(codium_exts)
    missing_exts = sorted(list(all_target_exts - antigravity_exts))

    print(f"Found {len(code_exts)} extensions in VS Code.")
    print(f"Found {len(codium_exts)} extensions in VSCodium.")
    print(f"Found {len(antigravity_exts)} extensions in Antigravity IDE.")
    print(f"Total unique extensions target: {len(all_target_exts)}")
    print(f"Extensions to install: {len(missing_exts)}")

    if not missing_exts:
        print("All extensions are already installed in Antigravity IDE.")
        sys.exit(0)

    # We will try installing them one by one. If it fails, we fall back to copying from local directories.
    vscode_ext_dir = os.path.expanduser("~/.vscode/extensions")
    codium_ext_dir = os.path.expanduser("~/.vscode-oss/extensions")
    antigravity_ext_dir = os.path.expanduser("~/.antigravity-ide/extensions")

    os.makedirs(antigravity_ext_dir, exist_ok=True)

    success_count = 0
    copied_count = 0
    failed_count = 0

    for i, ext in enumerate(missing_exts, 1):
        print(f"[{i}/{len(missing_exts)}] Processing '{ext}'...")
        
        # Try CLI installation first
        try:
            print(f"  Attempting to install '{ext}' via CLI...")
            result = subprocess.run(
                ["/opt/Antigravity IDE/bin/antigravity-ide", "--install-extension", ext],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30
            )
            if result.returncode == 0 and "successfully installed" in result.stdout.lower():
                print(f"  Successfully installed '{ext}' via CLI.")
                success_count += 1
                continue
            else:
                print(f"  CLI installation failed/warned for '{ext}'. Return code: {result.returncode}")
                if result.stdout:
                    print(f"    Stdout: {result.stdout.strip()}")
                if result.stderr:
                    print(f"    Stderr: {result.stderr.strip()}")
        except subprocess.TimeoutExpired:
            print(f"  CLI installation timed out for '{ext}'.")
        except Exception as e:
            print(f"  CLI installation encountered an error: {e}")

        # Fallback to local copy
        print(f"  Attempting fallback: copying local folder for '{ext}'...")
        copied = False
        
        # Look for matching directories in both VS Code and VSCodium extensions folder
        for search_dir in [vscode_ext_dir, codium_ext_dir]:
            if not os.path.exists(search_dir):
                continue
            
            try:
                entries = os.listdir(search_dir)
                matching_folders = []
                for entry in entries:
                    entry_lower = entry.lower()
                    is_match = (entry_lower == ext or entry_lower.startswith(ext + "-"))
                    if is_match and os.path.isdir(os.path.join(search_dir, entry)):
                        matching_folders.append(entry)
                
                # Sort matching folders (so we copy the latest version if there are multiple)
                if matching_folders:
                    matching_folders.sort()
                    target_folder = matching_folders[-1]
                    src_path = os.path.join(search_dir, target_folder)
                    dest_path = os.path.join(antigravity_ext_dir, target_folder)
                    
                    print(f"    Found local source folder: {src_path}")
                    if os.path.exists(dest_path):
                        print(f"    Destination folder already exists: {dest_path}. Skipping copy.")
                        copied = True
                        copied_count += 1
                        break
                    
                    print(f"    Copying to: {dest_path} ...")
                    shutil.copytree(src_path, dest_path)
                    print(f"    Successfully copied '{ext}' local folder.")
                    copied = True
                    copied_count += 1
                    break
            except Exception as e:
                print(f"    Error during local copy fallback for '{ext}' in '{search_dir}': {e}")
        
        if not copied:
            print(f"  Error: Failed to install '{ext}' via CLI and no local folder found.")
            failed_count += 1

    print("\n=== Sync Summary ===")
    print(f"Total extensions processed: {len(missing_exts)}")
    print(f"Installed via CLI: {success_count}")
    print(f"Copied from local backup: {copied_count}")
    print(f"Failed to install: {failed_count}")

if __name__ == "__main__":
    main()
