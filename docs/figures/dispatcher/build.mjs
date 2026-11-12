import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import * as k from "../kit/iso-kit.mjs";
import { tubePieces, tubeSvg } from "../kit/tube.mjs";
import { kitScript } from "../scripts/inline-kit.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const theme = process.argv.includes("--light") ? "light" : "dark";
// Headless Chrome reports prefers-reduced-motion: reduce, so a capture of the
// animation needs this flag. The shipped page still honours the preference.
const forceMotion = process.argv.includes("--force-motion");

const WIDTH = 720;
const HEIGHT = 470;

// ---------------------------------------------------------------------------
// World geometry. 1 unit ~ 1 px of the real machine.
// ---------------------------------------------------------------------------

const BASE = { x: -140, y: -76, w: 280, d: 156, r: 10 };
const BASE_H = 13;
const FOOT_H = 6;

const TRUNK = [0, 10];
const TRUNK_R = 9;
const TRUNK_TOP = 92;

const DRUM = [0, 10];
const DRUM_R = 22;
const DRUM_Z = 92;
const DRUM_H = 24;
const DRUM_TOP = DRUM_Z + DRUM_H;
const CAP_H = 5;
const RING_R = 23;

const INTAKE_Y = 50;
const INTAKE_Z = 26;
const INTAKE_X0 = -122;
const INTAKE_X1 = -34;

const BINS = [-48, -16, 16, 48];
const BIN_Y = -46;
const BIN_W = 30;
const BIN_D = 28;
const BIN_H = 21;

const OUT_X = 104;
const OUT_Y = 12;
const OUT_Z = 104;

const PUMP = [-108, -42];
const PUMP_R = 17;
const PUMP_H = 24;

const GAUGE = [-94, -42];
const GAUGE_R = 14;
const GAUGE_Z = 38;

const COUNTER = [58, 52];
const COUNTER_R = 13;
const COUNTER_Z = 40;

const LEVER = [-88, -50];
const LEVER_R = 17;

const CAPSULE_R = 5.4;
const CAPSULE_L = 13;

// The capsule route: in at the bell mouth, up the trunk, into the drum, then
// either down into a pigeonhole or out along the outbound tube.
const ROUTE_IN = [
  [INTAKE_X0 + 8, INTAKE_Y, INTAKE_Z],
  [INTAKE_X1 - 8, INTAKE_Y, INTAKE_Z],
  [INTAKE_X1 + 10, INTAKE_Y - 6, INTAKE_Z],
  [-16, 26, INTAKE_Z],
  [TRUNK[0], TRUNK[1] + 2, INTAKE_Z],
  [TRUNK[0], TRUNK[1], 48],
  [TRUNK[0], TRUNK[1], TRUNK_TOP + 4],
  [TRUNK[0], TRUNK[1], DRUM_Z + 16],
];

const ROUTE_BIN = [
  [TRUNK[0], TRUNK[1], DRUM_Z + 16],
  [TRUNK[0], TRUNK[1] - 16, DRUM_Z + 2],
  [TRUNK[0], TRUNK[1] - 26, DRUM_Z - 22],
  [TRUNK[0], BIN_Y + 6, BIN_H + 4],
  [TRUNK[0], BIN_Y, BIN_H + 1],
];

const ROUTE_OUT = [
  [TRUNK[0], TRUNK[1], DRUM_Z + 16],
  [DRUM_R + 4, TRUNK[1], DRUM_Z + 14],
  [OUT_X, TRUNK[1], OUT_Z],
  [OUT_X, TRUNK[1], 58],
  [OUT_X, OUT_Y - 24, 50],
  [OUT_X, OUT_Y - 40, 44],
];

const P = k.fitProjection(
  [
    ...k.boxCorners(BASE, -BASE_H - FOOT_H, 0),
    [TRUNK[0], TRUNK[1], DRUM_TOP + CAP_H + 4],
    [INTAKE_X0, INTAKE_Y, INTAKE_Z],
    [OUT_X, OUT_Y - 40, 44],
    [PUMP[0], PUMP[1], PUMP_H + 18],
  ],
  WIDTH,
  HEIGHT,
  { pad: 34, azimuth: 42 },
);

const at = (point) => k.iso(point, P);
const S = (paths, style) => k.solidSvg(paths, style);
const L = (d, style) => k.lineSvg(d, style);
const D = (points, style) => k.dotsSvg(points, style);
const byDepth = (points) =>
  [...points].sort((a, b) => k.depthOf([a[0], a[1], 0], P) - k.depthOf([b[0], b[1], 0], P));

// A flat arm in the ground plane, drawn from world coordinates.
function armPath(from, to, z) {
  return [at([from[0], from[1], z]), at([to[0], to[1], z])]
    .map((p) => p.join(","))
    .join(" ");
}

