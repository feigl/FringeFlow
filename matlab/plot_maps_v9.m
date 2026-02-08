% plot maps of average velocity at Sites MCGIN, DCAMP
% 2024/05/15 Kurt Feigl
% 2024/07/17 adapt for TSX
% 2024/08/04
% 2024/09/02 v.5 generalize
% 2025/04/10 adapt for delivery
% 2025/04/12 v.6 write CSV files
% 2025/04/15 v.7 write PDF files, too
% 2025/04/16 update to handle DCAMP
% 2025/05/20 adapt for Matlab R2024B on MBpro
% 2025/12/09 still on iMac
% 2025/12/18 v9 on FringeFlow

clear variables;
close all;

% use GIPhT functions
giphtpath

%% add shared software
giphtpath
switch computer('arch')
    case 'maci64'
        gdir='/Users/feigl/Desktop'
        %gdir='/Volumes/T7'
        %gdir='/Users/feigl/Library/CloudStorage/GoogleDrive-feigl@wisc.edu/Shared drives'
        rdir='/Volumes/feigl' % research drive
    case 'win64'
        gdir='G:\Shared drives'
    case 'glnxa64'
        gdir='/blah/blah'
    otherwise
        error(sprintf('unknown computer'))
end
%addpath(genpath(strrep(strcat(gdir,'/WHOLESCALEshared/Software/Matlab'),'/',filesep)),'-begin');
addpath(genpath(strrep(strcat(gdir,'/WHOLESCALE_local/Software/Matlab'),'/',filesep)),'-begin');



% constants
kilo=1000;
milli=1.E-3;
nf=0;  % number of figures
nfMaps=2; % start numbering maps
nfTser=5; % start numbering time series
minSigRatio = 2;
format compact

% Items for this script
scriptName='plot_maps_v8'
doHistogramStretch = false
doTimeSeries=true;
doMaps=true;
saveFigs=false;
saveCSVs=false;
% saveFigs=true;
% saveCSVs=true;
doRsync=true;
%sites={'MCGIN','DCAMP','SANEM','TUNGS','DIXIE'}
%sites={'MCGIN'}
%sites={'DCAMP'}
%sites={'SANEM'}
%sites={'TUNGS'}
%sites={'DIXIE'}
%sites={'BRADY'}
%sites={'EMESA'}
%sites={'BLUEM'}
sites={'LGTDK'}


%% set up file names
% 'smb://research.drive.wisc.edu/feigl/insar/FORGE/SDK'
DataDirLocal  = '/Volumes/feigl/insar'
DataDirRemote = 'emidio.ssec.wisc.edu:/data/insar'   ; % on


% defaults to be overwritten
iReferenceStyle=1;
Eref=NaN;
Nref=NaN;
refRadius=500; % dimension of reference area

%% set up HDF5 - not needed with Matlab release 2024B
% download pre-made binaries from https://www.hdfgroup.org/download-hdf5/
% setenv('HDF5_PLUGIN_PATH','/Applications/HDF_Group/HDF5/1.14.6/lib/plugin');
% getenv('HDF5_PLUGIN_PATH')

