(
	rollout main "Remove Modifiers"
	(
		fn populate_ddl_mods objs:unsupplied =
		(
			list=#();
			
			if objs == unsupplied then (
				mods = modifier.classes;
				
				for m in mods where (getclassinstances m).count > 0 do 
					append list (m as string);
			)
			else (
				mods=#();
				
				for o in objs where o.modifiers.count > 0 do (
					for m = 1 to o.modifiers.count do (
						appendifunique mods (classof o.modifiers[m]);
					)
				)
				
				for m in mods do 
					append list (m as string);
			)
			
			if list.count == 0 do 
				append list "None";
			
			list;
		)
		
		radiobuttons rdb_seltype "" labels:#("All","Selected")
		dropdownlist ddl_mods items:(populate_ddl_mods())
		button btn_remove "Remove"
		
		fn remove_modifiers  =
		(
			local objs=case rdb_seltype.state of (
				0 : return false
				1 : (objects as array)
				2 : (selection as array)
			)
			
			if ddl_mods.selection == 0 do return false;
				
			disablesceneredraw();
			suspendediting();
			
			for o in objs where o.modifiers.count > 0 do (
				offset = 0;
				
				for i = 1 to o.modifiers.count do (
					if ((classof o.modifiers[i]) as string) == ddl_mods.items[ddl_mods.selection] do
					(
						deleteModifier o (i-offset);
						offset += 1;
					)
				)
			)
			
			resumeediting();
			enablesceneredraw(); 
		)
		
		on rdb_seltype changed type do
		(
			case type of (
				1:  (
						ddl_mods.items=(populate_ddl_mods());
						callbacks.removescripts #selectionsetchanged id:#sz_delete_modifiers_clbk;
					)
				2:  (
						ddl_mods.items=(populate_ddl_mods objs:(selection as array))
						callbacks.addScript #selectionsetchanged \
							"RemoveModifiers_rollout.ddl_mods.items = RemoveModifiers_rollout.populate_ddl_mods objs:(selection as array)" \
							id:#sz_delete_modifiers_clbk;
					)
			)
		)
		
		on btn_remove pressed do
		(
			remove_modifiers()
			case rdb_seltype.state of (
				1: ddl_mods.items = (populate_ddl_mods());
				2: ddl_mods.items = (populate_ddl_mods objs:(selection as array));
			)
		)
		
		on main close do
		(
			callbacks.removescripts #selectionsetchanged id:#sz_delete_modifiers_clbk;
		)
	)
	
	try( destroydialog ::RemoveModifiers_rollout ) catch()
	::RemoveModifiers_rollout = main;
	createDialog RemoveModifiers_rollout;
)