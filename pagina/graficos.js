// ---------- utilidades ----------
const fmt = (v, d = 0) => v == null ? "–" : Number(v).toLocaleString("es-AR", { minimumFractionDigits: d, maximumFractionDigits: d });
const css = (nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
const NS = "http://www.w3.org/2000/svg";
function el(tag, attrs = {}, padre) {
  const e = document.createElementNS(NS, tag);
  for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
  if (padre) padre.appendChild(e);
  return e;
}
function html(tag, clase, texto) {
  const e = document.createElement(tag);
  if (clase) e.className = clase;
  if (texto != null) e.textContent = texto;
  return e;
}
// Ancho del dibujo: el del lugar donde va, entre 320 y 700 píxeles. Así los
// textos se ven a su tamaño real también en un celular.
const anchoDe = lienzo => Math.round(Math.min(700, Math.max(320, lienzo.clientWidth || 700)));
function escalaLineal(d0, d1, r0, r1) { return v => r0 + (v - d0) / (d1 - d0 || 1) * (r1 - r0); }
function ticks(max, n = 4) {
  const paso0 = max / n, mag = Math.pow(10, Math.floor(Math.log10(paso0)));
  const paso = [1, 2, 2.5, 5, 10].map(m => m * mag).find(p => p >= paso0);
  const t = []; let v = 0; do { t.push(+v.toFixed(6)); v += paso; } while (t[t.length - 1] < max - 1e-9);
  return t;
}

// Arma el marco común: título, subtítulo, leyenda, lienzo y tabla de datos.
function marco(id, { titulo, subtitulo, leyenda, fuente, columnas, filas, tipoLeyenda = "linea" }) {
  const fig = document.getElementById(id);
  fig.appendChild(html("p", "titulo", titulo));
  if (subtitulo) fig.appendChild(html("p", "subtitulo", subtitulo));
  if (leyenda && leyenda.length > 1) {
    const ley = html("div", "leyenda");
    leyenda.forEach(s => {
      const span = document.createElement("span");
      const i = document.createElement("i");
      if (tipoLeyenda === "caja") { i.className = "caja"; i.style.background = `var(${s.color})`; }
      else { i.style.borderColor = `var(${s.color})`; if (s.punteada) i.style.borderTopStyle = "dashed"; }
      span.appendChild(i); span.appendChild(document.createTextNode(s.nombre));
      ley.appendChild(span);
    });
    fig.appendChild(ley);
  }
  const lienzo = html("div", "lienzo");
  fig.appendChild(lienzo);
  const tip = html("div", "tooltip");
  lienzo.appendChild(tip);
  if (fuente) fig.appendChild(html("figcaption", null, fuente));
  if (columnas) {
    const det = html("details", "tabla");
    det.appendChild(html("summary", null, "Ver los datos"));
    const scroll = html("div", "tabla-scroll");
    const t = document.createElement("table");
    const tr = document.createElement("tr");
    columnas.forEach(c => tr.appendChild(html("th", null, c)));
    t.appendChild(tr);
    filas.forEach(f => { const r = document.createElement("tr"); f.forEach(c => r.appendChild(html("td", null, c))); t.appendChild(r); });
    scroll.appendChild(t); det.appendChild(scroll); fig.appendChild(det);
  }
  return { lienzo, tip };
}

function mostrarTip(tip, lienzo, x, y, encabezado, filas) {
  tip.replaceChildren();
  tip.appendChild(html("div", "encabezado", encabezado));
  filas.forEach(f => {
    const fila = html("div", "fila");
    const i = document.createElement("i");
    if (f.color) i.style.borderColor = `var(${f.color})`;
    fila.appendChild(i);
    fila.appendChild(html("b", null, f.valor));
    fila.appendChild(html("span", null, f.nombre));
    tip.appendChild(fila);
  });
  const ancho = lienzo.clientWidth;
  tip.style.left = Math.min(Math.max(x + 12, 0), ancho - 170) + "px";
  tip.style.top = Math.max(y - 20, 0) + "px";
  tip.style.opacity = 1;
}

// ---------- gráfico de líneas ----------
function lineas(id, cfg) {
  const { datos, x, series, yFmt = v => fmt(v), alto = 260 } = cfg;
  const { lienzo, tip } = marco(id, { ...cfg, leyenda: series });
  const W = anchoDe(lienzo), H = alto, m = { t: 12, r: cfg.margenDerecho ?? 92, b: 26, l: 46 };
  const svg = el("svg", { viewBox: `0 0 ${W} ${H}`, role: "img", "aria-label": cfg.titulo }, null);
  lienzo.insertBefore(svg, tip);
  const xs = datos.map(d => d[x]);
  const max = Math.max(...datos.flatMap(d => series.map(s => d[s.clave] ?? 0))) * 1.05;
  const yt = ticks(max);
  const X = escalaLineal(xs[0], xs[xs.length - 1], m.l, W - m.r);
  const Y = escalaLineal(0, yt[yt.length - 1], H - m.b, m.t);
  const eje = el("g", { class: "eje" }, svg);
  yt.forEach(v => {
    el("line", { class: "grilla", x1: m.l, x2: W - m.r, y1: Y(v), y2: Y(v) }, eje);
    el("text", { x: m.l - 6, y: Y(v) + 4, "text-anchor": "end" }, eje).textContent = yFmt(v);
  });
  const paso = Math.ceil(xs.length / (W < 500 ? 4 : 8));
  xs.forEach((v, i) => { const ultimo = i === xs.length - 1; if ((i % paso === 0 && (xs.length - 1 - i >= paso / 2 + 0.5 || ultimo)) || ultimo) el("text", { x: X(v), y: H - 6, "text-anchor": "middle" }, eje).textContent = v; });
  if (cfg.referencia != null) el("line", { x1: m.l, x2: W - m.r, y1: Y(cfg.referencia), y2: Y(cfg.referencia), stroke: css("--text-muted"), "stroke-dasharray": "3 3" }, svg);
  // Marcas verticales para hechos puntuales (x puede tener decimales: 2024.27 es abril de 2024).
  (cfg.marcas || []).forEach(mk => {
    el("line", { x1: X(mk.x), x2: X(mk.x), y1: m.t, y2: H - m.b, stroke: css("--text-muted"), "stroke-dasharray": "2 3" }, svg);
    el("text", { x: X(mk.x) + (mk.izquierda ? -5 : 5), y: m.t + 10, "text-anchor": mk.izquierda ? "end" : "start", class: "marca" }, svg).textContent = mk.texto;
  });
  // Una línea por serie; los años sin dato cortan la línea.
  const etiquetas = [];
  series.forEach(s => {
    let d = "", abierto = false;
    datos.forEach(p => {
      const v = p[s.clave];
      if (v == null) { abierto = false; return; }
      d += (abierto ? "L" : "M") + X(p[x]) + "," + Y(v); abierto = true;
    });
    el("path", { d, fill: "none", stroke: `var(${s.color})`, "stroke-width": 2, "stroke-linejoin": "round", "stroke-linecap": "round",
                 ...(s.punteada ? { "stroke-dasharray": "5 4" } : {}) }, svg);
    const ult = [...datos].reverse().find(p => p[s.clave] != null);
    if (ult) {
      el("circle", { cx: X(ult[x]), cy: Y(ult[s.clave]), r: 4, fill: `var(${s.color})`, stroke: "var(--surface-1)", "stroke-width": 2 }, svg);
      etiquetas.push({ y: Y(ult[s.clave]), x: X(ult[x]), texto: s.nombre });
    }
  });
  // Etiquetas directas al final de cada línea, separadas para que no se pisen.
  etiquetas.sort((a, b) => a.y - b.y);
  for (let i = 1; i < etiquetas.length; i++) if (etiquetas[i].y - etiquetas[i - 1].y < 14) etiquetas[i].y = etiquetas[i - 1].y + 14;
  etiquetas.forEach(e => { el("text", { class: "etiqueta", x: e.x + 8, y: e.y + 4 }, svg).textContent = e.texto; });
  // Capa de lectura: línea vertical y tooltip con todas las series del año.
  const guia = el("line", { y1: m.t, y2: H - m.b, stroke: css("--text-muted"), "stroke-width": 1, opacity: 0 }, svg);
  const zona = el("rect", { x: m.l, y: m.t, width: W - m.l - m.r, height: H - m.t - m.b, fill: "transparent", tabindex: 0 }, svg);
  function mover(evt) {
    const r = svg.getBoundingClientRect();
    const px = (evt.clientX - r.left) * W / r.width;
    let i = 0, mejor = Infinity;
    xs.forEach((v, k) => { const dd = Math.abs(X(v) - px); if (dd < mejor) { mejor = dd; i = k; } });
    const p = datos[i];
    guia.setAttribute("x1", X(p[x])); guia.setAttribute("x2", X(p[x])); guia.setAttribute("opacity", .6);
    mostrarTip(tip, lienzo, X(p[x]) * r.width / W, evt.clientY - r.top, String(p[x]),
      series.map(s => ({ color: s.color, nombre: s.nombre, valor: p[s.clave] == null ? "sin dato" : yFmt(p[s.clave]) })));
  }
  zona.addEventListener("pointermove", mover);
  zona.addEventListener("pointerleave", () => { tip.style.opacity = 0; guia.setAttribute("opacity", 0); });
}

// ---------- barras (simples o apiladas) ----------
function barras(id, cfg) {
  const { datos, x, series, yFmt = v => fmt(v), alto = 240, porcentaje = false } = cfg;
  const { lienzo, tip } = marco(id, { ...cfg, leyenda: series, tipoLeyenda: "caja" });
  const W = anchoDe(lienzo), H = alto, m = { t: 12, r: 12, b: 26, l: 46 };
  const svg = el("svg", { viewBox: `0 0 ${W} ${H}`, role: "img", "aria-label": cfg.titulo });
  lienzo.insertBefore(svg, tip);
  const totales = datos.map(d => series.reduce((a, s) => a + (d[s.clave] ?? 0), 0));
  const max = porcentaje ? 100 : Math.max(...totales) * 1.05;
  const yt = porcentaje ? [0, 25, 50, 75, 100] : ticks(max);
  const Y = escalaLineal(0, yt[yt.length - 1], H - m.b, m.t);
  const banda = (W - m.l - m.r) / datos.length, ancho = Math.min(banda * 0.7, 46);
  const eje = el("g", { class: "eje" }, svg);
  yt.forEach(v => {
    el("line", { class: "grilla", x1: m.l, x2: W - m.r, y1: Y(v), y2: Y(v) }, eje);
    el("text", { x: m.l - 6, y: Y(v) + 4, "text-anchor": "end" }, eje).textContent = porcentaje ? v + "%" : yFmt(v);
  });
  const paso = Math.ceil(datos.length / (W < 500 ? 5 : 10));
  datos.forEach((d, i) => {
    const cx = m.l + banda * i + banda / 2;
    const ultimo = i === datos.length - 1; if ((i % paso === 0 && (datos.length - 1 - i >= paso / 2 + 0.5)) || ultimo) el("text", { x: cx, y: H - 6, "text-anchor": "middle" }, eje).textContent = d[x];
    let base = 0;
    const g = el("g", { tabindex: 0 }, svg);
    series.forEach((s, k) => {
      const v = d[s.clave] ?? 0; if (v <= 0) return;
      const y0 = Y(base), y1 = Y(base + v);
      const alto = Math.max(y0 - y1 - 2, 1);
      const arriba = k === series.length - 1 || series.slice(k + 1).every(t => !(d[t.clave] > 0));
      el("rect", { x: cx - ancho / 2, y: y1, width: ancho, height: alto, rx: arriba ? 4 : 0, fill: `var(${s.color})` }, g);
      base += v;
    });
    const hit = el("rect", { x: cx - banda / 2, y: m.t, width: banda, height: H - m.t - m.b, fill: "transparent" }, g);
    const mostrar = evt => {
      const r = svg.getBoundingClientRect();
      mostrarTip(tip, lienzo, cx * r.width / W, (evt.clientY ?? r.top + 40) - r.top, String(d[x]),
        series.slice().reverse().map(s => ({ color: s.color, nombre: s.nombre, valor: porcentaje ? fmt(d[s.clave]) + "%" : yFmt(d[s.clave]) })));
      g.style.opacity = .85;
    };
    hit.addEventListener("pointermove", mostrar);
    g.addEventListener("focus", mostrar);
    hit.addEventListener("pointerleave", () => { tip.style.opacity = 0; g.style.opacity = 1; });
  });
}

function tabla(id, columnas, filas) {
  const t = document.getElementById(id);
  const tr = document.createElement("tr");
  columnas.forEach(c => tr.appendChild(html("th", null, c)));
  t.appendChild(tr);
  filas.forEach(f => { const r = document.createElement("tr"); f.forEach(c => r.appendChild(html("td", null, c))); t.appendChild(r); });
}

// ---------- mapa de puntos ----------
// Provincias en gris y un círculo por punto, con área proporcional al valor.
// Si el punto trae un valor anterior, se dibuja detrás como contorno punteado.
function mapa(id, cfg) {
  const { provincias, puntos, destacar = [], valorFmt = v => fmt(v), recorte } = cfg;
  const { lienzo, tip } = marco(id, cfg);
  const [lon0, lon1, lat0, lat1] = recorte || [-74, -53, -55.2, -21.7];
  const kx = Math.cos(38 * Math.PI / 180);           // corrige el estiramiento en latitudes medias
  const W = 420, escala = W / ((lon1 - lon0) * kx), H = Math.round((lat1 - lat0) * escala);
  const P = (lon, lat) => [(lon - lon0) * kx * escala, (lat1 - lat) * escala];
  const svg = el("svg", { viewBox: `0 0 ${W} ${H}`, role: "img", "aria-label": cfg.titulo, class: "mapa" });
  lienzo.insertBefore(svg, tip);
  provincias.forEach(pr => {
    const d = pr.anillos.map(a => "M" + a.map(([x, y]) => P(x, y).map(n => n.toFixed(1)).join(",")).join("L") + "Z").join("");
    el("path", { d, class: destacar.includes(pr.nombre) ? "provincia destacada" : "provincia" }, svg);
  });
  const max = Math.max(...puntos.flatMap(p => [p.valor ?? 0, p.anterior ?? 0]));
  const R = v => Math.sqrt(v / max) * (cfg.radioMax || 26);
  [...puntos].sort((a, b) => (b.valor ?? 0) - (a.valor ?? 0)).forEach(p => {
    const [x, y] = P(p.lon, p.lat);
    const g = el("g", { tabindex: 0 }, svg);
    if (p.anterior) el("circle", { cx: x, cy: y, r: R(p.anterior), class: "anterior" }, g);
    if (p.valor) el("circle", { cx: x, cy: y, r: R(p.valor), fill: `var(${p.color || "--series-1"})`, "fill-opacity": .85, stroke: "var(--surface-1)", "stroke-width": 1.5 }, g);
    else el("circle", { cx: x, cy: y, r: 3.5, fill: "var(--surface-1)", stroke: "var(--text-muted)", "stroke-width": 1.5 }, g);
    // Etiqueta con línea guía hacia el costado indicado.
    const [lx, ly] = [x + (p.dx ?? 40), y + (p.dy ?? 0)];
    el("line", { x1: x, y1: y, x2: lx, y2: ly, class: "guia" }, g);
    const anclaje = (p.dx ?? 40) < 0 ? "end" : "start", sep = anclaje === "end" ? -4 : 4;
    el("text", { x: lx + sep, y: ly - 2, "text-anchor": anclaje, class: "etiqueta-mapa" }, g).textContent = p.nombre;
    el("text", { x: lx + sep, y: ly + 12, "text-anchor": anclaje, class: "etiqueta-mapa-valor" }, g).textContent = p.leyenda;
    const mostrar = () => {
      const r = svg.getBoundingClientRect();
      mostrarTip(tip, lienzo, x * r.width / W, y * r.height / H, p.nombre,
        (p.tip || []).map(t => ({ nombre: t.nombre, valor: t.valor, color: t.color })));
    };
    g.addEventListener("pointerenter", mostrar); g.addEventListener("focus", mostrar);
    g.addEventListener("pointerleave", () => { tip.style.opacity = 0; });
    g.addEventListener("blur", () => { tip.style.opacity = 0; });
  });
  return svg;
}

// ---------- cascada (horizontal) ----------
// Arranca en un total, suma y resta cada paso, y termina en el otro total.
function cascada(id, cfg) {
  const { inicio, fin, pasos, valorFmt = v => fmt(v) } = cfg;
  const series = [
    { nombre: "Total", color: "--otros" },
    { nombre: "Bajó", color: "--series-2" },
    { nombre: "Subió", color: "--series-3" },
  ];
  const { lienzo, tip } = marco(id, { ...cfg, leyenda: series, tipoLeyenda: "caja" });
  const filas = [{ ...inicio, total: true }, ...pasos, { ...fin, total: true }];
  const alto = 34, W = anchoDe(lienzo), m = { t: 6, r: 50, b: 6, l: W < 500 ? 122 : 150 };
  const H = m.t + m.b + filas.length * alto;
  const svg = el("svg", { viewBox: `0 0 ${W} ${H}`, role: "img", "aria-label": cfg.titulo });
  lienzo.insertBefore(svg, tip);
  // La escala cubre todos los acumulados, incluso si el total termina en negativo.
  let acc = inicio.valor; const recorridos = [0, inicio.valor, fin.valor];
  pasos.forEach(s => { acc += s.valor; recorridos.push(acc); });
  const minimo = Math.min(...recorridos), maximo = Math.max(...recorridos);
  const X = escalaLineal(minimo, maximo + (maximo - minimo) * 0.02, m.l, W - m.r);
  let acumulado = inicio.valor;
  filas.forEach((f, i) => {
    const y = m.t + i * alto, g = el("g", { tabindex: 0 }, svg);
    let a, b, color;
    if (f.total) { a = 0; b = f.valor; color = f.valor < 0 ? "--series-2" : "--otros"; }
    else { a = acumulado; b = acumulado + f.valor; acumulado = b; color = f.valor < 0 ? "--series-2" : "--series-3"; }
    const x0 = X(Math.min(a, b)), x1 = X(Math.max(a, b));
    el("rect", { x: x0, y: y + 7, width: Math.max(x1 - x0, 2), height: alto - 14, rx: 4, fill: `var(${color})` }, g);
    // Conector punteado con la fila siguiente.
    if (i < filas.length - 1) el("line", { x1: X(f.total ? f.valor : b), x2: X(f.total ? f.valor : b), y1: y + alto - 7, y2: y + alto + 7, class: "conector" }, svg);
    el("text", { x: m.l - 10, y: y + alto / 2 + 4, "text-anchor": "end", class: f.total ? "rotulo-fila fuerte" : "rotulo-fila" }, g).textContent = f.nombre;
    const signo = f.total ? (f.valor < 0 ? "−" : "") : f.valor > 0 ? "+" : "−";
    el("text", { x: x1 + 6, y: y + alto / 2 + 4, class: "valor-fila" }, g).textContent = signo + valorFmt(Math.abs(f.valor));
    const hit = el("rect", { x: 0, y, width: W, height: alto, fill: "transparent" }, g);
    const mostrar = () => {
      const r = svg.getBoundingClientRect();
      mostrarTip(tip, lienzo, x1 * r.width / W, (y + alto) * r.height / H, f.nombre,
        [{ color, nombre: f.detalle || (f.total ? "total" : "cambio"), valor: signo + valorFmt(Math.abs(f.valor)) }]);
    };
    hit.addEventListener("pointerenter", mostrar); g.addEventListener("focus", mostrar);
    hit.addEventListener("pointerleave", () => { tip.style.opacity = 0; });
  });
}

// ---------- de cada 100 ----------
// Una cuadrícula de 10 x 10 por elemento: los cuadrados pintados son la parte.
function deCada100(id, cfg) {
  const { items, color = "--series-1" } = cfg;
  const fig = document.getElementById(id);
  fig.appendChild(html("p", "titulo", cfg.titulo));
  if (cfg.subtitulo) fig.appendChild(html("p", "subtitulo", cfg.subtitulo));
  const grilla = html("div", "cien-grilla");
  items.forEach(it => {
    const caja = html("div", "cien");
    const n = Math.round(it.valor);
    const svg = el("svg", { viewBox: "0 0 100 100", role: "img", "aria-label": `${it.nombre}: ${n} de cada 100` });
    for (let k = 0; k < 100; k++) {
      // Se llena de abajo hacia arriba, fila por fila.
      const fila = 9 - Math.floor(k / 10), col = k % 10;
      el("rect", { x: col * 10 + 1, y: fila * 10 + 1, width: 8, height: 8, rx: 1.5, fill: k < n ? `var(${color})` : "var(--grid)" }, svg);
    }
    caja.appendChild(svg);
    caja.appendChild(html("div", "cien-numero", String(n)));
    caja.appendChild(html("div", "cien-nombre", it.nombre));
    if (it.nota) caja.appendChild(html("div", "cien-nota", it.nota));
    grilla.appendChild(caja);
  });
  fig.appendChild(grilla);
  if (cfg.fuente) fig.appendChild(html("figcaption", null, cfg.fuente));
}

// ---------- antes y después ----------
// Una fila por indicador, con dos barras escaladas dentro de la fila.
function antesDespues(id, cfg) {
  const { filas, antes, despues } = cfg;
  const fig = document.getElementById(id);
  fig.appendChild(html("p", "titulo", cfg.titulo));
  if (cfg.subtitulo) fig.appendChild(html("p", "subtitulo", cfg.subtitulo));
  const caja = html("div", "ad");
  filas.forEach(f => {
    const fila = html("div", "ad-fila");
    fila.appendChild(html("div", "ad-nombre", f.nombre));
    const max = Math.max(f.antes, f.despues);
    [[antes, f.antes, "--otros"], [despues, f.despues, f.color || "--series-2"]].forEach(([anio, v, color]) => {
      const linea = html("div", "ad-barra");
      linea.appendChild(html("span", "ad-anio", anio));
      const pista = html("div", "ad-pista");
      const b = html("div", "ad-relleno");
      b.style.width = (100 * v / max) + "%"; b.style.background = `var(${color})`;
      pista.appendChild(b); linea.appendChild(pista);
      linea.appendChild(html("span", "ad-valor", f.fmt ? f.fmt(v) : fmt(v)));
      fila.appendChild(linea);
    });
    const cambio = 100 * (f.despues - f.antes) / f.antes;
    fila.appendChild(html("div", "ad-cambio", cfg.cambio ? cfg.cambio(f.antes, f.despues) : (cambio > 0 ? "+" : "−") + fmt(Math.abs(cambio)) + "%"));
    caja.appendChild(fila);
  });
  fig.appendChild(caja);
  if (cfg.fuente) fig.appendChild(html("figcaption", null, cfg.fuente));
}

// ---------- línea de tiempo ----------
function lineaDeTiempo(id, eventos) {
  const lista = document.getElementById(id);
  eventos.forEach(e => {
    const li = html("li", e.clase || null);
    li.appendChild(html("span", "lt-fecha", e.fecha));
    li.appendChild(html("span", "lt-texto", e.texto));
    lista.appendChild(li);
  });
}

// ---------- barras horizontales ----------
// Una fila por categoría: nombre, barra y valor. Para rankings con nombres largos.
function barrasHorizontales(id, cfg) {
  const { filas, color = "--series-1", valorFmt = v => fmt(v) } = cfg;
  const fig = document.getElementById(id);
  fig.appendChild(html("p", "titulo", cfg.titulo));
  if (cfg.subtitulo) fig.appendChild(html("p", "subtitulo", cfg.subtitulo));
  const caja = html("div", "bh");
  const max = Math.max(...filas.map(f => f.valor));
  filas.forEach(f => {
    caja.appendChild(html("div", "bh-nombre", f.nombre));
    const pista = html("div", "bh-pista");
    const b = html("div", "bh-relleno");
    b.style.width = (100 * f.valor / max) + "%"; b.style.background = `var(${f.color || color})`;
    pista.appendChild(b);
    pista.appendChild(html("span", "bh-valor", valorFmt(f.valor)));
    caja.appendChild(pista);
    if (f.nota) { caja.appendChild(html("div", null)); caja.appendChild(html("div", "bh-nota", f.nota)); }
  });
  fig.appendChild(caja);
  if (cfg.fuente) fig.appendChild(html("figcaption", null, cfg.fuente));
}

// ---------- tarjetas de corrección ----------
// Cada tarjeta: lo que se dijo (tachado), lo correcto y cómo se detectó.
function tarjetasCorreccion(id, items) {
  const caja = document.getElementById(id);
  items.forEach(c => {
    const t = html("article", "tarjeta");
    t.appendChild(html("div", "tarjeta-n", "Error " + c.numero + " · " + c.tipo));
    const dijo = html("p", "tarjeta-dijo"); dijo.appendChild(html("span", "rotulo", "Se dijo")); dijo.appendChild(html("s", null, c.lo_que_se_dijo));
    const era = html("p", "tarjeta-era"); era.appendChild(html("span", "rotulo", "Era")); era.appendChild(document.createTextNode(c.lo_correcto));
    t.appendChild(dijo); t.appendChild(era);
    t.appendChild(html("div", "tarjeta-como", "Lo detectó: " + c.como_se_detecto.toLowerCase().replace("francisco", "Francisco")));
    caja.appendChild(t);
  });
}
