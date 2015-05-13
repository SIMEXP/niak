clear;
in_path = '/home/surchs/Projects/stability_abstract/data/trt';
part_path = '/home/surchs/Projects/stability_abstract/mask/part_sc10_resampled.nii.gz';
out_path = '';
% Search for the files we need and build the structure
f = dir(in_path);
in_strings = {f.name};
in_files.fmri = struct;
for f_id = 1:numel(in_strings)
    in_string = in_strings{f_id};
    [start, stop] = regexp(in_string, 'sub[0-9]*_session[0-9]+');
    if ~isempty(start) && ~isempty(stop)
        sub_name = in_string(start:stop);
        in_files.fmri.(sub_name) = [in_path filesep in_string];
    end
end

opt.folder_out = out_path;