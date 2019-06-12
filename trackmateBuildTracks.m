function [track_keys, tracks] = trackmateBuildTracks(trackfilename)
    close all;    
    
    try
        track_map  = trackmateEdges(trackfilename);
    catch
        error('Error: extracting track_map from trackfilename failed');
    end 
    
    %initialize tracks containers
    spots_ids = containers.Map;
    tracks_displacement = containers.Map;
    tracks_link_cost = containers.Map;
    tracks_velocity = containers.Map;
    
    %loop through tracks
    for track = track_map.keys
        track_table = track_map(track{1});
        spot_id = setdiff(track_table.SPOT_SOURCE_ID, track_table.SPOT_TARGET_ID);
        
        %Prelocation
        list_length = height(track_table);
        spot_ids = zeros(1, list_length+1);
        track_displacement = zeros(1, list_length);
        track_link_cost = zeros(1, list_length);
        track_velocity = zeros(1, list_length);
        
        %loop through specific track
        while height(track_table) ~= 0
            spot_ids(list_length-height(track_table)+1) = spot_id;
            track_displacement(list_length-height(track_table)+1) = track_table.DISPLACEMENT(track_table.SPOT_SOURCE_ID == spot_id);
            track_link_cost(list_length-height(track_table)+1) = track_table.LINK_COST(track_table.SPOT_SOURCE_ID == spot_id);
            track_velocity(list_length-height(track_table)+1) = track_table.VELOCITY(track_table.SPOT_SOURCE_ID == spot_id);
            
            to_delete = track_table.SPOT_SOURCE_ID == spot_id;
            spot_id = track_table.SPOT_TARGET_ID(track_table.SPOT_SOURCE_ID == spot_id);
            track_table(to_delete, :)=[];
        end
        spot_ids(list_length+1) = spot_id;
        
        spots_ids(track{1}) =spot_ids;
        tracks_displacement(track{1}) = track_displacement;
        tracks_link_cost(track{1}) = track_link_cost;
        tracks_velocity(track{1}) = track_velocity;
         
    end
    track_keys = track_map.keys;
    tracks =struct('SPOTS_IDS', spots_ids, 'tracks_displacement', tracks_displacement, 'tracks_link_cost', tracks_link_cost, 'tracks_velocity', tracks_velocity);
end


function  trackMap = trackmateEdges(filePath, featureList)
%%TRACKMATEEDGES Import edges from a TrackMate data file.
%
%   trackMap = TRACKMATEEDGES(file_path) imports the edges - or links -
%   contained in the TrackMate XML file file_path. TRACKMATEEDGES only
%   imports the edges of visible tracks.
%
%   trackMap = TRACKMATEEDGES(file_path, feature_list) where feature_list
%   is a cell array of string only imports the edge features whose names
%   are in the cell array.
%
% INPUT:
%
%   file_path must be a path to a TrackMate file, containing the whole
%   TrackMate data, and not the simplified XML file that contains only
%   linear tracks. Such simplified tracks are imported using the
%   importTrackMateTracks function.
%
%   A TrackMate file is a XML file that starts with the following header:
%   <?xml version="1.0" encoding="UTF-8"?>
%       <TrackMate version="3.3.0">
%       ...    
%   and has a Model element in it:
%         <Model spatialunits="pixel" timeunits="sec">
%
% OUTPUT:
%
%   The output is a collection of tracks. trackMap is a Map that links
%   track names to a MATLAB table containing the edges of this track. The
%   columns of the table depend on the feature_list specified as second
%   argument, but it always contains at least the SPOT_SOURCE_ID and
%   SPOT_TARGET_ID features, that store the IDs of the source and target
%   spots.
%
% EXAMPLE:
%
%   >> trackMap = trackmateEdges(file_path);   
%   >> trackNames = trackMap.keys;
%   >> trackNames{1}
%
%   ans =
%       Track_0
%
%   >> trackMap('Track_0')
% 
%   ans = 
%     SPOT_SOURCE_ID    SPOT_TARGET_ID    DISPLACEMENT    LINK_COST    VELOCITY
%     ______________    ______________    ____________    _________    ________
% 
%     14580             16501             4.7503          1            4.7503  
%     12683             14580             2.8316          1            2.8316  
%     10813             12683             8.1622          1            8.1622  
%      5295              7123              3.193          1             3.193  
%      1715              3487             4.3063          1            4.3063  
%      7123              8953             3.0804          1            3.0804  
%      8953             10813             3.3689          1            3.3689  
%         0              1715             6.2733          1            6.2733  
%      3487              5295             5.9587          1            5.9587 
% 


