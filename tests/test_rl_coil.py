"""Limiting-case and worked-example tests for the RL coil starter model."""
import math
import pytest
from datum import rl_coil as m


def test_resistance_matches_textbook_worked_example():
    # v0.1 Ch 8: R_20 = 5.0 ohm -> R_120 = 6.965 ohm (illustrative, generic)
    assert m.resistance(5.0, 120.0) == pytest.approx(6.965, abs=1e-3)


def test_resistance_at_reference_is_identity():
    assert m.resistance(5.0, 20.0) == pytest.approx(5.0)


def test_resistance_rejects_nonpositive():
    with pytest.raises(ValueError):
        m.resistance(0.0, 50.0)


def test_rl_current_limiting_cases():
    v, r, l = 12.0, 6.0, 0.012
    assert m.rl_step_current(0.0, v, r, l) == pytest.approx(0.0)
    assert m.rl_step_current(1.0, v, r, l) == pytest.approx(v / r, rel=1e-6)  # t >> tau
    tau = l / r
    assert m.rl_step_current(tau, v, r, l) == pytest.approx((v / r) * (1 - math.exp(-1)), rel=1e-9)


def test_rl_current_monotonic():
    v, r, l = 12.0, 6.0, 0.012
    ts = [i * 1e-4 for i in range(50)]
    vals = [m.rl_step_current(t, v, r, l) for t in ts]
    assert all(b >= a for a, b in zip(vals, vals[1:]))


def test_v_required_matches_textbook_worked_example():
    # v0.1 Ch 8: 1.40 A at R_120=6.965, L=12 mH, 700 A/s, 0.8 V drop -> 18.95 V
    r120 = m.resistance(5.0, 120.0)
    assert m.v_required(1.40, 700.0, r120, 0.012, 0.8) == pytest.approx(18.95, abs=0.01)


def test_stored_energy_nonnegative_and_example():
    # v0.1 Ch 8: 0.5 * 12 mH * 1.4^2 = 11.8 mJ
    assert m.stored_energy(0.012, 1.40) == pytest.approx(0.01176, abs=1e-5)
    assert m.stored_energy(0.012, -1.40) == m.stored_energy(0.012, 1.40)
