function ea_compat_data

if exist([ea_getearoot,'templates',filesep,'mni_hires_t1.nii'],'file');
    movefile([ea_getearoot,'templates'], [ea_getearoot,'templates_temp']);
    mkdir([ea_getearoot,'templates',filesep,'space',filesep]);
    movefile([ea_getearoot,'templates_temp'],[ea_getearoot,'templates',filesep,'space',filesep,'MNI_ICBM_2009b_NLIN_ASYM']);
    %rmdir([ea_getearoot,'templates',filesep,'space',filesep,'MNI_ICBM_2009b_NLIN_ASYM',filesep,'space'],'s')
    movefile([ea_getearoot,'atlases'],[ea_getearoot,'templates',filesep,'space',filesep,'MNI_ICBM_2009b_NLIN_ASYM',filesep,'atlases']);
    
    movefile([ea_space,'mni_hires_t1.nii'],[ea_space,'t1.nii']);
    movefile([ea_space,'mni_hires_t2.nii'],[ea_space,'t2.nii']);
    movefile([ea_space,'mni_hires_pd.nii'],[ea_space,'pd.nii']);
    movefile([ea_space,'mni_hires_fa.nii'],[ea_space,'fa.nii']);
    movefile([ea_space,'mni_hires_bb.nii'],[ea_space,'bb.nii']);
    movefile([ea_space,'mni_hires_c1mask.nii'],[ea_space,'c1mask.nii']);
    movefile([ea_space,'mni_hires_c2mask.nii'],[ea_space,'c2mask.nii']);
    movefile([ea_space,'TPM_2009b.nii'],[ea_space,'TPM.nii']);
    movefile([ea_space,'mni_hires_distal.nii'],[ea_space,'distal.nii']);
    movefile([ea_space,'mni_hires_wires.mat'],[ea_space,'wires.mat']);
end

if ~exist([ea_space,'norm_mapping.mat'],'file')
    norm_mapping={{'t1'},{'t1'}
        {'t2'},{'t2'}
        {'pd'},{'pd'}
        {'fa'},{'fa'}
        {'*'},{'t1'}
        };
    templates={'t1','t2','pd','fa'};
    save([ea_space,'norm_mapping.mat'],'norm_mapping','av_templates');
    
end

if exist([ea_space,'distal.nii'],'file')
   movefile( [ea_space,'distal.nii'],[ea_space,'atlas.nii']);
end
