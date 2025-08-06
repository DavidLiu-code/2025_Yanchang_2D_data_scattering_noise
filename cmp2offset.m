% --- Configuration ---

% Input CMP gather directory
cmp_dir = '09YCEW180-cmp-gather\';
cmp_files = dir(fullfile(cmp_dir, '*.segy'));

% Output folder for sorted offset gathers
offset_output_dir = '09YCEW180-offset-gather\';
if ~exist(offset_output_dir, 'dir')
    mkdir(offset_output_dir);
end

% Offset bin width (in meters)
bin_width = 50;

% Placeholder for headers and data
all_headers = {};
all_data = {};
num_samples = [];

fprintf('Starting Pass 1: Reading all cmp traces and grouping by offset...\n');
% Loop through all offset gather files and collect traces
for i = 1:length(cmp_files)
    file_path = fullfile(cmp_dir, cmp_files(i).name);
    fid = fopen(file_path, 'r');
    fprintf('Reading cmp file: %s\n', cmp_files(i).name);

    if fid < 0
        warning('Cannot open file: %s', cmp_files(i).name);
        continue;
    end
    
    % Read 3600-byte header
    file_header = fread(fid, 3600, 'uint8');

    % Get file size and number of traces
    fseek(fid, 0, 'eof');
    file_size = ftell(fid);
    fseek(fid, 3600, 'bof');

    trace_header = fread(fid, 240, 'uint8');
    ns = trace_header(115)*256 + trace_header(116); % samples
    num_samples = ns;
    trace_len = 240 + ns * 4;
    num_traces = floor((file_size - 3600) / trace_len);

    % Rewind to read all traces
    fseek(fid, 3600, 'bof');

    for j = 1:num_traces
        header = fread(fid, 240, 'uint8');
        data = fread(fid, ns, 'float32');
        all_headers{end+1} = header;
        all_data{end+1} = data;
    end

    fclose(fid);
end

% Convert to matrix
num_total = length(all_headers);
trace_headers = zeros(240, num_total, 'uint8');
trace_data = zeros(num_samples, num_total, 'single');

for i = 1:num_total
    trace_headers(:, i) = all_headers{i};
    trace_data(:, i) = all_data{i};
end

% Extract sort keys
% --- Write each offset gather to a new SEG-Y file ---
% --- Primary: Offset bin (already done) ---
% --- Secondary: CMP number (bytes 21–24, ascending) ---
% --- Quaternary: Trace_Sequence_No (bytes 5–8, ascending) ---
% --- Tertiary: Field_Record_NOs (bytes 9–12, ascending) ---

for i = 1:num_total
    h = trace_headers(:, i);
    % Compute offset from SrcX, SrcY and RecX, RecY
    SrcX = typecast(flip(uint8(h(73:76))), 'int32');
    SrcY = typecast(flip(uint8(h(77:80))), 'int32');
    RecX = typecast(flip(uint8(h(81:84))), 'int32');
    RecY = typecast(flip(uint8(h(85:88))), 'int32');

    scalar= typecast(flip(uint8(h(71:72))), 'int16');
    if scalar == 0
       scalar = 10;
    end
    % Remember to divide scalar=10 for th
    offsets(i) = sqrt(single((RecX - SrcX)^2 + (RecY - SrcY)^2))/scalar;

    % Determine which offset bin it falls into
    bin_index = floor((offsets(i)) / bin_width);
    offset_bins(i) = bin_index;
end


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
    out_file = sprintf('%s09YCEW180-SCAMP1-gdm1700m-5s2ms-offset-%d.segy', offset_output_dir, offset_val);

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