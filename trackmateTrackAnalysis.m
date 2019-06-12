function done = trackmateAnalysis(ref_trackmatefile, listtrackmatefile, output_dir, channel, maximum_distance, minimum_association_time, minimum_dwell_time, nbins) 
   % try
        format long

        %Minimum dwell time must be at least 2
        if minimum_dwell_time < 2
            minimum_dwell_time = 2;
        end
        %Shut down warnings (excel sheet, dir)
        warning('off')
        
        %% extract and format reference tracks
        
        image_calibration = trackmateImageCalibration(ref_trackmatefile)
        %initialize channel_mapping_table
        channel_mapping_table = table(1, channel(1), {output_dir}, image_calibration.t.value, image_calibration.x.value, image_calibration.y.value,'VariableNames', {'CHANNEL_NUMBER', 'CHANNEL', 'OUTPUT_DIR', 'TIME_INTERVAL', 'X_CALIBATRION', 'Y_CALIBRATION'});
        %extract and reformat tracks and spots from reference track
        disp('Extracting reference Tracks')
        [ref_path, ~] = fileparts(ref_trackmatefile);
        ref_track_map = trackmateEdges(ref_trackmatefile);
        [ref_spot_table, ~] = trackmateSpots(ref_trackmatefile);
        for ref_track_key = ref_track_map.keys
            if height(ref_track_map(ref_track_key{1}))>= minimum_dwell_time
                new_ref_track_table = addvars(ref_track_map(ref_track_key{1}), ones(height(ref_track_map(ref_track_key{1})), 1), repmat(strcat(channel(1),'_',ref_track_key), height(ref_track_map(ref_track_key{1})), 1),'Before', 'SPOT_SOURCE_ID', 'NewVariableNames',{'CHANNEL_NUMBER', 'TRACK_KEY'});
                new_ref_track_ids_table = table(ones(height(ref_track_map(ref_track_key{1}))+1, 1), repmat(strcat(channel(1),'_',ref_track_key), height(ref_track_map(ref_track_key{1}))+1, 1), unique(union(ref_track_map(ref_track_key{1}).SPOT_SOURCE_ID, ref_track_map(ref_track_key{1}).SPOT_TARGET_ID)),'VariableNames', {'CHANNEL_NUMBER', 'TRACK_KEY', 'ID'});
                if exist('ref_track_table', 'var')
                    ref_track_table = union(ref_track_table, new_ref_track_table);
                    ref_track_ids_table = union(ref_track_ids_table, new_ref_track_ids_table);
                else
                    ref_track_table = new_ref_track_table;
                    ref_track_ids_table = new_ref_track_ids_table;
                end
            end
        end   
        ref_track_spots_table = join(ref_track_ids_table,ref_spot_table);
        %temp 
        ref_spot_table = addvars(ref_spot_table, ones(height(ref_spot_table),1), 'NewVariableNames',{'CHANNEL_NUMBER'});
        all_spots = ref_spot_table;
        
        %% configure paths and make folders
        %results will be saved in the folder near reference track
        full_path_output_dir =[ref_path '\' output_dir];
        full_path_output_dir_analysis =[ref_path '\' output_dir '\Analysis'];
        full_path_output_dir_analysis_hl =[full_path_output_dir_analysis '\Halflife'];
        full_path_output_dir_plots_2D = [ref_path '\' output_dir '\Plots_2D'];
        full_path_output_dir_plots_3D = [ref_path '\' output_dir '\Plots_3D'];
        full_path_output_dir_plots_link_cost = [ref_path '\' output_dir '\Plots_link_cost'];
        mkdir(full_path_output_dir);
        delete([full_path_output_dir '\*.*']);
        mkdir(full_path_output_dir_analysis_hl);
        delete([full_path_output_dir_analysis_hl '\*.*']);
        mkdir(full_path_output_dir_analysis);
        delete([full_path_output_dir_analysis '\*.*']);
        mkdir(full_path_output_dir_plots_2D);
        delete([full_path_output_dir_plots_2D '\*.*']);
        mkdir(full_path_output_dir_plots_3D);
        delete([full_path_output_dir_plots_3D '\*.*']);
        mkdir(full_path_output_dir_plots_link_cost);
        delete([full_path_output_dir_plots_link_cost '\*.*']);
        
        %logging routine
        logfile = fopen([full_path_output_dir '\' 'log.txt'],'w');
        fprintf(logfile,'%s\r\n','trackmateTracksAnalysis....');
        fprintf(logfile,'%s\r\n',['minimum_dwell_time =' num2str(minimum_dwell_time)]);
        fprintf(logfile,'%s\r\n',['maximum_distance =' num2str(maximum_distance)]);
        fprintf(logfile,'%s\r\n',['minimum_association_time =' num2str(minimum_association_time)]);
        fprintf(logfile,'%s\r\n',['nbins =' num2str(nbins)]);
        fprintf(logfile,'%s\r\n',['output_dir =' output_dir]);
        trackmateLog(logfile, ref_trackmatefile)
        for trackmatefile = listtrackmatefile
             trackmateLog(logfile, trackmatefile{1})
        end
        fprintf(logfile,'%s\r\n','-------------------------------------------');
        fprintf(logfile,'%s\r\n',['t calibration =' num2str(image_calibration.t.value)]);
        fprintf(logfile,'%s\r\n',['x calibration =' num2str(image_calibration.x.value)]);
        fprintf(logfile,'%s\r\n',['y calibration =' num2str(image_calibration.y.value)]);
        
        fclose(logfile);
        %% extract and format other tracks
        %extract the tracks from other channels
        disp('Extracting other Tracks')
        channel_number = 2;
        for trackmatefile = listtrackmatefile
            clear track_ids_table
            image_calibration = trackmateImageCalibration(trackmatefile{1});
            channel_mapping_table = [channel_mapping_table; {channel_number, channel(channel_number), {output_dir}, image_calibration.t.value, image_calibration.x.value, image_calibration.y.value}];
            track_map = trackmateEdges(trackmatefile{1});
            [spot_table, ~] = trackmateSpots(trackmatefile{1});
            for track_key = track_map.keys  
                if height(track_map(track_key{1}))>= minimum_dwell_time
                    new_track_table = addvars(track_map(track_key{1}), repmat(channel_number, height(track_map(track_key{1})), 1) , repmat(strcat(channel(channel_number), '_', track_key), height(track_map(track_key{1})), 1),'Before', 'SPOT_SOURCE_ID', 'NewVariableNames',{'CHANNEL_NUMBER', 'TRACK_KEY'});
                    new_track_ids_table = table(repmat(channel_number, height(track_map(track_key{1}))+1, 1), repmat(strcat(channel(channel_number), '_', track_key), height(track_map(track_key{1}))+1, 1), unique(union(track_map(track_key{1}).SPOT_SOURCE_ID, track_map(track_key{1}).SPOT_TARGET_ID)),'VariableNames', {'CHANNEL_NUMBER', 'TRACK_KEY', 'ID'});
                    if exist('track_table', 'var')
                        track_table = union(track_table, new_track_table);
                        if exist('track_ids_table', 'var')
                            track_ids_table = union(track_ids_table, new_track_ids_table);
                        else
                            track_ids_table = new_track_ids_table;
                        end
                    else
                        track_table = new_track_table;
                        track_ids_table = new_track_ids_table;
                    end
                end
            end
            if exist('track_spots_table', 'var')
                track_spots_table = [track_spots_table; join(track_ids_table, spot_table)];
            else
                track_spots_table = join(track_ids_table, spot_table);
            end
            channel_number = channel_number + 1;
            spot_table = addvars(spot_table, repmat(channel_number-1, height(spot_table), 1), 'NewVariableNames',{'CHANNEL_NUMBER'});
            
            all_spots = [all_spots;spot_table];
        end 
        
        %% find colocalized tracks
        %maximum_distance powered by 2
        maximum_distance = maximum_distance^2;

        %find related tracks
        disp('finding related tracks')
        track_analysis_table = innerjoin(ref_track_spots_table, track_spots_table, 'Keys', 'FRAME');
        %count distance for each frame
        track_analysis_table = addvars(track_analysis_table, (track_analysis_table.POSITION_X_ref_track_spots_table - track_analysis_table.POSITION_X_track_spots_table).^2 + (track_analysis_table.POSITION_Y_ref_track_spots_table - track_analysis_table.POSITION_Y_track_spots_table).^2, 'NewVariableNames' , 'DISTANCE');
        % apply distance filter 
        headers = {'TRACK_KEY_ref_track_spots_table','FRAME', 'CHANNEL_NUMBER_track_spots_table', 'TRACK_KEY_track_spots_table', 'DISTANCE'};
        track_analysis_distance_table = track_analysis_table(track_analysis_table.DISTANCE <= maximum_distance, headers);
        % apply minimum_association_time filter
        headers = {'TRACK_KEY_ref_track_spots_table','CHANNEL_NUMBER_track_spots_table','TRACK_KEY_track_spots_table'};
        dist_assoc_time_analysis_table = grpstats(track_analysis_distance_table, {'TRACK_KEY_ref_track_spots_table','CHANNEL_NUMBER_track_spots_table','TRACK_KEY_track_spots_table'});
        dist_assoc_time_analysis_table_filtered = dist_assoc_time_analysis_table(dist_assoc_time_analysis_table.GroupCount>=minimum_association_time, headers);

        statistics = fopen([full_path_output_dir '\' 'statistics.txt'],'w');
        fprintf(statistics,'%s\r\n','statistics....');
        
        %% plot colocalization
        %plot all tracks 2D
        for ref_track_key = transpose(unique(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table))
            ref_plot_table = ref_track_spots_table(ismember(ref_track_spots_table.TRACK_KEY, ref_track_key),:);
            ref_plot_table = sortrows(ref_plot_table,'FRAME');
            plot_table = track_spots_table(ismember(track_spots_table.TRACK_KEY, transpose(unique(dist_assoc_time_analysis_table_filtered(ismember(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table, ref_track_key),:).TRACK_KEY_track_spots_table))),:);   
            plot_table = sortrows(plot_table,'FRAME');
            to_plot = gramm('x',[ref_plot_table.POSITION_X; plot_table.POSITION_X], 'y', [ref_plot_table.POSITION_Y; plot_table.POSITION_Y], 'color', [ref_plot_table.TRACK_KEY; plot_table.TRACK_KEY], 'label', [ref_plot_table.FRAME; plot_table.FRAME]);
            to_plot.geom_line();
            to_plot.geom_label('color', 'k', 'FontSize', 2)
            to_plot.set_order_options('color', 0);
            to_plot.set_title('Visualization of related tracks');
            to_plot.set_names('x', 'Position X (Micrometers)', 'y', 'Position Y (Micrometers)', 'color', 'Tracks');
            to_plot.draw();
            to_plot.export('file_name', ref_track_key{1},'export_path',full_path_output_dir_plots_2D, 'file_type','png');
            close all;
        end

        %plot all tracks 3D
        for ref_track_key = transpose(unique(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table))
            figure()
            ref_plot_table = ref_track_spots_table(ismember(ref_track_spots_table.TRACK_KEY, ref_track_key),:);
            ref_plot_table = sortrows(ref_plot_table,'FRAME');
            plot_table = track_spots_table(ismember(track_spots_table.TRACK_KEY, transpose(unique(dist_assoc_time_analysis_table_filtered(ismember(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table, ref_track_key),:).TRACK_KEY_track_spots_table))),:);   
            plot_table = sortrows(plot_table,'FRAME');
            to_save_x =[ref_plot_table.POSITION_X; plot_table.POSITION_X]
            to_save_frame = [ref_plot_table.FRAME; plot_table.FRAME]
            to_save_y = [ref_plot_table.POSITION_Y; plot_table.POSITION_Y]
            to_save_TRACK_KEY = [ref_plot_table.TRACK_KEY; plot_table.TRACK_KEY]
            to_plot = gramm('x',[ref_plot_table.POSITION_X; plot_table.POSITION_X],'y', [ref_plot_table.FRAME; plot_table.FRAME], 'z', [ref_plot_table.POSITION_Y; plot_table.POSITION_Y], 'color', [ref_plot_table.TRACK_KEY; plot_table.TRACK_KEY]);
            to_plot.geom_line();
            to_plot.geom_label('color', 'k', 'FontSize', 2);
            to_plot.set_line_options('base_size', 2)
            to_plot.set_order_options('color', 0);
            to_plot.set_layout_options('legend', false, 'redraw', false);
            %to_plot.axe_property('Box', 'on','BoxStyle', 'full', 'DataAspectRatio', [1 20 1], 'view', [75 -25]);
            to_plot.set_names('x', 'Position X', 'y', 'Frame','z', 'Position Y', 'color', 'Tracks');
            to_plot.draw();
            %to_plot.export('file_name', ref_track_key{1},'export_path',full_path_output_dir_plots_3D, 'file_type','svg');
            savefig([full_path_output_dir_plots_3D '\' ref_track_key{1} '.fig'])
            close all;
        end

        %plot link cost
        for ref_track_key = transpose(unique(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table))
            ref_plot_table = innerjoin(ref_track_spots_table(ismember(ref_track_spots_table.TRACK_KEY, ref_track_key),:), ref_track_table, 'LeftKeys', {'ID', 'TRACK_KEY'}, 'RightKeys', {'SPOT_SOURCE_ID', 'TRACK_KEY'});
            ref_plot_table = sortrows(ref_plot_table,'FRAME');
            plot_table = innerjoin(track_spots_table(ismember(track_spots_table.TRACK_KEY, transpose(unique(dist_assoc_time_analysis_table_filtered(ismember(dist_assoc_time_analysis_table_filtered.TRACK_KEY_ref_track_spots_table, ref_track_key),:).TRACK_KEY_track_spots_table))),:), track_table, 'LeftKeys', {'ID', 'TRACK_KEY'}, 'RightKeys', {'SPOT_SOURCE_ID', 'TRACK_KEY'});
            plot_table = sortrows(plot_table,'FRAME');
            figure('Position',[100 100 800 400]);
            to_plot = gramm('x',[ref_plot_table.FRAME; plot_table.FRAME], 'y', [ref_plot_table.LINK_COST; plot_table.LINK_COST], 'color', [ref_plot_table.TRACK_KEY; plot_table.TRACK_KEY]);
            %plot.geom_point();
            to_plot.geom_line();
            to_plot.geom_label('color', 'k', 'FontSize', 2);
            to_plot.set_order_options('color', 0);
            to_plot.set_title('link cost of related tracks');
            to_plot.set_names('x', 'Frame', 'y', 'link cost', 'color', 'Tracks');
            to_plot.draw();

            to_plot.export('file_name', ref_track_key{1},'export_path',full_path_output_dir_plots_link_cost, 'file_type','png');
            close all;
        end
        %% plot analysis 
        %plot distribution time association
        dist_assoc_time_analysis_table = grpstats(track_analysis_distance_table, {'TRACK_KEY_ref_track_spots_table','CHANNEL_NUMBER_track_spots_table','TRACK_KEY_track_spots_table'});
        assoc_time_distr_table = grpstats(table(dist_assoc_time_analysis_table.GroupCount, dist_assoc_time_analysis_table.CHANNEL_NUMBER_track_spots_table,'VariableNames', {'ASSOCIATION_TIME', 'CHANNEL_NUMBER'}),{'CHANNEL_NUMBER','ASSOCIATION_TIME'});
        assoc_time_distr_table = join(assoc_time_distr_table,  channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        assoc_time_distr_table = sortrows(assoc_time_distr_table,'ASSOCIATION_TIME');
        plot_assoc_time = gramm('x', assoc_time_distr_table.ASSOCIATION_TIME, 'y', assoc_time_distr_table.GroupCount, 'color',assoc_time_distr_table.CHANNEL);
        plot_assoc_time.geom_point();
        plot_assoc_time.set_title(['Distribution of time association for related tracks to' channel(1)]);
        plot_assoc_time.set_names('x', 'Association Time (Frames)', 'y', 'Quantity (related Tracks)', 'Color', 'Channel');
        plot_assoc_time.draw();
        plot_assoc_time.export('file_name', 'Distribution_time_association','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        fprintf(statistics,'%s\r\n',['mean_association_time =' num2str(mean(assoc_time_distr_table.ASSOCIATION_TIME))]);

        %plot Spot concentration over Frames
        all_spots_stats = groupsummary(all_spots,  {'CHANNEL_NUMBER', 'FRAME'});
        all_spots_stats = join(all_spots_stats, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        all_spots_stats = sortrows(all_spots_stats,'FRAME');
        spot_concentration_plot = gramm('x',all_spots_stats.FRAME, 'y', all_spots_stats.GroupCount);
        spot_concentration_plot.facet_grid(all_spots_stats.CHANNEL,[]);
        spot_concentration_plot.geom_point();
        spot_concentration_plot.set_title('Spot concentration for different channels');
        spot_concentration_plot.set_names('x', 'Time (Frame)', 'y', 'Quantity (Spots)', 'Row', 'CHN.');
        spot_concentration_plot.draw();
        spot_concentration_plot.export('file_name', 'Spots_concentration','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot Spot concentration of tracks over Frames
        track_spots_table_combined = table([ref_track_spots_table.CHANNEL_NUMBER; track_spots_table.CHANNEL_NUMBER], [ref_track_spots_table.FRAME; track_spots_table.FRAME], 'VariableNames', {'CHANNEL_NUMBER', 'FRAME'});
        track_spots_table_combined_stats = groupsummary(track_spots_table_combined,  {'CHANNEL_NUMBER', 'FRAME'});
        track_spots_table_combined_stats = join(track_spots_table_combined_stats, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        track_spots_table_combined_stats = sortrows(track_spots_table_combined_stats,'FRAME');
        spot_concentration_plot = gramm('x',track_spots_table_combined_stats.FRAME, 'y', track_spots_table_combined_stats.GroupCount);
        spot_concentration_plot.facet_grid(track_spots_table_combined_stats.CHANNEL,[]);
        spot_concentration_plot.geom_point();
        spot_concentration_plot.set_title('Spot tracks concentration for different channels');
        spot_concentration_plot.set_names('x', 'Time (Frame)', 'y', 'Quantity (Spots)', 'Row', 'CHN.');
        spot_concentration_plot.draw();
        spot_concentration_plot.export('file_name', 'Spots_tracks_concentration','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot tracks Spot concentration over Location
        ref_track_spots_table_combined_stats = join(ref_track_spots_table, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        track_spots_table_combined_stats = join(track_spots_table, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        spot_location_plot = gramm('x',[ref_track_spots_table_combined_stats.POSITION_X; track_spots_table_combined_stats.POSITION_X], 'y', [ref_track_spots_table_combined_stats.POSITION_Y;track_spots_table_combined_stats.POSITION_Y]);
        spot_location_plot.facet_grid([],[ref_track_spots_table_combined_stats.CHANNEL; track_spots_table_combined_stats.CHANNEL]);
        spot_location_plot.stat_bin2d('nbins',[nbins nbins],'geom','image');
        spot_location_plot.set_title('Spot tracks location for different channels');
        spot_location_plot.set_names('column','Channel','color','Spots');
        spot_location_plot.draw();
        spot_location_plot.export('file_name', 'Spots_location_tracks','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot Spot concentration over Location
        all_spots_stats = join(all_spots, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        spot_location_plot = gramm('x',all_spots_stats.POSITION_X, 'y', all_spots_stats.POSITION_Y);
        spot_location_plot.facet_grid([],all_spots_stats.CHANNEL);
        spot_location_plot.stat_bin2d('nbins',[nbins nbins],'geom','image');
        spot_location_plot.set_title('Spot location for different channels');
        spot_location_plot.set_names('column','Channel','color','Spots');
        spot_location_plot.draw();
        spot_location_plot.export('file_name', 'Spots_location','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot dwelltime of related and not related tracks
        not_related = track_spots_table(~ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'Not Related Tracks'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        not_related_table_stats = groupsummary(not_related_table,  {'STATUS','CHANNEL_NUMBER', 'TRACK_KEY'});
        not_related_count_stats = groupsummary (not_related_table_stats, {'STATUS','CHANNEL_NUMBER', 'GroupCount'});
        related = track_spots_table(ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'Related Tracks'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        related_table_stats = groupsummary(related_table,  {'STATUS','CHANNEL_NUMBER', 'TRACK_KEY'});
        related_count_stats = groupsummary (related_table_stats, {'STATUS','CHANNEL_NUMBER', 'GroupCount'});
        to_plot_dwell_time = table([not_related_count_stats.GroupCount; related_count_stats.GroupCount], [not_related_count_stats.GroupCount_1; related_count_stats.GroupCount_1], [not_related_count_stats.STATUS; related_count_stats.STATUS], [not_related_count_stats.CHANNEL_NUMBER; related_count_stats.CHANNEL_NUMBER],'VariableNames', {'FRAMES', 'TRACKS', 'STATUS', 'CHANNEL_NUMBER'});
        to_plot_dwell_time = join(to_plot_dwell_time, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        dwell_time_plot_related_not_related = gramm('x',to_plot_dwell_time.FRAMES, 'y',to_plot_dwell_time.TRACKS, 'color', to_plot_dwell_time.STATUS);
        dwell_time_plot_related_not_related.facet_grid([],to_plot_dwell_time.CHANNEL);
        dwell_time_plot_related_not_related.geom_point();
        dwell_time_plot_related_not_related.set_title('Dwelltime of related and not related Tracks');
        dwell_time_plot_related_not_related.set_names('x', 'Dwelltime', 'y', 'Quantity(Tracks)', 'column', 'Channel', 'Color', 'Status');
        dwell_time_plot_related_not_related.draw();
        dwell_time_plot_related_not_related.export('file_name', 'Dwell_time_related_not_related','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        fprintf(statistics,'%s\r\n',['mean_dwelltime =' num2str(mean(to_plot_dwell_time.TRACKS))]);

        %boxplot total intensity of related and not related tracks
        not_related = track_spots_table(~ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'Not Related Tracks'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        related = track_spots_table(ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'Related Tracks'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        to_plot_total_intensity = table([not_related_table.TOTAL_INTENSITY; related_table.TOTAL_INTENSITY],[not_related_table.STATUS; related_table.STATUS], [not_related_table.CHANNEL_NUMBER; related_table.CHANNEL_NUMBER],'VariableNames', {'TOTAL_INTENSITY', 'STATUS', 'CHANNEL_NUMBER'});
        to_plot_total_intensity = join(to_plot_total_intensity, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        plot_total_intensity = gramm('x',to_plot_total_intensity.STATUS, 'y',to_plot_total_intensity.TOTAL_INTENSITY, 'Color', to_plot_total_intensity.CHANNEL);
        plot_total_intensity.stat_boxplot();
        plot_total_intensity.set_title('Total Intensity of related and not related Tracks');
        plot_total_intensity.set_names('x', 'Status', 'y', 'Total intensity', 'Color', 'Status');
        plot_total_intensity.draw();
        plot_total_intensity.export('file_name', 'Total_intensity_related_not_related','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %boxplot total displacement of related and not related tracks
        not_related = track_table(~ismember(track_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'Not Related Tracks'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        related = track_table(ismember(track_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'Related Tracks'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'STATUS');
        to_plot_displacement = table([not_related_table.DISPLACEMENT; related_table.DISPLACEMENT],[not_related_table.STATUS; related_table.STATUS], [not_related_table.CHANNEL_NUMBER; related_table.CHANNEL_NUMBER],'VariableNames', {'DISPLACEMENT', 'STATUS', 'CHANNEL_NUMBER'});
        to_plot_displacement = join(to_plot_displacement, channel_mapping_table, 'Keys', 'CHANNEL_NUMBER');
        plot_displacement = gramm('x',to_plot_displacement.STATUS, 'y',to_plot_displacement.DISPLACEMENT, 'Color', to_plot_displacement.CHANNEL);
        plot_displacement.stat_boxplot();
        plot_displacement.set_title('Displacement of related and not related Tracks');
        plot_displacement.set_names('x', 'Status', 'y', 'Displacement', 'Color', 'Status');
        plot_displacement.draw();
        plot_displacement.export('file_name', 'Displacement_related_not_related','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot SNR of all related tracks
        related = track_spots_table(ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related = sortrows(related,'FRAME');
        to_plot_total_intensity_related_individual = gramm('x',related.FRAME, 'y',related.SNR, 'Color', related.TRACK_KEY);
        to_plot_total_intensity_related_individual.geom_line();
        to_plot_total_intensity_related_individual.set_order_options('x', 1);
        to_plot_total_intensity_related_individual.set_title('SNR of related tracks over Frame');
        to_plot_total_intensity_related_individual.set_names('x', 'Time (Frame)', 'y', 'SNR', 'Color', 'Track');
        to_plot_total_intensity_related_individual.draw();
        to_plot_total_intensity_related_individual.export('file_name', 'SNR_related_tracks','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;
        
        %% plot analysis for reference channel
        %Extract reference Track Features
        ref_trackfeaturestable = trackmateTrackFeatures(ref_trackmatefile, channel(1), 1);

        %plot reference TrackFeatures Tracks vs. MAX_DISTANCE_TRAVELED
        plot_track_features_mdt = gramm('x',ref_trackfeaturestable.NUMBER_SPOTS, 'y',ref_trackfeaturestable.MAX_DISTANCE_TRAVELED);
        plot_track_features_mdt.geom_point();
        plot_track_features_mdt.set_title('Ref Tracks vs. MAX_DISTANCE_TRAVELED');
        plot_track_features_mdt.set_names('x', 'Number of Spots', 'y', 'Maximum Distance traveled');
        plot_track_features_mdt.draw();
        plot_track_features_mdt.export('file_name', 'REF_TRACKS_MAX_DISTANCE_TRAVELED','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot reference TrackFeatures Tracks vs. TOTAL_DISTANCE_TRAVELED
        plot_track_features_tdt = gramm('x',ref_trackfeaturestable.NUMBER_SPOTS, 'y',ref_trackfeaturestable.TOTAL_DISTANCE_TRAVELED);
        plot_track_features_tdt.geom_point();
        plot_track_features_tdt.set_title('Ref Tracks vs. TOTAL_DISTANCE_TRAVELED');
        plot_track_features_tdt.set_names('x', 'Number of Spots', 'y', 'Total Distance traveled');
        plot_track_features_tdt.draw();
        plot_track_features_tdt.export('file_name', 'REF_TRACKS_TOTAL_DISTANCE_TRAVELED','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot reference TrackFeatures Tracks vs.LINEARITY_OF_FORWARD_PROGRESSION
        plot_track_features_lfp = gramm('x',ref_trackfeaturestable.NUMBER_SPOTS, 'y',ref_trackfeaturestable.LINEARITY_OF_FORWARD_PROGRESSION);
        plot_track_features_lfp.geom_point();
        plot_track_features_lfp.set_title('Ref Tracks vs. Linearity of Forward progression');
        plot_track_features_lfp.set_names('x', 'Number of Spots', 'y', 'Linearity of Forward progression');
        plot_track_features_lfp.draw();
        plot_track_features_lfp.export('file_name', 'REF_TRACKS_LINEARITY_OF_FORWARD_PROGRESSION','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;

        %plot all tracks together colored by dwelltime
        ref_track_edge_spots_table=innerjoin(ref_track_spots_table, ref_trackfeaturestable, 'LeftKeys', 'TRACK_KEY', 'RightKeys', 'TRACK_KEY');
        to_plot= gramm('x', ref_track_edge_spots_table.POSITION_X, 'y', ref_track_edge_spots_table.POSITION_Y, 'color', ref_track_edge_spots_table.NUMBER_SPOTS, 'group', ref_track_edge_spots_table.TRACK_KEY);
        to_plot.geom_line();
        to_plot.set_title(strcat('All-',' ' , channel(1), '-tracks colored by dwelltime'));
        to_plot.set_names('x', 'Position X', 'y', 'Position Y', 'Color', 'Dwelltime');
        to_plot.draw();
        to_plot.export('file_name', 'Ref_tracks_dwelltime','export_path',full_path_output_dir_analysis, 'file_type','png');
        close all;
        
        %% plot analysis for other channles
        for trackmatefile = listtrackmatefile
            %Extract Track Features
            trackfeaturestable = trackmateTrackFeatures(trackmatefile{1}, channel(2), 2);

            %plot TrackFeatures Tracks vs. MAX_DISTANCE_TRAVELED
            plot_track_features_mdt = gramm('x',trackfeaturestable.NUMBER_SPOTS, 'y',trackfeaturestable.MAX_DISTANCE_TRAVELED);
            plot_track_features_mdt.geom_point();
            plot_track_features_mdt.set_title('Tracks vs. MAX_DISTANCE_TRAVELED');
            plot_track_features_mdt.set_names('x', 'Number of Spots', 'y', 'Maximum Distance traveled');
            plot_track_features_mdt.draw();
            plot_track_features_mdt.export('file_name', 'TRACKS_MAX_DISTANCE_TRAVELED','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;

            %plot TrackFeatures Tracks vs. TOTAL_DISTANCE_TRAVELED
            plot_track_features_tdt = gramm('x',trackfeaturestable.NUMBER_SPOTS, 'y',trackfeaturestable.TOTAL_DISTANCE_TRAVELED);
            plot_track_features_tdt.geom_point();
            plot_track_features_tdt.set_title('Tracks vs. TOTAL_DISTANCE_TRAVELED');
            plot_track_features_tdt.set_names('x', 'Number of Spots', 'y', 'Total Distance traveled');
            plot_track_features_tdt.draw();
            plot_track_features_tdt.export('file_name', 'TRACKS_TOTAL_DISTANCE_TRAVELED','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;

            %plot TrackFeatures Tracks vs.LINEARITY_OF_FORWARD_PROGRESSION
            plot_track_features_lfp = gramm('x',trackfeaturestable.NUMBER_SPOTS, 'y',trackfeaturestable.LINEARITY_OF_FORWARD_PROGRESSION);
            plot_track_features_lfp.geom_point();
            plot_track_features_lfp.set_title('Tracks vs. Linearity of Forward progression');
            plot_track_features_lfp.set_names('x', 'Number of Spots', 'y', 'Linearity of Forward progression');
            plot_track_features_lfp.draw();
            plot_track_features_lfp.export('file_name', 'TRACKS_LINEARITY_OF_FORWARD_PROGRESSION','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;

            %plot all trackstogether colored by dwelltime
            track_edge_spots_table=innerjoin(track_spots_table, trackfeaturestable, 'LeftKeys', 'TRACK_KEY', 'RightKeys', 'TRACK_KEY');
            to_plot= gramm('x', track_edge_spots_table.POSITION_X, 'y', track_edge_spots_table.POSITION_Y, 'color', track_edge_spots_table.NUMBER_SPOTS, 'group', track_edge_spots_table.TRACK_KEY);
            to_plot.geom_line();
            to_plot.set_title(strcat('All-' ,' ', channel(2), '-tracks colored by dwelltime'));
            to_plot.set_names('x', 'Position X', 'y', 'Position Y', 'Color', 'Dwelltime');
            to_plot.draw();
            to_plot.export('file_name', 'tracks_dwelltime','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;

            %plot max intensity over Frames
            to_plot_total_intensity = gramm('x',spot_table.FRAME, 'y',spot_table.MAX_INTENSITY);
            to_plot_total_intensity.geom_point();
            to_plot_total_intensity.set_title(['Max intensity vs. Frame' channel(2)]);
            to_plot_total_intensity.set_names('x', 'Time (Frame)', 'y', 'Max intensity');
            to_plot_total_intensity.draw();
            to_plot_total_intensity.export('file_name', 'max_intensity','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;

            %plot dwelltime other channel
            trackfeaturestabledwelltime = groupsummary (trackfeaturestable, {'NUMBER_SPOTS'});
            plotdwelltime = gramm('x', trackfeaturestabledwelltime.NUMBER_SPOTS, 'y', trackfeaturestabledwelltime.GroupCount)
            plotdwelltime.geom_point()
            plotdwelltime.set_title(['Total dwelltime ' channel(2)]);
            plotdwelltime.set_names('x', 'Dwelltime', 'y', 'Number of Tracks')
            plotdwelltime.draw()
            plotdwelltime.export('file_name', 'Totaldwelltime_other','export_path',full_path_output_dir_analysis, 'file_type','png');
            close all;
        end

        %% save in .xlsx
        writetable(dist_assoc_time_analysis_table_filtered, [full_path_output_dir '\' 'supporting_track_data.xlsx'],'Sheet','distance');
        
        not_related = track_table(~ismember(track_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'NO'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        related = track_table(ismember(track_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'YES'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        ref_track_table = addvars(ref_track_table, repmat({'REFERENCE'},height(ref_track_table), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        
        all_edges = [ref_track_table;not_related_table;related_table];
        writetable(all_edges, [full_path_output_dir '\' 'supporting_track_data.xlsx'],'Sheet','edges');
        
        not_related = track_spots_table(~ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'NO'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        related = track_spots_table(ismember(track_spots_table.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'YES'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        ref_track_spots_table = addvars(ref_track_spots_table, repmat({'REFERENCE'},height(ref_track_spots_table), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        
        all_track_spots = [ref_track_spots_table;not_related_table;related_table];
        writetable(all_track_spots, [full_path_output_dir '\' 'supporting_track_data.xlsx'],'Sheet','track_spots');
        
        writetable(all_spots, [full_path_output_dir '\' 'supporting_track_data.xlsx'],'Sheet','all_spots');
        
        
        not_related = trackfeaturestable(~ismember(trackfeaturestable.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        not_related_table = addvars(not_related, repmat({'NO'},height(not_related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        related = trackfeaturestable(ismember(trackfeaturestable.TRACK_KEY,dist_assoc_time_analysis_table_filtered.TRACK_KEY_track_spots_table),:);
        related_table = addvars(related, repmat({'YES'},height(related), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        ref_trackfeaturestable = addvars(ref_trackfeaturestable, repmat({'REFERENCE'},height(ref_trackfeaturestable), 1),'before', 'CHANNEL_NUMBER', 'NewVariableNames', 'COLOCALIZATION');
        
        all_tracks = [ref_trackfeaturestable;not_related_table;related_table];
        all_tracks = addvars(all_tracks, all_tracks.NUMBER_SPOTS*image_calibration.t.value,'After', 'NUMBER_SPOTS', 'NewVariableNames',{'TIME_CALIBRATED'});
        writetable(all_tracks, [full_path_output_dir '\' 'supporting_track_data.xlsx'],'Sheet','tracks');
        
        %% PLOT HALFLIFE
        try
            alltracks_col = all_tracks(ismember(all_tracks.COLOCALIZATION, 'YES'),:);
            alltracks_col_stats = groupsummary(alltracks_col,  {'COLOCALIZATION', 'NUMBER_SPOTS'});
            x_col = alltracks_col_stats.NUMBER_SPOTS
            y_col = alltracks_col_stats.GroupCount
            mdl = fittype('exp1')
            f_col = fit(x_col,y_col, mdl)
            mean_lifetime_col = 1 / -f_col.b
            halflife_col = log(2)/ -f_col.b
            plot(f_col,x_col,y_col)
            title('Exponetial fit for colocolized tracks')
            legend('off')
            saveas(gcf,[full_path_output_dir_analysis_hl '/exp_fit_colocalized'],'png');
            close all

            gg_hist_col = gramm('x', alltracks_col.NUMBER_SPOTS);
            gg_hist_col.stat_bin();
            gg_hist_col.set_title('Distribution of colocolized tracks');
            gg_hist_col.draw();
            gg_hist_col.export('file_name', 'Dwelltime_dist_col','export_path',full_path_output_dir_analysis_hl, 'file_type','png');
            close all;

            alltracks_ncol = all_tracks(ismember(all_tracks.COLOCALIZATION, 'NO'),:);
            gg_hist_ncol = gramm('x', alltracks_ncol.NUMBER_SPOTS);
            gg_hist_ncol.stat_bin();
            gg_hist_ncol.set_title('Distribution of not colocolized tracks');
            gg_hist_ncol.draw();
            gg_hist_ncol.export('file_name', 'Dwelltime_dist_notcol','export_path',full_path_output_dir_analysis_hl, 'file_type','png');
            close all;

            alltracks_ncol_stats = groupsummary(alltracks_ncol,  {'COLOCALIZATION', 'NUMBER_SPOTS'});
            x_ncol = alltracks_ncol_stats.NUMBER_SPOTS
            y_ncol = alltracks_ncol_stats.GroupCount
            f_ncol = fit(x_ncol,y_ncol, 'exp1')
            mean_lifetime_ncol = 1 / -f_ncol.b
            halflife_ncol = log(2)/ -f_ncol.b
            plot(f_ncol,x_ncol,y_ncol)
            title('Exponetial fit for not colocolized tracks')
            legend('off')
            saveas(gcf,[full_path_output_dir_analysis_hl '/exp_fit_notcolocalized'],'png');
            close all
   
            fprintf(statistics,'%s\r\n','-------------------------------------------');
            fprintf(statistics,'%s\r\n',['mean_lifetime_ncol =' num2str(mean_lifetime_ncol)]);
            fprintf(statistics,'%s\r\n',['halflife_ncol =' num2str(halflife_ncol)]);
            fprintf(statistics,'%s\r\n',['mean_lifetime_col =' num2str(mean_lifetime_col)]);
            fprintf(statistics,'%s\r\n',['halflife_col =' num2str(halflife_col)]);
        catch
            'no half life results'
        end  
        
        fclose(statistics);
        
        %% save Variables
        keep all_track_spots full_path_output_dir all_tracks all_edges all_spots dist_assoc_time_analysis_table_filtered;
        save([full_path_output_dir  '\' 'track_variables.mat'], 'all_track_spots', 'all_edges', 'all_spots', 'all_tracks','dist_assoc_time_analysis_table_filtered');
        
        done =true;
   % catch 
   %     done = false;
   % end
end