// ---------------------------------------------------------------------------
// Static parts
// ---------------------------------------------------------------------------

function base() {
  const out = [`<path class="iso-halo" d="${k.haloOf(BASE, -BASE_H - FOOT_H, BASE_H, P)}"/>`];
  for (const [x, y] of byDepth(k.corners(BASE, 20))) {
    out.push(S(k.cylinder(x, y, 7.5, -BASE_H - FOOT_H, 1.6, P, 28), { tone: "lo" }));
    out.push(S(k.cylinder(x, y, 5.6, -BASE_H - FOOT_H + 1.6, FOOT_H - 1.6, P, 28), { tone: "mid" }));
  }
  out.push(S(k.slabOf(BASE, -BASE_H, BASE_H, P, 8, 1.8), { tone: "lo" }));
  out.push(L(k.planOutline(k.insetPlan(BASE, 6), 0, P), { tone: "lo" }));

  const screws = k.corners(BASE, 11);
  out.push(L(screws.map(([x, y]) => k.ring(x, y, 2.4, 0, P, 16)).join(""), { tone: "lo" }));
  out.push(D(screws.map(([x, y]) => at([x, y, 0])), { size: 0.55 }));

  // engraved label plate on the front edge
  const plate = { x: -46, y: BASE.y + 5, w: 92, d: 16, r: 2 };
  out.push(S(k.slabOf(plate, 0, 1.4, P, 3, 0.4), { tone: "lo", crease: "none" }));
  for (let i = 0; i < 3; i += 1) {
    out.push(
      L(
        k.planOutline(
          { x: plate.x + 6, y: plate.y + 4 + i * 4, w: plate.w - 12 - i * 12, d: 1.2, r: 0.5 },
          1.4,
          P,
        ),
        { tone: "faint" },
      ),
    );
  }
  out.push(
    D([at([plate.x + 4, plate.y + 8, 1.4]), at([plate.x + plate.w - 4, plate.y + 8, 1.4])], { size: 0.5 }),
  );

  // ruler strip with ticks along the front-left edge
  const strip = { x: -128, y: BASE.y + BASE.d - 15, w: 74, d: 8, r: 1 };
  out.push(S(k.slabOf(strip, 0, 0.7, P, 3, 0.3), { tone: "lo", crease: "none" }));
  const ticks = k.topTicks(
    strip.x + 4,
    strip.x + strip.w - 4,
    4,
    5,
    strip.y + 1,
    0.7,
    [2, 4],
    P,
  );
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  out.push(
    D([at([strip.x + 2, strip.y + 4, 0.7]), at([strip.x + strip.w - 2, strip.y + 4, 0.7])], { size: 0.45 }),
  );
  return out.join("");
}

function trunk() {
  const out = [];
  const [tx, ty] = TRUNK;

  const flangeRing = (z) =>
    L(
      [
        [tx + 10, ty + 3],
        [tx + 10, ty - 3],
        [tx - 10, ty - 3],
        [tx - 10, ty + 3],
        [tx + 10, ty + 3],
      ]
        .map(([x, y]) => at([x, y, z]))
        .map((p) => p.join(","))
        .join(" "),
      { tone: "faint" },
    );

  // bottom flange with bolts
  out.push(S(k.cylinder(tx, ty, 14, 0, 5, P, 36, 0.6), { tone: "lo" }));
  out.push(flangeRing(5));
  for (let i = 0; i < 3; i += 1) {
    const a = (i / 3) * Math.PI * 2 + 0.4;
    const bx = tx + Math.cos(a) * 10.5;
    const by = ty + Math.sin(a) * 10.5;
    out.push(L(k.ring(bx, by, 1.9, 5, P, 14), { tone: "lo" }));
    out.push(D([at([bx, by, 5])], { size: 0.45 }));
  }

  // the brass tube
  out.push(S(k.cylinder(tx, ty, TRUNK_R, 5, TRUNK_TOP - 5, P, 40, 0.5), { tone: "mid" }));
  out.push(L(k.ring(tx, ty, TRUNK_R, TRUNK_TOP, P, 40), { tone: "mid" }));

  // regulator body + knurled knob
  out.push(S(k.cylinder(tx, ty, 11, 44, 9, P, 32, 0.5), { tone: "mid" }));
  out.push(L(k.knurl(tx, ty, 10, 53, 62, 26, P, 0.5), { tone: "hi" }));
  out.push(S(k.cylinder(tx, ty, 11.4, 62, 2.4, P, 32, 0.6), { tone: "mid" }));
  const scale = k.radialTicks(tx, ty, 13.5, 12, 4, 44, [2, 3.6], P, -1.9, 3.8);
  out.push(L(scale.minor, { tone: "lo" }), L(scale.major, { tone: "mid" }));

  // top flange
  out.push(S(k.cylinder(tx, ty, 14, TRUNK_TOP - 5, 5, P, 36, 0.6), { tone: "lo" }));
  out.push(flangeRing(TRUNK_TOP));
  for (let i = 0; i < 3; i += 1) {
    const a = (i / 3) * Math.PI * 2 + 0.9;
    const bx = tx + Math.cos(a) * 10.5;
    const by = ty + Math.sin(a) * 10.5;
    out.push(L(k.ring(bx, by, 1.9, TRUNK_TOP, P, 14), { tone: "lo" }));
    out.push(D([at([bx, by, TRUNK_TOP])], { size: 0.45 }));
  }
  return out.join("");
}

