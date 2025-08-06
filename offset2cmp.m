% Directory containing offset gather files
offset_dir = '09YCEW180-offset-gather\';
offset_files = dir(fullfile(offset_dir, '*.segy'));

% Output CMP gather directory
cmp_output_dir = '09YCEW180-cmp-gather\';
if ~exist(cmp_output_dir, 'dir')
    mkdir(cmp_output_dir);
end

% Placeholder for headers and data
all_headers = {};
all_data = {};
num_samples = [];

% Loop through all offset gather files and collect traces
for i = 1:length(offset_files)
    file_path = fullfile(offset_dir, offset_files(i).name);
    fid = fopen(file_path, 'r');

    if fid < 0
        warning('Cannot open file: %s', offset_files(i).name);
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
CMPs = zeros(num_total, 1);
CMP_Sequential_No = zeros(num_total, 1);
Offsets = zeros(num_total, 1);

for i = 1:num_total
    h = trace_headers(:, i);
    CMPs(i) = typecast(flip(h(21:24)), 'int32');
    CMP_Sequential_No(i) = typecast(flip(h(25:28)), 'int32');

    SrcX = double(typecast(flip(h(73:76)), 'int32'));
    SrcY = double(typecast(flip(h(77:80)), 'int32'));
    RecX = double(typecast(flip(h(81:84)), 'int32'));
    RecY = double(typecast(flip(h(85:88)), 'int32'));

    Offsets(i) = sqrt((RecX - SrcX)^2 + (RecY - SrcY)^2);
end

% Sort by CMP_No, CMP_Seq_No, Offset
sort_matrix = [CMPs, CMP_Sequential_No, Offsets];
[~, sort_order] = sortrows(sort_matrix, [1, 2, 3]);

% Apply sorting
sorted_headers = trace_headers(:, sort_order);
sorted_data = trace_data(:, sort_order);
CMPs = CMPs(sort_order);  % Also reorder CMPs to match

% Use a 3600-byte header from one of the original files
fid_in = fopen(fullfile(offset_dir, offset_files(1).name), 'r');
text_header = fread(fid_in, 3600, 'uint8');
fclose(fid_in);

% Unique CMPs
unique_CMPs = unique(CMPs);

% Write each CMP gather to a separate file
for i = 1:length(unique_CMPs)
    cmp_no = unique_CMPs(i);
    indices = find(CMPs == cmp_no);

    if isempty(indices)
        continue;
    end

    out_file = sprintf('%s09YCEW180-CMP-%06d.segy', cmp_output_dir, cmp_no);
    fid_out = fopen(out_file, 'w');

    % Write 3600-byte SEG-Y header
    fwrite(fid_out, text_header, 'uint8');

    % Write selected traces
    for k = 1:length(indices)
        idx = indices(k);
        fwrite(fid_out, sorted_headers(:, idx), 'uint8');
        fwrite(fid_out, sorted_data(:, idx), 'float32');
    end

    fclose(fid_out);
    fprintf('Wrote CMP gather %06d with %d traces to %s\n', cmp_no, length(indices), out_file);
end

fprintf('\n✅ CMP gather sorting complete.\n');
