function q2 = A_q2(predicted,observed)

x = predicted;
y = observed;

% Calculate MSE(x, y)
MSE_pred_obs = mean((y - x).^2);

% Calculate MSE(y, mean(y))
mean_y = mean(y); % Mean of observed values
MSE_obs_avg = mean((y - mean_y).^2);

% Calculate NMSE
NMSE = MSE_pred_obs / MSE_obs_avg;

% Calculate R^2 as 1 - NMSE
q2 = 1 - NMSE;


end

