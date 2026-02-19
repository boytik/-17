# с17 — Roadmap: Доработки, Исправления, Новые Фичи

> **Цель:** превратить текущий прототип в полноценное приложение,  
> которое пройдёт Apple Review, будет реально полезным и user-friendly.

--


---

## 1. Критические баги и технические проблемы {#1-критические-баги}

### 1.1 Архитектурные

- [ ] **VIPER не полностью реализован.** Сейчас используется View + ViewModel (MVVM). Для полного VIPER нужно добавить:
  - `Router` для каждого модуля (навигация через протоколы, а не @State-флаги в View)
  - `Interactor` — бизнес-логика вынесена в отдельный слой (сейчас смешана с ViewModel)
  - `Presenter` — маппинг Entity → ViewModel (сейчас ViewModel делает всё)
  - Протоколы для каждого слоя (тестируемость, DI)
- [ ] **NestMemory — singleton с @Published.** ObservableObject-синглтон может вызывать проблемы с множественными подписчиками. Решение: разделить на отдельные сервисы (ProfileService, DayService, ProgressService) и использовать Combine publishers
- [ ] **Отсутствует обработка ошибок.** JSON decode/encode молча глотают ошибки через `try?`. Нужно: логирование, fallback-значения, UI-индикация ошибок
- [ ] **Thread safety.** NestMemory читает/пишет файлы на main thread. Нужно: DispatchQueue для I/O операций, `@MainActor` для UI-обновлений
- [ ] **Утечки памяти.** Проверить все `[weak self]` в Combine-подписках и замыканиях. Timer в CradleSplashView может утечь если View уничтожится раньше

### 1.2 Баги в логике

- [ ] **loadOrCreateToday()** вызывается для любой даты, а не только для сегодня — нужно разделить логику в `CradleDayBrain.loadDay(for:)`
- [ ] **duplicateToTomorrow()** не проверяет, существует ли уже план на завтра — затрёт данные без предупреждения
- [ ] **Badge evaluation** вызывается только при mark — не вызывается при первом запуске, при загрузке старого дня
- [ ] **Streak calculation** сломается при переходе через полночь, если пользователь отмечает блоки поздно ночью
- [ ] **completionFraction** считает только `.done` блоки — `.moved` не учитываются как прогресс (спорное поведение — обсудить)
- [ ] **Profile deletion** не чистит загруженный `todayCradle` если удалённый профиль был активным

### 1.3 UI баги

- [ ] **Wheel Picker** в AddBlockSheet — цвет текста может быть плохо виден на тёмном фоне в некоторых версиях iOS
- [ ] **Sheet presentationDetents** — `.medium` может обрезать контент на маленьких экранах (iPhone SE). Нужен `.height()` или адаптивная логика
- [ ] **Keyboard avoidance** — TextEditor в DayNoteSheet может перекрываться клавиатурой. Нужен ScrollViewReader + scrollTo
- [ ] **TabView page style** в онбординге — свайп может конфликтовать с внутренними ScrollView
- [ ] **Bottom padding** для tab bar — hardcoded 80pt может не совпадать с реальной высотой кастомного tab bar

---

---

## 3. UX / UI доработки {#3-ux-ui}

### 3.1 Навигация и Flow

- [ ] **Haptic feedback.** Добавить `UIImpactFeedbackGenerator` при: quick mark done, block move, badge unlock, level up, tab switch
- [ ] **Pull-to-refresh** на Day timeline — обновить текущий день
- [ ] **Swipe actions на карточках блоков.** Swipe right → Done, Swipe left → Skip/Move (стандартный iOS паттерн)
- [ ] **Long press context menu** на блоках: Move +15min, Move +30min, Edit, Delete (из ТЗ)
- [ ] **Undo last action.** Snackbar-уведомление "Block marked done — Undo" с таймером 5 сек (из ТЗ)
- [ ] **Transition animations** между табами — сейчас opacity, добавить asymmetric transitions
- [ ] **Scroll to current time block** автоматически при открытии Day tab
- [ ] **"Today" button** — если пользователь ушёл на другую дату, кнопка быстрого возврата к сегодня

### 3.2 Visual Polish

- [ ] **Time indicator line** на таймлайне — горизонтальная золотая линия "сейчас" с текущим временем
- [ ] **Block duration visual** — высота карточки пропорциональна длительности (или полоска-индикатор)
- [ ] **Animated transitions** при mark done — конфетти или stardust particles (опционально, Reduced Motion safe)
- [ ] **Empty states** для всех экранов: Growth Garden без данных, Settings без профилей — добавить иллюстрации или анимации
- [ ] **Skeleton loading** вместо пустого экрана при загрузке данных
- [ ] **Gold shimmer** на Level Up — анимация когда пользователь переходит на новый уровень

### 3.3 Формы и Ввод

- [ ] **Date picker** для навигации по датам — вместо только стрелок, добавить calendar picker (tap на дату)
- [ ] **Time picker в Add Block** — заменить wheel picker на более compact вариант или использовать DatePicker с `.hourAndMinute`
- [ ] **Validation feedback** — если блоки перекрываются по времени, показать предупреждение
- [ ] **Quick templates в Add Block** — "Quick add: Nap 30min, Meal 30min, Walk 60min" одной кнопкой

---

## 4. Недостающие фичи из ТЗ {#4-недостающие-фичи}

### 4.1 Из ТЗ — не реализовано