% 2025/05/20 after downloading pre-made binary from
% sudo mkdir /usr/local/hdf5
% cd /usr/local/hdf5/
% ls /Applications/HDF_Group/HDF5/1.14.6/
% sudo ln -s /Applications/HDF_Group/HDF5/1.14.6/* .

for isite = 1:numel(sites)
    site=sites{isite};
    %% Read corners
    switch site
        case 'MCGIN'
            Tcorners = readtable('/Users/feigl/siteinfo/mcgin/MGH_InSAR_AOI2024.xlsx');%,'HeaderLines',1,'FileType','text');
            [Tcorners.E,Tcorners.N,utmzone] = deg2utm(Tcorners.lat,Tcorners.lon);
            utmzone1=utmzone{1};
            writetable(Tcorners,'/Users/feigl/siteinfo/mcgin/corners.csv')
            % read wells from kml file
            %https://www.mathworks.com/matlabcentral/answers/415325-how-to-open-and-plot-kml-file-in-matlab
            % for the moment, have only power plant
            % Twells = readgeotable('/Users/feigl/siteinfo/mcgin/MGHpowerPlant.kml');
            % Twells.lat = Twells.Shape.Latitude;
            % Twells.lon = Twells.Shape.Longitude;
            % [Twells.E,Twells.N,utmzone] = deg2utm(Twells.lat,Twells.lon);
            Twells=readtable('/Users/feigl/siteinfo/mcgin/MGH_Wellhead_Coordinates.csv')
            Twells=renamevars(Twells,'Well_ID','Well_Name');
            %DataDirLocal = '/Volumes/feigl/insar/MCGIN'
            wellToWatch='61-22';
            %sSoln='14';% fails because of compression in HDF file
            %sSoln='14b' % missing inputs
            %sSoln='14era'
            %sSoln='14hcorr'
            %sSolns={'15hcorr'}; % good for debugging
            %sSolns={'15'}; % good for debugging
            %{'14era','14hcorr'};
            sSolns={'15','15era','15hcorr'}; % do all three
            % read coordinates for bedrock
            Tbedrock=geotable2table(readgeotable('/Users/feigl/siteinfo/mcgin/Bedrock.kml'),["lat" "lon"])
            %project into UTM using deg2utm
            [Tbedrock.E,Tbedrock.N,utmzone] = deg2utm(Tbedrock.lat,Tbedrock.lon);
            % use bedrock for reference pixels
            iReferenceStyle=4;
            kk=find(contains(Tbedrock.Name,"MGH_Valmy_Quartzite_Basement"));
            Eref=Tbedrock.E(kk);
            Nref=Tbedrock.N(kk);
            % % use NW corner for reference pixels
            % iReferenceStyle=5;
            % Eref=nan;
            % Nref=nan;
            % use most coherent pixel as reference pixels
            % iReferenceStyle=1;
            % Eref=nan;
            % Nref=nan;
        case 'DCAMP'
            %DataDirLocal = '/Volumes/feigl/insar/DCAMP'
            Tcorners = readtable('/Users/feigl/siteinfo/dcamp/DCAMPcorners.csv','FileType','text','Range','A1:C5');
            [Tcorners.E,Tcorners.N,utmzone] = deg2utm(Tcorners.lat,Tcorners.lon);
            % Twells=array2table(nan([1,4]),'VariableNames',{'Easting_m','Northing_m','Well_ID','Type'})
            % Twells.Easting_m=385109.00;
            % Twells.Northing_m=4299503.;
            % Twells.Well_ID='Office';
            % Twells.Type='Observation';
            Twells=readtable('/Users/feigl/siteinfo/dcamp/Collar.csv');
            Twells=renamevars(Twells,'Well_ID','Well_Name');
            % back project for use in google earth
            utmzone1=utmzone{1};
            [Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            writetable(Twells,'/Users/feigl/siteinfo/dcamp/wells.csv')
            wellToWatch='65-11';
            %sSolns={'32_33'};
            %sSolns={'33hcorr'};
            %sSolns={'33era'};
            %sSolns={'33'};
            %sSolns={'30'}
            %sSolns={'25hcorr'};
            %sSolns={'47','33hcorr','33era'} % delivered to ORMAT
            sSolns={'33era'} % good test case
            % use NE corner for reference pixels
            iReferenceStyle=6;
            Eref=nan;
            Nref=nan;

        case 'SANEM'
            % Twells=readtable('/Users/feigl/siteinfo/sanem/well_specs_wUTMandLatLon.csv');
            % Twells=renamevars(Twells,{'UTM_Easting_m','UTM_Northing_m'},{'Easting_m','Northing_m'});

            wellfile=strcat('/Users/feigl/Desktop/WHOLESCALE_local/Shutdown2022kgPers/Wells_2022_Summary_comparison.xlsx');
            Twells=readtable(wellfile);
            Twells=renamevars(Twells,'Well_ID','Well_Name');
            Twells=renamevars(Twells,'Utility','Type');
            % short 1-year test case
            % sSolns={'53'} fails due to discrepancy in AOI
            % reference is overall median - very slow
            % iReferenceStyle=0;
            % Eref=nan;
            % Nref=nan;
            % use SE corner for reference pixels
            % iReferenceStyle=7;
            % Eref=nan;
            % Nref=nan;

            % short test case
            %sSolns={'56','56era'} 

            % long case with multiple bursts
            %sSolns={'55'}
            sSolns={'55','54','55hcorr','54hcorr','55era','54era'} 

            %area around reference GPS station GARL https://geodesy.unr.edu/NGLStationPages/stations/GARL.sta
            iReferenceStyle=4;
            refRadius = 500; % half-width of square containing reference pixels [meter]
            % % 40°25'01.2"N 119°21'18.0"W
            gps_lat=  40 + 25/60 +  1.2/60/60;
            gps_lon=-119 - 21/60. -18.0/60/60;
            [Eref,Nref,~] = deg2utm(gps_lat,gps_lon);

            %sSolns={'53','AriaT42','AriaT42era','AriaT42hcorr'} % from Stanford 2024
            %sSolns={'55'}%,'55hcorr'} % ,'55era'}
            %isGeographic = true;

             wellToWatch='76-16'

        case 'BRADY'
            LIM = get_site_dims('BRADY')
            Tcorners=table([LIM.Emin,LIM.Emax, LIM.Emax, LIM.Emin]',[LIM.Nmin,LIM.Nmin,LIM.Nmax, LIM.Nmax]');
            Tcorners.Properties.VariableNames={'E','N'};
            utmzone1='11 S';
            [Tcorners.lat,Tcorners.lon]=utm2deg(Tcorners.E,Tcorners.N,repmat(utmzone1,[numel(Tcorners.E),1]));
            Twells=readtable('/Users/feigl/siteinfo/brady/brady_prd.utm','FileType','text');
            Twells.Properties.VariableNames={'Easting_m','Northing_m','Var3','Var4','Well_Name','Var6','Var7','Var8'};
            % back project for use in google earth
            [Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            [nWells,~] = size(Twells)
            for i=1:nWells
                Twells.Well_ID{i}=sprintf('%02d',i);
            end
            %Twells=renamevars(Twells,'Well_ID','Well_Name');
            %writetable(Twells,'/Users/feigl/siteinfo/dcamp/wells.csv')
            wellToWatch='27-1';
            sSolns={'63'} %    
           
            iReferenceStyle=6;   % use NE corner for reference pixels
            %iReferenceStyle=0;   % use median of whole for reference pixels
            Eref=nan;
            Nref=nan;
            refRadius = 200; % half-width of square containing reference pixels [meter]
            markerSize = 137; % in DPI
        case 'TUNGS'
            LIM = get_site_dims('TUNGS')
            Tcorners=table([LIM.Emin,LIM.Emax, LIM.Emax, LIM.Emin]',[LIM.Nmin,LIM.Nmin,LIM.Nmax, LIM.Nmax]');
            Tcorners.Properties.VariableNames={'E','N'};
            utmzone1='11 S';
            [Tcorners.lat,Tcorners.lon]=utm2deg(Tcorners.E,Tcorners.N,repmat(utmzone1,[numel(Tcorners.E),1]));
            Twells=readtable('/Users/feigl/siteinfo/tungs/tungs_wells_utm.txt');
            Twells.Properties.VariableNames={'Easting_m','Northing_m'};
            % back project for use in google earth
            [Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            [nWells,~] = size(Twells)
            for i=1:nWells
                Twells.Well_ID{i}=sprintf('%02d',i);
            end
            Twells=renamevars(Twells,'Well_ID','Well_Name');
            %writetable(Twells,'/Users/feigl/siteinfo/dcamp/wells.csv')
            wellToWatch='01';
            sSolns={'38'} %
        case 'DIXIE'
            LIM = get_site_dims('DIXIE')
            Tcorners=table([LIM.Emin,LIM.Emax, LIM.Emax, LIM.Emin]',[LIM.Nmin,LIM.Nmin,LIM.Nmax, LIM.Nmax]');
            Tcorners.Properties.VariableNames={'E','N'};
            utmzone1='11 S';
            [Tcorners.lat,Tcorners.lon]=utm2deg(Tcorners.E,Tcorners.N,repmat(utmzone1,[numel(Tcorners.E),1]));
            Twells=readtable('/Users/feigl/siteinfo/dixie/dixie_wells.txt');
            Twells.Properties.VariableNames={'Longitude','Latitude','Well_Name'};
            [Twells.Easting_m,Twells.Northing_m] = deg2utm(Twells.Latitude,Twells.Longitude);

            %Twells.Properties.VariableNames={'Easting_m','Northing_m'}
            % back project for use in google earth
            %[Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            [nWells,~] = size(Twells)
            wellToWatch='Well_24-8';
            sSolns={'39'};
            % use NW corner for reference pixels
            iReferenceStyle=5;
            Eref=nan;
            Nref=nan;
        case 'EMESA'
            LIM = get_site_dims('EMESA')
            Tcorners=table([LIM.Emin,LIM.Emax, LIM.Emax, LIM.Emin]',[LIM.Nmin,LIM.Nmin,LIM.Nmax, LIM.Nmax]');
            Tcorners.Properties.VariableNames={'E','N'};
            utmzone1='11 S';
            [Tcorners.lat,Tcorners.lon]=utm2deg(Tcorners.E,Tcorners.N,repmat(utmzone1,[numel(Tcorners.E),1]));
            %Twells=readtable('/Users/feigl/siteinfo/emesa/emesa_wells.txt');
            %Twells.Properties.VariableNames={'Longitude','Latitude','Well_Name'};
            %[Twells.Easting_m,Twells.Northing_m] = deg2utm(Twells.Latitude,Twells.Longitude);
            Twells=[];

            %Twells.Properties.VariableNames={'Easting_m','Northing_m'}
            % back project for use in google earth
            %[Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            %[nWells,~] = size(Twells)
            nWells=0
            %wellToWatch='Well_24-8';
            wellToWatch=NaN;
            sSolns={'65','36','36hcorr','36era'};            
            %iReferenceStyle=5; % use NW corner for reference pixels           
            %iReferenceStyle=1; % most coherent pixel as reference 
            %iReferenceStyle=7; % SE corner
            iReferenceStyle=3; % SE corner
            Eref=nan;
            Nref=nan;
        case 'BLUEM'
            LIM=[-Inf, +Inf, -Inf, +Inf];
            Tcorners=[];
            % TODO LIM = get_site_dims('BLUEM')
            %Tcorners=table([LIM.Emin,LIM.Emax, LIM.Emax, LIM.Emin]',[LIM.Nmin,LIM.Nmin,LIM.Nmax, LIM.Nmax]');
            %Tcorners.Properties.VariableNames={'E','N'};
            %utmzone1='11 S';
            %[Tcorners.lat,Tcorners.lon]=utm2deg(Tcorners.E,Tcorners.N,repmat(utmzone1,[numel(Tcorners.E),1]));
            %Twells=readtable('/Users/feigl/siteinfo/emesa/emesa_wells.txt');
            %Twells.Properties.VariableNames={'Longitude','Latitude','Well_Name'};
            %[Twells.Easting_m,Twells.Northing_m] = deg2utm(Twells.Latitude,Twells.Longitude);
            %Twells=[];
            Twells=table({'vmin'},404.72E3,4538.96E3);
            Twells.Properties.VariableNames={'Well_Name','Easting_m','Northing_m'}
            % back project for use in google earth
            %[Twells.Latitude,Twells.Longitude]=utm2deg(Twells.Easting_m,Twells.Northing_m,repmat(utmzone1,[numel(Twells.Easting_m),1]));
            %[nWells,~] = size(Twells)
            nWells=0
            %wellToWatch='Well_24-8';
            wellToWatch='vmin';
            sSolns={'42'};
            % use NW corner for reference pixels
            iReferenceStyle=5;
            Eref=nan;
            Nref=nan;
        case 'LGTDK' % Lightning Dock New Mexico - Zanskar
            % asking ChatGPT 
            % find latitude longitude coordinates for geothermal wells at Lightning Dock as table in CSV format
            Twells = readtable('/Users/feigl/siteinfo/lgtdk/lightning_dock_coordinates.csv');
            Twells=renamevars(Twells,'latitude', 'lat');
            Twells=renamevars(Twells,'longitude','lon');
            Twells=renamevars(Twells,'name','Well_Name');
            [Twells.Easting_m,Twells.Northing_m,utmzone] = deg2utm(Twells.lat,Twells.lon);
            [nWells,~]=size(Twells);
            % get coordinates of center
            i0=find(contains(Twells.Well_Name,'Lightning Dock Power Plant'));
            margin_meters=10000; % margin in meters
            LIM=[Twells.Easting_m(i0)-margin_meters, Twells.Easting_m(i0)+margin_meters, Twells.Northing_m(i0)-margin_meters, Twells.Northing_m(i0)+margin_meters];
            Tcorners=table([LIM(1),LIM(2), LIM(2), LIM(1)]',[LIM(3),LIM(3),LIM(4), LIM(4)]');
            Tcorners.Properties.VariableNames={'E','N'};
            utmzone1='12 S';


            wellToWatch='Well 17B-7';
            %sSolns={'66era'};
            sSolns={'64','66'};
            % select reference pixels
            %iReferenceStyle=5; % NW corner 
            %iReferenceStyle=6; % NE corner 
            %iReferenceStyle=4; % center
            %iReferenceStyle=0; % overall median - FAILS
            iReferenceStyle=7; % SE corner
            %iReferenceStyle=1; % reference pixel selected by MintPy
            Eref=nan;
            Nref=nan; 
            % iReferenceStyle=4; % use selected point 
            % bedrock near Goat Mountain
            % Eref =  711936.55 % m E
            % Nref = 3558237.30 % m N
        otherwise
            error('unknown site %s', site)
    end

    % %% choose a well
    % if ~isempty(Twells) 
    %     iWellWatch=find(strcmp(Twells.Well_Name,wellToWatch));
    %     if numel(iWellWatch) <= 0
    %         error('cannot find well %s',wellToWatch)
    %     end
    % else
    %     iWellWatch = [];
    % end


    %% choose solution
    for isoln = 1:numel(sSolns)
        sSoln=sSolns{isoln}
        switch sSoln
            % File name convention#
            % Using the underscore _ as the delimiter in the file name, the first part
            % describes the file type, while the rest parts describe the additional
            % operations. For example:
            %
            % timeseries.h5 is the raw time series
            % timeseries_ERA5.h5 is the time series after the ERA5 correction;
            % velocity.h5 is the velocity from the final displacement time series
            % velocityERA5.h5 is the velocity from ERA5 tropospheric delay (from inputs/ERA5.h5 file), not the displacement velocity after ERA5 correction.
            % timeseriesResidual.h5 is the residual phase time series
            % timeseriesResidual_ramp.h5 is the residual phase time series after deramping
            %% Sentinel by SDK in UTM
            % case 1
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy1/velocity.h5'),'/',filesep)
            % case 3
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy3/velocity.h5'),'/',filesep)
            % case 4
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy4/velocity.h5'),'/',filesep)
            % case 5
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy5/velocity.h5'),'/',filesep)
            % case 6
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy6/velocity.h5'),'/',filesep)
            % case 7
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy7/velocity.h5'),'/',filesep)
            % case 8
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy8/velocity.h5'),'/',filesep)
            % case 9
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy9/velocity.h5'),'/',filesep)
            % case 10
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy10/velocity.h5'),'/',filesep)
            % case 11
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy11/velocity.h5'),'/',filesep)
            % case 12
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy12/velocity.h5'),'/',filesep)
            % case 13  % careful this one is DCAMP
            %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy13/velocity.h5'),'/',filesep)
            % case '14'
            %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14'),'/',filesep)
            %     fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
            % case '14b'
            %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14b'),'/',filesep)
            %     fnameV=strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14b/velocity.h5'),'/',filesep)
            %     fnameG=strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14b/inputs/geometryGeo.h5'),'/',filesep)
            % case '14era'
            %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14era'),'/',filesep)
            %     fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
            %     fnameT=strrep(strcat(dname,filesep,'timeseries_ERA5.h5'),'/',filesep) % after ERA correction
            % case '14hcorr'
            %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14hcorr'),'/',filesep)
            %     fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
            %     %fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep) %raw time series
            %     fnameT=strrep(strcat(dname,filesep,'timeseries_tropHgt.h5'),'/',filesep) % what is this?
            %     % fnameT=strrep(strcat(dname,filesep,'timeseriesResidual.h5'),'/',filesep); % residual, basically zero
            case '15' % copy of 15hcorr, but look at raw files
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy15'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'avgPhaseVelocity.h5')       ,'/',filesep) % uncorrected
                fnameT=strrep(strcat(dname,filesep,'timeseries.h5')             ,'/',filesep) % raw
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5')     ,'/',filesep) % geometry
            case '15era'
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy15era'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries_ERA5.h5'),'/',filesep) % after ERA correction
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '15hcorr'
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy15hcorr'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries_tropHgt.h5'),'/',filesep) % after height_correlation correction
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry

                %fnameV=strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy14hcorr/velocity.h5'),'/',filesep)

                % case 22 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy22/velocity.h5'),'/',filesep)
                % case 23 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy23/velocity.h5'),'/',filesep)
                % case 24 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy24/velocity.h5'),'/',filesep)
                % case 25 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy25/velocity.h5'),'/',filesep)

            case '25hcorr' % DCAMP
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy25hcorr'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries_tropHgt.h5'),'/',filesep) % after height_correlation correction
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry

                % case 27 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy27/velocity.h5'),'/',filesep)
                % case 28 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy28/velocity.h5'),'/',filesep)
                % case 29 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy29/velocity.h5'),'/',filesep)
                % case 30 % DCAMP
                %     fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy30/velocity.h5'),'/',filesep)
                % case '32_33' % DCAMP
                %     %fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy32_33/velocity.h5'),'/',filesep)
                %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy32_33'),'/',filesep)
                %     fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                %     fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep) %
                %     %fnameT=strrep(strcat(dname,filesep,'timeseries_demErr.h5'),'/',filesep) %
                %     fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '30' % DCAMP
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy30'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep) %
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '33hcorr' % DCAMP
                %fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy32_33/velocity.h5'),'/',filesep)
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy33hcorr'),'/',filesep)
                % fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                % fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep) %
                % %fnameT=strrep(strcat(dname,filesep,'timeseries_demErr.h5'),'/',filesep) %
                % fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '33' % DCAMP
                %fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy32_33/velocity.h5'),'/',filesep)
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy33'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep) %
                %fnameT=strrep(strcat(dname,filesep,'timeseries_demErr.h5'),'/',filesep) %
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '33era'
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy33era'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries_ERA5.h5'),'/',filesep) % after ERA correction
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            % case '36' % DCAMP
            %     dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy36'),'/',filesep)
            case '36' % EMESA
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy36'),'/',filesep)
            case '36hcorr' % EMESA
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy36hcorr'),'/',filesep)
            case '36era' % EMESA
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy36era'),'/',filesep)
            case '47' % DCAMP
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy47'),'/',filesep)
            case '47hcorr' % DCAMP
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy47hcorr'),'/',filesep)
                fnameV=strrep(strcat(dname,filesep,'velocity.h5')       ,'/',filesep)
                fnameT=strrep(strcat(dname,filesep,'timeseries_tropHgt.h5'),'/',filesep) % after height_correlation correction
                fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5'),'/',filesep) % geometry
            case '38' % TUNGS
                %fnameV=strrep(strcat(DataDirLocal,filesep','SDK/DESCENDING/mintpy38/velocity.h5'),'/',filesep)
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy38'),'/',filesep)
            case '39' % DIXIE
                %fnameV=strrep(strcat(DataDirLocal,filesep','SDK/ASCENDING/mintpy39/velocity.h5'),'/',filesep)
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy39'),'/',filesep)
            case '42' % BLUEM Nevada
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy42'),'/',filesep)
            case '53' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy53'),'/',filesep)
            case '54' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy54'),'/',filesep)
            case '54hcorr' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy54hcorr'),'/',filesep)
            case '54era' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy54era'),'/',filesep)
            case '55' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy55'),'/',filesep)
            case '55hcorr' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy55hcorr'),'/',filesep)
            case '55era' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy55era'),'/',filesep)
            case '56' % SANEM short test case on KF imac
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy56'),'/',filesep)
            case '56era' % SANEM short test case on KF imac
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy56era'),'/',filesep)
            case 'AriaT42' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'ARIA/T42/MINTPY_hcorr'),'/',filesep)
            case 'AriaT42hcorr' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'ARIA/T42/MINTPY_hcorr'),'/',filesep)
            case 'AriaT42era' % SANEM
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'ARIA/T42/MINTPY_pyaps'),'/',filesep)
            case '60' % BRADY short test case on KF imac
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy60'),'/',filesep)
            case '61' % BRADY long solution KF imac
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy61'),'/',filesep)
            case '63' % BRADY long solution on emidio
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy63'),'/',filesep)
            case '64' % LGTDK
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/DESCENDING/mintpy64'),'/',filesep)
            case '65' % EMESA
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy65'),'/',filesep)
            case '66' % LGTDK
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy66'),'/',filesep)
            case '66era' % LGTDK
                dname =strrep(strcat(DataDirLocal,filesep,site,filesep,'SDK/ASCENDING/mintpy66era'),'/',filesep)
            otherwise
                error('unknown sSoln = %s',sSoln);
        end

        %% build file names
        if contains(sSoln,'hcorr') == 1
            % after height_correlation correction
            fnameV=strrep(strcat(dname,filesep,'velocity.h5'),'/',filesep)
            fnameT=strrep(strcat(dname,filesep,'timeseries_tropHgt.h5'),'/',filesep);
        elseif contains(sSoln,'era') == 1
            % after tropospheric ERA correction
            fnameV=strrep(strcat(dname,filesep,'velocity.h5'),'/',filesep)
            fnameT=strrep(strcat(dname,filesep,'timeseries_ERA5.h5'),'/',filesep);
        else
            fnameV=strrep(strcat(dname,filesep,'avgPhaseVelocity.h5'),'/',filesep)      ; % uncorrected
            fnameT=strrep(strcat(dname,filesep,'timeseries.h5'),'/',filesep); % "raw"
        end
        % some files are always the same
        fnameG=strrep(strcat(dname,filesep,'inputs/geometryGeo.h5')             ,'/',filesep); %
        fnameP=strrep(strcat(dname,filesep,'pic')                               ,'/',filesep); %
        fnameR=strrep(strcat(dname,filesep,'rms_timeseriesResidual_ramp.txt')   ,'/',filesep);


        %% copy remote files - assumes ssh keys in place
        % velocity.h5
        mkdir(dname);
        rnameV=strrep(fnameV,DataDirLocal,DataDirRemote)
        if doRsync
            sysCmd=sprintf('rsync -rav %s %s',rnameV,fnameV)
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                error('rsync of velocity.h5 failed')
            end
        end

        % geometryGeo.h5
        rnameG=strrep(fnameG,DataDirLocal,DataDirRemote)
        mkdir(strcat(dname,filesep,'inputs'));
        sysCmd=sprintf('rsync -rav %s %s',rnameG,fnameG)
        if doRsync
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                error('rsync of geometryGeo.h5 failed')
            end
        end

        % timeseries.h5
        rnameT=strrep(fnameT,DataDirLocal,DataDirRemote)
        sysCmd=sprintf('rsync -rav %s %s',rnameT,dname)
        if doRsync
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                error('rsync of timeseries.h5 failed')
            end
        end

        % pic folder
        if doRsync
            rnameP = strrep(fnameP,DataDirLocal,DataDirRemote);
            fnameP = strrep(fnameP,'pic/pic','pic'); % remove one level
            sysCmd=sprintf('rsync -rav %s %s',rnameP,fnameP);
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                error('rsync of pic folder failed')
            end
        end

        % txt files Log files
        fnameL=strcat(dname,filesep);
        rnameL=strrep(fnameL,DataDirLocal,DataDirRemote);
        rnameL=strcat(rnameL,'*.out')

        fnameL
        rnameL
        %rnameL=strrep(rnameL,DataDirLocal,DataDirRemote)
        if doRsync
            sysCmd=sprintf('rsync -rav %s %s',rnameL,fnameL)
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                warning('rsync of text log files failed')
            end
        end

        % RMS file
        rnameR=strrep(fnameR,DataDirLocal,DataDirRemote)
        if doRsync
            sysCmd=sprintf('rsync -rav %s %s',rnameR,fnameR)
            [sysStatus,sysOut] = system(sysCmd)
            if sysStatus ~= 0
                warning('rsync of rms files failed')
            end
        end


        %% Read Information, Attributes and Data from HDF5 file for Velocity
        % https://mintpy.readthedocs.io/en/latest/api/data_structure/
        % Read velocity file
        % https://mintpy.readthedocs.io/en/latest/api/data_structure/
        % Using the underscore _ as the delimiter in the file name, the first part describes the file type, while the rest parts describe the additional operations. For example:
        %
        % timeseries.h5 is the raw time series
        % timeseries_ERA5.h5 is the time series after the ERA5 correction;
        % velocity.h5 is the velocity from the final displacement time series
        % velocityERA5.h5 is the velocity from ERA5 tropospheric delay (from inputs/ERA5.h5 file), not the displacement velocity after ERA5 correction.
        % timeseriesResidual.h5 is the residual phase time series
        % timeseriesResidual_ramp.h5 is the residual phase time series after deramping
        % positive value represents motion toward the satellite (uplift for pure vertical motion).

        % Using the underscore _ as the delimiter in the file name, the first part describes the file type, while the rest parts describe the additional operations. For example:
        % timeseries.h5 is the raw time series
        % timeseries_ERA5.h5 is the time series after the ERA5 correction;
        % velocity.h5 is the velocity from the final displacement time series
        % velocityERA5.h5 is the velocity from ERA5 tropospheric delay (from inputs/ERA5.h5 file), not the displacement velocity after ERA5 correction.
        % timeseriesResidual.h5 is the residual phase time series
        % timeseriesResidual_ramp.h5 is the residual phase time series after deramping

        
        
        [IV,AV,DV] = read_mintpy_h5(fnameV);


        % setting missing values to NaN
        kokV = find(isfinite(DV.velocity));
        if isnumeric(AV.NO_DATA_VALUE)
            knanV=find(abs(DV.velocity-AV.NO_DATA_VALUE) <= eps);
            DV.velocity(knanV) = nan;
        else
            knanV=[];
        end
        fprintf('number of good pixels in velocity field %20d\n',numel(kokV));
        fprintf('number of NaN  pixels in velocity field  %20d\n',numel(knanV));


        % decide about coordinates
        if strcmpi(AV.X_UNIT,'meters') == true
            isGeographic=false;
        elseif strcmpi(AV.X_UNIT,'degrees') == true
            isGeographic=true;
        else
            error('Unknown units %s',AV.X_UNIT);
        end

        % define significance ratio
        if isfield(DV,'velocityStd')
            DV.sigratio = abs(DV.velocity) ./ DV.velocityStd;
        else
            warning('field velocityStd is not defined for file %s',fnameV);
            DV.velocityStd = nan(size(DV.velocity));
            DV.sigratio = nan(size(DV.velocity));
        end

        if isGeographic
            % project (lat,lon) to (E,N), overwriting X,Y
            % if strcmp(site,'SANEM')
            %     [DV.vecX,DV.vecY,~,~] = lalo2wholescaleENXY(DV.vecY,DV.vecX);
            %     % TODO same for others
            % else
            [XGRD,YGRD,~,] = deg2utm(colvec(DV.YGRD),colvec(DV.XGRD));
            DV.XGRD=reshape(XGRD,size(DV.XGRD));
            DV.YGRD=reshape(YGRD,size(DV.YGRD));
            Ue=linspace(min(DV.XGRD,[],'all','omitnan'), max(DV.XGRD,[],'all','omitnan'), AV.WIDTH);
            Un=linspace(min(DV.YGRD,[],'all','omitnan'), max(DV.YGRD,[],'all','omitnan'), AV.LENGTH);
            % DV.vecX=unique(DV.XGRD);
            % DV.vecY=unique(DV.YGRD);
            %end
            % format long
            % lonMin=min(VELO.longitude,[],'all','omitnan')
            % lonMax=max(VELO.longitude,[],'all','omitnan')
            % latMin=min(VELO.latitude,[],'all','omitnan')
            % latMax=max(VELO.latitude,[],'all','omitnan')
        else
            % UTM Easting and corners in meters for four corners
            Ue=[AV.X_FIRST,  AV.X_FIRST+(AV.WIDTH-1)*AV.X_STEP, AV.X_FIRST+(AV.WIDTH-1) *AV.X_STEP, AV.X_FIRST ]'
            Un=[AV.Y_FIRST,  AV.Y_FIRST,                        AV.Y_FIRST+(AV.LENGTH-1)*AV.Y_STEP, AV.Y_FIRST+(AV.LENGTH-1)*AV.Y_STEP]'

            if abs(min(DV.vecX) - min(Ue)) > abs(AV.X_STEP)/2.
                error('minimum X coordinates do not agree')
            end
            if abs(max(DV.vecX) - max(Ue)) > abs(AV.X_STEP)/2.
                error('maximum X coordinates do not agree')
            end
            if abs(min(DV.vecY) - min(Un)) > abs(AV.Y_STEP)/2.
                error('minimum Y coordinates do not agree')
            end
            if abs(max(DV.vecY) - max(Un)) > abs(AV.Y_STEP)/2.
                error('maximum Y coordinates do not agree')
            end

        end


        %% back project to verify

        %% Read GEOMETRY file
        [IG,AG,DG] = read_mintpy_h5(fnameG);

        %% Read time series file
        % Read Inforrmation, Attributes and Data from HDF5 file for time series
        if doTimeSeries
            [IT,AT,DT] = read_mintpy_h5(fnameT);
            % number of epochs
            nt=numel(DT.date)
            % setting missing values to NaN
            kokT = find(isfinite(DT.timeseries));
            if isnumeric(AT.NO_DATA_VALUE)
                knanT=find(abs(DT.timeseries-AT.NO_DATA_VALUE) <= eps);
                DT.timeseries(knanT) = nan;
            else
                knanT=[];
            end
            fprintf('number of good pixels in time series %20d\n',numel(kokT));
            fprintf('number of NaN  pixels in time series %20d\n',numel(knanT));
        else
            nt=nan;
        end

        %% define AOI in UTM coordinates
        if exist('Tcorners.E','var') == 1
            UTMranges=[min(Tcorners.E), max(Tcorners.E), min(Tcorners.N), max(Tcorners.N)];
        else
            UTMranges=[min(Ue), max(Ue), min(Un), max(Un)];
        end


        %% choose end point for time series
        [~,~,iref,jref,kref,~,~] = extract_and_reference_velocity(AV ...
            ,DV.velocity,DV.velocityStd ...
            ,DV.XGRD,DV.YGRD,DG.incidenceAngle,UTMranges,iReferenceStyle,Eref,Nref,refRadius);

        if ~isempty(Twells)
            iWellWatch=find(strcmp(Twells.Well_Name,wellToWatch));
            if numel(iWellWatch) <= 0
                error('cannot find well %s',wellToWatch)
            end
            rdist=hypot(DV.XGRD-table2array(Twells(iWellWatch,'Easting_m')) ...
                ,DV.YGRD-table2array(Twells(iWellWatch,'Northing_m')));
            [~,kvmin]=min(rdist,[],'all','omitnan');

        else % make time series for min
            %[vmax,kvmax]=max(DV.velocity,[],'all')
            [vmin,kvmin]=min(DV.velocity,[],'all')
            %[ivmax,jvmax]=ind2sub(size(DV.XGRD),kvmax);
            %[ivmin,jvmin]=ind2sub(size(DV.XGRD),kvmin);
        end
        [iTrk,jTrk]=ind2sub(size(DV.XGRD),kvmin);
        % 2025/04/10 verified the following
        % iref, jref, kref are logicals
        % iiref, jjref are integer indices
        % find indices from logicals
        %%% [iiref,jjref]=find(kref);

 
        % width of pixel in DPI
        %https://undocumentedmatlab.com/articles/graphic-sizing-in-matlab-r2015b
        if exist('markerSize','var') ~= 1
           markerSize=(UTMranges(2)-UTMranges(1))/get(groot,'ScreenPixelsPerInch')
        end
        mmargin=markerSize/2;% margin in pixels
        UTMranges = UTMranges + mmargin*[-1,+1,-1,+1]; % pad a bit
        %contourInterval=0.010;

        if doMaps
            for it=5
                for ifield=4
                    nf=nf+1;nfMaps=nfMaps+1;figure('units','normalized','position',[0.05,0.05,0.9,0.9]);%,'Color','w');
                    set(gca,'Color',[0.9,0.9,0.9]); % set background to gray
                    %set(gca,'Color','k'); % set axes color
                    hold on;
                    % get limits
                    % get limits

                    switch ifield
                        case 4 % 'velocity'
                            tstring0='uzrate';
                            tString1='Mean rate of vertical displacement [mm/year]';
                            uString='mm/year';
                            if isfield(AV,'START_DATE')
                                tStamp=sprintf('%8d to %8d',AV.START_DATE,AV.END_DATE);
                            elseif isfield(AV,'DATE12')
                                tStamp=AV.DATE12;
                            else
                                tStamp='';
                            end
                            %[V2,tstring,iref,jref,kref,kok] = extract_and_reference_velocity(DV,AV,UTMranges,iReferencePoint,Eref,Nref);
                            [V2,tString2,iref,jref,kref,kok,V0] = extract_and_reference_velocity(AV ...
                                ,DV.velocity,DV.velocityStd ...
                                ,DV.XGRD,DV.YGRD,DG.incidenceAngle,UTMranges,iReferenceStyle,Eref,Nref,refRadius);
                            nok=numel((kok))
                            if nok < 100
                                error('Too few valid points!')
                            end

                            cmap=cmappolar;
                            % choose values for color mapping and contours
                            % following line can return NaNs
                            qlim1=max([abs(quantile(colvec(V2(kok)),0.01)),quantile(colvec(V2(kok)),0.99)],[],'omitnan');
                            if isfinite(qlim1) == false
                                qlim1=max([abs(min(V2,[],'all','omitnan')), abs(max(V2,[],'all','omitnan'))]) % overwrite Nan with meters
                            end

                            climits=[-1*qlim1,+1.*qlim1];
                            % case 5 % 'velocityStd'
                            %     tstring0='srate';
                            %     tString1 = sprintf('Standard Deviation of rate of vertical displacement [mm/year]');
                            %     uString='mm/year';
                            %     tStamp=sprintf('%8d to %8d',AV.START_DATE,AV.END_DATE);
                            S2=double(DV.velocityStd ./ cosd(DG.incidenceAngle));
                            % cmap=parula;
                            % climits=[0,quantile(V2(kok),0.99)];
                        % case 40 % 'time series for one frame
                        %     tstring0='vdisp';
                        %     tString1='Vertical displacement since last date [mm]';
                        %     uString='mm';
                        %     [V3,tString2,iref,jref,kref,kok,V0] = extract_and_reference_velocity(AV ...
                        %         ,squeeze(DT.timeseries(:,:,it)), nan ...
                        %         ,DV.XGRD,DV.YGRD,DG.incidenceAngle,UTMranges,iReferenceStyle,Eref,Nref,refRadius);
                        %     if it == 1
                        %         V2 = V3;
                        %         tStamp=sprintf('%s',DT.datetime(it));
                        %     else
                        %         V2 = V3-V2;
                        %         tStamp=sprintf('%s to %s',DT.datetime(it-1),DT.datetime(it));
                        %     end
                        % 
                        %     cmap=cmappolar;
                        %     % choose values for color mapping and contours
                        %     %qlim1=max([abs(quantile(V2(kok),0.01)),quantile(V2(kok),0.99)]);
                        %     qlim1=0.1; % meter
                        %     climits=[-1*qlim1,+1.*qlim1];

                        otherwise
                            error('unknown ifield = %d',ifield);
                    end

                    % start plot
                    if isfinite(qlim1)
                        if size(V2) ~= size(DV.XGRD)
                            warning('wrong sizes')
                        end

                        % use grid
                        Hs=scatter(colvec(DV.XGRD(kok))/kilo,colvec(DV.YGRD(kok))/kilo,markerSize,colvec(V2(kok))/milli ...
                            ,'filled','s','MarkerEdgeColor','none','clipping','on');
                        colormap(cmap);
                        clim(climits/milli)
                        hold on;

                        % plot reference pixels
                        if numel(iref) < 1000
                            Hr=scatter(colvec(DV.XGRD(kref))/kilo ...
                                ,      colvec(DV.YGRD(kref))/kilo, 3 ...
                                ,      colvec(zeros(size(DV.XGRD(kref)))) ...
                                ,'.','MarkerEdgeColor','k');
                            Lr='reference pixel';
                        else
                            Hr=[];
                            Lr='';
                        end

                        % plot bedrock outcrops
                        if exist('Tbedrock','var') == 1
                            plot(Tbedrock.E/kilo,Tbedrock.N/kilo,'Marker','h','Color','y','MarkerSize',15,'LineStyle','none','LineWidth',2,'MarkerFaceColor','none');
                        end

                        % plot wells
                        if ~isempty(Twells) 
                            [Hw,Lw] = plot_and_label_wells(Twells,UTMranges);
                            %Wtypes={'Production','Injection','Observation'};
                            %     Wsymbs={'r^','bv','go'};
                            %     for ii=1:numel(Wtypes)
                            %         iType=(contains(Twells.Type,Wtypes{ii}));
                            %         plot(Twells.Easting_m(iType)/kilo,Twells.Northing_m(iType)/kilo,Wsymbs{ii}...
                            %             ,'MarkerSize',15,'LineWidth',2,'MarkerFaceColor','none');
                            %     end
                        end

                        % plot pixel with min velocity
                        Hm=plot(colvec(DV.XGRD(kvmin))/kilo,colvec(DV.YGRD(kvmin))/kilo ...
                            ,'o','MarkerEdgeColor','y','MarkerFaceColor','none','MarkerSize',15,'LineWidth',3);
                        Lm='min velocity';

                        % outline study area
                        if ~isempty(Tcorners) 
                            Hs=plot(polyshape([Tcorners.E(1:4),Tcorners.N(1:4)]/kilo),'FaceColor','none','Edgecolor','g','LineWidth',2);
                        end
                        Ls = 'study area';

                        % legend
                        legend([Hw,Hm,Hs,Hr],{Lw,Lm,Ls,Lr});

                        % beautify
                        set(gca,'Clipping','on');
                        axis xy;
                        axis(UTMranges/kilo);
                        axis tight
                        axis equal;
                        box on;
                    else
                        qlim1
                        warning('qlim1 not defined')
                        scatter(colvec(DV.XGRD)/kilo,colvec(DV.YGRD)/kilo,markerSize,colvec(DV.velocity)/milli ...
                            ,'filled','s','MarkerEdgeColor','none','clipping','on');

                    end
                    xlabel('UTM Easting [km]');
                    ylabel('UTM Northing [km]');

                    Hcb=colorbar;
                    xlabel(Hcb,uString);%, 'Position', [0.5, 1.02]);

                    title(sprintf('Figure %d.mintpy%s Site %s %s',nfMaps,sSoln,site,tStamp),'Interpreter','none');
                    subtitle(sprintf('%s %s %s',fnameV,tString1,tString2),'Interpreter','none');

                    if saveFigs
                        fname_png1=strrep(fnameV,'.h5',sprintf('%s_%s_map.png',sSoln,strrep(tStamp,' ','_')))
                        exportgraphics(gcf,fname_png1,'resolution',600);
                        exportgraphics(gcf,strrep(fname_png1,'.png','.pdf'));
                    end

                    % make a table and write to CSV file
                    if saveCSVs
                        % make table
                        Tgrid=table(colvec(DV.XGRD(kok)),colvec(DV.YGRD(kok)),colvec(V2(kok)),colvec(S2(kok)));
                        Tgrid.Properties.VariableNames={'Eutm_m','Nutm_m','Disp_vert_m','Disp_vert_unc_m'};
                        Tgrid.Properties.VariableUnits={'m','m','m','m'};
                        % write to CSV file
                        fname_csv1=strrep(fname_png1,'.png','.csv');
                        writetable(Tgrid,fname_csv1,'WriteVariableNames',true);

                        %     % validate CSV file
                        %     Tcsv1=readtable(fname_csv1);
                        %     figure;
                        %     scatter(Tcsv1.Eutm_m/kilo,Tcsv1.Nutm_m/kilo,markerSize,Tcsv1.Disp_vert_m/milli);
                        %     hold on;
                        %     %plot(Ue/kilo,Un/kilo,'g*-','LineWidth',1)
                        %     plot(Tcorners.E/kilo,Tcorners.N/kilo,'*r-','LineWidth',1);
                        %     axis xy;
                        %     axis equal;
                        %     box on;
                        %     %axis(UTMranges/kilo);
                        %     %axis tight;
                        %     xlabel('UTM Easting [km]');
                        %     ylabel('UTM Northing [km]');
                        %     title(fname_csv1,'Interpreter','none');
                    end
                end
            end
        end

        %% plot time series
        if doTimeSeries == true
            %collect displacement of one pixel
            ncols=2
            Tdisp=array2table(nan([nt,ncols]));
            Tdisp.Properties.VariableNames={'UTC','Uz_m'};
            Tdisp.UTC=DT.datetime;

            % find pixel to track 
            if ~isempty(Twells) % track pixel nearest well 
                rdist=hypot(DV.XGRD-table2array(Twells(iWellWatch,'Easting_m')) ...
                    ,DV.YGRD-table2array(Twells(iWellWatch,'Northing_m')));
                [~,kkWellWatch]=min(rdist,[],'all','omitnan');
                [iTrk,jTrk]=ind2sub(size(DV.XGRD),kkWellWatch);
            else % track pixel with minimum velocity
                [vmin,kvmin]=min(DV.velocity,[],'all','omitnan');
                [iTrk,jTrk]=ind2sub(size(DV.XGRD),kvmin);
            end


            % collect some adjacent pixels
            pixelMargin=50;
            iTrk = [iTrk-pixelMargin:iTrk+pixelMargin];
            jTrk = [jTrk-pixelMargin:jTrk+pixelMargin];

            % collect velocity for tracked pixel at each point in time
            for it=1:nt
                %uz1=DT.timeseries(iTrk,jTrk,it) ./ cosd(DG.incidenceAngle(iTrk,jTrk));
                uz1=median(DT.timeseries(iTrk,jTrk,it) ./ cosd(DG.incidenceAngle(iTrk,jTrk)),'all','omitnan');

                % subtract mean of reference pixels
                uz0a = squeeze(DT.timeseries(:,:,it));
                uz0b = DG.incidenceAngle;
                uz0= mean((uz0a ./ uz0b),'all','omitnan');
                %whos uz*

                Tdisp.Uz_m(it)=uz1-uz0;
            end
   
            % start the figure
            nf=nf+1;nfTser=nfTser+1;figure('units','normalized','position',[0.1 0.1 0.8, 0.4]);
            hold on;

            % read overall RMS for each epoch
            if exist(fnameR,'file') == 2
                Trms=readtable(fnameR,'ReadVariableNames',false,'NumHeaderLines',4);
                Trms.Properties.VariableNames={'YYYYMMDD','RMS_m'};
                [nt2,~]=size(Trms)
                for it2=1:nt2
                    Trms.Time(it2)=yyyymmdd2datetime(Trms.YYYYMMDD(it2));
                end
                if nt2 ~= nt
                    error('Numbers of epochs %d %d do not match!',nt,nt2);
                end

                tplot=Tdisp.UTC;
                yplot=Tdisp.Uz_m/milli;
                eplot=Trms.RMS_m/milli;
                [pest1, psig1, tfit1, ymod1, ymodl1, ymodu1, mse1] = fit_straight_line(tplot,yplot,eplot);
                [pest2, psig2, tfit2, ymod2, ymodl2, ymodu2, mse2] = fit_quadratic(tplot,yplot,eplot);

                errorbar(Trms.Time,yplot,Trms.RMS_m/milli,'r+-');

                plot(tfit1,ymodu1,'k--');
                plot(tfit1,ymod1,'k-');
                plot(tfit1,ymodl1,'k--');
                plot(tfit1,ymod2,'b:');

                % legend
                if all(isfinite(pest1)) && all(isfinite(pest2))
                    legend('observed','+ 1 std',sprintf('%.2f +/- %.2f mm/year',pest1(2),psig1(2)),'- 1 std'...
                        ,sprintf('%.2f +/- %.2f mm/year/year',pest2(3),psig2(3)));
                else
                    legend('observed','+ 1 std');
                end
            else
                plot(Tdisp.UTC,Tdisp.Uz_m/milli,'r+-');
            end
            xlabel('date [UTC]');
            ylabel('vertical displacement [mm]');
            subtitle(sprintf('%s %s',fnameT,tStamp),'Interpreter','none');
            title(sprintf('Figure %d.mintpy%s Vertical displacement of pixel near %s Well %s w.r.t. %.1f [mm]'...
                ,nfTser,sSoln,site,wellToWatch,uz0/milli),'Interpreter','none');
            box on

            if saveFigs
                fname_png2=strrep(fnameT,'.h5',sprintf('%s_%s_%s_uz.png',sSoln,strrep(tStamp,' ','_'),wellToWatch));
                exportgraphics(gcf,fname_png2,'resolution',600)
                exportgraphics(gcf,strrep(fname_png2,'.png','.pdf'),'resolution',600);
            end

            % dump to CSV file
            if saveCSVs
                Tdisp=addvars(Tdisp,Trms.Time,Trms.RMS_m,'NewVariableNames',{'UTC_2','RMS_m'});
                fname_csv2=strrep(fname_png2,'.png','.csv');
                writetable(Tdisp,fname_csv2,'WriteVariableNames',true);

                % % validate CSV file
                % Tcsv2=readtable(fname_csv2);
                % [nt3,~]=size(Tcsv2);
                % for it3=1:nt3
                %     Tcsv2.datetime(it3)=yyyymmdd2datetime(Tcsv2.UTC(it3));
                % end
                % figure
                % plot(Tcsv2.datetime,Tcsv2.Uz_m/milli);
                % xlabel('date [UTC]');
                % ylabel('vertical displacement [mm]');
            end
        end
    end
end