% __
% Jean-Yves Tinevez - 2016

%% Import the XPath classes.
    import javax.xml.xpath.*
    
    %% Constants definition.

    TRACKMATE_ELEMENT           = 'TrackMate';
    TRACK_ID_ATTRIBUTE          = 'TRACK_ID';
    TRACK_NAME_ATTRIBUTE        = 'name';
    SPOT_SOURCE_ID_ATTRIBUTE    = 'SPOT_SOURCE_ID';
    SPOT_TARGET_ID_ATTRIBUTE    = 'SPOT_TARGET_ID';

    %% Open file
    filePath
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
    
    
    %% XPath initialization.
    factory = XPathFactory.newInstance;
    xPath = factory.newXPath;
    
    %% Retrieve edge feature list
    if nargin < 2 || isempty( featureList )
        xPathEdgeFilter = xPath.compile('//Edge');
        edgeNode        = xPathEdgeFilter.evaluate(xmlDoc, XPathConstants.NODE );
        featureList     = getEdgeFeatureList( edgeNode );
    end
    
    % Add spot source and target, whether they are here or not.
    featureList = union( SPOT_TARGET_ID_ATTRIBUTE, featureList, 'stable'  );
    featureList = union( SPOT_SOURCE_ID_ATTRIBUTE, featureList, 'stable' );
    nFeatures = numel( featureList );
    
    %% XPath to retrieve filtered track IDs.

    xPathFTrackFilter   = xPath.compile('//Model/FilteredTracks/TrackID');
    fTrackNodeList      = xPathFTrackFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nFTracks            = fTrackNodeList.getLength();
    
    fTrackIDs = NaN( nFTracks, 1);
    for i = 1 : nFTracks
        fTrackIDs( i ) = str2double( fTrackNodeList.item( i-1 ).getAttribute( TRACK_ID_ATTRIBUTE ) );
    end
    
    %% XPath to retrieve filtered track elements.
    
    xPathTrackFilter    = xPath.compile('//Model/AllTracks/Track');
    trackNodeList       = xPathTrackFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nTracks             = trackNodeList.getLength();
    
    % Prepare a map: trackName -> edge table. 
    trackMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    xPathEdgeFilter     = xPath.compile('./Edge');
    for i = 1 : nTracks
       
        trackNode       = trackNodeList.item( i-1 );
        trackID         = str2double( trackNode.getAttribute( TRACK_ID_ATTRIBUTE ) );
        trackName       = char( trackNode.getAttribute( TRACK_NAME_ATTRIBUTE ) );
        
        if any( trackID == fTrackIDs )
           
            edgeNodeList    = xPathEdgeFilter.evaluate( trackNode, XPathConstants.NODESET );
            nEdges          = edgeNodeList.getLength();
            features = NaN( nEdges, nFeatures );
            
            % Read all edge nodes.
            for k = 1 : nEdges
                node = edgeNodeList.item( k-1 );
                for j = 1 : nFeatures
                    features( k, j ) = str2double( node.getAttribute( featureList{ j } ) );
                end
            end
            
            % Create table.
            edgeTable = table();
            for j = 1 : nFeatures
                edgeTable.( featureList{ j } )   = features( :, j );
            end
            
            % Set table metadata.
            edgeTable.Properties.DimensionNames = { 'Edge', 'Feature' };
            
            vNames = edgeTable.Properties.VariableNames;
            nVNames = numel( vNames );
            vDescriptions   = cell( nVNames, 1);
            vUnits          = cell( nVNames, 1);
            
            [ ~, ef ] = trackmateFeatureDeclarations( filePath );
            for l = 1 : nVNames
                vn = vNames{ l };
                vDescriptions{ l }  = ef( vn ).name;
                vUnits{ l }         = ef( vn ).units;
            end
            edgeTable.Properties.VariableDescriptions   = vDescriptions;
            edgeTable.Properties.VariableUnits          = vUnits;
           
            trackMap( trackName ) = edgeTable;
            
        end
        
    end
    
     %% Subfunction.
    
    function featureList = getEdgeFeatureList(node)
        
        attribute_map = node.getAttributes;
        n_attributes = attribute_map.getLength;
        
        featureList = cell(n_attributes, 1);
        index = 1;
        for ii = 1 : n_attributes
            
            namel = node.getAttributes.item(ii-1).getName;
            featureList{index} = char(namel);
            index = index + 1;
            
        end
    end
    