function drum() {
  const out = [];
  const [dx, dy] = DRUM;

  out.push(S(k.cylinder(dx, dy, DRUM_R, DRUM_Z, DRUM_H, P, 44, 0.8), { tone: "mid" }));

  // cap with screws
  out.push(S(k.cylinder(dx, dy, DRUM_R + 1, DRUM_TOP, CAP_H, P, 44, 1.0), { tone: "hi" }));  const capScrews = k.corners({ x: dx - 15, y: dy - 15, w: 30, d: 30 }, 0);
  out.push(L(capScrews.map(([x, y]) => k.ring(x, y, 2.2, DRUM_TOP + CAP_H, P, 14)).join(""), { tone: "lo" }));
  out.push(D(capScrews.map(([x, y]) => at([x, y, DRUM_TOP + CAP_H])), { size: 0.5 }));

  // sight glass on the front of the drum
  out.push(S(k.cylinder(dx, dy - DRUM_R + 1, 7, DRUM_Z + 6, 11, P, 26, 0.4), { tone: "hi" }));
  // discharge spout with a collar
  out.push(S(k.cylinder(dx, dy - 16, 7.5, DRUM_Z - 12, 14, P, 24, 0.5), { tone: "mid" }));
  out.push(S(k.cylinder(dx, dy - 16, 9.2, DRUM_Z - 14, 3, P, 24, 0.4), { tone: "lo" }));

  // fixed index boss on the ring
  out.push(S(k.cylinder(dx + RING_R + 4, dy + 4, 4.2, DRUM_Z + 6, 8, P, 20, 0.4), { tone: "mid" }));
  out.push(L(k.ring(dx + RING_R + 4, dy + 4, 4.2, DRUM_Z + 14, P, 16), { tone: "lo" }));
  return out.join("");
}

function drumHead() {
  const out = [];
  const [dx, dy] = DRUM;
  out.push(S(k.cylinder(dx, dy, RING_R, DRUM_Z + 4, 16, P, 48, 0.5), { tone: "lo" }));
  const ticks = k.radialTicks(dx, dy, RING_R + 0.4, 24, 6, DRUM_Z + 12, [2, 4], P);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  return out.join("");
}

function intake() {
  const out = [];
  // The intake is a real horizontal pipe running from the bell mouth at the
  // back left, through a bellows, into the base of the trunk.
  const points = [
    [INTAKE_X0 - 4, INTAKE_Y, INTAKE_Z],
    [INTAKE_X0 + 16, INTAKE_Y, INTAKE_Z],
    [INTAKE_X0 + 34, INTAKE_Y, INTAKE_Z],
    [INTAKE_X0 + 62, INTAKE_Y, INTAKE_Z],
    [INTAKE_X1 + 4, INTAKE_Y - 4, INTAKE_Z],
    [-14, 28, INTAKE_Z],
  ];
  const pieces = tubePieces(points, 7.2, P, {
    maxLength: 34,
    spacing: 2.2,
    caps: true,
    rings: [{ at: 0.18, width: 3 }, { at: 0.52, width: 3 }],
  });
  for (const piece of pieces) out.push(tubeSvg(piece, { tone: "mid" }));

  // the bellows: a coil around the run between the two collars
  const bel = k.coil(
    INTAKE_X0 + 36,
    INTAKE_X0 + 60,
    [INTAKE_Y, INTAKE_Z],
    9.4,
    7,
    "x",
    P,
    14,
  );
  out.push(L(bel.back, { tone: "lo" }), L(bel.front, { tone: "hi" }));

  // bell mouth: a flared lip at the very start of the pipe
  out.push(S(k.cylinder(INTAKE_X0 - 4, INTAKE_Y, 11, INTAKE_Z - 11, 22, P, 30, 1.0), { tone: "hi" }));
  out.push(S(k.cylinder(INTAKE_X0 - 7, INTAKE_Y, 12.5, INTAKE_Z - 12, 24, P, 30, 1.2), { tone: "mid" }));
  return out.join("");
}

