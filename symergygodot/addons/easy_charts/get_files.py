import os
import mimetypes

# Define output file
OUTPUT_FILE = "aggregated_texts.txt"

# List of directories or files to exclude (add paths relative to the script location)
EXCLUDE_PATTERNS = ["node_modules", "package-lock.json", "package.json", "*.git", "*.mac", "*.import", "*.svg", OUTPUT_FILE]

# Function to check if a file or directory should be excluded
def should_exclude(file_path):
    return any(pattern in file_path for pattern in EXCLUDE_PATTERNS)

# Create/clear the output file
with open(OUTPUT_FILE, "w") as output:
    output.write("")

# Insert repository tree
with open(OUTPUT_FILE, "a") as output:
    output.write("Repository file structure:\n")
    for root, dirs, files in os.walk("."):
        # Exclude directories
        dirs[:] = [d for d in dirs if not should_exclude(os.path.join(root, d))]
        # Write tree structure
        level = root.count(os.sep)
        indent = "    " * level
        output.write(f"{indent}{os.path.basename(root)}/\n")
        for file in files:
            if not should_exclude(file):
                output.write(f"{indent}    {file}\n")

# Insert file contents
with open(OUTPUT_FILE, "a") as output:
    output.write("\nText-based files and contents:\n")
    for root, _, files in os.walk("."):
        for file in files:
            file_path = os.path.join(root, file)
            if should_exclude(file_path):
                continue
            # Check if the file is a text file
            mime_type, _ = mimetypes.guess_type(file_path)
            if mime_type and mime_type.startswith("text"):
                output.write("\n\n")
                output.write(f"<== Begin {file_path} ==>\n")
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        output.write(f.read())
                except Exception as e:
                    output.write(f"Error reading file: {e}")
                output.write(f"\n<== End {file_path} ==>\n")

print("Aggregation complete.")
