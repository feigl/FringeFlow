#!/usr/bin/python

import os
import logging
import logging.handlers
import sys
import shutil
import traceback
from optparse import OptionParser
import signal
import subprocess
import time
import re
import datetime
import mimetypes
import ConfigParser
import glob
from lxml import etree
import hashlib
import zipfile
import threading
import Queue

log = logging.getLogger(__file__)

cookies_txt = "asf_cookies.txt"
version = "0.9"

def get_cla():
    parser = OptionParser()
    parser.add_option(
        "--debug", action="store_true", dest="debug", help="Print out debug messages"
    )
    parser.add_option(
        "--version", action="store_true", dest="version", help="Print the version number and exit"
    )
    parser.add_option(
        "--platform", action="store", dest="platforms", help="Platform to search for (e.g., ALOS, ERS-1)"
    )
    parser.add_option(
        "--beam-mode", "--beam_mode", "--beammode", action="store", dest="beammodes",
        help="Beam Modes to search for (e.g., FBS, FBD)"
    )
    parser.add_option(
        "--start_time", "--start-time", action="store", dest="start_time",
        help="Start time for the search (format is YYYY-MM-DDTHH:MM:SS)"
    )
    parser.add_option(
        "--end_time", "--end-time", action="store", dest="end_time",
        help="End time for the search (format is YYYY-MM-DDTHH:MM:SS)"
    )
    parser.add_option(
        "--polygon", action="store", dest="polygon",
        help="Comma-separated list of lon,lat values (e.g.: -155.08,65.82,-153.28,64.47,-149.94,64.55,-149.50,63.07,-153.5,61.91)"
    )
    parser.add_option(
        "--delay", action="store", dest="delayStr",
        help="Seconds between granule fetching (e.g.: 3600, to get a granule once per hour)"
    )
    parser.add_option(
        "--dir", action="store", dest="dataDir", help="Directory to store downloaded granules"
    )
    parser.add_option(
        "--tmp", action="store", dest="tmpDir", help="Directory to store temporary files (default: /tmp)"
    )
    parser.add_option(
        "--user", "--username", action="store", dest="user", help="URS Username"
    )
    parser.add_option(
        "--pass", "--password", action="store", dest="password", help="URS Password"
    )
    parser.add_option(
        "--max", "--max_results", action="store", dest="maxStr", help="Maximum Number of Granules to Return"
    )
    parser.add_option(
        "--resume", action="store_true", dest="resume",
        help="If a file is already present in the download directory, instruct wget to attempt to resume the download of that file."
    )
    parser.add_option(
        "--ignore", action="store_true", dest="ignore",
        help="If a file is already present in the download directory, skip it."
    )
    parser.add_option(
        "--overwrite", "--redownload", action="store_true", dest="overwrite",
        help="If a file is already present in the download directory, download it again."
    )
    parser.add_option(
        "--l0", "--RAW", action="store_true", dest="l0",
        help="Download the Level 0 product (L1.0 for PALSAR, RAW for Sentinel) for a granule."
    )
    parser.add_option(
        "--slc", "--SLC", action="store_true", dest="slc",
        help="Download the SLC product (L1.1 for PALSAR) for a granule.  Legacy platforms do not have this product."
    )
    parser.add_option(
        "--l1", "--detected", "--GRD", action="store_true", dest="l1",
        help="Download the Level 1 product (L1.5 for PALSAR, GRD for Sentinel) for a granule. (This is the default)"
    )
    parser.add_option(
        "--verify", action="store_true", dest="verify", help="Verify checksums of downloaded files (Sentinel only)"
    )
    parser.add_option(
        "--max_retry", "--max-retry", "--retries", action="store", dest="max_retries", help="How many times to retry a failed download"
    )
    parser.add_option(
        "--wget_options", "--wget-options", action="store", dest="wget_options", help="Adds options to the wget commands responsible for downloading files. For example '--no-check-certificate' should be used if an invalid certificate is preventing downloading."
    )
    parser.add_option(
        "--threads", action="store", dest="threads_num", default=1, type="int", help="Specifies the number of threads to be used for downloading; default is 1."
    )
    (options, args) = parser.parse_args()
    return (options, args)


