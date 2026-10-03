# CardFight: промпти фінального арту

Генератори: Midjourney v6 / Leonardo / SDXL. Палітра: фон #14161f, кістка #e8e2d0, червоний #a8322d, синій #3b5a8a, золото #c9a24b.

## 1. Загальний стиль

Суфікс (додавати в кінець КОЖНОГО промпту):

```
dark fantasy, hand-painted digital illustration, gritty storybook style, limited muted palette of deep navy-black #14161f, bone white #e8e2d0, blood red #a8322d, steel blue #3b5a8a, antique gold #c9a24b, soft rim light, strong readable silhouette, consistent style, high detail, no text, no watermark
```

Негативний промпт (SDXL/Leonardo; у Midjourney додати як `--no ...`):

```
text, letters, watermark, signature, logo, UI, frame, border, photo, realistic photo, 3d render, anime, cartoon, neon colors, oversaturated, blurry, low quality, extra limbs, deformed hands, cropped, multiple characters
```

Midjourney: `--style raw --v 6`. Для спрайтів додавати "isolated on plain flat white background" (потім прибрати фон).

## 2. Список ассетів

### Фони (1080x1920, `--ar 9:16`): центр і низ спокійні, темні, без деталей під UI

- `bg_menu` `--ar 9:16`
  `ruined gothic castle silhouette on a cliff under a huge pale moon, drifting fog, tiny distant torch lights, vertical composition, top third dramatic sky, center and bottom calm dark misty ground, empty negative space for menu buttons`
- `bg_map` `--ar 9:16`
  `old weathered parchment map table seen from above, faded ink roads and dark forest edges, worn leather corners, candle glow at the edges, center large empty calm area, dark vignette`
- `bg_combat` `--ar 9:16`
  `dark crypt battle arena, cracked stone floor, broken pillars and bones along the sides, cold blue mist, faint red glow from the far back wall, enemy area upper half, bottom 40 percent plain dark flat stone floor, calm uncluttered center`
- `bg_merchant` `--ar 9:16`
  `hooded wanderer merchant camp in a dark cave, wooden stall with hanging lanterns and trinkets at the top, warm gold lantern light, deep shadows, center and bottom calm dark ground, no characters`
- `bg_rest` `--ar 9:16`
  `lonely campfire in a dark ruined forest clearing, warm gold and orange glow, fireflies, standing stones, night blue shadows, fire in the upper-middle, bottom third calm dark grass, no characters`
- `bg_sanctuary` `--ar 9:16`
  `hidden stone sanctuary hall, tall arches, glowing blue crystals and runes, soft steel-blue light shafts from above, sacred and quiet mood, dark symmetrical composition, calm center and bottom, no characters`

### Персонажі (прозорий фон, `--ar 1:1`): дивляться ВПРАВО, повний зріст, 3/4 вид

- `player_knight` `--ar 1:1`
  `armored knight facing right, battered steel plate armor with bone white tabard and red cloth accents, sword raised in a ready stance, dented great helm, full body, heroic but weary`
- `player_mage` `--ar 1:1`
  `young battle mage facing right, deep blue hooded robe with gold trim, glowing steel-blue staff, arcane runes floating around one hand, full body, mysterious`

`player_mage_locked` НЕ генерувати (силует робить гра).

### Вороги (прозорий фон, `--ar 1:1`): дивляться ВЛІВО, повний зріст

- `enemy_skeleton_warrior` `--ar 1:1`
  `skeleton warrior facing left, rusted sword and cracked round shield, tattered red cloth, glowing red eye sockets, bone white, full body`
- `enemy_skeleton_archer` `--ar 1:1`
  `skeleton archer facing left, drawing a bone longbow, ragged hood, quiver of black arrows, glowing pale blue eye sockets, full body`
- `enemy_ghoul` `--ar 1:1`
  `hunched ghoul facing left, gaunt gray-green skin, long clawed arms, torn rags, hungry feral grin, crouching, full body`
- `enemy_wraith` `--ar 1:1`
  `floating wraith facing left, tattered ghostly shroud fading into mist, hollow glowing steel-blue eyes, skeletal reaching hand, translucent, full body`
- `enemy_dark_cultist` `--ar 1:1`
  `dark cultist facing left, black hooded robe with blood red sigils, ritual dagger and a dripping red-lit chalice, face hidden in shadow, full body`
- `enemy_bone_minion` `--ar 1:1`
  `small animated pile of bones shaped like a tiny imp facing left, skull head too big for the body, glowing red eyes, cute but creepy, full body, smaller and simpler than other enemies`
- `enemy_bone_golem` (еліта) `--ar 1:1`
  `massive bone golem facing left, hulking body assembled from hundreds of skulls and femurs, huge fists, red glow in the chest cavity, gold-rusted iron bands, imposing elite monster, full body`
- `enemy_lich_lord` (бос, епічніший) `--ar 1:1`
  `epic lich lord boss facing left, towering skeletal sorcerer in ornate black and gold robes, spiked crown, glowing blood red eyes, staff topped with a skull and swirling red-blue necrotic energy, dramatic rim light, floating shards, full body, most detailed and imposing character`

### Рамки карт (`--ar 12:17`): центр-вікно порожнє під текст і ілюстрацію

Додати до всіх трьох: `ornate card frame only, flat front view, perfectly symmetrical, large empty dark center window #14161f, no characters, no text, isolated on plain white background`

- `card_frame_attack` `--ar 12:17`
  `dark metal card frame with blood red #a8322d gems and jagged blade-like corner ornaments, worn steel edges`
- `card_frame_skill` `--ar 12:17`
  `dark metal card frame with steel blue #3b5a8a inlays, shield and rune corner ornaments, worn steel edges`
- `card_frame_power` `--ar 12:17`
  `dark metal card frame with antique gold #c9a24b filigree, radiant star and crown corner ornaments, worn gold edges`

### Лого

- `logo` `--ar 3:1`
  `fantasy game logo lettering reading "CardFight", carved bone white letters with worn gold edges, crossed sword and playing card emblem, blood red accent, dark metal texture, centered, isolated on plain flat dark background`
  (Якщо генератор псує літери: згенерувати без тексту і дописати "CardFight" у Canva/Photoshop.)

Разом 20 файлів: 6 фонів, 2 персонажі, 8 ворогів, 3 рамки, 1 лого.

## 3. Інструкція для замовника

1. Для кожного файлу: промпт + суфікс зі секції 1, потім негативний промпт. Генеруйте 4-8 варіантів, беріть найближчий до решти за стилем.
2. Для персонажів, ворогів, рамок: прибрати фон (функція "remove background" генератора, remove.bg або Canva). Рамки: також видалити центр-вікно (зробити прозорим).
3. Перевірте напрям: гравець дивиться вправо, вороги вліво (інакше віддзеркаліть).
4. Розміри: фони 1080x1920, персонажі/вороги 512x512, рамки 480x680, лого 900x300.
5. Формат PNG (з альфа-каналом для всього, крім фонів). Ім'я = ім'я плейсхолдера, але `.png` (наприклад `enemy_ghoul.png`).
6. Складіть у `assets/art/final/`.
7. Для єдиного стилю: у Midjourney використовуйте `--sref` з першого вдалого результату, у Leonardo/SDXL фіксуйте модель і seed-стиль.
