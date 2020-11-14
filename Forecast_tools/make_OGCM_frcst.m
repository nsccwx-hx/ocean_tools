%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Common parameters
%
tic
crocotools_param
%
% Specific to forecast
%
makeplot = 0;
fprintf('theta_s is %5.1f; theta_b is %5.1f; tcline is %6.1f \n', theta_s, theta_b, hc);
fprintf('vtransform is %5.1f; vstetching is %5.1f \n', vtransform, Vstretching);
%
% Get the date
%
rundate_str='2020-09-02';
rundate=datenum(rundate_str)-datenum(Yorig,1,1)-1;
FRCST_prefix='HYCOM_';      % generic OGCM file name
FRCST_dir =['E:/croco_tools/DATA/HYCOM/',datestr(datenum(rundate_str)-1,'yyyymmddhh/')];
OGCM_name=dir([FRCST_dir,FRCST_prefix,'*.nc']);
OGCM_prefix=FRCST_dir;
% OGCM_name=dir([FRCST_dir,datestr(datenum(rundate_str)-1,'yyyymmddhh/'),FRCST_prefix,'*.nc']);
% OGCM_prefix=[FRCST_dir,datestr(datenum(rundate_str)-1,'yyyymmddhh/')];
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of user input  parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if level==0
  nc_suffix='.nc';
else
  nc_suffix=['.nc.',num2str(level)];
  grdname=[grdname,'.',num2str(level)];
end
%
% Get the model grid
%
nc=netcdf(grdname);
lon=nc{'lon_rho'}(:);
lat=nc{'lat_rho'}(:);
angle=nc{'angle'}(:);
h=nc{'h'}(:);
maxh=ceil(max(max(h)));
close(nc)
%
% Extract data over the internet
%
%
% Get the model limits
%
lonmin=min(min(lon));
lonmax=max(max(lon));
latmin=min(min(lat));
latmax=max(max(lat));
%
% Get the OGCM grid(1:el,2:s,3:ua,4:va,5:t,6:u,7:v)
% 
nc=netcdf([FRCST_dir,OGCM_name(5).name]);
lonT=nc{'lon'}(:);
latT=nc{'lat'}(:);
hycomtimeunits=nc{'time'}.units(:);
timeunits=strrep(strrep(hycomtimeunits,'hours','seconds'),'.000 UTC','');
OGCM_time=floor(nc{'time'}(:))*3600.d0;
close(nc)

nc=netcdf([FRCST_dir,OGCM_name(6).name]);
lonU=nc{'lon'}(:);
latU=nc{'lat'}(:);
close(nc)

nc=netcdf([FRCST_dir,OGCM_name(7).name]);
lonV=nc{'lon'}(:);
latV=nc{'lat'}(:);
Z=-nc{'depth'}(:);
NZ=length(Z);
levnum=find(-Z>maxh,1,'first')+2;
NZ=min(levnum,NZ-rmdepth);
Z=Z(1:NZ);
if strcmp(OGCM,'ECCO')
  time=[90 270];
  time_cycle=360;
  trange=[1 1];
  %hdays=1;
elseif strcmp(OGCM,'HYCOM')
  ntimes=length(OGCM_time);
  dt=max(gradient(OGCM_time));
  time_cycle=0;
  croco_time=OGCM_time;
  time=croco_time;
  initime=croco_time(1);
end   % MERCATOR
close(nc)

clmdt=4;
brydt=2;
bryt0=1;
clmt0=1;
makeini =1;
makebry =0;
makeclim=0;
%
% Initial file 
%
if makeini==1
  ininame=[ini_prefix,datestr(datenum(rundate_str)-1,'yyyymmdd'),nc_suffix];
  disp(['Create an initial file for ',datestr(datenum(rundate_str)-1,'yyyy-mm-dd')]);
  create_forecast_inifile(ininame,grdname,CROCO_title,...
                 theta_s,theta_b,hc,N,...
                 initime,timeunits,vtransform);
  nc_ini=netcdf(ininame,'write');
 
  interp_OGCM_frcst(OGCM_prefix,OGCM_name,Roa,interp_method,...
              lonU,latU,lonV,latV,lonT,latT,Z,1,...
              nc_ini,[],lon,lat,angle,h,1,vtransform)
  close(nc_ini)
  eval(['!cp ',ininame,' ',ini_prefix,'hct',nc_suffix])
end
%
%

% Clim and Bry files
%
if makeclim==1 || makebry==1
  if makebry==1
    bryname=[bry_prefix,datestr(datenum(rundate_str)-1,'yyyymmdd'),nc_suffix];
    create_forecast_bryfile(bryname,grdname,CROCO_title,obc,...
                   theta_s,theta_b,hc,N,...
                   time(bryt0:brydt:end),timeunits,vtransform);
    nc_bry=netcdf(bryname,'write');
  else
    nc_bry=[];
  end
  if makeclim==1
    clmname=[clm_prefix,datestr(datenum(rundate_str)-1,'yyyymmdd'),nc_suffix];
    create_forecast_climfile(clmname,grdname,CROCO_title,...
                    theta_s,theta_b,hc,N,...
                    time(1:clmdt:end),time_cycle,timeunits,vtransform);
    nc_clm=netcdf(clmname,'write');
  else
    nc_clm=[];
  end

if makeclim==1
for tndx=clmt0:clmdt:length(time)
  cntt = (tndx-clmt0)/clmdt+1;
  disp([' Time step : ',num2str(tndx),' of ',num2str(length(time)),' :'])
  interp_OGCM_frcst(OGCM_prefix,OGCM_name,Roa,interp_method,...
                    lonU,latU,lonV,latV,lonT,latT,Z,cntt,...
		    nc_clm,[],lon,lat,angle,h,cntt,vtransform)
end
end

if makebry==1
for tndx=bryt0:brydt:length(time)
  cntt = (tndx-bryt0)/brydt+1;
  disp([' Time step : ',num2str(tndx),' of ',num2str(length(time)),' :'])
  interp_OGCM_frcst(OGCM_prefix,OGCM_name,Roa,interp_method,...
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
%---------------------------------------------------------------
% Make a few plots
%---------------------------------------------------------------
if makeplot==1
  disp(' ')
  disp(' Make a few plots...')
  if makeini==1
    ininame=[ini_prefix,num2str(rundate),nc_suffix];
    figure
    test_clim(ininame,grdname,'temp',1,coastfileplot)
    figure
    test_clim(ininame,grdname,'salt',1,coastfileplot)
  end
  if makeclim==1
    clmname=[clm_prefix,num2str(rundate),nc_suffix];
    figure
    test_clim(clmname,grdname,'temp',1,coastfileplot)
    figure
    test_clim(clmname,grdname,'salt',1,coastfileplot)
  end
  if makebry==1
    bryname=[bry_prefix,num2str(rundate),nc_suffix];
    figure
    test_bry(bryname,grdname,'temp',1,obc)
    figure
    test_bry(bryname,grdname,'salt',1,obc)
    figure
    test_bry(bryname,grdname,'u',1,obc)
    figure
    test_bry(bryname,grdname,'v',1,obc)
  end
end

toc