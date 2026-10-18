// Landing page: the "two skies" clocks and the sticky header border.
// Sky colours and time-of-day labels match SkyPalette in the app.

(function () {
  const CITIES = [
    ['Toronto', 'America/Toronto'],
    ['New York', 'America/New_York'],
    ['San Francisco', 'America/Los_Angeles'],
    ['São Paulo', 'America/Sao_Paulo'],
    ['London', 'Europe/London'],
    ['Berlin', 'Europe/Berlin'],
    ['Dubai', 'Asia/Dubai'],
    ['Bengaluru', 'Asia/Kolkata'],
    ['Singapore', 'Asia/Singapore'],
    ['Tokyo', 'Asia/Tokyo'],
    ['Sydney', 'Australia/Sydney'],
  ];

  const SKY = {
    dawn: ['#F4C7A1', '#E9A6A1'],
    day: ['#BFD8EC', '#E6EEF3'],
    dusk: ['#F2B279', '#D9776A'],
    night: ['#2F3A66', '#1B2140'],
  };

  const youZone = Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  const $ = (id) => document.getElementById(id);

  function partsIn(zone, date) {
    const f = new Intl.DateTimeFormat('en-US', {
      timeZone: zone, hour: 'numeric', minute: '2-digit', hour12: true,
    });
    const hour24 = Number(new Intl.DateTimeFormat('en-US', {
      timeZone: zone, hour: 'numeric', hourCycle: 'h23',
    }).format(date));
    return { text: f.format(date).toLowerCase(), hour: hour24 };
  }

  // Minutes east of UTC for a zone at a given instant.
  function offsetMinutes(zone, date) {
    const local = new Date(date.toLocaleString('en-US', { timeZone: zone }));
    const utc = new Date(date.toLocaleString('en-US', { timeZone: 'UTC' }));
    return Math.round((local - utc) / 60000);
  }

  function skyFor(hour) {
    if (hour >= 5 && hour < 8) return 'dawn';
    if (hour >= 8 && hour < 17) return 'day';
    if (hour >= 17 && hour < 20) return 'dusk';
    return 'night';
  }

  function labelFor(hour) {
    if (hour >= 5 && hour < 8) return 'Early morning';
    if (hour >= 8 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 20) return 'Evening';
    if (hour >= 20 && hour < 23) return 'Night';
    return 'Late night';
  }

  function paint(card, hour) {
    const [a, b] = SKY[skyFor(hour)];
    card.style.background = `linear-gradient(${a}, ${b})`;
    card.classList.toggle('is-dark', hour < 5 || hour >= 20);
  }

  function describeGap(minutes, city) {
    if (minutes === 0) return `You and ${city} are on the same clock right now.`;
    const abs = Math.abs(minutes);
    const h = Math.floor(abs / 60);
    const m = abs % 60;
    const span = [h ? `${h} hour${h === 1 ? '' : 's'}` : '', m ? `${m} minutes` : '']
      .filter(Boolean).join(' ');
    return `${city} is <strong>${span} ${minutes > 0 ? 'ahead of' : 'behind'}</strong> you.`;
  }

  function whenItLands(zone) {
    // Tonight at 10pm your time, what time is it for them?
    const now = new Date();
    const youOffset = offsetMinutes(youZone, now);
    const tenPmYou = new Date(now);
    const youLocal = new Date(now.getTime() + youOffset * 60000);
    const dayStartUtc = Date.UTC(youLocal.getUTCFullYear(), youLocal.getUTCMonth(), youLocal.getUTCDate());
    tenPmYou.setTime(dayStartUtc + (22 * 60 - youOffset) * 60000);
    const them = partsIn(zone, tenPmYou);
    return ` If you check in at 10 pm tonight, it reaches them at <strong>${them.text}</strong> their time.`;
  }

  const select = $('city');
  // Some browsers still report the old names for a few zones.
  const RENAMED = { Calcutta: 'Kolkata', Saigon: 'Ho Chi Minh City', Kiev: 'Kyiv', Rangoon: 'Yangon', Katmandu: 'Kathmandu' };
  const lastPart = youZone.split('/').pop().replace(/_/g, ' ');
  const youCity = RENAMED[lastPart] || lastPart;
  const youOffsetNow = offsetMinutes(youZone, new Date());

  // Default to a city that is actually far away from the visitor.
  let defaultIndex = CITIES.findIndex(([, z]) => Math.abs(offsetMinutes(z, new Date()) - youOffsetNow) >= 8 * 60);
  if (defaultIndex < 0) defaultIndex = 0;

  CITIES.forEach(([name, zone], i) => {
    const opt = document.createElement('option');
    opt.value = zone;
    opt.textContent = name;
    if (i === defaultIndex) opt.selected = true;
    select.appendChild(opt);
  });

  function tick() {
    const now = new Date();
    const you = partsIn(youZone, now);
    const zone = select.value;
    const city = select.options[select.selectedIndex].textContent;
    const them = partsIn(zone, now);

    $('you-place').textContent = youCity === 'UTC' ? '' : youCity;
    $('you-time').textContent = you.text;
    $('you-label').textContent = labelFor(you.hour);
    $('them-time').textContent = them.text;
    $('them-label').textContent = labelFor(them.hour);
    paint($('sky-you'), you.hour);
    paint($('sky-them'), them.hour);

    const gap = offsetMinutes(zone, now) - offsetMinutes(youZone, now);
    $('sky-note').innerHTML = describeGap(gap, city) + (gap === 0 ? '' : whenItLands(zone));
  }

  select.addEventListener('change', tick);
  tick();
  setInterval(tick, 30000);

  // Header gets a hairline once the page has scrolled.
  const header = document.querySelector('.site-header');
  const onScroll = () => header.classList.toggle('scrolled', window.scrollY > 8);
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  const year = $('year');
  if (year) year.textContent = String(new Date().getFullYear());
})();
