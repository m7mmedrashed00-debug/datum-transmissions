"""RL coil starter model — textbook Weeks 1-2 deliverable (Ch 1, 3, 8).

Instructional and family-agnostic. Generic values; nothing here is a product limit.
Relationships:
  R(T) linear copper model, alpha = 0.00393 /degC for annealed copper of standard
  conductivity [Dellinger, Government tier — coefficient varies with conductivity].
  RL step response and driver voltage balance [Textbook, v0.1 Ch 3 and Ch 8].
"""
import math

ALPHA_CU = 0.00393  # 1/degC [Dellinger]
T_REF = 20.0        # degC reference for r_ref


def resistance(r_ref: float, temp_c: float, alpha: float = ALPHA_CU) -> float:
    """Coil resistance at temp_c, given r_ref at T_REF (20 degC)."""
    if r_ref <= 0.0:
        raise ValueError("r_ref must be positive")
    return r_ref * (1.0 + alpha * (temp_c - T_REF))


def rl_step_current(t: float, v: float, r: float, l: float) -> float:
    """Step-response current i(t) = (V/R)(1 - exp(-t/tau)), tau = L/R. Valid for t >= 0."""
    if t < 0.0:
        raise ValueError("t must be >= 0")
    if r <= 0.0 or l <= 0.0:
        raise ValueError("r and l must be positive")
    tau = l / r
    return (v / r) * (1.0 - math.exp(-t / tau))


def v_required(i_target: float, di_dt: float, r: float, l: float, v_drop: float = 0.0) -> float:
    """Driver voltage balance V = iR + L di/dt + v_drop (motion-linked term excluded).

    Separates steady accuracy from dynamic current authority: at steady state the
    L di/dt term vanishes; the transient requirement is a voltage-compliance question,
    not a controller-tuning question. [Textbook v0.1 Ch 8]
    """
    return i_target * r + l * di_dt + v_drop


def stored_energy(l: float, i: float) -> float:
    """Magnetic energy 0.5 L i^2 that must be handled at turn-off (flyback path)."""
    if l <= 0.0:
        raise ValueError("l must be positive")
    return 0.5 * l * i * i
