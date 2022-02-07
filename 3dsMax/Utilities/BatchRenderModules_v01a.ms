(
	fn format_date = (
		local sep = "-";
		local t = getlocaltime();
		(formattedprint t[1] format:"04d") \
		+ sep + (formattedprint t[2] format:"02d") \
		+ sep + (formattedprint t[4] format:"02d");
	)
	
	fn format_time = (
		local sep = "-";
		local t = getlocaltime();
		(formattedprint t[5] format:"02d")  \
		+ sep + (formattedprint t[6] format:"02d") \
		+ sep + (formattedprint t[7] format:"02d");
	)
	
	/* format variables */
	struct system_t (
		user = sysinfo.username,
		date = format_date(),
		time = format_time()
	);
	struct module_t (
		module_name, 
		module_root,
		module_filepath
	);
	struct view_t (
		view_id,
		view_name,
		view_camera = "viewport",
		view_width = renderwidth,
		view_height = renderheight,
		view_startFrame = animationrange.start,
		view_endFrame = animationrange.end,
		view_sceneStateName = maxfilename
	);
	
	/* utilities */
	struct util (
		
		fn last_not_digit str = ( local l = str.count; while(str[l] as integer != undefined) do l-=1; [l, str.count]; ),
		
		fn format_variables variables str = (
			for p in getpropnames variables do (
				v = getproperty variables p;
				if v == undefined do v = "";
				str = substitutestring str ("<"+p as string+">") (v as string);
			)
			str;
		),
		
		fn init_lv lv type = (
			lv.beginUpdate();
			for p in #(#(#fullrowselect, true), #(#gridlines, true), #(#multiselect, true), #(#checkboxes, false), 
				#(#hideselection, false), #(#isaccessible, true), #(#labeledit, false), #(#AllowColumnReorder,true)) do setproperty lv p[1] p[2];
			lv.columns.add "" 0; /* reserved for checkbox */ 
			for coll in (getpropnames type) do lv.columns.add coll coll ;
			lv.sorting = lv.sorting.ascending;
			lv.view = lv.view.details;
			local style = (dotnetclass "columnheaderautoresizestyle").headersize;
			for i = 1 to lv.columns.count do lv.autoresizecolumn (i-1) style;
			lv.endUpdate();
		),
		
		fn update_lv lv data = (
			lv.beginUpdate();
			lv.items.clear();
			lv.items.addrange (for entry in data collect (
				local item = dotnetobject "system.windows.forms.listviewitem" "";
				for p in getpropnames entry do item.subitems.add ((getproperty entry p) as string);
				item.tag = dotnetmxsvalue entry;
				item.checked = true;
				item;
			));
			lv.endUpdate();
		),
		
		fn add_files filepaths = (
			dlg = dotnetobject "system.windows.forms.openfiledialog"
			for p in dlgProps = #(#(#title, "add module"), #(#multiselect, true), #(#filter, "3dsmax (*.max)|*.max")) 
				do setproperty dlg p[1] p[2];
				
			result = dlg.showdialog();
			if result.equals result.ok do (
				for filename in dlg.filenames do (
					if finditem filepaths filename == 0 and ismaxfile filename do (
						append filepaths filename;
					)
				)
			)
			makeuniquearray filepaths;
		),
		
		fn as_modules filepaths = (
			local max_ver = (maxversion())[1];
			local modules = for filepath in filepaths collect (
				local file_ver = (getmaxfileversiondata filepath)[1];
				local filename = getfilenamefile filepath;
				local content = getmaxfileobjectnames filepath quiet:true;
				if file_ver > max_ver or finditem content filename == 0 then dontcollect;
				else module_t module_name:filename module_root:(getfilenamepath filepath) module_filepath:filepath ;
			)
			modules;
		),
		
		fn collect_views = (
			local views = #();
			local mgr = batchrendermgr;
			local hasp = hasproperty;
			local setp = setproperty;
			local getp = getproperty;
			local enump = getpropnames;
			local scls = superclassof;
			for i = 1 to mgr.numviews do (
				local vars = view_t view_id:i;
				bv = mgr.getview i;
				for p in #(#name,#width,#height,#startframe,#endframe,#scenestatename,#camera) 
					where hasp vars (ps = ("view_" + p as string) as name) do (
					local val = getp bv p;
					if p == #camera do if val != undefined then val = val.name else val = "viewport";
					setp vars ps val
				)
				append views vars;
			)
			views;
		),
		
		fn get_dependencies nodes = (
			local filepaths = #();
			local deps = #();
			atsops.refresh();
			
			for node in nodes do (
				for i = 1 to node.numsubs do
					append deps (getsubanim node i)
			)
			
			for node in makeuniquearray deps do (
				atsops.getdependencyfilelist node &deps true;
				join filepaths deps;
			)
			
			atsops.getresolvedpaths filepaths &filepaths;
			makeuniquearray filepaths;
		)
		
	)
	
	
	/* state */
	local bounds = undefined;
	local bounds_scale_factor = 1.f;
	local sys = system_t();
	local views = #();
	local modules = #();
	
	local fmt_max = "";
	local fmt_map = "";
	local fmt_out = "";
	
	/* processing */
	fn execute_procedure save_max save_maps save_outputs = (
		try (
			if not isvalidnode bounds do throw "no valid bounds selected";
			if views.count == 0 do throw "no valid batch render views selected";
			if modules.count == 0 do throw "no valid modules selected"
			if fmt_max == "" or fmt_map == "" or fmt_out == "" do throw "invalid formating string"
			
			/* save initial state */
			slidertime = 0f;
			holdmaxfile();
			local bounds_node_name = bounds.name;
			
			/* check if all variables are valid */
			local sys_max = util.format_variables sys fmt_max;
			local sys_map = util.format_variables sys fmt_map;
			local sys_out = util.format_variables sys fmt_out;
			for m in modules do (
				local directories = #();
				local module_out = util.format_variables m sys_out;
				
				/* prepare scene and module */
				fetchmaxfile quiet:true;
				mergemaxfile m.module_filepath #(m.module_name) #mergeDups #useMergedMtlDups #neverReparent quiet:true;
				redrawviews();
				
				local bounds = getnodebyname bounds_node_name;
				local bounds_center = (bounds.min + bounds.max) * 0.5;
				local module_bounds = getnodebyname m.module_name;
				local b1 = module_bounds.max - bounds_center;
				local b2 = module_bounds.min - bounds_center;
				local module_radius = amax #(abs(b1.x),abs(b1.y),abs(b1.z),abs(b2.x),abs(b2.y),abs(b2.z))
				b1 = bounds.max - bounds_center;
				b2 = bounds.min - bounds_center;
				local bounds_radius = amax #(abs(b1.x),abs(b1.y),abs(b1.z),abs(b2.x),abs(b2.y),abs(b2.z))
				--format "bounds max:% module bounds max:%\n" bounds_radius module_radius
				local scale_factor = ((module_radius*bounds_scale_factor) / bounds_radius);
				bounds.scale *= scale_factor;
				
				
				
				/* prepare render jobs outputs */
				
				local mgr = batchrendermgr;
				for v in views do (
					local view_out = util.format_variables v module_out;
					append directories (getfilenamepath view_out);

					local bv = mgr.getview v.view_id;
					bv.outputfilename = view_out;
				)
				
				
				
				/* save files and perform render job */
				if save_max do (
					local module_max = util.format_variables m sys_max;
					local module_max_dir = (getfilenamepath module_max);
					if not makedir module_max_dir all:true do throw ("couldn't create directory " + module_max_dir);
					savemaxfile module_max;
				)
				
				
				if save_maps do (
					local module_map = util.format_variables m sys_map;
					local module_map_dir =  (getfilenamepath module_map)

					local filepaths = util.get_dependencies objects;
					local newfilepaths = for filepath in filepaths collect (module_map + (filenamefrompath filepath));
					
					if newfilepaths.count > 0 do (
						if not makedir module_map_dir all:true do throw ("couldn't create directory " + module_map_dir);
						
						for i = 1 to filepaths.count do (
							--format "copying: %\nto: %\n\n" filepaths[i] newfilepaths[i];
							local filename = (filenamefrompath filepaths[i])
							local newfilepath = module_map + filename;
							while(doesfileexist newfilepath) do (
								local l = util.last_not_digit (getfilenamefile filename)
								local r = (l.y-l.x) as integer;
								local val = substring filename (l.x+1) r;
								local num = formattedprint (1 + val as integer) format:("0"+r as string+"d")
								filename = replace filename (l.x+1) r num;
								newfilepath = module_map + filename;
							)
							copyfile filepaths[i] newfilepath;
						)
					)
				)
				
				if save_outputs do (
					/* prepare directiories */
					for d in directories do 
						if not makedir d all:true do throw ("couldn't create directory " + d);
					
					batchrendermgr.render();
				)
				
			)
		)
		catch (messagebox(getcurrentexception()))
	)
	
	
	/* ui */
	main = newrolloutfloater "Batch Render Modules" 800 600;
	
	renderscene = ( rollout _ "Render Scene" (
		pickbutton pck_bounds "Pick Bounding Object" autodisplay:true across:3;
		spinner	spn_scale "Scale factor" type:#float range:[1e-3, 1e3, bounds_scale_factor];
		button btn_refresh "Refresh"
		dotnetcontrol lv "system.windows.forms.listView" height:80;
		
		on pck_bounds picked obj do bounds = obj;
		on spn_scale changed val do bounds_scale_factor = spn_scale.value;
		
		on btn_refresh pressed do util.update_lv lv (views = util.collect_views());
		
		on _ open do (
			util.init_lv lv view_t;
			util.update_lv lv (views = util.collect_views());
		)
	));
	
	modulefiles = (rollout _ "Module Files" (
		button btn_add "add" across:3 width:180; 
		button btn_rem "remove" width:180; 
		button btn_clr "clear" width:180;
		dotnetcontrol lv "system.windows.forms.listView" height:200;
		local filepaths =#();
		
		on btn_add pressed do (
			filepaths = util.add_files filepaths;
			modules = util.as_modules filepaths;
			util.update_lv lv modules;
		)
		on btn_rem pressed do (
			for i = 1 to lv.selecteditems.count do (
				local item = lv.selecteditems.item[i-1];
				deleteitem modules (finditem modules item.tag.value);
				deleteitem filepaths (finditem filepaths item.tag.value.module_filepath);
			)
			util.update_lv lv modules;
		)
		on btn_clr pressed do (
			filepaths = #();
			modules = #();
			util.update_lv lv #();
		)
		on _ open do util.init_lv lv module_t;
	));
	
	renderfiles = (rollout _"Render Files" (
		edittext edt_fmt_max "Max Dir:" text:"<module_root>/<module_name>/MAX/<module_name>.max";
		edittext edt_fmt_map "Map Dir:" text:"<module_root>/<module_name>/MAX/MAPS/";
		edittext edt_fmt_out "Out Dir:" text:"<module_root>/<module_name>/RENDERS/<view_name>/<module_name>_<view_camera>..png";
		checkbox chk_max "Save to max file" checked:true across:4;
		checkbox chk_map "Collect textures" checked:true;
		checkbox chk_out "Render batch jobs" checked:true; 
		button btn_render "Start Batch Render";
		
		fn is_valid_format str vars = (
			for v in vars do str = util.format_variables v str;
			(findstring str "<") == undefined and (findstring str ">") == undefined;
		)
		on btn_render pressed do (
			fmt_max = edt_fmt_max.text;
			fmt_map = edt_fmt_map.text;
			fmt_out = edt_fmt_out.text;
			
			try (
			if not is_valid_format fmt_max #(system_t(), module_t()) do throw "invalid max dir format";
			if not is_valid_format fmt_map #(system_t(), module_t()) do throw "invalid map dir format";
			if not is_valid_format fmt_out #(system_t(), module_t(), view_t()) do throw "invalid output format";
				
			execute_procedure chk_max.checked chk_map.checked chk_out.checked;
			) catch (messagebox(getcurrentexception()))
		)
	));
	
	formatparam = (rollout _ "Formating" (
		label info "" height:200 align:#left
		on _ open do (
			for p in getpropnames system_t do info.text += "<" + p as string + "> \n"; 
			for p in getpropnames module_t do info.text += "<" + p as string + "> \n";
			for p in getpropnames view_t do info.text += "<" + p as string + "> \n";
		)
	));
	
	addrollout renderscene main;
	addrollout modulefiles main;
	addrollout renderfiles main;
	addrollout formatparam main;
)