def setup_logger(dbg):
    if dbg:
        lvl = logging.DEBUG
    else:
        lvl = logging.INFO
    log.setLevel(lvl)

    handler_stream = logging.StreamHandler(sys.stdout)

    formatter = logging.Formatter('%(asctime)s [%(threadName)s] [%(levelname)s] %(message)s')
    handler_stream.setFormatter(formatter)

    handler_stream.setLevel(lvl)
    log.addHandler(handler_stream)

def get_config(cfg):
    cfg_path = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, "config"))
    cfg_file = os.path.join(cfg_path, 'get_asf.cfg')
    if os.path.isfile(cfg_file):
        config = ConfigParser.ConfigParser()
        config.read(cfg_file)

        if cfg.user is None and config.has_option('general', 'user'): cfg.user = config.get('general', 'user')
        if cfg.user is None and config.has_option('general', 'username'): cfg.user = config.get('general', 'username')
        if cfg.password is None and config.has_option('general', 'password'): cfg.password = config.get('general', 'password')
        if cfg.password is None and config.has_option('general', 'pass'): cfg.password = config.get('general', 'pass')
        if cfg.dataDir is None and config.has_option('general', 'dir'): cfg.dataDir = config.get('general', 'dir')
        if cfg.tmpDir is None and config.has_option('general', 'tmp'): cfg.tmpDir = config.get('general', 'tmp')
        if cfg.max_retries is None and config.has_option('general', 'max_retries'): cfg.max_retries = config.get('general', 'max_retries')
        if cfg.wget_options is None and config.has_option('general', 'wget_options'): cfg.wget_options = config.get('general', 'wget_options')
        if cfg.threads_num is None and config.has_option('general', 'threads'):
            cfg.threads_num = int(config.get('general', 'threads'))
        elif cfg.threads_num is None: cfg.threads_num = 1


def guess_platform(s):
    if s is None or len(s) == 0:
        return None

    plat = None
    #log.debug("Checking: '" + repr(s) + "'")
    if re.search("^S1[ABCD]_", s):
        plat = "Sentinel"
    elif re.search("^ALPSRP\d{9}", s):
        plat = "PALSAR"
    elif re.search("^AP_", s):
        plat = "PALSAR"
    elif re.search("^[JRE][12]", s):
        plat = s[0:2]
    elif re.search("^SS", s):
        plat = "SEASAT"
    elif re.search("^UA", s):
        plat = "UAVSAR"
    elif re.search("^AI", s):
        plat = "AIRMOSS"
    else:
        #log.warning(s + ": Not recognized")
        pass
    #log.debug(s + ": " + str(plat))

    return plat

def str_for_plat_lvl(platform, level):
    h = {
        "Sentinel-L0"  : "RAW",
        "Sentinel-SLC" : "SLC",
        "Sentinel-L1"  : "GRD",
        "PALSAR-L0"    : "L1.0",
        "PALSAR-SLC"   : "L1.1",
        "PALSAR-L1"    : "L1.5"
    }

    k = platform+"-"+level
    if k in h:
        return h[k]
    else:
        return level


def execute(cmd, expected=None, quiet=False):
    """
    Executes the specified script and returns its output.

    An exception is thrown if the script's exit code is non-zero, or the "expected" output
    file isn't found.  In those situations the output is inspected to try to find a useful error
    string to use as the Exception text.

    Params:
        cmd: Command-line to run.
        expected: A filename the script should generate.  The function checks for the existence
            of this file after the script completes, errors out of it isn't found.  When None,
            this check is skipped.
        quiet: If True, output from the script is not echoed.

    Returns:
        string containing the output of the script that was run.
    """

    log.debug('Running command: ' + cmd)
    rcmd = cmd + ' 2>&1'

    pipe = subprocess.Popen(rcmd, shell=True, stdout=subprocess.PIPE)
    output = pipe.communicate()[0]
    return_val = pipe.returncode
    log.debug('subprocess return value was ' + str(return_val))

    for line in output.split('\n'):
        if not quiet and len(line.rstrip()) > 0:
            log.debug('Proc: ' + line)

    if not quiet:
        log.debug('Finished: ' + cmd)

    if return_val != 0:
        log.debug('Nonzero return value!')
        tool = cmd.split(' ')[0]
        last = 'Nonzero return value: ' + str(return_val)
        for l in output.split('\n'):
            line = l.strip()
            if len(line) > 0:
                last = line
                if 'ERROR' in line.upper():
                    raise Exception(tool + ': ' + line)
        # No error line found, die with last line
        raise Exception(tool + ': ' + last)

    if expected is not None:
        log.debug('Checking for expected output: ' + expected)
        if os.path.isfile(expected):
            log.debug('Found: ' + expected)
        else:
            log.warning('Expected output file not found: ' + expected)
            raise Exception("Expected output file not found: " + expected)

    return output


