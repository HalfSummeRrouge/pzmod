# PZ B42 食物数据表（从游戏源码提取）

> 共 722 种食物，来源：media/scripts/items/food.txt

## 字段说明

| 字段 | 含义 |
|------|------|
| id | 物品 ID（Base.xxx），用于 AddItem |
| weight | 重量 kg |
| hunger | HungerChange（负=解饿） |
| thirst | ThirstChange（负=解渴） |
| calories | 热量 |
| carbs | 碳水化合物 |
| lipids | 脂肪 |
| proteins | 蛋白质 |
| foodType | 食物类别 |
| daysFresh | 新鲜天数 |
| daysRotten | 完全腐烂天数 |
| cantEat | true=需开罐/加工后才能吃 |
| eatType | 进食方式 |

## Bacon（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Bacon | 0.3 | -12.0 | - | 160.0 | 0.0 | 14.0 | 10.0 | 3 | 5 | - | - |
| Base.BaconBits | 0.025 | -1.0 | - | 10.0 | 0.0 | 0.875 | 0.6125 | 3 | 5 | - | - |
| Base.BaconRashers | 0.1 | -4.0 | - | 40.0 | 0.0 | 3.5 | 2.5 | 3 | 5 | - | - |

## Bean（10 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.BeanBowl | 1.5 | -24.0 | - | 170.0 | 33.0 | 1.0 | 7.0 | 2 | 4 | - | 2handbowl |
| Base.Blackbeans | 0.1 | -10.0 | - | 45.0 | 10.45 | 0.45 | 3.95 | 3 | 5 | - | EatSmall |
| Base.DriedBlackBeans | 2.0 | -60.0 | - | 3084.0 | 580.0 | 0.0 | 199.0 | - | - | true | - |
| Base.DriedChickpeas | 2.0 | -60.0 | - | 2851.0 | 544.0 | 0.0 | 181.0 | - | - | true | - |
| Base.DriedKidneyBeans | 2.0 | -60.0 | - | 3265.0 | 508.0 | 13.0 | 272.0 | - | - | true | - |
| Base.DriedWhiteBeans | 2.0 | -60.0 | - | 2823.0 | 527.0 | 10.0 | 188.0 | - | - | true | - |
| Base.OpenBeans | 0.8 | -24.0 | - | 170.0 | 33.0 | 1.0 | 7.0 | 2 | 4 | - | Candrink |
| Base.RefriedBeans | 0.2 | -10.0 | - | 70.0 | 25.0 | 1.5 | 10.0 | 4 | 8 | - | - |
| Base.Soybeans | 0.1 | -5.0 | - | 25.0 | 10.45 | 0.45 | 3.95 | 3 | 5 | - | - |
| Base.SoybeansSeed | 0.02 | -1.0 | - | 5.0 | 2.0 | 0.1 | 0.8 | - | - | true | - |

## Beef（6 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Beef | 0.5 | -80.0 | - | 440.0 | 0.0 | 18.7 | 62.62 | 2 | 4 | - | - |
| Base.BeefJerky | 0.2 | -20.0 | - | 410.0 | 11.0 | 26.0 | 33.0 | - | - | - | - |
| Base.CannedCornedBeefOpen | 0.8 | -24.0 | - | 720.0 | 0.0 | 48.0 | 78.0 | 2 | 4 | - | Candrink |
| Base.MeatPatty | 0.3 | -40.0 | - | 612.0 | 0.0 | 30.0 | 46.0 | 2 | 4 | - | - |
| Base.MincedMeat | 0.3 | -40.0 | - | 300.0 | 0.0 | 30.0 | 46.0 | 2 | 4 | - | 2handforced |
| Base.Steak | 0.3 | -40.0 | - | 220.0 | 0.0 | 9.35 | 31.62 | 2 | 4 | - | - |

## Berry（13 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.BeautyBerry | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryBlack | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryBlue | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryGeneric1 | 0.1 | -5.0 | -1.0 | 12.0 | 3.0 | 0.0 | 2.0 | 6 | 10 | - | - |
| Base.BerryGeneric2 | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryGeneric3 | 0.1 | -5.0 | -1.0 | 8.0 | 3.0 | 0.0 | 2.0 | 6 | 10 | - | - |
| Base.BerryGeneric4 | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryGeneric5 | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.BerryPoisonIvy | 0.1 | -5.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.HollyBerry | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |
| Base.Rosehips | 0.1 | -6.0 | - | 81.0 | 19.0 | 0.0 | 2.0 | 6 | 10 | - | - |
| Base.Strewberrie | 0.1 | -5.0 | -1.0 | 4.0 | 0.92 | 0.04 | 0.08 | 2 | 5 | - | - |
| Base.WinterBerry | 0.1 | -10.0 | -1.0 | 23.0 | 5.0 | 0.0 | 4.0 | 6 | 10 | - | - |

## Bread（5 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Baguette | 0.3 | -23.0 | - | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | - | EatOffStick |
| Base.Bread | 0.3 | -30.0 | - | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | - | - |
| Base.BreadSlices | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 3 | 6 | - | - |
| Base.BunsHamburger_single | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 3 | 6 | - | - |
| Base.BunsHotdog_single | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 3 | 6 | - | - |

## Candy（25 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Allsorts | 0.2 | -10.0 | - | 16.6 | 4.33 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.CandiedApple | 0.2 | -18.0 | -4.0 | 250.0 | 36.0 | 9.0 | 6.0 | 5 | 8 | - | EatOffStick |
| Base.Candycane | 0.2 | -10.0 | - | 16.6 | 4.33 | 0.0 | 0.0 | - | - | - | EatOffStick |
| Base.CandyCaramels | 0.1 | -5.0 | - | 170.0 | 28.0 | 5.0 | 1.0 | - | - | - | EatSmall |
| Base.CandyCorn | 0.2 | -10.0 | - | 32.0 | 14.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.CandyFruitSlices | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.CandyGummyfish | 0.1 | -5.0 | - | 110.0 | 27.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.CandyMolasses | 0.1 | -5.0 | - | 160.0 | 33.0 | 3.5 | 0.1 | - | - | - | EatSmall |
| Base.CandyNovapops | 0.1 | -5.0 | - | 120.0 | 24.0 | 2.5 | 0.0 | - | - | - | EatSmall |
| Base.Chocolate_Butterchunkers | 0.2 | -20.0 | - | 230.0 | 29.0 | 12.0 | 2.0 | - | - | - | - |
| Base.Chocolate_Candy | 0.1 | -5.0 | - | 110.0 | 27.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.Chocolate_Crackle | 0.2 | -20.0 | - | 230.0 | 29.0 | 12.0 | 2.0 | - | - | - | - |
| Base.Chocolate_Deux | 0.2 | -20.0 | - | 250.0 | 34.0 | 12.0 | 2.0 | - | - | - | - |
| Base.Chocolate_GalacticDairy | 0.2 | -20.0 | - | 190.0 | 30.0 | 8.0 | 2.0 | - | - | - | - |
| Base.Chocolate_RoysPBPucks | 0.2 | -20.0 | - | 230.0 | 26.0 | 13.0 | 5.0 | - | - | - | - |
| Base.Chocolate_Smirkers | 0.2 | -20.0 | - | 280.0 | 35.0 | 14.0 | 4.0 | - | - | - | - |
| Base.Chocolate_SnikSnak | 0.2 | -20.0 | - | 230.0 | 29.0 | 12.0 | 3.0 | - | - | - | - |
| Base.GummyBears | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.GummyWorms | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | - |
| Base.HardCandies | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.JellyBeans | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.Jujubes | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.LicoriceBlack | 0.1 | -2.0 | - | 22.0 | 7.0 | 0.0 | 0.0 | - | - | - | - |
| Base.LicoriceRed | 0.1 | -2.0 | - | 22.0 | 7.0 | 0.0 | 0.0 | - | - | - | - |
| Base.RockCandy | 0.1 | -5.0 | - | 40.0 | 60.0 | 0.0 | 0.0 | - | - | - | EatOffStick |

## CatFood（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CatFoodBag | 2.0 | -60.0 | - | - | - | - | - | 365 | 547 | true | - |

## Cheese（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Cheese | 0.2 | -15.0 | - | 113.0 | 0.87 | 9.33 | 6.4 | 14 | 20 | - | - |
| Base.cheese_powdered | 0.1 | -14.0 | 14.0 | 130.0 | 20.7 | 9.7 | 21.0 | - | - | - | GlugFood |
| Base.Processedcheese | 0.1 | -5.0 | - | 70.0 | 0.0 | 6.0 | 4.0 | 6 | 10 | - | - |

## Chocolate（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.ChocolateChips | 0.1 | -6.0 | - | 50.0 | 17.0 | 8.0 | 1.0 | - | - | - | EatSmall |

## Citrus（2 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Lemon | 0.2 | -10.0 | -5.0 | 17.0 | 5.41 | 0.17 | 0.64 | 7 | 9 | - | - |
| Base.Lime | 0.2 | -10.0 | -5.0 | 17.0 | 5.41 | 0.17 | 0.64 | 7 | 9 | - | - |

## Cocoa（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CocoaPowder | 1.0 | -30.0 | 50.0 | 60.0 | 8.0 | 5.0 | 2.0 | - | - | - | Candrink |

## Coffee（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Coffee2 | 1.0 | -30.0 | 60.0 | 2.0 | 0.0 | 0.0 | 1.0 | - | - | - | Candrink |

## DogFood（2 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.DogFoodBag | 2.0 | -60.0 | - | - | - | - | - | 365 | 547 | true | - |
| Base.DogfoodOpen | 0.8 | -30.0 | - | 498.0 | 77.56 | 12.58 | 16.04 | 5 | 7 | - | Candrink |

## Egg（9 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Egg | 0.1 | -7.0 | - | 63.0 | 0.32 | 4.18 | 5.55 | 14 | 21 | - | - |
| Base.EggBoiled | 0.1 | -10.0 | - | 63.0 | 0.32 | 4.18 | 5.55 | 3 | 6 | - | - |
| Base.EggOmelette | 0.1 | -20.0 | - | 120.0 | 0.52 | 6.18 | 10.55 | 3 | 6 | - | - |
| Base.EggPoached | 0.1 | -10.0 | - | 63.0 | 0.32 | 4.18 | 5.55 | 3 | 6 | - | - |
| Base.EggScrambled | 0.1 | -20.0 | - | 120.0 | 0.52 | 6.18 | 10.55 | 3 | 6 | - | - |
| Base.OmeletteRecipe | 0.5 | -14.0 | - | 123.0 | 2.0 | 8.33 | 11.0 | 3 | 6 | - | - |
| Base.OmeletteRecipeForged | 0.5 | -14.0 | - | 123.0 | 2.0 | 8.33 | 11.0 | 3 | 6 | - | - |
| Base.TurkeyEgg | 0.1 | -10.0 | - | 71.0 | 0.37 | 4.54 | 5.78 | 14 | 21 | - | - |
| Base.WildEggs | 0.1 | -7.0 | - | 63.0 | 0.32 | 4.18 | 5.55 | 14 | 21 | - | - |

