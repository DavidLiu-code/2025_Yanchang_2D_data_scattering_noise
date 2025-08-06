% Input CMP gather file
input_filebase = '.\09YCEW180-shot-gather\';
input_file = [input_filebase, '09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy'];

% Output folder for CMP gathers (by CMP number)
cmp_output_dir = '09YCEW180-cmp-gather\';
if ~exist(cmp_output_dir, 'dir')
    mkdir(cmp_output_dir);
end

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

% Rewind to first trace
fseek(fid, 3600, 'bof');

% Preallocate storage
trace_headers = zeros(240, num_traces, 'uint8');
trace_data = zeros(num_samples, num_traces, 'single');
h= zeros(240, 1, 'uint8');
% Preallocate storage for sort keys
CMPs = zeros(num_traces, 1, 'int32');
CMP_Sequential_No = zeros(num_traces, 1, 'int32');
Offsets = zeros(num_traces, 1);


for i = 1:num_traces
    h(:,1) = fread(fid, 240, 'uint8');
    data = fread(fid, num_samples, 'float32');

    trace_headers(:, i) = h;
    trace_data(:, i) = data;

    % Extract sort keys
    CMPs(i) = typecast(flip(h(21:24)), 'int32');
    CMP_Sequential_No(i) = typecast(flip(h(25:28)), 'int32');

    SrcX = double(typecast(flip(h(73:76)), 'int32'));
    SrcY = double(typecast(flip(h(77:80)), 'int32'));
    RecX = double(typecast(flip(h(81:84)), 'int32'));
    RecY = double(typecast(flip(h(85:88)), 'int32'));

    Offsets(i) = sqrt((RecX - SrcX)^2 + (RecY - SrcY)^2);

end
fclose(fid);

% Sort by CMP_No, CMP_Seq_No, Offset
sort_matrix = [CMPs, CMP_Sequential_No, Offsets];
[~, sort_order] = sortrows(sort_matrix, [1, 2, 3]);

% Apply sorting
sorted_headers = trace_headers(:, sort_order);
sorted_data = trace_data(:, sort_order);
CMPs = CMPs(sort_order);  % Also reorder CMPs to match

% Use a 3600-byte header from one of the original files
fid_in = fopen(input_file, 'r');
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