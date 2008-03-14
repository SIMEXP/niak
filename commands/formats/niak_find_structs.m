function mask = niak_find_structs(data,tags)

% Select a subset of entries in a structure based on a list of
% acceptable (string) values for some given fields
%
% SYNTAX:
% MASK = NIAK_FIND_STRUCTS(DATA,TAGS)
%
% INPUTS:
% DATA       (Structure) arbitrary number of entries and arbitrary fields.
% TAGS       (Structure) Arbitrary fields whose values are either
%               strings or cell of strings.
%
% OUTPUTS:
% MASK      (binary vector) MASK has the same size as DATA. MASK(i)==1 if
%               the following conditions are verified : 
%               For each field of TAGS that is present in DATA, this field
%               should be either a string or a cell of strings, and one of
%               the(se) value(s) at least should be present if the
%               corresponding entry of TAGS.
%
% EXAMPLE:
% data(1).subject = 'Subj1'; data(1).condition = 'motor';
% data(2).subject = 'Subj1'; data(2).condition = 'rest';
% data(3).subject = 'Subj1'; data(3).condition = 'visual';
% data(4).subject = 'Subj2'; data(4).condition = 'motor';
% data(5).subject = 'Subj2'; data(5).condition = 'rest';
% data(6).subject = 'Subj2'; data(6).condition = 'visual';
% % Select all data for subject 'Subj1'
% tags.subject = 'Subj1';
% mask = niak_find_structs(data,tags);
% data2 = data(mask)
% % Select conditions 'rest', 'motor' and 'toto' for subject 'Subj1'
% tags.subject = 'Subj1';
% tags.condition = {'rest','motor','toto'};
% mask = niak_find_structs(data,tags);
% data2 = data(mask)
%
% COMMENTS:
% Selection of entries in DATA will not change the order of entries.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : structure

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

list_field = fieldnames(tags);
nb_field = length(list_field);
nb_entries = length(data);

for num_f = 1:length(list_field)
    list_val{num_f} = getfield(tags,list_field{num_f});
    if ischar(list_val{num_f})
        list_val{num_f} = {list_val{num_f}};
    end
end
   
mask = zeros([nb_entries 1]);
flag_first = ones([nb_entries 1]);

for num_f = 1:nb_field

    if isfield(data,list_field(num_f))

        for num_a = 1:nb_entries

            act_val = getfield(data(num_a),list_field{num_f});

            if ischar(act_val)
                act_val = {act_val};
            end
                
            test_f = max(ismember(act_val,list_val{num_f}));

            if (flag_first(num_a) == 1)
                flag_first(num_a) = 0;
                mask(num_a) = test_f;
            else
                mask(num_a) = mask(num_a) & test_f;
            end

        end % Loop over all entries of data

    end % Test if the tag field is present in data

end % Loop over all fields of tags

mask = mask > 0;