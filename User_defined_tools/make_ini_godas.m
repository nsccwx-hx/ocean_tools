clear all; close all; clc;
%%%%%%%%%%%%%%%%%%%%% USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%
%
%  Title 
%
title='GODAS';
%
% Common parameters
%
crocotools_param
%
hycom_data  = [CROCO_files_dir,'godas_2018-2020.nc'];
disp([' GODAS_data : ', hycom_data])
%preprocessing input data
% deeper_input(hycom_data);
%
nc=netcdf(grdname);
lon=nc{'lon_rho'}(:);
lat=nc{'lat_rho'}(:);
angle=nc{'angle'}(:);
h=nc{'h'}(:);
maxh=ceil(max(max(h)));
close(nc)
lonmin=min(min(lon));
lonmax=max(max(lon));
latmin=min(min(lat));
latmax=max(max(lat));
%
nc=netcdf(hycom_data);
lonT=nc{'lonT'}(:);
latT=nc{'latT'}(:);
lonU=nc{'lonUV'}(:);
latU=nc{'latUV'}(:);
lonV=nc{'lonUV'}(:);
latV=nc{'latUV'}(:);
Z=-nc{'depth'}(:);
NZ=length(Z);
levnum=find(-Z>maxh,1,'first')+1;
NZ=min(levnum,NZ-rmdepth);
Z=Z(1:NZ);
hycomtimeunits=nc{'time'}.units(:);
torig=nc{'time'}.time_origin(:);
timeunits=hycomtimeunits;
time=floor(nc{'time'}(:));
close(nc)
%
initime=time(1);
initimestr=datestr(datenum(torig)+initime/3600.0/24.0,'yyyymmdd_HH');
%
clmdt=1;
brydt=1;
bryt0=1;
clmt0=1;
makeini =1;
makebry =0;
makeclim=0;
%
%%%%%%%%%%%%%%%%%%% END USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%

%
% Initial file
%
if makeini==1
%
% Title
%
    disp(' ')
    disp([' Making initial file: ',ininame])
    disp(' ')
    disp([' Title: ',title])
    
    create_forecast_inifile(ininame,grdname,title,theta_s,theta_b,hc,N,...
               initime,timeunits,vtransform);
    disp(['Create an initial file for ',initimestr]);
    nc_ini=netcdf(ininame,'write');
%
% Horizontal and vertical interp/extrapolations 
% 
    interp_godas_frcst(hycom_data,Roa,interp_method,lonU,latU,lonV,latV,lonT,latT,Z,1,...
              nc_ini,[],lon,lat,angle,h,1,vtransform)
    close(nc_ini)
    
%     eval(['!cp ',ininame,' ',ini_prefix,'hct',nc_suffix])
end
%
% Clim and Bry files
%
if makeclim==1 || makebry==1
  if makebry==1
    create_forecast_bryfile(bryname,grdname,title,obc,...
                   theta_s,theta_b,hc,N,...
                   time(bryt0:brydt:end),timeunits,vtransform);
    nc_bry=netcdf(bryname,'write');
  else
    nc_bry=[];
  end
  if makeclim==1
    create_forecast_climfile(clmname,grdname,title,...
                    theta_s,theta_b,hc,N,...
                    time(1:clmdt:end),timeunits,vtransform);
    nc_clm=netcdf(clmname,'write');
  else
    nc_clm=[];
  end

if makeclim==1
for tndx=clmt0:clmdt:length(time)
  cntt = (tndx-clmt0)/clmdt+1;
  disp([' Time step : ',num2str(tndx),' of ',num2str(length(time)),' :'])
  interp_godas_frcst(hycom_data,Roa,interp_method,...
                    lonU,latU,lonV,latV,lonT,latT,Z,cntt,...
		    nc_clm,[],lon,lat,angle,h,cntt,vtransform)
end
end

if makebry==1
for tndx=bryt0:brydt:length(time)
  cntt = (tndx-bryt0)/brydt+1;
  disp([' Time step : ',num2str(tndx),' of ',num2str(length(time)),' :'])
  interp_godas_frcst(hycom_data,Roa,interp_method,...
                    lonU,latU,lonV,latV,lonT,latT,Z,cntt,...
		    [],nc_bry,lon,lat,angle,h,cntt,vtransform)
end
end

%
% Close the CROCO files
%
  if ~isempty(nc_clm)
    close(nc_clm);
  end
  if ~isempty(nc_bry)
    close(nc_bry);
  end
%
end

%
% End
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
