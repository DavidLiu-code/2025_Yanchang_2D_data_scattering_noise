% create_placeholders.m
% This script creates the required folders and puts a .placeholder file in each.

% Define output directories
output_dirs = {
    '09YCEW180-cmp-gather', ...
    '09YCEW180-offset-gather', ...
    '09YCEW180-shot-gather'
};

% Loop over each directory
for i = 1:length(output_dirs)
    dir_name = output_dirs{i};
    
    % Create directory if it does not exist
    if ~exist(dir_name, 'dir')
        mkdir(dir_name);
    end
    
    % Create a .placeholder file
    placeholder_path = fullfile(dir_name, '.placeholder');
    fid = fopen(placeholder_path, 'w');
    if fid ~= -1
        fprintf(fid, 'This file is a placeholder to preserve this directory.\n');
        fclose(fid);
    else
        warning('Failed to create placeholder in %s', dir_name);
    end
end

disp('✅ Placeholder files created successfully.');
