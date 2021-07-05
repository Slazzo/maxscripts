(
	/*/ 	Note:
		Registering a new xView Checker using MAXScript will cause the new checker to appear on the list of checker shown at the bottom of the viewport when another checker is active, 
		but will NOT put the checker automatically in the Viewport Menu which contains regular MacroScripts exposing the xView Checkers to the 3ds Max Menu System as ActionItems.
		You will have to define a new MacroScript to expose your custom xView to the Menu System and will have to add it to the xViews menu either manually or using MAXScript 
		https://help.autodesk.com/view/3DSMAX/2017/ENU/?guid=__files_GUID_8385056C_4105_485F_B9AE_4280F87E366A_htm
	/*/
	
	struct chk_show_mtl_id_t
	(
		name_ = "Show MaterialID",
		sel_id_ = undefined,
		all_ids_ = undefined,
		roll_dlg_ = undefined,
		
		fn num_faces n = 
		(
			case classof n of (
				default : 0;
				editable_mesh : meshop.getnumfaces n;
				editable_poly : polyop.getnumfaces n;
				polymeshobject : getnumfaces n;
			)
		),
		
		fn face_mtl_id n i =
		(
			case classof n of (
				default : 0;
				editable_mesh : getfacematid n i;
				editable_poly : polyop.getfacematid n i;
				polymeshobject : polyop.getfacematid n i;
			)
		),
		
		fn sup n = geometryclass == superclassof n and num_faces n > 0,
			
		fn txt = ( if all_ids_ != undefined then all_ids_.count as string + " Material IDs" else "unsupported geometry"),
		
		fn upd = xviewchecker.runcheck currenttime,
			
		fn chk t n r = 
		(
			all_ids_=#();
			local nf = num_faces n;
			local id;
			for i = 1 to nf do
			(
				id = face_mtl_id n i;
				appendifunique all_ids_ id;
				if(sel_id_ == id) do append r i;
			)
			sort all_ids_;
			if(::chk_show_mtl_id.roll_dlg_ != undefined) do ::chk_show_mtl_id.roll_dlg_.upd();
			3;
		),
		
		fn drw t n h r = xviewchecker.displayresults green t n h #faces r,
			
		fn dlg =
		(
			rollout roll_dlg name_ 
			(
				dropdownlist ddl 
				
				on ddl selected i do
				(
					::chk_show_mtl_id.sel_id_ = ddl.items[i] as integer;
					::chk_show_mtl_id.upd();
				)
				
				fn upd =
				(
					if(::chk_show_mtl_id.all_ids_ != undefined) do
						ddl.items = for id in ::chk_show_mtl_id.all_ids_ collect (id as string)
					
					if(ddl.items.count == 0) then 
						ddl.items = #("none");
					else 
						ddl.selection = findItem ddl.items (::chk_show_mtl_id.sel_id_ as string);
				)
				
				on roll_dlg open do upd();
			);
			
			try(destroyDialog ::chk_show_mtl_id.roll_dlg_) catch();
			::chk_show_mtl_id.roll_dlg_ = roll_dlg;
			createDialog ::chk_show_mtl_id.roll_dlg_; 
			
		)
	);
	::chk_show_mtl_id = chk_show_mtl_id_t();
	
	xViewChecker.unRegisterChecker chk_show_mtl_id.name_;
	
	xViewChecker.registerChecker chk_show_mtl_id.chk \ 
	chk_show_mtl_id.sup #Faces chk_show_mtl_id.name_ \
	chk_show_mtl_id.dlg chk_show_mtl_id.txt chk_show_mtl_id.drw;
)