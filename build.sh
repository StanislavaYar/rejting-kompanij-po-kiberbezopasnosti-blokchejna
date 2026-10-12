#!/usr/bin/env bash
# Сборка статического сайта: components/ + content/{slug}.html + meta/{slug}.json -> {path}index.html
# Запуск из корня проекта: bash build.sh
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN="https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com"
SITE_NAME="Редакция рейтинга кибербезопасности блокчейна"
# Дата публикации и lastmod в sitemap.xml (можно переопределить: SITE_DATE=2026-11-01 bash build.sh)
BUILD_DATE="${SITE_DATE:-2026-10-20}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Значение строкового или числового поля из плоского meta/*.json (одно поле на строку)
get() {
  sed -n "s/^[[:space:]]*\"$1\":[[:space:]]*//p" "$2" | head -n 1 | sed -e 's/,[[:space:]]*$//' -e 's/^"//' -e 's/"$//'
}

# {{include:content/_file.html}} на отдельной строке -> содержимое файла;
# {{icon:name}} в любом месте строки -> inline SVG из components/icons/name.svg
expand() {
  awk '
    function slurp(path,   line, out) {
      out = ""
      while ((getline line < path) > 0) out = out (out == "" ? "" : "\n") line
      close(path)
      return out
    }
    {
      if (match($0, /\{\{include:[^}]+\}\}/)) {
        print slurp(substr($0, RSTART + 10, RLENGTH - 12))
        next
      }
      print
    }' "$1" | awk '
    function slurp(path,   line, out) {
      out = ""
      while ((getline line < path) > 0) out = out line
      close(path)
      return out
    }
    {
      while (match($0, /\{\{icon:[a-z0-9-]+\}\}/)) {
        name = substr($0, RSTART + 7, RLENGTH - 9)
        svg = slurp("components/icons/" name ".svg")
        if (svg == "") { print "Missing icon: " name > "/dev/stderr"; exit 1 }
        $0 = substr($0, 1, RSTART - 1) svg substr($0, RSTART + RLENGTH)
      }
      print
    }'
}

# Подстановка {{ROOT}}, аватаров и активного пункта меню
render() {
  local src="$1" root="$2" nav="$3"
  expand "$src" | sed \
    -e "s#{{ROOT}}#${root}#g" \
    -e "s#{{DOMAIN}}#${DOMAIN}#g" \
    -e "s#data-nav=\"${nav}\"#data-nav=\"${nav}\" aria-current=\"page\"#g" \
    -e '/<!--AVATAR_SM-->/{r components/avatar-sm.html' -e 'd}' \
    -e '/<!--AVATAR_LG-->/{r components/avatar-lg.html' -e 'd}'
}

ORG_JSONLD=$(cat <<'JSONLD'
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/#organization",
      "name": "Редакция рейтинга кибербезопасности блокчейна",
      "url": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/",
      "logo": {
        "@type": "ImageObject",
        "url": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/icon-512.png",
        "width": 512,
        "height": 512
      },
      "email": "editor@rejting-kompanij-po-kiberbezopasnosti-blokchejna.com"
    },
    {
      "@type": "WebSite",
      "@id": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/#website",
      "name": "Рейтинг компаний по кибербезопасности блокчейна",
      "url": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/",
      "inLanguage": "ru",
      "publisher": { "@id": "https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com/#organization" }
    }
  ]
}
JSONLD
)

# Минификация CSS: исходник css/global.css, на страницах подключается css/global.min.css
perl tools/minify-css.pl css/global.css > css/global.min.css

SITEMAP="$TMP_DIR/sitemap.xml"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
} > "$SITEMAP"

