addpath(genpath(pwd));
fprintf('Running super cool test now\n');
fprintf(sprintf('%s\n',pwd));
niak_test_all (struct, struct('flag_test', true));
fprintf('\nJust ran supercool test\n');
