function trackfeatures = trackmateTrackFeatures(filePath, channel, channelNumber) 
    TRACKMATE_ELEMENT           = 'TrackMate';
    TRACK_ID_ATTRIBUTE          = 'TRACK_ID';
    TRACK_NAME_ATTRIBUTE        = 'name';
    
    try
        xmlDoc = xmlread( filePath );
    catch
        error('Failed to read XML file %s.',filePath);
    end
    xmlRoot = xmlDoc.getFirstChild();

    if ~strcmp(xmlRoot.getTagName, TRACKMATE_ELEMENT)
        error('MATLAB:trackMateGraph:BadXMLFile', ...
        'File does not seem to be a proper TrackMate file.')
    end

    import javax.xml.xpath.*

    factory = XPathFactory.newInstance;
    xPath = factory.newXPath;

    xPathFTrackFilter   = xPath.compile('//Model/FilteredTracks/TrackID');
    fTrackNodeList      = xPathFTrackFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nFTracks            = fTrackNodeList.getLength();

    fTrackIDs = NaN( nFTracks, 1);

    for i = 1 : nFTracks
        fTrackIDs( i ) = str2double( fTrackNodeList.item( i-1 ).getAttribute( TRACK_ID_ATTRIBUTE ) );
    end

    xPathTrackFilter    = xPath.compile('//Model/AllTracks/Track');
    trackNodeList       = xPathTrackFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nTracks             = trackNodeList.getLength();


    trackMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    xPathTrackFilter_LFP = xPath.compile('./@LINEARITY_OF_FORWARD_PROGRESSION');
    xPathTrackFilter_MAX_DISTANCE_TRAVELED = xPath.compile('./@MAX_DISTANCE_TRAVELED');
    xPathTrackFilter_TOTAL_DISTANCE_TRAVELED = xPath.compile('./@TOTAL_DISTANCE_TRAVELED');
    xPathTrackFilter_NUMBER_SPOTS = xPath.compile('./@NUMBER_SPOTS');

    LFP = {};
    MAX_DISTANCE_TRAVELED = {};
    TOTAL_DISTANCE_TRAVELED = {};
    NUMBER_SPOTS = {};
    Tracks = {};
    for i = 1 : nTracks

        trackNode       = trackNodeList.item( i-1 );
        trackID         = str2double( trackNode.getAttribute( TRACK_ID_ATTRIBUTE ) );
        trackName       = strcat(channel, '_', char( trackNode.getAttribute( TRACK_NAME_ATTRIBUTE ))) ;
        
        if any( trackID == fTrackIDs )
            Tracks = [Tracks, trackName];
            LFP = [LFP, str2double(xPathTrackFilter_LFP.evaluate( trackNode, XPathConstants.STRING))];
            MAX_DISTANCE_TRAVELED =[MAX_DISTANCE_TRAVELED, str2double(xPathTrackFilter_MAX_DISTANCE_TRAVELED.evaluate( trackNode, XPathConstants.STRING ))];
            TOTAL_DISTANCE_TRAVELED =[TOTAL_DISTANCE_TRAVELED, str2double(xPathTrackFilter_TOTAL_DISTANCE_TRAVELED.evaluate( trackNode, XPathConstants.STRING ))];
            NUMBER_SPOTS = [NUMBER_SPOTS, str2double(xPathTrackFilter_NUMBER_SPOTS.evaluate( trackNode, XPathConstants.STRING ))];

        end
    end
    featurecell = [Tracks', LFP',MAX_DISTANCE_TRAVELED', TOTAL_DISTANCE_TRAVELED', NUMBER_SPOTS'];
    trackfeatures = cell2table(featurecell,'VariableNames',{'TRACK_KEY' 'LINEARITY_OF_FORWARD_PROGRESSION' 'MAX_DISTANCE_TRAVELED' 'TOTAL_DISTANCE_TRAVELED' 'NUMBER_SPOTS'}) ;
    trackfeatures = addvars(trackfeatures, repmat(channelNumber,length(Tracks),1), 'before', 'TRACK_KEY', 'NewVariableNames', 'CHANNEL_NUMBER')
end