end
function [ sf, ef, tf ] = trackmateFeatureDeclarations(filePath)
%%TRACKMATEFATUREDECLARATIONS Import feature declarations from a TrackMate file.
%
%   [ sf, ef, tf ] = TRACKMATEFEATUREDECLARATIONS(file_path) imports the
%   feature declarations stored in a TrackMate file file_path and returns
%   them as three maps:
%       - sf is the map for spot features;
%       - ef is the map for edge features;
%       - tf is the map for track features.
%   Each map links the feature key to a struct containing the feature
%   declaration.
%
% INPUT:
%
%   file_path must be a path to a TrackMate file, containing the whole
%   TrackMate data, and not the simplified XML file that contains only
%   linear tracks. Such simplified tracks are imported using the
%   importTrackMateTracks function.
%
%   A TrackMate file is a XML file that starts with the following header:
%   <?xml version="1.0" encoding="UTF-8"?>
%       <TrackMate version="3.3.0">
%       ...    
%   and has a Model element in it:
%         <Model spatialunits="pixel" timeunits="sec">
%
% EXAMPLE:
%
%   >> [ sf, ef, tf ] = trackmateFeatureDeclarations(file_path);
%   >> tf.keys
%   >> tf('TRACK_DISPLACEMENT')
%
%   ans = 
%           key: 'TRACK_DISPLACEMENT'
%          name: 'Track displacement'
%     shortName: 'Displacement'
%     dimension: 'LENGTH'
%         isInt: 0
%         units: 'pixels'

% __
% Jean-Yves Tinevez - 2016


    %% Import the XPath classes.
    import javax.xml.xpath.*
    
    
    %% Constants definition.
    TRACKMATE_ELEMENT           = 'TrackMate';
    SPATIAL_UNITS_ATTRIBUTE     = 'spatialunits';
    TIME_UNITS_ATTRIBUTE        = 'timeunits';
    FEATURE_KEY_ATTRIBUTE       = 'feature';
    FEATURE_NAME_ATTRIBUTE      = 'name';
    FEATURE_SHORTNAME_ATTRIBUTE = 'shortname';
    FEATURE_DIMENSION_ATTRIBUTE = 'dimension';
    FEATURE_ISINT_ATTRIBUTE     = 'isint';
        
    
    %% Open and check XML.
    
    try
        xmlDoc = xmlread(filePath);
    catch
        error('Failed to read XML file %s.',filePath);
    end
    xmlRoot = xmlDoc.getFirstChild();
    
    if ~strcmp(xmlRoot.getTagName, TRACKMATE_ELEMENT)
        error('MATLAB:trackMateGraph:BadXMLFile', ...
            'File does not seem to be a proper TrackMate file.')
    end
    
    factory = XPathFactory.newInstance;
    xpath = factory.newXPath;
    
    %% Retrieve physical units.
    
    modelPath   =  xpath.compile('/TrackMate/Model');
    modelNode   = modelPath.evaluate(xmlRoot, XPathConstants.NODESET).item(0);
    spaceUnits  = char( modelNode.getAttribute( SPATIAL_UNITS_ATTRIBUTE ) );
    timeUnits   = char( modelNode.getAttribute( TIME_UNITS_ATTRIBUTE ) );
    
    %% XPath to retrieve spot feature declarations.
    
    spotFeatureFilter = xpath.compile('/TrackMate/Model/FeatureDeclarations/SpotFeatures/Feature');
    spotFeatureNodes = spotFeatureFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nSpotFeatureNodes = spotFeatureNodes.getLength();
    
    sf = containers.Map();
    for i = 1 : nSpotFeatureNodes
        f = readFeature( spotFeatureNodes.item( i-1 ), spaceUnits, timeUnits );
        sf( f.key ) = f;
    end
    
    %% XPath to retrieve edge feature declarations.
    
    edgeFeatureFilter = xpath.compile('/TrackMate/Model/FeatureDeclarations/EdgeFeatures/Feature');
    edgeFeatureNodes = edgeFeatureFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nEdgeFeatureNodes = edgeFeatureNodes.getLength();
    
    ef = containers.Map();
    for i = 1 : nEdgeFeatureNodes
        f = readFeature( edgeFeatureNodes.item( i-1 ), spaceUnits, timeUnits );
        ef( f.key ) = f;
    end
    
    %% XPath to retrieve track feature declarations.
    
    trackFeatureFilter = xpath.compile('/TrackMate/Model/FeatureDeclarations/TrackFeatures/Feature');
    trackFeatureNodes = trackFeatureFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    nTrackFeatureNodes = trackFeatureNodes.getLength();
    
    tf = containers.Map();
    for i = 1 : nTrackFeatureNodes
        f = readFeature( trackFeatureNodes.item( i-1 ), spaceUnits, timeUnits );
        tf( f.key ) = f;
    end
    
    
    
    %% Subfunctions.
    
    function f = readFeature(featureNode, spaceUnits, timeUnits)
       
        key         = char( featureNode.getAttribute( FEATURE_KEY_ATTRIBUTE ) );
        name        = char( featureNode.getAttribute( FEATURE_NAME_ATTRIBUTE ) );
        shortName   = char( featureNode.getAttribute( FEATURE_SHORTNAME_ATTRIBUTE ) );
        dimension   = char( featureNode.getAttribute( FEATURE_DIMENSION_ATTRIBUTE ) );
        isInt       = strcmp( 'true', char( featureNode.getAttribute( FEATURE_ISINT_ATTRIBUTE ) ) );
        units       = determineUnits( dimension, spaceUnits, timeUnits );
        
        f = struct();
        f.key       = key;
        f.name      = name;
        f.shortName = shortName;
        f.dimension = dimension;
        f.isInt     = isInt;
        f.units     = units;
        
    end

    function  units = determineUnits( dimension, spaceUnits, timeUnits )
        switch ( dimension )
            case 'ANGLE'
                units = 'Radians';
            case 'INTENSITY'
                units = 'Counts';
            case 'INTENSITY_SQUARED'
                units = 'Counts^2';
            case' NONE'
                units = '';
            case { 'POSITION', 'LENGTH' }
                units = spaceUnits;
            case 'QUALITY'
                units = 'Quality';
            case 'TIME'
                units = timeUnits;
            case 'VELOCITY'
                units = [ spaceUnits '/' timeUnits];
            case 'RATE'
                units = [ '/' timeUnits];
            case 'STRING'
                units = '';
            otherwise
                units = 'no unit';
        end
    end
