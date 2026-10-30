# Фитнес-клуб (fitness_web)

Flutter Web + PocketBase: расписание, записи, абонементы, роли member / trainer / admin.

**Репозиторий:** https://github.com/Veronikaaaa00/fitness_web  

**Сайт (GitHub Pages):** https://veronikaaaa00.github.io/fitness_web/

## Быстрый старт (локально)

### 1. PocketBase

Бинарник: скачайте [PocketBase](https://pocketbase.io/docs/) в `pocketbase/` (v0.40+). Миграции в `pocketbase/pb_migrations/`.

```powershell
cd pocketbase
.\pocketbase.exe serve --http=127.0.0.1:8090
```

Админка: http://127.0.0.1:8090/_/  
Superuser: `admin@gmail.com` / `admin123`

### 2. Flutter

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8090
```

Сборка под GitHub Pages:

```powershell
flutter build web --release --base-href "/fitness_web/" --dart-define=API_BASE_URL=https://YOUR-PB-HOST
```

## Деплой PocketBase (Render)

В репозитории есть `Dockerfile` и `render.yaml`.

1. https://dashboard.render.com/select-repo?type=blueprint  
2. Подключите `Veronikaaaa00/fitness_web`  
3. Задеплойте сервис `fitness-pocketbase` (free)  
4. URL вида `https://fitness-pocketbase.onrender.com` пропишите в сборку Flutter / GitHub variable `API_BASE_URL`

**Важно про сохранение данных:** на Render Free диск эфемерный — после сна/рестарта всё сбрасывается. В `render.yaml` стоит **Starter + persistent disk** (`/pb/pb_data`), чтобы записи, абонементы и правки по ролям переживали перезапуск. После смены плана в Dashboard сделай Manual Deploy.

## Тестовые аккаунты

| Роль    | Email               | Пароль     | Кто это              |
|---------|---------------------|------------|----------------------|
| admin   | admin@gmail.com     | admin123   | администратор        |
| trainer | trainer@gmail.com   | trainer123 | тренер               |
| member  | member@gmail.com    | member123  | клиент клуба         |

## Структура

- `lib/core` — конфиг, Dio/PB-клиент, права, тема
- `lib/models` — сущности
- `lib/repositories` — доступ к коллекциям PB
- `lib/screens` — экраны по ролям
- `lib/state` — auth, сеть, load status
- `pocketbase/pb_migrations` — схема + сиды
