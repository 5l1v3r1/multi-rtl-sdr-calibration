multi-rtl-sdr-calibration README

=======================
By a enthusiast <putaoshu@msn.com> <putaoshu@gmail.com> of Software Defined Radio.

Try to process/calibrate multiple rtl-sdr dongles simultaneously.

Different dongles IQ samples are sent through different rtl_tcp instances. (rtl_tcp is a utility offered with rtl-sdr package: https://github.com/steve-m/librtlsdr.git)

Currently, it is only tested in Ubuntu Linux (12.04 LTS) You may try it in more diverse platform.

My initial purpose is performing in-fly calibration for multiple dongles according to some pre-known signals (GSM, ADS-B?) to let them work together coherently.

An ideal scheme may be that we should generate a very narrow band and very week signal in (or just located at the edge of) target working band of dongles, and perform the software in-fly calibration in background (or driver level). This would be user friendly.

I know it is far from final state currently, and many things are not clear yet (See TODO).

But please join me if you also think this is a good idea. Please see TODO firstly.

Usage
=======================
Assume that you have rtl-sdr worked correctly. (See http://sdr.osmocom.org/trac/wiki/rtl-sdr)

Quick demo after you plug dongle to your computer. (You may try more than one dongle on your computer.)

Assume that you have two dongles there, open two shell and run

  rtl_tcp -p 1234 -d 0

  rtl_tcp -p 1235 -d 1

in two shells respectively.

Then run matlab script: scan_band_power_spectrum_tcp.m to see how to use two dongles to scan a band simultaneously.

If you only have one dongle, don't forget to change num_dongle from 2 to 1 in scan_band_power_spectrum_tcp.m.

You may also define any other band according to your interests. Just modify start_freq, end_freq, etc., parameters in the script.

Detail usage example/explanation:

In matlab, I receive and process TCP streams like this:

	tcp_obj0 = tcpip('127.0.0.1', 1234); % for dongle 0
	tcp_obj1 = tcpip('127.0.0.1', 1235); % for dongle 1

	fread_len = 8192;
	set(tcp_obj0, 'InputBufferSize', fread_len);
	set(tcp_obj0, 'Timeout', 1);
	set(tcp_obj1, 'InputBufferSize', fread_len);
	set(tcp_obj1, 'Timeout', 1);

	fopen(tcp_obj0);
	fopen(tcp_obj1);
	while 1
	    [a0, real_count0] = fread(tcp_obj0, fread_len, 'uint8');
	    [a1, real_count1] = fread(tcp_obj1, fread_len, 'uint8');
	    if real_count0~=fread_len || real_count1~=fread_len
          disp(num2str([fread_len, real_count0, real_count1]));
	        continue;
	    end

	    %process samples from two dongles in varable "a0" and "a1"
	    ....
	end

See detail in script scan_band_power_spectrum_tcp.m

I also give some little tool scripts to set dongle's frequency, gain, etc.

Please see: set_gain_tcp.m, set_rate_tcp.m, set_freq_tcp.m.

Contributing
=======================
multi-rtl-sdr-calibration was started during the end of 2013 in my spare time.

You are welcome to send pull requests in order to improve the project.

See TODO list included in the source distribution first (If you want).

