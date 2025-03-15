# NodeFiltering
## Installation
1. Download it from [GitHub][rls]
2. Extract the files to your project directory
3. In ```Project/ProjectSettings/Plugins```, ensure that NodeFiltering is enabled.

## Customization
Modify ```res://addons/node_filtering/filters.txt``` to add/remove filters.
You can also make new tabs by adding new keys (see example below)
Set a class to true to display it and false to hide it.
```
	"Example - Level Design":
		{
			"Meshs":
				{
					"MeshInstance3D": true,
				},
			"Lights":
				{
					"OmniLight3D": true,
				}
		}
```

[rls]: https://github.com/Raftatul/NodeFiltering/releases/latest****
