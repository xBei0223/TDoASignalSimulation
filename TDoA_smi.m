% 仿真参数
Fs = 1e6; % 采样频率
T = 1; % 仿真时间（秒）
N = Fs * T; % 样本数量
num_repeat = 100; % 每个SNR的重复次数
SNR_values = 0:5:50 ; % 信噪比范围（dB）

% 信号参数
signal_length = 100; % 信号长度（样本数量）
Fc = 1e5; % 载波频率

% 基站和节点的位置
base_station = [0, 0; 5000, 0; 2000, 5000];
node = [2500, 2500];

% 光速（米/秒）
c = 3e8;


% 生成AM信号
t = (0:signal_length-1)'/Fs;
message_signal = cos(2*pi*1e3*t); % 1kHz 信号
carrier_signal = cos(2*pi*Fc*t);
am_signal = (1 + message_signal) .* carrier_signal;

% 信道参数
num_stations = size(base_station, 1);
fd = 10; % 多普勒频移(Hz)


% 瑞丽衰落信道
rayleigh_chan = comm.RayleighChannel( ...
    'SampleRate', Fs, ...
    'MaximumDopplerShift', fd ...
);


% 多径瑞丽衰落信道
multipath_delays = [0 1.5e-6 3.5e-6];
multipath_gains = [0 -3 -10];
rayleigh_multipath_chan = comm.RayleighChannel( ...
    'SampleRate', Fs, ...
    'PathDelays', multipath_delays, ...
    'AveragePathGains', multipath_gains, ...
    'MaximumDopplerShift', fd ...
    ...
    );

% 初始化平均误差存储
mean_errors_gaussian = zeros(length(SNR_values), 1);
mean_errors_rayleigh = zeros(length(SNR_values), 1);
mean_errors_rayleigh_multipath = zeros(length(SNR_values), 1);


for snr_idx = 1:length(SNR_values)
    SNR = SNR_values(snr_idx);
    
    % 初始化定位结果数组
    estimated_positions_gaussian = zeros(num_repeat, 2);
    estimated_positions_rayleigh = zeros(num_repeat, 2);
    estimated_positions_rayleigh_multipath = zeros(num_repeat, 2);

    % 初始化误差数组
    errors_gaussian = zeros(num_repeat, 1);
    errors_rayleigh = zeros(num_repeat, 1);
    errors_rayleigh_multipath = zeros(num_repeat, 1);

    for i = 1:num_repeat
        % 生成随机发送时间
        send_time = rand * T;
        send_sample = round(send_time * Fs);

        % 初始化每种信道类型的接收信号
        received_signals_gaussian = zeros(N, num_stations);
        received_signals_rayleigh = zeros(N, num_stations);
        received_signals_rayleigh_multipath = zeros(N, num_stations);

        for i = 1:num_stations
            % 计算距离和路径损耗
            distance = norm(base_station(i, :) - node);
            attenuation = 1 / distance^2;

            % 信号到达时间和样本
            arrival_time = send_time + distance / c;
            arrival_sample = round(arrival_time * Fs);

            % 高斯信道
            gaussian_signal = am_signal * attenuation;
            received_signals_gaussian(arrival_sample:arrival_sample+signal_length-1, i) = gaussian_signal;

            % 瑞丽信道

            faded_signal_rayleigh = rayleigh_chan(am_signal);
            reset(rayleigh_chan);
            faded_signal_rayleigh = faded_signal_rayleigh * attenuation;
            received_signals_rayleigh(arrival_sample:arrival_sample+signal_length-1, i) = faded_signal_rayleigh;

            % 含有多径的瑞丽信道
            faded_signal_rayleigh_multipath = rayleigh_multipath_chan(am_signal);
            reset(rayleigh_multipath_chan);
            faded_signal_rayleigh_multipath = faded_signal_rayleigh_multipath * attenuation;
            received_signals_rayleigh_multipath(arrival_sample:arrival_sample+signal_length-1, i) = faded_signal_rayleigh_multipath;

            % 添加噪声
            received_signals_gaussian(:, i) = awgn(received_signals_gaussian(:, i), SNR, 'measured');
            received_signals_rayleigh(:, i) = awgn(received_signals_rayleigh(:, i), SNR, 'measured');
            received_signals_rayleigh_multipath(:, i) = awgn(received_signals_rayleigh_multipath(:, i), SNR, 'measured');
        end

        % 估计到达时间
        estimated_samples_gaussian = zeros(num_stations, 1);
        estimated_samples_rayleigh = zeros(num_stations, 1);
        estimated_samples_rayleigh_multipath = zeros(num_stations, 1);

        estimated_times_gaussian = zeros(num_stations, 1);
        estimated_times_rayleigh = zeros(num_stations, 1);
        estimated_times_rayleigh_multipath = zeros(num_stations, 1);

        for i = 1:num_stations
            [~, estimated_samples_gaussian(i)] = max(received_signals_gaussian(:, i));
            [~, estimated_samples_rayleigh(i)] = max(received_signals_rayleigh(:, i));
            [~, estimated_samples_rayleigh_multipath(i)] = max(received_signals_rayleigh_multipath(:, i));

            estimated_times_gaussian(i) = (estimated_samples_gaussian(i) - 1) / Fs;
            estimated_times_rayleigh(i) = (estimated_samples_rayleigh(i) - 1) / Fs;
            estimated_times_rayleigh_multipath(i) = (estimated_samples_rayleigh_multipath(i) - 1) / Fs;
        end

        % 调用 TDoA 定位函数
        estTDoA_gaussian = estimated_times_gaussian - estimated_times_gaussian(1);
        estTDoA_rayleigh = estimated_times_rayleigh - estimated_times_rayleigh(1);
        estTDoA_rayleigh_multipath = estimated_times_rayleigh_multipath - estimated_times_rayleigh_multipath(1);

        estimated_positions_gaussian(i, :) = locatePosition(base_station, estTDoA_gaussian);
        estimated_positions_rayleigh(i, :) = locatePosition(base_station, estTDoA_rayleigh);
        estimated_positions_rayleigh_multipath(i, :) = locatePosition(base_station, estTDoA_rayleigh_multipath);

        % 计算定位误差
        errors_gaussian(i) = norm(estimated_positions_gaussian(i, :) - node);
        errors_rayleigh(i) = norm(estimated_positions_rayleigh(i, :) - node);
        errors_rayleigh_multipath(i) = norm(estimated_positions_rayleigh_multipath(i, :) - node);
    end

    % 计算平均误差
    mean_errors_gaussian(snr_idx) = mean(errors_gaussian);
    mean_errors_rayleigh(snr_idx) = mean(errors_rayleigh);
    mean_errors_rayleigh_multipath(snr_idx) = mean(errors_rayleigh_multipath);

end
