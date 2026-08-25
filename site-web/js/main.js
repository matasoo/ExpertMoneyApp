/* =========================================================
   ExpertMoney — landing page interactions
   No dependencies.
   ========================================================= */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------------------------------------------------------
     Footer year
     --------------------------------------------------------- */
  var yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  /* ---------------------------------------------------------
     Sticky nav
     --------------------------------------------------------- */
  var nav = document.getElementById('nav');
  function onScroll() {
    if (!nav) return;
    nav.classList.toggle('is-stuck', window.scrollY > 12);
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* ---------------------------------------------------------
     Mobile menu
     --------------------------------------------------------- */
  var toggle = document.getElementById('navToggle');
  var links = document.getElementById('navLinks');

  function closeMenu() {
    if (!toggle || !links) return;
    toggle.classList.remove('is-open');
    links.classList.remove('is-open');
    toggle.setAttribute('aria-expanded', 'false');
  }

  if (toggle && links) {
    toggle.addEventListener('click', function () {
      var open = links.classList.toggle('is-open');
      toggle.classList.toggle('is-open', open);
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });

    links.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') closeMenu();
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeMenu();
    });
  }

  /* ---------------------------------------------------------
     Scroll reveal + one-shot animations
     (progress bars, goal rings, counters)
     --------------------------------------------------------- */
  var ringLength = 2 * Math.PI * 52; // r=52 in the SVG viewBox

  function fillBars(scope) {
    var bars = scope.querySelectorAll('.bar');
    for (var i = 0; i < bars.length; i++) {
      (function (bar, idx) {
        setTimeout(function () { bar.classList.add('is-on'); }, reduceMotion ? 0 : idx * 110);
      })(bars[i], i);
    }
  }

  function fillCharts(scope) {
    var charts = scope.querySelectorAll('.chart');
    for (var i = 0; i < charts.length; i++) {
      (function (chart) {
        setTimeout(function () { chart.classList.add('is-on'); }, reduceMotion ? 0 : 140);
      })(charts[i]);
    }
  }

  function fillRings(scope) {
    var rings = scope.querySelectorAll('.ring');
    for (var i = 0; i < rings.length; i++) {
      (function (ring, idx) {
        var pct = parseFloat(ring.getAttribute('data-pct')) || 0;
        var fg = ring.querySelector('.ring-fg');
        if (!fg) return;
        fg.style.strokeDasharray = ringLength;
        fg.style.strokeDashoffset = ringLength;
        setTimeout(function () {
          fg.style.strokeDashoffset = ringLength * (1 - pct / 100);
        }, reduceMotion ? 0 : 160 + idx * 150);
      })(rings[i], i);
    }
  }

  function runCounters(scope) {
    var counters = scope.querySelectorAll('.count');
    for (var i = 0; i < counters.length; i++) {
      (function (el) {
        if (el.dataset.done) return;
        el.dataset.done = '1';
        var target = parseFloat(el.getAttribute('data-to')) || 0;
        if (reduceMotion) { el.textContent = target; return; }

        var start = null;
        var dur = 1200;
        function tick(ts) {
          if (start === null) start = ts;
          var p = Math.min((ts - start) / dur, 1);
          // easeOutExpo
          var eased = p === 1 ? 1 : 1 - Math.pow(2, -10 * p);
          el.textContent = Math.round(target * eased);
          if (p < 1) requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
      })(counters[i]);
    }
  }

  var revealables = document.querySelectorAll('.reveal');

  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        el.classList.add('is-in');
        fillBars(el);
        fillRings(el);
        fillCharts(el);
        runCounters(el);
        io.unobserve(el);
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -60px 0px' });

    for (var r = 0; r < revealables.length; r++) io.observe(revealables[r]);
  } else {
    for (var f = 0; f < revealables.length; f++) revealables[f].classList.add('is-in');
    fillBars(document);
    fillRings(document);
    fillCharts(document);
    runCounters(document);
  }

  /* ---------------------------------------------------------
     Phone screen carousel
     --------------------------------------------------------- */
  var screens = document.querySelectorAll('.scr');
  var dots = document.querySelectorAll('.scr-dots button');
  var current = 0;
  var timer = null;

  function showScreen(index) {
    if (!screens.length) return;
    current = index;

    for (var i = 0; i < screens.length; i++) {
      screens[i].classList.toggle('is-active', i === index);
    }
    for (var d = 0; d < dots.length; d++) {
      dots[d].classList.toggle('is-active', d === index);
    }

    // Replay the bars/rings inside the screen that just became visible
    var active = screens[index];
    var bars = active.querySelectorAll('.bar');
    for (var b = 0; b < bars.length; b++) bars[b].classList.remove('is-on');
    fillBars(active);
  }

  function startAuto() {
    if (reduceMotion || !screens.length) return;
    stopAuto();
    timer = setInterval(function () {
      showScreen((current + 1) % screens.length);
    }, 4200);
  }

  function stopAuto() {
    if (timer) { clearInterval(timer); timer = null; }
  }

  for (var dd = 0; dd < dots.length; dd++) {
    dots[dd].addEventListener('click', function () {
      showScreen(parseInt(this.getAttribute('data-go'), 10));
      startAuto();
    });
  }

  var phoneWrap = document.querySelector('.hero-visual');
  if (phoneWrap) {
    phoneWrap.addEventListener('mouseenter', stopAuto);
    phoneWrap.addEventListener('mouseleave', startAuto);
  }

  // Pause the carousel while the tab is hidden
  document.addEventListener('visibilitychange', function () {
    if (document.hidden) stopAuto(); else startAuto();
  });

  startAuto();

  /* ---------------------------------------------------------
     FAQ accordion
     --------------------------------------------------------- */
  var questions = document.querySelectorAll('.q');
  for (var q = 0; q < questions.length; q++) {
    (function (item) {
      var btn = item.querySelector('.q-btn');
      var body = item.querySelector('.q-body');
      if (!btn || !body) return;

      btn.addEventListener('click', function () {
        var isOpen = item.classList.contains('is-open');

        // Close every other panel
        for (var k = 0; k < questions.length; k++) {
          questions[k].classList.remove('is-open');
          var otherBtn = questions[k].querySelector('.q-btn');
          var otherBody = questions[k].querySelector('.q-body');
          if (otherBtn) otherBtn.setAttribute('aria-expanded', 'false');
          if (otherBody) otherBody.style.maxHeight = null;
        }

        if (!isOpen) {
          item.classList.add('is-open');
          btn.setAttribute('aria-expanded', 'true');
          body.style.maxHeight = body.scrollHeight + 'px';
        }
      });
    })(questions[q]);
  }

  /* ---------------------------------------------------------
     Cursor glow on feature cards
     --------------------------------------------------------- */
  var cards = document.querySelectorAll('.card');
  for (var c = 0; c < cards.length; c++) {
    cards[c].addEventListener('mousemove', function (e) {
      var rect = this.getBoundingClientRect();
      this.style.setProperty('--mx', (e.clientX - rect.left) + 'px');
      this.style.setProperty('--my', (e.clientY - rect.top) + 'px');
    });
  }

  /* ---------------------------------------------------------
     Smooth anchor scroll with sticky-nav offset
     --------------------------------------------------------- */
  var anchors = document.querySelectorAll('a[href^="#"]');
  for (var a = 0; a < anchors.length; a++) {
    anchors[a].addEventListener('click', function (e) {
      var id = this.getAttribute('href');
      if (!id || id === '#') return;
      var target = document.querySelector(id);
      if (!target) return;

      e.preventDefault();
      var offset = target.getBoundingClientRect().top + window.scrollY - 84;
      window.scrollTo({ top: offset, behavior: reduceMotion ? 'auto' : 'smooth' });
    });
  }
})();
