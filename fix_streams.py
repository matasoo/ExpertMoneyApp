import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    in_listen = False
    listen_bracket_count = 0
    new_lines = []
    
    for line in lines:
        if '.listen((data) {' in line or '.listen((profile) {' in line:
            in_listen = True
            listen_bracket_count = 1
        elif in_listen:
            listen_bracket_count += line.count('{')
            listen_bracket_count -= line.count('}')
            
            if listen_bracket_count == 0 and '});' in line:
                # We reached the end of the listen block
                line = line.replace('});', '}, onError: (e) => print(\'Stream error: $e\'));')
                in_listen = False
        
        new_lines.append(line)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

files_to_fix = [
    'lib/core/providers/currency_provider.dart',
    'lib/core/providers/premium_provider.dart',
    'lib/features/dashboard/providers/daily_budget_provider.dart',
    'lib/features/dashboard/providers/transactions_provider.dart',
    'lib/features/goals/providers/budgets_provider.dart',
    'lib/features/goals/providers/goals_provider.dart',
    'lib/features/setup/providers/setup_provider.dart',
    'lib/features/wallet/providers/accounts_provider.dart',
    'lib/features/wallet/providers/credits_provider.dart',
    'lib/features/wallet/providers/recurring_payments_provider.dart'
]

for f in files_to_fix:
    if os.path.exists(f):
        fix_file(f)
        print(f"Fixed {f}")
    else:
        print(f"Not found: {f}")
