%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Build a CROCO forcing file
%
%  Extrapole and interpole surface data to get surface boundary
%  conditions for CROCO (forcing netcdf file)
%
%  Data input format (netcdf):
%     taux(T, Y, X)
%     T : time [Months]
%     Y : Latitude [degree north]
%     X : Longitude [degree east]
%
%  Data source : IRI/LDEO Climate Data Library 
%                (Atlas of Surface Marine Data 1994)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
%%%%%%%%%%%%%%%%%%%%% USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%
%
crocotools_param
%
%  Wind stress
%
taux_file=[coads_dir,'taux.cdf'];
taux_name='taux';
tauy_file=[coads_dir,'tauy.cdf'];
tauy_name='tauy';
%
%  Heat fluxes w3
%
shf_file=[coads_dir,'netheat.cdf'];
shf_name='netheat';
%
%  Fresh water fluxes (evaporation - precipitation)
%
swf_file=[coads_dir,'emp.cdf'];
swf_name='emp';
%
%  Sea surface temperature and heat flux sensitivity to the
%  sea surface temperature (dQdSST).
%  To compute dQdSST we need:
%    sat     : Surface atmospheric temperature
%    airdens : Surface atmospheric density
%    w3      : Wind speed at 10 meters
%    qsea    : Sea level specific humidity
%
sst_file=[coads_dir,'sst.cdf'];
sst_name='sst';
sat_file=[coads_dir,'sat.cdf'];
sat_name='sat';
airdens_file=[coads_dir,'airdens.cdf'];
airdens_name='airdens';
w3_file=[coads_dir,'w3.cdf'];
w3_name='w3';
qsea_file=[coads_dir,'qsea.cdf'];
qsea_name='qsea';
%
%  Sea surface salinity
%
sss_file=[coads_dir,'sss.cdf'];
sss_name='salinity';
%
%  Short wave radiation
%
srf_file=[coads_dir,'shortrad.cdf'];
srf_name='shortrad';
%
%
%%%%%%%%%%%%%%%%%%% END USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%
%
% Title
%
disp(' ')
disp(CROCO_title)
%
% Read in the grid
%
disp(' ')
disp(' Read in the grid...')
nc=netcdf(grdname,'r');
Lp=length(nc('xi_rho'));
Mp=length(nc('eta_rho'));
lon=nc{'lon_rho'}(:);
lat=nc{'lat_rho'}(:);
angle=nc{'angle'}(:);
close(nc);
cosa = cos(angle);
sina = sin(angle);
%
% Create the forcing file
%
disp(' ')
disp(' Create the forcing file...')
create_forcing(frcname,grdname,CROCO_title,...
               coads_time,Ymin)
%
% Loop on time
%
nc=netcdf(frcname,'write');
for tindex=1:length(coads_time)
  time=coads_time(tindex);
  u=ext_data(taux_file,taux_name,tindex,...
             lon,lat,time,Roa,2);
  v=ext_data(tauy_file,tauy_name,tindex,...
             lon,lat,time,Roa,2);
%
%  Rotation (if not rectangular lon/lat grid)
%
  nc{'sustr'}(tindex,:,:)=rho2u_2d(u.*cosa + v.*sina);
  nc{'svstr'}(tindex,:,:)=rho2v_2d(v.*cosa - u.*sina);
  nc{'sustr'}(12+tindex,:,:)=rho2u_2d(u.*cosa + v.*sina);
  nc{'svstr'}(12+tindex,:,:)=rho2v_2d(v.*cosa - u.*sina);  
  nc{'sustr'}(24+tindex,:,:)=rho2u_2d(u.*cosa + v.*sina);
  nc{'svstr'}(24+tindex,:,:)=rho2v_2d(v.*cosa - u.*sina);  
  nc{'sustr'}(36+tindex,:,:)=rho2u_2d(u.*cosa + v.*sina);
  nc{'svstr'}(36+tindex,:,:)=rho2v_2d(v.*cosa - u.*sina); 
end
for tindex=1:length(coads_time)
  time=coads_time(tindex);
  nc{'shflux'}(tindex,:,:)=ext_data(shf_file,shf_name,tindex,...
                                    lon,lat,time,Roa,1);
  nc{'shflux'}(12+tindex,:,:)=ext_data(shf_file,shf_name,tindex,...
                                    lon,lat,time,Roa,1);                               
  nc{'shflux'}(24+tindex,:,:)=ext_data(shf_file,shf_name,tindex,...
                                    lon,lat,time,Roa,1);   
  nc{'shflux'}(36+tindex,:,:)=ext_data(shf_file,shf_name,tindex,...
                                    lon,lat,time,Roa,1);   