end
function [ spotTable, spotIDMap ] = trackmateSpots(filePath, featureList)
%%TRACKMATESPOTS Import spots from a TrackMate data file.
%
%   S = TRACKMATESPOTS(file_path) imports the spots contained in the
%   TrackMate XML file file_path as a MATLAB table. TRACKMATESPOTS only
%   imports visible spots.
% 
%   S = TRACKMATESPOTS(file_path, feature_list) where feature_list is a
%   cell array of string only imports the spot features whose names are in
%   the cell array.
%
%   [ S, idMap ] = TRACKMATESPOTS( ... ) also returns idMap, a Map from
%   spot ID to row number in the table. idMap is such that idMap(10) the
%   row at which the spot with ID 10 is listed.
%
% INPUT:
%
%   file_path must be a path to a TrackMate file, containing the whole
%   TrackMate data, and not the simplified XML file that contains only
%   linear tracks. Such simplified tracks are imported using the
%   importTrackMateTracks function.
%
%   A TrackMate file is a XML file that starts with the following header:
%   <?xml version="1.0" encoding="UTF-8"?>
%       <TrackMate version="3.3.0">
%       ...    
%   and has a Model element in it:
%         <Model spatialunits="pixel" timeunits="sec">
%
% OUTPUT:
%
%   The output is a MATLAB table with at least two columns, ID (the spot
%   ID) and name (the spot name). Extra features listed in the specified
%   feature_list input appear as supplemental column.
%
% EXAMPLES:
%
%   >> [ spotTable, spotIDMap ] = trackmateSpots(file_path, {'POSITION_X', ...
%       'POSITION_Y', 'POSITION_Z' } );
%   >> spotTable(20:25, :)
% 
%   ans = 
%     ID      name       POSITION_X    POSITION_Y    POSITION_Z
%     __    _________    __________    __________    __________
% 
%     18    '18 (18)'    309.04        937.77        713.72    
%     21    '21 (21)'    210.25        1023.7        955.36    
%     20    '20 (20)'    302.03        1271.2        1247.9    
%     23    '23 (23)'    1577.6        888.73        547.66    
%     22    '22 (22)'    253.45        1186.9        1179.4    
%     25    '25 (25)'    947.44        1565.2        1297.1 
%
%   >> r = spotIDMap(20)
%
%   r =
%       22
%
%   >> spotTable(22, :)
%
%   ans = 
%        ID      name       POSITION_X    POSITION_Y    POSITION_Z
%        __    _________    __________    __________    __________
% 
%        20    '20 (20)'    302.03        1271.2        1247.9    
%
%   >> x = spotTable.POSITION_X;
%   >> y = spotTable.POSITION_Y;
%   >> z = spotTable.POSITION_Z;
%   >> plot3(x, y, z, 'k.')
%   >> axis equal


