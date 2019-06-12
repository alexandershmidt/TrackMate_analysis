function trackmateLog(logfile, path_xml)

    % Import the XPath classes
    import javax.xml.xpath.*

    % Construct the DOM.
    xmlDoc = xmlread(path_xml);
    % Create an XPath expression.
    factory = XPathFactory.newInstance;
    xpath = factory.newXPath;
    [~, xml_name] = fileparts(path_xml);
    fprintf(logfile,'%s\r\n','');
    fprintf(logfile,'%s\r\n',['XML_NAME = ' xml_name]);
    expression = xpath.compile('TrackMate/Settings/DetectorSettings/@DETECTOR_NAME');
    DETECTOR_NAME = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['DETECTOR_NAME = ' DETECTOR_NAME]);
    expression = xpath.compile('TrackMate/Settings/DetectorSettings/@RADIUS');
    RADIUS = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['RADIUS = ' RADIUS]);
    expression = xpath.compile('TrackMate/Settings/DetectorSettings/@THRESHOLD');
    THRESHOLD = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['THRESHOLD = ' THRESHOLD]);
    expression = xpath.compile('TrackMate/Settings/DetectorSettings/@DO_MEDIAN_FILTERING');
    DO_MEDIAN_FILTERING = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['DO_MEDIAN_FILTERING = ' DO_MEDIAN_FILTERING]);
    expression = xpath.compile('TrackMate/Settings/DetectorSettings/@DO_SUBPIXEL_LOCALIZATION');
    DO_SUBPIXEL_LOCALIZATION = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['DO_SUBPIXEL_LOCALIZATION = ' DO_SUBPIXEL_LOCALIZATION]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/@TRACKER_NAME');
    TRACKER_NAME = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['TRACKER_NAME = ' TRACKER_NAME]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/Linking/@LINKING_MAX_DISTANCE');
    LINKING_MAX_DISTANCE = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['LINKING_MAX_DISTANCE = ' LINKING_MAX_DISTANCE]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/GapClosing/@ALLOW_GAP_CLOSING');
    ALLOW_GAP_CLOSING = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['ALLOW_GAP_CLOSING = ' ALLOW_GAP_CLOSING]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/GapClosing/@GAP_CLOSING_MAX_DISTANCE');
    GAP_CLOSING_MAX_DISTANCE = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['GAP_CLOSING_MAX_DISTANCE = ' GAP_CLOSING_MAX_DISTANCE]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/GapClosing/@MAX_FRAME_GAP');
    MAX_FRAME_GAP = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['MAX_FRAME_GAP = ' MAX_FRAME_GAP]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/TrackSplitting/@ALLOW_TRACK_SPLITTING');
    ALLOW_TRACK_SPLITTING = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['ALLOW_TRACK_SPLITTING = ' ALLOW_TRACK_SPLITTING]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/TrackSplitting/@SPLITTING_MAX_DISTANCE');
    SPLITTING_MAX_DISTANCE = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['SPLITTING_MAX_DISTANCE = ' SPLITTING_MAX_DISTANCE]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/TrackMerging/@ALLOW_TRACK_MERGING');
    ALLOW_TRACK_MERGING = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['ALLOW_TRACK_MERGING = ' ALLOW_TRACK_MERGING]);
    expression = xpath.compile('TrackMate/Settings/TrackerSettings/TrackMerging/@MERGING_MAX_DISTANCE');
    MERGING_MAX_DISTANCE = expression.evaluate(xmlDoc,XPathConstants.STRING);
    fprintf(logfile,'%s\r\n',['MERGING_MAX_DISTANCE = ' MERGING_MAX_DISTANCE]);
end