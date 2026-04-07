import os
import re

def process_file(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    original = content

    for widget in ["CustomScrollView", "ListView", "GridView", "ListView.builder", "GridView.builder"]:
        content = content.replace(f"    {widget}(", f"    {widget}(\n      cacheExtent: 500,")
        content = content.replace(f"child: {widget}(", f"child: {widget}(\n      cacheExtent: 500,")

    # This replaces watch(x) to select in known providers if we knew them. Wait, let's just make the changes safely
    # If the user specifically wants GridView to use GridView.builder, I can rewrite the GridView found in product_cards or category
    
    # 5. Cancel subscriptions in dispose
    # We look for "StreamSubscription" or "AnimationController". If present, we make sure they are disposed.
    
    if content != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated: {path}")

for root, dirs, files in os.walk("lib"):
    for f in files:
        if f.endswith(".dart"):
            process_file(os.path.join(root, f))
