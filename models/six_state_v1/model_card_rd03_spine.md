# Model card — RD-03 spine v0.2-alpha (param set RD03-P-0002)

**Status placard (corrected per Sol 5.6 cross-check, 2026-07-18):**
**v0.2-alpha / RELATIONSHIP PROTOTYPE.** Executable eight-state spine with
**selected component equations checked** (analytic RL benchmark with magnetics
disabled; electrical-only energy balance; constitutive limits; tolerance check on
three terminal states). **NOT code-verified as a coupled system. NOT calibrated,
NOT bench-validated, NOT disposition-capable. Not ready for calibration,
fault-library development, or design decisions.**

**Independent reproduction (positive evidence):** Sol 5.6 translated the exact
equations to SciPy/BDF and reproduced both headline runs to 5 significant digits
(0.4 s: 0.98035 A / 1.5540 mm / 389.965 kPa; 180 s: 0.69450 A / 0.3674 mm /
144.264 kPa / 131.93 °C / 136.26 °C). Cross-implementation agreement verifies the
ARITHMETIC, not the physics.

## KNOWN DEFECTS (v0.2-alpha — fix before any new physics)
1. **CRITICAL — energy non-conservation at the EM coupling.** Fmag = kf·i² performs
   mechanical work (≈5.5 mJ in the reference run) that is never removed from the
   electrical side: the electrical equation uses constant L with no motion-linked
   back-EMF (no i·dλ/dx·v term). The v0.2 energy test hid this by setting kf=0.
   Fix (v0.3): mutually consistent flux-linkage/co-energy pair
   V = R·i + dλ(i,x,T)/dt, F = ∂W′mag/∂x; energy ledger test WITH force active.
2. **CRITICAL — the 180 s "thermal droop" is dominated by an arbitrary Pheat=100 W
   fluid-heating input**, not by coil self-heating (~3–5 W). With Pheat=0:
   38.1 °C winding, 0.934 A, 1.307 mm, 359 kPa at 180 s [Sol 5.6 reproduction].
   The scenario is hereby relabeled **"forced-hot-fluid illustration"** — a
   commanded boundary condition (hot ATF is the RD-03P operating condition), NOT an
   emergent production signature. The voltage-vs-current-drive lesson survives
   qualitatively; the 63% figure belongs to the forced scenario only.
3. **CRITICAL — identifiability claim RETRACTED.** The v0.2 screen used 4 scalar
   features for 6 parameters, guaranteeing ≥2 exact null directions by
   construction; t63 was extracted from the adaptive solver mesh (find), making its
   sensitivity mesh-dependent. The specific {cr, beta, Fc} null-direction claim is
   **withdrawn**. Status: **rank-deficient preliminary screen**; the only claim
   retained is the generic one — a single energize trace cannot support six
   parameters. Redo per the redesigned program (multiple experiments, full sampled
   time series via deval on fixed grids, noise-covariance weighting, stacked
   QR/SVD, then profile likelihood on the surviving subset).
4. **HIGH — boundary models are soft numerical clamps.** The seat/stroke penalty
   admits penetration (−18.9 µm energized, −25.5 µm unpowered [Sol run]; ICs are
   not a seated equilibrium). The vapor floor only blocks negative dP, so a
   temperature-driven RISE of Pvap can strand P below the moving floor (~650 Pa
   violation in an isolated warming test). Fix: consistent seated initial
   equilibrium, event/complementarity contact, floor projection or DAE
   formulation; mass-conserving vapor/gas fractions remain RESERVED.
5. HIGH — constitutive gaps: Cd tanh surrogate is NOT Wu's fitted form; outlet path
   hard-codes 0.6·1.2e-7 (magic numbers); no signed/reverse flow; no flow force;
   constant beta; no static/stick friction mode; chamber volume constant (no V(x)).
6. HIGH — verification narrowness: single scalar AbsTol across states of wildly
   different magnitude; convergence checked on 3 terminal states only; the 1.7e4
   stiffness indicator lacked a definition/script (FD-Jacobian eigenvalue spread at
   the 0.4 s state is ~9.7e5 [Sol]; publish the script with the number).
7. MEDIUM — observation layer covers pressure only (no current-probe bandwidth,
   temperature lag, sampling/clock/anti-alias model; noise is declared, not
   realized). MEDIUM — V0 incomplete: no one-command runner/buildfile, no file
   hashes, no generated-data manifest.

## Retained strengths (per cross-check)
Gauge vs absolute pressure explicit · sensor in the observation path · topology
claim bounded (one body, one pressure node) · [Repr]/[Measured] provenance
discipline · constitutive library separation · card refuses calibration/validation/
disposition claims · ode15s selection sensible (evidence, not solver, was the gap).

## States
x = [i, x_p, v, P(gauge), T_w, T_f, p_s1, p_s2].

## Agreed development sequence (2026-07-18 decision)
- **v0.2.1 — truth & verification repair (BEFORE new physics):** relabels above;
  reproducible runner + buildfile + hashes; vector AbsTol; trajectory-level
  convergence incl. event times; all-time contact/floor/range/NaN assertions;
  full multiphysics energy ledger with force active (expected FAIL against
  v0.2-alpha — documents defect 1 until v0.3 closes it); all magic numbers to
  parameters with provenance; seated-equilibrium ICs; solver stats + Jacobian
  sparsity; stiffness metric defined + scripted.
- **v0.3 — energy-consistent EM + driver:** λ(i,x,T)/co-energy force from
  FEMM/OctaveFEMM sweeps (mesh-convergence checked); averaged current-regulated
  driver with PI/hysteresis, supply + voltage-compliance limits, PWM duty +
  flyback, sense dynamics/offsets, protections. NO algebraic i=Icmd shortcut.
- **v0.4 — thermal/hydraulic boundary repair:** measured bath/inlet temperature
  boundary or enthalpy flow; V(x); signed flows incl. reverse; Wu's actual Cd
  structure; overlap/underlap + flow force; seated contact + breakaway/Stribeck/
  viscous/dither friction modes. Aeration/cavitation states stay behind a
  fidelity switch until data reject single-phase.
- **Identifiability program:** seven dedicated experiments (locked-spool current
  steps over gap/T; no-flow force ramp; trapped-volume decay over T; bidirectional
  steady flow sweeps; dither + dwell; synchronized pressure step/pulse cal;
  bath-temperature sweep), full signals, noise-weighted, stacked; profile
  likelihood on survivors [Raue2009][Litwin2022].

## Run manifest (V0, partial — runner pending v0.2.1)
model v0.2-alpha · RD03-P-0002 · MATLAB R2026a U3 ode15s (RelTol 1e-6/AbsTol 1e-9
scalar — to be vectorized) · IC zeros(8,1) 25 °C (NOT seated equilibrium — defect 4)
· cross-reproduced in SciPy/BDF (Sol 5.6, 2026-07-18).

## Parameter policy
Unchanged: structure from sources; all coefficients/thresholds/limits bench-owned;
unidentifiable parameters reported as such, never regularized into false certainty.
