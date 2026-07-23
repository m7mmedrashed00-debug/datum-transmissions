// DTC RD-03 C0 v2 Mesh-Convergence Report — .docx twin of the PDF
const fs = require('fs');
const D = require('docx');
const {Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
       WidthType, ShadingType, ImageRun, HeadingLevel, AlignmentType,
       BorderStyle, Footer, PageNumber} = D;

const ORANGE='F2541B', GRAPH='1C1F26', STEEL='8A929B', ROW='F3F4F5', GRID='D8DBDE';
const PAGEW = 12240-1440*2; // usable DXA at 1in margins... use letter-ish width in DXA for A4: 11906-2*1021 ≈ 9864
const USE_W = 9800;

function tr(text, o={}) { return new TextRun(Object.assign({text, font:'Helvetica', size:19, color:GRAPH}, o)); }
function p(text, o={}, ro={}) {
  return new Paragraph(Object.assign({children:[tr(text, ro)], spacing:{after:120}}, o));
}
function eyebrow(t){ return new Paragraph({children:[tr(t,{bold:true,size:15,color:ORANGE})],spacing:{after:80}}); }
function h1(t){ return new Paragraph({heading:HeadingLevel.HEADING_1, spacing:{before:260,after:120},
  children:[tr(t,{bold:true,size:28,color:GRAPH})]}); }
function h2(t){ return new Paragraph({heading:HeadingLevel.HEADING_2, spacing:{before:180,after:90},
  children:[tr(t,{bold:true,size:22,color:GRAPH})]}); }
function cap(t){ return new Paragraph({children:[tr(t,{italics:true,size:16,color:STEEL})],spacing:{after:180}}); }
function mono(t,o={}){ return new TextRun(Object.assign({text:t,font:'Courier New',size:17,color:GRAPH},o)); }

function tbl(rows, widths) {
  const total = widths.reduce((a,b)=>a+b,0);
  const cw = widths.map(w=>Math.round(USE_W*w/total));
  return new Table({
    width:{size:USE_W,type:WidthType.DXA}, columnWidths:cw,
    rows: rows.map((r,i)=> new TableRow({children: r.map((c,j)=> new TableCell({
      width:{size:cw[j],type:WidthType.DXA},
      shading: i===0? {type:ShadingType.CLEAR, fill:GRAPH} : (i%2===0? {type:ShadingType.CLEAR, fill:ROW}:undefined),
      margins:{top:60,bottom:60,left:80,right:80},
      children:[new Paragraph({children:[ i===0? tr(String(c),{bold:true,color:'FFFFFF',size:17})
                                                : tr(String(c),{size:17}) ]})]
    }))}))
  });
}
function img(path, wpx, hpx) {
  const W = 655;                                  // full text width at 96 dpi
  return new Paragraph({alignment:AlignmentType.CENTER,
    children:[new ImageRun({type:'png', data: fs.readFileSync(path),
    transformation:{width:W, height:Math.round(W*hpx/wpx)}})],
    spacing:{before:80,after:40}});
}

const sizeOf = require('image-size');
let EQN = 0;
function eqp(name, numbered=true) {
  // centered display equation image; equation number right-aligned via tab
  const path = `eqs/${name}.png`;
  const dim = sizeOf.imageSize ? sizeOf.imageSize(fs.readFileSync(path)) : sizeOf(path);
  const wpx = dim.width, hpx = dim.height;
  const targetW = Math.min(430, Math.round(wpx/300*96*0.85));   // px at 96dpi
  const targetH = Math.round(targetW*hpx/wpx);
  const children = [new ImageRun({type:'png', data: fs.readFileSync(path),
      transformation:{width:targetW, height:targetH}})];
  if (numbered) { EQN += 1; children.push(new TextRun({text:`\t(${EQN})`, font:'Helvetica', size:20, color:GRAPH})); }
  return new Paragraph({alignment:AlignmentType.CENTER,
    tabStops:[{type:D.TabStopType.RIGHT, position:USE_W-100}],
    children, spacing:{before:100,after:100}});
}