function outbound() {
  const out = [];
  // the outbound pipe leaves the drum, runs right and drops into the chute
  const points = [
    [DRUM_R - 2, OUT_Y, DRUM_Z + 12],
    [OUT_X - 34, OUT_Y, OUT_Z - 6],
    [OUT_X, OUT_Y, OUT_Z],
    [OUT_X, OUT_Y, 62],
    [OUT_X, OUT_Y - 18, 52],
    [OUT_X, OUT_Y - 34, 46],
  ];
  const pieces = tubePieces(points, 6.4, P, {
    maxLength: 34,
    spacing: 2.2,
    caps: true,
    rings: [{ at: 0.06, width: 3 }],
  });
  for (const piece of pieces) out.push(tubeSvg(piece, { tone: "mid" }));
  return out.join("");
}

function bins() {
  const out = [];
  BINS.forEach((bx, index) => {
    const plan = { x: bx - BIN_W / 2, y: BIN_Y - BIN_D / 2, w: BIN_W, d: BIN_D, r: 2 };
    out.push(S(k.slabOf(plan, 0, 3, P, 4, 0.4), { tone: "mid" }));
    out.push(
      S(k.slabOf({ x: plan.x, y: plan.y, w: BIN_W, d: 2.2, r: 1 }, 3, BIN_H, P, 3, 0.3), { tone: "mid" }),
    );
    out.push(
      S(
        k.slabOf({ x: plan.x, y: plan.y + BIN_D - 2.2, w: BIN_W, d: 2.2, r: 1 }, 3, BIN_H, P, 3, 0.3),
        { tone: "mid" },
      ),
    );
    out.push(
      S(k.slabOf({ x: plan.x, y: plan.y, w: 2.2, d: BIN_D, r: 1 }, 3, BIN_H, P, 3, 0.3), { tone: "mid" }),
    );
    out.push(
      S(
        k.slabOf({ x: plan.x + BIN_W - 2.2, y: plan.y, w: 2.2, d: BIN_D, r: 1 }, 3, BIN_H, P, 3, 0.3),
        { tone: "mid" },
      ),
    );
    const label = { x: bx - 11, y: plan.y - 3.4, w: 22, d: 2.6, r: 0.8 };
    out.push(S(k.slabOf(label, 3, 0.8, P, 2, 0.2), { tone: "lo", crease: "none" }));
    out.push(
      L(
        k.planOutline({ x: label.x + 3, y: label.y + 0.8, w: label.w - 6, d: 1, r: 0.4 }, 3.8, P),
        { tone: "faint" },
      ),
    );
    if (index < BINS.length - 1) {
      out.push(
        S(
          k.slabOf(
            { x: bx + BIN_W / 2 - 0.9, y: plan.y, w: 1.8, d: BIN_D, r: 0.6 },
            3,
            BIN_H + 3,
            P,
            2,
            0.3,
          ),
          { tone: "lo" },
        ),
      );
    }
  });
  return out.join("");
}

function pump() {
  const out = [];
  const [px, py] = PUMP;
  out.push(S(k.cylinder(px, py, PUMP_R + 4, 0, 4, P, 36, 0.6), { tone: "mid" }));
  for (let i = 0; i < 3; i += 1) {
    const a = (i / 3) * Math.PI * 2 + 0.7;
    const bx = px + Math.cos(a) * (PUMP_R + 1);
    const by = py + Math.sin(a) * (PUMP_R + 1);
    out.push(L(k.ring(bx, by, 1.9, 4, P, 14), { tone: "lo" }));
    out.push(D([at([bx, by, 4])], { size: 0.45 }));
  }
  out.push(S(k.cylinder(px, py, PUMP_R, 4, PUMP_H, P, 40, 0.8), { tone: "mid" }));
  out.push(S(k.cylinder(px, py, PUMP_R - 2, PUMP_H + 4, 5, P, 36, 0.6), { tone: "hi" }));
  out.push(S(k.cylinder(px, py, 7, PUMP_H + 9, 3, P, 24, 0.4), { tone: "mid" }));
  out.push(S(k.cylinder(px + 9, py, 3.2, PUMP_H + 9, 4, P, 18, 0.3), { tone: "mid" }));
  out.push(L(k.knurl(px + 13, py, 6, PUMP_H + 13, PUMP_H + 20, 18, P, 0.5), { tone: "hi" }));
  out.push(S(k.cylinder(px + 13, py, 6.4, PUMP_H + 20, 2.2, P, 18, 0.5), { tone: "mid" }));
  out.push(S(k.cylinder(px + PUMP_R - 2, py, 5.5, PUMP_H - 4, 8, P, 22, 0.4), { tone: "mid" }));
  // vacuum hose from the pump outlet to the base of the trunk
  const hose = k.coil(
    px + PUMP_R - 2,
    TRUNK[0] - TRUNK_R - 2,
    [TRUNK[1], PUMP_H + 4],
    5,
    5,
    "x",
    P,
    14,
  );
  out.push(L(hose.back, { tone: "lo" }), L(hose.front, { tone: "mid" }));
  return out.join("");
}

