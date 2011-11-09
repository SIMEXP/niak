function versions = niak_log_version(folder_in,opt)

%%%%%%%%%%%%%%%%%
%%     SVN     %%
%%%%%%%%%%%%%%%%%

  % Look for a .svn folder in 'psom' repository
  if exist(cat(2,folder_in,'psom/.svn')) == 7
    [status,output]=system(cat(2,'svn info ',folder_in,'psom/'));
    idx = strfind(output,'Revision: ');
    idx_end = strfind(output,'Node Kind:');
    versions.svn.psom = output(idx+10:idx_end-2);
  end

  % Look for a .svn folder in 'niak' repository
  if exist(cat(2,folder_in,'niak/.svn')) == 7
    [status,output]=system(cat(2,'svn info ',folder_in,'niak/'));
    idx = strfind(output,'Revision: ');
    idx_end = strfind(output,'Node Kind:');
    versions.svn.niak = output(idx+10:idx_end-2);
  end

  % Look for a .svn folder in 'basc' repository
  if exist(cat(2,folder_in,'basc/.svn')) == 7
    [status,output]=system(cat(2,'svn info ',folder_in,'basc/'));
    idx = strfind(output,'Revision: ');
    idx_end = strfind(output,'Node Kind:');
    versions.svn.basc = output(idx+10:idx_end-2);
  end

  % Look for a .svn folder in 'bht' repository
  if exist(cat(2,folder_in,'bht/.svn')) == 7
    [status,output]=system(cat(2,'svn info ',folder_in,'bht/'));
    idx = strfind(output,'Revision: ');
    idx_end = strfind(output,'Node Kind:');
    versions.svn.bht = output(idx+10:idx_end-2);
  end

  % Look for a .svn folder in 'simus' repository
  if exist(cat(2,folder_in,'simus/.svn')) == 7
    [status,output]=system(cat(2,'svn info ',folder_in,'simus/'));
    idx = strfind(output,'Revision: ');
    idx_end = strfind(output,'Node Kind:');
    versions.svn.simus = output(idx+10:idx_end-2);
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

end