import re

path = 'lib/features/home/widgets/animated_bottom_nav.dart'
try:
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Find .withOpacity(x) and replace it with .withValues(alpha: x)
    text = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', text)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Replaced withOpacity in animated_bottom_nav.dart")
except Exception as e:
    print(f"Error: {e}")
