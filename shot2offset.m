% Input shot gather file
input_filebase = '.\09YCEW180-shot-gather\';
input_file = [input_filebase, '09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy'];

% Output folder for offset gathers
filebase = '09YCEW180-offset-gather\';
if ~exist(filebase, 'dir')
    mkdir(filebase);
end

% Offset bin width
bin_width = 50;

% Open the input SEG-Y file
fid = fopen(input_file, 'r');
fseek(fid, 3600, 'bof');
info = dir(input_file);
file_size = info.bytes;

% Read first trace header to determine trace length
trace_header = fread(fid, 240, 'uchar');
num_samples = trace_header(115)*256 + trace_header(116);
trace_length = 240 + num_samples * 4;

% Total number of traces
num_traces = floor((file_size - 3600) / trace_length);

% Rewind
fseek(fid, 3600, 'bof');

% Preallocate
trace_headers = zeros(240, num_traces, 'uint8');
trace_data = zeros(num_samples, num_traces, 'single');
offsets = zeros(num_traces, 1);
offset_bins = [];

% Read all trace headers and data
for i = 1:num_traces
    header = fread(fid, 240, 'uint8');
    data = fread(fid, num_samples, 'float32');

    trace_headers(:, i) = header;
    trace_data(:, i) = data;

    % Compute offset from SrcX, SrcY and RecX, RecY
    SrcX = typecast(flip(uint8(header(73:76))), 'int32');
    SrcY = typecast(flip(uint8(header(77:80))), 'int32');
    RecX = typecast(flip(uint8(header(81:84))), 'int32');
    RecY = typecast(flip(uint8(header(85:88))), 'int32');
    % Remember to divide 10 for th
    offsets(i) = sqrt(single((RecX - SrcX)^2 + (RecY - SrcY)^2))/10;

    % Determine which offset bin it falls into
    bin_index = floor((offsets(i)) / bin_width);
    offset_bins(i) = bin_index;
end

fclose(fid);

% Get unique bins
unique_bins = unique(offset_bins);

% --- Write each offset gather to a new SEG-Y file ---
% --- Primary: Offset bin (already done) ---
% --- Secondary: CMP number (bytes 21–24, ascending) ---
% --- Quaternary: Trace_Sequence_No (bytes 5–8, ascending) ---
% --- Tertiary: Field_Record_NOs (bytes 9–12, ascending) ---
for j = 1:length(unique_bins)
    bin_idx = unique_bins(j);
    offset_val = bin_idx * bin_width + 25;  % center-ish value for naming
    out_file = sprintf('%s09YCEW180-SCAMP1-gdm1700m-5s2ms-offset-%d.segy', filebase, offset_val);

    % Find traces in this bin
    indices = find(offset_bins == bin_idx);
    
    if isempty(indices)
        continue;
    end

    % --- Extract CMP and Channel Numbers ---
    CMPs = zeros(length(indices), 1);
    Trace_Sequence_No = zeros(length(indices), 1);
    Field_Record_NOs = zeros(length(indices), 1);
    for k = 1:length(indices)
        idx = indices(k);
        header = trace_headers(:, idx);
        CMPs(k) = typecast(flip(uint8(header(21:24))), 'int32');    % CMP
        Trace_Sequence_No(k) = typecast(flip(uint8(header(5:8))), 'int32');% Channel
        Field_Record_NOs(k) = typecast(flip(uint8(header(9:12))), 'int32');    % CMP
    end

    % --- Sort by CMP, then Channel ---
    sort_matrix = [CMPs, Trace_Sequence_No, Field_Record_NOs];
    [~, sort_order] = sortrows(sort_matrix, [1, 2, 3]); % sort by CMP, Field_Record_NOs, then Channel
    sorted_indices = indices(sort_order);

    % --- Write to SEG-Y ---
    fid_out = fopen(out_file, 'w');

    % Copy the original 3600-byte header
    fid_in = fopen(input_file, 'r');
    header3600 = fread(fid_in, 3600, 'uint8');
    fclose(fid_in);
    fwrite(fid_out, header3600, 'uint8');

    % Write sorted traces
    for k = 1:length(sorted_indices)
        idx = sorted_indices(k);
        fwrite(fid_out, trace_headers(:, idx), 'uint8');
        fwrite(fid_out, trace_data(:, idx), 'float32');
    end

    fclose(fid_out);
    fprintf('Wrote %d sorted traces to %s\n', length(sorted_indices), out_file);
end

fprintf('Offset gather sorting complete.\n');