def find_granules_file(i, granules, cfg):
    if os.path.isfile(granules) and (mimetypes.guess_type(granules)[0] == 'text/plain' or mimetypes.guess_type(granules)[0] == 'text/csv'):
        log.info("Opening " + granules)
        with open(granules, 'r') as fl:
            granule_list = fl.read().replace('\n', ' ').replace('\r', ' ').replace('<',' ').replace('>',' ').replace('/', ' ')
        return find_granules_list(i, granule_list, cfg)
    else:
        log.info("Adding " + granules)
        return find_granules_list(i, granules, cfg)


def fudge_level(g, l):
    if 'S1' in g:
        if 'GRD' in g: return 'L1'
        if 'SLC' in g: return 'SLC'
        if 'RAW' in g: return 'L0'
        if 'OCN' in g: return 'OCN'
    return l


def zpad6(i):
    return "00000"+str(i)[-6:]


def find_granules_list(i, granules, level):
    g = dict()
    t = dict()
    n = 0

    pr = {
           "Sentinel-1": r'S1[ABCD]_\w{2}_\w{4}_\w{4}_\d{8}T\d{6}_\d{8}T\d{6}_\d{6}_\w{6}_\w{4}',
           "PALSAR":     r'ALPSRP\d{9}'
         }
    for plat in pr:
        log.debug("Looking for " + plat)
	regex = re.compile(pr[plat])
	for granule_name in regex.findall(granules):
	    if granule_name not in g.values():
		n += 1
		k = zpad6(i) + '-' + zpad6(n)
		g[k] = granule_name
		log.debug('Found ' + granule_name)

		if plat in t:
		    t[plat] += 1
		else:
		    t[plat] = 1

    if n > 1:
        for p in t.keys():
            s = ""
            if t[p] > 1: s= "s"
            log.info("Found %d %s granule%s" % (t[p], p, s))

    return g


def find_granules_search(platforms, beammodes, starttime, endtime, polygon, max, level):
    s = "param?"
    if platforms is not None:
        s += "platform=" + platforms + "&"
    if beammodes is not None:
        s += "beamMode=" + beammodes + "&"
    if starttime is not None:
        s += "start=" + starttime.strftime("%Y-%m-%dT%H:%M:%SUTC") + "&"
    if endtime is not None:
        s += "end=" + endtime.strftime("%Y-%m-%dT%H:%M:%SUTC") + "&"
    if polygon is not None:
        s += "polygon=" + polygon + "&"

    s += ("maxResults=%d&output=CSV" % max)
    return do_granule_search(s, level)


def do_granule_search(search_str, level):
    if 'granule_list' in search_str:
        i = search_str.find('granule_list')+13
        g = search_str[i:search_str.find('&',i)]
        log.info('Searching for ' + g)

    cmd = ('wget -O- %s "https://api.daac.asf.alaska.edu/services/search/' + search_str + '"') % (cfg.wget_options)
    output = execute(cmd)

    granules = dict()
    for line in output.split("\n"):
        l = line.strip()
        if 'SAR' in l and ',' in l:
            if len(l.split(","))>8:
		g = l.split(",")[0][1:-1].strip() # granule name
		t = l.split(",")[8][1:-1].strip() # time
		if len(g) > 0:
                    if str_for_plat_lvl(guess_platform(g), fudge_level(g, level)) in l:
		        granules[t] = g
       
    if len(granules.keys()) == 0:
        log.warning('No results')
 
    return granules


