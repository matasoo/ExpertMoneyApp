import os
import re

# We will replace these specific dark colors with Theme.of(context).colorScheme.surface
# or primaryColor.withValues(alpha: 0.1) where appropriate.

dark_surface_colors = [
    'Color(0xFF181818)',
    'Color(0xFF252525)',
    'Color(0xFF383838)',
    'Color(0xFF2A2A2C)',
    'Color(0xFF333335)',
    'Color(0xFF2E2E2E)',
    'Color(0xFF1A1A1A)'
]

greenish_surface = 'Color(0xFF1B2E24)'
dark_green_1 = 'Color(0xFF1B3B2B)'
dark_green_2 = 'Color(0xFF0D1F15)'

for root, _, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'):
            continue
        if file in ['app_theme.dart', 'app_colors.dart']:
            continue
            
        filepath = os.path.join(root, file)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        orig = content
        
        for c in dark_surface_colors:
            content = content.replace(f'const {c}', 'Theme.of(context).colorScheme.surface')
            content = content.replace(c, 'Theme.of(context).colorScheme.surface')
            
        # For the greenish cards (like AI Tip)
        content = content.replace(f'const {greenish_surface}', 'Theme.of(context).primaryColor.withValues(alpha: 0.15)')
        content = content.replace(greenish_surface, 'Theme.of(context).primaryColor.withValues(alpha: 0.15)')
        content = content.replace(f'const {dark_green_1}', 'Theme.of(context).primaryColor.withValues(alpha: 0.15)')
        content = content.replace(dark_green_1, 'Theme.of(context).primaryColor.withValues(alpha: 0.15)')
        content = content.replace(f'const {dark_green_2}', 'Theme.of(context).primaryColor.withValues(alpha: 0.25)')
        content = content.replace(dark_green_2, 'Theme.of(context).primaryColor.withValues(alpha: 0.25)')
        
        if orig != content:
            content = content.replace('const ', '')
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")