function gauge() {
  const out = [];
  const [gx, gy] = GAUGE;
  out.push(S(k.cylinder(gx, gy, 4.5, 0, GAUGE_Z - 10, P, 20, 0.4), { tone: "mid" }));
  out.push(S(k.cylinder(gx, gy, GAUGE_R, GAUGE_Z - 10, 11, P, 40, 0.8), { tone: "hi" }));
  out.push(S(k.cylinder(gx, gy, GAUGE_R + 1.6, GAUGE_Z + 1, 3.4, P, 40, 0.6), { tone: "mid" }));
  out.push(S(k.cylinder(gx, gy, GAUGE_R - 1.2, GAUGE_Z + 0.4, 0.9, P, 36, 0.3), { tone: "lo" }));
  const ticks = k.radialTicks(gx, gy, GAUGE_R - 3.4, 12, 4, GAUGE_Z + 1.3, [2, 3.4], P, -2.2, 4.4);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  for (let i = 0; i < 4; i += 1) {
    const a = (i / 4) * Math.PI * 2 + 0.78;
    const bx = gx + Math.cos(a) * (GAUGE_R - 0.4);
    const by = gy + Math.sin(a) * (GAUGE_R - 0.4);
    out.push(L(k.ring(bx, by, 1.7, GAUGE_Z + 4.4, P, 12), { tone: "lo" }));
    out.push(D([at([bx, by, GAUGE_Z + 4.4])], { size: 0.42 }));
  }
  return out.join("");
}

function counter() {
  const out = [];
  const [cx, cy] = COUNTER;
  out.push(S(k.cylinder(cx, cy, 4.5, 0, COUNTER_Z - 10, P, 20, 0.4), { tone: "mid" }));
  out.push(S(k.cylinder(cx, cy, COUNTER_R, COUNTER_Z - 10, 10, P, 36, 0.8), { tone: "hi" }));
  out.push(S(k.cylinder(cx, cy, COUNTER_R + 1.4, COUNTER_Z, 3, P, 36, 0.5), { tone: "mid" }));
  out.push(S(k.cylinder(cx, cy, COUNTER_R - 1.2, COUNTER_Z - 0.6, 0.8, P, 32, 0.3), { tone: "lo" }));
  const ticks = k.radialTicks(cx, cy, COUNTER_R - 3, 10, 5, COUNTER_Z, [1.8, 3], P, -1.6, 3.2);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  return out.join("");
}

function lever() {
  const out = [];
  const [lx, ly] = LEVER;
  out.push(S(k.cylinder(lx, ly, LEVER_R, 0, 3.4, P, 36, 0.6), { tone: "mid" }));
  for (let i = 0; i < 4; i += 1) {
    const a = -0.5 + (i / 3) * 3.0;
    const bx = lx + Math.cos(a) * (LEVER_R - 5);
    const by = ly + Math.sin(a) * (LEVER_R - 5);
    out.push(L(k.ring(bx, by, 1.8, 3.4, P, 14), { tone: "lo" }));
    out.push(D([at([bx, by, 3.4])], { size: 0.44 }));
  }
  out.push(S(k.cylinder(lx, ly, 4.6, 3.4, 6, P, 22, 0.5), { tone: "mid" }));
  const ticks = k.radialTicks(lx, ly, LEVER_R - 2.4, 10, 5, 3.4, [1.8, 3.2], P, -0.6, 3.0);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  return out.join("");
}

function leverKnob() {
  return (
    S(k.cylinder(0, 0, 4.4, 0, 5, P, 20, 0.5), { tone: "hi" }) +
    S(k.cylinder(0, 0, 4.8, 5, 1.6, P, 20, 0.4), { tone: "mid" })
  );
}

function chute() {
  const out = [];
  const tray = { x: OUT_X - 15, y: OUT_Y - 52, w: 30, d: 26, r: 2 };
  out.push(S(k.slabOf(tray, 0, 2.4, P, 4, 0.4), { tone: "mid" }));
  out.push(S(k.slabOf({ x: tray.x, y: tray.y, w: tray.w, d: 2.2, r: 1 }, 2.4, 7, P, 3, 0.3), { tone: "mid" }));
  out.push(
    S(k.slabOf({ x: tray.x, y: tray.y + tray.d - 2.2, w: tray.w, d: 2.2, r: 1 }, 2.4, 7, P, 3, 0.3), { tone: "mid" }),
  );
  out.push(S(k.slabOf({ x: tray.x, y: tray.y, w: 2.2, d: tray.d, r: 1 }, 2.4, 7, P, 3, 0.3), { tone: "mid" }));
  out.push(
    S(k.slabOf({ x: tray.x + tray.w - 2.2, y: tray.y, w: 2.2, d: tray.d, r: 1 }, 2.4, 7, P, 3, 0.3), { tone: "mid" }),
  );
  for (const sx of [tray.x + 4, tray.x + tray.w - 4]) {
    out.push(S(k.cylinder(sx, tray.y + tray.d / 2, 2.4, 0, 2.4, P, 14, 0.2), { tone: "lo" }));
  }
  const label = { x: tray.x + 5, y: tray.y - 3.2, w: tray.w - 10, d: 2.4, r: 0.8 };
  out.push(S(k.slabOf(label, 2.4, 0.8, P, 2, 0.2), { tone: "lo", crease: "none" }));
  return out.join("");
}