def get_url(granule, level):
    cmd = ('wget -O- %s "https://api.daac.asf.alaska.edu/services/search/param?granule_list=%s&output=CSV"' % (cfg.wget_options, granule))
    output = execute(cmd)
    url = None

    for line in output.split("\n"):
        l = line.strip()
        if str_for_plat_lvl(guess_platform(granule), fudge_level(granule, level)) in l:
	    m = re.search('(http.*zip)', l)
            if m is not None:
	        url = m.group(0)

    log.debug("URL: " + str(url))
    return url


def verify_download(cfg, tmpName, finalName):
    try:
	if 'S1A' in tmpName:
            log.debug('Verifying Sentinel granule ' + tmpName)
	    uzDir = os.path.join(cfg.tmpDir, "tmp_" + str(os.getpid()))
	    log.debug('Unzipping into ' + uzDir)
	    d = do_unzip(tmpName, uzDir)
            ok = verify_checksums(d)
            shutil.rmtree(uzDir)
        if 'ALPSRP' in tmpName:
            log.debug('Verifying PALSAR granule ' + tmpName)
            ok = verify_zip(tmpName)
	else:
	    ok = True
    except Exception, e:
        log.info('Verify failed: ' + e.message)
        ok = False

    if ok:
        log.info('Verification passed for ' + os.path.basename(tmpName))
	log.debug('Moving: {0} -> {1}'.format(tmpName, cfg.dataDir))
        os.rename(tmpName, finalName)

    return ok


def download(cfg, keys_queue):
    n = len(cfg.new.keys())
    program_start_time = cfg.program_start_time
    while True:
        nfails = 0
        try:
            k = keys_queue.get(block=False)
        except Queue.Empty:
            break
        granule = cfg.new[k]

        url = get_url(granule, cfg.level)
        if url is None:
            log.warning("No URL found for: " + granule)
            continue

        path, fileName = os.path.split(url)
        realName = os.path.join(cfg.tmpDir, fileName)
        dataStr = realName + ".tmp"
        completeName = os.path.join(cfg.dataDir, fileName)

        resume_opt = ""
        get_it = True

        if os.path.isfile(completeName):
            log.info('Already have: ' + granule)
            continue

        log.info("Downloading " + granule + ": " + url)

        if os.path.isfile(realName):
            if cfg.overwrite:
                log.warning('Already exists: ' + realName + ' (overwriting)')
                os.remove(realName)
            elif cfg.ignore:
                log.info('Already exists: ' + realName + ' (skipped)')
                get_it = False
                if os.path.isfile(dataStr):
                    os.remove(dataStr)
            else:  # cfg.resume
                if os.path.isfile(dataStr):
                    # Just ignore the real file, try to resume the .tmp
                    pass
                else:
                    log.info('Already exists: ' + realName + ' (skipped)')
                    get_it = False

        if os.path.isfile(dataStr):
            if cfg.ignore:
                log.info('Already exists: ' + dataStr + ' (skipped)')
                get_it = False
            elif cfg.overwrite:
                log.warning('Already exists: ' + dataStr + ' (overwriting)')
                os.remove(dataStr)
            else:  ## cfg.resume, now the default
                log.info('Already exists: ' + dataStr + ' (resuming)')
                resume_opt = "--continue"

        if get_it:
            cmd = ('wget %s %s --http-user=%s --http-password=%s -O %s %s' % (cfg.wget_options, resume_opt, cfg.user, re.escape(cfg.password), dataStr, url))

            start_time = time.time()
            o = execute(cmd, dataStr, quiet=True)
            elapsed_time = time.time() - start_time
            rate = 0

            if 'The file is already fully retrieved; nothing to do' in o:
                log.info("Already completely downloaded: %s" % (granule)) # TODO Add counter
                amt = 0
            else:
                log.info("Completed: %s" % (granule)) # TODO Add counter
            
                # 162432397 (155M) remaining
                amt = None
                total = 0

                if resume_opt == "--continue":
                    m = re.search('(\d+) \(*?\) remaining', o)
                    if m is not None:
                        amt = int(m.group(1))
                        log.debug("Remaining: "+str(amt))

                m = re.search('saved \[(\d+)', o)
                if m is not None:
                    total = int(m.group(1))
                    if amt is None:
                        amt = total

                if amt is None:
                    amt_str = "(none) " 
                elif amt>1024*1024*1024:
                    amt_str = "(%.2f GB) " % (amt/1024.0/1024.0/1024.0)
                elif amt>1024*1024:
                    amt_str = "(%.2f MB) " % (amt/1024.0/1024.0)
                elif amt>1024:
                    amt_str = "(%.2f KB) " % (amt/1024.0)
                else:
                    amt_str = ""

                rate = amt/float(elapsed_time)/1024.0/1024.0

                log.debug('Downloaded %d/%d bytes %sin %ds (%.2f MB/s)' % (amt, total, amt_str, elapsed_time, rate))

                seconds_downloading = 0
                total_mb_downloaded = 0
                seconds_downloading += elapsed_time
                total_elapsed_time = time.time() - program_start_time
                total_mb_downloaded += amt/1024.0/1024.0
                eff = seconds_downloading*100.0/float(total_elapsed_time)
                orate = total_mb_downloaded/float(total_elapsed_time)
                orate2 = total_mb_downloaded/float(seconds_downloading)

                log.debug('Elapsed time: %ds, downloading %ds (%.2f%% efficiency).  Overall rate: %.2f MB/s (%.2f while transferring)'
                           % (total_elapsed_time, seconds_downloading, eff, orate, orate2))

            log.debug('Renaming: {0} -> {1}'.format(dataStr, realName))
            os.rename(dataStr, realName)

            if not cfg.debug:
                log.debug('Downloaded %s in %ds (%.2f MB/s)' % (fileName, elapsed_time, rate))

            if cfg.delay > 0:
                log.info("Waiting " + str(cfg.delay) + "s")
                time.sleep(cfg.delay)

        if os.path.isfile(realName):
            if cfg.verify:
                ok = verify_download(cfg, realName, completeName)
                if ok:
                    del cfg.new[k]
                else:
                    nfails += 1
                    os.unlink(realName)
            else:
                log.debug('Moving: {0} -> {1}'.format(fileName, cfg.dataDir))
                os.rename(realName, completeName)
                del cfg.new[k]

        elif os.path.isfile(completeName):
            log.debug("Skipped already completed: " + fileName)
        else:
            log.warning("As far as I know this should never happen.")

