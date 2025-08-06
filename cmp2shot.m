% Input CMP gather directory
cmp_dir = '09YCEW180-cmp-gather\';
cmp_files = dir(fullfile(cmp_dir, '*.segy'));

% Output shot-gather file
output_file = '.\09YCEW180-shot-gather\09YCEW180-SCAMP1-gdm1700m-5s2ms-reconstructed_by_cmp.sgy';

% Placeholder for headers and data
all_headers = {};
all_data = {};
num_samples = [];

fprintf('Starting: Reading all cmp traces and grouping by shot...\n');

% Loop through all offset gather files and collect traces
for i = 1:length(cmp_files)
    file_path = fullfile(cmp_dir, cmp_files(i).name);
    fid = fopen(file_path, 'r');
    
    if fid < 0
        warning('Cannot open file: %s', cmp_files(i).name);
        continue;
    end
    
    % Read 3600-byte header
    file_header = fread(fid, 3600, 'uint8');
    fprintf('Reading cmp file: %s\n', cmp_files(i).name);

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
FFIDs = zeros(num_total, 1);
CMP_Sequential_No = zeros(num_total, 1);
CMPs = zeros(num_total, 1);
Channels = zeros(num_total, 1);

for i = 1:num_total
    h = trace_headers(:, i);
    FFIDs(i) = typecast(flip(h(9:12)), 'int32');
    CMP_Sequential_No(i) = typecast(flip(h(25:28)), 'int32');
    CMPs(i) = typecast(flip(h(21:24)), 'int32');
    Channels(i) = typecast(flip(h(13:16)), 'int32');
end

% Sort by FFID, CMP, Channel
sort_matrix = [FFIDs, CMP_Sequential_No, CMPs];
[~, sort_order] = sortrows(sort_matrix, [1, 2, 3]);

sorted_headers = trace_headers(:, sort_order);
sorted_data = trace_data(:, sort_order);

% Write to new shot gather SEG-Y file
fid_out = fopen(output_file, 'w');

% Use header from one of the offset gathers
fid_in = fopen(fullfile(cmp_dir, cmp_files(1).name), 'r');
text_header = fread(fid_in, 3600, 'uint8');
fclose(fid_in);
fwrite(fid_out, text_header, 'uint8');

% Write traces
for i = 1:num_total
    fwrite(fid_out, sorted_headers(:, i), 'uint8');
    fwrite(fid_out, sorted_data(:, i), 'float32');
end

fclose(fid_out);

fprintf('Reconstructed and sorted shot gather written to:\n%s\n', output_file);
