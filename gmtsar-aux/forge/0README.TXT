On  2019-Dec-12, at 16:49 , Ben Erickson <benerickson@utah.gov> wrote:

Hi Kurt,

I believe you requested the GPS data during the FORGE meeting this morning. Attached is the spreadsheet I use to track and determine vector change from the monitoring campaigns and our technical report. 

Here's a primer to read the spreadsheet, the first three tabs are not used in the study, they are comparisons to Initial A, which was using outdated firmware. The GPS Monitoring Initial B tab contains comparison calculations from Initial B to the most recent and between each campaign. The tabs following are the tabular results of the campaign and the difference from Initial B (March 11-12, 2019). The Adj_Elevation column is a thermal adjustment based on temperature of the ground at the time of occupation compared to Initial A thermal values, further explanation is within the attached report; thermal values are calculated in a separate spreadsheet. The remainder of the columns should be self explanatory, but please let me know if you have any questions.

I will be out of the office until Wednesday next week, performing campaign 4 for the project. If there are questions about the data Steve Bowman can address them in my absence. Please let us know if there are questions or concerns. 

Thanks,
Ben
--
Ben Erickson, M.S., P.G.
Hazard Mapping Project Geologist
Utah Geological Survey
1594 W. North Temple, Salt Lake City, Utah 84114-6100
(801) 537-3379


<FORGE_GPS_Monitoring.xlsx><FORGE GDM Report 3_12-2019.pdf>


Wed Jan 29 2020 Kurt Feigl

Extracted by Kurt Feigl 2020/01/29 from FORGE_GPS_Monitoring.xlsx [2019

FORGE_GPS_MonitoringCoordinatesOnly.txt

Create Files for InSAR plotting


  FORGE_GPS_MonitoringCoordinatesOnly.txt | awk '{print $6,$5,$8,"0",$1}' > forge_gps_utm.txt
  FORGE_GPS_MonitoringCoordinatesOnly.txt | awk '{print $4,$3,$8,"0",$1}' > forge_gps.txt