const F = (n)=>`figs/${n}.png`;
const kids = [];
kids.push(eyebrow('DATUM TRANSMISSION CO. - R&D REPORT - RD-03 C0 VERIFICATION GATE - FOR SOL 5.6 RE-AUDIT'));
kids.push(new Paragraph({children:[tr('RD-03 C0 Gate v2: Mesh-Convergence Study',{bold:true,size:46})],spacing:{after:100}}));
kids.push(p('FEMM/MATLAB extraction-and-solver verification rebuilt to the SOL-RD03-C0e-R stop-ship list: manufactured-solution operator certification, five-mesh coax known-answer family with co-refined arc discretization, four-mesh axisymmetric loop family against elliptic-integral quadrature references, Richardson/GCI machinery meta-verified against exact solutions, and the FEMM convention set locked by experiment. Family-agnostic: relationships and methods only.',{},{color:STEEL}));
kids.push(tbl([
 ['Field','Value'],
 ['Milestone','C0 verification gate v2 — ALL GATES PASS. Coax energy in asymptotic range (ratio 1.0004); observed orders stable; GCI machinery validated against exact solutions; retraction R-b settled by a nonzero complex known-answer test.'],
 ['Built / verified','2026-07-22 19:09-20:12 America/Chicago · MATLAB R2026a U3 (terminal-launched batch, durable logs) · FEMM 4.2 21Apr2019 x64 (femm.exe SHA-256 matches audit record).'],
 ['Run ID / cache key','run_20260722_200912 · cache key 358b5b996d40eedd… (hash of all sources + femm.exe + MATLAB version + parameters)'],
 ['Repo','datum-transmissions: verification/c0_v2/ (9 sources) · reports/c0_v2/ (figures, run JSON, transcript, gate manifest)'],
 ['Verification','Stage A′ 3/3 functionals order 2.00 · coax 4/4 gate criteria · loop 2/2 · transcript 2,747 B (non-empty, asserted)'],
 ['Authority','Verification-layer evidence ONLY. No application adequacy claimed: decision-layer thresholds await the S2b error budget [NISTIR8298 posture]. Every value is [Measured] from this run unless tagged.']],[30,144]));

kids.push(h1('01 / Scope and posture'));
kids.push(p('What this buys Datum: a trustworthy FEMM+MATLAB verification gate is the prerequisite for the C0 dynamic-magnetics decision (eddy branch vs. diffusion state) that RD-03P’s dynamic-current screen depends on. Two prior FEMM campaigns (v2–v5) were lost to extraction defects this gate class would have caught.'));
kids.push(p('Sol 5.6’s adversarial audit (SOL-RD03-C0e-R, 2026-07-22) returned HOLD with five stop-ship defects and a corrected mesh-study design. This report is the rebuilt gate, rerun from scratch, with every P0 repair landed and the audit’s Q1–Q8 answers folded in. Every claim carries its number; every number traces to a sample calculation in Appendix A; the evidence bundle is immutable.'));
kids.push(p('Two-layer threshold policy (audit Q3): this report exercises the VERIFICATION gate (exact/manufactured targets, order behavior, asymptotic range). The DECISION gate is not exercised — it requires the S2b error budget, blocked on shop data only Mohammed can supply.'));

kids.push(h1('02 / Corrections adopted from SOL-RD03-C0e-R'));
kids.push(tbl([
 ['Audit item','Disposition in v2'],
 ['P0-1 fail-closed runner','Every stage gate computed, persisted, then ASSERTED; gate_manifest.json carries pass bits + cache key; failed gates still leave the full evidence bundle.'],
 ['P0-2 hash-bound provenance','Cache key = SHA-256 over all 9 sources + femm.exe + MATLAB version + parameter struct. femm.exe hash verified EQUAL to audit-recorded 5e83cf08…21 at run time.'],
 ['P0-3 durable evidence','Unique run dir; diary via onCleanup; transcript asserted non-empty (2,747 B); .fem/.ans retained; results.mat + report_numbers.json.'],
 ['P0-4 Stage A′ manufactured solution','A_z = A0 sin(kx x) sin(ky y); all three functionals nontrivial; accuracy AND order enforced (2.001/2.001/2.000).'],
 ['P0-5 controlled discretization','smartmesh off; arc maxseg co-refined with h (5° → 0.31°); realized element counts and ratios recorded; smoothing OFF and ON both measured.'],
 ['Q5 contour policy','Angle-halving study 4°→0.25° × 3 radii × 3 offsets × smoothing: anglestep-independent; smoothing state dominates; “contour floor” refuted.'],
 ['M2 singular reference','Finite 1×1 mm source; exact-kernel quadrature reference (integral2 tol 1e-11); filament-vs-quadrature shift measured at 2.39e-5.'],
 ['M2 outer boundary','7-shell ABC at 0.12 m + truncation check at 0.18 m: ΔΦ 9.8e-3, Δ|B| 1.3e-2 at mid mesh — reported, not hidden.']],[45,129]));
