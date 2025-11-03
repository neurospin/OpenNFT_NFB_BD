function setupFirstVolume(inpFileName)
% Function that collect operations that are required only during the first
% real-time volume processing.
%
% input:
% inpFileName - input file name
%
% output:
% Output is assigned to workspace variables.
%__________________________________________________________________________
% Copyright (C) 2016-2021 OpenNFT.org
%
% Written by Yury Koush

P = evalin('base', 'P');
mainLoopData = evalin('base', 'mainLoopData');

matTemplMotCorr = mainLoopData.matTemplMotCorr;
        
%% Read first Exported Volume, set Dimensions
disp(inpFileName)
[vol, matVol, dimVol] = getVolData(P.DataType, inpFileName, 0, P.getMAT, P.UseTCPData);
if P.getMAT
    dicomInfoVox   = [dicomInfoVol.PixelSpacing; dicomInfoVol.SpacingBetweenSlices]';
else
    dicomInfoVox   = sqrt(sum(matTemplMotCorr(1:3,1:3).^2));
end
[slNrImg2DdimX, slNrImg2DdimY, img2DdimX, img2DdimY] = getMosaicDim(dimVol);
nrVoxInVol = prod(dimVol);

%% Init memmapfile transport
% mosaic volume from root matlab to python GUI
initMemmap(P.memMapFile, 'shared', uint8(zeros(img2DdimX, img2DdimY)), ...
    'uint8', 'mmImgViewTempl');

% statVol from root matlab to helper matlab
statVol = zeros(dimVol);
initMemmap(P.memMapFile, 'statVol', zeros(nrVoxInVol,2), 'double', ...
    'mmStatVol', {'double', size(statVol), 'posStatVol'; 'double', size(statVol), 'negStatVol'});

if P.isRTQA
    rtqaVol = zeros(dimVol);
    initMemmap(P.memMapFile, 'RTQAVol', zeros(nrVoxInVol,1), 'double', ...
        'mmrtQAVol', {'double', size(rtqaVol), 'rtQAVol'});
end

% mosaic stat map to python GUI
initMemmap(P.memMapFile, 'statMap', uint8(zeros(img2DdimX*img2DdimY, 1)), 'uint8', ...
    'mmStatMap', {'uint8', [img2DdimX, img2DdimY], 'statMap'; });
initMemmap(P.memMapFile, 'statMap_neg', uint8(zeros(img2DdimX*img2DdimY, 1)), 'uint8', ...
    'mmStatMap_neg', {'uint8', [img2DdimX, img2DdimY], 'statMap_neg' });

map_template = zeros(img2DdimX,img2DdimY);
m_out =  evalin('base', 'mmStatMap');
m_out.Data.statMap = uint8(map_template);
assignin('base', 'statMap', map_template);

m_out =  evalin('base', 'mmStatMap_neg');
m_out.Data.statMap_neg = uint8(map_template);
assignin('base', 'statMap_neg', map_template);


%% transfer background mosaic to Python
imgVolTempl = mainLoopData.imgVolTempl;
imgViewTempl = vol3Dimg2D(imgVolTempl, slNrImg2DdimX, slNrImg2DdimY, ...
    img2DdimX, img2DdimY, dimVol);
imgViewTempl = uint8((imgViewTempl) / max(max(imgViewTempl)) * 255);
assignin('base', 'imgViewTempl', imgViewTempl);

m = evalin('base', 'mmImgViewTempl');
shift = 0 * length(imgViewTempl(:)) + 1;
m.Data(shift:end) = imgViewTempl(:);

mainLoopData.dimVol = dimVol;
mainLoopData.matVol = matVol;
mainLoopData.dicomInfoVox = dicomInfoVox;
mainLoopData.img2DdimX = img2DdimX;
mainLoopData.img2DdimY = img2DdimY;
mainLoopData.slNrImg2DdimX = slNrImg2DdimX;
mainLoopData.slNrImg2DdimY = slNrImg2DdimY;
mainLoopData.nrVoxInVol = nrVoxInVol;

assignin('base', 'mainLoopData', mainLoopData);
assignin('base', 'P', P);
end

