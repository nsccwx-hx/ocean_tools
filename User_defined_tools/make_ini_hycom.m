clear all; close all; clc;
%%%%%%%%%%%%%%%%%%%%% USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%
%
%  Title 
%
title='HYCOM';
%
% Common parameters
%
crocotools_param
%
hycom_data  = [CROCO_files_dir,'hycom_20170819.nc'];
disp([' hycom_data : ', hycom_data])
insitu2pot = 1;    %Hycom data is temperature, converted it to potential temperature
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
lonT=nc{'lon'}(:);
latT=nc{'lat'}(:);
lonU=nc{'lon'}(:);
latU=nc{'lat'}(:);
lonV=nc{'lon'}(:);
latV=nc{'lat'}(:);
Z=-nc{'depth'}(:);
NZ=length(Z);
levnum=find(-Z>maxh,1,'first')+2;
NZ=min(levnum,NZ-rmdepth);
Z=Z(1:NZ);
hycomtimeunits=nc{'time'}.units(:);
torig=nc{'time'}.time_origin(:);
timeunits=strrep(strrep(hycomtimeunits,'hours','seconds'),'.000 UTC','');
time=floor(nc{'time'}(:))*3600.d0;
close(nc)
%
initime=time(1);
initimestr=datestr(datenum(torig)+initime/3600.0/24.0,'yyyymmdd_HH');
%
clmdt=2;
brydt=2;
bryt0=1;
clmt0=1;
makeini =0;
makebry =0;
makeclim=1;
%
%%%%%%%%%%%%%%%%%%% END USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%
%
% Title
%
disp(' ')
disp([' Making initial file: ',ininame])
disp(' ')
disp([' Title: ',title])
%
% Initial file
%
if makeini==1
    create_forecast_inifile(ininame,grdname,title,theta_s,theta_b,hc,N,...
               initime,timeunits,vtransform);
    disp(['Create an initial file for ',initimestr]);
    nc_ini=netcdf(ininame,'write');
%
% Horizontal and vertical interp/extrapolations 
% 
    interp_hycom_frcst(hycom_data,Roa,interp_method,lonU,latU,lonV,latV,lonT,latT,Z,1,...
              nc_ini,[],lon,lat,angle,h,1,vtransform)
    close(nc_ini)
    
    if (insitu2pot)
        disp(' ')
        disp(' Compute potential temperature from in-situ...')
        getpot(ininame,grdname)
    end
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
  interp_hycom_frcst(hycom_data,Roa,interp_method,...
                    lonU,latU,lonV,latV,lonT,latT,Z,cntt,...
		    nc_clm,[],lon,lat,angle,h,cntt,vtransform)
end
end

if makebry==1
for tndx=bryt0:brydt:length(time)
  cntt = (tndx-bryt0)/brydt+1;
  disp([' Time step : ',num2str(tndx),' of ',num2str(length(time)),' :'])
  interp_hycom_frcst(hycom_data,Roa,interp_method,...
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