kids.push(p('Not yet landed (next iteration, per audit sequencing): nonlinear manufactured constitutive case; slab v6 complex-field benchmark; per-artifact .ans hashing.'));

kids.push(h1('03 / Theory and exact references'));
kids.push(h2('03.1 Coax known-answer set'));
kids.push(p('Infinite coaxial line (planar 2-D, depth 1 m), inner conductor a = 5 mm carrying I = 100 A, return shell 20–22 mm. Ampère’s law on a circle of radius r in the air annulus gives the field, and the exact targets follow by integration (values plugged step-by-step in App. A.1–A.3):'));
kids.push(eqp('eq01')); kids.push(eqp('eq02')); kids.push(eqp('eq03')); kids.push(eqp('eq04'));
kids.push(p('Evaluated: E = 1.386294361e-3 J/m; upper-half ∫Bx dA = −6.000000e-7 Wb/m; I_enc = 100 A. The half-annulus split in Eq. (3) gives the vector block integrals (FEMM types 8/9) NONZERO exact targets — the operator-level test the audit found missing (defect 13).'));
kids.push(h2('03.2 Manufactured solution for Stage A′'));
kids.push(p('Following [Salari&Knupp2000], the field derives from a vector potential chosen so no tested functional is exact by construction (A₀ = 1e-3 Wb/m, k_x = 37, k_y = 59 m⁻¹):'));
kids.push(eqp('eq05')); kids.push(eqp('eq06')); kids.push(eqp('eq07'));
kids.push(p('Closed-form targets over [25,85]×[15,65] mm (App. A.7): T1 = −6.117585e-5 Wb/m, T2 = 1.583262 J/m, T3 = 3971.499 A.'));
kids.push(h2('03.3 Axisymmetric loop references'));
kids.push(p('Circular filament of radius a in plane z = z_s, observed at (r, z) [NASA-Loop2013]:'));
kids.push(eqp('eq08')); kids.push(eqp('eq09')); kids.push(eqp('eq10')); kids.push(eqp('eq11')); kids.push(eqp('eq12'));
kids.push(p('The benchmark source is a finite 1×1 mm cross-section at (30, 0) mm; references integrate the kernels of Eqs. (9)–(11) over that cross-section (integral2, RelTol 1e-11), so no singular filament energy enters (audit defect 10). ellipke (m = k²) validated to 2.2e-16 against independent 30-digit values (App. A.8) [NIST-DLMF19].'));
kids.push(h2('03.4 Order, Richardson, GCI'));
kids.push(p('For grids 1 (fine), 2, 3 with realized ratios r₂₁, r₃₂ [NASA-GCI]:'));
kids.push(eqp('eq13')); kids.push(eqp('eq14')); kids.push(eqp('eq15')); kids.push(eqp('eq16'));
kids.push(p('Because the coax truth is known exactly, the machinery is META-VERIFIED in §05.3: the extrapolate must beat the finest mesh and GCI must bound the TRUE error.'));
kids.push(h2('03.5 FEMM harmonic conventions under test'));
kids.push(p('FEMM harmonic problems solve for peak-amplitude phasors. For a linear lossless inductor at equal numeric current:'));
kids.push(eqp('eq17'));
kids.push(p('Field-phasor integrals (bi8) should instead preserve amplitude (ratio 1). Both predictions tested at four frequencies in §05.5; complex capability (R-b) tested against the complex form of Eq. (3) with Î = 100∠30° (App. A.11).'));

