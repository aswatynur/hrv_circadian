% a function to convert raw ecg data to rr
% rr than is convert into rri and hr in minutes
% return: rr, rri, and hr in minutes
function [rr, rri, hr, bpfecg]=get_HR_BPM(ecg)
    % argument setup for mouse
    HR = 608;
    QS = 0.00718;
    QT = 0.03;
    QRSa = 1090;
    QRSamin = 370;
    RRmin = 0.05;
    RRmax = 0.24;
    window_size_sec = 0.005744;
    
    fs = 1000;
    lcf = 3;
    hcf = 300;
    nt = [];
    debug = 0;
    
    thr = 0.5;
    rp = 0.03;
    ws = 10;
    peaks_window = 17;
    
    % calling mhrv
    bpfecg = mhrv.ecg.bpfilt(ecg, fs, lcf, hcf, nt, debug);
    rr = mhrv.ecg.wjqrs(bpfecg, fs, thr, rp, ws);
    rri = rr(2:1:end) - rr(1:1:end-1);
    hr = groupcounts(floor(rr/(60*1000))'); % per minute
end