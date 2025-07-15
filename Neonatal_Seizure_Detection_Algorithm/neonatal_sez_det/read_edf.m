function [dat, hdr, label, fs, scle, offs] = read_edf(filename)
    fid = fopen(filename, 'r');

    hdr = cell(1);
    hdr{1} = fread(fid, 256, 'char');  % Fixed header
    len_s = str2num(char(hdr{1}(235:244))');       % Number of data records
    rec_dur = str2num(char(hdr{1}(244:252))');     % Duration of data record in seconds
    ns = str2num(char(hdr{1}(253:256))');          % Number of signals

    hdr{2} = fread(fid, ns*16, 'char');  % Labels
    hdr{3} = fread(fid, ns*80, 'char');  % Transducer
    hdr{4} = fread(fid, ns*8, 'char');   % Physical dimension (e.g., uV)
    hdr{5} = fread(fid, ns*8, 'char');   % Physical minimum
    hdr{6} = fread(fid, ns*8, 'char');   % Physical maximum
    hdr{7} = fread(fid, ns*8, 'char');   % Digital minimum
    hdr{8} = fread(fid, ns*8, 'char');   % Digital maximum

    % Extract scaling info
    label = cell(1, ns);
    phy_lo = zeros(1, ns);
    phy_hi = zeros(1, ns);
    dig_lo = zeros(1, ns);
    dig_hi = zeros(1, ns);

    for jj = 1:ns
        rf2 = jj*8; rf1 = rf2-7; 
        label{jj} = strtrim(char(hdr{2}((jj-1)*16+1 : jj*16)));
        phy_lo(jj) = str2double(char(hdr{5}(rf1:rf2))');
        phy_hi(jj) = str2double(char(hdr{6}(rf1:rf2))');
        dig_lo(jj) = str2double(char(hdr{7}(rf1:rf2))');
        dig_hi(jj) = str2double(char(hdr{8}(rf1:rf2))');
    end

    scle = (phy_hi - phy_lo) ./ (dig_hi - dig_lo);
    offs = (phy_hi + phy_lo) / 2;

    hdr{9} = fread(fid, ns*80, 'char');     % Pre-filtering
    hdr{10} = fread(fid, ns*8, 'char');     % Samples per record
    nsamp = str2num(char(hdr{10})');
    hdr{11} = fread(fid, ns*32, 'char');    % Reserved

    fs = nsamp / rec_dur;

    % Preallocate
    dat = cell(1, ns);
    for jj = 1:ns
        dat{jj} = int16(zeros(1, len_s * nsamp(jj)));
    end

    % Read data
    for ii = 1:len_s
        for jj = 1:ns
            r1 = nsamp(jj)*(ii-1)+1;
            r2 = nsamp(jj)*ii;
            dat{jj}(r1:r2) = fread(fid, nsamp(jj), 'short')';
        end
    end

    fclose(fid);
end
