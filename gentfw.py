#!/usr/bin/env python

import time, mx.DateTime, sys, pg, random

v = sys.argv[1]
sector = sys.argv[2]
sts = sys.argv[3]
ts = mx.DateTime.strptime(sts, '%Y%m%d%H%M')


out = open("%s_N0Q_CLEAN_%s.tfw" % (sector, v), 'w')

if sector == 'US':
    wkt = "-126 50,-66 50,-66 24,-126 24,-126 50"
    out.write("""   0.0050000000000%s
   0.00000
   0.00000
  -0.005000000000000%s
-126.000000
  50.0000""" % (v, random.randint(0,1000) ) )
elif sector == 'AK':
    wkt = "-170.5 68.71,-130.50 68.71,-130.50 53.21,-170.5 53.21,-170.5 68.71"
    out.write("""   0.010000000000%s
   0.00000
   0.00000
  -0.01000000000000%s
-170.500000
  68.7100""" % (v, random.randint(0,1000) ) )
    
elif sector == 'HI': 
    wkt = "-162.41 24.44,-152.41 24.44,-152.41 15.44,-162.41 15.44,-162.41 24.44"
    out.write("""   0.005000000000%s
   0.00000
   0.00000
  -0.00500000000000%s
-162.400000
  24.4400""" % (v, random.randint(0,1000) ) )

out.close()

mydb = pg.connect('postgis', 'iemdb')
mydb.query("SET TIME ZONE 'GMT'")
sql = """INSERT into nexrad_n0q_tindex( the_geom, datetime, filepath) values 
  ('SRID=4326;MULTIPOLYGON(((%s)))', '%s', 
  '/mesonet/ARCHIVE/data/%s/GIS/%scomp/n0q_%s.png')""" % (wkt, ts.strftime("%Y-%m-%d %H:%M"), 
  ts.strftime("%Y/%m/%d"), sector.lower(), ts.strftime("%Y%m%d%H%M") )
mydb.query(sql)
