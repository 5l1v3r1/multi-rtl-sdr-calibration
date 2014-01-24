function [FCCH_pos, first_round_pos, FCCH_snr, sampling_ppm, carrier_ppm, r] = FCCH_fine_correction(s, base_position, oversampling_ratio, carrier_freq)
first_round_pos = 0;
FCCH_snr = 0;
sampling_ppm = 0;
carrier_ppm = 0;
r = 0;

symbol_rate = (1625/6)*1e3;
sampling_rate = symbol_rate*oversampling_ratio;

len_FCCH_CW = 148; % GSM spec. 1x rate
fft_len = len_FCCH_CW*oversampling_ratio;

num_fcch_hit = length(base_position);
FCCH_pos = inf.*ones(1, num_fcch_hit);

len_s_ov = length(s);
len_s = floor( len_s_ov/oversampling_ratio );

max_offset = 48;
last_idx = 0;
for i=1:num_fcch_hit
    position = base_position(i);
    
    if (position+max_offset) > (len_s-len_FCCH_CW+1); % run out of sampled signal
        last_idx = i-1;
        break;
    end

    sp = position - max_offset;
    ep = position + max_offset;
    
    sp = (sp - 1)*oversampling_ratio + 1;
    ep = (ep - 1)*oversampling_ratio + 1;

    len = ep - sp + 1;
    
    fft_mat = toeplitz(s(sp:(ep+fft_len-1)), [s(sp) zeros(1, len-1)]);
    fft_mat = fft_mat(len:end, end:-1:1);
    [fft_peak_val, ~] = max( abs( fft(fft_mat, fft_len, 1) ).^2, [], 1 );
    
    [~, max_idx] = max(fft_peak_val);
    
    if max_idx==1 || max_idx==len
        disp('FCCH Warning! no peak around base position is found!');
        FCCH_pos = -1;
        return;
    else
        FCCH_pos(i) = sp + max_idx - 1;
        last_idx = i;
    end
end
FCCH_pos = FCCH_pos(1:last_idx);
first_round_pos = FCCH_pos;

% estimate and correct sampling time error
if last_idx >= 5
    sp = FCCH_pos(1);
    r = s(sp:end);
    diff_seq = diff(FCCH_pos);
    
    num_sym_per_slot = 625/4;
    num_slot_per_frame = 8;
    num_sym_per_frame = num_sym_per_slot*num_slot_per_frame;
    
    num_sym_between_FCCH_ov = 10*num_sym_per_frame*oversampling_ratio;
    num_sym_between_FCCH1_ov = 11*num_sym_per_frame*oversampling_ratio; % in case the last idle frame of the multiframe
    
    max_ppm = 250;
    max_th = floor( num_sym_between_FCCH_ov*max_ppm*1e-6 );
    max_th1 = floor( num_sym_between_FCCH1_ov*max_ppm*1e-6 );
    
    a = diff_seq - num_sym_between_FCCH_ov; 
    a_logical = abs(a)<max_th;
    num_distance_a = sum(a_logical);
    
    b = diff_seq - num_sym_between_FCCH1_ov;
    b_logical = abs(b)<max_th1;
    num_distance_b = sum(b_logical);
    
    if (num_distance_a + num_distance_b) ~= last_idx-1
        disp('It is abnormal!');
        return;
    end
    
    ex_percent = zeros(1, last_idx-1);
    ex_percent(a_logical) = a(a_logical)./num_sym_between_FCCH_ov;
    ex_percent(b_logical) = b(b_logical)./num_sym_between_FCCH1_ov;
    mean_ex_percent = mean(ex_percent);
    sampling_ppm = mean_ex_percent*1e6;
    
    if mean_ex_percent >= 0
        max_len = floor( length(r)/(1+mean_ex_percent) );
    else
        max_len = length(r);
    end
    interp_seq = (0:(max_len-1)).*(1+mean_ex_percent);
    
    r = interp1((0 : (length(r)-1)), r, interp_seq, 'linear');
    
    step_size = zeros(1, last_idx-1);
    step_size(a_logical) = num_sym_between_FCCH_ov;
    step_size(b_logical) = num_sym_between_FCCH1_ov;
    FCCH_pos = cumsum([1 step_size]);
    
    if (FCCH_pos(end) + fft_len-1) > length(r)
        FCCH_pos = FCCH_pos(1:(end-1));
    end
end

num_fcch = length(FCCH_pos);
% estimate and correct carrier freqeuncy error
if num_fcch >= 5
    fcch_mat = zeros(fft_len, num_fcch);
    for i=1:num_fcch
        sp = FCCH_pos(i);
        fcch_mat(:,i) = r(sp:(sp+fft_len-1));
    end
    fd_fcch = abs(fft(fcch_mat, fft_len, 1)).^2;
    fd_fcch = [fd_fcch( ((fft_len/2)+1):end, : ); fd_fcch( 1:(fft_len/2), : )];
    [~, max_idx] = max(fd_fcch, [], 1);
    int_phase_rotate = 2.*pi.*(max_idx - ((fft_len/2) + 1 ) )./fft_len;
    fcch_mat = fcch_mat.*exp( -1i.*((0:(fft_len-1))')*int_phase_rotate );
    phase_rotate = exp( 1i.*angle( fcch_mat(2:end,:) ) )./exp( 1i.*angle( fcch_mat(1:(end-1),:) ) );
    phase_rotate = angle(mean(phase_rotate,1));
    fo = mean( sampling_rate.*(int_phase_rotate + phase_rotate)./(2*pi) );
    target_freq = symbol_rate/4;
    carrier_ppm = 1e6*(fo - target_freq)/carrier_freq;
    
    comp_freq = target_freq - fo;
    comp_phase_rotate = comp_freq*2*pi/sampling_rate;
    r = r.*exp(1i.*(0:(length(r)-1)).*comp_phase_rotate);
end
