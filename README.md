# Рейтинг компаний по кибербезопасности блокчейна

Статический сайт на HTML и CSS: главная с рейтингом 10 компаний, методология, страница редакции, форма добавления компании, 6 E-E-A-T страниц и 4 статьи. Домен: https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com

## Структура

```
components/        header.html, footer.html, avatar-sm.html, avatar-lg.html, icons/*.svg (Lucide)
content/{slug}.html  содержимое <main> каждой страницы
content/_*.html      фрагменты, сгенерированные из data/ratings.json (не редактировать вручную)
meta/{slug}.json     title, description, robots, путь, глубина, хлебная крошка
meta/{slug}.schema.json  JSON-LD страницы (Organization и WebSite добавляет build.sh)
data/ratings.json    баллы компаний по 7 критериям, тексты карточек, источник каждого балла
css/global.css       токены DESIGN.md и все компоненты
fonts/               Manrope, Inter, JetBrains Mono (woff2, кириллица + латиница, SIL OFL)
images/              logo.svg, og-image.png, companies/*.webp (скриншоты 1200x622)
js/ui.js             подсветка навигатора и закрытие меню (необязательный)
tools/               render-ratings.ps1, serve.ps1, shot.sh, служебные HTML для фавиконов и webp
{slug}/index.html    готовые страницы (результат сборки, не редактировать)
```

## Сборка

1. Если менялись баллы или тексты карточек в `data/ratings.json`:
   ```
   powershell -ExecutionPolicy Bypass -File tools/render-ratings.ps1
   ```
   Скрипт проверяет, что сумма баллов совпадает с итогом, и перегенерирует таблицу, карточки, мини-карточки статей и ItemList.
2. Собрать страницы и sitemap.xml (дата публикации и lastmod задаются в build.sh, переменная SITE_DATE):
   ```
   bash build.sh
   ```

В контенте доступны токены: `{{ROOT}}` (относительный путь к корню), `{{icon:name}}` (inline SVG из `components/icons/`), `{{include:content/_file.html}}` (на отдельной строке), `<!--AVATAR_SM-->` и `<!--AVATAR_LG-->` (на отдельной строке).

## Предпросмотр

```
powershell -ExecutionPolicy Bypass -File tools/serve.ps1
```
Сайт откроется на http://localhost:3000. Все пути относительные, поэтому сайт работает и при открытии `index.html` из папки.

## Открыть сайт к индексации

Сейчас на всех страницах стоит `noindex, nofollow`. Чтобы открыть индексацию:

1. Во всех `meta/*.json` замените `"robots": "noindex, nofollow"` на `"robots": "index, follow"`:
   ```
   sed -i 's/"robots": "noindex, nofollow"/"robots": "index, follow"/' meta/*.json
   ```
2. Пересоберите сайт: `bash build.sh`.

`robots.txt` уже разрешает обход и указывает sitemap: запрет через `Disallow` не используется, иначе поисковики не увидят noindex.

## Формы

Формы на страницах "Добавить компанию" и "Контакты" отправляются на `action="#"`: обработчик нужно подключить (в коде стоит комментарий "подключить обработчик"). Пока обработчика нет, на страницах указаны адреса почты.

## GitHub Pages

Файл `.nojekyll` в корне обязателен. Для своего домена добавьте файл `CNAME` с доменом.
