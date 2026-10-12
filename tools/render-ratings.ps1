# Генерирует HTML-фрагменты рейтинга из data/ratings.json:
#   content/_rating-table.html   - сводная таблица + мобильные карточки
#   content/_company-cards.html  - 10 карточек компаний
#   content/_mini-{ne|kf|sk}.html - мини-карточки "Компании из рейтинга" для статей
#   meta/home.schema.json        - из meta/home.schema.tpl.json с подстановкой ItemList
# Запуск: powershell -ExecutionPolicy Bypass -File tools/render-ratings.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$ru = [Globalization.CultureInfo]::GetCultureInfo('ru-RU')
$utf8 = New-Object Text.UTF8Encoding $false
$domain = 'https://rejting-kompanij-po-kiberbezopasnosti-blokchejna.com'

$data = [IO.File]::ReadAllText((Join-Path $root 'data/ratings.json'), $utf8) | ConvertFrom-Json
$criteria = $data.criteria
$companies = $data.companies | Sort-Object rank

function Num($v) { ([double]$v).ToString('0.##', $ru) }
function Enc($s) { [Net.WebUtility]::HtmlEncode([string]$s) }
function Pct($v, $w) { if ($w -eq 0) { 0 } else { [math]::Round(100 * [double]$v / [double]$w, 2) } }
function Tint($share) { if ($share -ge 90) { '' } elseif ($share -ge 75) { 't2' } else { 't3' } }
function Bar($v, $w, $extra) {
  $p = Pct $v $w
  $t = Tint $p
  $cls = if ($t) { " class=`"$t`"" } else { '' }
  $wStr = $p.ToString([Globalization.CultureInfo]::InvariantCulture)
  "<span class=`"bar$extra`" aria-hidden=`"true`"><span$cls style=`"width:$wStr%`"></span></span>"
}
function Write-Utf8($rel, $text) {
  [IO.File]::WriteAllText((Join-Path $root $rel), ($text -replace "`r`n", "`n"), $utf8)
  Write-Host "wrote $rel"
}

# Проверка сумм
foreach ($c in $companies) {
  $sum = 0; foreach ($k in $criteria) { $sum += [double]$c.scores.($k.code) }
  if ([math]::Abs($sum - [double]$c.total) -gt 0.001) { throw "Сумма баллов $($c.name): $sum, указано $($c.total)" }
}

# ---------- Сводная таблица ----------
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('<div class="table-wrap rank-table-wrap">')
[void]$sb.AppendLine('  <table class="data-table rank-table">')
[void]$sb.AppendLine('    <thead><tr><th scope="col">Место</th><th scope="col">Компания</th><th scope="col">Тип</th><th scope="col">Главная услуга</th><th scope="col" class="num">Балл</th><th scope="col"><span class="visually-hidden">Обзор</span></th></tr></thead>')
[void]$sb.AppendLine('    <tbody>')
foreach ($c in $companies) {
  $first = if ($c.rank -eq 1) { ' class="is-first"' } else { '' }
  [void]$sb.AppendLine("      <tr$first><td><span class=`"rank-num`">$($c.rank)</span></td><td><span class=`"co-name`"><span class=`"co-mark`" aria-hidden=`"true`">$(Enc $c.initials)</span>$(Enc $c.name)</span></td><td>$(Enc $c.type_table)</td><td>$(Enc $c.main_service)</td><td><div class=`"score`"><span class=`"score__val`">$(Num $c.total) <small>/ 100</small></span>$(Bar $c.total 100 ' bar--w')</div></td><td><a class=`"btn btn--secondary btn--sm`" href=`"#company-$($c.rank)`">Обзор<span class=`"visually-hidden`">: $(Enc $c.name)</span></a></td></tr>")
}
[void]$sb.AppendLine('    </tbody>')
[void]$sb.AppendLine('  </table>')
[void]$sb.AppendLine('</div>')
[void]$sb.AppendLine('<ol class="rank-cards" aria-label="Рейтинг: 10 компаний">')
foreach ($c in $companies) {
  $first = if ($c.rank -eq 1) { ' is-first' } else { '' }
  [void]$sb.AppendLine("  <li class=`"rank-card$first`"><span class=`"rank-num`">$($c.rank)</span><span class=`"co-name`">$(Enc $c.name)</span><a class=`"btn btn--secondary btn--sm`" href=`"#company-$($c.rank)`">Обзор<span class=`"visually-hidden`">: $(Enc $c.name)</span></a><span class=`"rank-card__type`">$(Enc $c.type_table), <span class=`"mono`">$(Num $c.total) / 100</span></span>$(Bar $c.total 100 '')</li>")
}
[void]$sb.AppendLine('</ol>')
Write-Utf8 'content/_rating-table.html' $sb.ToString()

# ---------- Карточки компаний ----------
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('<div class="company-list">')
foreach ($c in $companies) {
  $n = $c.rank
  $first = if ($n -eq 1) { ' is-first' } else { '' }
  $lazy = if ($n -le 2) { 'eager' } else { 'lazy' }
  [void]$sb.AppendLine("<article class=`"company$first`" id=`"company-$n`" aria-labelledby=`"company-$n-name`">")
  [void]$sb.AppendLine('  <div class="company__head">')
  [void]$sb.AppendLine("    <span class=`"company__rank`" aria-label=`"Место $n`">#$n</span>")
  [void]$sb.AppendLine("    <span class=`"co-mark co-mark--lg`" aria-hidden=`"true`">$(Enc $c.initials)</span>")
  [void]$sb.AppendLine('    <div class="company__title">')
  [void]$sb.AppendLine("      <h3 id=`"company-$n-name`">$(Enc $c.name)</h3>")
  $tier = if ($n -eq 1) { ' <span class="badge badge--tier1">1 место по методологии</span>' } else { '' }
  [void]$sb.AppendLine("      <div class=`"company__type`"><span class=`"badge`">$(Enc $c.type)</span>$tier</div>")
  [void]$sb.AppendLine('    </div>')
  [void]$sb.AppendLine('  </div>')
  [void]$sb.AppendLine('  <div class="company__top">')
  [void]$sb.AppendLine('    <figure class="company__shot">')
  [void]$sb.AppendLine("      <div class=`"browser`"><div class=`"browser__bar`" aria-hidden=`"true`"><i></i><i></i><i></i><span>$(Enc $c.site_label)</span></div><img src=`"{{ROOT}}images/companies/$($c.slug).webp`" width=`"1200`" height=`"622`" loading=`"$lazy`" decoding=`"async`" alt=`"Главная страница сайта $(Enc $c.name)`"></div>")
  [void]$sb.AppendLine('    </figure>')
  [void]$sb.AppendLine("    <div class=`"scorecard`" aria-label=`"Баллы $(Enc $c.name) по 7 критериям`">")
  [void]$sb.AppendLine("      <p class=`"scorecard__total`"><span>Баллы</span><b>$(Num $c.total) <small>из 100</small></b></p>")
  [void]$sb.AppendLine('      <ul class="scores">')
  foreach ($k in $criteria) {
    $v = $c.scores.($k.code)
    [void]$sb.AppendLine("        <li><abbr title=`"$(Enc $k.name)`">$(Enc $k.code)</abbr><span class=`"scores__val`">$(Num $v)<small>/$($k.weight)</small></span>$(Bar $v $k.weight '')</li>")
  }
  [void]$sb.AppendLine('      </ul>')
  [void]$sb.AppendLine('    </div>')
  [void]$sb.AppendLine('  </div>')
  [void]$sb.AppendLine("  <p class=`"company__about`">$(Enc $c.about)</p>")
  [void]$sb.AppendLine('  <div class="company__panels">')
  [void]$sb.AppendLine('    <div class="company__panel"><h4>Ключевые услуги</h4><ul class="check-list">')
  foreach ($s in $c.services) { [void]$sb.AppendLine("      <li>{{icon:check}}$(Enc $s)</li>") }
  [void]$sb.AppendLine('    </ul></div>')
  [void]$sb.AppendLine("    <div class=`"company__panel`"><h4>Для кого</h4><p class=`"company__for`">$(Enc ($c.for.Substring(0,1).ToUpper() + $c.for.Substring(1)))</p></div>")
  [void]$sb.AppendLine('    <div class="company__panel"><h4>Подтверждения экспертизы</h4><ul class="dash-list">')
  foreach ($s in $c.proof) { [void]$sb.AppendLine("      <li>$(Enc $s)</li>") }
  [void]$sb.AppendLine('    </ul></div>')
  [void]$sb.AppendLine('  </div>')
  [void]$sb.AppendLine('  <div class="company__pros">')
  [void]$sb.AppendLine('    <div><h4>{{icon:circle-check}} Сильные стороны</h4><ul class="check-list">')
  foreach ($s in $c.strengths) { [void]$sb.AppendLine("      <li>{{icon:check}}$(Enc $s)</li>") }
  [void]$sb.AppendLine('    </ul></div>')
  [void]$sb.AppendLine('    <div class="is-limit"><h4>{{icon:circle-x}} Ограничения</h4><ul class="check-list x-list">')
  foreach ($s in $c.limits) { [void]$sb.AppendLine("      <li>{{icon:x}}$(Enc $s)</li>") }
  [void]$sb.AppendLine('    </ul></div>')
  [void]$sb.AppendLine('  </div>')
  [void]$sb.AppendLine("  <p class=`"company__foot`"><span>Сайт компании: <a href=`"$($c.site)`" target=`"_blank`" rel=`"noopener`">$(Enc $c.site_label)</a></span><span>Статья по теме: <a href=`"{{ROOT}}$($c.article.path)`">$(Enc $c.article.title)</a></span></p>")
  [void]$sb.AppendLine('</article>')
}
[void]$sb.AppendLine('</div>')
Write-Utf8 'content/_company-cards.html' $sb.ToString()

# ---------- Мини-карточки для статей ----------
$minis = @{ 'ne' = 'НЭ'; 'kf' = 'КФ'; 'sk' = 'СК' }
foreach ($key in $minis.Keys) {
  $code = $minis[$key]
  $crit = $criteria | Where-Object { $_.code -eq $code }
  $top = $companies | Sort-Object @{ Expression = { [double]$_.scores.$code }; Descending = $true }, @{ Expression = { [double]$_.total }; Descending = $true } | Select-Object -First 3
  $sb = New-Object Text.StringBuilder
  [void]$sb.AppendLine('<div class="mini-cards">')
  foreach ($c in $top) {
    $v = $c.scores.$code
    [void]$sb.AppendLine('  <div class="mini-card">')
    [void]$sb.AppendLine("    <p class=`"mini-card__head`"><span class=`"co-mark`" aria-hidden=`"true`">$(Enc $c.initials)</span>$(Enc $c.name)</p>")
    [void]$sb.AppendLine("    <p class=`"mini-card__score`"><span>$(Enc $crit.name)</span><b>$(Num $v) из $($crit.weight)</b></p>")
    [void]$sb.AppendLine("    $(Bar $v $crit.weight '')")
    [void]$sb.AppendLine("    <a href=`"{{ROOT}}#company-$($c.rank)`">Карточка в рейтинге: $($c.rank) место</a>")
    [void]$sb.AppendLine('  </div>')
  }
  [void]$sb.AppendLine('</div>')
  Write-Utf8 "content/_mini-$key.html" $sb.ToString()
}

# ---------- ItemList для главной ----------
$items = @()
foreach ($c in $companies) {
  $items += "        { `"@type`": `"ListItem`", `"position`": $($c.rank), `"name`": `"$($c.name)`", `"url`": `"$domain/#company-$($c.rank)`" }"
}
$tpl = [IO.File]::ReadAllText((Join-Path $root 'meta/home.schema.tpl.json'), $utf8)
Write-Utf8 'meta/home.schema.json' ($tpl.Replace('"{{ITEMLIST}}"', "[`n" + ($items -join ",`n") + "`n      ]"))
