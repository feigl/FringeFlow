# README for GMTSAR files
# These files are specifically for high resolution data. All changes from original scripts are added as comment s to the top of the scripts 
#
# changes from original GMTSAR scripts:
# filter.csh - commented out lines for files we don't use to save processing time
#
# geocode.csh - geocode for phase_ll.grd;  separate into real and imaginary parts before geocoding, do not geocode unnecessary files, do not make google earth image
#
# proj_ra2ll.csh - set resolution based on DEM (currently set for Brady location)
