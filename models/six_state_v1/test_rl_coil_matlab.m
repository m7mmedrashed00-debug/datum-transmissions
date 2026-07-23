function tests = test_rl_coil_matlab
% Completion-test unit tests: textbook v0.1 Ch 8 worked example (generic values).
tests = functiontests(localfunctions);
end

function testHotResistanceWorkedExample(testCase)
r120 = 5.0 * (1 + 0.00393 * (120 - 20));   % [Dellinger] alpha, generic R20
verifyEqual(testCase, r120, 6.965, "AbsTol", 1e-3)
end

function testDriverVoltageCompliance(testCase)
r120 = 5.0 * (1 + 0.00393 * (120 - 20));
v_req = 1.40 * r120 + 0.012 * 700 + 0.8;    % iR + L*di/dt + drop
verifyEqual(testCase, v_req, 18.95, "AbsTol", 0.01)
end

function testFlybackEnergyNonnegative(testCase)
e = 0.5 * 0.012 * 1.40^2;
verifyEqual(testCase, e, 0.01176, "AbsTol", 1e-5)
verifyGreaterThanOrEqual(testCase, e, 0)
end
