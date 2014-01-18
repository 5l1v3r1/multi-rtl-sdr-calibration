function [hit_flag, hit_idx] = specific_fft_snr_fix_avg(s, target_set, fft_len, th, avg_snr)
hit_flag = false;
hit_idx = -1;

for count=1:length(target_set)
    i = target_set(count);
    chn_tmp = s(i:(i+fft_len-1));
    chn_tmp = abs(fft(chn_tmp, fft_len)).^2;
    signal_power = max(chn_tmp);
    noise_power = sum(chn_tmp) - signal_power;
    snr = 10.*log10(signal_power/noise_power);
    
    peak_to_avg = snr - avg_snr;

    if peak_to_avg > th
        hit_flag = true;
        disp(['Hit. idx ' num2str(i) '; SNR ' num2str(snr) 'dB; peak SNR to avg SNR ' num2str(peak_to_avg) 'dB']);
        break;
    end
end

if hit_flag
    hit_idx = i;
end