kids.push(h1('04 / Method — harness v2 architecture'));
kids.push(tbl([
 ['Element','Implementation'],
 ['Gate order','Stage A′ (no solver) → asserted → coax family → loop family → probes.'],
 ['Coax family','5 meshes h = 4/2/1/0.5/0.25 mm, maxseg 5°→0.3125°, elements 2,498→132,262 (realized ratios 1.54/1.53/1.73/1.78).'],
 ['Loop family','4 meshes h = 8/4/2/1 mm (coil h/8), 4,194→57,472 el.; ABC 7 shells @0.12 m; truncation check @0.18 m; 6 probes ≥14 mm from source.'],
 ['Smoothing policy','mo_smooth OFF and ON measured for every point/contour observable; authoritative state declared per observable (§05.4).'],
 ['Probes','ω-sequence 0.01/0.1/1/10 Hz (σ=0); harmonic bi8 ratio; P4 complex-circuit marshaling with exact complex target; mo_geta convention probe.'],
 ['Evidence','transcript.log (asserted non-empty) · results.mat · report_numbers.json · gate_manifest.json · 11 retained .fem/.ans · 12 figures.']],[35,139]));

kids.push(h1('05 / Results'));
kids.push(h2('05.1 Stage A′ — operators certified on the manufactured field'));
kids.push(tbl([
 ['N','T1 ∫Bx dA','T2 energy','T3 circulation'],
 ['12','3.954e-03','4.936e-04','3.471e-03'],
 ['25','9.092e-04','1.134e-04','7.993e-04'],
 ['50','2.272e-04','2.832e-05','1.998e-04'],
 ['100','5.680e-05','7.080e-06','4.995e-05'],
 ['200','1.420e-05','1.770e-06','1.249e-05'],
 ['400','3.550e-06','4.425e-07','3.122e-06'],
 ['fitted order','2.001','2.001','2.000']],[30,48,48,48]));
kids.push(p('All three functionals converge at theoretical order 2; production-grid errors ≤1.42e-5. PASS with order ENFORCED. The historical v4/v5 failures (159%/193%) remain attributable to operator construction (audit C2 replacement).'));
kids.push(img(F('F1_stageA_convergence'),1500,950)); kids.push(cap('Fig. F1 — Stage A′ manufactured-solution self-test: all three operators on slope −2.'));

kids.push(h2('05.2 Coax mesh family — five levels, co-refined arcs'));
kids.push(tbl([
 ['h (mm)','maxseg (°)','N_el','E rel.err','bi8 rel.err','Ampère (off)','Ampère (on)','max|B|pt (off)','max|B|pt (on)'],
 ['4.0','5','2,498','6.236e-3','1.055e-3','2.570e-2','—','1.067e-1','—'],
 ['2.0','2.5','5,928','3.938e-3','4.655e-4','1.140e-2','—','1.192e-1','—'],
 ['1.0','1.25','13,868','1.550e-3','8.186e-5','4.040e-3','—','4.971e-2','—'],
 ['0.5','0.625','41,584','5.068e-4','1.007e-5','2.008e-4','—','2.857e-2','—'],
 ['0.25','0.3125','132,262','1.533e-4','5.356e-6','8.309e-4','7.437e-5','1.551e-2','3.228e-3']],
 [16,18,20,22,22,24,22,24,24]));
kids.push(img(F('F2_coax_convergence'),1500,950)); kids.push(cap('Fig. F2 — Coax family convergence: energy and bi8 monotone; smoothing-OFF Ampère bottoms near 2e-4 and rebounds at the finest mesh.'));

