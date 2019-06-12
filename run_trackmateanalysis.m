 path_to_folder = 'D:\shmidt\Dropbox\Arbeit\MPIIB\trackmate_data\ERK16mer'
 protein_track1 ='20180718_02_cell1_grb2'
 ligand_track ='20180718_02_cell1_erk'
 
 reference_trackmatefile = [path_to_folder '\' ligand_track '.xml']
 listtrackmatefile =  {[path_to_folder '\' protein_track1 '.xml']}
 trackmateTrackAnalysis(reference_trackmatefile, listtrackmatefile, '20180718_02_cell1_grb2', {'GRB2', 'ERK'}, 0.2, 3, 2, 70)