## Fish（6 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedSardinesOpen | 0.3 | -14.0 | - | 150.0 | 0.0 | 11.0 | 14.0 | 2 | 4 | - | Candrink |
| Base.FishFillet | 0.2 | -25.0 | - | 205.0 | 1.0 | 12.0 | 28.52 | 2 | 4 | - | - |
| Base.FishFingers | 0.2 | -10.0 | - | 230.0 | 10.2 | 8.1 | 26.441 | 3 | 5 | - | - |
| Base.FishFried | 0.2 | -30.0 | - | 210.0 | 7.0 | 12.0 | 16.0 | 4 | 7 | - | - |
| Base.Salmon | 0.3 | -30.0 | - | 270.0 | 0.0 | 10.55 | 34.28 | 2 | 4 | - | - |
| Base.TunaTinOpen | 0.3 | -18.0 | - | 370.0 | 0.0 | 34.0 | 15.0 | 2 | 4 | - | Candrink |

## Fruits（17 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Apple | 0.2 | -16.0 | -7.0 | 95.0 | 25.13 | 0.31 | 0.47 | 5 | 8 | - | - |
| Base.Banana | 0.2 | -16.0 | -5.0 | 105.0 | 26.95 | 0.39 | 1.29 | 5 | 7 | - | - |
| Base.CannedFruitCocktailOpen | 0.8 | -15.0 | - | 250.0 | 0.0 | 24.0 | 10.0 | 5 | 7 | - | Candrink |
| Base.CannedPeachesOpen | 0.8 | -15.0 | - | 250.0 | 0.0 | 24.0 | 10.0 | 5 | 7 | - | Candrink |
| Base.CannedPineappleOpen | 0.8 | -15.0 | - | 250.0 | 0.0 | 24.0 | 10.0 | 5 | 7 | - | Candrink |
| Base.Cherry | 0.1 | -3.0 | -1.0 | 5.0 | 1.31 | 0.0 | 0.09 | 4 | 9 | - | - |
| Base.DriedApricots | 0.2 | -16.0 | - | 241.0 | 62.6 | 0.5 | 3.4 | - | - | - | - |
| Base.Grapefruit | 0.3 | -20.0 | -50.0 | 15.0 | 101.11 | 3.78 | 17.56 | 6 | 8 | - | - |
| Base.Grapes | 0.2 | -15.0 | -5.0 | 62.0 | 15.78 | 0.32 | 0.58 | 5 | 8 | - | - |
| Base.Mango | 0.3 | -20.0 | -13.0 | 252.0 | 78.7 | 1.09 | 3.89 | 6 | 14 | - | - |
| Base.Orange | 0.2 | -12.0 | -8.0 | 65.0 | 16.27 | 0.3 | 1.0 | 6 | 9 | - | - |
| Base.Peach | 0.2 | -12.0 | -5.0 | 58.0 | 14.31 | 0.38 | 1.36 | 5 | 8 | - | - |
| Base.Pear | 0.2 | -16.0 | -7.0 | 75.0 | 20.13 | 0.21 | 0.27 | 5 | 8 | - | - |
| Base.Pineapple | 0.3 | -24.0 | -13.0 | 452.0 | 118.7 | 1.09 | 4.89 | 6 | 14 | - | - |
| Base.Watermelon | 3.0 | -60.0 | -140.0 | 1355.0 | 341.11 | 6.78 | 27.56 | 6 | 8 | true | - |
| Base.WatermelonSliced | 0.3 | -6.0 | -20.0 | 135.5 | 34.11 | 0.67 | 2.75 | 3 | 4 | - | - |
| Base.WatermelonSmashed | 0.6 | -12.0 | -25.0 | 271.0 | 68.2 | 1.35 | 5.51 | 2 | 3 | - | - |

## Game（4 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.FrogMeat | 0.2 | -10.0 | - | 66.0 | 0.0 | 0.28 | 14.6 | 4 | 8 | - | - |
| Base.Rabbitmeat | 0.3 | -30.0 | - | 969.0 | 20.0 | 20.0 | 185.0 | 2 | 4 | - | - |
| Base.Smallanimalmeat | 0.3 | -15.0 | - | 201.0 | 5.0 | 7.25 | 45.0 | 2 | 4 | - | - |
| Base.Smallbirdmeat | 0.3 | -15.0 | - | 261.0 | 5.0 | 8.25 | 90.0 | 2 | 4 | - | - |

## Greens（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Dandelions | 0.1 | -5.0 | - | 25.0 | 5.0 | 0.5 | 1.5 | 6 | 10 | - | - |
| Base.Kale | 0.2 | -16.0 | -10.0 | 178.0 | 41.41 | 0.71 | 9.14 | 3 | 5 | - | - |
| Base.Lettuce | 0.2 | -15.0 | -7.0 | 54.0 | 10.33 | 0.54 | 4.9 | 3 | 5 | - | - |

## Herb（48 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Basil | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.BasilDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.BlackSage | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.BlackSageDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.Chamomile | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.ChamomileDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Chives | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.ChivesDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Cilantro | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.CilantroDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.CilantroSeed | 0.02 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Cinnamon | 0.1 | -5.0 | - | 1.0 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.CommonMallow | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.CommonMallowDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.FourLeafClover | 0.1 | -1.0 | - | 1.0 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | - |
| Base.Garlic | 0.2 | -5.0 | - | 14.0 | 3.27 | 0.035 | 0.385 | 14 | 28 | - | - |
| Base.GreenOnions | 0.2 | -3.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 7 | 14 | - | EatSmall |
| Base.Lavender | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.LavenderPetalsDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.LemonGrass | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | - |
| Base.Marigold | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.MarigoldDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.MintHerb | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.MintHerbDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.Nettles | 0.1 | -4.0 | - | 50.0 | 15.0 | 0.0 | 2.0 | 6 | 10 | - | - |
| Base.Oregano | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.OreganoDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Parsley | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.ParsleyDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Rosemary | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 14 | 28 | - | EatSmall |
| Base.RosemaryDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.RosePetalsDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.Roses | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.Sage | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.SageDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Basil | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Chives | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Cilantro | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Oregano | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Parsley | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Rosemary | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Sage | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Seasoning_Thyme | 0.2 | -20.0 | - | 0.4 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Thistle | 0.1 | -4.0 | - | 45.0 | 18.0 | 0.0 | 3.0 | 6 | 10 | - | - |
| Base.Thyme | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.ThymeDried | 0.1 | -5.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.WildGarlic2 | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | - | EatSmall |
| Base.WildGarlicDried | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | - | - | - | EatSmall |

## HotPepper（4 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.PepperHabanero | 0.1 | -2.0 | - | 15.0 | 0.0 | 0.21 | 0.0 | 5 | 8 | - | - |
| Base.PepperHabaneroDried | 0.1 | -1.0 | - | 15.0 | 0.0 | 0.21 | 0.0 | - | - | - | - |
| Base.PepperJalapeno | 0.1 | -2.0 | - | 15.0 | 0.0 | 0.21 | 0.0 | 5 | 8 | - | - |
| Base.PepperJalapenoDried | 0.1 | -1.0 | - | 15.0 | 0.0 | 0.21 | 0.0 | - | - | - | - |

## Insect（20 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.AmericanLadyCaterpillar | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.BandedWoolyBearCaterpillar | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.Centipede | 0.1 | -1.0 | - | 60.0 | 3.5 | 6.5 | 15.21 | 14 | 21 | - | - |
| Base.Centipede2 | 0.1 | -1.0 | - | 60.0 | 3.5 | 6.5 | 15.21 | 14 | 21 | - | - |
| Base.Cockroach | 0.1 | -1.0 | - | 30.0 | 1.27 | 3.9 | 7.41 | 14 | 21 | - | - |
| Base.Cricket | 0.1 | -1.0 | - | 20.0 | 1.34 | 1.32 | 3.6 | 14 | 21 | - | - |
| Base.Grasshopper | 0.1 | -1.0 | - | 25.0 | 3.0 | 0.24 | 5.55 | 14 | 21 | - | - |
| Base.Maggots | 0.01 | -1.0 | - | 1.5 | 0.0 | 0.05 | 0.25 | 14 | 21 | - | EatSmall |
| Base.Millipede | 0.1 | -1.0 | - | 60.0 | 3.5 | 6.5 | 15.21 | 14 | 21 | - | - |
| Base.Millipede2 | 0.1 | -1.0 | - | 60.0 | 3.5 | 6.5 | 15.21 | 14 | 21 | - | - |
| Base.MonarchCaterpillar | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.Pillbug | 0.01 | -1.0 | - | 1.5 | 0.0 | 0.05 | 0.25 | 14 | 21 | - | - |
| Base.SawflyLarva | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.SilkMothCaterpillar | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.Slug | 0.1 | -1.0 | - | 90.0 | 2.11 | 1.9 | 17.41 | 4 | 8 | - | - |
| Base.Slug2 | 0.1 | -1.0 | - | 90.0 | 2.11 | 1.9 | 17.41 | 4 | 8 | - | - |
| Base.Snail | 0.1 | -1.0 | - | 90.0 | 2.11 | 1.9 | 17.41 | 4 | 8 | - | - |
| Base.SwallowtailCaterpillar | 0.1 | -1.0 | - | 27.0 | 3.0 | 20.24 | 27.55 | 14 | 21 | - | - |
| Base.Termites | 0.01 | -1.0 | - | 2.5 | 0.0 | 0.5 | 0.5 | 14 | 21 | - | - |
| Base.Worm | 0.01 | -1.0 | - | 3.0 | 0.0 | 0.1 | 0.5 | 4 | 8 | - | - |

## Juice（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedFruitBeverageOpen | 0.8 | -15.0 | -85.0 | 250.0 | 0.0 | 24.0 | 10.0 | 5 | 7 | - | Candrink |

## Meat（10 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedBologneseOpen | 0.8 | -24.0 | - | 540.0 | 68.0 | 22.0 | 18.0 | 3 | 5 | - | Candrink |
| Base.CannedChiliOpen | 0.8 | -16.0 | - | 260.0 | 33.0 | 7.0 | 16.0 | 3 | 5 | - | Candrink |
| Base.Ham | 1.0 | -60.0 | - | 1560.0 | 91.0 | 78.0 | 117.0 | 5 | 10 | - | 2handforced |
| Base.HamSlice | 0.2 | -10.0 | - | 260.0 | 15.16 | 13.0 | 19.5 | 3 | 6 | - | - |
| Base.Hotdog | 0.3 | -20.0 | - | 100.0 | 2.0 | 12.0 | 2.0 | 3 | 6 | - | - |
| Base.Hotdog_single | 0.15 | -10.0 | - | 65.0 | 1.25 | 2.0 | 1.25 | 3 | 6 | - | - |
| Base.MeatDumpling | 0.1 | -10.0 | - | 28.0 | 8.0 | 3.0 | 15.0 | 2 | 4 | - | - |
| Base.MuttonChop | 0.3 | -30.0 | - | 234.0 | 0.08 | 11.0 | 33.0 | 2 | 4 | - | - |
| Base.Pork | 0.5 | -60.0 | - | 300.0 | 0.0 | 12.0 | 50.0 | 2 | 4 | - | - |
| Base.PorkChop | 0.3 | -30.0 | - | 150.0 | 0.0 | 6.0 | 25.0 | 2 | 4 | - | - |