kids.push(h2('05.3 Convergence, Richardson, GCI — meta-verified'));
kids.push(tbl([
 ['Observable','p fit(all)','p fit(3)','p blind','GCI_fine','Asym ratio','True finest','Richardson'],
 ['Energy','1.365','1.669','1.561','2.266e-4','1.0004 (IN)','1.533e-4','2.794e-5'],
 ['bi8 upper','2.077','1.97','3.93*','4.146e-7','1.0000 (IN)','5.356e-6','5.024e-6'],
 ['Ampère (off)','1.573','1.141','n/a','1.069e-3','1.866 (OUT)','8.309e-4','—'],
 ['|B| pts (off)','0.763','—','—','—','—','1.551e-2','—']],
 [28,18,18,18,24,24,24,24]));
kids.push(p('Meta-verification on energy: blind p reproduces the hand calculation exactly; Richardson lands 5.5× closer to truth than the finest mesh; GCI_fine (2.27e-4) BOUNDS the true error (1.53e-4) by 1.48×. (*bi8 blind p reflects a near-converged triplet at roundoff; exact-aware 2.08 is authoritative.) No continuum claim for observables outside the asymptotic range (audit Q4).'));
kids.push(img(F('F3_orders_asymptotic'),1500,950)); kids.push(cap('Fig. F3 — Observed orders; energy passes the asymptotic-range check at 1.0004.'));
kids.push(img(F('F4_richardson_meta'),1500,950)); kids.push(cap('Fig. F4 — Richardson meta-verification: extrapolate beats finest mesh; GCI is conservative.'));

kids.push(h2('05.4 Ampère contour study — Q5 answered with data'));
kids.push(p('Error is FLAT in anglestep (4°→0.25°, <2% variation) in both smoothing states — polygonal quadrature is NOT the mechanism; O-3 refuted. Smoothing moves the error an order of magnitude: 4.66e-3 (off) vs 5.0e-4 (on) at h = 1 mm; 8.3e-4 vs 7.4e-5 at the finest family mesh. Declared v6 policy: smoothed field authoritative for contour/point observables; OFF channel retained as sentinel.'));
kids.push(img(F('F5_contour_study'),1500,950)); kids.push(cap('Fig. F5 — Contour study: flat in anglestep, separated by smoothing state.'));

kids.push(h2('05.5 Convention set — locked by experiment'));
kids.push(tbl([
 ['Convention','Test','Result','Reading'],
 ['Harmonic energy','E_harm/E_static, σ=0, 4 freqs','0.4999999999974 (all)','Peak phasors; bi2 = time-averaged energy; ×2 only for same-peak comparisons.'],
 ['Field-phasor integrals','|bi8|_harm/|bi8|_static','0.99992 (all)','Amplitude-preserving; NO ½ on field integrals.'],
 ['Complex capability (R-b)','P4: I = 100∠30°','Round-trip exact; bi8 = −5.195727e-7−2.9997544e-7i vs exact −5.19615e-7−3.0000e-7i (mag err 8e-5, phase <0.01°)','blockintegral(8/9) IS complex-capable; R-b SETTLED — earlier real-zeros were symmetry artifacts.'],
 ['Axisym potential','mo_geta vs both readings','2πrA reading matches at 2.4e-4; A reading off by 0.796','mo_geta returns modified potential 2πrA (circle flux); all v6 axisym extraction must use this.']],
 [26,34,52,62]));
kids.push(img(F('F8_omega_ratio'),1500,950)); kids.push(cap('Fig. F8 — ω-sequence at σ=0: harmonic/static energy ratio = 0.5 to 12 digits at four frequencies.'));

kids.push(h2('05.6 Axisymmetric loop family'));
kids.push(tbl([
 ['h_air (mm)','N_el','Φ max rel.err','|B| max rel.err'],
 ['8','4,194','2.245e-2','4.654e-2'],
 ['4','6,169','1.666e-2','3.438e-2'],
 ['2','14,892','2.352e-3','1.278e-2'],
 ['1','57,472','5.483e-4','3.225e-3'],
 ['4 (ABC @0.18 m)','9,628','6.822e-3','2.114e-2']],[40,30,50,54]));
