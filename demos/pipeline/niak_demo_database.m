
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization of the root of the database : common variables   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
struct_data.vars.path_data = '/data/aces/aces1/pbellec/database/FRB/';
struct_data.vars.TR = 4;
levels_data = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First level : population  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up the context-dependent variables
list_vars = struct(); 
list_vars(1).vars.folder_population = 'controls';
list_vars(2).vars.folder_population = 'patients';

% Adding new fields in the 1st level
list_fields = {'healthy','AD'};
[struct_data,levels_data] = niak_database_add_level(struct_data,levels_data,'population',list_fields,list_vars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Second level : subject  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
levels_data{end+1} = 'subject';

% Setting up the context-dependent variables
list_vars = struct(); 
list_vars.vars = struct();

% Generating subject labels in population 'healthy'
list_fields = cell([5 1]); 
for num_s = 1:length(list_fields)
    list_fields{num_s} = cat(2,'S',num2str(num_s));
end
struct_data.healthy = niak_database_add_fields(struct_data.healthy,list_fields,list_vars);

% Generating patient labels in population 'AD'
list_fields = cell([3 1]); 
for num_s = 1:length(list_fields)
    list_fields{num_s} = cat(2,'P',num2str(num_s));
end
struct_data.AD = niak_database_add_fields(struct_data.AD,list_fields,list_vars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Third levels : condition    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up the context-dependent variables
list_vars = struct(); 
list_vars.vars = struct();

% Adding new field at every 2nd level node
list_fields = {'rest','motor'};
[struct_data,levels_data] = niak_database_add_level(struct_data,levels_data,'condition',list_fields,list_vars);

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fourht level : run  %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up the context-dependent variables
list_vars = struct(); 
list_vars.vars = struct();

% Adding new field at every 3rd level node
list_fields = {'run1','run2'};
[struct_data,levels_data] = niak_database_add_level(struct_data,levels_data,'run',list_fields,list_vars);

% !! the 2nd patient only completed one run in condition rest ...
struct_data.AD.P2.rest = rmfield(struct_data.AD.P2.rest,'run2');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Visualization of the database as a dot graph %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
niak_visu_database(struct_data,levels_data)