count=0
for META in meta/*.json; do
  case "$META" in *.schema*.json) continue ;; esac
  SLUG="$(get slug "$META")"
  PATH_URL="$(get path "$META")"          # "" для главной, "metodologiya/" для внутренних
  DEPTH="$(get depth "$META")"
  NAV="$(get nav "$META")"
  TITLE="$(get title "$META")"
  DESC="$(get description "$META")"
  ROBOTS="$(get robots "$META")"
  OG_TYPE="$(get og_type "$META")"
  CRUMB="$(get breadcrumb "$META")"
  SCHEMA="meta/${SLUG}.schema.json"
  CONTENT="content/${SLUG}.html"
  if [ ! -f "$CONTENT" ]; then echo "skip ${SLUG}: нет ${CONTENT}" >&2; continue; fi

  if [ "$DEPTH" = "0" ]; then ROOT="./"; else ROOT="$(printf '../%.0s' $(seq 1 "$DEPTH"))"; fi
  CANONICAL="${DOMAIN}/${PATH_URL}"
  OUT_DIR="./${PATH_URL}"
  mkdir -p "$OUT_DIR"
  OUT="${OUT_DIR}index.html"

  render components/header.html "$ROOT" "$NAV" > "$TMP_DIR/header.html"
  render components/footer.html "$ROOT" "$NAV" > "$TMP_DIR/footer.html"
  render "$CONTENT" "$ROOT" "$NAV" > "$TMP_DIR/content.html"

  {
    echo '<!doctype html>'
    echo '<html lang="ru">'
    echo '<head>'
    echo '<meta charset="utf-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo "<title>${TITLE}</title>"
    echo "<meta name=\"description\" content=\"${DESC}\">"
    echo "<meta name=\"robots\" content=\"${ROBOTS}\">"
    echo "<link rel=\"canonical\" href=\"${CANONICAL}\">"
    echo "<meta property=\"og:type\" content=\"${OG_TYPE}\">"
    echo "<meta property=\"og:locale\" content=\"ru_RU\">"
    echo "<meta property=\"og:site_name\" content=\"Рейтинг компаний по кибербезопасности блокчейна\">"
    echo "<meta property=\"og:title\" content=\"${TITLE}\">"
    echo "<meta property=\"og:description\" content=\"${DESC}\">"
    echo "<meta property=\"og:url\" content=\"${CANONICAL}\">"
    echo "<meta property=\"og:image\" content=\"${DOMAIN}/images/og-image.png\">"
    echo '<meta property="og:image:width" content="1200">'
    echo '<meta property="og:image:height" content="630">'
    echo '<meta name="theme-color" content="#1F3A5F">'
    echo "<link rel=\"icon\" href=\"${ROOT}favicon.ico\" sizes=\"32x32\">"
    echo "<link rel=\"icon\" href=\"${ROOT}favicon.svg\" type=\"image/svg+xml\">"
    echo "<link rel=\"apple-touch-icon\" href=\"${ROOT}apple-touch-icon.png\">"
    echo "<link rel=\"manifest\" href=\"${ROOT}site.webmanifest\">"
    echo "<link rel=\"preload\" href=\"${ROOT}fonts/inter-cyrillic.woff2\" as=\"font\" type=\"font/woff2\" crossorigin>"
    echo "<link rel=\"preload\" href=\"${ROOT}fonts/manrope-cyrillic.woff2\" as=\"font\" type=\"font/woff2\" crossorigin>"
    echo "<link rel=\"stylesheet\" href=\"${ROOT}css/global.min.css\">"
    echo '<script type="application/ld+json">'
    echo "$ORG_JSONLD"
    echo '</script>'
    if [ "$DEPTH" != "0" ]; then
      echo '<script type="application/ld+json">'
      echo '{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":['
      echo "{\"@type\":\"ListItem\",\"position\":1,\"name\":\"Главная\",\"item\":\"${DOMAIN}/\"},"
      echo "{\"@type\":\"ListItem\",\"position\":2,\"name\":\"${CRUMB}\",\"item\":\"${CANONICAL}\"}"
      echo ']}'
      echo '</script>'
    fi
    if [ -f "$SCHEMA" ]; then
      echo '<script type="application/ld+json">'
      sed "s#{{DOMAIN}}#${DOMAIN}#g" "$SCHEMA"
      echo '</script>'
    fi
    echo '</head>'
    echo '<body>'
    cat "$TMP_DIR/header.html"
    echo '<main id="main">'
    cat "$TMP_DIR/content.html"
    echo '</main>'
    cat "$TMP_DIR/footer.html"
    echo '</body>'
    echo '</html>'
  } > "$OUT"

  {
    echo '  <url>'
    echo "    <loc>${CANONICAL}</loc>"
    echo "    <lastmod>${BUILD_DATE}</lastmod>"
    echo '  </url>'
  } >> "$SITEMAP"

  count=$((count + 1))
  echo "built ${OUT}"
done

echo '</urlset>' >> "$SITEMAP"
cp "$SITEMAP" sitemap.xml
echo "Done: ${count} pages, sitemap.xml updated (${BUILD_DATE})."