kids.push(p('Orders p_Φ = 1.89, p_B = 1.30; finest 5.5e-4 / 3.2e-3. Truncation deltas at mid mesh (9.8e-3 / 1.3e-2) are comparable to mid-mesh discretization error — the coarse end mixes domain and mesh error (audit defect 11). LIMITATION: repeat the truncation sequence at the finest mesh next iteration; no GCI claimed for the loop family.'));
kids.push(img(F('F9_loop_convergence'),1500,950)); kids.push(cap('Fig. F9 — Loop family convergence with ABC truncation delta annotated.'));

kids.push(h2('05.7 Field and error surfaces'));
kids.push(img(F('F6a_coax_B_analytic_3d'),1500,1000)); kids.push(cap('Fig. F6a — Analytic |B| reference surface over the coax annulus (mT).'));
kids.push(img(F('F6b_coax_error_3d'),1500,1000)); kids.push(cap('Fig. F6b — Pointwise |B| relative-error surface (%), finest mesh, 2,592 samples.'));
kids.push(img(F('F7a_loop_flux_3d'),1500,1000)); kids.push(cap('Fig. F7a — Loop mo_geta surface (µWb): recorded convention 2πrAφ (circle flux).'));
kids.push(img(F('F7b_loop_B_3d'),1500,1000)); kids.push(cap('Fig. F7b — Loop |B| magnitude surface (log10), source tube excluded.'));

kids.push(h1('06 / Uncertainty accounting'));
kids.push(tbl([
 ['Error term','Where measured','Magnitude (this run)','Status'],
 ['Spatial discretization (coax E)','GCI_fine, asym range verified','2.27e-4 (bounds true 1.53e-4)','QUANTIFIED'],
 ['Spatial discretization (bi8)','order 2.08, GCI 4.1e-7','5.4e-6 true at finest','QUANTIFIED'],
 ['Contour/point extraction','smoothing channels + anglestep sweep','7.4e-5 (on) / 8.3e-4 (off)','QUANTIFIED, policy declared'],
 ['Geometry (arc) discretization','maxseg co-refined ∝ h','absorbed in order (1.67 last-3 vs 1.36 all-5)','CONTROLLED'],
 ['Domain truncation (loop)','ABC 0.12 vs 0.18 m, mid mesh','ΔΦ 9.8e-3, Δ|B| 1.3e-2','MEASURED; finest-mesh sequence OWED'],
 ['Reference uncertainty','integral2 tol; ellipke vs 30-digit','≤1e-11; 2.2e-16','NEGLIGIBLE'],
 ['Solver tolerance','FEMM precision 1e-8 fixed','not varied this run','OWED (v6 sweep)'],
 ['Application adequacy','—','—','NOT CLAIMED — awaits S2b error budget [TBD]']],
 [38,48,48,40]));

kids.push(h1('07 / Handoff'));
kids.push(tbl([
 ['Item','State'],
 ['State','Gate v2 PASSES all declared verification-layer criteria. Evidence immutable (run dir + repo mirror). Conventions locked (energy ½, field 1, geta = 2πrA, complex bi8). R-b settled. Contour floor refuted; smoothing policy declared.'],
 ['Open questions','(1) Loop truncation at finest mesh. (2) Solver-tolerance sweep. (3) Nonlinear manufactured case before saturation-dependent M3 conclusions. (4) Sol re-audit. (5) Adopt smoothed channel for Ampère gating (proposed: yes).'],
 ['Next gate','Sol 5.6 re-audit (SOL-RD03-C0f) → M3 probe matrix (linked incremental AC, bias sweep) and M4 slab v6 (complex fields, 2 kHz grid, wrapped phase) on the verified extraction stack.'],
 ['Measurements needed (Mohammed only)','None for this gate. Decision gate still needs S2b shop data. MATLAB license remains DEMO/trial — resolve before commercial use.']],[35,139]));

