%% Applying Tone Mapping to CT Data Enabling Simultaneus Display of Bony and Soft-Tissue Structures
%
% Andreas Husch
% Centre Hospitalier de Luxembourg, Dep. of Neurosurgery /
% University of Luxembourg - Luxembourg Centre for Systems Biomedicine
% 2016 - 2017
% mail@andreashusch.de, husch.andreas@chl.lu
function CTColormapRGB()
linearColormapR = nan(4096,1);
linearColormapG = nan(4096,1);
linearColormapB = nan(4096,1);

linearColormapR(1:1024) = linspace(1,0,length(1:1024));
linearColormapG(1025:1125) = linspace(0,1,length(1025:1125));

linearColormapB(1126:1525) = linspace(1,0,length(1126:1525));

linearColormapR(1526:4096) = linspace(0,1,length(1526:4096));

% have the neighbor regions overlapping!
linearColormapB(1126:4096) = linspace(0,1,length(1126:4096)); % increase brigthness

linearColormapRGB = [linearColormapR linearColormapG linearColormapB];
colormap(linearColormapRGB)
% %% Plot Transfer Function
% f= figure, plot(-1024:1:3071, linearColormap, 'LineWidth', 5)
% a = gca
% a.XTick = [-1024 0 100 500 3072]
% a.XGrid = 'on'
% xlabel('Data intensity [HU]')
% ylabel('Display Intensity')
% title('Piece-wise Linear Non-Monotic Tone Mapping Transfer Function')
% ChangeInterpreter(gcf,'Latex');
% 
% xlim([-1025 3073])
% pos=f.Position;
% pos(3) = 1200;
% pos(4) = 200;
% f.Position = pos;
% a.FontSize = 18;
% cmdStr = Plot2LaTeX(gcf, 'piece-wise-lin-tone-mapping');
% disp(cmdStr);
end