function harness() {
  const out = [];
  const run = k.coil(-118, 118, [-18, 4], 3.4, 1, "x", P, 16);
  out.push(L(run.back, { tone: "lo" }), L(run.front, { tone: "mid" }));
  for (const cx of [-118, 118]) {
    out.push(S(k.cylinder(cx, -18, 5, 1.6, 5, P, 18, 0.4), { tone: "mid" }));
    out.push(D([at([cx, -18, 6.6])], { size: 0.5 }));
  }
  const cover = { x: -110, y: -23, w: 220, d: 10, r: 2 };
  out.push(S(k.slabOf(cover, 0, 1.6, P, 4, 0.3), { tone: "lo", crease: "none" }));
  return out.join("");
}

// ---------------------------------------------------------------------------
// Moving parts
// ---------------------------------------------------------------------------

function capsule() {
  const out = [];
  out.push(S(k.cylinder(0, 0, CAPSULE_R, -CAPSULE_L / 2, CAPSULE_L, P, 26, 0.5), { tone: "lit" }));
  out.push(S(k.cylinder(0, 0, CAPSULE_R - 1.1, -CAPSULE_L / 2 + 1.4, CAPSULE_L - 2.8, P, 22, 0.3), { tone: "lo" }));
  out.push(
    S(
      k.slabOf({ x: -3.2, y: -0.4, w: 6.4, d: 0.9, r: 0.3 }, -CAPSULE_L / 2 + 2, CAPSULE_L - 4.4, P, 3, 0.2),
      { tone: "mid" },
    ),
  );
  out.push(S(k.cylinder(0, 0, CAPSULE_R + 0.7, -CAPSULE_L / 2 - 1.2, 1.4, P, 26, 0.4), { tone: "mid" }));
  out.push(S(k.cylinder(0, 0, CAPSULE_R + 0.7, CAPSULE_L / 2 - 0.2, 1.4, P, 26, 0.4), { tone: "mid" }));
  return out.join("");
}

// The drum's index needle, carried round by the ring.
function needlePath(turn) {
  const [dx, dy] = DRUM;
  const r = RING_R + 4;
  const a = turn - Math.PI / 2;
  const tip = [dx + Math.cos(a) * r, dy + Math.sin(a) * r];
  return armPath([dx, dy], tip, DRUM_Z + 14);
}

// A pointer arm that steps between four detents.
function leverPath(angle) {
  const [lx, ly] = LEVER;
  const len = LEVER_R - 4;
  return armPath([lx, ly], [lx + Math.cos(angle) * len, ly + Math.sin(angle) * len], 9);
}

function leverTip(angle) {
  const [lx, ly] = LEVER;
  const len = LEVER_R - 4;
  return [lx + Math.cos(angle) * len, ly + Math.sin(angle) * len, 7];
}

function gaugePath(angle) {
  const [gx, gy] = GAUGE;
  const len = GAUGE_R - 4;
  return armPath([gx, gy], [gx + Math.cos(angle) * len, gy + Math.sin(angle) * len], GAUGE_Z + 1.6);
}

function counterPath(angle) {
  const [cx, cy] = COUNTER;
  const len = COUNTER_R - 3.5;
  return armPath([cx, cy], [cx + Math.cos(angle) * len, cy + Math.sin(angle) * len], COUNTER_Z + 0.6);
}

// ---------------------------------------------------------------------------
// Figure
// ---------------------------------------------------------------------------

