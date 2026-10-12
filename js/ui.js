// Необязательные улучшения: подсветка пункта навигатора при прокрутке и закрытие выпадающего меню.
// Контент и навигация работают без этого файла.
(function () {
  var links = document.querySelectorAll('.side-nav a[href^="#"]');
  if (links.length && 'IntersectionObserver' in window) {
    var map = {};
    links.forEach(function (a) { map[a.getAttribute('href').slice(1)] = a; });
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        links.forEach(function (a) { a.classList.remove('is-active'); a.removeAttribute('aria-current'); });
        var link = map[e.target.id];
        if (link) { link.classList.add('is-active'); link.setAttribute('aria-current', 'true'); }
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    Object.keys(map).forEach(function (id) { var el = document.getElementById(id); if (el) observer.observe(el); });
  }
  var drop = document.querySelector('.nav-drop');
  if (drop) {
    document.addEventListener('click', function (e) { if (drop.open && !drop.contains(e.target)) drop.open = false; });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && drop.open) { drop.open = false; drop.querySelector('summary').focus(); } });
  }
})();
