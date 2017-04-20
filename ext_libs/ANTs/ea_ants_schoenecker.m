function [cmd]=ea_ants_nonlinear(varargin)
% Wrapper for ANTs nonlinear registration

fixedimage=varargin{1};
movingimage=varargin{2};
outputimage=varargin{3};



if ischar(movingimage)
    movingimage={movingimage};
elseif ~iscell(movingimage)
    ea_error('Please supply variable fixedimage as either char or cellstring');
end
try
    subcorticalrefine=varargin{7};
catch
    subcorticalrefine=0;
end
slabsupport=1; % check for slabs in anat files and treat slabs differently (add additional SyN stage only in which slabs are being used).

[outputdir, outputname, ~] = fileparts(outputimage);
if outputdir
    outputbase = [outputdir, filesep, outputname];
else
    outputbase = ['.', filesep, outputname];
end

if ischar(fixedimage)
    fixedimage={fixedimage};
elseif ~iscell(fixedimage)
    ea_error('Please supply variable fixedimage as either char or cellstring');
end

if slabsupport
    disp(['Checking for slabs among structural images (assuming dominant structural file ',movingimage{end},'is a whole-brain acquisition)...']);
    tmaskdir=fullfile(tempdir,'lead');
    if ~exist(tmaskdir,'dir')
        mkdir(tmaskdir);
    end
    for mov=1:length(movingimage)
        mnii=ea_load_nii(movingimage{mov});
        mnii.img=~(mnii.img==0);
        if ~exist('AllMX','var')
            AllMX=mnii.img;
        else
            AllMX=AllMX.*mnii.img;
        end
        sums(mov)=sum(mnii.img(:));
    end
    slabspresent=0; % default no slabs present.
    
    if length(sums)>1 % multispectral warp
        slabs=sums(1:end-1)<(sums(end)*0.7);
        if any(slabs) % one image is smaller than 70% of last (dominant) image, a slab is prevalent.
            slabmovingimage=movingimage(slabs); % move slabs to new cell slabimage
            slabfixedimage=fixedimage(slabs);
            movingimage(slabs)=[]; % remove slabs from movingimage
            fixedimage(slabs)=[]; % remove slabs from fixedimage
            
            % write out slab mask
            slabspresent=1;
            mnii.dt=[4,0];
            mnii.img=AllMX;
            mnii.fname=[tmaskdir,filesep,'slabmask.nii'];
            ea_write_nii(mnii);
            disp('Slabs found. Separating slabs to form an additional SyN stage.');
        else
            disp('No slabs found.');
        end
    end
    
else
    slabspresent=0;
    impmasks=repmat({'nan'},length(movingimage),1);
end


if nargin>3
    weights=varargin{4};
    metrics=varargin{5};
    options=varargin{6};
else
    weights=ones(length(fixedimage),1);
    metrics=repmat({'MI'},length(fixedimage),1);
end


directory=fileparts(movingimage{1});
directory=[directory,filesep];



for fi=1:length(fixedimage)
    fixedimage{fi} = ea_path_helper(ea_niigz(fixedimage{fi}));
end
for fi=1:length(movingimage)
    movingimage{fi} = ea_path_helper(ea_niigz(movingimage{fi}));
end

if length(fixedimage)~=length(movingimage)
    ea_error('Please supply pairs of moving and fixed images (can be repetitive).');
end

outputimage = ea_path_helper(ea_niigz(outputimage));

basedir = [fileparts(mfilename('fullpath')), filesep];

if ispc
    HEADER = [basedir, 'PrintHeader.exe'];
    ANTS = [basedir, 'antsRegistration.exe'];
    applyTransforms = [basedir, 'antsApplyTransforms.exe'];
    
else
    HEADER = [basedir, 'PrintHeader.', computer('arch')];
    ANTS = [basedir, 'antsRegistration.', computer('arch')];
    applyTransforms = [basedir, 'antsApplyTransforms.', computer('arch')];
    
end



if ~ispc
    [~, imgsize] = system(['bash -c "', HEADER, ' ',fixedimage{1}, ' 2"']);
else
    [~, imgsize] = system([HEADER, ' ', fixedimage{1}, ' 2']);
end

imgsize = cellfun(@(x) str2double(x),ea_strsplit(imgsize,'x'));

% Rigid stage
rigidconvergence='[1000x500x250x100,1e-6,10]';
rigidshrinkfactors='8x4x2x1';
rigidsmoothingssigmas='3x2x1x0';

% Affine stage
affineconvergence='[1000x500x250x100,1e-6,10]';
affineshrinkfactors='8x4x2x1';
affinesmoothingssigmas='3x2x1x0';