## Milk（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedMilkOpen | 0.8 | -10.0 | -10.0 | 472.0 | 23.6 | 23.6 | 23.6 | 4 | 7 | - | GlugFood |

## Mushroom（9 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedMushroomSoupOpen | 0.8 | -10.0 | -4.0 | 160.0 | 19.0 | 8.0 | 3.0 | 2 | 4 | - | Candrink |
| Base.MushroomGeneric1 | 0.2 | -13.0 | -1.0 | 30.0 | 2.12 | 0.24 | 2.04 | 3 | 4 | - | - |
| Base.MushroomGeneric2 | 0.2 | -13.0 | -1.0 | 30.0 | 2.12 | 0.24 | 2.04 | 3 | 4 | - | - |
| Base.MushroomGeneric3 | 0.2 | -15.0 | -1.0 | 32.0 | 2.56 | 0.32 | 2.36 | 3 | 4 | - | - |
| Base.MushroomGeneric4 | 0.2 | -13.0 | -1.0 | 30.0 | 2.12 | 0.24 | 2.04 | 3 | 4 | - | - |
| Base.MushroomGeneric5 | 0.2 | -15.0 | -1.0 | 32.0 | 2.56 | 0.32 | 2.36 | 3 | 4 | - | - |
| Base.MushroomGeneric6 | 0.2 | -13.0 | -1.0 | 30.0 | 2.12 | 0.24 | 2.04 | 3 | 4 | - | - |
| Base.MushroomGeneric7 | 0.2 | -13.0 | -1.0 | 32.0 | 2.12 | 0.24 | 2.04 | 3 | 4 | - | - |
| Base.MushroomsButton | 0.2 | -7.0 | - | 15.0 | 1.06 | 0.12 | 1.02 | 3 | 4 | - | - |

## NoExplicit（49 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.BalsamicVinegar | 0.2 | -20.0 | - | 1250.0 | 300.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.BBQSauce | 0.2 | -20.0 | - | 980.0 | 252.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Biscuit | 0.1 | -5.0 | - | 160.0 | 22.0 | 8.0 | 1.0 | 3 | 5 | - | - |
| Base.CatTreats | 0.1 | -5.0 | - | 70.0 | 12.0 | 6.0 | 1.0 | 365 | 547 | - | EatSmall |
| Base.ChickenFried | 0.1 | -15.0 | - | 260.0 | 17.0 | 14.0 | 16.0 | 2 | 4 | - | - |
| Base.Chocolate | 0.2 | -20.0 | - | 850.0 | 110.0 | 66.0 | 10.0 | - | - | - | - |
| Base.Chocolate_HeartBox | 0.5 | -40.0 | - | 1700.0 | 220.0 | 130.0 | 20.0 | - | - | - | EatBox |
| Base.ChocolateCoveredCoffeeBeans | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatSmall |
| Base.Cornbread | 0.1 | -10.0 | - | 300.0 | 54.0 | 10.0 | 7.0 | 3 | 5 | - | - |
| Base.Crackers | 0.1 | -5.0 | - | 70.0 | 12.0 | 6.0 | 1.0 | - | - | - | - |
| Base.Dip_NachoCheese | 0.2 | -16.0 | - | 630.0 | 56.0 | 42.0 | 14.0 | 60 | 75 | - | Candrink |
| Base.Dip_Ranch | 0.2 | -16.0 | - | 867.0 | 29.0 | 72.0 | 14.5 | 60 | 75 | - | Candrink |
| Base.Dip_Salsa | 0.2 | -16.0 | - | 140.0 | 28.0 | 0.0 | 0.0 | 60 | 75 | - | Candrink |
| Base.GingerPickled | 0.1 | -5.0 | - | 23.0 | 0.22 | 1.18 | 2.55 | 14 | 21 | - | - |
| Base.Ginseng | 0.1 | -1.0 | - | 0.1 | 0.0 | 0.0 | 0.0 | 14 | 28 | - | - |
| Base.Gravy | 0.2 | -8.0 | - | 79.0 | 5.0 | 6.0 | 2.0 | 4 | 7 | - | Teacup |
| Base.Guacamole | 0.1 | -8.0 | - | 182.0 | 2.0 | 16.6 | 4.6 | 4 | 8 | - | 2handforced |
| Base.Hotsauce | 0.2 | -16.0 | - | 430.0 | 270.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Icing | 0.1 | -10.0 | - | 110.0 | 80.0 | 44.0 | 16.0 | 4 | 8 | - | - |
| Base.JamFruit | 0.2 | -30.0 | - | 550.0 | 130.0 | 0.0 | 1.0 | - | - | - | Candrink |
| Base.JamMarmalade | 0.2 | -30.0 | - | 550.0 | 130.0 | 0.0 | 1.0 | - | - | - | Candrink |
| Base.Ketchup | 0.2 | -20.0 | - | 1480.0 | 370.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Lard | 0.3 | -24.0 | - | 4095.0 | 0.0 | 454.0 | 0.0 | - | - | - | - |
| Base.MapleSyrup | 0.2 | -45.0 | - | 1100.0 | 270.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Margarine | 0.3 | -24.0 | - | 3255.0 | 4.0 | 368.0 | 1.0 | - | - | - | - |
| Base.Marinara | 0.2 | -10.0 | - | 350.0 | 55.0 | 7.5 | 10.0 | - | - | - | Candrink |
| Base.Marshmallows | 0.1 | -5.0 | - | 30.0 | 8.0 | 0.0 | 0.5 | - | - | - | - |
| Base.MayonnaiseFull | 0.5 | -30.0 | - | 3000.0 | 0.0 | 330.0 | 0.0 | 10 | 13 | - | Candrink |
| Base.Mustard | 0.2 | -20.0 | - | 510.0 | 0.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.PeanutButter | 0.3 | -25.0 | - | 2660.0 | 128.0 | 224.0 | 84.0 | - | - | - | Candrink |
| Base.Pepper | 0.2 | -10.0 | 20.0 | - | - | - | - | - | - | - | GlugFood |
| Base.Pickles | 0.1 | -6.0 | - | 5.0 | 1.0 | 0.0 | 0.0 | - | - | - | - |
| Base.PowderedGarlic | 0.2 | -10.0 | 20.0 | - | - | - | - | - | - | - | GlugFood |
| Base.PowderedOnion | 0.2 | -10.0 | 20.0 | - | - | - | - | - | - | - | GlugFood |
| Base.Pumpkin | 1.0 | -40.0 | - | 404.0 | 20.45 | 20.61 | 34.53 | 14 | 28 | - | 2handforced |
| Base.PumpkinSliced | 0.1 | -4.0 | - | 40.0 | 2.04 | 2.06 | 3.45 | 14 | 28 | - | - |
| Base.PumpkinSmashed | 0.2 | -8.0 | - | 80.0 | 4.09 | 4.12 | 6.9 | 14 | 28 | - | EatSmall |
| Base.RemouladeFull | 0.5 | -10.0 | - | 150.0 | 0.0 | 50.0 | 0.0 | 8 | 11 | - | Candrink |
| Base.RiceVinegar | 0.2 | -20.0 | - | 20.0 | 0.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Salt | 0.2 | -10.0 | 20.0 | - | - | - | - | - | - | - | GlugFood |
| Base.SeasoningSalt | 0.2 | -10.0 | 20.0 | - | - | - | - | - | - | - | GlugFood |
| Base.Seaweed | 0.2 | -3.0 | - | 3.0 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.SourCream | 0.2 | -16.0 | - | 420.0 | 370.0 | 14.0 | 2.0 | 3 | 5 | - | - |
| Base.Soysauce | 0.2 | -10.0 | 40.0 | 20.0 | 0.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Squash | 0.5 | -20.0 | - | 202.0 | 10.22 | 10.3 | 17.26 | 14 | 28 | - | 2handforced |
| Base.TomatoPaste | 0.2 | -15.0 | - | 120.0 | 32.0 | 8.0 | 0.0 | - | - | - | GlugFood |
| Base.Violets | 0.1 | -2.0 | - | 27.0 | 7.0 | 0.0 | 1.0 | 6 | 10 | - | EatSmall |
| Base.Wasabi | 0.2 | -10.0 | 20.0 | - | - | - | - | 4 | 8 | - | EatSmall |
| Base.Yoghurt | 0.3 | -10.0 | - | 30.0 | 1.0 | 1.0 | 5.0 | 10 | 15 | - | Candrink |

## Nut（2 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Acorn | 0.1 | -10.0 | - | 55.0 | 12.0 | 24.0 | 6.0 | 180 | 365 | - | - |
| Base.Peanuts | 0.2 | -8.0 | - | 161.0 | 4.57 | 13.96 | 7.31 | - | - | - | EatSmall |

## Oil（2 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.OilOlive | 0.2 | -30.0 | - | 2480.0 | 0.0 | 150.0 | 0.0 | - | - | - | GlugFood |
| Base.OilVegetable | 0.2 | -30.0 | - | 2120.0 | 0.0 | 130.0 | 0.0 | - | - | - | GlugFood |

## Pasta（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Macaroni | 2.0 | -60.0 | 60.0 | 3360.0 | 656.0 | 16.0 | 112.0 | - | - | - | EatSmall |
| Base.Pasta | 2.0 | -60.0 | 60.0 | 3360.0 | 656.0 | 16.0 | 112.0 | - | - | - | EatOffStick |
| Base.Ramen | 0.2 | -10.0 | 40.0 | 52.0 | 0.0 | 14.0 | 10.0 | 365 | 730 | - | - |

## Poultry（9 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Chicken | 0.3 | -33.0 | - | 230.0 | 0.0 | 9.0 | 38.0 | 2 | 4 | - | - |
| Base.ChickenFillet | 0.3 | -30.0 | - | 230.0 | 0.0 | 9.0 | 38.0 | 2 | 4 | - | - |
| Base.ChickenNuggets | 0.2 | -10.0 | - | 230.0 | 10.2 | 8.1 | 26.441 | 3 | 5 | - | EatSmall |
| Base.ChickenWhole | 1.2 | -160.0 | - | 1495.0 | 0.0 | 41.0 | 99.8 | 2 | 4 | - | - |
| Base.ChickenWings | 0.3 | -19.0 | - | 190.0 | 0.0 | 6.0 | 22.0 | 2 | 4 | - | - |
| Base.TurkeyFillet | 0.3 | -50.0 | - | 230.0 | 0.0 | 10.0 | 32.0 | 2 | 4 | - | - |
| Base.TurkeyLegs | 0.3 | -42.0 | - | 230.0 | 0.0 | 9.0 | 38.0 | 2 | 4 | - | - |
| Base.TurkeyWhole | 1.3 | -224.0 | - | 1821.0 | 0.0 | 53.3 | 104.2 | 2 | 4 | - | - |
| Base.TurkeyWings | 0.3 | -30.0 | - | 200.0 | 0.0 | 10.0 | 32.0 | 2 | 4 | - | - |

