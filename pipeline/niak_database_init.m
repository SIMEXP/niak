function struct_data = niak_database_init(labels,levels_data)

% Initialization of a database structure
%
% SYNTAX
% struct_data = niak_database_init(labels,levels_data)
%
% INPUTS
% labels            (structure) each entry of labels is a cell of string.
% levels_data   (cell of strings) a list of fields in labels in a given
%                   order.
%
% OUTPUTS
% struct_data      (structure) struct_data is such that each field at
%                   level n has subfields defined by
%                   labels.levels_data{n+1}
%
% EXAMPLE
% levels_data = {'population','subject','condition'};
% labels.population = {'healthy','AD'};
% labels.subject = {'S1','S2','S3'};
% labels.condition = {'rest','motor'};
% struct_data = niak_init_database(labels,levels_data)
%
% SEE ALSO
% niak_database2dot
%
% COMMENT
% 
% Copyright (C) 2008 Pierre Bellec

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

struct_data.vars = [];
struct_data = sub_add_levels(struct_data,labels,levels_data);

function struct_data2 = sub_add_levels(struct_data,labels,levels_data)

list_vals = getfield(labels,levels_data{1});
struct_data2 = struct_data;

if length(levels_data) == 1    
    tmp.vars = struct();
    for num_f = 1:length(list_vals)    
        struct_data2 = setfield(struct_data2,list_vals{num_f},tmp);
    end
else
    tmp.vars = struct();
    for num_f = 1:length(list_vals)
        labels2 = rmfield(labels,levels_data{1});
        levels_data2 = levels_data(2:end);
        struct_data2 = setfield(struct_data2,list_vals{num_f},sub_add_levels(tmp,labels2,levels_data2));        
    end
end    