kids.push(h1('Appendix A / Sample calculations'));
kids.push(p('Every number in the body traces to a hand calculation below, with values plugged explicitly. Constants: μ₀ = 4π×10⁻⁷ H/m; I = 100 A; a = 5 mm; b₁ = 20 mm.'));
const SC = [
 ['A.1 Coax annulus energy (§03.1, §05.2)','Substituting into Eq. (2):',['a1_1','a1_2']],
 ['A.2 Half-annulus ∫Bx target (§03.1)','With B = Bφ(−sinθ, cosθ) over the upper half-annulus, Eq. (3):',['a2_1','a2_2']],
 ['A.3 Relative error, finest coax energy (§05.2)','',['a3_1']],
 ['A.4 Blind three-grid observed order (§05.3)','Fine triplet f₁ = 1.3860818e-3, f₂ = 1.3855918e-3, f₃ = 1.3841461e-3 (r = 2), in Eq. (13):',['a4_1','a4_2']],
 ['A.5 Richardson extrapolation (§05.3)','Applying Eq. (14) with p = 1.5608:',['a5_1','a5_2']],
 ['A.6 GCI and asymptotic-range check (§05.3)','Applying Eqs. (15)–(16):',['a6_1','a6_2','a6_3','a6_4']],
 ['A.7 Manufactured-solution targets (§03.2)','Closed-form antiderivatives of Eqs. (5)–(7) over [25,85]×[15,65] mm:',['a7_1','a7_2']],
 ['A.8 ellipke validation (§03.3)','',['a8_1','a8_2']],
 ['A.9 Loop flux target and finite-cross-section effect (§03.3)','Filament a = 30 mm, probe (20, 10) mm, via Eqs. (8) and (12):',['a9_1','a9_2','a9_3']],
 ['A.10 Harmonic ½-convention arithmetic (§05.5)','From Eq. (17) at equal numeric current:',['a10_1','a10_2']],
 ['A.11 P4 complex target (§05.5, R-b closure)','Complex form of Eq. (3) with the phased circuit current:',['a11_1','a11_2','a11_3']],
 ['A.12 Realized refinement ratios and skin depths (§04, §07)','Realized ratios from element counts; skin depth from Eq. (18) at 5 kHz [Representative — VERIFY]:',['a12_1','a12_2']]];
for (const [t, lead, ims] of SC) {
  kids.push(h2(t));
  if (lead) kids.push(p(lead));
  for (const nm of ims) kids.push(eqp(nm, false));
}

kids.push(h1('Appendix B / Run manifest and provenance'));
kids.push(tbl([
 ['Item','Value'],
 ['Run ID','run_20260722_200912 (2026-07-22 20:09:12 America/Chicago)'],
 ['Cache key','358b5b996d40eedd… (SHA-256 over 9 source hashes + femm.exe + MATLAB version + params)'],
 ['femm.exe SHA-256','5e83cf0899cabae2017868ddcce338e3ba4ac25d1bf8e511eac77eda2bc92a21 — EQUAL to Sol’s C0e-R record'],
 ['MATLAB','R2026a U3 — DEMO/trial license [licensing gate]'],
 ['Gate manifest','{stageA:true, coax:true, loop:true, femm_exe_matches_audit:true}'],
 ['Evidence','11 .fem/.ans · transcript 2,747 B · results.mat · report_numbers.json · 12 figures · gate_manifest.json'],
 ['Cite','[Salari&Knupp2000],[NASA-GCI],[NASA-Loop2013],[NIST-DLMF19],[NISTIR8298],[Meeker-FEMM],[Sol 5.6 — 2026-07-22, SOL-RD03-C0e-R]; Sol rows Inbox/provisional; all run values [Measured].']],[30,144]));

const doc = new Document({
  styles:{default:{document:{run:{font:'Helvetica',size:19,color:GRAPH}}}},
  sections:[{
    properties:{page:{size:{width:11906,height:16838},margin:{top:1021,bottom:1134,left:1021,right:1021}}},
    footers:{default:new Footer({children:[new Paragraph({
      children:[tr('DATUM TRANSMISSION CO.   ·   Diagnosed. Rebuilt to spec. Verified.        ',{size:15,color:STEEL}),
                new TextRun({children:[PageNumber.CURRENT],font:'Helvetica',size:15,color:STEEL})]})]})},
    children:kids}]
});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync('DTC_RD03_C0v2_MeshConvergence_Report.docx',b);console.log('DOCX built',b.length);});