## Rice（5 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Rice | 2.0 | -60.0 | - | 2880.0 | 648.0 | 0.0 | 72.0 | - | - | true | - |
| Base.WaterPotForgedRice | 3.0 | -10.0 | - | 480.0 | 108.0 | 0.0 | 12.0 | 3 | 6 | - | Pot |
| Base.WaterPotRice | 3.0 | -10.0 | - | 480.0 | 108.0 | 0.0 | 12.0 | 3 | 6 | - | Pot |
| Base.WaterSaucepanRice | 3.0 | -10.0 | - | 480.0 | 108.0 | 0.0 | 12.0 | 3 | 6 | - | Plate |
| Base.WaterSaucepanRiceCopper | 3.0 | -10.0 | - | 480.0 | 108.0 | 0.0 | 12.0 | 3 | 6 | - | Plate |

## Roe（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.CannedRoe_Open | 0.8 | -10.0 | - | 150.0 | 0.0 | 11.0 | 14.0 | 3 | 5 | - | Candrink |
| Base.Caviar | 0.2 | -10.0 | - | 150.0 | 0.0 | 11.0 | 14.0 | 3 | 5 | - | GlugFood |
| Base.FishRoe | 0.1 | -10.0 | - | 63.0 | 0.32 | 4.18 | 5.55 | 14 | 21 | - | - |

## Sausage（6 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Baloney | 0.2 | -30.0 | - | 200.0 | 2.0 | 6.35 | 22.65 | 2 | 4 | - | - |
| Base.BaloneySlice | 0.04 | -5.0 | - | 33.0 | 0.33 | 1.06 | 3.78 | 2 | 4 | - | - |
| Base.Pepperoni | 0.1 | -20.0 | - | 180.0 | 0.0 | 4.35 | 15.62 | 15 | 30 | - | - |
| Base.Salami | 0.1 | -20.0 | - | 330.0 | 2.0 | 26.0 | 22.0 | 10 | 15 | - | - |
| Base.SalamiSlice | 0.02 | -4.0 | - | 66.0 | 0.4 | 5.2 | 4.4 | 10 | 15 | - | - |
| Base.Sausage | 0.1 | -20.0 | - | 180.0 | 0.0 | 4.35 | 15.62 | 2 | 4 | - | - |

## Seafood（10 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Crayfish | 0.2 | -10.0 | - | 40.0 | 0.0 | 2.0 | 8.0 | 2 | 4 | - | - |
| Base.Lobster | 0.4 | -40.0 | - | 120.0 | 0.0 | 7.0 | 28.0 | 2 | 4 | - | 2handforced |
| Base.Oysters | 0.1 | -5.0 | - | 15.0 | 10.0 | 4.0 | 22.0 | 2 | 4 | - | 2handforced |
| Base.OystersFried | 0.1 | -6.0 | - | 25.0 | 11.0 | 4.0 | 20.0 | 4 | 7 | - | 2handforced |
| Base.Shrimp | 0.1 | -10.0 | - | 80.0 | 0.0 | 7.0 | 10.0 | 2 | 4 | - | - |
| Base.ShrimpDumpling | 0.1 | -15.0 | - | 120.0 | 5.0 | 7.0 | 15.0 | 2 | 4 | - | - |
| Base.ShrimpFried | 0.1 | -15.0 | - | 160.0 | 17.0 | 14.0 | 16.0 | 2 | 4 | - | - |
| Base.ShrimpFriedCraft | 0.1 | -15.0 | - | 160.0 | 17.0 | 14.0 | 16.0 | 2 | 4 | - | - |
| Base.Squid | 0.2 | -30.0 | - | 205.0 | 1.0 | 13.0 | 32.52 | 2 | 4 | - | - |
| Base.SquidCalamari | 0.1 | -10.0 | - | 105.0 | 3.0 | 0.0 | 18.0 | 2 | 4 | - | - |

## Seed（4 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.FlaxSeed | 0.02 | -1.0 | - | 71.0 | 0.0 | 4.5 | 0.0 | - | - | - | - |
| Base.PoppySeed | 0.1 | -1.0 | - | 31.0 | 3.0 | 2.0 | 1.6 | - | - | - | EatSmall |
| Base.PumpkinSeed | 0.1 | -5.0 | - | 155.0 | 14.12 | 5.48 | 4.34 | - | - | - | EatSmall |
| Base.SunflowerSeeds | 0.1 | -5.0 | - | 355.0 | 0.0 | 22.5 | 0.0 | - | - | - | - |

## Stock（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.BouillonCube | 0.1 | -3.0 | 5.0 | 16.0 | 2.3 | 0.5 | 0.6 | - | - | - | EatSmall |

## Sugar（4 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Sugar | 0.6 | -30.0 | - | 387.0 | 100.0 | 0.0 | 0.0 | - | - | - | Candrink |
| Base.SugarBrown | 0.6 | -30.0 | - | 337.0 | 90.0 | 0.0 | 0.0 | - | - | - | Candrink |
| Base.SugarCubes | 0.02 | -4.0 | - | 44.0 | 12.0 | 0.0 | 0.0 | - | - | - | EatSmall |
| Base.SugarPacket | 0.005 | -1.0 | - | 11.0 | 3.0 | 0.0 | 0.0 | - | - | - | - |

## Tea（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Teabag2 | 0.1 | -5.0 | 10.0 | - | - | - | - | - | - | - | - |

## Thickener（3 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Cornflour2 | 2.0 | -60.0 | - | - | - | - | - | - | - | true | - |
| Base.Cornmeal2 | 2.0 | -20.0 | - | - | - | - | - | - | - | true | - |
| Base.Flour2 | 2.0 | -60.0 | - | 50.0 | 21.0 | 0.0 | 5.0 | - | - | true | - |