% __
% Jean-Yves Tinevez - 2016

    %% Import the XPath classes.
    import javax.xml.xpath.*
    
    %% Constants definition.

    TRACKMATE_ELEMENT           = 'TrackMate';
    SPOT_ID_ATTRIBUTE           = 'ID';
    SPOT_NAME_ATTRIBUTE         = 'name';

    %% Open file.

    try
        xmlDoc = xmlread(filePath);
    catch
        error('Failed to read XML file %s.',filePath);
    end
    xmlRoot = xmlDoc.getFirstChild();

    if ~strcmp(xmlRoot.getTagName, TRACKMATE_ELEMENT)
        error('MATLAB:trackMateGraph:BadXMLFile', ...
            'File does not seem to be a proper TrackMate file.')
    end
    
    
    %% XPath to retrieve spot nodes.
    
    % Use XPath to retrieve all visible spots.
    factory = XPathFactory.newInstance;
    xPath = factory.newXPath;
    xPathFilter = xPath.compile('//Model/AllSpots/SpotsInFrame/Spot[@VISIBILITY=1]');
    nodeList = xPathFilter.evaluate(xmlDoc, XPathConstants.NODESET);
    
    %% Retrieve spot feature list.
    
    if nargin < 2 || isempty( featureList )
        featureList = getSpotFeatureList(nodeList.item(0));
    end
    
    % Remove ID and name, because we will get them anyway.
    featureList = setdiff( featureList, SPOT_ID_ATTRIBUTE );
    featureList = setdiff( featureList, SPOT_NAME_ATTRIBUTE );
    n_features = numel( featureList );
    
    %% Get filtered spot IDs.

    % Prepare holders.
    nSpots      = nodeList.getLength();
    ID          = NaN( nSpots, 1 );
    name        = cell( nSpots, 1);
    features    = NaN( nSpots, n_features );

    % Read all spot nodes.
    for i = 1 : nSpots
        node = nodeList.item( i-1 );
        ID( i )     = str2double( node.getAttribute( SPOT_ID_ATTRIBUTE ) );
        name{ i }   = char( node.getAttribute( SPOT_NAME_ATTRIBUTE ) );
        for j = 1 : n_features
           features( i, j ) = str2double( node.getAttribute( featureList{ j } ) ); 
        end
    end
    
    % Create table.
    spotTable = table();
    spotTable.( SPOT_ID_ATTRIBUTE )     = ID;
    spotTable.( SPOT_NAME_ATTRIBUTE )   = name;
    for j = 1 : n_features
       spotTable.( featureList{ j } )   = features( :, j ); 
    end
    
    % Set table metadata.
    spotTable.Properties.DimensionNames = { 'Spot', 'Feature' };
    
    vNames = spotTable.Properties.VariableNames;
    nVNames = numel( vNames );
    vDescriptions   = cell( nVNames, 1);
    vUnits          = cell( nVNames, 1);
    
    fs = trackmateFeatureDeclarations( filePath );
    for k = 1 : nVNames
        vn = vNames{ k };
        if strcmp( SPOT_ID_ATTRIBUTE, vn )
            vDescriptions{ k }  = 'Spot ID';
            vUnits{ k }         = '';
        elseif strcmp( SPOT_NAME_ATTRIBUTE, vn )
            vDescriptions{ k }  = 'Spot name';
            vUnits{ k }         = '';
        else
            vDescriptions{ k }  = fs( vn ).name;
            vUnits{ k }         = fs( vn ).units;
        end
    end
    spotTable.Properties.VariableDescriptions   = vDescriptions;
    spotTable.Properties.VariableUnits          = vUnits;
    
    % Generate map ID -> table row number.
    spotIDMap = containers.Map( ID, 1 : nSpots, ...
        'UniformValues', true);
    
    %% Subfunction.
    
    function featureList = getSpotFeatureList(node)
        
        attribute_map = node.getAttributes;
        nAttributes = attribute_map.getLength;
        
        featureList = cell(nAttributes - 1, 1); % -1 for the spot name, which we do not take
        index = 1;
        for ii = 1 : nAttributes
            
            namel = node.getAttributes.item(ii-1).getName;
            if strcmp(namel, SPOT_NAME_ATTRIBUTE)
                continue;
            end
            featureList{index} = char(namel);
            index = index + 1;
            
        end
    end
    