- [ ] **Drag & Drop перенос блоков.** Ключевая фича из ТЗ! "Один тап — перенёс блок". Нужно:
  - `.draggable()` / `.dropDestination()` для iOS 16+
  - Или `onDrag`/`onDrop` с custom DragGesture
  - Визуальный "подъём" блока при перетаскивании (shadow + scale)
  - Перестройка соседних блоков при drop
- [ ] **Локальные уведомления (Notifications).** Из ТЗ — мягкие напоминания. Реализовать:
  - `UNUserNotificationCenter` — запрос разрешения
  - Планирование уведомлений за N минут до блока
  - Action buttons в уведомлении: "Done" / "Move +15min" / "Skip"
  - Учёт Quiet Hours — подавление уведомлений в тихое время
  - Пересчёт уведомлений при изменении/перемещении блока
- [ ] **Шаблоны — полный раздел.** В ТЗ описан отдельный таб "Шаблоны". У нас шаблоны только в онбординге. Нужно:
  - Просмотр и применение встроенных шаблонов по возрасту
  - Создание custom шаблонов из текущего дня
  - Редактор шаблона
  - "Применить шаблон" к любой дате
- [ ] **Несколько стилей шаблонов** per age group (Calm / Active / Structured) — сейчас только Calm генерируется по умолчанию, нужны реальные вариации
- [ ] **Мульти-профиль UX** — быстрое переключение профиля из Day tab (не только из Settings). Dropdown или segmented control в header
- [ ] **"Тихий режим" с реальной логикой** — сейчас только флаг, нужно: при включении подавлять запланированные уведомления, показывать индикатор на экране

### 4.2 Из ТЗ — частично реализовано

- [ ] **Сводка дня** — есть в Growth Garden, но нет отдельного экрана "Day Summary" с 2-3 инсайтами по итогу дня
- [ ] **Причина переноса** — в ТЗ: при переносе блока можно выбрать причину (быстрый выбор). Сейчас только mark as "Moved" без причины
- [ ] **Duplicate Day** — есть, но нет проверки конфликтов и UI-подтверждения
- [ ] **Export данных** — в ТЗ указано "не делаем", но Share Summary уже есть. Расширить: экспорт в PDF или CSV за период

---

## 5. Новые фичи для полезности {#5-новые-фичи}

### 5.1 Обязательные для полезности

- [ ] **Recurring blocks** — ежедневно повторяющиеся блоки которые не нужно создавать каждый день
- [ ] **Conflict detection** — предупреждение если блоки перекрываются по времени

### 5.2 Nice-to-have


- [ ] **Charts framework (Swift Charts)** — для iOS 16+ заменить кастомные графики на нативные Swift Charts (красивее, accessibility бесплатно)
- [ ] **Focus Filters** — показывать/скрывать контент в зависимости от Focus Mode



---

## 6. Геймификация — расширение {#6-геймификация}

### 6.1 Улучшения текущей системы

- [ ] **Level Up celebration screen** — полноэкранная анимация при переходе на новый уровень (конфетти + новый emoji + поздравление)
- [ ] **Badge unlock notification** — in-app toast/banner когда разблокирован новый бейдж
- [ ] **XP animation** — "+15 ✦" вылетает из карточки блока при mark done и летит к счётчику в header
- [ ] **Daily bonus** — первое действие каждый день даёт бонусные XP (+10 "good morning bonus")
- [ ] **Combo system** — отметить 3 блока подряд без пропуска → множитель XP (x1.5)

### 6.2 Новые элементы

- [ ] **Weekly challenge** — "Complete 5 walks this week" → bonus badge + XP
- [ ] **Milestone rewards** — 10 дней подряд, 50 блоков, 1000 XP → special badges
- [ ] **Parent mood tracker** — как себя чувствует родитель (спокойно/устал/стресс) → корреляция с расписанием
- [ ] **"Golden Hour" bonus** — выполнение блока ровно по расписанию (±5 мин) даёт +50% XP
- [ ] **Seasonal badges** — специальные бейджи по сезонам/праздникам

---

## 7. Accessibility {#7-accessibility}

### 7.1 Обязательные

- [ ] **VoiceOver labels** для всех интерактивных элементов. Сейчас: SF Symbols читаются, но кастомные элементы (donut chart, progress rings, emoji buttons) нуждаются в `.accessibilityLabel()` и `.accessibilityHint()`
- [ ] **Reduced Motion** — проверить все анимации. При `UIAccessibility.isReduceMotionEnabled`:
  - Отключить floating particles в StarryNestBackground
  - Заменить spring-анимации на dissolve
  - Упростить splash sequence
  - Отключить shimmer эффект
- [ ] **Increase Contrast** — при включённом Increase Contrast увеличить opacity золотых акцентов, утолщить borders
- [ ] **Color Blind safe** — не полагаться только на цвет для статусов. Добавить иконки/текст вместе с цветом (частично уже есть)
- [ ] **Minimum touch target** — проверить все кнопки ≥ 44x44pt (в emoji picker кнопки 40x40 — нужно увеличить)

---

## 8. Производительность и стабильность {#8-производительность}

### 8.1 Оптимизация

- [ ] **Lazy loading** — загружать дневные данные только при необходимости (сейчас loadRecentCradles грузит до 365 дней для badge check)
- [ ] **File I/O on background queue** — все read/write операции вынести с main thread:
  ```swift
  DispatchQueue.global(qos: .userInitiated).async { 
      // read/write 
      DispatchQueue.main.async { /* update UI */ }
  }
  ```
- [ ] **Debounce** для частых операций (перетаскивание блоков, ввод текста)
- [ ] **Image caching** — если добавим фото к блокам
- [ ] **Memory profiling** — проверить утечки в Instruments (Leaks, Allocations)




