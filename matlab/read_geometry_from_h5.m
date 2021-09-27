close all
cd /System/Volumes/Data/mnt/t31/insar/SANEM/SENTINEL/T144d/mintpyRAMP/work
fname = 'geometryRadarUTM.h5'
I=h5info(fname)
I.Datasets
H=h5read(fname,'/height');
figure;
title(fname)
imagesc(H);
axis xy
xlabel('Longitude');
ylabel('Latitude');
colormap(jet);
colorbar;
figure;
E=h5read(fname,'/easting');
N=h5read(fname,'/northing');
plot(E/1.e3,N/1.e3,'.');
xlabel('UTM Easting [km]');
ylabel('UTM Northing [km]');
title(fname)