const svg = k.figureSvg({
  width: WIDTH,
  height: HEIGHT,
  label:
    "A pneumatic transaction dispatcher on a walnut bench. A glass capsule carrying one transaction is pushed into the bell mouth at the back left; a vacuum line lifts it up the brass trunk to the address drum at the head of the machine. The drum turns to the destination the address selects, and the capsule drops into one of four pigeonholes (memory) or is dispatched down the outbound tube to the chute (a peripheral). A lever on the left steps the core through fetch, execute and memory; a counter on the right tallies completed dispatches and the gauge shows bus activity.",
  body: [
    base(),
    harness(),
    chute(),
    pump(),
    bins(),
    intake(),
    trunk(),
    drum(),
    drumHead(),
    outbound(),
    gauge(),
    counter(),
    lever(),
    `<path data-part="needle" class="iso-line" data-tone="lit" data-free="start" d="${needlePath(0)}" style="stroke-width:1.6"/>`,
    `<path data-part="leverarm" class="iso-line" data-tone="hi" data-free="start" d="${leverPath(-0.5)}" style="stroke-width:2.2"/>`,
    `<g data-part="leverknob" transform="${k.translateAlong(P, leverTip(-0.5))}">${leverKnob()}</g>`,
    `<path data-part="gaugeneedle" class="iso-line" data-tone="lit" data-free="start" d="${gaugePath(-2.2)}" style="stroke-width:1.3"/>`,
    `<path data-part="counterneedle" class="iso-line" data-tone="lit" data-free="start" d="${counterPath(-1.6)}" style="stroke-width:1.2"/>`,
    `<g data-part="capsule">${capsule()}</g>`,
  ],
});

// ---------------------------------------------------------------------------
// Live animation
// ---------------------------------------------------------------------------

const live = `
const P = ${JSON.stringify(P)};
const ROUTE_IN = ${JSON.stringify(ROUTE_IN)};
const ROUTE_BIN = ${JSON.stringify(ROUTE_BIN)};
const ROUTE_OUT = ${JSON.stringify(ROUTE_OUT)};
const LEVER = ${JSON.stringify(LEVER)};
const GAUGE = ${JSON.stringify(GAUGE)};
const COUNTER = ${JSON.stringify(COUNTER)};
const GAUGE_Z = ${GAUGE_Z};
const COUNTER_Z = ${COUNTER_Z};
const DRUM = ${JSON.stringify(DRUM)};
const DRUM_Z = ${DRUM_Z};
const LEVER_R = ${LEVER_R};
const GAUGE_R = ${GAUGE_R};
const COUNTER_R = ${COUNTER_R};

const stage = document.querySelector(".iso-stage");
const svg = stage.querySelector("svg");
const capsule = svg.querySelector('[data-part="capsule"]');
const needle = svg.querySelector('[data-part="needle"]');
const leverarm = svg.querySelector('[data-part="leverarm"]');
const leverknob = svg.querySelector('[data-part="leverknob"]');
const gaugeneedle = svg.querySelector('[data-part="gaugeneedle"]');
const counterneedle = svg.querySelector('[data-part="counterneedle"]');
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const motionOff = still.matches && !${JSON.stringify(forceMotion)};

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const smooth = (t) => t * t * (3 - 2 * t);

function armPath(from, to, z) {
  return [iso([from[0], from[1], z], P), iso([to[0], to[1], z], P)].map((p) => p.join(",")).join(" ");
}

function routePoint(route, t) {
  const segs = [];
  let total = 0;
  for (let i = 1; i < route.length; i += 1) {
    const a = route[i - 1];
    const b = route[i];
    const d = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
    segs.push(d);
    total += d;
  }
  let want = clamp(t, 0, 1) * total;
  for (let i = 0; i < segs.length; i += 1) {
    if (want <= segs[i] || i === segs.length - 1) {
      const f = segs[i] ? want / segs[i] : 0;
      const a = route[i];
      const b = route[i + 1];
      return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f];
    }
    want -= segs[i];
  }
  return route[route.length - 1];
}

// One transaction, from the peripheral port to memory and out again.
const PHASES = [
  { name: "req / gnt",   route: ROUTE_IN,  from: 0.00, to: 0.20 },
  { name: "bus beat",    route: ROUTE_IN,  from: 0.20, to: 0.44 },
  { name: "bus beat",    route: ROUTE_IN,  from: 0.44, to: 0.62 },
  { name: "decode",      route: ROUTE_IN,  from: 0.62, to: 0.72 },
  { name: "to memory",   route: ROUTE_BIN, from: 0.00, to: 0.86 },
  { name: "to peripheral", route: ROUTE_OUT, from: 0.00, to: 1.00 },
];

const DETENTS = [-0.5, 0.5, 1.5, 2.5];
const DETENT_NAMES = ["FETCH", "EXEC", "MEM", "TRAP"];

function phaseAt(t) {
  let start = 0;
  for (const p of PHASES) {
    const span = p.to - p.from;
    if (t < start + span) return { phase: p, f: span ? (t - start) / span : 0 };
    start += span;
  }
  const last = PHASES[PHASES.length - 1];
  return { phase: last, f: 1 };
}

const PERIOD = 9.0;
let clock = 0;
let last = 0;
let frame = 0;
let visible = false;
let dispatched = 0;
let lastDispatched = 0;

function draw() {
  const t = (clock % PERIOD) / PERIOD;
  const { phase, f } = phaseAt(t);
  const p = routePoint(phase.route, smooth(clamp(f, 0, 1)));

  capsule.setAttribute("transform", translateAlong(P, p));

  // the address drum turns while the transaction is being decoded, then again
  // when it is dispatched to the peripheral
  let turn = 0;
  if (t >= 0.56 && t < 0.76) turn = smooth((t - 0.56) / 0.20) * 1.05;
  else if (t >= 0.84 && t < 0.97) turn = 1.05 + smooth((t - 0.84) / 0.13) * 0.85;
  else if (t >= 0.97) turn = 1.9;
  needle.setAttribute("d", armPath(DRUM, [
    DRUM[0] + Math.cos(turn - Math.PI / 2) * 30,
    DRUM[1] + Math.sin(turn - Math.PI / 2) * 30,
  ], DRUM_Z + 14));

  // the lever steps through the core's four architectural states
  const stateIndex = Math.min(3, Math.floor(t * 4.4));
  const angle = DETENTS[stateIndex];
  leverarm.setAttribute("d", armPath(LEVER, [
    LEVER[0] + Math.cos(angle) * (LEVER_R - 4),
    LEVER[1] + Math.sin(angle) * (LEVER_R - 4),
  ], 9));
  leverknob.setAttribute("transform", translateAlong(P, [
    LEVER[0] + Math.cos(angle) * (LEVER_R - 4),
    LEVER[1] + Math.sin(angle) * (LEVER_R - 4),
    7,
  ]));

  // the gauge needle flicks with each bus beat
  const flick = Math.sin(t * 42) * (0.3 + 0.28 * Math.sin(t * 7.3));
  gaugeneedle.setAttribute("d", armPath(GAUGE, [
    GAUGE[0] + Math.cos(-2.2 + flick * 0.5) * (GAUGE_R - 4),
    GAUGE[1] + Math.sin(-2.2 + flick * 0.5) * (GAUGE_R - 4),
  ], GAUGE_Z + 1.6));

  // the counter advances once the transaction has landed
  if (t > 0.86 && dispatched === lastDispatched) {
    dispatched += 1;
  }
  lastDispatched = dispatched;
  const counterTurn = -1.6 + (dispatched + (t > 0.86 ? (t - 0.86) * 4 : 0)) * 0.63;
  counterneedle.setAttribute("d", armPath(COUNTER, [
    COUNTER[0] + Math.cos(counterTurn) * (COUNTER_R - 3.5),
    COUNTER[1] + Math.sin(counterTurn) * (COUNTER_R - 3.5),
  ], COUNTER_Z + 0.6));

  readout.textContent =
    phase.name + "  ·  core " + DETENT_NAMES[stateIndex] +
    "  ·  bus " + (t < 0.56 ? "idle" : "beat") +
    "  ·  dispatched " + dispatched;
}

function tick(now) {
  if (!last) last = now;
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  clock += dt;
  draw();
  frame = visible && !motionOff ? requestAnimationFrame(tick) : 0;
}
const run = () => { if (!frame && visible) { last = 0; frame = requestAnimationFrame(tick); } };
new IntersectionObserver((entries) => { visible = entries[entries.length - 1].isIntersecting; if (visible) run(); }, { rootMargin: "140px 0px" }).observe(stage);
if (motionOff) { clock = 1.2; }
draw();
`;

