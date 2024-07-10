% 计算最大误差
max_mean_error_gaussian = max(mean_errors_gaussian);
max_mean_error_rayleigh = max(mean_errors_rayleigh);
max_mean_error_rayleigh_multipath = max(mean_errors_rayleigh_multipath);

% 归一化处理
normalized_mean_errors_gaussian = mean_errors_gaussian / max_mean_error_gaussian;
normalized_mean_errors_rayleigh = mean_errors_rayleigh / max_mean_error_rayleigh;
normalized_mean_errors_rayleigh_multipath = mean_errors_rayleigh_multipath / max_mean_error_rayleigh_multipath;

% 绘制归一化后的定位平均误差
figure;
hold on;
plot(SNR_values, normalized_mean_errors_gaussian, 'r', 'DisplayName', '高斯信道');
plot(SNR_values, normalized_mean_errors_rayleigh, 'g', 'DisplayName', '瑞丽信道');
plot(SNR_values, normalized_mean_errors_rayleigh_multipath, 'b', 'DisplayName', '多径瑞丽信道');
xlabel('信噪比 (dB)');
ylabel('归一化定位平均误差');
title('不同信道在不同信噪比下的归一化定位平均误差');
legend('show');
grid on;
hold off;


%%
% 绘制基站、真实节点和特定定位结果
specific_snr_idx =2;
specific_iteration = 23;

estimated_position_gaussian = estimated_positions_gaussian(specific_iteration, :);
estimated_position_rayleigh = estimated_positions_rayleigh(specific_iteration, :);
estimated_position_rayleigh_multipath = estimated_positions_rayleigh_multipath(specific_iteration, :);

figure;
hold on;
plot(base_station(:, 1), base_station(:, 2), 'ro', 'MarkerSize', 10, 'DisplayName', '基站');
plot(node(1), node(2), 'bx', 'MarkerSize', 10, 'DisplayName', '真实节点');
plot(estimated_position_gaussian(1), estimated_position_gaussian(2), 'g+', 'MarkerSize', 10, 'DisplayName', '高斯信道估计位置');
plot(estimated_position_rayleigh(1), estimated_position_rayleigh(2), 'm+', 'MarkerSize', 10, 'DisplayName', '瑞丽信道估计位置');
plot(estimated_position_rayleigh_multipath(1), estimated_position_rayleigh_multipath(2), 'c+', 'MarkerSize', 10, 'DisplayName', '多径瑞丽信道估计位置');
legend('show');
xlabel('X 位置 (米)');
ylabel('Y 位置 (米)');
title(sprintf('基站、真实节点和信噪比 %d dB 下第 %d 次仿真估计位置', SNR_values(specific_snr_idx), specific_iteration));
grid on;
hold off;

