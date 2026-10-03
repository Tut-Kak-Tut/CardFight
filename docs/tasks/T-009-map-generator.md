# T-009 Генератор мапи підземелля
Залежить від: — (лише `data/balance.json` → `map`)
Модель: sonnet

## Мета
Чиста функція, що за seed будує мапу з 10 шарів з розгалуженнями за правилами GDD 4.5.

## Файли
Створити: `scripts/core/map/map_generator.gd`, `tests/test_map_generator.gd`

## Формат результату
```
{"nodes": [{"id": int, "layer": int (0-based), "index": int (позиція в шарі 0..n-1),
            "type": "battle"|"elite"|"merchant"|"rest"|"boss", "next": [id, ...]}],
 "layers": [[id, ...], ...]}      # layers[i] — id вузлів шару i, зліва направо
```
`nodes[id].id == id` (id = індекс у масиві).

## Конфіг (`balance.map`)
`layers 10, min_nodes 2, max_nodes 3, first_layer_nodes 2, weights {battle 50, rest 18, merchant 15, elite 12}, elite_layers [4,9], elite_count [1,2], merchant_min 2, merchant_required_layer 8, rest_layers [3,9], rest_count [3,4], rest_required_layer 9`. Номери шарів у конфігу — 1-based (шар 1 = layer 0).

## Кроки
- [x] 1. `class_name MapGenerator extends RefCounted`, `static func generate(cfg: Dictionary, rng: RandomNumberGenerator) -> Dictionary`.
- [x] 2. Структура: шар 1 — `first_layer_nodes` вузлів; шари 2..(layers-1) — випадково `min_nodes..max_nodes`; останній шар — 1 вузол `boss`.
- [x] 3. Зв'язки між сусідніми шарами (без перетинів ліній): зіставляй вузли за відносною позицією `index/(n-1)`. Кожен вузол шару i з'єднай з найближчим за позицією вузлом шару i+1; потім з ймовірністю 0.4 додай ребро до сусіднього (index±1) вузла наступного шару, якщо не створює перетину (перетин: ребра a→b і c→d з a<c і b>d). Гарантуй: кожен вузол шару i+1 має хоча б одне вхідне ребро (якщо ні — з'єднай з найближчим вузлом шару i). Усі вузли передостаннього шару → boss.
- [x] 4. Типи: шар 1 — усі `battle`. Решту (шари 2..layers-1) призначай випадково за `weights` з урахуванням дозволених шарів (elite лише в `elite_layers`, rest лише в `rest_layers`; шари 2-3 без elite), потім перевір правила:
  - elite: кількість у `elite_count`;
  - merchant: >= `merchant_min`, у шарі `merchant_required_layer` хоча б один;
  - rest: кількість у `rest_count`, у шарі `rest_required_layer` хоча б один;
  - немає ребра між двома вузлами з типами з {rest, merchant} (два «мирних» вузли підряд на шляху);
  - вузли з однаковим `next`-набором в одному шарі можуть мати різні типи — це ок.
  Якщо правила не виконані — повтор призначення типів (до 500 спроб; якщо не вийшло — перебудувати структуру; максимум 50 перебудов, далі `push_error` і повернути останню).
- [x] 5. `static func validate(map: Dictionary, cfg: Dictionary) -> Array[String]` — перевіряє всі правила з кроку 4 + структуру (кожен не-boss вузол має next, кожен вузол крім шару 1 має вхідне ребро, ребра лише на наступний шар, немає перетинів). Використовується в тестах.
- [x] 6. `tests/test_map_generator.gd`: cfg читати з `data/balance.json` (через `JSON.parse_string(FileAccess.get_file_as_string(...))`, числа float → приводити до int там, де потрібно, або в генераторі використовуй `int()`):
  - `test_500_seeds_valid`: 500 seed'ів → `validate` порожній для всіх (у msg — перший seed з помилкою);
  - `test_deterministic`: однаковий seed → однакова мапа;
  - `test_shape`: 10 шарів, шар 0 — 2 battle, останній — 1 boss;
  - `test_distribution`: на 500 мапах частка battle у шарах 2-9 між 40% і 60%.

## Готово, коли
Тести зелені; 500 мап генеруються < 3 с.

## Як перевірити
`"$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd` (`$GODOT` — docs/plan.md)
