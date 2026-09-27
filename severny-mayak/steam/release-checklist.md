# Выпуск в Steam — чек-лист

## 1. Аккаунт и приложение
- [ ] Steamworks: зарегистрироваться как разработчик (Steam Direct, $100 за игру, возвращаются после $1000 выручки).
- [ ] Получить **App ID** и записать его в `steam_appid.txt` вместо `480`. 480 — тестовый Spacewar от Valve, на нём можно проверять достижения.
- [ ] Заполнить налоговую и банковскую информацию (проверка идёт несколько дней).

## 2. Страница магазина (открыть как можно раньше, чтобы копить вишлисты)
- [ ] Тексты — в `store-page.md` (RU + EN).
- [ ] Капсулы: header 920×430, small 462×174, main 1232×706, vertical 748×896, library 600×900, library hero 3840×1240, logo.
- [ ] 5+ скриншотов 1920×1080. Лучшие моменты: яркий стол, прятки «МАМА В КОМНАТЕ», диспетчер задач с pix_guard, красная 3-я стадия, выбор в «Шёпоте».
- [ ] Трейлер 30–60 с: начать мило, закончить «Лёва ушёл к башне, потому что я его позвал».
- [ ] Предупреждение о контенте в Steam: тема пропавшего ребёнка, мерцание.
- [ ] Системные требования: Windows 10+, 4 ГБ ОЗУ, любая видеокарта. Proton/Steam Deck — проверить (Electron работает).

## 3. Достижения
- [ ] Завести в Steamworks → Stats & Achievements достижения с API-именами из `achievements.md` (регистр важен).
- [ ] Иконки 256×256 (открытое и закрытое состояние) для каждого.

## 4. Сборка и Steamworks в Godot
- [ ] Поставить **GodotSteam** (GDExtension) в проект: Godot → AssetLib → «GodotSteam GDExtension» → Install.
      Код игры уже готов: `scripts/game.gd` сам находит синглтон `Steam`, вызывает `steamInitEx()` и выдаёт достижения.
      Без GodotSteam игра просто работает без Steam.
- [ ] Положить `steam_appid.txt` с App ID рядом с `.exe` для локальной проверки (из Steam он не нужен).
- [ ] Сборка:
```bash
cd godot
godot --headless --export-release "Windows Desktop" ../dist/windows/SevernyMayak.exe
godot --headless --export-release "Linux" ../dist/linux/SevernyMayak.x86_64
```
- [ ] Иконка .exe: сделать `icon.ico` (256×256) и указать в Project → Export → Windows → Application → Icon
      (понадобится rcedit: Editor Settings → Export → Windows → rcedit).
- [ ] Проверить, что при запуске из Steam работает оверлей (Shift+Tab) и выдаются достижения.

## 5. Загрузка билда
- [ ] Steamworks SDK → `tools/ContentBuilder`: депо для Windows (и Linux при желании), путь к `dist/windows`.
- [ ] Launch options: `SevernyMayak.exe` (Windows), `SevernyMayak.x86_64` (Linux).
- [ ] Steam Cloud (Auto-Cloud): Windows — `%APPDATA%/SevernyMayak/*.json`, Linux — `~/.local/share/SevernyMayak/*.json`.

## 6. Перед релизом
- [ ] Автотест зелёный на обоих языках: `godot --headless -- --test --lang=ru` и `--lang=en`.
- [ ] Пройти руками: минимум один раз каждый финал, прятки, проигрыш «Шнур выдернут», второй круг.
- [ ] Проверить щадящие эффекты и выключенные скримеры.
- [ ] Демо для Steam Next Fest: часть 1 целиком, в конце — заставка «Продолжение в полной версии».
- [ ] Отправить на проверку Valve (2–5 рабочих дней), потом «Coming Soon» не меньше двух недель.

## Маркетинг
- Хоррор-стримеры: короткая игра на один стрим с твистом и несколькими финалами — идеальный формат.
- Референсы на странице: Simulacra, Sara is Missing, KinitoPET, Doki Doki Literature Club, Her Story.
- Второй круг с уликами — хороший повод для роликов «вы не заметили это в первый раз».
