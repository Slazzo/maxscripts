
(
	--sz_display_params = undefined; /* force invalidate global params */
	/* global params */
	if sz_display_params == undefined do (
		::sz_backface_cull = false;
		::sz_display_params = true;
		::sz_display_face_num = true;
		::sz_face_color = yellow;
		::sz_display_face_normals = true;
		::sz_face_normals_size = 10;
		::sz_face_normals_color = blue;
		::sz_display_vert_num = false;
		::sz_vert_color = green;
		::sz_display_vert_normals = true;
		::sz_vert_normals_size = 5;
		::sz_vert_normals_color = green;
		::sz_display_rface_normals = false;
		::sz_display_rface_as_verts = true;
		::sz_face_rcolors=#(red,green,blue);
	)
	
	local inv = inverse;
	local viewtm = getviewtm;
	local getf = getface;
	local getfc = meshop.getfacecenter;
	local getfn = getfacenormal;
	local getfrns = meshop.getfacernormals;
	local getv = meshop.getvert;
	local getn = getnormal;
	local gwtext = gw.text;
	local gwpolyline = gw.polyline;
	local gwmarker = gw.marker;

	fn draw_mesh_data = 
	(
		local coordsystm = inv (viewtm());
		local viewdir = -coordSysTM.row3;
			
		for obj in selection where not obj.ishiddeninvpt \
			and classof obj == editable_mesh do (
			--gw.settransform obj.transform

			if sz_display_face_num or sz_display_face_normals or sz_display_rface_normals do 
			(
				for f = 1 to obj.numfaces do (
					local pos = getfc obj f;
					local n = getfn obj f;
					if sz_backface_cull and dot n viewDir > 0 do continue;
						
					if sz_display_face_num do
						gwtext pos (f as string) color:sz_face_color;
					
					if sz_display_face_normals do 
					(
						
						local pos2 = pos + n*sz_face_normals_size;
						gwpolyline #(pos, pos2) false color:sz_face_normals_color
						gwmarker pos2 #smallCircle color:sz_face_normals_color
					)
					
					if sz_display_rface_normals do 
					(
						local pos1 = pos;
						local frns = getfrns obj f;
						local vs = getf obj f;
						
						for i = 1 to 3 do (
							if sz_display_rface_as_verts do pos1 = getv obj vs[i]
							local pos2 = pos1+frns[i]*sz_face_normals_size;
							gwpolyline #(pos1, pos2) false color:sz_face_normals_color
						)
					)
				)
			)
			
			if sz_display_vert_num or sz_display_vert_normals do 
			(
				for v = 1 to obj.numverts do (
					local pos = getv obj v;
					
					if sz_display_vert_num do 
						gwtext pos (v as string) color:sz_vert_color;
					
					if sz_display_vert_normals do (
						local n = getn obj v;
						local pos2 = pos + n*sz_vert_normals_size;
						gwpolyline #(pos, pos2) false color:sz_vert_normals_color
						gwmarker pos2 #xMarker  color:sz_vert_normals_color
					)
				)
			)
			
			gw.enlargeupdaterect #whole
		)
	)
	
	rollout roll_sz_display_settings "settings" width:260 (
		checkbox chk_bkface_cull "don't draw backfaces (slow)" checked:sz_backface_cull
		checkbox chk_fnum "face num" checked:sz_display_face_num across:2
		colorpicker clr_f "" align:#right color:sz_face_color
		checkbox chk_vnum "vert num" checked:sz_display_vert_num across:2
		colorpicker clr_v "" align:#right color:sz_vert_color
		checkbox chk_fnorm "face normals" checked:sz_display_face_normals across:3
		spinner spn_fnorm "" align:#right width:40 type:#float range:[1e-6,1e+6, sz_face_normals_size]
		colorpicker clr_fnorm "" align:#right color:sz_face_normals_color
		checkbox chk_vnorm "vert normals" checked:sz_display_vert_normals across:3
		spinner spn_vnorm "" align:#right width:40 type:#float range:[1e-6,1e+6, sz_vert_normals_size]
		colorpicker clr_vnorm "" align:#right color:sz_vert_normals_color
		checkbox chk_rfnorms "r face normals" checked:sz_display_rface_normals across:2
		checkbox chk_rfvnorms "as vert" checked:sz_display_rface_as_verts

		on chk_bkface_cull changed state do sz_backface_cull = state;

		/*faces*/
		on chk_fnum changed state do sz_display_face_num = state;
		on clr_f changed val do sz_face_color = val;
		on chk_fnorm changed state do sz_display_face_normals = state;
		on spn_fnorm changed val do sz_face_normals_size = val;
		on clr_fnorm changed val do sz_face_normals_color = val; 

		/*verts*/
		on chk_vnum changed state do sz_display_vert_num = state;
		on clr_v changed val do sz_vert_color = val; 
		on chk_vnorm changed state do sz_display_vert_normals = state;
		on spn_vnorm changed val do sz_vert_normals_size = val;
		on clr_vnorm changed val do sz_vert_normals_color = val; 

		/* more normals */
		on chk_rfnorms changed state do sz_display_rface_normals = state;
		on chk_rfvnorms changed state do sz_display_rface_as_verts = state;
			
		on roll_sz_display_settings close do unregisterredrawviewscallback draw_mesh_data;
		on roll_sz_display_settings open do (
			unregisterredrawviewscallback draw_mesh_data;
			registerredrawviewscallback draw_mesh_data;
		)
	)
	try(destroydialog ::sz_display_settings)catch()
	::sz_display_settings = roll_sz_display_settings;
	createdialog ::sz_display_settings;
)