end
for tindex=1:length(coads_time)
  time=coads_time(tindex);
%
% coeff = mm/(3hour) -> centimeter day-1 (!!!!!)
%
  nc{'swflux'}(tindex,:,:)=0.8*ext_data(swf_file,swf_name,tindex,...
                                        lon,lat,time,Roa,1);
  nc{'swflux'}(12+tindex,:,:)=0.8*ext_data(swf_file,swf_name,tindex,...
                                        lon,lat,time,Roa,1);
  nc{'swflux'}(24+tindex,:,:)=0.8*ext_data(swf_file,swf_name,tindex,...
                                        lon,lat,time,Roa,1);
  nc{'swflux'}(36+tindex,:,:)=0.8*ext_data(swf_file,swf_name,tindex,...
                                        lon,lat,time,Roa,1);                                    
                                    %  nc{'swflux'}(tindex,:,:)=0.8*(ext_data(evap_file,evap_name,...
%                                         tindex,lon,lat,time,Roa)-...
%			        ext_data(precip_file,precip_name,...
%                                         tindex,lon,lat,time,Roa));
end
for tindex=1:length(coads_time)
  time=coads_time(tindex);
  sst=ext_data(sst_file,sst_name,tindex,lon,lat,time,Roa,2);
  sat=ext_data(sat_file,sat_name,tindex,lon,lat,time,Roa,2);
  airdens=ext_data(airdens_file,airdens_name,tindex,lon,lat,time,Roa,2);
  w3=ext_data(w3_file,w3_name,tindex,lon,lat,time,Roa,2);
  qsea=0.001*ext_data(qsea_file,qsea_name,tindex,lon,lat,time,Roa,2);
  dqdsst=get_dqdsst(sst,sat,airdens,w3,qsea);
  nc{'SST'}(tindex,:,:)=sst;
  nc{'SST'}(12+tindex,:,:)=sst;
  nc{'SST'}(24+tindex,:,:)=sst;
  nc{'SST'}(36+tindex,:,:)=sst;
  nc{'dQdSST'}(tindex,:,:)=dqdsst;
  nc{'dQdSST'}(12+tindex,:,:)=dqdsst;
  nc{'dQdSST'}(24+tindex,:,:)=dqdsst;
  nc{'dQdSST'}(36+tindex,:,:)=dqdsst;
end
for tindex=1:length(coads_time)
  time=coads_time(tindex);
  nc{'SSS'}(tindex,:,:)=ext_data(sss_file,sss_name,tindex,...
                                 lon,lat,time,Roa,1);
  nc{'SSS'}(12+tindex,:,:)=ext_data(sss_file,sss_name,tindex,...
                                 lon,lat,time,Roa,1);                             
  nc{'SSS'}(24+tindex,:,:)=ext_data(sss_file,sss_name,tindex,...
                                 lon,lat,time,Roa,1); 
  nc{'SSS'}(36+tindex,:,:)=ext_data(sss_file,sss_name,tindex,...
                                 lon,lat,time,Roa,1); 
end
for tindex=1:length(coads_time)
  time=coads_time(tindex);
  nc{'swrad'}(tindex,:,:)=ext_data(srf_file,srf_name,tindex,...
                                  lon,lat,time,Roa,1);
  nc{'swrad'}(12+tindex,:,:)=ext_data(srf_file,srf_name,tindex,...
                                  lon,lat,time,Roa,1);
  nc{'swrad'}(24+tindex,:,:)=ext_data(srf_file,srf_name,tindex,...
                                  lon,lat,time,Roa,1);
  nc{'swrad'}(36+tindex,:,:)=ext_data(srf_file,srf_name,tindex,...
                                  lon,lat,time,Roa,1);
end
close(nc)
%
% Make a few plots
%
if makeplot==1
  disp(' ')
  disp(' Make a few plots...')
  test_forcing(frcname,grdname,'spd',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'shflux',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'swflux',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'SST',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'SSS',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'dQdSST',[1 4 7 10],3,coastfileplot)
  figure
  test_forcing(frcname,grdname,'swrad',[1 4 7 10],3,coastfileplot)
end
%
% End
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
