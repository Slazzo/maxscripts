(
	rollout main "Select Nodes by Materials" width:320 height:160
	(
		multilistbox mlb "" items:#() selection:#() height:12 width:320 pos:(point2 0 0)
		
		local materials = #();
		local clbk_selection_changed = undefined;
		
		fn get_materials_from nodes = (
			mtls=#();
			for o in nodes where o.material != undefined do (
				if classof o.material == multimaterial then (
					for m in o.material.materiallist where m != undefined do (
						appendIfUnique mtls m;
					)
				) else (
					appendIfUnique mtls o.material;
				)
			)
			materials = mtls;
		)			
		
		fn updatelist ev nd = (
			local selectednodes = selection as array;
			get_materials_from selectednodes;
			mlb.items = for m in materials collect m.name;
		)
		
		on mlb selectionEnd do (
			filteredselection = #();
			currentselection = for i in mlb.selection collect materials[i];
			for c in currentselection do (
				for d in refs.dependentnodes c where superclassof d == geometryclass do (
					append filteredselection d;
				)
			)
			select filteredselection;
		)
		
		on main open do ( 
			clbk_selection_changed = nodeeventcallback mouseup:true delay:1000 selectionchanged:updatelist 
			updatelist undefined undefined;
		)
		
		on main close do ( clbk_selection_changed = undefined; )
	)
	
	try( destroydialog selectNodesByMaterial_roll ) catch()
	::selectNodesByMaterial_roll = main;
	createdialog selectNodesByMaterial_roll ;
)