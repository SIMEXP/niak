function [flag_err,msg_err] = niak_visu_database(struct_data,levels_data)

niak_gb_vars

file_tmp = niak_file_tmp('.dot');

[flag_err,msg_err] = niak_database2dot(struct_data,levels_data,file_tmp);

if ~(flag_err==-1)

    if strcmp(gb_niak_language,'matlab')
        
        [s,w] = system(cat(2,'dot -Tsvg ',file_tmp,' -o ',file_tmp,'.svg'));

        [s,w] = system(cat(2,gb_niak_viewersvg,' ',file_tmp,'.svg'));

        [s,w] = system(cat(2,'rm ',file_tmp,'*'));
        
    else

        system(cat(2,'dot -Tsvg ',file_tmp,' -o ',file_tmp,'.svg'));
        
        system(cat(2,gb_niak_viewersvg,' ',file_tmp,'.svg'),[],'sync');
        
        system(cat(2,'rm ',file_tmp,'*'));
        
    end

end