""" Create the auxillary JSON metadata that goes with this production 

{"meta": {"vcp": 212, "product": "N0Q", "valid": "2014-06-25T20:43:55Z", "site": "DMX"}}

"""
import json
import sys
import os
import datetime
import tempfile
import subprocess

if __name__ == '__main__':
    # Go Main Go
    ts = datetime.datetime( int(sys.argv[1]), int(sys.argv[2]), 
                            int(sys.argv[3]), int(sys.argv[4]),
                            int(sys.argv[5]) )
    prod = sys.argv[6]
    
    res = {'meta': {'vcp': None, 'product': prod, 'site': 'USCOMP',
                    'valid': ts.strftime("%Y-%m-%dT%H:%M:%SZ")}}
    
    (tmpfp, tmpfn) = tempfile.mkstemp()
    os.write(tmpfp, json.dumps(res) )
    os.close(tmpfp)
    cmd = ("/home/ldm/bin/pqinsert -p 'gis r %s gis/images/4326/USCOMP/%s_"
           +" bogus json' %s") % (ts.strftime("%Y%m%d%H%M"), prod.lower(),
                                  tmpfn)
    subprocess.call(cmd, shell=True)
    os.unlink(tmpfn)