function options = defaultOptions()
%DEFAULTOPTIONS Default configuration for SVR active learning workflow.
%
% Returns:
%   options (struct): Configuration with fields required by the project:
%     alpha, Npool, N0, Nmax, acqMethod, eps_d, eps_sigma, bootstrapM,
%     eta, Kconsec, bayesoptMaxEvals, rngSeed.

options = struct();

% Pool / DOE / budget
options.alpha = 0.001;
options.Npool = 20000;
options.N0 = 20;
options.Nmax = 100;

% Acquisition ("A1" or "Uboot")
options.acqMethod = "A1";
options.eps_d = 1.0e-12;
options.eps_sigma = 1.0e-12;

% Bootstrap uncertainty
options.bootstrapM = 20;

% Stop criteria on Pf convergence
options.eta = 5.0e-3;
options.Kconsec = 3;

% SVR BayesOpt configuration
options.bayesoptMaxEvals = 30;

% Reproducibility
options.rngSeed = 42;

% Output tagging (optional)
options.runTag = "";
end

