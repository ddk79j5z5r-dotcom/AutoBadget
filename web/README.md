# AutoBudget Web

Веб-версия AutoBudget: те же функции и дизайн, что в iOS-приложении.
React 19 · TypeScript · Vite · Tailwind CSS 4 · Recharts · Dexie (IndexedDB) · React Router.

## Запуск

```bash
npm install
npm run dev
```

Откройте http://localhost:5173. При первом запуске загружаются демо-данные Toyota Aristo JZS160.

Онлайн-версия: https://ddk79j5z5r-dotcom.github.io/AutoBadget/ — обновляется автоматически
при каждом push в `main` (GitHub Actions, `.github/workflows/deploy-web.yml`).

Сборка для публикации (статические файлы в `dist/`, подходит любой хостинг статики):

```bash
npm run build
```

## Где хранятся данные

В IndexedDB браузера — на сервер ничего не отправляется. Данные живут только в этом браузере,
поэтому в «Гараж» → ⋯ есть экспорт и импорт резервной копии (JSON, вместе с фото).
Синхронизации с iOS-приложением нет.

## Уведомления

Через Notification API браузера. Без сервера и push-подписки браузер показывает уведомления,
только пока сайт открыт:

- по пробегу — сразу, когда остаток ресурса пересекает 5 000 / 1 000 / 0 км;
- по времени и ресурсу деталей — при открытии сайта, за N дней до срока (каждое событие один раз).

## Структура — те же слои, что в iOS

```
src/
├── models/        типы сущностей и категорий; serviceTracking — общая логика ресурса; partTemplates
├── services/      db (Dexie), analytics, maintenance, dataService, notifications,
│                  demoData, backup, formatters, images
├── viewmodels/    хуки-ViewModel экранов, живые запросы к IndexedDB, периоды статистики
├── components/    AppShell (нижняя панель / боковое меню), Sheet, ui, rows, charts, controls, icons
├── sheets/        формы: расход, ремонт, деталь, напоминание, автомобиль
└── pages/         Главная, Расходы, Заправки, Статистика, Гараж, Ремонты, Timeline, Детали, Напоминания
```

На телефоне — нижняя панель с «+» по центру и формы в виде bottom sheet, как в iOS;
на широком экране — боковое меню, двухколоночные экраны и формы в диалоговых окнах.
