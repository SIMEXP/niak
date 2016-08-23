function buildFilesIn (evt) {
  switch(evt.params.data.id) {
    case "1":
      var filesIn = {
		  "anat": "\/home\/pbellec\/demo_niak\/anat_X0010001.mnc.gz",
		  "fmri": {
		    "session1": {
			   "motor": "\/home\/pbellec\/demo_niak\/func_rest_X0010001.mnc.gz",
				"rest": "\/home\/pbellec\/demo_niak\/func_rest_X0010001.mnc.gz"
		    }
		  }
      };
      break;
    case "2":
      var filesIn = {
		  "anat": "\/home\/pbellec\/demo_niak\/anat_X0010001.mnc.gz",
		  "fmri": {
		    "session1": {
			   "motor": "\/home\/pbellec\/demo_niak\/func_motor_X0010001.mnc.gz",
				"rest": "\/home\/pbellec\/demo_niak\/func_rest_X0010001.mnc.gz"
			 }
		  }
	   };
	   break;
  };
  return filesIn 
}

var opt = {
	"folder_out": "\/home\/pbellec\/demo_niak\/fmri_preprocess\/",
	"size_output": "quality_control",
	"slice_timing": {
		"type_acquisition": "interleaved ascending",
		"type_scanner": "Bruker",
		"delay_in_tr": 0,
		"suppress_vol": 0,
		"flag_nu_correct": 1,
		"arg_nu_correct": "-distance 200",
		"flag_center": 0,
		"flag_skip": 0
	},
	"motion": {
		"session_ref": "session1"
	},
	"resample_vol": {
		"interpolation": "trilinear",
		"voxel_size": [3,3,3]
	},
	"t1_preprocess": {
		"nu_correct": {
			"arg": "-distance 75"
		}
	},
	"time_filter": {
		"hp": 0.01,
		"lp": "_Inf_"
	},
	"regress_confounds": {
		"flag_wm": 1,
		"flag_vent": 1,
		"flag_motion_params": 1,
		"flag_gsc": 0,
		"flag_scrubbing": 1,
		"thre_fd": 0.5
	},
	"corsica": {
		"sica": {
			"nb_comp": 60
		},
		"threshold": 0.15,
		"flag_skip": 1
	},
	"smooth_vol": {
		"fwhm": 6,
		"flag_skip": 0
	},
	"tune": [
		{
			"subject": "subject1",
			"param": {
				"slice_timing": {
					"flag_center": 1
				}
			}
		},
		{
			"subject": "subject2",
			"param": {
				"slice_timing": {
					"flag_center": 0
				}
			}
		}
	]
}
