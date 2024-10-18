% import matlab.io.xml.dom.*
% 
% doc = parseFile(Parser,"SUIT75_23_05_24_LH_FEED_QTY.xml");

sampleXMLfile = "SUIT75_23_05_24_LH_FEED_QTY.xml";
%type(sampleXMLfile)

theStruct = parseXML(sampleXMLfile);