% 1. Mask stage
affinemask1convergence='[1000x500x250x100,1e-6,10]';
affinemask1shrinkfactors='8x4x2x1';
affinemask1smoothingssigmas='3x2x1x0';

% 2. Mask stage
affinemask2convergence='[1000x500x250x100,1e-6,10]';
affinemask2shrinkfactors='8x4x2x1';
affinemask2smoothingssigmas='3x2x1x0';


% Rigid stage

rigidstage = [' --initial-moving-transform [', fixedimage{1}, ',', movingimage{1}, ',1]' ...
    ' --transform Rigid[0.1]' ...
    ' --convergence ', rigidconvergence, ...
    ' --shrink-factors ', rigidshrinkfactors, ...
    ' --smoothing-sigmas ', rigidsmoothingssigmas, ...
    ' --masks [NULL,NULL]'];

for fi=1:length(fixedimage)
    switch metrics{fi}
        case 'MI'
            suffx=',32,Regular,0.25';
        case 'CC'
            suffx=',4';
        case 'GC'
            suffx=',15,Random,0.05';
    end
    
    try
        rigidstage=[rigidstage,...
            ' --metric ','MI','[', fixedimage{fi}, ',', movingimage{fi}, ',',num2str(weights(fi)),suffx,']'];
    catch
        keyboard
    end
end

% Affine stage

affinestage = [' --transform Affine[0.1]'...
    ' --convergence ', affineconvergence, ...
    ' --shrink-factors ', affineshrinkfactors ...
    ' --smoothing-sigmas ', affinesmoothingssigmas, ...
    ' --masks [NULL,NULL]'];

for fi=1:length(fixedimage)
    switch metrics{fi}
        case 'MI'
            suffx=',32,Regular,0.25';
        case 'CC'
            suffx=',4';
        case 'GC'
            suffx=',15,Random,0.05';
    end
    affinestage=[affinestage,...
        ' --metric ','MI','[', fixedimage{fi}, ',', movingimage{fi}, ',',num2str(weights(fi)),suffx,']'];
end

% 1. Mask stage

if slabsupport && slabspresent
    % re-add slabs to the masked stages:
    
    fixedimage=[fixedimage,slabfixedimage];
    movingimage=[movingimage,slabmovingimage];
end

affinestage_mask1 = [' --transform Affine[0.1]'...
    ' --convergence ', affineconvergence, ...
    ' --shrink-factors ', affineshrinkfactors ...
    ' --smoothing-sigmas ', affinesmoothingssigmas, ...
    ' --masks [',ea_space([],'subcortical'),'secondstepmask.nii',',NULL]'];

for fi=1:length(fixedimage)
    switch metrics{fi}
        case 'MI'
            suffx=',32,Regular,0.25';
        case 'CC'
            suffx=',4';
        case 'GC'
            suffx=',15,Random,0.05';
    end
    affinestage_mask1=[affinestage_mask1,...
        ' --metric ',metrics{fi},'[', fixedimage{fi}, ',', movingimage{fi}, ',',num2str(weights(fi)),suffx,']'];
end


% 2. Mask stage

affinestage_mask2 = [' --transform Affine[0.1]'...
    ' --convergence ', affineconvergence, ...
    ' --shrink-factors ', affineshrinkfactors ...
    ' --smoothing-sigmas ', affinesmoothingssigmas, ...
    ' --masks [',ea_space([],'subcortical'),'thirdstepmask.nii',',NULL]'];

for fi=1:length(fixedimage)
    switch metrics{fi}
        case 'MI'
            suffx=',32,Regular,0.25';
        case 'CC'
            suffx=',4';
        case 'GC'
            suffx=',15,Random,0.05';
    end
    affinestage_mask2=[affinestage_mask2,...
        ' --metric ',metrics{fi},'[', fixedimage{fi}, ',', movingimage{fi}, ',',num2str(weights(fi)),suffx,']'];
end






ea_libs_helper
%setenv('ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS','8')




cmd = [ANTS, ' --verbose 1', ...
    ' --dimensionality 3', ...
    ' --output [',ea_path_helper(outputbase), ',', outputimage, ']', ...
    ' --interpolation Linear', ...
    ' --use-histogram-matching 1', ...
    ' --float 1',...
    ' --write-composite-transform 1', ...
    rigidstage, affinestage, affinestage_mask1, affinestage_mask2];

display(cmd)

fid=fopen([directory,'ea_ants_command.txt'],'a');
fprintf(fid,[datestr(datetime('now')),':\n',cmd,'\n\n']);
fclose(fid);

if ~ispc
    system(['bash -c "', cmd, '"']);
else
    system(cmd);
end


ea_conv_antswarps(directory);