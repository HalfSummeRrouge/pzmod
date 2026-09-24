import re, os, json

food_file = r'e:\Steam\steamapps\common\ProjectZomboid\media\scripts\generated\items\food.txt'
out_dir = r'd:\project\pzmod\docs\superpowers\specs\current'

with open(food_file, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# 匹配 item 块（处理嵌套大括号）
def parse_items(text):
    items = []
    i = 0
    while True:
        m = re.search(r'item\s+(\w+)\s*\{', text[i:])
        if not m:
            break
        name = m.group(1)
        start = i + m.end()
        # 找到匹配的 closing brace
        depth = 1
        j = start
        while j < len(text) and depth > 0:
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
            j += 1
        block = text[start:j-1]
        items.append((name, block))
        i = j
    return items

items = parse_items(content)

def extract_field(block, field):
    m = re.search(field + r'\s*=\s*([^,\n]+)', block)
    return m.group(1).strip() if m else None

foods = []
for name, block in items:
    item_type = extract_field(block, 'ItemType')
    if item_type and 'food' in item_type.lower():
        food = {
            'id': 'Base.' + name,
            'weight': extract_field(block, 'Weight'),
            'hunger': extract_field(block, 'HungerChange'),
            'thirst': extract_field(block, 'ThirstChange'),
            'calories': extract_field(block, 'Calories'),
            'carbs': extract_field(block, 'Carbohydrates'),
            'lipids': extract_field(block, 'Lipids'),
            'proteins': extract_field(block, 'Proteins'),
            'foodType': extract_field(block, 'FoodType'),
            'daysFresh': extract_field(block, 'DaysFresh'),
            'daysRotten': extract_field(block, 'DaysTotallyRotten'),
            'cantEat': extract_field(block, 'CantEat'),
            'eatType': extract_field(block, 'EatType'),
        }
        foods.append(food)

foods.sort(key=lambda x: (str(x['foodType']), x['id']))

groups = {}
for f in foods:
    ft = f['foodType'] or 'Unknown'
    groups.setdefault(ft, []).append(f)

md_lines = ['# PZ B42 食物数据表（从游戏源码提取）', '', f'> 共 {len(foods)} 种食物，来源：media/scripts/items/food.txt', '']

md_lines.append('## 字段说明')
md_lines.append('| 字段 | 含义 |')
md_lines.append('|------|------|')
md_lines.append('| id | 物品 ID（Base.xxx），用于 AddItem |')
md_lines.append('| weight | 重量 kg |')
md_lines.append('| hunger | HungerChange（负=解饿） |')
md_lines.append('| thirst | ThirstChange（负=解渴） |')
md_lines.append('| calories | 热量 |')
md_lines.append('| carbs | 碳水化合物 |')
md_lines.append('| lipids | 脂肪 |')
md_lines.append('| proteins | 蛋白质 |')
md_lines.append('| foodType | 食物类别 |')
md_lines.append('| daysFresh | 新鲜天数 |')
md_lines.append('| daysRotten | 完全腐烂天数 |')
md_lines.append('| cantEat | true=需开罐/加工后才能吃 |')
md_lines.append('| eatType | 进食方式 |')
md_lines.append('')

for ft, items in sorted(groups.items()):
    md_lines.append(f'## {ft}（{len(items)} 种）')
    md_lines.append('')
    md_lines.append('| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |')
    md_lines.append('|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|')
    for f in items:
        row = '| ' + ' | '.join([
            f['id'],
            f['weight'] or '-',
            f['hunger'] or '-',
            f['thirst'] or '-',
            f['calories'] or '-',
            f['carbs'] or '-',
            f['lipids'] or '-',
            f['proteins'] or '-',
            f['daysFresh'] or '-',
            f['daysRotten'] or '-',
            f['cantEat'] or '-',
            f['eatType'] or '-',
        ]) + ' |'
        md_lines.append(row)
    md_lines.append('')

out_path = os.path.join(out_dir, 'pz-b42-food-table.md')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(md_lines))

print(f'提取完成：{len(foods)} 种食物，分组 {len(groups)} 类')
print(f'输出：{out_path}')
print()
print('=== 含水食物（thirst < 0）===')
for f in foods:
    if f['thirst']:
        try:
            if float(f['thirst']) < 0:
                print(f"  {f['id']}: thirst={f['thirst']}, weight={f['weight']}")
        except:
            pass

print()
print('=== 常用测试食物 ===')
test_ids = ['Base.Apple', 'Base.Bread', 'Base.TinnedSoupOpen', 'Base.CannedMushroomSoupOpen',
            'Base.Watermelon', 'Base.Carrot', 'Base.Potato', 'Base.CannedCornOpen']
for f in foods:
    if f['id'] in test_ids:
        print(f"  {f['id']}: weight={f['weight']}, hunger={f['hunger']}, thirst={f['thirst']}, cal={f['calories']}, carbs={f['carbs']}")
