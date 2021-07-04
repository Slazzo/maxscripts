(
	/* global params */
	if sz_draw_names_params == undefined do (
		::sz_draw_names_params = true;
		::sz_draw_names_selected = true;
		::sz_draw_names_helpers = false;
		::sz_draw_names_clbk = undefined;
	)
	
	fn sz_draw_names_clbk = (
		local objs = objects;
		if ::sz_draw_names_selected do objs = selection;
		
		for obj in objs where not obj.ishiddeninvpt \
			and (superclassof obj != helper or ::sz_draw_names_helpers) \
			and (classof obj != targetobject) do (
			gw.text obj.pos obj.name color:gray;
		)
	)
	
	rollout main "Display object names" width:200 (
		checkbox chk_selected_only "selected only" checked:::sz_draw_names_selected
		checkbox chk_draw_helpers "helpers" checked:::sz_draw_names_helpers
		
		on main open do (
			::sz_draw_names_clbk = sz_draw_names_clbk;
			registerredrawviewscallback ::sz_draw_names_clbk;	
		)
		
		on main close do (
			unregisterredrawviewscallback sz_draw_names_clbk;
		)
		
		on chk_selected_only changed state do ::sz_draw_names_selected = state;
		on chk_draw_helpers changed state do ::sz_draw_names_helpers = state;
	)
	
	try( destroydialog ::sz_draw_names ) catch()
	::sz_draw_names = main;
	createdialog ::sz_draw_names;
)