end
function G = trackmateGraph(filePath, spotFeatureList, edgeFeatureList, verbose)
%%TRACKMATEGRAPH Import a TrackMate data file as a MATLAB directed graph.
%
%   G = TRACKMATEGRAPH(file_path) imports the TrackMate data stored in the
%   file file_path and returns it as a MATLAB directed graph.
%
%   G = TRACKMATEGRAPH(file_path, spot_feature_list, edge_feature_list)
%   where spot_feature_list and edge_feature_list are two cell arrays of
%   string only imports the spot and edge features whose names are in the
%   cell arrays. If the cell arrays are empty, all available features are
%   imported.
%
%   G = TRACKMATEGRAPH(file_path, sfl, efl, true) generates output in the
%   command window that log the current import progress.
%
% INPUT:
%
%   file_path must be a path to a TrackMate file, containing the whole
%   TrackMate data, and not the simplified XML file that contains only
%   linear tracks. Such simplified tracks are imported using the
%   importTrackMateTracks function.
%
%   A TrackMate file is a XML file that starts with the following header:
%   <?xml version="1.0" encoding="UTF-8"?>
%       <TrackMate version="3.3.0">
%       ...    
%   and has a Model element in it:
%         <Model spatialunits="pixel" timeunits="sec">
%
% OUTPUT:
%
%   The ouput G is a MATLAB directed graph, which allows for the
%   representation of tracks with possible split and merge events. The full
%   capability of MATLAB graph is listed in the digraph class
%   documentation.
%
%   G.Edges and G.Nodes are two MATLAB tables that list the spot and edges
%   feature values. The G.Edges.EndNodes N x 2 matrix lists the source and
%   target nodes row number in the G.Nodes table.
%
% EXAMPLE:
%
%   >> G = trackmateGraph(file_path, [], [], true);
%   >> x = G.Nodes.POSITION_X;
%   >> y = G.Nodes.POSITION_Y;
%   >> z = G.Nodes.POSITION_Z;
%   >> % MATLAB cannot plot graphs in 3D, so we ship gplot23D.
%   >> gplot23D( adjacency(G), [ x y z ], 'k.-' )
%   >> axis equal

% __
% Jean-Yves Tinevez - 2016


    %% Constants definition.
    
    SPOT_SOURCE_ID_ATTRIBUTE    = 'SPOT_SOURCE_ID';
    SPOT_TARGET_ID_ATTRIBUTE    = 'SPOT_TARGET_ID';

    %% Deal with inputs.
    
    if nargin < 4
        verbose = true;
        if nargin < 3
            edgeFeatureList = [];
            if nargin < 2
                spotFeatureList = [];
            end
        end
    end

    %% Import spot table.
    
    if verbose
        fprintf('Importing spot table. ')
        tic
    end
    
    [ spotTable, spotIDMap ] = trackmateSpots(filePath, spotFeatureList);
    
    if verbose
        fprintf('Done in %.1f s.\n', toc)
    end

    
    %% Import edge table.
    
    if verbose
        fprintf('Importing edge table. ')
        tic
    end
    
    trackMap = trackmateEdges(filePath, edgeFeatureList);
    
    if verbose
        fprintf('Done in %.1f s.\n', toc)
    end
    
    tmp = trackMap.values;
    edgeTable = vertcat( tmp{:} );
    
    %% Build graph.
    
    
    if verbose
        fprintf('Building graph. ')
        tic
    end
    
    sourceID = edgeTable.( SPOT_SOURCE_ID_ATTRIBUTE );
    targetID = edgeTable.( SPOT_TARGET_ID_ATTRIBUTE );
    
    s = cell2mat( values( spotIDMap, num2cell(sourceID) ) );
    t = cell2mat( values( spotIDMap, num2cell(targetID) ) );
    
    EndNodes = [ s t ];
    nodeTable = table( EndNodes );
    nt = horzcat( nodeTable, edgeTable );
    
    G = digraph( nt, spotTable );
    
    if verbose
        fprintf('Done in %.1f s.\n', toc)
    end
    

end
