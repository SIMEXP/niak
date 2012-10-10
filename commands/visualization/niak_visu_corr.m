function [results]=niak_visu_corr(file_in,folder_out,db_name)
% gen a video of all the correlation matrix
% In
%   FILES_IN
%   FOLDER_OUT
%   DB_NAME
%
% Out
% 	RESULTS
%		R_MEAN Average correlation matrix
%
%		R_STD Standard deviation correlation matrix
%
%		ORDER Order of the matrix based on the average correlation matrix


  data = load(file_in);

  R_mean = niak_vec2mat(mean(data.y,1));
  R_std  = niak_vec2mat(std(data.y,[],1));

  hier = niak_hierarchical_clustering(R_mean);
  order = niak_hier2order(hier);
  opt_v.order = order;

  opt_mat.limits = [-1,1];
  f_handle_mean = figure;
  niak_visu_matrix(R_mean(order,order),opt_mat);
  title([db_name ' R mean']);
  print(f_handle_mean,[folder_out filesep 'R_all_mean.pdf'],'-dpdf');
  close(f_handle_mean);

  opt_mat.limits = [0,0.3];
  f_handle_std = figure;
  niak_visu_matrix(R_std(order,order),opt_mat);
  title([db_name ' R std']);
  print(f_handle_std,[folder_out filesep 'R_all_std.pdf'],'-dpdf');
  close(f_handle_std);

  results.R_mean = R_mean;
  results.R_std  = R_std;
  results.order  = order;

%niak_visu_motion(data.y',opt_v);

system(['mkdir ' folder_out filesep 'png' filesep ]);
opt_mat.limits = [-1,1];

% Print the correlation matrices for video
 for n_s = 1:size(data.labels_subject,1)
   R_ind = niak_vec2mat(data.y(n_s,:));
   f_handle=figure;
   niak_visu_matrix(R_ind(order,order),opt_mat);
   title([db_name ' ' data.labels_subject{n_s}]);
   print(f_handle,[folder_out filesep 'png' filesep 'R_' data.labels_subject{n_s} '.png'],'-dpng');
   close(f_handle);
  end
['mencoder mf://' folder_out filesep 'png' filesep '*.png -ovc lavc -lavcopts vcodec=msmpeg4v2 -mf fps=5 -o ' folder_out filesep 'corr_' db_name '.avi']
% Generate the video
 system(['mencoder mf://' folder_out filesep 'png' filesep '*.png -ovc lavc -lavcopts vcodec=msmpeg4v2 -mf fps=5 -o ' folder_out filesep 'corr_' db_name '.avi']);


