#! /usr/bin/env python

import os
import sys
import datetime

# import json
# import datetime
# import time
# import csv
# from xml.dom import minidom
# import itertools
# import operator
# import re
import argparse

import requests
from os import listdir

import asf_search as asf

DESCRIPTION = """
Command line client 
"""

EXAMPLE = """Usage Examples:
  
"""
def start_session():
    session = asf.ASFSession() 

  
def download_from_asf(site_name, output_dir, track, start_date, end_date):
    
    if site_name.lower() == 'sanem':
        polygon='POLYGON((-119.4600000000 40.3480000000, -119.3750000000 40.3480000000, -119.3750000000 40.4490000000, -119.4600000000 40.4490000000, -119.4600000000 40.3480000000))'
        relOrb=144
    else:
        print(f,'unknown site_name {site_name}')
        
        
    results = asf.geo_search(
        intersectsWith=polygon,
        platform=asf.PLATFORM.SENTINEL1,
        relativeOrbit=relOrb,
        start=start_date,
        end=end_date,
        processingLevel=asf.constants.PRODUCT_TYPE.GRD_HD,
        maxResults=250)

    nFiles=len(results)
    print(f'Found nFiles {nFiles}')
    
    listFilePath = './search.csv'

    
    for i in range(nFiles):
            url     = results[i].properties["url"]
            print(f'url is {url}')
            remoteFileName = results[i].properties["fileName"]
            print(f'remoteFileName is {remoteFileName}')
            
            localFileName = './' + remoteFileName  # Use the current directory
            
            with open(listFilePath, 'w') as file:
                    file.write(url + ',' + remoteFileName +  '\n')  # Add a newline character to separate lines
        
            if os.path.exists(localFileName):
                print(f'local file named {localFileName} already exists. Not downloading again.')
            else:
                # Send a GET request with cookies and follow redirects
                response = requests.get(url, cookies={'urs_user': 'feigl'}, allow_redirects=True, stream=True)

                # Check if the request was successful
                if response.status_code == 200:
                    
                    total_size = int(response.headers.get('content-length', 0))
                    block_size = 100*1024*1024  # You can adjust this value for larger or smaller updates

                    bytes=0;
                    with open(localFileName, 'wb') as file:
                        for data in response.iter_content(block_size):
                            file.write(data)
                            bytes=bytes+block_size
                            #progress_bar.update(len(data))
                            formattedString1 = "Downloaded {:.0f}".format(100*bytes/block_size)
                            formattedString2 = " of {:.0f} Mbyte".format(100*total_size/block_size)
                            print(formattedString1+formattedString2)
                    
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
    parser.add_argument('-o', '--output_dir', type=str, help='working directory for output')
    parser.add_argument('-t', '--track', type=str, help='track, i.e. relative orbit number. e.g., 144')
    # Define optional arguments with nargs='?'
    parser.add_argument('-s', '--start_date', nargs='?', type=str, help='start_date, e.g.20220101 ',default='20160101')
    #parser.add_argument('-e', '--end_date', nargs='?',type=str, help='end_date, e.g.20220601',default=formatted_date)
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
    print(f'end_date is {end_date}')
    
    start_session()
    download_from_asf(args.site_name, args.output_dir, args.track, start_date, end_date)


if (__name__ == '__main__'):
    main()




