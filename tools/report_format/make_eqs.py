#!/usr/bin/env python3
"""Render numbered display equations + appendix sample-calculation lines as
high-res PNGs (matplotlib mathtext), graphite ink, transparent-white bg."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

INK = '#1C1F26'
plt.rcParams['mathtext.fontset'] = 'stix'   # serif math, engineering-report look

def render(name, tex, fs=27):
    fig = plt.figure()
    t = fig.text(0.01, 0.5, f'${tex}$', fontsize=fs, color=INK)
    fig.canvas.draw()
    bb = t.get_window_extent()
    w, h = bb.width/fig.dpi + 0.12, bb.height/fig.dpi + 0.10
    fig.set_size_inches(w, h)
    t.set_position((0.06/w, 0.5))
    fig.savefig(f'eqs/{name}.png', dpi=300, transparent=False,
                facecolor='white', bbox_inches='tight', pad_inches=0.045)
    plt.close(fig)
    print(name)

import os; os.makedirs('eqs', exist_ok=True)

# ---------------- theory equations (numbered in report) ----------------
E = {
 'eq01': r'B_\varphi(r) = \dfrac{\mu_0 I}{2\pi r}',
 'eq02': r'E = \int_a^{b_1}\!\!\dfrac{B_\varphi^2}{2\mu_0}\,2\pi r\,dr \;=\; \dfrac{\mu_0 I^2}{4\pi}\,\ln\!\dfrac{b_1}{a}',
 'eq03': r'\int_{\mathrm{upper}} B_x\,dA \;=\; -\dfrac{\mu_0 I}{\pi}\,(b_1-a), \qquad \int_{\mathrm{upper}} B_y\,dA = 0',
 'eq04': r'\oint \vec{H}\cdot d\vec{l} \;=\; I_{enc}',
 'eq05': r'A_z(x,y) \;=\; A_0\,\sin(k_x x)\,\sin(k_y y)',
 'eq06': r'B_x = \dfrac{\partial A_z}{\partial y}, \qquad B_y = -\dfrac{\partial A_z}{\partial x}, \qquad J_z = \dfrac{(k_x^2+k_y^2)}{\mu_0}\,A_z',
 'eq07': r'T_3 \;=\; \oint \vec{H}\cdot d\vec{l} \;=\; \dfrac{k_x^2+k_y^2}{\mu_0}\iint_W A_z\,dA',
 'eq08': r'm = k^2 = \dfrac{4\,a\,r}{(a+r)^2+(z-z_s)^2}',
 'eq09': r'A_\varphi(r,z) \;=\; \dfrac{\mu_0 I}{\pi k}\sqrt{\dfrac{a}{r}}\left[\left(1-\frac{k^2}{2}\right)K(m) - E(m)\right]',
 'eq10': r'B_r = \dfrac{\mu_0 I\,(z-z_s)}{2\pi r\,S}\left[-K(m) + \dfrac{a^2+r^2+(z-z_s)^2}{D}\,E(m)\right],\quad S^2=(a+r)^2+(z-z_s)^2,\; D=(a-r)^2+(z-z_s)^2',
 'eq11': r'B_z = \dfrac{\mu_0 I}{2\pi S}\left[K(m) + \dfrac{a^2-r^2-(z-z_s)^2}{D}\,E(m)\right]',
 'eq12': r'\Phi(r,z) \;=\; 2\pi r\,A_\varphi \;=\; M(r,z)\,I, \qquad M = \mu_0\sqrt{ar}\left[\left(\frac{2}{k}-k\right)K(m) - \frac{2}{k}\,E(m)\right]',
 'eq13': r'\dfrac{f_3-f_2}{f_2-f_1} \;=\; r_{21}^{\,p}\;\dfrac{r_{32}^{\,p}-1}{r_{21}^{\,p}-1}',
 'eq14': r'f_{ext} \;=\; f_1 + \dfrac{f_1-f_2}{r_{21}^{\,p}-1}',
 'eq15': r'GCI_{fine} \;=\; \dfrac{F_s\,|\varepsilon_{21}|}{r_{21}^{\,p}-1}, \qquad \varepsilon_{21}=\dfrac{f_1-f_2}{f_1}, \qquad F_s = 1.25',
 'eq16': r'\dfrac{GCI_{23}}{r_{21}^{\,p}\;GCI_{12}} \;\approx\; 1 \quad \Rightarrow \quad \mathrm{asymptotic\ range}',
 'eq17': r'E_{static} = \frac{1}{2}L I_{pk}^2, \qquad \langle E_{harm}\rangle = \frac{1}{4}L I_{pk}^2 \quad\Rightarrow\quad \dfrac{\langle E_{harm}\rangle}{E_{static}} = 0.5',
 'eq18': r'\delta \;=\; \sqrt{\dfrac{2}{\omega\,\mu\,\sigma}} \;=\; \dfrac{1}{\sqrt{\pi f \mu \sigma}}',
}
# ---------------- appendix sample-calculation lines ----------------
A = {
 'a1_1': r'E \;=\; \dfrac{(4\pi\times10^{-7})(100)^2}{4\pi}\,\ln\!\dfrac{0.020}{0.005} \;=\; 10^{-3}\ln 4',
 'a1_2': r'E \;=\; 1.386294\times10^{-3}\ \mathrm{J/m}, \qquad E_{FEMM,h=0.25mm} = 1.3860818\times10^{-3}\ \mathrm{J/m}',
 'a2_1': r'\int_{up} B_x dA = -\dfrac{\mu_0 I}{2\pi}(b_1-a)[-\cos\theta]_0^{\pi} = -\dfrac{(4\pi\times10^{-7})(100)}{\pi}(0.015)',
 'a2_2': r'= -6.000\times10^{-7}\ \mathrm{Wb/m}; \qquad \mathrm{FEMM:}\ -5.999968\times10^{-7}\ (up),\ +5.999987\times10^{-7}\ (low)',
 'a3_1': r'\varepsilon \;=\; \left|\dfrac{1.3860818\times10^{-3}}{1.3862944\times10^{-3}} - 1\right| \;=\; 1.533\times10^{-4}',
 'a4_1': r'\dfrac{f_3-f_2}{f_2-f_1} = \dfrac{-1.44566\times10^{-6}}{-4.90035\times10^{-7}} = 2.95015',
 'a4_2': r'p \;=\; \dfrac{\ln 2.95015}{\ln 2} \;=\; 1.5608',
 'a5_1': r'f_{ext} = 1.3860818\times10^{-3} + \dfrac{4.90035\times10^{-7}}{2^{1.5608}-1} = 1.3860818\times10^{-3} + 2.51280\times10^{-7}',
 'a5_2': r'f_{ext} = 1.3863331\times10^{-3}; \qquad \varepsilon_{ext} = \dfrac{|1.3863331-1.3862944|}{1.3862944} = 2.794\times10^{-5}',
 'a6_1': r'\varepsilon_{21} = \dfrac{f_1-f_2}{f_1} = 3.53534\times10^{-4} \;\Rightarrow\; GCI_{12} = \dfrac{1.25\,(3.53534\times10^{-4})}{1.95015} = 2.2661\times10^{-4}',
 'a6_2': r'\varepsilon_{32} = 1.04335\times10^{-3} \;\Rightarrow\; GCI_{23} = 6.6876\times10^{-4}',
 'a6_3': r'\dfrac{GCI_{23}}{r^{\,p}\,GCI_{12}} = \dfrac{6.6876\times10^{-4}}{2.95015\times2.2661\times10^{-4}} = 1.00035 \;\Rightarrow\; \mathrm{IN\ range}',
 'a6_4': r'\mathrm{check:}\quad GCI_{12} = 2.27\times10^{-4} \;\geq\; \varepsilon_{true} = 1.53\times10^{-4} \quad (1.48\times\ \mathrm{conservative})',
 'a7_1': r'T_1 = A_0 k_y\,\dfrac{\cos(k_x x_1)-\cos(k_x x_2)}{k_x}\cdot\dfrac{\sin(k_y y_2)-\sin(k_y y_1)}{k_y} = -6.117585\times10^{-5}\ \mathrm{Wb/m}',
 'a7_2': r'T_2 = 1.583262\ \mathrm{J/m}, \qquad T_3 = \dfrac{37^2+59^2}{\mu_0}A_0\,I_{sin}(k_x)I_{sin}(k_y) = 3971.499\ \mathrm{A}',
 'a8_1': r'K(0.5)_{MATLAB} = 1.854074677301372\ \ \mathrm{vs}\ \ 1.85407467730137191\ldots\ \Rightarrow\ |\Delta| = 2.2\times10^{-16}',
 'a8_2': r'K(\frac{1}{2}) = \dfrac{\Gamma(\frac{1}{4})^2}{4\sqrt{\pi}}\ \ \mathrm{identity\ agrees\ to\ 28\ digits\ (independent\ 30\!-\!digit\ mpmath)}',
 'a9_1': r'm = \dfrac{4(0.030)(0.020)}{(0.050)^2+(0.010)^2} = \dfrac{0.0024}{0.0026} = 0.923077,\quad K = 2.702178,\; E = 1.085256',
 'a9_2': r'M = \mu_0\sqrt{(0.030)(0.020)}\left[\left(\frac{2}{k}-k\right)K - \frac{2}{k}E\right] = 2.369300\times10^{-8}\ \mathrm{H}',
 'a9_3': r'\Phi_{fil} = MI = 2.369300\times10^{-6}\ \mathrm{Wb}; \quad \Phi_{quad} = 2.369244\times10^{-6}\ \mathrm{Wb} \;\Rightarrow\; \Delta_{rel} = 2.39\times10^{-5}',
 'a10_1': r'\dfrac{\langle E_{harm}\rangle}{E_{static}} = \dfrac{\frac{1}{4}LI_{pk}^2}{\frac{1}{2}LI_{pk}^2} = 0.5000 \quad \mathrm{vs\ measured}\ 0.49999999999739\ \ (4\ \mathrm{frequencies})',
 'a10_2': r'\dfrac{|bi8|_{harm}}{|bi8|_{static}} = \dfrac{5.9995088\times10^{-7}}{5.9999679\times10^{-7}} = 0.99992 \;\Rightarrow\; \mathrm{amplitude\!-\!preserving}',
 'a11_1': r'\hat{I} = 100\angle 30^\circ = 86.60254 + 50.00000j\ \mathrm{A}',
 'a11_2': r'\mathrm{target} = -(6.0\times10^{-9})\hat{I} = -(5.19615\times10^{-7} + 3.0000\times10^{-7}j)\ \mathrm{Wb/m}',
 'a11_3': r'\mathrm{measured}\ bi8 = -5.195727\times10^{-7} - 2.9997544\times10^{-7}j \;\Rightarrow\; \varepsilon_{|\cdot|} = 8.0\times10^{-5},\ \varepsilon_{\angle} < 0.01^\circ',
 'a12_1': r'r_{eff} = \sqrt{N_{j+1}/N_j}: \ \sqrt{5928/2498}=1.540,\ \sqrt{13868/5928}=1.530,\ \sqrt{41584/13868}=1.732,\ \sqrt{132262/41584}=1.783',
 'a12_2': r'\delta_{Al} = \dfrac{1}{\sqrt{\pi(5000)(4\pi\times10^{-7})(25\times10^{6})}} = 1.424\ \mathrm{mm};\quad \delta_{Cu}=0.935,\ \delta_{Fe,\mu_r 100}=0.291,\ \delta_{Fe,\mu_r 1000}=0.092\ \mathrm{mm}',
}
for n, t in {**E, **A}.items():
    render(n, t)
print('done', len(E)+len(A))
