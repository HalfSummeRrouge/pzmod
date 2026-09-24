const fs = require('fs');

const foodFile = 'e:\\Steam\\steamapps\\common\\ProjectZomboid\\media\\scripts\\generated\\items\\food.txt';
const outDir = 'd:\\project\\pzmod\\docs\\superpowers\\specs\\current';

const content = fs.readFileSync(foodFile, 'utf-8');

function parseItems(text) {
    const items = [];
    const regex = /item\s+(\w+)\s*\{/g;
    let m;
    while ((m = regex.exec(text)) !== null) {
        const name = m[1];
        const start = m.index + m[0].length;
        let depth = 1;
        let j = start;
        while (j < text.length && depth > 0) {
            if (text[j] === '{') depth++;
            else if (text[j] === '}') depth--;
            j++;
        }
        const block = text.substring(start, j - 1);
        items.push({ name, block });
    }
    return items;
}

function extractField(block, field) {
    const re = new RegExp(field + '\\s*=\\s*([^,\\n]+)');
    const m = block.match(re);
    return m ? m[1].trim() : null;
}

const items = parseItems(content);
const foods = [];

for (const { name, block } of items) {
    const itemType = extractField(block, 'ItemType');
    if (itemType && itemType.toLowerCase().includes('food')) {
        foods.push({
            id: 'Base.' + name,
            weight: extractField(block, 'Weight'),
            hunger: extractField(block, 'HungerChange'),
            thirst: extractField(block, 'ThirstChange'),
            calories: extractField(block, 'Calories'),
            carbs: extractField(block, 'Carbohydrates'),
            lipids: extractField(block, 'Lipids'),
            proteins: extractField(block, 'Proteins'),
            foodType: extractField(block, 'FoodType'),
            daysFresh: extractField(block, 'DaysFresh'),
            daysRotten: extractField(block, 'DaysTotallyRotten'),
            cantEat: extractField(block, 'CantEat'),
            eatType: extractField(block, 'EatType'),
        });
    }
}

foods.sort((a, b) => {
    const fa = a.foodType || 'Unknown';
    const fb = b.foodType || 'Unknown';
    if (fa !== fb) return fa.localeCompare(fb);
    return a.id.localeCompare(b.id);
});

const groups = {};
for (const f of foods) {
    const ft = f.foodType || 'Unknown';
    if (!groups[ft]) groups[ft] = [];
    groups[ft].push(f);
}

let md = '# PZ B42 食物数据表（从游戏源码提取）\n\n';
md += `> 共 ${foods.length} 种食物，来源：media/scripts/items/food.txt\n\n`;

md += '## 字段说明\n\n';
md += '| 字段 | 含义 |\n|------|------|\n';
md += '| id | 物品 ID（Base.xxx），用于 AddItem |\n';
md += '| weight | 重量 kg |\n';
md += '| hunger | HungerChange（负=解饿） |\n';
md += '| thirst | ThirstChange（负=解渴） |\n';
md += '| calories | 热量 |\n';
md += '| carbs | 碳水化合物 |\n';
md += '| lipids | 脂肪 |\n';
md += '| proteins | 蛋白质 |\n';
md += '| foodType | 食物类别 |\n';
md += '| daysFresh | 新鲜天数 |\n';
md += '| daysRotten | 完全腐烂天数 |\n';
md += '| cantEat | true=需开罐/加工后才能吃 |\n';
md += '| eatType | 进食方式 |\n\n';

for (const ft of Object.keys(groups).sort()) {
    const items = groups[ft];
    md += `## ${ft}（${items.length} 种）\n\n`;
    md += '| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |\n';
    md += '|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|\n';
    for (const f of items) {
        md += `| ${f.id} | ${f.weight || '-'} | ${f.hunger || '-'} | ${f.thirst || '-'} | ${f.calories || '-'} | ${f.carbs || '-'} | ${f.lipids || '-'} | ${f.proteins || '-'} | ${f.daysFresh || '-'} | ${f.daysRotten || '-'} | ${f.cantEat || '-'} | ${f.eatType || '-'} |\n`;
    }
    md += '\n';
}

const outPath = outDir + '\\pz-b42-food-table.md';
fs.writeFileSync(outPath, md, 'utf-8');

console.log(`提取完成：${foods.length} 种食物，分组 ${Object.keys(groups).length} 类`);
console.log(`输出：${outPath}`);
console.log('');
console.log('=== 含水食物（thirst < 0）===');
for (const f of foods) {
    if (f.thirst) {
        const t = parseFloat(f.thirst);
        if (!isNaN(t) && t < 0) {
            console.log(`  ${f.id}: thirst=${f.thirst}, weight=${f.weight}`);
        }
    }
}
console.log('');
console.log('=== 常用测试食物 ===');
const testIds = ['Base.Apple', 'Base.Bread', 'Base.TinnedSoupOpen', 'Base.CannedMushroomSoupOpen',
    'Base.Watermelon', 'Base.Carrot', 'Base.Potato', 'Base.CannedCornOpen'];
for (const f of foods) {
    if (testIds.includes(f.id)) {
        console.log(`  ${f.id}: weight=${f.weight}, hunger=${f.hunger}, thirst=${f.thirst}, cal=${f.calories}, carbs=${f.carbs}`);
    }
}
