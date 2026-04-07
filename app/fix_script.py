import os
import re

def process_file(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    original = content

    # Add cacheExtent: 500 to constructors. Be careful not to keep adding it
    for widget in ["CustomScrollView", "ListView.builder", "GridView.builder"]:
        pattern = r"(" + widget.replace(".", r"\.") + r")\s*\("
        if "cacheExtent" not in content and widget in content:
            content = re.sub(pattern, r"\1(cacheExtent: 500, ", content)

    # ClipRRect
    content = re.sub(r"(?<!\:\s)(?<!\:\sRepaintBoundary\(\s*child\:\s)ClipRRect\(", r"RepaintBoundary(child: ClipRRect(", content)
    # ClipPath
    content = re.sub(r"(?<!\:\s)(?<!\:\sRepaintBoundary\(\s*child\:\s)ClipPath\(", r"RepaintBoundary(child: ClipPath(", content)

    if content != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated: {path}")

for root, dirs, files in os.walk("lib"):
    for f in files:
        if f.endswith(".dart"):
            process_file(os.path.join(root, f))
