#! /usr/bin/env python

import os
import sys
# import json
# import datetime
# import time
# import csv
# from xml.dom import minidom
# import itertools
# import operator
# import re
import optparse
#import threading
import subprocess as sub
import requests
from os import listdir

import asf_search as asf

DESCRIPTION = """
Command line client 
"""

EXAMPLE = """Usage Examples:
  
"""


class MyParser(optparse.OptionParser):
    def format_epilog(self, formatter):
        return self.epilog
    def format_description(self, formatter):
        return self.description
    
def main(argv):
    ### READ IN PARAMETERS FROM THE COMMAND LINE ###
    parser = MyParser(description=DESCRIPTION, epilog=EXAMPLE, version='1.0')
    #querygroup = optparse.OptionGroup(parser, "Query Parameters", "These options are used for the API query.  "  
                                    #   "Use options to limit what is returned by the search. These options act as a way "
                                    #   "to filter the results and narrow down the search results.")
    

    results = asf.geo_search(
        intersectsWith='POLYGON((-91.97 28.78,-88.85 28.78,-88.85 30.31,-91.97 30.31,-91.97 28.78))',
        platform=asf.PLATFORM.UAVSAR,
        processingLevel=asf.PRODUCT_TYPE.METADATA,
        maxResults=20)

    #print(results[0].properties["url"])

    # results = requests.get('https://stackoverflow.com/questions/26000336')
    # print(f'text {results.text}')


    url     = results[0].properties["url"]
    print(f'url is {url}')
    fileName = results[0].properties["fileName"]
    print(f'fileName is {fileName}')
    
    # payload = { 'key' : 'val' }
    # headers = {}
    # res = requests.post(url, data=payload, headers=headers)
    # print(res.headers)

    # # https://wiki.earthdata.nasa.gov/display/EL/How+To+Access+Data+With+cURL+And+Wget
    # fetch_urls() {
    #         while read -r line; do
    #             curl -b ~/.urs_cookies -c ~/.urs_cookies -L -n -f -Og $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
    #         done;
    # }
    # fetch_urls <<'EDSCEOF'
    
    #cmd='curl -b ~/.urs_cookies -c ~/.urs_cookies -L -n -f -Og ' + results[0].properties["url"]
    #res=os.system(cmd)
    
    
    #   Replace 'YOUR_URL_HERE' with the URL you want to download.
    # Replace 'YOUR_URS_USER_HERE' with your URS user.
    # The code sends a GET request with cookies and follows redirects (-L in curl).
    # If the request is successful (HTTP status code 200), it saves the response content to a local file with the same name as the remote file (-Og in curl).
    # It saves the cookies to the specified cookie file (-c ~/.urs_cookies in curl).
    # The requests library handles cookies automatically, so you don't need to use the -b option like in curl.
    # 


    # Set the path for the cookie file
    cookie_file = '~/.urs_cookies'

    # Send a GET request with cookies and follow redirects
    response = requests.get(url, cookies={'urs_user': 'feigl'}, allow_redirects=True)
    

    # Check if the request was successful
    if response.status_code == 200:
        # Save the response content to a local file with the same name as the remote file
    #     with open(response.headers.get('content-disposition', '').split('filename=')[1], 'wb') as file:
    #         file.write(response.content)
        #print(response.content)
        #result=open(response.headers.get('content-disposition', '').split('filename=')[1], 'wb') 
  with open(response.headers.get('content-disposition', '').split('filename=')[1], 'wb') as file:
    #         file.write(response.content)
    else:
        print(f'Failed to download the file. Status code: {response.status_code}')

    # # Save the cookies to the cookie file
    # with open(cookie_file, 'w') as cookies:
    #     for key, value in response.cookies.items():
    #         cookies.write(f'{key}={value}\n')

    # Close the session
    response.close()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.argv.append('-h')
    main(sys.argv[1:])




