%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2012 by Jerome Maye                                            %
% jerome.maye@gmail.com                                                        %
%                                                                              %
% This program is free software; you can redistribute it and/or modify         %
% it under the terms of the Lesser GNU General Public License as published by  %
% the Free Software Foundation; either version 3 of the License, or            %
% (at your option) any later version.                                          %
%                                                                              %
% This program is distributed in the hope that it will be useful,              %
% but WITHOUT ANY WARRANTY; without even the implied warranty of               %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                %
% Lesser GNU General Public License for more details.                          %
%                                                                              %
% You should have received a copy of the Lesser GNU General Public License     %
% along with this program. If not, see <http://www.gnu.org/licenses/>.         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script performs systematic evaluation on the sine wave path with
% varying amplitudes.

clear all;

% simulation parameters
params;

% number of repetitions for each amplitude
rep = 50;

% sine wave frequency
frequency = 0.01;

% landmarks parameters
nl = 17;
minX = 0;
maxX = 15;
minY = 0;
maxY = 15;

% amplitude parameters
minAmplitude = 3;
maxAmplitude = 3;
amplitudeStep = 0.5;

% output for each repetition with a given amplitude
Theta_tqr_mi = zeros(rep, 3);
Sigma_tqr_mi = zeros(3, 3, rep);
batchSize_rep = zeros(rep, 1);
Theta_ls = zeros(rep, 3);
Sigma_ls = zeros(3, 3, rep);
Theta_ekf = zeros(rep, 3);
Sigma_ekf = zeros(3, 3, rep);
R1_rep = zeros(rep, 100);
R2_rep = zeros(rep, 100);

% amplitude index
ampIdx = 1;

% optimization parameters
optTol = 1e-6;
maxIter = 15;
rankTol = 0.016;
batchSize = 100;
miThreshold = 0.5;

% initial guess for Theta
Theta_hat = [0.22; 0.12; 0.8];

warning off all;

% perform evaluation
for amplitude = minAmplitude:amplitudeStep:maxAmplitude
  amplitude

  if amplitude == 0
    rankTol = 0.016;
  end
  if amplitude == 0.5
    rankTol = 0.016;
  end
  if amplitude == 1.0
    rankTol = 0.016;
  end
  if amplitude == 1.5
    rankTol = 0.015;
  end
  if amplitude == 2.0
    rankTol = 0.015;
  end
  if amplitude == 2.5
    rankTol = 0.013;
  end
  if amplitude == 3.0
    rankTol = 0.011;
  end

  for i = 1:rep
    i

    % setting up the scene
    u = genSinPath(steps, amplitude, frequency, T);
    l = genLandmarks(nl, [minX maxX], [minY maxY]);
    [x_true y_true th_true r b v om t] = simulate(u, x0, l, Q, R, Theta, T);

    % initial guess
    x_odom = odomInt([x_true(1), y_true(1), th_true(1)], [v, om], t);
    l_hat = initLandmarks(x_odom, Theta_hat, r, b);

    % TQR-MI optimization
    disp('TQR-MI');
    [x_est l_est Theta_est Sigma batchIdx] = ls_slam_calib_it(x_odom, l_hat, ...
       Theta_hat, [v, om], r, b, t, Q, R, maxIter, optTol, batchSize, ...
       miThreshold, rankTol);
    Theta_tqr_mi(i, :) = Theta_est';
    Sigma_tqr_mi(:, :, i) = Sigma;
    batchSize_rep(i) = length(batchIdx);
    Theta_est
    Sigma

    % Non-linear least squares without regularization
    disp('LS');
    [x_est l_est Theta_est Sigma R1 R2] = ls_slam_calib_prior(x_odom, l_hat, ...
      Theta_hat, [v, om], r, b, t, Q, R, maxIter, optTol, x0, ...
      diag([1e-6; 1e-6; 1e-6]));
    Theta_ls(i, :) = Theta_est';
    Sigma_ls(:, :, i) = Sigma;
    R1_rep(i, :) = R1(end - 99:end);
    R2_rep(i, :) = R2(end - 99:end);
    Theta_est
    Sigma

    % EKF
    disp('EKF');
    [x_est, P] = ekf_slam_calib(x0, diag([1e-6; 1e-6; 1e-6]), Theta_hat, ...
      diag([1e-1; 1e-1; 1e-1]), [v, om], r, b, t, Q, R);
    Theta_ekf(i, :) = x_est(end, end - 2:end);
    Sigma_ekf(:, :, i) = P(end - 2:end, end - 2:end, end);
    x_est(end, end - 2:end)
    P(end - 2:end, end - 2:end, end)
  end

  % save results for this amplitude
  ampResTQRMI(ampIdx).amplitude = amplitude;
  ampResTQRMI(ampIdx).rep = rep;
  ampResTQRMI(ampIdx).R1_rep = R1_rep;
  ampResTQRMI(ampIdx).R2_rep = R2_rep;
  ampResTQRMI(ampIdx).Theta_tqr_mi = Theta_tqr_mi;
  ampResTQRMI(ampIdx).Sigma_tqr_mi = Sigma_tqr_mi;
  ampResTQRMI(ampIdx).batchSize_rep = batchSize_rep;
  ampResTQRMI(ampIdx).Theta_ls = Theta_ls;
  ampResTQRMI(ampIdx).Sigma_ls = Sigma_ls;
  ampResTQRMI(ampIdx).Theta_ekf = Theta_ekf;
  ampResTQRMI(ampIdx).Sigma_ekf = Sigma_ekf;

  % save file to disk
  save('ampResTQRMI.mat', 'ampResTQRMI');

  % increment amplitude index
  ampIdx = ampIdx + 1;
end

warning on all;