#! /usr/bin/env python

import os
from os import listdir
import sys
import datetime
import argparse
import getpass
import requests
from requests.auth import HTTPBasicAuth
import netrc
import asf_search as asf

DESCRIPTION = """
Command line client 
"""

EXAMPLE = """Usage Examples:
download_asf.py -n sanem -t 144 -s 20220331 -e 20220506 -a download
  
"""
   
def download_from_asf(site_name, output_dir, track, start_date, end_date, action):
    
    # set polygon based on site
    if site_name.lower() == 'sanem':
        polygon='POLYGON((-119.4600000000 40.3480000000, -119.3750000000 40.3480000000, -119.3750000000 40.4490000000, -119.4600000000 40.4490000000, -119.4600000000 40.3480000000))'
    elif site_name.lower() == 'forge':
        polygon='POLYGON((-112.9852300489 38.4450885264, -112.7536042430 38.4450885264, -112.7536042430 38.5924406708, -112.9852300489 38.5924406708, -112.9852300489 38.4450885264))'
    elif site_name.lower() == 'mcgin':
        polygon='POLYGON((-116.9505358645377 39.54986687495545, -116.8500501384442 39.54993172719434, -116.8494884150711 39.62923290986418, -116.9500887617826 39.62916863967577, -116.9505358645377 39.54986687495545 ))'
    else:
        print(f,'unknown site_name {site_name}')
    
    # https://gis.stackexchange.com/questions/237116/sentinel-1-relative-orbit
    # set default track based on site
    if track is None :
        if  site_name.lower() == 'sanem': 
            relOrb=144
        elif site_name.lower() == 'forge':
            relOrb=20
        elif site_name.lower() == 'mcgin':
            relOrb=71
        else:
            # set to all allowable values
            relOrb=(0,176)
            print(f,'Setting relorb to {relOrb}')
    else:
        relOrb=track
                
      
    # https://docs.asf.alaska.edu/api/keywords/  
    results = asf.geo_search(
        intersectsWith=polygon,
        dataset=asf.PLATFORM.SENTINEL1,
        relativeOrbit=relOrb,
        start=start_date,
        end=end_date,
        processingLevel=asf.constants.PRODUCT_TYPE.SLC,
        maxResults=250)

    nFiles=len(results)
    print(f'Found nFiles {nFiles}')  
    listFilePath = 'search.csv'
    for i in range(nFiles):
        print(f'\n i is {i}')
        url     = results[i].properties["url"]
        print(f'\turl is {url}')
        remoteFileName = results[i].properties["fileName"]
        print(f'\tremoteFileName is {remoteFileName}')
        
        localFileName = output_dir + '/' + remoteFileName  # 
        print(f'\tlocalFileName is {localFileName}')
        
        with open(listFilePath, 'a') as file:
            list1 = url + ',' + remoteFileName +  ',' + localFileName + '\n'
            file.write(list1)  # Add a newline character to separate lines
        
    if action.lower() == 'download':           

        # Read the credentials from the .netrc file
        credentials = netrc.netrc()

        # Specify the machine (e.g., "example.com") for which you want to retrieve credentials
        machine = "urs.earthdata.nasa.gov"

        # Get the login and password from the .netrc file
        try:
            username, account, password = credentials.authenticators(machine)
        except ValueError as e:
            print(f'Exception {e}')
        else:
            print(f'Successfully logged in as {username}')
            
 
            for i in range(nFiles):
                    url     = results[i].properties["url"]
                    print(f'url is {url}')
                    remoteFileName = results[i].properties["fileName"]
                    print(f'remoteFileName is {remoteFileName}')
                    
                    localFileName = output_dir + '/' + remoteFileName  #             
                
                    if os.path.exists(localFileName):
                        print(f'local file named {localFileName} already exists. Not downloading again.')
                    else:
                        # Send a GET request with cookies and follow redirects
                        #response = requests.get(url, cookies={'urs_user': 'feigl'}, allow_redirects=True, stream=True)
                        response = requests.get(url, auth=HTTPBasicAuth(username, password), allow_redirects=True, stream=True)

                        # Check if the request was successful
                        if response.status_code == 200:
                            total_size = int(response.headers.get('content-length', 0))
                            block_size = 100*1024*1024  # You can adjust this value for larger or smaller updates
                            print(f'Starting download with block_size of {block_size} bytes')
                            formattedString2 = " {:.0f} Mbyte".format(100*total_size/block_size)
                            print(formattedString2)
                            
                            bytes=0;
                            with open(localFileName, 'wb') as file:
                                for data in response.iter_content(block_size):
                                    file.write(data)
                                    bytes=bytes+block_size
                                    #progress_bar.update(len(data))
                                    formattedString1 = "Downloaded {:.0f}".format(100*bytes/block_size)
                                    print(formattedString1 + ' of ' + formattedString2)
                            
                        else:
                            print(f'Failed to download the file. Status code: {response.status_code}')

                        # Close the session
                        response.close()   
def main():
    #today = datetime.now()

    # Format the date as "yyyy mm dd"
    #formatted_date = today.strftime("%Y%m%d")
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--site_name', type=str, help='5-digit code for site, e.g. SANEM')
    parser.add_argument('-o', '--output_dir', type=str, help='working directory for output',default='.')
    parser.add_argument('-t', '--track', type=str, help='track, i.e. relative orbit number. e.g., 144',default=None)
    parser.add_argument('-a', '--action', type=str, help='action, e.g. search or download',default='search')
    # Define optional arguments with nargs='?'
    parser.add_argument('-s', '--start_date', nargs='?', type=str, help='start_date, e.g.20220101 ',default='20160101')
    parser.add_argument('-e', '--end_date', nargs='?',type=str, help='end_date, e.g.20220601',default='20250101')

    args = parser.parse_args()
    
    yyyy=args.start_date[0:4]
    mm=args.start_date[4:6]
    dd=args.start_date[6:8]
    start_date=yyyy + "-" + mm + "-" + dd
    print(f'start_date is {start_date}')
    
    yyyy=args.end_date[0:4]
    mm=args.end_date[4:6]
    dd=args.end_date[6:8]
    end_date=yyyy + "-" + mm + "-" + dd
    print(f'end_date is   {end_date}')
    
    download_from_asf(args.site_name, args.output_dir, args.track, start_date, end_date, args.action)

if (__name__ == '__main__'):
    main()