def download_granules(cfg, trynum=0):
    if cfg.new is None or len(cfg.new.keys()) == 0:
        log.error("No granules to get!")
        return

    # Check data directory
    if len(cfg.dataDir) >0 and not os.path.exists(cfg.dataDir):
        log.error('Data directory (%s) does not exist' % cfg.dataDir)
        sys.exit(1)

    i = 0
    n = len(cfg.new.keys())
    log.info("Have %d granules to get" % n)

    program_start_time = cfg.program_start_time
    nfails = 0

    # Get the data
    cfg.dataDir = os.path.abspath(cfg.dataDir)
    keys = sorted(cfg.new.keys())
    keys_queue = Queue.Queue()
    for k in keys:
        keys_queue.put(k)
    threads = [threading.Thread(target=download, args=(cfg, keys_queue))
            for i in range(cfg.threads_num)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    if nfails > 0:
        if trynum < cfg.max_retries:
            log.info('Retrying failed granules')
            download_granules(cfg, trynum=trynum+1)
        else:
            log.info('Reached maximum retries.')


def get_xml_attribute(obj, key, attr):
    """Search for and return a given XML attribute from the given XML tree structure"""

    o = obj.find(key)
    if o is not None and attr in o.attrib:
        return o.attrib[attr]
    else:
        raise Exception('Required XML attribute not found: ' + key + '["' + attr + '"]')


def get_text_attr(doc, attr):
    """
    Parses an XML attribute, returns it as a string.

    If there is no such attribute, returns the empty string.
    """

    a = doc.find(attr)
    if a is None:
        return ''
    else:
        return a.text


def find_manifest(dir):
    """
    Look in the specified directory for "manifest.safe"

    If the file can't be found, returns None.
    """
    # Look for manifest.safe
    p = os.path.join(dir, 'manifest.safe')
    if os.path.isfile(p):
        return p

    raise Exception('manifest.safe file was not found in ' + dir)


def verify_checksums(dir):
    """For every MD5 given in the manifest.safe file, check the associated file's MD5 to make sure it matches"""

    safe_file = find_manifest(dir)
    log.debug('Verifying MD5 checksums in manifest file')

    doc = etree.parse(safe_file)
    if doc is None:
        raise Exception('Could not parse manifest.safe file', failure_type='QC_FAILED')
    dos = doc.find('dataObjectSection')
    if dos is None:
        raise Exception('No dataObjectSection found in manifest.xml! Could not verify MD5 sums')
    for obj in dos.findall('dataObject'):
        loc = get_xml_attribute(obj, 'byteStream/fileLocation', 'href')
        if loc.startswith('./'):
            loc = loc[2:]

        md5 = get_text_attr(obj, 'byteStream/checksum')
        log.debug('Found: ' + loc + ', ' + md5)

        path = os.path.join(os.path.dirname(safe_file), loc)
        log.debug('Path: ' + path)
        if not os.path.isfile(path):
            raise Exception('manifest.safe has checksum for file that was not found: ' + loc)

        sz = os.stat(path).st_size
        file_size = get_xml_attribute(obj, 'byteStream', 'size')
        if file_size is not None and sz == int(file_size):
            log.debug('File Size ok: ' + str(file_size) + ' bytes')
        else:
            raise Exception('File size check failed for ' + os.path.basename(path) + '.  Manifest: ' + str(file_size) + ', actual: ' + str(sz))

        md5_2 = get_md5sum(path)
        if md5 == md5_2:
            log.debug('MD5 ok: ' + md5)
        else:
            raise Exception('Checksum failed for ' + os.path.basename(path) + '. Manifest: ' + md5 + ', actual: ' + md5_2)

    log.debug('All MD5 checks passed.')
    return True


def get_md5sum(filename):
    """Returns MD5 string of the given file"""

    hasher = hashlib.md5()
    with open(filename, 'rb') as afile:
        buf = afile.read()
        hasher.update(buf)
    return hasher.hexdigest()


def verify_zip(zipFilePath):
    log.debug('Verifying ' + zipFilePath)

    if not os.path.isfile(zipFilePath):
        raise Exception('File not found: ' + zipFilePath)

    z = zipfile.ZipFile(zipFilePath)
    ret = z.testzip()

    if ret is not None:
        raise Exception("First bad file in zip: " + ret)
    else:
        return True


def do_unzip(zipFilePath, destDir):
    """
    Unzips the path+file zipFilePath into the specified destDir
    """

    log.debug('Unzipping ' + zipFilePath + ' into ' + destDir)

    if not os.path.isfile(zipFilePath):
        raise Exception('File not found: ' + zipFilePath)

    try:
        z = zipfile.ZipFile(zipFilePath)

        z.extractall(destDir)

        retdir = None
        for name in z.namelist():
            (dirName, fileName) = os.path.split(name)
            if fileName == '':
                # directory
                newDir = destDir + '/' + dirName
                if not os.path.exists(newDir):
                    raise Exception('Directory not extracted! => ' + newDir)
                if retdir is None:
                    retdir = newDir
                    break

        z.close()
    except Exception, e:
        log.info(zipFilePath + ': Bad zip file!')
        tb = traceback.format_exc().split("\n")
        for tbline in tb:
            line = tbline.rstrip()
            if len(line) > 0:
                log.info(line)

        log.info('Trying command-line unzip')
        try:
            execute('unzip -d ' + destDir + ' ' + zipFilePath)

            # Here we use our insider knowledge
            retdir = os.path.join(destDir, os.path.basename(zipFilePath).replace('.zip', '') + '.SAFE')

        except Exception, e2:
            log.info(zipFilePath + ': Bad zip file again!')
            raise e

    return retdir


if __name__ == "__main__":
    (cfg, args) = get_cla()
    get_config(cfg)

    setup_logger(cfg.debug)

    if cfg.version:
        log.info("Version: " + version)
        sys.exit(0)

    cfg.program_start_time = time.time()
    log.debug("Start Time: " + str(datetime.datetime.fromtimestamp(cfg.program_start_time)))
    log.debug("Version: " + version)

    n_args = len(args)
    log.debug("Args: " + str(args))
  
    if cfg.wget_options is None:
        cfg.wget_options = ""

    cfg.level = "L1"
    if cfg.l0:
        cfg.level = "L0"
    if cfg.slc:
        cfg.level = "SLC"
 
    if cfg.dataDir is None:
        cfg.dataDir = ""

    if not cfg.tmpDir:
        cfg.tmpDir = os.path.join(cfg.dataDir, "download")

    if not os.path.isdir(cfg.tmpDir):
        log.info("Creating download directory: " + cfg.tmpDir)
        os.mkdir(cfg.tmpDir)

    if n_args == 0 and \
        cfg.platforms is None and \
        cfg.beammodes is None and \
        cfg.start_time is None and \
        cfg.end_time is None and \
        cfg.polygon is None:
        log.critical("Please specify granules to get, or search criteria.")
        exit(-1)

    if n_args > 0 and \
        (cfg.platforms is not None or \
        cfg.beammodes is not None or \
        cfg.start_time is not None or \
        cfg.end_time is not None or \
        cfg.polygon is not None):
        log.warning("Your search criteria will be ignored since you specified granules manually")

    if cfg.user is None or cfg.password is None:
        log.critical("Please provide your URS login credentials")
        exit(-1)

    if cfg.delayStr:
        cfg.delay = int(cfg.delayStr)
    else:
        cfg.delay = 0

    if cfg.maxStr:
        cfg.max = int(cfg.maxStr)
    else:
        cfg.max = 100

    # install signal handling for SIGTERM, SIGQUIT, and SIGHUP
    def signal_handler(signum, frame):
        # this ugly line creates a lookup table between signal numbers and their "nice" names
        signum_to_names = dict((getattr(signal, n), n) for n in dir(signal) if n.startswith('SIG') and '_' not in n )
        log.critical("Received a {0}; bailing out.".format(signum_to_names[signum]))
        sys.exit(1)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGQUIT, signal_handler)
    signal.signal(signal.SIGHUP, signal_handler)

    try:
        log.debug("Debug messages: " + str(cfg.debug))

        log.debug("Download Dir: " + cfg.tmpDir)
        log.debug("Data Dir: " + cfg.dataDir)
        log.debug("Delay: " + str(cfg.delay) + "s")
        log.debug("Max Results: " + str(cfg.max))
        log.debug("Max Retries: " + str(cfg.max_retries))

        if n_args > 0:
            cfg.new = dict()
            for i in xrange(0,n_args):
                g1 = find_granules_file(i, args[i], cfg)
                cfg.new.update(g1)
            download_granules(cfg)

        else:
	    start = None
	    if cfg.start_time:
		start = datetime.datetime.strptime(cfg.start_time, "%Y-%m-%dT%H:%M:%S")
		log.debug("Start Time: " + str(start))

	    end = None
	    if cfg.end_time:
		end = datetime.datetime.strptime(cfg.end_time, "%Y-%m-%dT%H:%M:%S")
		log.debug("End Time: " + str(start))

	    log.debug("Platform(s): " + str(cfg.platforms))
	    log.debug("Beam Mode(s): " + str(cfg.beammodes))
	    log.debug("Polygon: " + str(cfg.polygon))

	    cfg.new = find_granules(cfg.platforms, cfg.beammodes, start, end, cfg.polygon, cfg.max, cfg.level)

	    #g = find_granules('ALOS', 'FBS', datetime.datetime.strptime("2008-12-01T00:00:00", "%Y-%m-%dT%H:%M:%S"),
	    #                  datetime.datetime.strptime("2008-12-31T00:00:00", "%Y-%m-%dT%H:%M:%S"),
	    #                  "-155.08,65.82,-153.28,64.47,-149.94,64.55,-149.50,63.07,-153.5,61.91")
	    download_granules(cfg)

	log.info("Done")

    # if we get a SystemExit from down in, pass it thru silently
    except SystemExit:
        raise
    # trap Ctrl-C
    except KeyboardInterrupt:
        log.critical("Keyboard interrupt received (Ctrl-C).")
    except Exception, e:
        log.critical("Uncaught exception seen, traceback follows.")
        tb = traceback.format_exc().split("\n")
        for tbline in tb:
            log.info(tbline)
        log.critical("Aborting due to uncaught exception.")