const body = k.plateHtml({
  fig: "Fig 1",
  title: "The transaction dispatcher",
  hint: "One transaction crossing the machine",
  readout: "req / gnt",
  keys: [
    { mark: "lit", label: "The capsule: one transaction crossing the fabric" },
    { mark: "raised", label: "The address drum: which slave the transaction selects" },
    { mark: "mid", label: "The four pigeonholes: Boot ROM, TCM, SRAM and the peripherals" },
  ],
  caption:
    "A pneumatic dispatcher on a bench. A capsule carrying one transaction is pushed in at the bell mouth and lifted up the brass trunk; the address drum at the head turns to the slave the address selects, and the capsule either drops into a pigeonhole (memory) or is dispatched down the outbound tube to the chute (a peripheral). The lever steps the core through fetch, execute and memory while the capsule travels; the counter tallies completed dispatches and the gauge shows bus activity.",
  body: `<div class="iso-stage" tabindex="0" role="img" aria-label="Animation of one transaction crossing the SoC: in at the peripheral port, up the bus fabric, decoded by the address drum, and out to memory or a peripheral">${svg}</div>`,
});

writeFileSync(
  join(HERE, theme === "light" ? "dispatcher-light.html" : "dispatcher.html"),
  k.pageHtml({ title: "The transaction dispatcher", theme, body, script: kitScript() + live }),
);
console.log("wrote", theme === "light" ? "dispatcher-light.html" : "dispatcher.html");