## Unknown（360 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.AligatorGar | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Animal_Brain | 0.1 | - | - | - | - | - | - | - | - | - | - |
| Base.Animal_Brain_Small | 0.1 | - | - | - | - | - | - | - | - | - | - |
| Base.Antibiotics | 0.1 | - | - | - | - | - | - | - | - | - | - |
| Base.BagelPlain | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 1 | 6 | - | - |
| Base.BagelPoppy | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 1 | 6 | - | - |
| Base.BagelSesame | 0.1 | -10.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 1 | 6 | - | - |
| Base.BaguetteDough | 0.3 | -15.0 | 15.0 | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | - | EatOffStick |
| Base.BaguetteSandwich | 0.2 | -10.0 | - | 360.0 | 42.0 | 8.5 | 5.8 | 3 | 6 | - | - |
| Base.BaitFish | 0.1 | -3.0 | - | 30.0 | 0.0 | 1.5 | 8.52 | 4 | 8 | - | - |
| Base.BakingTray_Muffin | 1.5 | -30.0 | - | 520.0 | 50.45 | 52.61 | 54.53 | 3 | 10 | true | - |
| Base.BakingTray_Muffin_Recipe | 1.5 | -30.0 | - | 520.0 | 50.45 | 52.61 | 54.53 | 3 | 10 | true | - |
| Base.BarleySeed | 0.02 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.BarleySheaf | 1.0 | -5.0 | - | - | - | - | - | 7 | 14 | true | - |
| Base.BarleySheafDried | 1.0 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.BlackCrappie | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.BlueCatfish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Bluegill | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.BreadDough | 0.3 | -24.0 | 15.0 | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | - | 2handforced |
| Base.BucketOfSoup | 3.0 | -40.0 | -40.0 | 202.0 | 25.0 | 4.5 | 14.0 | 3 | 5 | - | Bucket |
| Base.BucketOfStew | 3.0 | -40.0 | -40.0 | 202.0 | 25.0 | 4.5 | 14.0 | 3 | 5 | - | Bucket |
| Base.Bull_Head_Angus | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Bull_Head_Holstein | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Bull_Head_Simmental | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.BunsHamburger | 0.4 | - | - | 708.0 | 132.0 | 8.88 | 23.6 | 3 | 6 | true | - |
| Base.BunsHotdog | 0.3 | - | - | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | true | - |
| Base.Burger | 0.3 | -25.0 | - | 440.0 | 0.0 | 37.0 | 25.0 | 3 | 5 | - | 2handforced |
| Base.BurgerRecipe | 0.3 | -20.0 | - | 440.0 | 30.5 | 37.0 | 25.0 | 3 | 5 | - | 2handforced |
| Base.Burrito | 0.3 | -25.0 | - | 500.0 | 100.0 | 34.0 | 37.0 | 3 | 5 | - | - |
| Base.BurritoRecipe | 0.1 | -5.0 | - | 40.0 | 0.0 | 2.0 | 2.0 | 3 | 5 | - | - |
| Base.Butter | 0.3 | -24.0 | - | 3200.0 | 0.0 | 352.0 | 0.0 | - | - | - | - |
| Base.CabbageRoll | 0.3 | -20.0 | - | 110.0 | 7.0 | 7.0 | 5.0 | 3 | 5 | - | - |
| Base.CakeBlackForest | 0.2 | -10.0 | - | 90.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.CakeCarrot | 0.2 | -7.0 | - | 70.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.CakeCheeseCake | 0.2 | -8.0 | - | 80.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.CakeChocolate | 0.2 | -10.0 | - | 90.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.CakePrep | 0.5 | -30.0 | - | 800.0 | 50.0 | 48.0 | 8.0 | 4 | 9 | - | Plate |
| Base.CakeRaw | 0.5 | -15.0 | - | 560.0 | 9.0 | 53.0 | 10.0 | 4 | 9 | - | Plate |
| Base.CakeRedVelvet | 0.2 | -8.0 | - | 80.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.CakeSlice | 0.2 | -7.0 | - | 70.0 | 1.0 | 5.0 | 5.0 | 3 | 5 | - | - |
| Base.CakeStrawberryShortcake | 0.2 | -8.0 | - | 75.0 | 4.0 | 12.0 | 10.0 | 3 | 5 | - | - |
| Base.Calf_Head_Angus | 1.2 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Calf_Head_Holstein | 1.2 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Calf_Head_Simmental | 1.2 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.CandyPackage | 0.6 | - | - | 500.0 | 125.0 | 2.5 | 0.0 | - | - | true | - |
| Base.CannedBellPepper | 0.8 | -48.0 | - | 180.0 | 42.0 | 0.0 | 6.0 | 30 | 60 | true | - |
| Base.CannedBolognese | 0.8 | - | - | 540.0 | 68.0 | 22.0 | 18.0 | - | - | true | - |
| Base.CannedBroccoli | 0.8 | -45.0 | - | 55.0 | 10.0 | 0.5 | 4.5 | 30 | 60 | true | - |
| Base.CannedCabbage | 0.8 | -48.0 | - | 360.0 | 82.0 | 1.4 | 18.0 | 30 | 60 | true | - |
| Base.CannedCarrots | 0.8 | -40.0 | - | 125.0 | 30.0 | 0.75 | 3.0 | 30 | 60 | true | - |
| Base.CannedCarrots2 | 0.8 | - | - | 10.5 | 28.0 | 0.0 | 0.0 | - | - | true | - |
| Base.CannedChili | 0.8 | - | - | 260.0 | 33.0 | 7.0 | 16.0 | - | - | true | - |
| Base.CannedCorn | 0.8 | - | - | 315.0 | 70.0 | 1.75 | 7.0 | - | - | true | - |
| Base.CannedCornedBeef | 0.8 | - | - | 720.0 | 0.0 | 48.0 | 78.0 | - | - | true | - |
| Base.CannedEggplant | 0.8 | -48.0 | - | 342.0 | 81.0 | 2.4 | 13.5 | 30 | 60 | true | - |
| Base.CannedFruitBeverage | 0.8 | - | - | 250.0 | 0.0 | 24.0 | 10.0 | - | - | true | - |
| Base.CannedFruitCocktail | 0.8 | - | - | 250.0 | 0.0 | 24.0 | 10.0 | - | - | true | - |
| Base.CannedLeek | 0.8 | -48.0 | - | 216.0 | 560.0 | 1.2 | 15.2 | 30 | 60 | true | - |
| Base.CannedMilk | 0.8 | - | - | 472.0 | 23.6 | 23.6 | 23.6 | - | - | - | - |
| Base.CannedMushroomSoup | 0.8 | - | - | 160.0 | 19.0 | 8.0 | 3.0 | - | - | true | - |
| Base.CannedPeaches | 0.8 | - | - | 250.0 | 0.0 | 24.0 | 10.0 | - | - | true | - |
| Base.CannedPeas | 0.8 | - | - | 280.0 | 52.5 | 0.0 | 14.0 | - | - | true | - |
| Base.CannedPineapple | 0.8 | - | - | 250.0 | 0.0 | 24.0 | 10.0 | - | - | true | - |
| Base.CannedPotato | 0.8 | -48.0 | - | 210.0 | 45.0 | 0.45 | 9.0 | 30 | 60 | true | - |
| Base.CannedPotato2 | 0.8 | - | - | 175.0 | 35.0 | 0.0 | 2.5 | - | - | true | - |
| Base.CannedRedRadish | 0.8 | -45.0 | - | 15.0 | 2.25 | 0.0 | 0.0 | 30 | 60 | true | - |
| Base.CannedRoe | 0.8 | -48.0 | - | 56.0 | 14.0 | 0.8 | 5.2 | 30 | 60 | true | - |
| Base.CannedSardines | 0.3 | - | - | 150.0 | 0.0 | 11.0 | 14.0 | - | - | true | - |
| Base.CannedTomato | 0.8 | -48.0 | - | 56.0 | 14.0 | 0.8 | 5.2 | 30 | 60 | true | - |
| Base.CannedTomato2 | 0.8 | - | - | 90.0 | 18.0 | 0.0 | 3.0 | - | - | true | - |
| Base.CanPipe_Tobacco | 0.3 | 0.0 | - | - | - | - | - | - | - | - | Pipe |
| Base.Cereal | 0.2 | -40.0 | - | 2360.0 | 572.0 | 26.0 | 52.0 | - | - | - | EatBox |
| Base.CerealBowl | 0.8 | -20.0 | -15.0 | 295.0 | 71.5 | 3.25 | 6.5 | 4 | 7 | - | 2handbowl |
| Base.ChannelCatfish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Chicken_Chick_Head | 0.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Chicken_Hen_Brown_Head | 0.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Chicken_Hen_White_Head | 0.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Chicken_Rooster_Head_Brown | 0.2 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Chicken_Rooster_Head_White | 0.2 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.ChickenFeather | 0.001 | - | - | - | - | - | - | - | - | - | - |
| Base.ChickenFoot | 0.1 | -12.0 | - | 70.0 | 17.0 | 14.0 | 16.0 | 2 | 4 | - | - |
| Base.ChocoCakes | 0.2 | -10.0 | - | 200.0 | 30.0 | 8.0 | 1.8 | - | - | - | - |
| Base.Chum | 0.5 | 0.0 | - | - | - | - | - | - | - | - | - |
| Base.Cigar | 0.2 | 0.0 | - | - | - | - | - | - | - | - | Cigarettes |
| Base.CigaretteRolled | 0.01 | 0.0 | - | - | - | - | - | - | - | - | Cigarettes |
| Base.CigaretteSingle | 0.01 | 0.0 | - | - | - | - | - | - | - | - | Cigarettes |
| Base.Cigarillo | 0.02 | 0.0 | - | - | - | - | - | - | - | - | Cigarettes |
| Base.CinnamonRoll | 0.1 | -12.0 | - | 350.0 | 50.0 | 24.0 | 4.0 | - | - | - | - |
| Base.Comfrey | 0.1 | - | - | - | - | - | - | 6 | 10 | true | - |
| Base.ComfreyDried | 0.1 | - | - | - | - | - | - | - | - | true | - |
| Base.Cone | 0.1 | -5.0 | - | 15.0 | 10.0 | 5.0 | 2.0 | 15 | 20 | - | - |
| Base.ConeIcecream | 0.2 | -15.0 | - | 470.0 | 120.0 | 44.0 | 20.0 | 1 | 2 | - | EatOffStick |
| Base.ConeIcecreamMelted | 0.2 | -15.0 | - | 470.0 | 120.0 | 44.0 | 20.0 | 2 | 3 | - | - |
| Base.ConeIcecreamToppings | 0.2 | -15.0 | - | 470.0 | 120.0 | 44.0 | 20.0 | 1 | 2 | - | EatOffStick |
| Base.CookieChocolateChip | 0.1 | -5.0 | - | 160.0 | 22.0 | 8.0 | 1.0 | - | - | - | - |
| Base.CookieChocolateChipDough | 1.9 | -23.0 | - | 960.0 | 132.0 | 48.0 | 1.0 | 7 | 30 | - | 2handforced |
| Base.CookieJelly | 0.1 | -5.0 | - | 160.0 | 22.0 | 8.0 | 1.0 | - | - | - | - |
| Base.CookiesChocolate | 0.1 | -5.0 | - | 170.0 | 25.0 | 9.0 | 2.0 | - | - | - | - |
| Base.CookiesChocolateDough | 1.9 | -23.0 | - | 1020.0 | 150.0 | 54.0 | 12.0 | 7 | 30 | - | 2handforced |
| Base.CookiesOatmeal | 0.1 | -5.0 | - | 110.0 | 20.0 | 6.0 | 1.0 | - | - | - | - |
| Base.CookiesOatmealDough | 1.9 | -23.0 | - | 660.0 | 120.0 | 36.0 | 6.0 | 7 | 30 | - | 2handforced |
| Base.CookiesShortbread | 0.1 | -5.0 | - | 120.0 | 22.0 | 8.0 | 2.0 | - | - | - | - |
| Base.CookiesShortbreadDough | 1.9 | -23.0 | - | 720.0 | 132.0 | 48.0 | 12.0 | 7 | 30 | - | 2handforced |
| Base.CookiesSugar | 0.1 | -5.0 | - | 120.0 | 22.0 | 8.0 | 2.0 | - | - | - | - |
| Base.CookiesSugarDough | 1.9 | -23.0 | - | 720.0 | 132.0 | 48.0 | 12.0 | 7 | 30 | - | 2handforced |
| Base.Corndog | 0.1 | -12.0 | - | 180.0 | 7.0 | 9.0 | 19.0 | 3 | 6 | - | EatOffStick |
| Base.CorpseAnimal | 0.1 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Cow_Head_Angus | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Cow_Head_Holstein | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Cow_Head_Simmental | 2.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Creamocle | 0.2 | -15.0 | - | 100.0 | 19.0 | 1.5 | 1.0 | 1 | 2 | - | EatOffStick |
| Base.Creamocle_Melted | 0.2 | -15.0 | - | 100.0 | 19.0 | 1.5 | 1.0 | 2 | 3 | - | - |
| Base.Crisps | 0.2 | -15.0 | - | 720.0 | 72.0 | 45.0 | 4.5 | - | - | - | EatBox |
| Base.Crisps2 | 0.2 | -15.0 | - | 720.0 | 72.0 | 45.0 | 4.5 | - | - | - | EatBox |
| Base.Crisps3 | 0.2 | -15.0 | - | 720.0 | 72.0 | 45.0 | 4.5 | - | - | - | EatBox |
| Base.Crisps4 | 0.2 | -15.0 | - | 720.0 | 72.0 | 45.0 | 4.5 | - | - | - | EatBox |
| Base.CrispyRiceSquare | 0.2 | -10.0 | - | 140.0 | 28.0 | 3.0 | 1.0 | - | - | - | - |
| Base.Croissant | 0.1 | -8.0 | - | 180.0 | 32.0 | 15.0 | 4.0 | 3 | 5 | - | - |
| Base.Cupcake | 0.2 | -20.0 | - | 305.0 | 67.0 | 4.0 | 4.0 | 4 | 8 | - | - |
| Base.Danish | 0.1 | -7.0 | - | 263.0 | 34.0 | 13.0 | 4.0 | 3 | 5 | - | - |
| Base.DeadBird | 0.1 | -15.0 | - | 161.0 | 0.5 | 2.0 | 22.0 | 8 | 12 | - | - |
| Base.DeadMouse | 0.05 | -10.0 | - | 220.0 | 0.7 | 3.15 | 9.5 | 6 | 10 | - | - |
| Base.DeadMousePups | 0.03 | -5.0 | - | 110.0 | 0.35 | 1.58 | 4.2 | 6 | 10 | - | - |
| Base.DeadMousePupsSkinned | 0.03 | -5.0 | - | 110.0 | 0.35 | 1.58 | 4.2 | 6 | 10 | - | - |
| Base.DeadMouseSkinned | 0.05 | -10.0 | - | 220.0 | 0.7 | 3.15 | 9.5 | 6 | 10 | - | - |
| Base.DeadRabbit | 1.0 | -45.0 | - | 1730.0 | 0.0 | 35.0 | 330.0 | 8 | 12 | - | - |
| Base.DeadRat | 0.2 | -22.0 | - | 324.0 | 0.0 | 16.0 | 40.0 | 6 | 10 | - | - |
| Base.DeadRatBaby | 0.12 | -12.0 | - | 174.6 | 0.0 | 8.6 | 21.6 | 6 | 10 | - | - |
| Base.DeadRatBabySkinned | 0.12 | -12.0 | - | 174.6 | 0.0 | 8.6 | 21.6 | 6 | 10 | - | - |
| Base.DeadRatSkinned | 0.2 | -22.0 | - | 324.0 | 0.0 | 16.0 | 40.0 | 6 | 10 | - | - |
| Base.DeadSquirrel | 0.4 | -32.0 | - | 480.0 | 0.0 | 15.0 | 84.8 | 8 | 12 | - | - |
| Base.Deer_Buck_Head | 1.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Deer_Doe_Head | 1.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Deer_Fawn_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.DehydratedMeatStick | 0.1 | -10.0 | - | 100.0 | 5.3 | 5.1 | 21.63 | - | - | - | - |
| Base.DentedCan | 0.8 | - | - | - | - | - | - | - | - | true | - |
| Base.Dogfood | 0.8 | - | - | 498.0 | 77.56 | 12.58 | 16.04 | - | - | true | - |
| Base.Dough | 0.3 | -15.0 | 20.0 | 532.0 | 99.0 | 6.66 | 17.7 | 3 | 6 | - | - |
| Base.DoughnutChocolate | 0.1 | -7.0 | - | 180.0 | 35.0 | 15.0 | 3.0 | 3 | 5 | - | - |
| Base.DoughnutFrosted | 0.1 | -7.0 | - | 180.0 | 35.0 | 15.0 | 3.0 | 3 | 5 | - | - |
| Base.DoughnutJelly | 0.1 | -7.0 | - | 180.0 | 35.0 | 15.0 | 3.0 | 3 | 5 | - | - |
| Base.DoughnutPlain | 0.1 | -7.0 | - | 180.0 | 35.0 | 15.0 | 3.0 | 3 | 5 | - | - |
| Base.Dung_Chicken | 0.01 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Cow | 1.0 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Deer | 0.5 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Mouse | 0.01 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Pig | 0.7 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Rabbit | 0.1 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Raccoon | 0.1 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Rat | 0.01 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Sheep | 0.5 | - | - | - | - | - | - | - | - | true | - |
| Base.Dung_Turkey | 0.01 | - | - | - | - | - | - | - | - | true | - |
| Base.EggCarton | 1.0 | - | - | - | - | - | - | 14 | 21 | - | - |
| Base.FishGuts | 0.1 | -5.0 | - | - | - | - | - | 4 | 8 | - | - |
| Base.FishRoeSac | 0.1 | -5.0 | - | 56.0 | 14.0 | 0.8 | 5.2 | 4 | 8 | - | - |
| Base.FlatheadCatfish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Flax | 0.2 | - | - | - | - | - | - | 7 | 14 | true | - |
| Base.FlaxRippled | 0.2 | - | - | - | - | - | - | - | - | true | - |
| Base.FreshwaterDrum | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Fries | 0.4 | -10.0 | - | 203.0 | 35.97 | 5.19 | 3.35 | 3 | 5 | - | EatBox |
| Base.Frozen_ChickenNuggets | 1.0 | - | - | - | - | - | - | 3 | 5 | true | - |
| Base.Frozen_FishFingers | 1.0 | - | - | - | - | - | - | 3 | 5 | true | - |
| Base.Frozen_FrenchFries | 1.0 | - | - | - | - | - | - | 3 | 5 | true | - |
| Base.Frozen_TatoDots | 1.0 | - | - | - | - | - | - | 3 | 5 | true | - |
| Base.FruitSalad | 0.7 | -60.0 | - | 97.0 | 25.0 | 0.5 | 1.4 | 2 | 3 | - | 2handbowl |
| Base.FruitSaladClay | 0.7 | -60.0 | - | 97.0 | 25.0 | 0.5 | 1.4 | 2 | 3 | - | 2handbowl |
| Base.FudgeePop | 0.2 | -15.0 | - | 100.0 | 18.0 | 2.5 | 2.0 | 1 | 2 | - | EatOffStick |
| Base.FudgeePop_Melted | 0.2 | -15.0 | - | 100.0 | 18.0 | 2.5 | 2.0 | 2 | 3 | - | - |
| Base.Gingerbreadman | 0.1 | -5.0 | - | 160.0 | 22.0 | 8.0 | 1.0 | - | - | - | - |
| Base.GingerRoot | 0.1 | -5.0 | - | 46.0 | 0.44 | 2.36 | 5.1 | 6 | 10 | - | - |
| Base.GrahamCrackers | 0.1 | -5.0 | - | 70.0 | 12.0 | 6.0 | 1.0 | - | - | - | - |
| Base.GranolaBar | 0.2 | -15.0 | - | 270.0 | 120.0 | 44.0 | 20.0 | - | - | - | - |
| Base.GrassTuft | 0.1 | -7.0 | - | - | - | - | - | - | - | true | - |
| Base.GreenSunfish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.GriddlePanFriedVegetables | 1.5 | -10.0 | - | 190.0 | 25.0 | 2.0 | 11.0 | 3 | 5 | - | Plate |
| Base.Gum | 0.1 | -1.0 | - | 30.0 | 10.0 | 0.0 | 0.0 | - | - | - | - |
| Base.HalloweenPumpkin | 1.0 | -40.0 | - | 404.0 | 20.45 | 20.61 | 34.53 | 14 | 28 | - | 2handforced |
| Base.HayTuft | 0.1 | -12.0 | - | - | - | - | - | - | - | true | - |
| Base.HempBundle | 1.0 | -5.0 | - | - | - | - | - | 7 | 14 | true | - |
| Base.HempBundleDried | 1.0 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.HiHis | 0.2 | -10.0 | - | 200.0 | 30.0 | 8.0 | 1.8 | - | - | - | - |
| Base.Honey | 0.4 | -20.0 | - | 660.0 | 187.0 | 0.0 | 0.0 | - | - | - | GlugFood |
| Base.Hops | 0.3 | - | - | - | - | - | - | 7 | 14 | true | - |
| Base.HopsDried | 0.3 | - | - | - | - | - | - | - | - | true | - |
| Base.HotdogPack | 0.6 | - | - | 270.0 | 5.0 | 8.0 | 5.0 | 3 | 6 | true | - |
| Base.HotDrink | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkClay | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkCopper | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkGold | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkMetal | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkRed | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkSilver | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkSpiffo | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkTea | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Teacup |
| Base.HotDrinkTeaCeramic | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Teacup |
| Base.HotDrinkTumbler | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.HotDrinkWhite | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.Icecream | 0.2 | -30.0 | - | 1680.0 | 180.0 | 84.0 | 26.0 | 1 | 2 | - | Candrink |
| Base.IcecreamMelted | 0.2 | -30.0 | - | 1680.0 | 180.0 | 84.0 | 26.0 | 2 | 3 | - | Candrink |
| Base.IcecreamSandwich | 0.2 | -15.0 | - | 140.0 | 26.0 | 3.0 | 2.0 | 1 | 2 | - | - |
| Base.IcecreamSandwich_Melted | 0.2 | -15.0 | - | 140.0 | 26.0 | 3.0 | 2.0 | 2 | 3 | - | - |
| Base.JellyRoll | 0.1 | -7.0 | - | 230.0 | 41.0 | 7.0 | 1.0 | 3 | 5 | - | - |
| Base.Ladybug | 0.01 | -1.0 | - | 1.5 | 0.0 | 0.05 | 0.25 | 14 | 21 | - | EatSmall |
| Base.LargemouthBass | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Leech | 0.1 | -1.0 | - | 90.0 | 2.11 | 1.9 | 17.41 | 2 | 4 | - | - |
| Base.LemonBar | 0.1 | -7.0 | - | 156.0 | 22.0 | 11.0 | 2.0 | 3 | 5 | - | - |
| Base.Lollipop | 0.1 | -5.0 | - | 40.0 | 10.0 | 0.5 | 0.0 | - | - | - | EatOffStick |
| Base.Macandcheese | 0.5 | - | - | 690.0 | 126.0 | 12.0 | 21.0 | 180 | 365 | true | - |
| Base.Maki | 0.1 | -10.0 | - | 12.0 | 5.0 | 1.0 | 2.0 | 2 | 4 | - | - |
| Base.MeatSteamBun | 0.1 | -15.0 | - | 35.0 | 12.0 | 4.0 | 18.0 | 2 | 4 | - | - |
| Base.MintCandy | 0.1 | -2.0 | - | 60.0 | 15.0 | 0.0 | 0.0 | - | - | - | - |
| Base.Modjeska | 0.1 | -10.0 | - | 60.0 | 15.0 | 0.0 | 0.0 | - | - | - | - |
| Base.MuffinFruit | 0.1 | -7.0 | - | 120.0 | 10.45 | 12.61 | 14.53 | 5 | 8 | - | - |
| Base.MuffinGeneric | 0.1 | -7.0 | - | 120.0 | 10.45 | 12.61 | 14.53 | 5 | 8 | - | - |
| Base.Muffintray_Biscuit | 1.5 | -23.0 | - | 960.0 | 132.0 | 48.0 | 6.0 | 3 | 5 | true | - |
| Base.Muskellunge | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Mussels | 0.1 | -5.0 | - | 15.0 | 10.0 | 4.0 | 22.0 | 2 | 4 | - | EatSmall |
| Base.MysteryCan | 0.8 | - | - | - | - | - | - | - | - | true | - |
| Base.NoodleSoup | 1.0 | -10.0 | - | 52.0 | 0.0 | 14.0 | 10.0 | 1 | 3 | - | 2handbowl |
| Base.Oatmeal | 0.8 | -10.0 | - | 300.0 | 81.0 | 9.0 | 15.0 | 1 | 2 | - | 2handbowl |
| Base.OatsRaw | 0.8 | -50.0 | - | 1500.0 | 405.0 | 45.0 | 75.0 | 180 | 365 | - | Candrink |
| Base.Onigiri | 0.1 | -12.0 | - | 25.0 | 12.0 | 4.0 | 18.0 | 2 | 4 | - | - |
| Base.Paddlefish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Painauchocolat | 0.1 | -2.0 | - | 414.0 | 47.4 | 21.1 | 6.9 | 3 | 7 | - | - |
| Base.Pancakes | 0.3 | -16.0 | - | 210.0 | 42.0 | 2.0 | 6.0 | 3 | 5 | - | - |
| Base.PancakesCraft | 0.3 | -20.0 | - | 210.0 | 42.0 | 2.0 | 6.0 | 3 | 5 | - | - |
| Base.PancakesRecipe | 0.3 | -20.0 | - | 210.0 | 42.0 | 2.0 | 6.0 | 3 | 5 | - | - |
| Base.PanFriedVegetables | 1.5 | -10.0 | - | 516.0 | 36.0 | 41.5 | 4.8 | 3 | 5 | - | Plate |
| Base.PanFriedVegetables2 | 1.3 | -10.0 | - | 180.0 | 36.0 | 2.5 | 6.0 | 3 | 5 | - | Plate |
| Base.PanFriedVegetablesForged | 1.0 | -10.0 | - | 516.0 | 36.0 | 41.5 | 4.8 | 3 | 5 | - | Plate |
| Base.PastaBowl | 1.0 | -12.0 | - | 330.0 | 41.0 | 6.5 | 24.0 | 3 | 6 | - | 2handbowl |
| Base.PastaBowlClay | 1.0 | -12.0 | - | 330.0 | 41.0 | 6.5 | 24.0 | 3 | 6 | - | 2handbowl |
| Base.PastaPan | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 4 | 7 | - | Plate |
| Base.PastaPanCopper | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 4 | 7 | - | Plate |
| Base.PastaPot | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Pot |
| Base.PastaPotForged | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Pot |
| Base.Peppermint | 0.1 | -2.0 | - | 16.6 | 4.33 | 0.0 | 0.0 | - | - | - | - |
| Base.Perogies | 0.1 | -7.0 | - | 160.0 | 31.0 | 2.0 | 5.0 | 3 | 7 | - | - |
| Base.Pie | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PieApple | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PieBlueberry | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PieKeyLime | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PieLemonMeringue | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PiePrep | 0.5 | -15.0 | - | 189.0 | 11.2 | 11.5 | 9.6 | 4 | 7 | - | Plate |
| Base.PiePumpkin | 0.5 | -30.0 | - | 404.0 | 20.45 | 20.61 | 54.53 | 5 | 8 | - | - |
| Base.PieWholeRaw | 0.5 | -15.0 | - | 189.0 | 11.2 | 11.5 | 9.6 | 4 | 9 | - | Plate |
| Base.PieWholeRawSweet | 0.5 | -15.0 | - | 189.0 | 11.2 | 11.5 | 9.6 | 4 | 9 | - | Plate |
| Base.Pig_Boar_Head_Black | 1.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pig_Boar_Head_Pink | 1.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pig_Piglet_Head_Black | 0.8 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pig_Piglet_Head_Pink | 0.8 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pig_Sow_Head_Black | 1.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pig_Sow_Head_Pink | 1.4 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Pizza | 0.3 | -25.0 | - | 990.0 | 120.0 | 39.0 | 42.0 | 3 | 5 | - | - |
| Base.PizzaRecipe | 1.5 | -80.0 | - | 1529.0 | 231.0 | 34.0 | 41.8 | 3 | 5 | - | Pizza |
| Base.PizzaWhole | 1.8 | -150.0 | - | 5940.0 | 720.0 | 234.0 | 252.0 | 3 | 5 | - | Pizza |
| Base.Plantain | 0.1 | - | - | - | - | - | - | 6 | 10 | true | - |
| Base.PlantainDried | 0.1 | - | - | - | - | - | - | - | - | true | - |
| Base.Plonkies | 0.2 | -10.0 | - | 200.0 | 30.0 | 8.0 | 1.8 | - | - | - | - |
| Base.Popcorn | 0.3 | -10.0 | 10.0 | 120.0 | 20.41 | 2.69 | 3.57 | - | - | - | EatBox |
| Base.Poppies | 0.1 | - | - | 0.1 | 0.0 | 0.0 | 0.0 | 6 | 10 | true | - |
| Base.PoppyPods | 0.1 | - | - | - | - | - | - | 6 | 10 | true | - |
| Base.PoppyPodsDried | 0.1 | - | - | - | - | - | - | - | - | true | - |
| Base.Popsicle | 0.2 | -15.0 | - | 80.0 | 22.0 | 0.0 | 0.0 | 1 | 2 | - | EatOffStick |
| Base.Popsicle_Melted | 0.2 | -15.0 | - | 80.0 | 22.0 | 0.0 | 0.0 | 2 | 3 | - | - |
| Base.PorkRinds | 0.1 | -5.0 | - | 240.0 | 24.0 | 15.0 | 1.5 | - | - | - | EatSmall |
| Base.PotatoPancakes | 0.1 | -15.0 | - | 268.0 | 35.0 | 15.0 | 6.0 | 3 | 7 | - | - |
| Base.PotForgedSoupRecipe | 3.0 | -40.0 | -40.0 | 202.0 | 25.0 | 4.5 | 14.0 | 3 | 5 | - | Pot |
| Base.PotForgedStew | 3.0 | -40.0 | -40.0 | 310.0 | 26.3 | 14.5 | 3.8 | 3 | 5 | - | Pot |
| Base.PotOfSoup | 3.0 | -30.0 | -30.0 | 202.0 | 25.0 | 4.5 | 14.0 | 3 | 5 | - | Pot |
| Base.PotOfSoupRecipe | 3.0 | -40.0 | -40.0 | 202.0 | 25.0 | 4.5 | 14.0 | 3 | 5 | - | Pot |
| Base.PotOfStew | 3.0 | -40.0 | -40.0 | 310.0 | 26.3 | 14.5 | 3.8 | 3 | 5 | - | Pot |
| Base.Pretzel | 0.1 | -5.0 | - | 80.0 | 11.0 | 2.0 | 1.0 | - | - | - | - |
| Base.QuaggaCakes | 0.2 | -10.0 | - | 200.0 | 30.0 | 8.0 | 1.8 | - | - | - | - |
| Base.Rabbit_Head_Appalachian | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Rabbit_Head_CottonTail | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Rabbit_Head_Swamp | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Rabbit_Kitten_Head_Appalachian | 0.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Rabbit_Kitten_Head_CottonTail | 0.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Rabbit_Kitten_Head_Swamp | 0.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Raccoon_Boar_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Raccoon_Kit_Head | 0.5 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Raccoon_Sow_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.RamenBowl | 1.0 | -10.0 | - | 52.0 | 0.0 | 14.0 | 10.0 | 1 | 3 | - | 2handbowl |
| Base.RatKing | 1.0 | -110.0 | - | 1620.0 | 0.0 | 96.0 | 240.0 | 0 | 0 | - | - |
| Base.RedearSunfish | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.RiceBowl | 1.0 | -12.0 | - | 160.0 | 36.0 | 0.0 | 3.0 | 3 | 6 | - | 2handbowl |
| Base.RiceBowlClay | 1.0 | -12.0 | - | 160.0 | 36.0 | 0.0 | 3.0 | 3 | 6 | - | 2handbowl |
| Base.RicePan | 3.0 | -10.0 | - | 720.0 | 0.0 | 48.0 | 78.0 | 4 | 7 | - | Plate |
| Base.RicePanCopper | 3.0 | -10.0 | - | 720.0 | 0.0 | 48.0 | 78.0 | 4 | 7 | - | Plate |
| Base.RicePaper | 0.1 | -4.0 | - | 10.0 | 0.0 | 0.0 | 0.0 | - | - | - | - |
| Base.RicePot | 3.0 | -10.0 | - | 720.0 | 0.0 | 48.0 | 78.0 | 3 | 6 | - | Pot |
| Base.RicePotForged | 3.0 | -10.0 | - | 720.0 | 0.0 | 48.0 | 78.0 | 3 | 6 | - | Pot |
| Base.RyeSeed | 0.02 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.RyeSheaf | 1.0 | -5.0 | - | - | - | - | - | 7 | 14 | true | - |
| Base.RyeSheafDried | 1.0 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.Salad | 0.5 | -60.0 | - | - | - | - | - | 2 | 3 | - | 2handbowl |
| Base.SaladClay | 0.5 | -60.0 | - | - | - | - | - | 2 | 3 | - | 2handbowl |
| Base.Sandwich | 0.2 | -10.0 | - | 360.0 | 42.0 | 8.5 | 5.8 | 3 | 6 | - | - |
| Base.Sauger | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.ScoutCookies | 0.2 | -20.0 | - | 1200.0 | 290.0 | 13.0 | 26.0 | - | - | - | EatBox |
| Base.SeedPaste | 0.2 | -30.0 | - | 2120.0 | 0.0 | 130.0 | 0.0 | 3 | 5 | - | - |
| Base.SeedPasteBowl | 0.3 | -30.0 | - | 2120.0 | 0.0 | 130.0 | 0.0 | 3 | 5 | - | - |
| Base.SesameOil | 0.2 | -10.0 | 40.0 | 120.0 | 0.0 | 14.0 | 0.0 | - | - | - | GlugFood |
| Base.Sheep_Ewe_Head_Black | 1.3 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Sheep_Ewe_Head_White | 1.3 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Sheep_Lamb_Head_Black | 0.8 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Sheep_Lamb_Head_White | 0.8 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Sheep_Ram_Head_Black | 1.3 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Sheep_Ram_Head_White | 1.3 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.SmallmouthBass | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.SmokingPipe_Tobacco | 0.3 | 0.0 | - | - | - | - | - | - | - | - | Pipe |
| Base.Smore | 0.1 | -10.0 | - | 200.0 | 33.0 | 10.0 | 3.0 | 10 | 15 | - | - |
| Base.SnoGlobes | 0.2 | -10.0 | - | 200.0 | 30.0 | 8.0 | 1.8 | - | - | - | - |
| Base.SoupBowl | 1.0 | -15.0 | -15.0 | 124.0 | 15.0 | 4.7 | 6.3 | 1 | 3 | - | 2handbowl |
| Base.SoupBowlClay | 1.0 | -15.0 | -15.0 | 124.0 | 15.0 | 4.7 | 6.3 | 1 | 3 | - | 2handbowl |
| Base.SpottedBass | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.Springroll | 0.1 | -20.0 | - | 180.0 | 22.0 | 17.0 | 9.0 | 2 | 4 | - | - |
| Base.StewBowl | 1.0 | -15.0 | - | 250.0 | 34.0 | 3.0 | 23.0 | 2 | 4 | - | 2handbowl |
| Base.StewBowlClay | 1.0 | -15.0 | - | 250.0 | 34.0 | 3.0 | 23.0 | 2 | 4 | - | 2handbowl |
| Base.StripedBass | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.SugarBeetPulpPot | 3.0 | -45.0 | - | 216.0 | 27.0 | 0.0 | 36.0 | 3 | 6 | - | Pot |
| Base.SugarBeetSugarPot | 3.0 | -30.0 | - | 387.0 | 100.0 | 0.0 | 0.0 | - | - | - | Pot |
| Base.SugarBeetSyrupPot | 3.0 | -30.0 | - | 387.0 | 100.0 | 0.0 | 0.0 | 1 | 2 | - | Pot |
| Base.SunflowerHead | 0.2 | - | - | - | - | - | - | 10 | 13 | true | - |
| Base.SunflowerHeadDried | 0.2 | - | - | - | - | - | - | - | - | true | - |
| Base.SushiEgg | 0.1 | -8.0 | - | 19.0 | 7.0 | 3.0 | 12.0 | 2 | 4 | - | - |
| Base.SushiFish | 0.1 | -8.0 | - | 19.0 | 5.0 | 0.0 | 10.0 | 2 | 4 | - | - |
| Base.Taco | 0.3 | -25.0 | - | 400.0 | 80.0 | 28.0 | 32.0 | 3 | 5 | - | 2handforced |
| Base.TacoRecipe | 0.1 | -5.0 | - | 55.0 | 8.4 | 3.0 | 0.8 | 15 | 20 | - | 2handforced |
| Base.TacoShell | 0.1 | -5.0 | - | 55.0 | 8.4 | 3.0 | 0.8 | 15 | 20 | - | 2handforced |
| Base.Tadpole | 0.1 | -1.0 | - | 90.0 | 2.11 | 1.9 | 17.41 | 2 | 4 | - | - |
| Base.TestHotDrink | 0.5 | - | -20.0 | - | - | - | - | - | - | - | Popcan |
| Base.TinnedBeans | 0.8 | - | - | 170.0 | 33.0 | 1.0 | 7.0 | - | - | true | - |
| Base.TinnedSoup | 0.8 | - | - | 125.0 | 20.0 | 2.5 | 7.5 | - | - | true | - |
| Base.Toast | 0.1 | -8.0 | - | 177.0 | 33.0 | 2.22 | 5.9 | 3 | 6 | - | - |
| Base.Tobacco | 0.2 | - | - | - | - | - | - | 7 | 14 | true | - |
| Base.Tortilla | 0.1 | -5.0 | - | 40.0 | 0.0 | 2.0 | 2.0 | 3 | 5 | - | - |
| Base.TortillaChips | 0.2 | -15.0 | - | 420.0 | 42.0 | 40.0 | 2.5 | - | - | - | EatBox |
| Base.TortillaChipsBaked | 0.2 | -15.0 | - | 120.0 | 0.0 | 6.0 | 6.0 | 3 | 5 | - | EatSmall |
| Base.TunaTin | 0.3 | - | - | 370.0 | 0.0 | 34.0 | 15.0 | - | - | true | - |
| Base.Turkey_Gobbler_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Turkey_Hen_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.Turkey_Poult_Head | 1.0 | - | - | - | - | - | - | 5 | 7 | - | - |
| Base.TurkeyFeather | 0.001 | - | - | - | - | - | - | - | - | - | - |
| Base.TVDinner | 0.4 | -23.0 | - | 670.0 | 81.0 | 25.0 | 30.0 | 3 | 5 | - | Plate |
| Base.Waffles | 0.3 | -15.0 | - | 80.0 | 13.0 | 4.0 | 3.0 | 3 | 5 | - | - |
| Base.WafflesRecipe | 0.3 | -15.0 | - | 80.0 | 13.0 | 4.0 | 3.0 | 3 | 5 | - | - |
| Base.Walleye | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.WaterPotForgedPasta | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Pot |
| Base.WaterPotPasta | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Pot |
| Base.WaterRationCan | 0.8 | - | - | - | - | - | - | - | - | true | - |
| Base.WaterSaucepanPasta | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Plate |
| Base.WaterSaucepanPastaCopper | 3.0 | -10.0 | - | 560.0 | 109.3 | 2.66 | 18.66 | 3 | 6 | - | Plate |
| Base.WheatSeed | 0.02 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.WheatSheaf | 1.0 | -5.0 | - | - | - | - | - | 7 | 14 | true | - |
| Base.WheatSheafDried | 1.0 | -5.0 | - | - | - | - | - | - | - | true | - |
| Base.WhiteBass | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.WhiteCrappie | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |
| Base.YellowPerch | 0.4 | -15.0 | - | 159.0 | 1.0 | 1.0 | 35.0 | 4 | 8 | - | 2handforced |

