function problem = make2dNormalProblem()
%MAKE2DNORMALPROBLEM Create the 2D validation problem definition.
%
% Returns:
%   problem (struct) with fields:
%     name, d, dists, gfun

dist1 = makedistCompat('Normal', 'mu', 1.5, 'sigma', 1.0);
dist2 = makedistCompat('Normal', 'mu', 2.5, 'sigma', 1.0);

problem = struct();
problem.name = "2d_analytic";
problem.d = 2;
problem.dists = [dist1, dist2];
problem.gfun = @(X) gfun2d_analytic(X);
end
