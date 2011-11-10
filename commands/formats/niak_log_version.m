function versions = niak_log_version(folder_in,opt)

%%%%%%%%%%%%%%%%%
%%     SVN     %%
%%%%%%%%%%%%%%%%%
list_library = {'psom','niak','basc','bht','simus'};

for num_l = 1:length(list_library)
  lib = list_library{num_l};
  % Look for a .svn folder in 'psom' repository
  folder_lib = fullfile(folder_in,lib,filesep);
  [status,output]=system(cat(2,'svn info ',folder_lib));
  if status ~= 0
      versions.svn.(lib) = NaN;
  else
      idx = strfind(output,'Revision: ');
      idx_end = strfind(output,'Node Kind:');
      if ~isempty(idx)&&~isempty(idx_end)
          versions.svn.(lib) = output(idx+10:idx_end-2);
      else
          versions.svn.(lib) = output;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%     Release number     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Look for the PSOM version release
if exist('psom_gb_vars') == 2
    psom_gb_vars
    versions.release.psom = gb_psom_version;
end

% Look for the NIAK version release
if exist('niak_gb_vars') == 2
    niak_gb_vars
    versions.release.niak = gb_niak_version;
end

