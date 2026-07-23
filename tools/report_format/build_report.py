#!/usr/bin/env python3
"""DTC RD-03 C0 v2 Mesh-Convergence Report — Datum R&D brief format
(mirrors RD-03_Model_Spine_Brief_v0.1 layout: orange eyebrow, big title,
dark-header tables, '0x / Section' heads, italic captions, branded footer)."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph,
                                Spacer, Table, TableStyle, Image, PageBreak,
                                KeepTogether)
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT

ORANGE  = HexColor('#F2541B'); GRAPH = HexColor('#1C1F26')
STEEL   = HexColor('#8A929B'); BONE  = HexColor('#F5F5EF')
LGRID   = HexColor('#D8DBDE'); ROWALT = HexColor('#F3F4F5')

W, H = A4
MX = 18*mm
CW = W - 2*MX

S = {
 'eyebrow': ParagraphStyle('eyebrow', fontName='Helvetica-Bold', fontSize=8.2,
            textColor=ORANGE, spaceAfter=4, leading=10),
 'title':   ParagraphStyle('title', fontName='Helvetica-Bold', fontSize=23,
            textColor=GRAPH, leading=27, spaceAfter=5),
 'subtitle':ParagraphStyle('subtitle', fontName='Helvetica', fontSize=9.6,
            textColor=STEEL, leading=13.5, spaceAfter=10),
 'h1':      ParagraphStyle('h1', fontName='Helvetica-Bold', fontSize=14.5,
            textColor=GRAPH, spaceBefore=13, spaceAfter=6, leading=17),
 'h2':      ParagraphStyle('h2', fontName='Helvetica-Bold', fontSize=11,
            textColor=GRAPH, spaceBefore=9, spaceAfter=4),
 'body':    ParagraphStyle('body', fontName='Helvetica', fontSize=9.4,
            textColor=GRAPH, leading=13.4, spaceAfter=6, alignment=TA_LEFT),
 'bodyb':   ParagraphStyle('bodyb', fontName='Helvetica-Bold', fontSize=9.4,
            textColor=GRAPH, leading=13.4, spaceAfter=6),
 'cap':     ParagraphStyle('cap', fontName='Helvetica-Oblique', fontSize=8.2,
            textColor=STEEL, leading=11, spaceBefore=2, spaceAfter=10),
 'mono':    ParagraphStyle('mono', fontName='Courier', fontSize=8.2,
            textColor=GRAPH, leading=11.4, spaceAfter=6),
 'cell':    ParagraphStyle('cell', fontName='Helvetica', fontSize=8.4,
            textColor=GRAPH, leading=11),
 'cellb':   ParagraphStyle('cellb', fontName='Helvetica-Bold', fontSize=8.4,
            textColor=white, leading=11),
 'cellm':   ParagraphStyle('cellm', fontName='Courier', fontSize=8.0,
            textColor=GRAPH, leading=10.6),
 'cite':    ParagraphStyle('cite', fontName='Helvetica-Oblique', fontSize=7.8,
            textColor=STEEL, leading=10.5, spaceBefore=10),
}


from PIL import Image as PILImage
EQN = [0]
def eqn(name, numbered=True, scale=0.80):
    """Centered display equation image + right-aligned (n)."""
    path = f'eqs/{name}.png'
    with PILImage.open(path) as im:
        wpx, hpx = im.size
    wpt = wpx/300.0*72*scale
    maxw = CW - 16*mm
    if wpt > maxw:
        wpt = maxw
    hpt = wpt*hpx/wpx
    img = Image(path, width=wpt, height=hpt)
    if numbered:
        EQN[0] += 1
        num = Paragraph(f'({EQN[0]})', ParagraphStyle('eqn', fontName='Helvetica',
                        fontSize=10, textColor=GRAPH, alignment=2))
        t = Table([[img, num]], colWidths=[CW-14*mm, 14*mm])
    else:
        t = Table([[img, '']], colWidths=[CW-14*mm, 14*mm])
    t.setStyle(TableStyle([('ALIGN',(0,0),(0,0),'CENTER'),
                           ('VALIGN',(0,0),(-1,-1),'MIDDLE'),
                           ('TOPPADDING',(0,0),(-1,-1),4),
                           ('BOTTOMPADDING',(0,0),(-1,-1),4)]))
    return t

def footer(canv, doc):
    canv.saveState()
    canv.setStrokeColor(LGRID); canv.setLineWidth(0.6)
    canv.line(MX, 14*mm, W-MX, 14*mm)
    canv.setFont('Helvetica', 7.6); canv.setFillColor(STEEL)
    canv.drawString(MX, 10.2*mm,
        'DATUM TRANSMISSION CO.   ·   Diagnosed. Rebuilt to spec. Verified.')
    canv.drawRightString(W-MX, 10.2*mm, str(canv.getPageNumber()))
    canv.restoreState()

doc = BaseDocTemplate('DTC_RD03_C0v2_MeshConvergence_Report.pdf', pagesize=A4,
        leftMargin=MX, rightMargin=MX, topMargin=16*mm, bottomMargin=20*mm,
        title='RD-03 C0 v2 Mesh-Convergence Verification Report',
        author='Datum Transmission Co.')
doc.addPageTemplates([PageTemplate(id='main',
    frames=[Frame(MX, 20*mm, CW, H-36*mm, id='f')], onPage=footer)])

def T(data, widths, header=True, mono_cols=(), align_right=()):
    rows = []
    for i, row in enumerate(data):
        out = []
        for j, cell in enumerate(row):
            if i == 0 and header: st = S['cellb']
            elif j in mono_cols:  st = S['cellm']
            else:                 st = S['cell']
            out.append(Paragraph(str(cell), st))
        rows.append(out)
    t = Table(rows, colWidths=widths, repeatRows=1 if header else 0)
    style = [('GRID',(0,0),(-1,-1),0.5,LGRID),
             ('VALIGN',(0,0),(-1,-1),'TOP'),
             ('TOPPADDING',(0,0),(-1,-1),3.2),('BOTTOMPADDING',(0,0),(-1,-1),3.2),
             ('LEFTPADDING',(0,0),(-1,-1),5),('RIGHTPADDING',(0,0),(-1,-1),5)]
    if header:
        style += [('BACKGROUND',(0,0),(-1,0),GRAPH)]
        style += [('ROWBACKGROUNDS',(0,1),(-1,-1),[white, ROWALT])]
    else:
        style += [('ROWBACKGROUNDS',(0,0),(-1,-1),[white, ROWALT])]
    t.setStyle(TableStyle(style)); return t

def fig(path, cap, wfrac=1.0):
    img = Image(path, width=CW*wfrac, height=CW*wfrac*1000/1560)
    return [img, Paragraph(cap, S['cap'])]

def fig3(path, cap, wfrac=1.0):
    img = Image(path, width=CW*wfrac, height=CW*wfrac*1040/1560)
    return [img, Paragraph(cap, S['cap'])]

E = []
A = E.append

# ================= header =================
A(Paragraph('DATUM TRANSMISSION CO. - R&amp;D REPORT - RD-03 C0 VERIFICATION GATE - FOR SOL 5.6 RE-AUDIT', S['eyebrow']))
A(Paragraph('RD-03 C0 Gate v2: Mesh-Convergence Study', S['title']))
A(Paragraph('FEMM/MATLAB extraction-and-solver verification rebuilt to the SOL-RD03-C0e-R stop-ship list: '
  'manufactured-solution operator certification, five-mesh coax known-answer family with co-refined arc '
  'discretization, four-mesh axisymmetric loop family against elliptic-integral quadrature references, '
  'Richardson/GCI machinery meta-verified against exact solutions, and the FEMM convention set locked by '
  'experiment. Family-agnostic: relationships and methods only, no family numbers, no part numbers, no prices.', S['subtitle']))

A(T([['Field','Value'],
 ['Milestone','C0 verification gate v2 — ALL GATES PASS. Coax energy in the asymptotic range (ratio 1.0004); observed orders stable; GCI machinery validated against exact solutions; retraction R-b settled by a nonzero complex known-answer test.'],
 ['Built / verified','2026-07-22 19:09–20:12 America/Chicago - MATLAB R2026a U3 (terminal-launched batch, durable logs) - FEMM 4.2 21Apr2019 x64 (femm.exe SHA-256 matches the C0e-R audit record).'],
 ['Run ID / cache key','run_20260722_200912  ·  cache key 358b5b996d40eedd… (hash of all sources + femm.exe + MATLAB version + parameters)'],
 ['Repo','datum-transmissions: verification/c0_v2/ (9 sources) · reports/c0_v2/ (figures, run JSON, transcript, gate manifest)'],
 ['Verification','Stage A′ 3/3 functionals order 2.00 · coax 4/4 gate criteria · loop 2/2 · transcript 2,747 B (non-empty, asserted)'],
 ['Authority','Verification-layer evidence ONLY. No application adequacy is claimed: decision-layer thresholds await the S2b error budget [NISTIR8298 posture]. Every value below is [Measured] from this run unless tagged otherwise.']],
 [30*mm, CW-30*mm]))
A(Spacer(1,6))

# ================= 01 =================
A(Paragraph('01 / Scope and posture', S['h1']))
A(Paragraph('<b>What this buys Datum:</b> a trustworthy FEMM+MATLAB verification gate is the prerequisite for the '
 'C0 dynamic-magnetics decision (eddy branch vs. diffusion state) that RD-03P\'s dynamic-current screen depends on. '
 'Two prior FEMM campaigns (v2–v5) were lost to extraction defects that this gate class would have caught; the cost '
 'of NOT having it is already measured.', S['body']))
A(Paragraph('Sol 5.6\'s adversarial audit (SOL-RD03-C0e-R, 2026-07-22) returned HOLD with five stop-ship defects and '
 'a corrected design for the mesh study. This report is the rebuilt gate, rerun from scratch, with every P0 repair '
 'landed and the audit\'s Q1–Q8 design answers folded in. It is written for Sol\'s re-audit: every claim carries its '
 'number, every number carries a sample calculation in Appendix A, and the full evidence bundle (sources, .fem/.ans, '
 'transcript, manifest with hashes) is retained in an immutable run directory.', S['body']))
A(Paragraph('Two-layer threshold policy adopted from the audit (Q3): the <b>verification gate</b> (this report) uses '
 'exact/manufactured targets, observed-order behavior, and asymptotic-range checks; the <b>decision gate</b> '
 '(pass/fail against donor requirements) is NOT exercised — it requires the S2b error budget, which is blocked on '
 'shop data only Mohammed can supply.', S['body']))

# ================= 02 =================
A(Paragraph('02 / Corrections adopted from SOL-RD03-C0e-R', S['h1']))
A(T([['Audit item','Disposition in v2'],
 ['P0-1 fail-closed runner','Every stage gate computed, persisted, then ASSERTED. gate_manifest.json written with pass bits + cache key; a failed gate still leaves the full evidence bundle.'],
 ['P0-2 hash-bound provenance','Cache key = SHA-256 over all 9 sources + femm.exe + MATLAB version + parameter struct. femm.exe hash verified EQUAL to the audit-recorded 5e83cf08…21 at run time.'],
 ['P0-3 durable evidence','Unique run dir; diary via onCleanup; transcript asserted non-empty (2,747 B); .fem/.ans retained per level; results.mat + report_numbers.json.'],
 ['P0-4 Stage A′ manufactured solution','A_z = A_0 sin(k_x x) sin(k_y y); all three functionals nontrivial; accuracy AND order enforced in code (orders 2.001/2.001/2.000).'],
 ['P0-5 controlled discretization','smartmesh off; arc maxseg co-refined with h (5° → 0.31°); realized element counts and refinement ratios recorded; smoothing OFF and ON both measured.'],
 ['C2/C3/C6/C9 replacements','Accepted verbatim; C6 is now superseded by the stronger convention triple-lock in §05.5 (ratio 0.5 at four frequencies + complex round-trip).'],
 ['Q5 contour policy','Angle-halving study 4°→0.25° × 3 radii × 3 offsets × smoothing off/on. Result: anglestep-independent below 4°; smoothing state dominates (§05.4). "Contour floor" hypothesis (O-3) is REFUTED as the mechanism.'],
 ['M2 singular reference','Loop benchmark uses a finite 1×1 mm cross-section source; references are exact-kernel quadrature over that cross-section (integral2, tol 1e-11) — no filament energy anywhere. Filament-vs-quadrature difference measured at 2.39e-5 (App. A.9).'],
 ['M2 outer boundary','7-shell improvised ABC at R = 0.12 m + explicit truncation check at 0.18 m (mid mesh): ΔΦ = 9.8e-3, Δ|B| = 1.3e-2 — domain error is a live term at coarse mesh and is REPORTED, not hidden (§05.6).']],
 [44*mm, CW-44*mm]))
A(Paragraph('Not yet landed (scoped to the next iteration, per audit sequencing): nonlinear manufactured constitutive case '
 '(prerequisite for saturation-dependent M3 conclusions, not for this linear study); slab v6 complex-field benchmark; '
 'unique-run-ID artifact hashing of individual .ans files.', S['body']))

# ================= 03 =================
A(PageBreak())
A(Paragraph('03 / Theory and exact references', S['h1']))
A(Paragraph('03.1  Coax known-answer set', S['h2']))
A(Paragraph('Infinite coaxial line (planar 2-D, depth 1 m), inner conductor radius a = 5 mm carrying I = 100 A, '
 'return shell 20–22 mm. Ampère\'s law on a circle of radius r in the air annulus gives the field', S['body']))
A(eqn('eq01'))
A(Paragraph('and the exact targets follow by integration over the annulus a ≤ r ≤ b<sub>1</sub> '
 '(numerical values plugged step-by-step in App. A.1–A.3):', S['body']))
A(eqn('eq02'))
A(eqn('eq03'))
A(eqn('eq04'))
A(Paragraph('Evaluated: E = 1.386294361e-3 J/m; upper-half ∫B<sub>x</sub> dA = −6.000000e-7 Wb/m; I<sub>enc</sub> = 100 A. '
 'The half-annulus split in Eq. (3) is the v2 addition that gives the vector block integrals (FEMM types 8/9) '
 'NONZERO exact targets — the operator-level test the audit found missing (defect 13).', S['body']))
A(Paragraph('03.2  Manufactured solution for Stage A′', S['h2']))
A(Paragraph('Following the manufactured-solutions posture [Salari&amp;Knupp2000], the field derives from a vector '
 'potential chosen so that NO tested functional is exact by construction (A<sub>0</sub> = 1e-3 Wb/m, k<sub>x</sub> = 37, '
 'k<sub>y</sub> = 59 m<super>−1</super>):', S['body']))
A(eqn('eq05'))
A(eqn('eq06'))
A(eqn('eq07'))
A(Paragraph('Closed-form targets over the window [25,85] × [15,65] mm (worked in App. A.7): '
 'T1 = −6.117585e-5 Wb/m, T2 = 1.583262 J/m, T3 = 3971.499 A. Every operator must converge at its theoretical '
 'order against these targets before any solver runs.', S['body']))
A(Paragraph('03.3  Axisymmetric loop references', S['h2']))
A(Paragraph('For a circular filament of radius a in the plane z = z<sub>s</sub>, observed at (r, z), define the '
 'modulus [NASA-Loop2013]:', S['body']))
A(eqn('eq08'))
A(Paragraph('The vector potential and field components in complete-elliptic-integral form are', S['body']))
A(eqn('eq09'))
A(eqn('eq10'))
A(eqn('eq11'))
A(Paragraph('and the flux through the coaxial circle at (r, z) is Maxwell\'s mutual-inductance form', S['body']))
A(eqn('eq12'))
A(Paragraph('The benchmark source is a finite 1 × 1 mm square cross-section at (30, 0) mm carrying 100 A-turns; the '
 'references integrate the kernels of Eqs. (9)–(11) over that cross-section (integral2, AbsTol 1e-14 / RelTol 1e-11), '
 'so the reference matches the ACTUAL source and the singular self-energy of an ideal filament never enters (audit '
 'defect 10). MATLAB ellipke (m = k<super>2</super> convention) is validated to 2.2e-16 against independent 30-digit '
 'values cross-checked with the Γ(1/4) identity (App. A.8) [NIST-DLMF19].', S['body']))
A(Paragraph('03.4  Order, Richardson, GCI', S['h2']))
A(Paragraph('For grids 1 (fine), 2, 3 with realized refinement ratios r<sub>21</sub> = h<sub>2</sub>/h<sub>1</sub>, '
 'r<sub>32</sub> = h<sub>3</sub>/h<sub>2</sub>, the blind observed order p solves the generalized ratio equation (13); '
 'the Richardson extrapolate is (14); the fine-grid convergence index is (15) with F<sub>s</sub> = 1.25 for three or '
 'more grids; and the asymptotic-range check is (16) [NASA-GCI, retrieved 2026-07-23]:', S['body']))
A(eqn('eq13'))
A(eqn('eq14'))
A(eqn('eq15'))
A(eqn('eq16'))
A(Paragraph('Because the coax truth is known exactly, the machinery itself is META-VERIFIED in §05.3: the extrapolate '
 'must beat the finest mesh, and GCI must bound the TRUE error.', S['body']))
A(Paragraph('03.5  FEMM harmonic conventions under test', S['h2']))
A(Paragraph('FEMM harmonic problems solve for peak-amplitude phasors (manual Eq. 1.14 posture per the audit\'s Q8 '
 'reading). For a linear lossless inductor at equal numeric current the stored-energy prediction is', S['body']))
A(eqn('eq17'))
A(Paragraph('while field-phasor integrals (bi8) should instead preserve amplitude (ratio 1). Both predictions are '
 'tested at four frequencies in §05.5, and the complex-capability question behind retraction R-b is tested against '
 'the complex form of Eq. (3) with Î = 100∠30° (App. A.11).', S['body']))

# ================= 04 =================
A(Paragraph('04 / Method — harness v2 architecture', S['h1']))
A(T([['Element','Implementation (all [Measured] from run_20260722_200912)'],
 ['Gate order','Stage A′ (no solver) → asserted → coax family → loop family → probes. Solver runs are unreachable while Stage A′ fails.'],
 ['Coax family','5 meshes, requested h = 4/2/1/0.5/0.25 mm, arc maxseg co-refined 5°→0.3125°, elements 2,498 → 132,262 (realized ratios √(N<sub>j+1</sub>/N<sub>j</sub>) = 1.54/1.53/1.73/1.78).'],
 ['Loop family','4 meshes, air h = 8/4/2/1 mm (coil h/8), elements 4,194 → 57,472; ABC 7 shells at 0.12 m; truncation check at 0.18 m; 6 probe points ≥14 mm from source.'],
 ['Smoothing policy','mo_smooth OFF and ON measured for every point/contour observable; energy and block integrals are element sums (state recorded). Authoritative state for gating: declared per-observable in §05.4.'],
 ['Probes','ω-sequence 0.01/0.1/1/10 Hz (σ=0); harmonic bi8 ratio; P4 complex-circuit marshaling with exact complex target; mo_geta axisym convention probe (both readings scored).'],
 ['Evidence','runs/run_20260722_200912/: transcript.log (asserted non-empty), results.mat, report_numbers.json, gate_manifest.json, 11 retained .fem/.ans, figs/ (12 figures).']],
 [32*mm, CW-32*mm]))

# ================= 05 =================
A(PageBreak())
A(Paragraph('05 / Results', S['h1']))
A(Paragraph('05.1  Stage A′ — operators certified on the manufactured field', S['h2']))
A(T([['N','T1 ∫B<sub>x</sub> dA','T2 energy','T3 circulation'],
 ['12','3.954e-03','4.936e-04','3.471e-03'],
 ['25','9.092e-04','1.134e-04','7.993e-04'],
 ['50','2.272e-04','2.832e-05','1.998e-04'],
 ['100','5.680e-05','7.080e-06','4.995e-05'],
 ['200','1.420e-05','1.770e-06','1.249e-05'],
 ['400','3.550e-06','4.425e-07','3.122e-06'],
 ['fitted order','2.001','2.001','2.000']],
 [26*mm, 44*mm, 44*mm, CW-114*mm], mono_cols=(1,2,3)))
A(Paragraph('All three functionals converge at the theoretical order 2 with production-grid (N=200) errors ≤1.42e-5 — '
 'PASS with order ENFORCED (v1\'s degenerate T1/T3 are gone). The v1 harness gets no credit it did not earn: on this '
 'field, 12-cell grids err at 3.95e-3, so the historical v4/v5 failures (159%/193%) remain attributable to operator '
 'construction, exactly as the audit\'s C2 replacement stated.', S['body']))
for x in fig('figs/F1_stageA_convergence.png',
  'Fig. F1 — Stage A′ manufactured-solution self-test: all three operators on slope −2; no functional is trivially exact.'):
    A(x)

A(Paragraph('05.2  Coax mesh family — five levels, co-refined arcs', S['h2']))
A(T([['h (mm)','maxseg (°)','N<sub>el</sub>','E rel.err','bi8 rel.err','Ampère (off)','Ampère (on)','max|B|pt (off)','max|B|pt (on)'],
 ['4.0','5','2,498','6.236e-3','1.055e-3','2.570e-2','—','1.067e-1','—'],
 ['2.0','2.5','5,928','3.938e-3','4.655e-4','1.140e-2','—','1.192e-1','—'],
 ['1.0','1.25','13,868','1.550e-3','8.186e-5','4.040e-3','—','4.971e-2','—'],
 ['0.5','0.625','41,584','5.068e-4','1.007e-5','2.008e-4','—','2.857e-2','—'],
 ['0.25','0.3125','132,262','1.533e-4','5.356e-6','8.309e-4','7.437e-5','1.551e-2','3.228e-3']],
 [15*mm,17*mm,19*mm,21*mm,21*mm,23*mm,21*mm,22*mm,CW-159*mm], mono_cols=(0,1,2,3,4,5,6,7,8)))
A(Paragraph('(Smoothing-ON values were recorded at every level; the table shows the finest level for compactness — the '
 'full set is in report_numbers.json. bi9 on the zero-target: 9.5e-7 normalized; upper/lower antisymmetry closes to 3.2e-6.)', S['cap']))
for x in fig('figs/F2_coax_convergence.png',
  'Fig. F2 — Coax family convergence. Energy and bi8 descend monotonically; the smoothing-OFF Ampère loop bottoms out '
  'near 2e-4 and rebounds at the finest mesh — the non-monotone tail the gate criteria treat separately (§05.4).'):
    A(x)
A(PageBreak())
A(Paragraph('05.3  Convergence, Richardson, GCI — and their meta-verification', S['h2']))
A(T([['Observable','p fit(all)','p fit(last-3)','p blind','GCI<sub>fine</sub>','Asym. ratio','True finest err','Richardson err'],
 ['Energy','1.365','1.669','1.561','2.266e-4','1.0004  (IN)','1.533e-4','2.794e-5'],
 ['bi8 upper','2.077','1.97','3.93','4.146e-7','1.0000  (IN)','5.356e-6','5.024e-6*'],
 ['Ampère (off)','1.573','1.141','n/a (non-monotone)','1.069e-3','1.866  (OUT)','8.309e-4','—'],
 ['|B| points (off)','0.763','—','—','—','—','1.551e-2','—']],
 [26*mm,16*mm,20*mm,26*mm,21*mm,22*mm,21*mm,CW-152*mm], mono_cols=(1,2,3,4,5,6,7)))
A(Paragraph('<b>The machinery is meta-verified where truth is known:</b> for energy, the blind three-grid order (1.561) '
 'reproduces the hand calculation (App. A.4) exactly; the Richardson extrapolate lands 5.5× closer to truth than the '
 'finest mesh (2.79e-5 vs 1.53e-4); and GCI<sub>fine</sub> = 2.27e-4 BOUNDS the true finest error 1.53e-4 with a 1.48× '
 'margin — GCI behaves as a valid numerical-uncertainty estimate here. (*bi8\'s blind p = 3.93 comes from a near-'
 'converged triplet where differences approach roundoff; its exact-aware order 2.08 is authoritative, and Richardson '
 'is skipped from gating for it.) Per the audit\'s Q4 answer, no continuum claim is made for the two observables '
 'outside the asymptotic range.', S['body']))
for x in fig('figs/F3_orders_asymptotic.png',
  'Fig. F3 — Observed orders across estimators. Energy passes the asymptotic-range check at 1.0004; the audit-mandated '
  'refusal to extrapolate applies to Ampère (ratio 1.87) and pointwise |B|.'):
    A(x)
for x in fig('figs/F4_richardson_meta.png',
  'Fig. F4 — Meta-verification on the energy observable: finest-mesh error vs Richardson-extrapolate error vs claimed '
  'GCI. The extrapolate improves on the finest mesh and GCI conservatively bounds the true error.'):
    A(x)
A(PageBreak())
A(Paragraph('05.4  Ampère contour study — Q5 answered with data', S['h2']))
A(Paragraph('5 anglesteps (4°→0.25°) × 3 radii × 3 angular offsets × smoothing off/on, on the h = 1 mm extras mesh: '
 'the error is FLAT in anglestep in both smoothing states (max variation &lt;2% of the error), so polygonal contour '
 'quadrature is NOT the floor mechanism — O-3\'s "contour floor" hypothesis is refuted, as the audit suspected. What '
 'moves the error an order of magnitude is the smoothing state: max error 4.66e-3 (off) vs 5.0e-4 (on) at this mesh; '
 'at the finest family mesh, 8.3e-4 (off) vs 7.4e-5 (on). <b>Declared policy for v6:</b> smoothed field is '
 'authoritative for contour and point observables (recorded explicitly per run); anglestep 1° retained; the '
 'smoothing-OFF channel stays measured as a sentinel.', S['body']))
for x in fig('figs/F5_contour_study.png',
  'Fig. F5 — Contour discretization study. Orange = smoothing off, graphite = on; markers = radii; offsets folded as max. '
  'Flat in anglestep; separated cleanly by smoothing state.'):
    A(x)
A(Paragraph('05.5  Convention set — locked by experiment', S['h2']))
A(T([['Convention','Test','Result','Reading'],
 ['Harmonic energy','E<sub>harm</sub>/E<sub>static</sub>, σ=0, f = 0.01/0.1/1/10 Hz','0.4999999999974 (all four)','Peak-amplitude phasors; bi2 returns TIME-AVERAGED energy. Factor 2 applies to same-peak comparisons only (audit C6 wording adopted).'],
 ['Field-phasor integrals','|bi8|<sub>harm</sub>/|bi8|<sub>static</sub>','0.99992 (all four)','Amplitude-preserving: NO ½ factor on field integrals — the ½ belongs to quadratic (energy-like) quantities only.'],
 ['Complex capability (R-b)','P4: circuit I = 100∠30° = 86.60254+50i A','Round-trip EXACT; bi8 = −5.195727e-7 −2.9997544e-7i vs exact −(μ<sub>0</sub>Î/π)(b<sub>1</sub>−a) = −5.19615e-7 −3.0000e-7i → magnitude err 7e-5, phase err &lt;0.01°','mo_blockintegral(8/9) IS complex-capable in harmonic mode. R-b is SETTLED: earlier real-zeros were symmetry artifacts, not an interface limitation.'],
 ['Axisym potential','mo_geta vs both candidate readings at 6 probes','matches 2πr·A_φ at 2.4e-4; A_φ reading off by 0.796','mo_geta returns the modified potential 2πrA (circle flux) in axisym problems. All v6 axisym extraction must use this reading.']],
 [30*mm, 42*mm, 46*mm, CW-118*mm]))
for x in fig('figs/F8_omega_ratio.png',
  'Fig. F8 — ω-sequence at σ=0: the harmonic/static energy ratio sits at 0.5 to 12 digits across four frequencies.'):
    A(x)
A(PageBreak())
A(Paragraph('05.6  Axisymmetric loop family', S['h2']))
A(T([['h<sub>air</sub> (mm)','N<sub>el</sub>','Φ max rel.err','|B| max rel.err'],
 ['8','4,194','2.245e-2','4.654e-2'],
 ['4','6,169','1.666e-2','3.438e-2'],
 ['2','14,892','2.352e-3','1.278e-2'],
 ['1','57,472','5.483e-4','3.225e-3'],
 ['4 (ABC at 0.18 m)','9,628','6.822e-3','2.114e-2']],
 [34*mm, 26*mm, 40*mm, CW-100*mm], mono_cols=(0,1,2,3)))
A(Paragraph('Fitted orders p<sub>Φ</sub> = 1.89, p<sub>B</sub> = 1.30; finest-mesh errors 5.5e-4 (Φ) and 3.2e-3 (|B|). '
 'The truncation check moves mid-mesh errors by ΔΦ = 9.8e-3 / Δ|B| = 1.3e-2 — comparable to the mid-mesh discretization '
 'error itself, so the coarse-end of this family mixes domain and mesh error exactly as the audit warned (defect 11). '
 'LIMITATION carried to the next iteration: the truncation sequence must be repeated at the finest mesh before the '
 'loop family\'s asymptotic behavior is separately certified; the present loop gate is convergence-trend + finest-'
 'error only, and no GCI is claimed for it.', S['body']))
for x in fig('figs/F9_loop_convergence.png',
  'Fig. F9 — Loop family convergence with ABC truncation delta annotated. Flux converges near order 2; |B| at 1.3 with '
  'the domain-error floor visible at coarse mesh.'):
    A(x)
A(Paragraph('05.7  Field and error surfaces', S['h2']))
for x in fig3('figs/F6a_coax_B_analytic_3d.png',
  'Fig. F6a — Coax annulus, analytic |B| = μ0I/(2πr) reference surface (mT scale) over the sampled polar grid (36×72).'):
    A(x)
A(PageBreak())
for x in fig3('figs/F6b_coax_error_3d.png',
  'Fig. F6b — Pointwise |B| relative-error surface (%) on the finest coax mesh (smoothed field, 2,592 samples): error is '
  'azimuthally structured near the conductor edges and bounded by 1.55e-2 max / far lower in the mid-annulus.'):
    A(x)
for x in fig3('figs/F7a_loop_flux_3d.png',
  'Fig. F7a — Loop benchmark: mo_geta surface over the (r,z) grid (µWb) with the source tube excluded — the recorded '
  'convention is the circle flux 2πrA_φ.'):
    A(x)
A(PageBreak())
for x in fig3('figs/F7b_loop_B_3d.png',
  'Fig. F7b — Loop benchmark |B| magnitude surface, log10 scale, finest mesh; the dipolar decay across two decades is '
  'resolved smoothly away from the excluded source region.'):
    A(x)

# ================= 06 =================
A(Paragraph('06 / Uncertainty accounting', S['h1']))
A(T([['Error term','Where it is measured','Magnitude (this run)','Status'],
 ['Spatial discretization (coax E)','GCI<sub>fine</sub>, asymptotic range verified','2.27e-4 (bounds true 1.53e-4)','QUANTIFIED'],
 ['Spatial discretization (bi8)','exact-aware order 2.08, GCI 4.1e-7','5.4e-6 true at finest','QUANTIFIED'],
 ['Contour/point extraction','smoothing on/off channels + anglestep sweep','7.4e-5 (on) / 8.3e-4 (off) finest','QUANTIFIED, policy declared'],
 ['Geometry (arc) discretization','co-refined maxseg ∝ h across family','absorbed into observed order (1.67 last-3 vs 1.36 all-5: coarse-end contamination visible)','CONTROLLED'],
 ['Domain truncation (loop)','ABC 0.12 vs 0.18 m at mid mesh','ΔΦ 9.8e-3, Δ|B| 1.3e-2','MEASURED at mid mesh; finest-mesh sequence OWED'],
 ['Reference uncertainty','integral2 tolerances; ellipke vs 30-digit refs','≤1e-11 (quadrature), 2.2e-16 (ellipke)','NEGLIGIBLE'],
 ['Solver tolerance','FEMM precision 1e-8, fixed','not separately varied this run','OWED (audit M4 asks a tolerance sweep in v6)'],
 ['Application adequacy','—','—','NOT CLAIMED: decision-layer gate awaits S2b error budget [TBD]']],
 [40*mm, 52*mm, 52*mm, CW-144*mm]))

# ================= 07 =================
A(Paragraph('07 / Handoff', S['h1']))
A(T([['Item','State'],
 ['State','C0 verification gate v2 PASSES all declared verification-layer criteria. Evidence bundle immutable at runs/run_20260722_200912 (+ mirrored to repo reports/c0_v2). Conventions locked: energy ½, field-integral 1, geta = 2πrA, complex bi8 verified. R-b settled. Contour floor refuted; smoothing policy declared.'],
 ['Open questions','(1) Loop truncation sequence at finest mesh. (2) Solver-tolerance sweep. (3) Nonlinear manufactured constitutive case before any saturation-dependent M3 conclusion. (4) Sol re-audit of this report and the P4/R-b closure. (5) Whether Ampère-loop gating should simply adopt the smoothed channel (proposed: yes).'],
 ['Next gate','Sol 5.6 re-audit (SOL-RD03-C0f expected) → then M3 probe matrix (incremental-permeability, linked AC, bias sweep) and M4 slab v6 (complex fields, 2 kHz grid, wrapped phase) on the now-verified extraction stack.'],
 ['Measurements needed (Mohammed only)','None for this gate. The DECISION gate still needs S2b shop data (volume, pack-replacement, NTF, comeback cost) before any accuracy target becomes a pass/fail spec. MATLAB license remains DEMO/trial — resolve before commercial use of MATLAB-derived work.']],
 [40*mm, CW-40*mm]))

# ================= Appendix A =================
A(PageBreak())
A(Paragraph('Appendix A / Sample calculations', S['h1']))
A(Paragraph('Every number in the body traces to one of the hand calculations below (values plugged explicitly, ME-report '
 'style). Constants: μ<sub>0</sub> = 4π×10<super>−7</super> H/m; I = 100 A; a = 5 mm; b<sub>1</sub> = 20 mm.', S['body']))

A(Paragraph('A.1  Coax annulus energy (§03.1, §05.2)', S['h2']))
A(Paragraph('Substituting μ<sub>0</sub>, I, b<sub>1</sub>, a into Eq. (2):', S['body']))
A(eqn('a1_1', numbered=False))
A(eqn('a1_2', numbered=False))
A(Paragraph('A.2  Half-annulus ∫B<sub>x</sub> target (§03.1)', S['h2']))
A(Paragraph('With B = B_φ(−sinθ, cosθ) over the upper half-annulus (θ from 0 to π), Eq. (3) evaluates as:', S['body']))
A(eqn('a2_1', numbered=False))
A(eqn('a2_2', numbered=False))
A(Paragraph('Antisymmetry check: (bi8<sub>up</sub> + bi8<sub>low</sub>)/|target| = 3.2e-6.', S['body']))
A(Paragraph('A.3  Relative error, finest coax energy (§05.2)', S['h2']))
A(eqn('a3_1', numbered=False))
A(Paragraph('A.4  Blind three-grid observed order (§05.3)', S['h2']))
A(Paragraph('Fine triplet f<sub>1</sub> = 1.3860818e-3, f<sub>2</sub> = 1.3855918e-3, f<sub>3</sub> = 1.3841461e-3 '
 '(h = 0.25/0.5/1 mm, r = 2), applied to Eq. (13):', S['body']))
A(eqn('a4_1', numbered=False))
A(eqn('a4_2', numbered=False))
A(Paragraph('Matches the run\'s fzero solution to 13 digits.', S['body']))
A(Paragraph('A.5  Richardson extrapolation (§05.3)', S['h2']))
A(Paragraph('Applying Eq. (14) with p = 1.5608:', S['body']))
A(eqn('a5_1', numbered=False))
A(eqn('a5_2', numbered=False))
A(Paragraph('The extrapolate is 5.5× closer to truth than the finest mesh (1.533e-4).', S['body']))
A(Paragraph('A.6  GCI and asymptotic-range check (§05.3)', S['h2']))
A(Paragraph('Applying Eqs. (15) and (16):', S['body']))
A(eqn('a6_1', numbered=False))
A(eqn('a6_2', numbered=False))
A(eqn('a6_3', numbered=False))
A(eqn('a6_4', numbered=False))
A(Paragraph('A.7  Manufactured-solution targets (§03.2)', S['h2']))
A(Paragraph('Using the closed-form antiderivatives of Eqs. (5)–(7) over [25,85] × [15,65] mm:', S['body']))
A(eqn('a7_1', numbered=False))
A(eqn('a7_2', numbered=False))
A(Paragraph('A.8  ellipke validation (§03.3)', S['h2']))
A(eqn('a8_1', numbered=False))
A(eqn('a8_2', numbered=False))
A(Paragraph('Same at m = 0.25 and 0.75: |Δ| = 0. Confirms the m = k<super>2</super> convention end-to-end.', S['body']))
A(Paragraph('A.9  Loop flux target and finite-cross-section effect (§03.3)', S['h2']))
A(Paragraph('Filament a = 30 mm, probe (r, z) = (20, 10) mm, via Eqs. (8) and (12):', S['body']))
A(eqn('a9_1', numbered=False))
A(eqn('a9_2', numbered=False))
A(eqn('a9_3', numbered=False))
A(Paragraph('The 2.39e-5 finite-cross-section shift exceeds the reference-precision target (1e-11) by seven orders — '
 'which is exactly why the reference integrates the ACTUAL source cross-section instead of a filament (audit defect 10).', S['body']))
A(Paragraph('A.10  Harmonic ½-convention arithmetic (§05.5)', S['h2']))
A(Paragraph('From Eq. (17) at equal numeric current (DC value = AC peak):', S['body']))
A(eqn('a10_1', numbered=False))
A(eqn('a10_2', numbered=False))
A(Paragraph('A.11  P4 complex target (§05.5, R-b closure)', S['h2']))
A(Paragraph('The complex form of Eq. (3) with the phased circuit current:', S['body']))
A(eqn('a11_1', numbered=False))
A(eqn('a11_2', numbered=False))
A(eqn('a11_3', numbered=False))
A(Paragraph('A complex value with the correct magnitude AND phase cannot come from a real-only interface: R-b settled.', S['body']))
A(Paragraph('A.12  Realized refinement ratios and skin-depth planning set (§04, §07)', S['h2']))
A(eqn('a12_1', numbered=False))
A(Paragraph('The request (r = 2.000) is not what the mesher delivers; blind-order work uses realized values. '
 'Skin depth from Eq. (18) at 5 kHz [Representative — VERIFY]:', S['body']))
A(eqn('eq18'))
A(eqn('a12_2', numbered=False))
A(Paragraph('These are the audit\'s coupon-ladder rationale (Al → Cu → steel) in numbers.', S['body']))

# ================= Appendix B =================
A(Paragraph('Appendix B / Run manifest and provenance', S['h1']))
A(T([['Item','Value'],
 ['Run ID','run_20260722_200912  (started 2026-07-22 20:09:12, America/Chicago)'],
 ['Cache key','358b5b996d40eedd…  (SHA-256 over 9 source hashes + femm.exe hash + MATLAB version + jsonencode(params))'],
 ['femm.exe SHA-256','5e83cf0899cabae2017868ddcce338e3ba4ac25d1bf8e511eac77eda2bc92a21 — EQUAL to the value recorded independently by Sol 5.6 in C0e-R §P0-2'],
 ['MATLAB','R2026a Update 3 (26.1.0.3276743) — DEMO/trial license [licensing gate before commercial use]'],
 ['Gate manifest','{stageA: true, coax: true, loop: true, femm_exe_matches_audit: true}'],
 ['Evidence retained','11 × .fem/.ans (5 coax + 4 loop + trunc + extras) · transcript.log 2,747 B · results.mat · report_numbers.json · 12 figures · gate_manifest.json'],
 ['Provenance tags','All run values [Measured]; GCI/order machinery [NASA-GCI]; loop kernels [NASA-Loop2013]; elliptic checks [NIST-DLMF19]; threshold policy posture [NISTIR8298]; audit inputs [Sol 5.6 — 2026-07-22, SOL-RD03-C0e-R]. Sol-return rows remain Status = Inbox pending link verification; verdicts leaning on them are provisional per shelf law.']],
 [34*mm, CW-34*mm]))
A(Paragraph('Cite: [Salari&Knupp2000],[NASA-GCI],[NASA-Loop2013],[NIST-DLMF19],[NISTIR8298],[Meeker-FEMM],[Sol 5.6 — 2026-07-22, SOL-RD03-C0e-R]. '
 'Sol-return shelf rows are Inbox (link-resolution pending); everything else [Measured] from run_20260722_200912. '
 'Verification-layer only — no family numbers, no application adequacy, no disposition. MATLAB run 2026-07-22.', S['cite']))

doc.build(E)
print('PDF built')