## Vegetable（4 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Capers | 0.1 | -5.0 | - | 10.0 | 2.0 | 0.0 | 1.0 | - | - | - | EatSmall |
| Base.FrenchFries | 0.2 | -10.0 | - | 203.0 | 35.97 | 5.19 | 3.35 | 3 | 5 | - | - |
| Base.Olives | 0.1 | -5.0 | - | 47.0 | 2.0 | 4.7 | 0.0 | - | - | - | EatSmall |
| Base.TatoDots | 0.2 | -10.0 | - | 203.0 | 35.97 | 5.19 | 3.35 | 3 | 5 | - | - |

## Vegetables（50 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Avocado | 0.3 | -16.0 | -7.0 | 227.0 | 11.75 | 20.96 | 2.67 | 6 | 14 | - | - |
| Base.BellPepper | 0.2 | -8.0 | -2.0 | 30.0 | 7.0 | 0.0 | 1.0 | 5 | 8 | - | - |
| Base.Broccoli | 0.2 | -9.0 | -4.0 | 11.0 | 2.0 | 0.1 | 0.9 | 4 | 6 | - | - |
| Base.BrusselSprouts | 0.6 | -20.0 | -5.0 | 119.0 | 20.45 | 0.85 | 7.95 | 3 | 5 | - | - |
| Base.Cabbage | 0.2 | -24.0 | -10.0 | 180.0 | 41.0 | 0.7 | 9.0 | 2 | 4 | - | - |
| Base.CannedBellPepper_Open | 0.8 | -48.0 | - | 180.0 | 42.0 | 0.0 | 6.0 | 2 | 4 | - | Candrink |
| Base.CannedBroccoli_Open | 0.8 | -45.0 | - | 55.0 | 10.0 | 0.5 | 4.5 | 2 | 4 | - | Candrink |
| Base.CannedCabbage_Open | 0.8 | -48.0 | - | 360.0 | 82.0 | 1.4 | 18.0 | 2 | 4 | - | Candrink |
| Base.CannedCarrots_Open | 0.8 | -40.0 | - | 125.0 | 30.0 | 0.75 | 3.0 | 2 | 4 | - | Candrink |
| Base.CannedCarrotsOpen | 0.8 | -12.0 | -4.0 | 10.5 | 28.0 | 0.0 | 0.0 | 2 | 4 | - | Candrink |
| Base.CannedCornOpen | 0.8 | -16.0 | -4.0 | 315.0 | 70.0 | 1.75 | 7.0 | 2 | 4 | - | Candrink |
| Base.CannedEggplant_Open | 0.8 | -48.0 | - | 342.0 | 81.0 | 2.4 | 13.5 | 2 | 4 | - | Candrink |
| Base.CannedLeek_Open | 0.8 | -48.0 | - | 216.0 | 560.0 | 1.2 | 15.2 | 2 | 4 | - | Candrink |
| Base.CannedPeasOpen | 0.8 | -16.0 | -3.0 | 280.0 | 52.5 | 0.0 | 14.0 | 2 | 4 | - | Candrink |
| Base.CannedPotato_Open | 0.8 | -48.0 | - | 210.0 | 45.0 | 0.45 | 9.0 | 2 | 4 | - | Candrink |
| Base.CannedPotatoOpen | 0.8 | -18.0 | -7.0 | 175.0 | 35.0 | 0.0 | 2.5 | 2 | 4 | - | Candrink |
| Base.CannedRedRadish_Open | 0.8 | -45.0 | - | 15.0 | 2.25 | 0.0 | 0.0 | 2 | 4 | - | Candrink |
| Base.CannedTomato_Open | 0.8 | -48.0 | - | 56.0 | 14.0 | 0.8 | 5.2 | 2 | 4 | - | Candrink |
| Base.CannedTomatoOpen | 0.8 | -12.0 | -8.0 | 90.0 | 18.0 | 0.0 | 3.0 | 2 | 4 | - | Candrink |
| Base.Carrots | 0.2 | -8.0 | -4.0 | 25.0 | 6.0 | 0.15 | 0.6 | 6 | 8 | - | - |
| Base.Cauliflower | 0.2 | -9.0 | -4.0 | 24.0 | 3.0 | 0.0 | 4.0 | 4 | 6 | - | - |
| Base.Corn | 0.2 | -14.0 | -4.0 | 88.0 | 26.74 | 1.93 | 4.68 | 5 | 8 | - | EatOffStick |
| Base.CornFrozen | 0.6 | -20.0 | -5.0 | 396.0 | 94.0 | 5.0 | 15.0 | 3 | 5 | - | EatBox |
| Base.CornSeed | 0.02 | -4.0 | - | 24.8 | 7.6 | 0.56 | 1.32 | - | - | true | - |
| Base.Cucumber | 0.3 | -10.0 | -10.0 | 33.0 | 6.1 | 0.63 | 2.37 | 6 | 14 | - | - |
| Base.Daikon | 0.2 | -12.0 | -5.0 | 54.0 | 12.59 | 0.27 | 1.34 | 5 | 8 | - | - |
| Base.DriedLentils | 2.0 | -60.0 | - | 3000.0 | 540.0 | 0.0 | 220.0 | - | - | true | - |
| Base.DriedSplitPeas | 2.0 | -60.0 | - | 2217.0 | 544.0 | 0.0 | 221.0 | - | - | true | - |
| Base.Edamame | 0.1 | -5.0 | - | 25.0 | 10.45 | 0.45 | 3.95 | 3 | 5 | - | - |
| Base.Eggplant | 0.2 | -16.0 | -9.0 | 114.0 | 27.0 | 0.8 | 4.5 | 5 | 8 | - | - |
| Base.FriedOnionRings | 0.1 | -10.0 | - | 200.0 | 22.0 | 12.0 | 2.0 | 4 | 7 | - | - |
| Base.FriedOnionRingsCraft | 0.1 | -10.0 | - | 200.0 | 22.0 | 12.0 | 2.0 | 4 | 7 | - | - |
| Base.GrapeLeaves | 0.1 | -4.0 | - | 73.0 | 11.0 | 2.0 | 4.0 | 6 | 10 | - | EatSmall |
| Base.Greenpeas | 0.2 | -4.0 | -1.0 | 70.0 | 13.125 | 0.0 | 3.5 | 3 | 5 | - | - |
| Base.GreenpeasSeed | 0.02 | -1.0 | - | 17.5 | 3.25 | 0.0 | 0.875 | - | - | true | - |
| Base.Leek | 0.2 | -12.0 | -5.0 | 54.0 | 140.0 | 0.3 | 1.3 | 5 | 8 | - | - |
| Base.MixedVegetables | 0.6 | -20.0 | -5.0 | 271.0 | 37.0 | 0.0 | 9.0 | 3 | 5 | - | EatBox |
| Base.Onion | 0.2 | -10.0 | - | 28.0 | 6.54 | 0.07 | 0.77 | 14 | 28 | - | - |
| Base.Peas | 0.6 | -20.0 | -5.0 | 119.0 | 20.45 | 0.85 | 7.95 | 3 | 5 | - | EatBox |
| Base.Potato | 0.2 | -18.0 | -7.0 | 70.0 | 15.0 | 0.15 | 3.0 | 28 | 280 | - | - |
| Base.RedRadish | 0.1 | -3.0 | -1.0 | 1.0 | 0.15 | 0.0 | 0.0 | 3 | 7 | - | - |
| Base.Spinach | 0.1 | -5.0 | - | 24.0 | 3.0 | 0.0 | 4.0 | 4 | 6 | - | - |
| Base.SugarBeet | 0.2 | -9.0 | -4.0 | 24.0 | 3.0 | 0.0 | 4.0 | 4 | 6 | - | - |
| Base.SweetPotato | 0.2 | -18.0 | -7.0 | 70.0 | 14.52 | 0.15 | 2.88 | 28 | 280 | - | - |
| Base.TinnedSoupOpen | 0.8 | -25.0 | -4.0 | 125.0 | 20.0 | 2.5 | 7.5 | 2 | 4 | - | Candrink |
| Base.Tofu | 0.3 | -10.0 | - | 30.0 | 1.0 | 1.0 | 5.0 | 6 | 14 | - | - |
| Base.TofuFried | 0.3 | -15.0 | - | 35.0 | 3.0 | 1.0 | 5.0 | 6 | 14 | - | - |
| Base.Tomato | 0.2 | -12.0 | -8.0 | 14.0 | 3.5 | 0.2 | 1.3 | 4 | 12 | - | - |
| Base.Turnip | 0.2 | -18.0 | -7.0 | 70.0 | 14.52 | 0.15 | 2.88 | 28 | 280 | - | - |
| Base.Zucchini | 0.3 | -10.0 | -10.0 | 33.0 | 6.1 | 0.63 | 2.37 | 6 | 14 | - | - |

## Venison（1 种）

| id | weight | hunger | thirst | calories | carbs | lipids | proteins | daysFresh | daysRotten | cantEat | eatType |
|----|--------|--------|--------|----------|-------|--------|----------|-----------|------------|---------|---------|
| Base.Venison | 0.5 | -80.0 | - | 440.0 | 0.0 | 18.7 | 62.62 | 2 | 4 | - | - |

