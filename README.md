multi-rtl-sdr-udp-relay README

=======================
By a enthusiast <putaoshu@msn.com> <putaoshu@gmail.com> of Software Defined Radio.

Relay multiple rtl-sdr dongles IQ samples out by UDP packets for easy real-time use in Matlab or other program.

Different dongles IQ samples are sent through different UDP ports.

The relay program also can receive UDP instrction pakcet(listening port 13485), extract parameters, and set them to corresponding dongles.

Currently, it is only tested in Ubuntu Linux (12.04 LTS), and only relay to localhost/host-computer.

Some codes are copied/modified from rtl-sdr: http://sdr.osmocom.org/trac/wiki/rtl-sdr.

My initial purpose is performing in-fly calibration for multiple dongles according to some pre-known signals (GSM, ADS-B?) to let them work together coherently.

An ideal scheme may be that we should generate a very narrow band and very week signal in (or just located at the edge of) target working band of dongles, and perform the software in-fly calibration in background (or driver level). This would be user friendly.

I know it is far from final state currently, and many things are not clear yet (See TODO).

But please join me if you also think this is a good idea. Please see TODO firstly.

Build
=======================
Open a shell/command-line, and enter the directory where there is Makefile.

Type "make".


Usage
=======================
Quick demo after you successfully make: (Plug two dongles to your computer!)

  ./rtl-sdr-relay -f 905000000 -s 1000000 -b 8192 -l 8192

Then run matlab script: recv_proc_udp.m to see bursts (roughly synchronized in timeline) received from two dongles.

If you can't see obvious GSM bursts, you should replace frequency 905MHz with your local frequency where there is strong signal,
such as GSM uplink, downlink or your signal generator. 905MHz just works fine in my location (China).

Detail usage example/explanation:

	./rtl-sdr-relay -f 409987500 1090000000 -g 30 50 -s 2000000 1000000 -d 0 1 -p 6666 6667 -b 65536 131072 -l 16384 32768
	-f: multi-frequencies for multi-dongles[Hz]. If not specified, 1090000000 will be set as default.
	-g: multi-gains for multi-dongles[dB]. If not specified, automatic gain will be set as default.
	-s: multi-sample-rates for multi-dongles[Hz]. If not specified, 1000000 will be set as default.
	-d: device IDs. If not specified, all detected dongles will be involved.
	-p: UDP ports. If not specified, ports will be used begining with 6666,
	for example, 6666, 6667, 6668.... The number of ports must be equal to the number of dongles or
	the number of dongles counted from -d option.
	-b: multi-buffer-lengths for reading IQ from multi-dongles. If not specified, default value is 262144.
	-l: multi-length-of-UDP-packets for multi-dongles. If not specified, default value is 32768.
	NOTE: If only one value is given for specific parameter, the value will be used for multiple dongles.
	Otherwise, all parameters should have the same number of values.

	Press Ctrl+C to exit.

In matlab, you may receive and process UDP packets like this:

	udp_obj0 = udp('127.0.0.1', 13485, 'LocalPort', 6666); % for dongle 0
	udp_obj1 = udp('127.0.0.1', 13485, 'LocalPort', 6667); % for dongle 1

	fread_len = 8192; % max allowed
	set(udp_obj0, 'InputBufferSize', fread_len);
	set(udp_obj0, 'Timeout', 1);
	set(udp_obj1, 'InputBufferSize', fread_len);
	set(udp_obj1, 'Timeout', 1);

	fopen(udp_obj0);
	fopen(udp_obj1);
	while 1
	    [a0, real_count0] = fread(udp_obj0, fread_len, 'uint8');
	    [a1, real_count1] = fread(udp_obj1, fread_len, 'uint8');
	    if real_count0~=fread_len || real_count1~=fread_len
          disp(num2str([fread_len, real_count0, real_count1]));
	        continue;
	    end

	    %process samples from two dongles in varable "a0" and "a1"
	    ....
	end

See detail script recv_proc_udp.m

In matlab, you may send UDP packet to rtl-sdr-relay like this (Assume that there are two dongles):

  fwrite(udp_obj0, int32(round([freq, gain, samp_rate])), 'int32');

set the same frequency, gain and sampling rate parameters to two dongles.

  fwrite(udp_obj0, int32(round([freq0, gain0, samp_rate0, freq1, gain1, samp_rate1])), 'int32');

set two sets of parameters to two dongles respectively.

See detail script scan_band_power_spectrum.m

Contributing
=======================
multi-rtl-sdr-udp-relay was written during the end of 2013 in my spare time.

You are welcome to send pull requests in order to improve the project.

See TODO list included in the source distribution first (If you want).

